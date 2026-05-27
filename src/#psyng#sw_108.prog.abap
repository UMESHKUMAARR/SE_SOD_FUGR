*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_108
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
REPORT /psyng/sw_108 MESSAGE-ID /psyng/sw.
TABLES: /psyng/function,     "SW: Function Definition
        /psyng/conflict,     "SW: Conflict Header
        /psyng/mchdr,        "SW: Mitigating Controls Header
        /psyng/mcuser,       "SW: Mit. Controls Assignment to Users
        /psyng/mcusrgrp,     "SW: Mit. Controls Assignment to User Group
        /psyng/mccauser,     "Mit Controls Assignment to Cri Auth Users
        /psyng/mccarole,     "Mit Controls Assignment to Cri Auth Roles
        /psyng/mcrole,        "Mitigating Controls Assignment to Roles
        /psyng/user,          "SW: User Header
        usr02,
        /psyng/swaudhdr,
        /psyng/critcodes,
        /psyng/criprof,
        /psyng/criroles,
        /psyng/swconfig.

TYPE-POOLS: slis.

DATA: BEGIN OF gt_output OCCURS 0,
        tabname(50) TYPE c,
        vrsio       LIKE /psyng/function-vrsio,
        object      LIKE cdpos-objectid,
        chngind(10) TYPE c,
        username    LIKE cdhdr-username,
        userfull    LIKE adrp-name_text,
        udate       LIKE cdhdr-udate,
        utime       LIKE cdhdr-utime,
        tabkey      LIKE cdpos-tabkey,
        fname       LIKE cdpos-fname,
        field_desc  LIKE dd04t-ddtext,
        val_old     LIKE cdpos-value_old,
        val_new     LIKE cdpos-value_new,
      END OF gt_output.

DATA: gt_fieldcat TYPE slis_t_fieldcat_alv,
      gt_sort     TYPE slis_t_sortinfo_alv.

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
SELECT-OPTIONS: s_date FOR sy-datum,
                s_cuser FOR /psyng/mcuser-userid.
SELECTION-SCREEN END OF BLOCK blk1.

SELECTION-SCREEN BEGIN OF BLOCK conrep WITH FRAME TITLE text-t02.
SELECT-OPTIONS: s_vrsio FOR /psyng/function-vrsio.
PARAMETERS: p_vrsio AS CHECKBOX.
SELECTION-SCREEN BEGIN OF BLOCK function WITH FRAME TITLE text-t03.
PARAMETERS: p_funct AS CHECKBOX.
SELECT-OPTIONS: s_funct FOR /psyng/function-function.
SELECTION-SCREEN END OF BLOCK function.

SELECTION-SCREEN BEGIN OF BLOCK conflict WITH FRAME TITLE text-t04.
PARAMETERS: p_conid AS CHECKBOX.
SELECT-OPTIONS: s_conid FOR /psyng/conflict-conid.
SELECTION-SCREEN END OF BLOCK conflict.

SELECTION-SCREEN BEGIN OF BLOCK mc WITH FRAME TITLE text-t05.
PARAMETERS: p_cont AS CHECKBOX.
SELECT-OPTIONS: s_contid FOR /psyng/mchdr-contid,
                s_mconid FOR /psyng/mcuser-conid.

SELECTION-SCREEN BEGIN OF BLOCK assignment WITH FRAME TITLE text-t06.
PARAMETERS: p_userid AS CHECKBOX.
SELECT-OPTIONS: s_userid FOR /psyng/mcuser-userid.
PARAMETERS: p_class AS CHECKBOX.
SELECT-OPTIONS: s_class  FOR /psyng/mcusrgrp-class.
PARAMETERS: p_role AS CHECKBOX.
SELECT-OPTIONS: s_role  FOR /psyng/mcrole-agr_name.
PARAMETERS: p_audid AS CHECKBOX.
SELECT-OPTIONS: s_audid  FOR /psyng/mccauser-swaudid,
                s_auser  FOR /psyng/mccauser-userid.
PARAMETERS: p_carole AS CHECKBOX.
SELECT-OPTIONS: s_caid   FOR /psyng/mccarole-swaudid,
                s_carole FOR /psyng/mccarole-agr_name.
SELECTION-SCREEN END OF BLOCK assignment.
SELECTION-SCREEN END OF BLOCK mc.
SELECTION-SCREEN BEGIN OF BLOCK cauth WITH FRAME TITLE text-t07.
PARAMETERS: p_cauth AS CHECKBOX.
SELECT-OPTIONS: s_cauth FOR /psyng/swaudhdr-swaudid.

PARAMETERS: p_ctcode AS CHECKBOX.
SELECT-OPTIONS: s_ctcode FOR /psyng/critcodes-tcode.

PARAMETERS: p_cprof AS CHECKBOX.
SELECT-OPTIONS: s_cprof FOR /psyng/criprof-profile.

