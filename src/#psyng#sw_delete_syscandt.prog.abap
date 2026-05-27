*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_DELETE_SYSCANDT
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
REPORT /psyng/sw_delete_syscandt MESSAGE-ID /psyng/sw.

TABLES: /psyng/syscandt, usr02, agr_define,/psyng/sw_cratdt.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /PSYNG/BASIS_EXELOG.

TYPE-POOLS:slis.

DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv.
DATA: g_answer(1) TYPE c,
      g_alv_flag(1) TYPE c,
      records_c(20),
      g_question(40),
      g_text TYPE string,
      g_poptxt TYPE string,
      g_commitcount TYPE i VALUE '5000', "database commit counter
      g_loopcount   TYPE i,  "loop counter
      g_records TYPE i,     "number of records in internal table
      gt_del_syscandt1 TYPE /psyng/syscandt OCCURS 0 WITH HEADER LINE,
      g_reject      TYPE /psyng/bapiflagx,
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx.

DATA:       gt_syscandt     TYPE STANDARD TABLE OF /psyng/syscandt
                         WITH HEADER LINE.
DATA :      gs_tabname   TYPE tabname.

DATA : BEGIN OF gt_log OCCURS 0,
        type      LIKE icon-id,
        message   LIKE t100-text,
        tot_no    TYPE i,
      END OF gt_log.


CONSTANTS : gc_enh_tabname TYPE tabname VALUE '/PSYNG/ENHSCANDT',
            gc_sys_tabname TYPE tabname VALUE '/PSYNG/SYSCANDT'.

DATA : g_totusrs TYPE i,
       g_totroles TYPE i,
       g_totcausrs TYPE i.

SELECTION-SCREEN: BEGIN OF BLOCK vrsio WITH FRAME TITLE text-017.
SELECTION-SCREEN: SKIP 1.
PARAMETERS : sodvrsio LIKE /psyng/syscandt-vrsio.
SELECTION-SCREEN: SKIP 1.
PARAMETERS : test_run TYPE flag  AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: END OF BLOCK vrsio .



SELECTION-SCREEN: BEGIN OF BLOCK prms WITH FRAME TITLE text-000.
SELECTION-SCREEN: SKIP 1.
PARAMETERS : users  TYPE flag  AS CHECKBOX DEFAULT 'X' .
SELECTION-SCREEN: SKIP 1.
SELECT-OPTIONS: bname FOR usr02-bname,
                conid FOR /psyng/syscandt-conid,
                scandate FOR /psyng/syscandt-scandate.
SELECTION-SCREEN: SKIP 1.

PARAMETERS : sysscan  TYPE flag  RADIOBUTTON GROUP 1  MODIF ID scn .
PARAMETERS : enhscan  TYPE flag  RADIOBUTTON GROUP 1 MODIF ID scn .
SELECTION-SCREEN: END OF BLOCK prms .

SELECTION-SCREEN: BEGIN OF BLOCK rprms WITH FRAME TITLE text-016.
SELECTION-SCREEN: SKIP 1.
PARAMETERS : roles  TYPE flag  AS CHECKBOX DEFAULT 'X' .
SELECTION-SCREEN: SKIP 1.
SELECT-OPTIONS: role FOR agr_define-agr_name,
                scandatr FOR /psyng/syscandt-scandate.

SELECTION-SCREEN: SKIP 1.

SELECTION-SCREEN: END OF BLOCK rprms .

SELECTION-SCREEN: BEGIN OF BLOCK carms WITH FRAME TITLE text-019.
SELECTION-SCREEN: SKIP 1.

PARAMETERS : cas  TYPE flag  AS CHECKBOX DEFAULT 'X' .
SELECTION-SCREEN: SKIP 1.
SELECT-OPTIONS: cbname FOR usr02-bname,
                swaudid FOR  /psyng/sw_cratdt-swaudid,
                scandatc FOR /psyng/sw_cratdt-scandate.

SELECTION-SCREEN: SKIP 1.

SELECTION-SCREEN: END OF BLOCK carms .




AT SELECTION-SCREEN OUTPUT.
  PERFORM get_enhancement_settings.

AT SELECTION-SCREEN.
  PERFORM authority_check.

  IF users IS INITIAL AND roles IS INITIAL AND cas IS INITIAL.
    MESSAGE e116.
  ENDIF.


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

EXELOG sy-repid ''.

  IF test_run = 'X'.
    g_answer = '1'.
    g_alv_flag = 'X'.
  ENDIF.
*** For Users
  IF users = 'X'. "#EC SAST_CI_GEN_CHECK
    PERFORM delete_user.
  ENDIF.

*** For Roles
  IF roles = 'X'.
    PERFORM delete_role.
  ENDIF.

*** For Critical Authorization
  IF cas = 'X'.
    PERFORM delete_crit_auth.
  ENDIF.
  IF NOT gt_log[] IS INITIAL.
    g_alv_flag = 'X'."if we have logging, show it
    PERFORM output_log.
  ENDIF.
*&---------------------------------------------------------------------*
*&      Form  authority_check
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM authority_check.
  AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
           ID 'Y&SW_ADMF' FIELD 'DSODSC'.

  IF sy-subrc NE 0.
    MESSAGE e108(/psyng/sw) WITH 'delete SOD Scan details'(014).
  ENDIF.