PARAMETERS: p_crole AS CHECKBOX.
SELECT-OPTIONS: s_crole FOR /psyng/criroles-agr_name.
SELECTION-SCREEN END OF BLOCK cauth.
.
SELECTION-SCREEN END OF BLOCK conrep.
SELECTION-SCREEN BEGIN OF BLOCK blkc WITH FRAME TITLE text-t08.
PARAMETERS :
  p_local  TYPE flag USER-COMMAND local DEFAULT 'X',
  p_system TYPE /psyng/sw_rfcdes-rfcdest
           MATCHCODE OBJECT /psyng/sw_rfcsh_coll.
PARAMETERS: p_conf AS CHECKBOX.
SELECT-OPTIONS: s_param FOR /psyng/swconfig-param.
SELECTION-SCREEN END OF BLOCK blkc.

*-------------------------- INITIALIZATION ----------------------------*
INITIALIZATION.
  PERFORM exelog.

*------------------------ AT SELECTION-SCREEN OUTPUT-------------------*
AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-name.
      WHEN 'P_SYSTEM'.
        IF p_local = 'X'.
          CLEAR p_system.
          screen-input = '0'.
        ELSE.
          screen-input = '1'.
        ENDIF.
        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.
*------------------------ AT SELECTION-SCREEN -------------------------*
AT SELECTION-SCREEN.

*------------------------ START-OF-SELECTION --------------------------*
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
  IF  p_local IS INITIAL
  AND p_system IS INITIAL.
    MESSAGE s002(/psyng/sw)
    WITH 'Please enter remote system Or Choose local system'(a01).
    LEAVE LIST-PROCESSING.
  ENDIF.
*-- Check RFC destinations
  IF NOT p_system IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.
  IF p_funct  IS INITIAL AND
     p_conid  IS INITIAL AND
     p_cont   IS INITIAL AND
     p_userid IS INITIAL AND
     p_class  IS INITIAL AND
     p_audid  IS INITIAL AND
     p_role   IS INITIAL AND
     p_cauth  IS INITIAL AND
     p_ctcode IS INITIAL AND
     p_crole  IS INITIAL AND
     p_cprof  IS INITIAL AND
     p_carole IS INITIAL AND
     p_conf IS INITIAL   AND
     p_vrsio IS INITIAL.
    MESSAGE s127.
    LEAVE LIST-PROCESSING.
  ENDIF.

  PERFORM get_data.
  PERFORM output_screen.

*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: lt_exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE,
        l_current_user TYPE sy-uname. "C0700
* BOC by RGUPTA on 05.04.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 05.04.22 for C0700

  lt_exelog-mandt = sy-mandt.
  lt_exelog-repid = sy-repid.
  lt_exelog-uname = l_current_user. "sy-uname. C0700
  lt_exelog-datum = sy-datum.
  lt_exelog-uzeit = sy-uzeit.
  APPEND lt_exelog.

  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = lt_exelog.

  COMMIT WORK.
ENDFORM.                    " exelog