ENDFORM.                    " authority_check

*&---------------------------------------------------------------------*
*&      Form  check_ugroup_auth
*&---------------------------------------------------------------------*
*       Check authority to user group
*----------------------------------------------------------------------*
*      -->I_BNAME   User ID
*      <--E_REJECT  Reject record?  X = Reject, Space = Keep
*----------------------------------------------------------------------*
FORM check_ugroup_auth USING    i_bname TYPE usr02-bname
                       CHANGING e_reject TYPE /psyng/bapiflagx.
*STATICS: BEGIN OF lt_user OCCURS 0,
*           bname  TYPE usr02-bname,
*           reject TYPE /psyng/bapiflagx,
*         END OF lt_user,
*
*         BEGIN OF lt_ugroup OCCURS 0,
*           class  TYPE usr02-class,
*           reject TYPE /psyng/bapiflagx,
*         END OF lt_ugroup.
*
*DATA: l_class        TYPE usr02-class,
*      l_user_tabix   TYPE i,
*      l_ugroup_tabix TYPE i.
*
** Check if user has already been found
*  READ TABLE lt_user WITH KEY bname = i_bname BINARY SEARCH.
*  IF sy-subrc = 0.
*    e_reject = lt_user-reject.
*    EXIT.
*  ENDIF.
*
*  l_user_tabix = sy-tabix.
*
*  SELECT SINGLE class INTO l_class FROM usr02
*                WHERE bname = i_bname.
*
** Check if user group has already been found
*  READ TABLE lt_ugroup WITH KEY class = l_class BINARY SEARCH.
*  IF sy-subrc = 0.
*    lt_user-bname  = i_bname.
*    lt_user-reject = lt_ugroup-reject.
*    INSERT lt_user INDEX l_user_tabix.
*
*    e_reject = lt_ugroup-reject.
*    EXIT.
*  ENDIF.
*
*  l_ugroup_tabix = sy-tabix.
*
*  IF NOT l_class IS INITIAL.
**DHO 20101202
**    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
**             ID 'CLASS' FIELD l_class.
*    IF sy-subrc <> 0.
*      gf_missing_auth_ugroup = 'X'.
*      lt_ugroup-reject       = 'X'.
*      lt_user-reject         = 'X'.
*      e_reject               = 'X'.
*    ENDIF.
*  ENDIF.
*
*  lt_user-bname = i_bname.
*  INSERT lt_user INDEX l_user_tabix.
*  lt_ugroup-class = l_class.
*  INSERT lt_ugroup INDEX l_ugroup_tabix.
ENDFORM.                    " check_ugroup_auth
*&---------------------------------------------------------------------*
*&      Form  get_enhancement_settings
*&---------------------------------------------------------------------*
*     Check if a separate table is used for enhanced SOD Matrix
*     scan data (  SW_ENH_SCAN_TBL = Y )
*----------------------------------------------------------------------*
FORM get_enhancement_settings.
  DATA : ls_config  TYPE /psyng/swconfig.
  se_config_param 'SW_ENH_SCAN_TBL' ls_config-value.
  IF  ls_config-value = 'Y'.
* Show radio buttons from selection screen.
    LOOP AT SCREEN.
      CASE screen-group1.
        WHEN 'SCN'.
          screen-invisible = 0.
          MODIFY SCREEN.
      ENDCASE.
    ENDLOOP.
  ELSE.
* Hide radio buttons from selection screen.
    LOOP AT SCREEN.
      CASE screen-group1.
        WHEN 'SCN'.
          screen-invisible = 1.
          MODIFY SCREEN.
      ENDCASE.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " get_enhancement_settings
*&---------------------------------------------------------------------*
*&      Form  set_scantable
*&---------------------------------------------------------------------*
*       Set scantable to delete from
*----------------------------------------------------------------------*
FORM set_scantable.
  IF  enhscan IS INITIAL.
    gs_tabname = gc_sys_tabname.
  ELSE.
    gs_tabname = gc_enh_tabname.
  ENDIF.
ENDFORM.                    " set_scantable

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
  TYPES : BEGIN OF typ_rpoug ,
    vrsio TYPE /psyng/sodvrsio,
    class TYPE xuclass,
    company TYPE char20,
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
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD is_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP'   FIELD is_uinfo-company.
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ELSEIF NOT is_uinfo-class IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD is_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ELSEIF NOT is_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP'   FIELD is_uinfo-company.
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ENDIF.
    ef_reject =  lt_rpoug-rejected.
    INSERT TABLE lt_rpoug.
  ENDIF.
  CLEAR lt_rpoug.

ENDFORM.                    " check_rpoug_auth

*&---------------------------------------------------------------------*
*&      Form  delete_user
*&---------------------------------------------------------------------*
*       Delete scan data for users
*----------------------------------------------------------------------*
FORM delete_user.
  PERFORM set_scantable.