*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       Get change documents from database
*----------------------------------------------------------------------*
FORM get_data.
  RANGES: lr_objclas FOR cdhdr-objectclas,
          lr_objid   FOR cdhdr-objectid,
          lr_tabname FOR cdpos-tabname,
          lr_mcusr_tab FOR cdpos-tabname.                   " C0693

  DATA: BEGIN OF lt_cdpos_uid OCCURS 0,
        keyguid(32) TYPE c,
        objectclas TYPE cdpos-objectclas,
        objectid TYPE cdpos-objectid,
        changenr TYPE cdpos-changenr,
        tabname   TYPE tabname,
        tabkey    TYPE cdfldvaln,
        END OF lt_cdpos_uid.
  CONSTANTS c_cdpos_uid TYPE tabname VALUE 'CDPOS_UID'.

  DATA: lt_cdhdr TYPE TABLE OF cdhdr WITH HEADER LINE,
        lt_cdpos TYPE TABLE OF cdpos WITH HEADER LINE,
        lt_cdhdr_rem TYPE TABLE OF cdhdr,
        lt_cdpos_rem TYPE TABLE OF cdpos,
        lt_objid TYPE TABLE OF cdpos-objectid WITH HEADER LINE,
        lt_cdpos_tmp LIKE TABLE OF lt_cdpos  WITH HEADER LINE,
        l_numcheck(10) TYPE c VALUE '0123456789',
        lt_parts  TYPE STANDARD TABLE OF string,
        lv_value TYPE string,
        lv_cauth TYPE string,
        lv_len TYPE i,
        lv_lines TYPE sy-tabix.
  DATA  lf_config_change TYPE flag.

  lr_objclas-sign   = lr_objid-sign   = lr_tabname-sign
  = lr_mcusr_tab-sign = 'I'.
  lr_objclas-option = lr_objid-option = lr_tabname-option =
  lr_mcusr_tab-option = 'EQ'.

  IF p_vrsio = 'X'.
    lr_objclas-low = '/PSYNG/VRSIO'.
    APPEND lr_objclas.

    lr_tabname-low = '/PSYNG/SWSODVERS'.
    APPEND lr_tabname.
  ENDIF.

  IF p_funct = 'X'.
    lr_objclas-low = '/PSYNG/FUNCTS'.
    APPEND lr_objclas.
    lr_objclas-low = '/PSYNG/FAOBJ'.
    APPEND lr_objclas.

    lr_tabname-low = '/PSYNG/FUNCTION'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/FUNCTTRAN'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/FAOBJ2'.
    APPEND lr_tabname.
  ENDIF.

  IF p_conid = 'X'.
    lr_objclas-low = '/PSYNG/CONFLICT'.
    APPEND lr_objclas.

    lr_tabname-low = '/PSYNG/CONFLICT'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/CONFDET'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/CONOWNER'.
    APPEND lr_tabname.
  ENDIF.

  IF p_cont = 'X'.
    lr_objclas-low = '/PSYNG/MIT'.
    APPEND lr_objclas.

    lr_tabname-low = '/PSYNG/MCHDR'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/MCAUDITOR'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/MCTRAN'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/MCREPID'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/MCRVWHDR'.
    APPEND lr_tabname.

  ENDIF.

  IF p_userid = 'X'.
    lr_objclas-low = '/PSYNG/MIT'.
    COLLECT lr_objclas.

    lr_tabname-low = '/PSYNG/MCUSER'.
    APPEND lr_tabname.

    lr_mcusr_tab-low = '/PSYNG/MCUSER'.
    APPEND lr_mcusr_tab.
  ENDIF.

  IF p_class = 'X'.
    lr_objclas-low = '/PSYNG/MIT'.
    COLLECT lr_objclas.

    lr_tabname-low = '/PSYNG/MCUSRGRP'.
    APPEND lr_tabname.
  ENDIF.

  IF p_audid = 'X'.
    lr_objclas-low = '/PSYNG/MIT'.
    COLLECT lr_objclas.

    lr_tabname-low = '/PSYNG/MCCAUSER'.
    APPEND lr_tabname.
  ENDIF.

  IF p_carole = 'X'.
    lr_objclas-low = '/PSYNG/MIT'.
    COLLECT lr_objclas.

    lr_tabname-low = '/PSYNG/MCCAROLE'.
    APPEND lr_tabname.
  ENDIF.

  IF p_role = 'X'.
    lr_objclas-low = '/PSYNG/MIT'.
    COLLECT lr_objclas.

    lr_tabname-low = '/PSYNG/MCROLE'.
    APPEND lr_tabname.
  ENDIF.

  IF p_cauth = 'X'.
    lr_objclas-low = '/PSYNG/SWAUD'.
    APPEND lr_objclas.

    lr_tabname-low = '/PSYNG/SWAUDHDR'.
    APPEND lr_tabname.

*Begin of Addition:HBHALLA(PN-5886)(12/02/26)
    lr_objclas-low = '/PSYNG/SWAUDC'.
    APPEND lr_objclas.
*End of Addition:HBHALLA(PN-5886)(12/02/26)

    lr_tabname-low = '/PSYNG/SWAUDC2'.
    APPEND lr_tabname.
  ENDIF.

  IF p_ctcode = 'X'.

    lr_objclas-low = '/PSYNG/CRIT_OBJ'.
    APPEND lr_objclas.

    lr_tabname-low = '/PSYNG/CRITCODES'.
    APPEND lr_tabname.
  ENDIF.

  IF p_crole = 'X'.
    lr_objclas-low = '/PSYNG/CRIT_OBJ'.
    APPEND lr_objclas.

    lr_tabname-low = '/PSYNG/CRIROLES'.
    APPEND lr_tabname.
  ENDIF.

  IF p_cprof = 'X'.
    lr_objclas-low = '/PSYNG/CRIT_OBJ'.
    APPEND lr_objclas.

    lr_tabname-low = '/PSYNG/CRIPROF'.
    APPEND lr_tabname.
  ENDIF.

  IF  p_conf = 'X'.


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

    CALL FUNCTION '/PSYNG/SW_GET_CHANGE_HISTORY'
     DESTINATION p_system
     EXPORTING
       if_conf         = p_conf
     TABLES
       it_date         = s_date
       it_bname        = s_cuser
       et_cdhdr        = lt_cdhdr_rem
       et_cdpos        = lt_cdpos_rem
     EXCEPTIONS
       system_failure        = 1
       communication_failure = 2
       OTHERS                = 3."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc NE 0.
*Raise error
    ENDIF.
  ENDIF.

  IF NOT lr_objclas[] IS INITIAL.
    SELECT * INTO TABLE lt_cdhdr FROM cdhdr
           WHERE objectclas IN lr_objclas
             AND objectid   IN lr_objid
             AND username   IN s_cuser
             AND udate      IN s_date.
    IF NOT lt_cdhdr[] IS INITIAL.
      SORT lt_cdhdr BY objectclas objectid changenr.

      SELECT * INTO TABLE lt_cdpos                      "#EC CI_NOORDER
      FROM cdpos FOR ALL ENTRIES IN lt_cdhdr
             WHERE objectclas = lt_cdhdr-objectclas
               AND objectid   = lt_cdhdr-objectid
               AND changenr   = lt_cdhdr-changenr
               AND tabname   IN lr_tabname.