*--> BOC PN 11269 - ATC fixes - HBHALLA - 22/01/25
CASE gs_tabname.
 WHEN gc_enh_tabname.
  SELECT * FROM /PSYNG/ENHSCANDT INTO TABLE gt_syscandt WHERE
           bname IN bname   AND
           conid IN conid   AND
           vrsio = sodvrsio AND
           scandate IN scandate.
 WHEN gc_sys_tabname.
  SELECT * FROM /PSYNG/SYSCANDT INTO TABLE gt_syscandt WHERE
           bname IN bname   AND
           conid IN conid   AND
           vrsio = sodvrsio AND
           scandate IN scandate.

ENDCASE.

**  SELECT * FROM (gs_tabname) INTO TABLE gt_syscandt WHERE
**           bname IN bname   AND
**           conid IN conid   AND
**           vrsio = sodvrsio AND
**           scandate IN scandate. "#EC SAST_CI_GEN_CHECK
*--> EOC PN 11269 - ATC fixes - HBHALLA - 22/01/25

  if sy-subrc <> 0.
     CONCATENATE 'No data selected for'(001)
                'users'(022) INTO g_text
                SEPARATED BY space.
      PERFORM log USING 'W'   g_text 0.
      exit.
  endif.

  DESCRIBE TABLE gt_syscandt LINES g_records.
  WRITE: g_records TO records_c.
  CONDENSE records_c NO-GAPS.
  g_totusrs = g_records.


*DHO 20101202
  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
         lf_reject TYPE flag.
  LOOP AT gt_syscandt.
    lt_uinfo-bname = gt_syscandt-bname.
    APPEND lt_uinfo.
  ENDLOOP.
  SORT lt_uinfo.
  DELETE ADJACENT DUPLICATES FROM lt_uinfo.
  CALL FUNCTION '/PSYNG/SW_USER_INFO'
   EXPORTING
     vrsio                    = sodvrsio
*   ENHANCED_SCANTABLE       = ''
     i_name_only              = 'X'
     i_mr_company             = 'X'
    TABLES
      sw_uinfo                 = lt_uinfo.
  LOOP AT lt_uinfo.
    CLEAR lf_reject.
    PERFORM check_rpoug_auth USING lt_uinfo sodvrsio
                             CHANGING lf_reject.
    IF lf_reject = 'X'.
      DELETE gt_syscandt WHERE bname = lt_uinfo-bname.
      gf_missing_auth_ugroup = 'X'.
    ENDIF.
  ENDLOOP.





  IF bname[] IS INITIAL AND
     conid[] IS INITIAL AND
     scandate[] IS INITIAL.


    IF sy-batch <> 'X'.
      CONCATENATE:
 'Delete all records from /PSYNG/SYSCANDT table for this version -'(003)
             sodvrsio '?'(029) INTO g_poptxt
                   SEPARATED BY space.
      IF test_run IS INITIAL.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
             EXPORTING
                  titlebar              = 'Delete all records?'(002)
                  text_question         = g_poptxt
                  text_button_1         = 'Yes'(004)
                  default_button        = '3'
                  text_button_2         = 'No'(005)
                  display_cancel_button = 'X'
             IMPORTING
                  answer                = g_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND     = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ELSEIF g_answer EQ 'A'.
          MESSAGE s113 WITH 'Processing cancelled.'(021).
*          EXIT.
        ELSEIF g_answer EQ '1'.
          g_alv_flag = 'X'.
        ENDIF.
      ENDIF.
    ELSE.
      g_answer = '1'.
    ENDIF.

    IF g_answer = '1'.
      CLEAR g_records.
      LOOP AT gt_syscandt.
        CLEAR g_reject.
**DHO 20101202
*      PERFORM check_ugroup_auth USING syscandt-bname
*                                CHANGING g_reject.
*      CHECK g_reject IS INITIAL.

        g_loopcount = g_loopcount + 1.
        g_records = g_records + 1.
*        l_totusrs = l_totusrs + 1.
        MOVE-CORRESPONDING gt_syscandt TO gt_del_syscandt1.
        DELETE gt_syscandt.
        APPEND gt_del_syscandt1.

        IF test_run IS INITIAL.
          IF g_loopcount GE g_commitcount.
    CASE gs_tabname.
        WHEN gc_enh_tabname.
          DELETE /PSYNG/ENHSCANDT FROM TABLE gt_del_syscandt1.
        WHEN gc_sys_tabname.
          DELETE /PSYNG/SYSCANDT FROM TABLE gt_del_syscandt1.
    ENDCASE.
*DELETE (gs_tabname)  FROM TABLE gt_del_syscandt1.
            COMMIT WORK.
*            IF sy-subrc = 0.
*              MESSAGE s398(00) WITH records text-006.
*            ENDIF.
            REFRESH gt_del_syscandt1. CLEAR gt_del_syscandt1.
            CLEAR g_loopcount.
          ENDIF.
        ENDIF.
*        CONCATENATE text-025 sodvrsio INTO l_text.
*        PERFORM log USING 'S' del_syscandt1-bname
*                              del_syscandt1-conid
*                              del_syscandt1-vrsio
*                              del_syscandt1-scandate
*                              l_text.
      ENDLOOP.
      IF test_run IS INITIAL.
        IF NOT gt_del_syscandt1[] IS INITIAL.
    CASE gs_tabname.
        WHEN gc_enh_tabname.
          DELETE /PSYNG/ENHSCANDT FROM TABLE gt_del_syscandt1.
        WHEN gc_sys_tabname.
          DELETE /PSYNG/SYSCANDT FROM TABLE gt_del_syscandt1.
    ENDCASE.