*--- read mcuser change key length > 70
      READ TABLE lr_mcusr_tab TRANSPORTING NO FIELDS
      WITH KEY low = '/PSYNG/MCUSER'.
      IF sy-subrc = 0.
*--collect only for mcuser table records
        LOOP AT lt_cdpos WHERE tabname = '/PSYNG/MCUSER'.
          lt_cdpos_tmp-objectclas = lt_cdpos-objectclas.
          lt_cdpos_tmp-objectid = lt_cdpos-objectid.
          lt_cdpos_tmp-changenr = lt_cdpos-changenr.
          lt_cdpos_tmp-tabkey = lt_cdpos-tabkey.
          APPEND lt_cdpos_tmp.
        ENDLOOP.
        IF NOT lt_cdpos_tmp[] IS INITIAL.
          SELECT keyguid  objectclas objectid
                  changenr tabname   tabkey
     INTO TABLE lt_cdpos_uid FROM (C_CDPOS_UID) "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
            FOR ALL ENTRIES IN lt_cdpos_tmp
              WHERE  objectclas  = lt_cdpos_tmp-objectclas
                   AND objectid  = lt_cdpos_tmp-objectid
                   AND changenr  = lt_cdpos_tmp-changenr
                   AND tabname   IN lr_mcusr_tab.

          LOOP AT lt_cdpos_uid.
            lt_cdpos-tabkey = lt_cdpos_uid-tabkey.
            MODIFY lt_cdpos TRANSPORTING tabkey
            WHERE tabkey  = lt_cdpos_uid-keyguid
                 AND tabname    = '/PSYNG/MCUSER'.
          ENDLOOP.
          free : lt_cdpos_tmp, lt_cdpos_uid.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
*-- HANA Comment : Cannot use Order by with For all entries
*ENDIF.
  APPEND LINES OF lt_cdhdr_rem TO lt_cdhdr.
  APPEND LINES OF lt_cdpos_rem TO lt_cdpos.
  SORT lt_cdhdr BY objectclas objectid changenr.
  SORT lt_cdpos BY objectclas objectid changenr.

  LOOP AT lt_cdpos.
    CLEAR lf_config_change.
    CASE lt_cdpos-tabname.
      WHEN '/PSYNG/SWSODVERS'.
        CHECK lt_cdpos-objectid(3) CO l_numcheck.
        CHECK lt_cdpos-objectid(3) IN s_vrsio.

        gt_output-tabname = 'Version Header'(026).
        gt_output-vrsio   = lt_cdpos-objectid(3).
        gt_output-object  = lt_cdpos-objectid(3).

      WHEN '/PSYNG/FUNCTION'.
        CHECK lt_cdpos-objectid(3) CO l_numcheck.
        CHECK lt_cdpos-objectid(3) IN s_vrsio.
        CHECK lt_cdpos-objectid+3  IN s_funct.

        gt_output-tabname = text-000.
        gt_output-vrsio   = lt_cdpos-objectid(3).
        gt_output-object  = lt_cdpos-objectid+3.

      WHEN '/PSYNG/FUNCTTRAN'.
        CHECK lt_cdpos-objectid(3) CO l_numcheck.
        CHECK lt_cdpos-objectid(3) IN s_vrsio.
        CHECK lt_cdpos-objectid+3  IN s_funct.

        gt_output-tabname = text-001.
        gt_output-vrsio   = lt_cdpos-objectid(3).
        gt_output-object  = lt_cdpos-objectid+3.

      WHEN '/PSYNG/FAOBJ2'.
        gt_output-tabname = text-002.
        SPLIT lt_cdpos-objectid AT '|' INTO TABLE lt_objid.

        CLEAR lt_objid.
        READ TABLE lt_objid INDEX 1.
        CHECK lt_objid IN s_funct.

        CLEAR lt_objid.
        READ TABLE lt_objid INDEX 8.
        CHECK lt_objid IN s_vrsio.
        gt_output-vrsio = lt_objid.

        gt_output-object = lt_cdpos-objectid.

      WHEN '/PSYNG/CONFLICT'.
        CHECK lt_cdpos-objectid(3) CO l_numcheck.
        CHECK lt_cdpos-objectid(3) IN s_vrsio.
        CHECK lt_cdpos-objectid+3  IN s_conid.

        gt_output-tabname = text-003.
        gt_output-vrsio   = lt_cdpos-objectid(3).
        gt_output-object  = lt_cdpos-objectid+3.

      WHEN '/PSYNG/CONFDET'.
        CHECK lt_cdpos-objectid(3) CO l_numcheck.
        CHECK lt_cdpos-objectid(3) IN s_vrsio.
        CHECK lt_cdpos-objectid+3  IN s_conid.

        gt_output-tabname = text-004.
        gt_output-vrsio   = lt_cdpos-objectid(3).
        gt_output-object  = lt_cdpos-objectid+3.

      WHEN '/PSYNG/CONOWNER'.
        CHECK lt_cdpos-objectid(3) CO l_numcheck.
        CHECK lt_cdpos-objectid(3) IN s_vrsio.
        CHECK lt_cdpos-objectid+3  IN s_conid.

        gt_output-tabname = text-005.
        gt_output-vrsio   = lt_cdpos-objectid(3).
        gt_output-object  = lt_cdpos-objectid+3.

      WHEN '/PSYNG/MCHDR'.

        CHECK lt_cdpos-objectid IN s_contid.
        gt_output-tabname = text-006.
        gt_output-object  = lt_cdpos-objectid.

      WHEN '/PSYNG/MCRVWHDR'.
        CHECK lt_cdpos-objectid IN s_contid.
        gt_output-tabname = text-024.
        gt_output-object  = lt_cdpos-objectid.

      WHEN '/PSYNG/MCAUDITOR'.
        CHECK lt_cdpos-objectid IN s_contid.
        gt_output-tabname = text-007.
        gt_output-object  = lt_cdpos-objectid.


      WHEN '/PSYNG/MCTRAN'.
        CHECK lt_cdpos-objectid IN s_contid.
        gt_output-tabname = text-008.
        gt_output-object  = lt_cdpos-objectid.


      WHEN '/PSYNG/MCREPID'.
        CHECK lt_cdpos-objectid IN s_contid.
        gt_output-tabname = text-009.
        gt_output-object  = lt_cdpos-objectid.

      WHEN '/PSYNG/MCUSER'.
        CHECK lt_cdpos-objectid IN s_contid.
        CHECK lt_cdpos-tabkey+15(12) IN s_mconid.
        CHECK lt_cdpos-tabkey+27(12) IN s_userid.
        CHECK lt_cdpos-tabkey+39(3) CO l_numcheck.
        CHECK lt_cdpos-tabkey+39(3) IN s_vrsio.

        gt_output-tabname = text-010.
        gt_output-object  = lt_cdpos-objectid.
        gt_output-vrsio   = lt_cdpos-tabkey+39(3).

      WHEN '/PSYNG/MCUSRGRP'.
        CHECK lt_cdpos-objectid IN s_contid.
        CHECK lt_cdpos-tabkey+15(12) IN s_mconid.
        CHECK lt_cdpos-tabkey+27(12) IN s_class.
        CHECK lt_cdpos-tabkey+39(3) CO l_numcheck.
        CHECK lt_cdpos-tabkey+39(3) IN s_vrsio.

        gt_output-tabname = text-011.
        gt_output-object  = lt_cdpos-objectid.
        gt_output-vrsio   = lt_cdpos-tabkey+39(3).

      WHEN '/PSYNG/MCCAUSER'.
        CHECK lt_cdpos-objectid IN s_contid.
        CHECK lt_cdpos-tabkey+15(12) IN s_audid.
        CHECK lt_cdpos-tabkey+27(12) IN s_auser.
        CHECK lt_cdpos-tabkey+39(3) CO l_numcheck.
        CHECK lt_cdpos-tabkey+39(3) IN s_vrsio.

        gt_output-tabname = text-022.
        gt_output-object  = lt_cdpos-objectid.
        gt_output-vrsio   = lt_cdpos-tabkey+39(3).

      WHEN '/PSYNG/MCCAROLE'.
        CHECK lt_cdpos-objectid IN s_contid.
        CHECK lt_cdpos-tabkey+15(12) IN s_caid.
        CHECK lt_cdpos-tabkey+27(30) IN s_carole.
        CHECK lt_cdpos-tabkey+57(3) CO l_numcheck.
        CHECK lt_cdpos-tabkey+39(3) IN s_vrsio.

        gt_output-tabname = text-023.
        gt_output-object  = lt_cdpos-objectid.
        gt_output-vrsio   = lt_cdpos-tabkey+39(3).

      WHEN '/PSYNG/MCROLE'.
        CHECK lt_cdpos-objectid IN s_contid.
        CHECK lt_cdpos-tabkey+15(12) IN s_mconid.
        CHECK lt_cdpos-tabkey+27(30) IN s_role.
        CHECK lt_cdpos-tabkey+57(3) CO l_numcheck.
        CHECK lt_cdpos-tabkey+57(3) IN s_vrsio.

        gt_output-tabname = text-013.
        gt_output-object  = lt_cdpos-objectid.
        gt_output-vrsio   = lt_cdpos-tabkey+57(3).

      WHEN '/PSYNG/SWAUDHDR'.
        CHECK lt_cdpos-objectid(3) CO l_numcheck.
        CHECK lt_cdpos-objectid(3) IN s_vrsio.
        CHECK lt_cdpos-objectid+3  IN s_cauth.

        gt_output-tabname = text-017.
        gt_output-vrsio   = lt_cdpos-objectid(3).
        gt_output-object  = lt_cdpos-objectid+3.

      WHEN '/PSYNG/SWAUDC2'.