*          DELETE (gs_tabname) FROM TABLE gt_del_syscandt1.
          COMMIT WORK.

*          IF sy-subrc = 0.
*            MESSAGE s398(00) WITH records text-006.
*          ENDIF.
          REFRESH gt_del_syscandt1.
          CLEAR: gt_del_syscandt1, g_loopcount, g_records.
        ENDIF.
      ENDIF.

    ENDIF.

  ELSE.   "if user selected specific records to be deleted

    CONCATENATE: 'Delete'(012) records_c 'records?'(013) INTO g_question
                 SEPARATED BY space.
    IF sy-batch <> 'X'.
      IF test_run IS INITIAL.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
             EXPORTING
                  titlebar              = 'Confirm'(007)
                  text_question         = g_question
                  text_button_1         = 'Yes'(004)
                  default_button        = '2'
                  text_button_2         = 'No'(005)
                  display_cancel_button = 'X'
             IMPORTING
                  answer                = g_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND    = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ELSEIF g_answer EQ 'A'.
          MESSAGE s113 WITH 'Processing cancelled.'(021).
*          EXIT.
        ELSEIF g_answer EQ '1'.
          g_alv_flag = 'X'.
        ENDIF.
      ENDIF.
    ELSE.
      g_answer = '1'.
    ENDIF.
  ENDIF.

  IF g_answer = '1'.
    CLEAR g_records.
    LOOP AT gt_syscandt.
      CLEAR g_reject.
*DHO 20101202
*      PERFORM check_ugroup_auth USING syscandt-bname
*                                CHANGING g_reject.
*      CHECK g_reject IS INITIAL.

      g_loopcount = g_loopcount + 1.
      g_records = g_records + 1.
      MOVE-CORRESPONDING gt_syscandt TO gt_del_syscandt1.
      DELETE gt_syscandt.
      APPEND gt_del_syscandt1.

      IF test_run IS INITIAL.
        IF g_loopcount GE g_commitcount.

    CASE gs_tabname.
        WHEN gc_enh_tabname.
          DELETE /PSYNG/ENHSCANDT FROM TABLE gt_del_syscandt1.
        WHEN gc_sys_tabname.
          DELETE /PSYNG/SYSCANDT FROM TABLE gt_del_syscandt1.
    ENDCASE.
*DELETE (gs_tabname) FROM TABLE gt_del_syscandt1.
          COMMIT WORK.
*          IF sy-subrc = 0.
*            MESSAGE s398(00) WITH records text-006.
*          ENDIF.
          REFRESH gt_del_syscandt1. CLEAR gt_del_syscandt1.
          CLEAR g_loopcount.
        ENDIF.
      ENDIF.
*      CONCATENATE text-025 sodvrsio INTO l_text.
*      PERFORM log USING 'S' del_syscandt1-bname
*                            del_syscandt1-conid
*                            del_syscandt1-vrsio
*                            del_syscandt1-scandate
*                            l_text.

    ENDLOOP.

    IF test_run IS INITIAL.
      IF NOT gt_del_syscandt1[] IS INITIAL.
    CASE gs_tabname.
        WHEN gc_enh_tabname.
          DELETE /PSYNG/ENHSCANDT FROM TABLE gt_del_syscandt1.
        WHEN gc_sys_tabname.
          DELETE /PSYNG/SYSCANDT FROM TABLE gt_del_syscandt1.
    ENDCASE.


*DELETE (gs_tabname) FROM TABLE gt_del_syscandt1."#EC SAST_CI_GEN_CHECK
*HBHALLA: Variable used in DELETE clause is not constant,
*so it can't be fixed.(12/12/24)
        COMMIT WORK.
*        IF sy-subrc = 0.
*          MESSAGE s398(00) WITH records text-006.
*        ENDIF.
        REFRESH gt_del_syscandt1.
        CLEAR: gt_del_syscandt1, g_loopcount, g_records.
      ENDIF.
    ENDIF.
  ENDIF.

  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE s398(00) WITH
    'Missing some user group authorizations.'(009)
    'Some records skipped.'(010).
  ENDIF.

  IF g_answer EQ '1'.
    IF g_totusrs EQ 0.
      CONCATENATE 'No data selected for'(001) 'users'(022) INTO g_text
                                 SEPARATED BY space.
      PERFORM log USING 'E' g_text g_totusrs.
    ELSEIF g_totusrs NE 0 AND test_run IS INITIAL.

      CONCATENATE 'Data found & deleted for'(032) 'users'(022)
                                INTO g_text SEPARATED BY space.
      PERFORM log USING 'S' g_text g_totusrs.

    ELSEIF g_totusrs NE 0 AND test_run EQ 'X'.

      CONCATENATE 'Data selected for'(030) 'users'(022)
                            INTO g_text SEPARATED BY space.
      PERFORM log USING 'W'   g_text g_totusrs.
    ENDIF.

  ELSE.

    IF g_totusrs EQ 0.
      CONCATENATE 'No data selected for'(001) 'users'(022)
                            INTO g_text SEPARATED BY space.
      PERFORM log USING 'E'   g_text g_totusrs.

    ELSEIF g_totusrs NE 0.

      CONCATENATE 'Data selected for'(030) 'users'(022)
                            INTO g_text SEPARATED BY space.
      PERFORM log USING 'W'   g_text g_totusrs.
    ENDIF.

  ENDIF.