*Begin of Addition:HBHALLA(PN-5886)(13/02/26)
  IF lt_cdpos-objectclas = '/PSYNG/SWAUDC'.
        CLEAR lt_parts[].
        SPLIT lt_cdpos-objectid AT '|' INTO TABLE lt_parts.

        DESCRIBE TABLE lt_parts LINES lv_lines.

        IF lv_lines > 0.
          READ TABLE lt_parts INTO lv_value INDEX lv_lines.
          READ TABLE lt_parts INTO lv_cauth INDEX 1.
        ENDIF.

        lv_len = strlen( lt_cdpos-objectid ) - 3.

        CHECK lv_value CO l_numcheck.
        CHECK lv_value IN s_vrsio.
        CHECK lv_cauth IN s_cauth.


        gt_output-tabname = text-018.
        gt_output-vrsio   = lv_value.
        gt_output-object  = lt_cdpos-objectid(lv_len).

  ELSE.
*End of Addition:HBHALLA(PN-5886)(13/02/26)
        CHECK lt_cdpos-objectid(3) CO l_numcheck.
        CHECK lt_cdpos-objectid(3) IN s_vrsio.
        CHECK lt_cdpos-objectid+3  IN s_cauth.

        gt_output-tabname = text-018.
        gt_output-vrsio   = lt_cdpos-objectid(3).
        gt_output-object  = lt_cdpos-objectid+3.
  ENDIF. "(++)HBHALLA(PN-5886)(13/02/26)


      WHEN '/PSYNG/CRITCODES'.
        CHECK lt_cdpos-objectid(3) CO l_numcheck.
        CHECK lt_cdpos-objectid(3) IN s_vrsio.
        CHECK lt_cdpos-objectid+3  IN s_ctcode.

        gt_output-tabname = text-019.
        gt_output-vrsio   = lt_cdpos-objectid(3).
        gt_output-object  = lt_cdpos-objectid+3.

      WHEN '/PSYNG/CRIROLES'.
        CHECK lt_cdpos-objectid(3) CO l_numcheck.
        CHECK lt_cdpos-objectid(3) IN s_vrsio.
        CHECK lt_cdpos-objectid+3  IN s_crole.

        gt_output-tabname = text-020.
        gt_output-vrsio   = lt_cdpos-objectid(3).
        gt_output-object  = lt_cdpos-objectid+3.

      WHEN '/PSYNG/CRIPROF'.
        CHECK lt_cdpos-objectid(3) CO l_numcheck.
        CHECK lt_cdpos-objectid(3) IN s_vrsio.
        CHECK lt_cdpos-objectid+3  IN s_cprof.

        gt_output-tabname = text-021.
        gt_output-vrsio   = lt_cdpos-objectid(3).
        gt_output-object  = lt_cdpos-objectid+3.

      WHEN '/PSYNG/SWCONFIG'.
        CHECK lt_cdpos-objectid IN s_param.
        gt_output-tabname = 'Configuration Parameter'(025).
        gt_output-object  = lt_cdpos-objectid.
        lf_config_change  = 'X'.
    ENDCASE.

    CASE lt_cdpos-chngind.
      WHEN 'I' OR 'J'.
        gt_output-chngind = 'Insert'(014).
      WHEN 'D' OR 'E'.
        gt_output-chngind = 'Delete'(015).
      WHEN 'U'.
        gt_output-chngind = 'Update'(016).
    ENDCASE.

    READ TABLE lt_cdhdr WITH KEY objectclas = lt_cdpos-objectclas
                                 objectid   = lt_cdpos-objectid
                                 changenr   = lt_cdpos-changenr
                        BINARY SEARCH.

    gt_output-username = lt_cdhdr-username.
    gt_output-udate    = lt_cdhdr-udate.
    gt_output-utime    = lt_cdhdr-utime.
    gt_output-tabkey   = lt_cdpos-tabkey.
    gt_output-fname    = lt_cdpos-fname.
    gt_output-val_old  = lt_cdpos-value_old.
    gt_output-val_new  = lt_cdpos-value_new.

    PERFORM get_field_desc USING lt_cdpos-tabname
                                 lt_cdpos-fname
                                CHANGING gt_output-field_desc.
    PERFORM get_username USING gt_output-username
                               lf_config_change
                               CHANGING gt_output-userfull.
    APPEND gt_output.
    CLEAR gt_output.
  ENDLOOP.
ENDFORM.                    " get_data

*&---------------------------------------------------------------------*
*&      Form  get_field_desc
*&---------------------------------------------------------------------*
*       Get field description
*----------------------------------------------------------------------*
FORM get_field_desc USING   i_tabname TYPE cdpos-tabname
                            i_fname TYPE cdpos-fname
                   CHANGING e_ftext TYPE dd04t-ddtext.
  TYPES: BEGIN OF typ_fld,
           tabname TYPE cdpos-tabname,
           fname   TYPE cdpos-fname,
           ftext   TYPE dd04t-ddtext,
         END OF typ_fld.

  STATICS: lt_fld TYPE HASHED TABLE OF typ_fld
                  WITH UNIQUE KEY tabname fname
                  WITH HEADER LINE.


  CLEAR e_ftext.
  READ TABLE lt_fld WITH TABLE KEY tabname = i_tabname
                                   fname   = i_fname.
  IF sy-subrc = 0.
    e_ftext = lt_fld-ftext.
    EXIT.
  ENDIF.

* First, check if text was defined locally on the table
  SELECT SINGLE ddtext INTO e_ftext FROM dd03t       "#EC CI_SEL_NESTED
                WHERE tabname    = i_tabname
                  AND ddlanguage = sy-langu
                  AND as4local   = 'A'
                  AND fieldname  = i_fname."#EC SAST_CI_GEN_CHECK

  IF sy-subrc <> 0.
*   Next, check the data element
    SELECT SINGLE dd04t~ddtext INTO e_ftext          "#EC CI_SEL_NESTED
             FROM dd03l INNER JOIN dd04t
               ON dd03l~rollname = dd04t~rollname
              AND dd03l~as4local = dd04t~as4local
            WHERE dd03l~tabname    = i_tabname
              AND dd03l~fieldname  = i_fname
              AND dd03l~as4local   = 'A'
              AND dd04t~ddlanguage = sy-langu."#EC SAST_CI_GEN_CHECK
  ENDIF.

  CHECK sy-subrc = 0.

  lt_fld-tabname = i_tabname.
  lt_fld-fname   = i_fname.
  lt_fld-ftext  = e_ftext.
  INSERT TABLE lt_fld.
ENDFORM.                    " get_field_desc

*---------------------------------------------------------------------*
*       FORM get_username                                             *
*---------------------------------------------------------------------*
*       Get user's full name
*---------------------------------------------------------------------*
FORM get_username USING    i_bname TYPE cdhdr-username
                           if_config_change TYPE flag
                  CHANGING e_name_text TYPE adrp-name_text.
  TYPES: BEGIN OF typ_user,
           bname     TYPE cdhdr-username,
           name_text TYPE adrp-name_text,
         END OF typ_user.

  STATICS: lt_user TYPE HASHED TABLE OF typ_user WITH UNIQUE KEY bname
                   WITH HEADER LINE.

  DATA: lt_uidn TYPE TABLE OF /psyng/bc_uidn WITH HEADER LINE.

  RANGES: lt_bname FOR /psyng/bc_uidn-bname.


  CLEAR e_name_text.
  READ TABLE lt_user WITH TABLE KEY bname = i_bname.
  IF sy-subrc = 0.
    e_name_text = lt_user-name_text.
    EXIT.
  ENDIF.

  lt_bname-sign   = 'I'.
  lt_bname-option = 'EQ'.
  lt_bname-low    = i_bname.
  APPEND lt_bname.
  IF NOT if_config_change IS INITIAL.
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



    CALL FUNCTION '/PSYNG/BC_011'
      DESTINATION p_system
         TABLES
              it_bname = lt_bname
              et_uidn  = lt_uidn
   EXCEPTIONS
     system_failure        = 1
     communication_failure = 2
     OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc NE 0.
*Raise error
    ENDIF.
  ELSE.
    CALL FUNCTION '/PSYNG/BC_011'
         TABLES
              it_bname = lt_bname
              et_uidn  = lt_uidn.
  ENDIF.

  SORT lt_uidn BY bname.
  READ TABLE lt_uidn INDEX 1 TRANSPORTING name_text.
  CHECK sy-subrc = 0.

  e_name_text       = lt_uidn-name_text.
  lt_user-bname     = i_bname.
  lt_user-name_text = e_name_text.
  INSERT TABLE lt_user.
ENDFORM.                    " get_username

*&---------------------------------------------------------------------*
*&      Form  output_screen
*&---------------------------------------------------------------------*
*       Output to screen
*----------------------------------------------------------------------*
FORM output_screen.
  DATA: l_repid     LIKE sy-repid,
        ls_layout   TYPE slis_layout_alv,
        ls_variant  LIKE disvariant.
  DATA: lt_excluding TYPE slis_t_extab,
        ls_excluding TYPE slis_extab.


  l_repid = sy-repid.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name         = l_repid
            i_internal_tabname     = 'GT_OUTPUT'
            i_inclname             = l_repid
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

  PERFORM prepare_fieldcat.
  PERFORM sort_order.

*--Exclude unneeded buttons
  ls_excluding-fcode = '&INFO'.
  APPEND ls_excluding TO lt_excluding.

  ls_layout-zebra             = 'X'.
  ls_layout-colwidth_optimize = 'X'.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            is_layout     = ls_layout
            it_fieldcat   = gt_fieldcat
            it_excluding  = lt_excluding
            it_sort       = gt_sort
            i_save        = 'A'
            is_variant    = ls_variant
       TABLES
            t_outtab      = gt_output
       EXCEPTIONS
            program_error = 1
            OTHERS        = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " output_screen