ENDFORM.                    " delete_user

*&---------------------------------------------------------------------*
*&      Form  delete_role
*&---------------------------------------------------------------------*
*       Delete scan data for roles
*----------------------------------------------------------------------*
FORM delete_role.
  DATA: lt_syscandt2 TYPE TABLE OF /psyng/syscandt2 WITH HEADER LINE,
        lt_delsyscandt2 TYPE TABLE OF /psyng/syscandt2 WITH HEADER LINE.


  SELECT * FROM /psyng/syscandt2 INTO TABLE lt_syscandt2 WHERE
                                agr_name IN role AND
                                vrsio = sodvrsio AND
                                scandate IN scandatr.

  if sy-subrc <> 0.
     CONCATENATE 'No data selected for'(001)
                'roles'(023) INTO g_text
                SEPARATED BY space.
      PERFORM log USING 'W'   g_text 0.
      exit.
  endif.

  DESCRIBE TABLE lt_syscandt2 LINES g_records.
  g_totroles = g_records .

  WRITE: g_records TO records_c.
  CONDENSE records_c NO-GAPS.

  IF role[] IS INITIAL .
    IF sy-batch <> 'X'.

      CONCATENATE:
'Delete all records from /PSYNG/SYSCANDT2 table for this version -'(018)
                         sodvrsio '?'(029) INTO g_poptxt
                         SEPARATED BY space.

      IF test_run IS INITIAL.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
             EXPORTING
                  titlebar              = 'Delete all records?'(002)
                  text_question         = g_poptxt
                  text_button_1         = 'Yes'(004)
                  default_button        = '3'
                  text_button_2         = 'No'(005)
                  display_cancel_button = 'X'
             IMPORTING
                  answer                = g_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND      = 1
             OTHERS              = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ELSEIF g_answer EQ 'A'.
          MESSAGE s113 WITH 'Processing cancelled.'(021).
*          EXIT.
        ELSEIF g_answer EQ '1'.
          g_alv_flag = 'X'.
        ENDIF.
      ENDIF.
    ELSE.
      g_answer = '1'.
      g_alv_flag = 'X'.
    ENDIF.

    CLEAR : g_loopcount, g_records.
    IF g_answer = '1'.
      CLEAR g_records.
      LOOP AT lt_syscandt2.

        g_loopcount = g_loopcount + 1.
        g_records = g_records + 1.
        MOVE-CORRESPONDING lt_syscandt2 TO lt_delsyscandt2.
        DELETE lt_syscandt2.
        APPEND lt_delsyscandt2.

        IF test_run IS INITIAL.
          IF g_loopcount GE g_commitcount.
            DELETE /psyng/syscandt2          "#EC CI_IMUD_NESTED
                 FROM TABLE lt_delsyscandt2.
            COMMIT WORK.
*            IF sy-subrc = 0.
*              MESSAGE s398(00) WITH records text-006.
*            ENDIF.
            REFRESH lt_delsyscandt2. CLEAR lt_delsyscandt2.
            CLEAR g_loopcount.
          ENDIF.

        ENDIF.
*        CONCATENATE text-026 sodvrsio INTO l_text.
*        PERFORM log USING 'S' lt_delsyscandt2-agr_name
*                              lt_delsyscandt2-conid
*                              lt_delsyscandt2-vrsio
*                              lt_delsyscandt2-scandate
*                              l_text.

      ENDLOOP.
      IF test_run IS INITIAL.
        IF NOT lt_delsyscandt2[] IS INITIAL.
          DELETE /psyng/syscandt2 FROM TABLE lt_delsyscandt2.
          COMMIT WORK.
*          IF sy-subrc = 0.
*            MESSAGE s398(00) WITH records text-006.
*          ENDIF.
          REFRESH lt_delsyscandt2.
          CLEAR: lt_delsyscandt2, g_loopcount, g_records.
        ENDIF.
      ENDIF.
    ENDIF.

  ELSE.   "if user selected specific records to be deleted

    CONCATENATE: 'Delete'(012) records_c 'records?'(013) INTO g_question
                 SEPARATED BY space.
    IF sy-batch <> 'X'.
      IF test_run IS INITIAL.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
             EXPORTING
                  titlebar              = 'Confirm'(007)
                  text_question         = g_question
                  text_button_1         = 'Yes'(004)
                  default_button        = '2'
                  text_button_2         = 'No'(005)
                  display_cancel_button = 'X'
             IMPORTING
                  answer                = g_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND   = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ELSEIF g_answer EQ 'A'.
          MESSAGE s113 WITH 'Processing cancelled.'(021).
*          EXIT.
        ELSEIF g_answer EQ '1'.
          g_alv_flag = 'X'.
        ENDIF.
      ENDIF.
    ELSE.
      g_answer = '1'.
    ENDIF.

    IF g_answer = '1'.
      CLEAR g_records.
      LOOP AT lt_syscandt2.
        CLEAR g_reject.