*&---------------------------------------------------------------------*
*&      Form  prepare_fieldcat
*&---------------------------------------------------------------------*
*       Prepare field category for ALV
*----------------------------------------------------------------------*
FORM prepare_fieldcat.
  DATA: ls_fieldcat TYPE slis_fieldcat_alv.


  ls_fieldcat-seltext_l    = text-h01.
  ls_fieldcat-seltext_m    = text-h01.
  ls_fieldcat-seltext_s    = text-h01.
  ls_fieldcat-reptext_ddic = text-h01.
  MODIFY gt_fieldcat FROM ls_fieldcat
                     TRANSPORTING seltext_l seltext_m seltext_s
                                  reptext_ddic
                     WHERE fieldname = 'TABNAME'.
  ls_fieldcat-seltext_l    = text-h02.
  ls_fieldcat-seltext_m    = text-h02.
  ls_fieldcat-seltext_s    = text-h02.
  ls_fieldcat-reptext_ddic = text-h02.
  MODIFY gt_fieldcat FROM ls_fieldcat
                     TRANSPORTING seltext_l seltext_m seltext_s
                                  reptext_ddic
                     WHERE fieldname = 'CHNGIND'.

  ls_fieldcat-seltext_l    = text-h03.
  ls_fieldcat-seltext_m    = text-h03.
  ls_fieldcat-seltext_s    = text-h03.
  ls_fieldcat-reptext_ddic = text-h03.
  MODIFY gt_fieldcat FROM ls_fieldcat
                     TRANSPORTING seltext_l seltext_m seltext_s
                                  reptext_ddic
                     WHERE fieldname = 'USERNAME'.

  ls_fieldcat-seltext_l    = text-h04.
  ls_fieldcat-seltext_m    = text-h04.
  ls_fieldcat-seltext_s    = text-h04.
  ls_fieldcat-reptext_ddic = text-h04.
  MODIFY gt_fieldcat FROM ls_fieldcat
                     TRANSPORTING seltext_l seltext_m seltext_s
                                  reptext_ddic
                     WHERE fieldname = 'USERFULL'.
ENDFORM.                    " prepare_fieldcat

*&---------------------------------------------------------------------*
*&      Form  sort_order
*&---------------------------------------------------------------------*
*       Add sort order to initial screen
*----------------------------------------------------------------------*
FORM sort_order.
  DATA: ls_sort TYPE slis_sortinfo_alv.


  ls_sort-spos      = '1'.
  ls_sort-tabname   = 'GT_OUTPUT'.
  ls_sort-fieldname = 'TABNAME'.
  ls_sort-up        = 'X'.
  APPEND ls_sort TO gt_sort.

ENDFORM.                    " sort_order
*&---------------------------------------------------------------------*
*&      Form  assigned_user_f4_help
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_CUSER  text
*----------------------------------------------------------------------*
FORM assigned_user_f4_help CHANGING p_s_cuser TYPE /psyng/user-userid .
  DATA: BEGIN OF lt_mcuser OCCURS 0,
        userid TYPE /psyng/user-userid,
        END OF lt_mcuser.
  DATA: lt_return TYPE STANDARD TABLE OF ddshretval,
        wa_return LIKE LINE OF lt_return.
  SELECT userid FROM /psyng/user INTO TABLE lt_mcuser.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
*   DDIC_STRUCTURE         = 'EKKO'
      retfield               = 'USERID'
*   PVALKEY                = ' '
*  dynpprog               = sy-repid
*  dynpnr                 = sy-dynnr
*   DYNPROFIELD            = 'EBELN'
*   STEPL                  = 0
      window_title           = 'User ID'
*   VALUE                  = ' '
      value_org              = 'S'
*    MULTIPLE_CHOICE        = 'X'
*   DISPLAY                = ' '
*   CALLBACK_PROGRAM       = ' '
*   CALLBACK_FORM          = ' '
*   MARK_TAB               =
* IMPORTING
*   USER_RESET             = ld_ret
    TABLES
      value_tab              = lt_mcuser
*    FIELD_TAB              = lt_fields
      return_tab             = lt_return
*   DYNPFLD_MAPPING        =
   EXCEPTIONS
     parameter_error        = 1
     no_values_found        = 2
     OTHERS                 = 3.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

  READ TABLE lt_return INTO wa_return INDEX 1.
  p_s_cuser = wa_return-fieldval.
ENDFORM.                    " assigned_user_f4_help
*&---------------------------------------------------------------------*
*&      Form  RFC_VALIDATIONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM rfc_validations .
  DATA: lt_rfcs    TYPE TABLE OF /psyng/sw_sel_opts_rfcdest,
        ls_rfcs    TYPE /psyng/sw_sel_opts_rfcdest.
  DATA: lt_ret TYPE TABLE OF bapiret2,
        ls_ret TYPE bapiret2.
  ls_rfcs-sign   = 'I'.
  ls_rfcs-option = 'EQ'.
  ls_rfcs-low    = p_system.

  APPEND ls_rfcs TO lt_rfcs.
*--Validate RFC Destinations
  CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
    EXPORTING
      i_popup   = 'N'
      i_module  = 'SE'
    TABLES
      it_rfcdes = lt_rfcs
      et_return = lt_ret.

  IF NOT lt_ret IS INITIAL.
    READ TABLE lt_ret INTO ls_ret INDEX 1.
    MESSAGE s002(/psyng/sw) WITH ls_ret-message.
    LEAVE LIST-PROCESSING.
  ENDIF.

ENDFORM.