*DHO 20101202
*      PERFORM check_ugroup_auth USING lt_syscandt2-bname
*                                CHANGING g_reject.
*      CHECK g_reject IS INITIAL.

        g_loopcount = g_loopcount + 1.
        g_records = g_records + 1.
        MOVE-CORRESPONDING lt_syscandt2 TO lt_delsyscandt2.
        DELETE lt_syscandt2.
        APPEND lt_delsyscandt2.
        IF test_run IS INITIAL.
          IF g_loopcount GE g_commitcount.
            DELETE /psyng/syscandt2              "#EC CI_IMUD_NESTED
                 FROM TABLE lt_delsyscandt2.
            COMMIT WORK.
*            IF sy-subrc = 0.
*              MESSAGE s398(00) WITH records text-006.
*            ENDIF.
            REFRESH lt_delsyscandt2. CLEAR lt_delsyscandt2.
            CLEAR g_loopcount.
          ENDIF.
        ENDIF.
*        CONCATENATE text-026 sodvrsio INTO l_text.
*        PERFORM log USING 'S' lt_delsyscandt2-agr_name
*                              lt_delsyscandt2-conid
*                              lt_delsyscandt2-vrsio
*                              lt_delsyscandt2-scandate
*                              l_text.


      ENDLOOP.
      IF test_run IS INITIAL.
        IF NOT lt_delsyscandt2[] IS INITIAL.
          DELETE /psyng/syscandt2 FROM TABLE lt_delsyscandt2.
          COMMIT WORK.
*        IF sy-subrc = 0.
*          MESSAGE s398(00) WITH records text-006.
*        ENDIF.
          REFRESH lt_delsyscandt2.
          CLEAR: lt_delsyscandt2, g_loopcount, g_records.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  IF gf_missing_auth_ugroup = 'X'.
   MESSAGE s398(00) WITH 'Missing some user group authorizations.'(009)
                              'Some records skipped.'(010).
  ENDIF.

  IF g_answer EQ '1'.
    IF g_totroles EQ 0.
      CONCATENATE 'No data selected for'(001) 'roles'(023)
                              INTO g_text SEPARATED BY space.
      PERFORM log USING 'E'   g_text g_totroles.

    ELSEIF g_totroles NE 0 AND test_run IS INITIAL.

      CONCATENATE 'Data found & deleted for'(032) 'roles'(023)
                                INTO g_text SEPARATED BY space.
      PERFORM log USING 'S'   g_text g_totroles.

    ELSEIF g_totroles NE 0 AND test_run EQ 'X'.

      CONCATENATE 'Data selected for'(030) 'roles'(023)
                                INTO g_text SEPARATED BY space.
      PERFORM log USING 'W'   g_text g_totroles.

    ENDIF.
  ELSE.

    IF g_totroles EQ 0.
      CONCATENATE 'No data selected for'(001) 'roles'(023)
                                INTO g_text SEPARATED BY space.
      PERFORM log USING 'E'   g_text g_totroles.


    ELSEIF g_totroles NE 0.

      CONCATENATE 'Data selected for'(030) 'roles'(023)
                                INTO g_text SEPARATED BY space.
      PERFORM log USING 'W'   g_text g_totroles.

    ENDIF.

  ENDIF.

ENDFORM.                    " delete_role

*&---------------------------------------------------------------------*
*&      Form  delete_crit_auth
*&---------------------------------------------------------------------*
*       Delete scan data for critical authorizations
*----------------------------------------------------------------------*
FORM delete_crit_auth.
  DATA : lt_cradt TYPE TABLE OF /psyng/sw_cratdt WITH HEADER LINE,
         lt_delcradt TYPE TABLE OF /psyng/sw_cratdt WITH HEADER LINE.


  SELECT * FROM /psyng/sw_cratdt INTO TABLE lt_cradt WHERE
                                bname IN cbname AND
                                vrsio = sodvrsio AND
                                swaudid IN swaudid AND
                                scandate IN scandatc.

  if sy-subrc <> 0.
     CONCATENATE 'No data selected for'(001)
                'critical authorizations'(024) INTO g_text
                SEPARATED BY space.
      PERFORM log USING 'W'   g_text 0.
      exit.
  endif.


  DESCRIBE TABLE lt_cradt LINES g_records.
  g_totcausrs = g_records.

  WRITE: g_records TO records_c.
  CONDENSE records_c NO-GAPS.

  IF cbname[] IS INITIAL AND
     swaudid[] IS INITIAL AND
     scandatc[] IS INITIAL .

    IF sy-batch <> 'X'.

      CONCATENATE:
'Delete all records from /PSYNG/SW_CRATDT table for this version -'(020)
       sodvrsio '?'(029) INTO g_poptxt SEPARATED BY space.

      IF test_run IS INITIAL.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
             EXPORTING
                  titlebar              = 'Delete all records?'(002)
                  text_question         = g_poptxt
                  text_button_1         = 'Yes'(004)
                  default_button        = '3'
                  text_button_2         = 'No'(005)
                  display_cancel_button = 'X'
             IMPORTING
                  answer                = g_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND       = 1
             OTHERS               = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ELSEIF g_answer EQ 'A'.
          MESSAGE s113 WITH 'Processing cancelled.'(021).
*          EXIT.
        ELSEIF g_answer EQ '1'.
          g_alv_flag = 'X'.
        ENDIF.
      ENDIF.
    ELSE.
      g_answer = '1'.
    ENDIF.

    CLEAR : g_loopcount, g_records.

    IF g_answer = '1'.
      CLEAR g_records.
      LOOP AT lt_cradt.

        g_loopcount = g_loopcount + 1.
        g_records = g_records + 1.
        MOVE-CORRESPONDING lt_cradt TO lt_delcradt.
        DELETE lt_cradt.
        APPEND lt_delcradt.
        IF test_run IS INITIAL.
          IF g_loopcount GE g_commitcount.
            DELETE /psyng/sw_cratdt          "#EC CI_IMUD_NESTED
                 FROM TABLE lt_delcradt.
            COMMIT WORK.
*            IF sy-subrc = 0.
*              MESSAGE s398(00) WITH records text-006.
*            ENDIF.
            REFRESH lt_delcradt. CLEAR lt_delcradt.
            CLEAR g_loopcount.
          ENDIF.
        ENDIF.
*        CONCATENATE text-027 sodvrsio INTO l_text.
*        PERFORM log USING 'S' lt_delcradt-bname
*                            lt_delcradt-swaudid
*                            lt_delcradt-vrsio
*                            lt_delcradt-scandate
*                            l_text.
      ENDLOOP.
      IF test_run IS INITIAL.
        IF NOT lt_delcradt[] IS INITIAL.
          DELETE /psyng/sw_cratdt FROM TABLE lt_delcradt.
          COMMIT WORK.
*          IF sy-subrc = 0.
*            MESSAGE s398(00) WITH records text-006.
*          ENDIF.
          REFRESH lt_delcradt.
          CLEAR: lt_delcradt, g_loopcount, g_records.
        ENDIF.
      ENDIF.
    ENDIF.

  ELSE.   "if user selected specific records to be deleted

    CONCATENATE: 'Delete'(012) records_c 'records?'(013) INTO g_question
                 SEPARATED BY space.
    IF sy-batch <> 'X'.
      IF test_run IS INITIAL.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
             EXPORTING
                  titlebar              = 'Confirm'(007)
                  text_question         = g_question
                  text_button_1         = 'Yes'(004)
                  default_button        = '2'
                  text_button_2         = 'No'(005)
                  display_cancel_button = 'X'
             IMPORTING
                  answer                = g_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND = 1
             OTHERS          = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ELSEIF g_answer EQ 'A'.
          MESSAGE s113 WITH 'Processing cancelled.'(021).
*          EXIT.
        ELSEIF g_answer EQ '1'.
          g_alv_flag = 'X'.
        ENDIF.
      ENDIF.
    ELSE.
      g_answer = '1'.
    ENDIF.


    IF g_answer = '1'.
      CLEAR g_records.
      LOOP AT lt_cradt.
        CLEAR g_reject.
*DHO 20101202
        PERFORM check_ugroup_auth USING lt_cradt-bname
                                  CHANGING g_reject.
        CHECK g_reject IS INITIAL.

        g_loopcount = g_loopcount + 1.
        g_records = g_records + 1.
        MOVE-CORRESPONDING lt_cradt TO lt_delcradt.
        DELETE lt_cradt.
        APPEND lt_delcradt.
        IF test_run IS INITIAL.
          IF g_loopcount GE g_commitcount.
            DELETE /psyng/sw_cratdt FROM TABLE lt_delcradt.
            COMMIT WORK.
*            IF sy-subrc = 0.
*              MESSAGE s398(00) WITH records text-006.
*            ENDIF.
            REFRESH lt_delcradt. CLEAR lt_delcradt.
            CLEAR g_loopcount.
          ENDIF.
        ENDIF.

      ENDLOOP.
      IF test_run IS INITIAL.
        IF NOT lt_delcradt[] IS INITIAL.
          DELETE /psyng/sw_cratdt         "#EC CI_IMUD_NESTED
                FROM TABLE lt_delcradt.
          COMMIT WORK.
*          IF sy-subrc = 0.
*            MESSAGE s398(00) WITH records text-006.
*          ENDIF.
          REFRESH lt_delcradt.
          CLEAR: lt_delcradt, g_loopcount, g_records.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  IF g_answer EQ '1'.
    IF g_totcausrs EQ 0.
      CONCATENATE 'No data selected for'(001)
                  'critical authorizations'(024)
                      INTO g_text SEPARATED BY space.

      PERFORM log USING 'E'   g_text g_totcausrs.
    ELSEIF g_totcausrs NE 0 AND test_run IS INITIAL.

      CONCATENATE 'Data found & deleted for'(032)
                  'critical authorizations'(024)
                      INTO g_text SEPARATED BY space.

      PERFORM log USING 'S'   g_text g_totcausrs.

    ELSEIF g_totcausrs NE 0 AND test_run EQ 'X'.

      CONCATENATE 'Data selected for'(030)
                  'critical authorizations'(024)
                      INTO g_text SEPARATED BY space.

      PERFORM log USING 'W'   g_text g_totcausrs.

    ENDIF.

  ELSE.

    IF g_totcausrs EQ 0.
      CONCATENATE 'No data selected for'(001)
                  'critical authorizations'(024)
                      INTO g_text SEPARATED BY space.

      PERFORM log USING 'E'   g_text g_totcausrs.
    ELSEIF g_totcausrs NE 0.

      CONCATENATE 'Data selected for'(030)
                  'critical authorizations'(024)
                      INTO g_text SEPARATED BY space.

      PERFORM log USING 'W'   g_text g_totcausrs.
    ENDIF.

  ENDIF.


  IF gf_missing_auth_ugroup = 'X'.
   MESSAGE s398(00) WITH 'Missing some user group authorizations.'(009)
                              'Some records skipped.'(010).
  ENDIF.
ENDFORM.                    " delete_crit_auth


*---------------------------------------------------------------------*
*       FORM output_log                                               *
*---------------------------------------------------------------------*
*       Show log in ALV format                                        *
*---------------------------------------------------------------------*
FORM output_log.


  DATA: ls_variant TYPE disvariant,
        alv_layout      TYPE slis_layout_alv.


  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv,
  l_program LIKE sy-repid.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  l_program = sy-repid.

  IF g_alv_flag EQ 'X'.

    CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
         EXPORTING
              i_program_name     = l_program
              i_internal_tabname = 'GT_LOG'
              i_inclname         = l_program
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

    CHECK sy-subrc = 0.
    PERFORM change_catalog_texts.


    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
         EXPORTING
              i_callback_top_of_page = 'ALV_HEADER'
              i_callback_program     = l_program
              is_layout              = alv_layout
              it_fieldcat            = i_fieldcat_alv
              i_save                 = 'A'
              is_variant             = ls_variant
         TABLES
              t_outtab               = gt_log
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

  ENDIF.
  CLEAR g_alv_flag.
ENDFORM.                    " output_log


*---------------------------------------------------------------------*
*       FORM log                                                      *
*---------------------------------------------------------------------*
*       Add record to log table                                       *
*---------------------------------------------------------------------*
*  -->  I_FILE                                                        *
*  -->  I_TYPE                                                        *
*  -->  I_OBJECT                                                      *
*  -->  I_OBJECT_ID                                                   *
*  -->  I_FIELD                                                       *
*  -->  I_VALUE                                                       *
*  -->  I_MESSAGE                                                     *
*---------------------------------------------------------------------*
FORM log USING    i_type
*                  i_object
*                  i_field
*                  i_vrsio
*                  i_date
                  i_message
                  i_totno
                  .
  CLEAR gt_log.
  CASE i_type.
    WHEN 'S'."Success
      gt_log-type      =  '@08@'.
    WHEN 'W'."Warning
      gt_log-type      =  '@09@'.
    WHEN 'E'."Error
      gt_log-type      =  '@0A@'.
  ENDCASE.

*  gt_log-object    = i_object.
*  gt_log-fieldname = i_field.
*  gt_log-vrsio     = i_vrsio.
*  gt_log-date      = i_date.
  gt_log-message   = i_message.
  gt_log-tot_no   = i_totno.
  APPEND gt_log.

ENDFORM.                    " log

*---------------------------------------------------------------------*
*       FORM ALV_HEADER                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        l_count TYPE i,
        c_count TYPE string,
        alv_grid_titl2   TYPE lvc_title.
  .

*TITLE AREA
  wa-typ = 'H'.
  wa-info = 'Clear Delete Scan Tables'(h02).
  APPEND wa TO header.
*SOD Version.
  wa-typ = 'S'.
  wa-key = 'Sod Version'(h03).
  wa-info = sodvrsio.
  APPEND wa TO header.
*Errors
  CLEAR l_count.

*  LOOP AT gt_log.
*    IF gt_log-type = '@08@'.
*      ADD 1 TO count.
*    ENDIF.
*  ENDLOOP.
  c_count = g_totusrs + g_totroles + g_totcausrs.
  wa-typ = 'S'.
  wa-key = 'Total no. of records deleted'(h04).
  wa-info = c_count.
  APPEND wa TO header.

  IF test_run = 'X'.
    wa-typ  = 'A'.
    wa-info = 'Test Run Mode'(h05).
    APPEND wa TO header.
  ENDIF.
  CLEAR : g_totusrs ,g_totroles , g_totcausrs.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = header.
*            i_logo             = 'Z_3SW_LOGO_JPG'.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM change_catalog_texts                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM change_catalog_texts.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  wa_fieldcat_alv-seltext_l = 'NrRcds'(031).
  wa_fieldcat_alv-seltext_m = 'NrRcds'(031).
  wa_fieldcat_alv-seltext_s = 'NrRcds'(031).
  wa_fieldcat_alv-reptext_ddic = 'NrRcds'(031).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TOT_NO'.

  wa_fieldcat_alv-seltext_l = 'Status'(033).
  wa_fieldcat_alv-seltext_m = 'Status'(033).
  wa_fieldcat_alv-seltext_s = 'Status'(033).
  wa_fieldcat_alv-reptext_ddic = 'Status'(033).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TYPE'.


ENDFORM.
