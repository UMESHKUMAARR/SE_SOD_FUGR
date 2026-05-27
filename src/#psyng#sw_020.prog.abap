*----------------------------------------------------------------------*
* Report  /PSYNG/SW_020                                                *
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

REPORT /psyng/sw_020 LINE-SIZE 200.
INCLUDE /PSYNG/SW_CONFIG.
TABLES: agr_define, /psyng/rolehdr.
TYPE-POOLS: slis.                                      "For ALV call

TYPES: BEGIN OF t_text,
         roleid LIKE /psyng/rolehdr-roleid,
         line LIKE /psyng/texts-line,
         text LIKE /psyng/texts-text,
       END OF t_text.

DATA: gs_program         LIKE sy-repid.                   "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call

DATA: g_currentrid TYPE /psyng/rolehdr-roleid,
      g_ridcounter(12) TYPE n VALUE '000000000000',
      g_ridlen TYPE i,
      g_maxsroles(12) TYPE n, "max single roles
      g_currentrid1 TYPE /psyng/rolehdr-roleid.


DATA: g_keepgoing VALUE 'Y'.

DATA: BEGIN OF output OCCURS 10,
        agr_name LIKE agr_define-agr_name,
        tcode TYPE tcode,
        roleid LIKE /psyng/rolehdr-roleid,
        rolecr,
        rolehdr,
        roletc,
        roletxt,
        message(100),
      END OF output.

DATA: gt_irolehdr TYPE STANDARD TABLE OF /psyng/rolehdr WITH HEADER LINE
,
      gt_iroletrans TYPE STANDARD TABLE OF /psyng/roletrans
                 WITH HEADER LINE,
      itexts TYPE STANDARD TABLE OF /psyng/texts WITH HEADER LINE.

DATA: BEGIN OF urolehdr OCCURS 0,
        roleid LIKE /psyng/rolehdr-roleid,
        description LIKE /psyng/rolehdr-description,
        owner LIKE /psyng/rolehdr-owner,
        approval LIKE /psyng/rolehdr-approval,
        importance LIKE /psyng/rolehdr-importance,
        project LIKE /psyng/rolehdr-project,
        rolemodule LIKE /psyng/rolehdr-rolemodule,
        saptechname LIKE /psyng/rolehdr-saptechname,
        status LIKE /psyng/rolehdr-status,
      END OF urolehdr.

DATA: BEGIN OF uroletrans OCCURS 0,
        roleid LIKE /psyng/rolehdr-roleid,
        tcode LIKE sy-tcode,
      END OF uroletrans.


DATA: gt_uroletext TYPE TABLE OF t_text WITH HEADER LINE,
      gt_roletextsod TYPE TABLE OF t_text WITH HEADER LINE.

DATA: g_file_path LIKE rlgrap-filename,
      flag_upld_r_dwld,
      gs_swconfig_import_der TYPE /psyng/swconfig.


DATA:  g_rolexits,
       g_conf,
       g_rcdno TYPE i,
       g_ridgen TYPE c.
DATA: gv_spl(20) TYPE c VALUE '~!@#$%_*'.
SELECTION-SCREEN: BEGIN OF BLOCK a1 WITH FRAME TITLE text-121.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: upagr RADIOBUTTON GROUP a  DEFAULT 'X' USER-COMMAND check.
SELECTION-SCREEN COMMENT 3(21) text-007 FOR FIELD upagr.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: upfile RADIOBUTTON GROUP a.
SELECTION-SCREEN COMMENT 3(21) text-005 FOR FIELD upfile.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: downrole RADIOBUTTON GROUP a.
SELECTION-SCREEN COMMENT 3(31) text-003 FOR FIELD downrole.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK a1.

SELECTION-SCREEN: BEGIN OF BLOCK 1st WITH FRAME TITLE text-009.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: POSITION 25.
SELECT-OPTIONS: proles FOR agr_define-agr_name MODIF ID r1 .
SELECTION-SCREEN COMMENT 3(21) text-122 FOR FIELD proles MODIF ID r1.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(23) text-008 FOR FIELD ucrid  MODIF ID r1.
SELECTION-SCREEN: POSITION 28.
PARAMETERS: ucrid(12) MODIF ID r1.          "Role ID Prefix
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(24) text-123 FOR FIELD n_gn  MODIF ID r1.
PARAMETER: n_gn TYPE /psyng/role_id MODIF ID r1.

SELECTION-SCREEN PUSHBUTTON  45(10) text-124
                              USER-COMMAND scjb MODIF ID r1.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(60) text-010  MODIF ID r1.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_der AS CHECKBOX  MODIF ID r1.
SELECTION-SCREEN COMMENT 3(40) text-120 FOR FIELD p_der  MODIF ID r1.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(25) text-101 FOR FIELD rb_nrol  MODIF ID r1.
PARAMETERS : rb_nrol RADIOBUTTON GROUP rb1 MODIF ID r1.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(25) text-102 FOR FIELD rb_orol MODIF ID r1.
PARAMETERS : rb_orol RADIOBUTTON GROUP rb1 MODIF ID r1.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: SKIP 1.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_tstrun AS CHECKBOX MODIF ID r1.
SELECTION-SCREEN COMMENT 3(40) text-103 FOR FIELD p_tstrun MODIF ID r1.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK 1st.

SELECTION-SCREEN: BEGIN OF BLOCK 2nd WITH FRAME TITLE text-009.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(60) text-011 MODIF ID r2.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(21) text-004 MODIF ID r2.
SELECTION-SCREEN: POSITION 25.
PARAMETER: urhfile LIKE rlgrap-filename DEFAULT
                      'C:\TEMP\swroles\UP_Roles_Header.txt' LOWER CASE
MODIF ID r2.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(21) text-001 MODIF ID r2.
SELECTION-SCREEN: POSITION 25.
PARAMETER: urtfile LIKE rlgrap-filename DEFAULT
                      'C:\TEMP\swroles\UP_Roles_Tcodes.txt' LOWER CASE
MODIF ID r2.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(22) text-002 MODIF ID r2.
SELECTION-SCREEN: POSITION 25.
PARAMETER: urxfile LIKE rlgrap-filename DEFAULT
                      'C:\TEMP\swroles\UP_Roles_Texts.txt' LOWER CASE
MODIF ID r2.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(21) text-082 MODIF ID r2.
SELECTION-SCREEN: POSITION 25.
PARAMETER: urxfile2 LIKE rlgrap-filename DEFAULT
                    'C:\TEMP\swroles\UP_Roles_Texts_SOD.txt' LOWER CASE
MODIF ID r2.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: POSITION 3.
PARAMETER: p_ovrwrt  AS CHECKBOX MODIF ID r2.
SELECTION-SCREEN COMMENT 6(40) text-081 FOR FIELD p_ovrwrt MODIF ID r2.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: POSITION 3.
PARAMETER: testrun AS CHECKBOX DEFAULT 'X' MODIF ID r2.
SELECTION-SCREEN COMMENT 6(40) text-012 FOR FIELD testrun MODIF ID r2.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 1.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(23) text-008 FOR FIELD ucrid1  MODIF ID r2.
SELECTION-SCREEN: POSITION 28.
PARAMETERS: ucrid1(12) MODIF ID r2.          "Role ID Prefix
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(24) text-123 FOR FIELD n_gn1  MODIF ID r2.
PARAMETER: n_gn1 TYPE /psyng/role_id MODIF ID r2.

SELECTION-SCREEN PUSHBUTTON  45(10) text-124
                              USER-COMMAND scjb MODIF ID r2.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: END OF BLOCK 2nd.

SELECTION-SCREEN: BEGIN OF BLOCK 3rd WITH FRAME TITLE text-009.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(21) text-000 MODIF ID r3.
SELECTION-SCREEN: POSITION 22.
SELECT-OPTIONS: droleids FOR /psyng/rolehdr-roleid MODIF ID r3.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(21) text-004 MODIF ID r3.
SELECTION-SCREEN: POSITION 25.
PARAMETER: drhfile LIKE rlgrap-filename DEFAULT
                   'C:\TEMP\swroles\Down_Roles_Header.txt' LOWER CASE
MODIF ID r3.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(21) text-001 MODIF ID r3.
SELECTION-SCREEN: POSITION 25.
PARAMETER: drtfile LIKE rlgrap-filename DEFAULT
                     'C:\TEMP\swroles\Down_Roles_Tcodes.txt' LOWER CASE
MODIF ID r3.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(22) text-002 MODIF ID r3.
SELECTION-SCREEN: POSITION 25.
PARAMETER: drxfile LIKE rlgrap-filename DEFAULT
                     'C:\TEMP\swroles\Down_Roles_Texts.txt' LOWER CASE
MODIF ID r3.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(21) text-082 MODIF ID r3.
SELECTION-SCREEN: POSITION 25.
PARAMETER: drxfile2 LIKE rlgrap-filename DEFAULT
                  'C:\TEMP\swroles\Down_Roles_Texts_SOD.txt' LOWER CASE
MODIF ID r3.
SELECTION-SCREEN: END OF LINE.

*SELECTION-SCREEN: END OF BLOCK 1st.
SELECTION-SCREEN: END OF BLOCK 3rd.


*27-08-2008 TSEN INSERT BEGIN
************************** Value request*****************
AT SELECTION-SCREEN ON VALUE-REQUEST FOR urhfile.
  MOVE 'C:\TEMP\swroles\UP_Roles_Header.txt' TO g_file_path.
  flag_upld_r_dwld = 'X'.
  PERFORM file_select CHANGING urhfile g_file_path flag_upld_r_dwld.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR urtfile.
  MOVE 'C:\TEMP\swroles\UP_Roles_Tcodes.txt' TO g_file_path.
  flag_upld_r_dwld = 'X'.
  PERFORM file_select CHANGING urtfile g_file_path flag_upld_r_dwld.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR urxfile.
  MOVE 'C:\TEMP\swroles\UP_Roles_Texts.txt' TO g_file_path.
  flag_upld_r_dwld = 'X'.
  PERFORM file_select CHANGING urxfile g_file_path flag_upld_r_dwld.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR urxfile2.
  MOVE 'C:\TEMP\swroles\UP_Roles_Texts_SOD.txt' TO g_file_path.
  flag_upld_r_dwld = 'X'.
  PERFORM file_select CHANGING urxfile2 g_file_path flag_upld_r_dwld.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR drhfile.
  MOVE 'C:\TEMP\swroles\Down_Roles_Header.txt' TO g_file_path.
  CLEAR flag_upld_r_dwld .
  PERFORM file_select CHANGING drhfile g_file_path flag_upld_r_dwld.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR drtfile.
  MOVE 'C:\TEMP\swroles\Down_Roles_Tcodes.txt' TO g_file_path.
  CLEAR flag_upld_r_dwld .
  PERFORM file_select CHANGING drtfile g_file_path flag_upld_r_dwld.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR drxfile.
  MOVE 'C:\TEMP\swroles\Down_Roles_Texts.txt' TO g_file_path.
  CLEAR flag_upld_r_dwld .
  PERFORM file_select CHANGING drxfile g_file_path flag_upld_r_dwld.
*27-08-2008. INSET END tsen

AT SELECTION-SCREEN ON VALUE-REQUEST FOR drxfile2.
  MOVE 'C:\TEMP\swroles\Down_Roles_Texts_SOD.txt' TO g_file_path.
  CLEAR flag_upld_r_dwld.
  PERFORM file_select CHANGING drxfile2 g_file_path flag_upld_r_dwld.

************************************************************************
*   DECLARATION F1 HELP FOR SELECTION SCREEN FIELDS
************************************************************************
* For field Role ID Prefix
AT SELECTION-SCREEN ON HELP-REQUEST FOR ucrid.

  PERFORM show_help USING '/PSYNG/SW_020_UCRID'.


* For Radio button Create NewRole ID
AT SELECTION-SCREEN ON HELP-REQUEST FOR rb_nrol.

  PERFORM show_help USING '/PSYNG/SW_020_CREATEROLE'.

* For Radio button Overwrite existing Role ID
AT SELECTION-SCREEN ON HELP-REQUEST FOR rb_orol.

  PERFORM show_help USING '/PSYNG/SW_020_OVERWRITEROLE'.

* For Check Box Test Run
AT SELECTION-SCREEN ON HELP-REQUEST FOR p_tstrun.

  PERFORM show_help USING '/PSYNG/SW_020_TESTRUN'.

** For Radio button Upload files
AT SELECTION-SCREEN ON HELP-REQUEST FOR upfile.

  PERFORM show_help USING '/PSYNG/SW_020_UPFILE'.

* For Check box Overwrite Role
AT SELECTION-SCREEN ON HELP-REQUEST FOR p_ovrwrt.

  PERFORM show_help USING '/PSYNG/SW_020_P_OVRWRT'.

* For Check box Test Run
AT SELECTION-SCREEN ON HELP-REQUEST FOR testrun.

  PERFORM show_help USING '/PSYNG/SW_020_TESTRUN'.

** For Radio button Download files
AT SELECTION-SCREEN ON HELP-REQUEST FOR downrole.

  PERFORM show_help USING '/PSYNG/SW_020_DOWNROLE'.
************************************************************************

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'R1'.
        IF upagr NE 'X'.
          screen-input = '0'.
          screen-output = '0'.
          screen-invisible = '1'.
          MODIFY SCREEN.
        ENDIF.
      WHEN 'R2'.
        IF upfile NE 'X'.
          screen-input = '0'.
          screen-output = '0'.
          screen-invisible = '1'.
          MODIFY SCREEN.
        ENDIF.
      WHEN 'R3'.
        IF downrole NE 'X'.
          screen-input = '0'.
          screen-output = '0'.
          screen-invisible = '1'.
          MODIFY SCREEN.
        ENDIF.
    ENDCASE.
  ENDLOOP.
  IF upfile = 'X'.
    LOOP AT SCREEN.
      IF screen-group1 = 'R2'.
        IF screen-name = 'UCRID1' OR screen-name = 'N_GN1'
                    OR screen-name = '%F008088_1000'
                    OR screen-name = '%F123093_1000'
                    OR screen-group3 = 'PBU'.
          screen-input = '0'.
          screen-output = '0'.
          screen-invisible = 1.
          MODIFY SCREEN.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.
* 24/01/2018.

INITIALIZATION.
  se_config_param 'ROLES_IMP_DERIVED' gs_swconfig_import_der-value.
  IF gs_swconfig_import_der-value = 'Y'.
    LOOP AT SCREEN.
      IF screen-name = 'P_DER'.
        screen-invisible = 0.
        screen-input = 1.
        MODIFY SCREEN.
      ELSEIF screen-name = '%C010012_1000'.
        screen-invisible = 1.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ELSE.
    LOOP AT SCREEN.
      IF screen-name = 'P_DER'.
        screen-invisible = 1.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.
************************* AT SELECTION-SCREEN***************************
AT SELECTION-SCREEN.
  IF upagr = 'X'.
    g_currentrid = ucrid.
    CALL FUNCTION '/PSYNG/SW_CHECK_SWROLE_EXISTS'
         EXPORTING
              proleid = ucrid
         IMPORTING
              exists  = g_rolexits.

  ENDIF.

  IF sy-ucomm EQ 'SCJB'.
    IF upagr = 'X'.
      IF ucrid IS INITIAL.
        MESSAGE i113(/psyng/sw) WITH text-125.
      ELSE.
        PERFORM f_get_number.
      ENDIF.
    ELSEIF upfile = 'X'.
      IF ucrid1 IS INITIAL.
        MESSAGE i113(/psyng/sw) WITH text-125.
      ELSE.
        PERFORM f_get_number.
      ENDIF.

    ENDIF.

  ENDIF.



************************************************************************
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
  gs_program = sy-repid.

  IF upagr = 'X'.
    PERFORM import_from_pfcg.
    PERFORM build_alv_catalog.
    PERFORM output_using_alv.
  ELSEIF upfile = 'X'.
    PERFORM import_from_file.
    IF testrun = 'X'.
      CHECK g_keepgoing = 'Y'.
    ENDIF.
    PERFORM build_alv_catalog.
    PERFORM output_using_alv.

  ELSEIF downrole = 'X'.
    PERFORM download_roles.
  ENDIF.

*&---------------------------------------------------------------------*
*&      Form  show_help
*&---------------------------------------------------------------------*
*       Show f1 help for fields
*----------------------------------------------------------------------*
*      -->I_DOKNAME  Document name
*----------------------------------------------------------------------*
FORM show_help USING    i_dokname.

  CALL FUNCTION '/PSYNG/BASIS_F1_HELP'
       EXPORTING
            dokname = i_dokname.

ENDFORM.                    " show_help


*&---------------------------------------------------------------------*
*&      Form  import_from_pfcg
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM import_from_pfcg.
  DATA: iagr_define TYPE STANDARD TABLE OF agr_define WITH HEADER LINE.


  AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
           ID 'ACTVT' FIELD '60'
           ID 'Y&SW_ROLID' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  IF sy-subrc NE 0.
    MESSAGE e113(/psyng/sw) WITH text-013   .
    STOP.
  ENDIF.
* 23/01/2018.
  SELECT agr_name parent_agr FROM agr_define
           INTO CORRESPONDING FIELDS OF TABLE iagr_define
           WHERE agr_name IN proles.
  DESCRIBE TABLE iagr_define LINES g_rcdno.
* 23/01/2018.

  IF NOT ucrid IS INITIAL AND n_gn IS INITIAL.
    g_ridlen = strlen( ucrid ).
*DHORIONS 2012/1/20 : making this a little bit more
* dynamic
    g_maxsroles = ( 10  ** ( 12 - g_ridlen ) ) - 1.
    IF g_maxsroles = 0 .
      g_maxsroles = g_rcdno.
    ENDIF.
  ELSEIF NOT n_gn IS INITIAL AND ucrid IS INITIAL.
    g_ridlen = strlen( n_gn ).
    g_maxsroles = ( 10  ** ( 12 - g_ridlen ) ) - 1.
    IF g_maxsroles = 0 .
      g_maxsroles = g_rcdno.
    ENDIF.
  ELSEIF NOT ucrid IS INITIAL AND NOT n_gn IS INITIAL.
    g_ridlen = strlen( n_gn ).
    g_maxsroles = ( 10  ** ( 12 - g_ridlen ) ) - 1.
    IF g_maxsroles = 0 .
      g_maxsroles = g_rcdno.
    ENDIF.
  ENDIF.
*  IF g_rolexits = 'Y' AND rb_orol = 'X'.
*    IF g_rcdno > '1'.
*      MESSAGE e152(/psyng/sw).
*      LEAVE TO LIST-PROCESSING.
*    ENDIF.
*  ENDIF.

*   23/01/2018
***************************************
  SORT: iagr_define.
*Case 2326 : Composite roles that had no child roles were still included
  DATA : lt_roleinfo TYPE TABLE OF /psyng/sw_roleinfo WITH HEADER LINE.
  CONCATENATE sy-sysid sy-mandt INTO lt_roleinfo.
  LOOP AT  iagr_define.
    lt_roleinfo-agr_name = iagr_define-agr_name.
    APPEND lt_roleinfo.
  ENDLOOP.
  CALL FUNCTION '/PSYNG/SW_ROLE_INFO'
*   EXPORTING
*     I_SPRAS        = 'EN'
    TABLES
      it_roles       = lt_roleinfo.
*--filter out composite roles
  LOOP AT lt_roleinfo WHERE composite = 'X'.
    DELETE iagr_define WHERE agr_name = lt_roleinfo-agr_name.
  ENDLOOP.
* delete roles that are derived
  IF NOT gs_swconfig_import_der-value = 'Y'.
    DELETE iagr_define WHERE parent_agr <> ''.
  ELSE.
    IF p_der IS INITIAL.
      DELETE iagr_define WHERE parent_agr <> ''.
    ENDIF.
  ENDIF.
  LOOP AT iagr_define.
    IF g_ridcounter GT g_maxsroles AND g_ridgen <> 'Y'.
      MESSAGE i113(/psyng/sw) WITH text-014 g_maxsroles
                                   text-015.
      EXIT.
    ENDIF.
    PERFORM import_single_role USING iagr_define-agr_name.
  ENDLOOP.
ENDFORM.                    " import_from_pfcg
*&---------------------------------------------------------------------*
*&      Form  import_from_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM import_from_file.
  AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
           ID 'ACTVT' FIELD '60'
           ID 'Y&SW_ROLID' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  IF sy-subrc NE 0.
    MESSAGE e113(/psyng/sw) WITH text-013.
    STOP.
  ENDIF.

  PERFORM upload_files.
  SORT urolehdr.
  SORT uroletrans.
  SORT gt_uroletext BY roleid line.
  SORT gt_roletextsod BY roleid line.

*  CHECK g_keepgoing = 'Y'.

  IF ( uroletrans[] IS INITIAL )          "Continue if there no
    OR ( gt_uroletext[] IS INITIAL ) .    "transaction and/or role text
    PERFORM popup_ques_to_continue.       "data was not uploaded
  ENDIF.
  CHECK g_keepgoing = 'Y'.

*  CHECK testrun EQ ' '.
  PERFORM move_files_data_2_itabs.
  PERFORM create_sw_rolesids.
ENDFORM.                    " import_from_file

*&---------------------------------------------------------------------*
*&      Form  import_single_role
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IAGR_AGRS_CHILD_AGR  text
*----------------------------------------------------------------------*
FORM import_single_role USING    pagr_name.
  DATA: l_rid_exists,
        roleid_created,
        role_hdr_created,
        role_tc_added,
        role_txt_added,
        l_existing_roleid type /PSYNG/ROLE_ID,
        l_currentid type /PSYNG/ROLE_ID,
        lf_skip type flag,
        lf_overwritten type flag,
        l_prefixpattern type /psyng/role_id.
        concatenate  ucrid '%' into l_prefixpattern.

*--Check if this specific role already exists,
*  based on role name and prefix
  SELECT SINGLE roleid
  FROM /psyng/rolehdr
  INTO l_existing_roleid
  WHERE SAPTECHNAME = pagr_name and roleid like l_prefixpattern .
  if sy-subrc = 0.
*  --There is already an SW role for this PFCG role
*    If overwrite is selected, delete the role,
*    and recreate with the same ID
    l_currentid    = l_existing_roleid.
    if rb_orol = 'X'.
      lf_overwritten = 'X'.
      clear lf_skip.
    else.
*  If overwrite is not selected, skip this role
      lf_skip = 'X'.
    endif.
  else.
*--There is no SW role for this PFCG role yet, get a new ID
    l_rid_exists = 'Y'.
    WHILE l_rid_exists = 'Y' AND g_ridcounter LE g_maxsroles.
      PERFORM get_nextrid.
      CALL FUNCTION '/PSYNG/SW_CHECK_SWROLE_EXISTS'
           EXPORTING
                proleid = g_currentrid
           IMPORTING
                exists  = l_rid_exists.
    ENDWHILE.
    l_currentid = g_currentrid.
  endif.
  IF lf_skip <> 'X'.
    IF g_ridcounter GT g_maxsroles.
      g_ridgen = 'Y'.
      EXIT.
    ENDIF.
  CLEAR output.
  IF p_tstrun <> 'X'.
    CALL FUNCTION '/PSYNG/SW_CREATE_SWROLE_PFCG'
         EXPORTING
              pagr_name        = pagr_name
              proleid          = l_currentid
              ovrwrte          = rb_orol
         IMPORTING
              roleid_created   = roleid_created
              role_hdr_created = role_hdr_created
              role_tc_added    = role_tc_added
              role_txt_added   = role_txt_added
         EXCEPTIONS
              sw_role_exists   = 1
              not_authorized   = 2
              OTHERS           = 3.
    IF sy-subrc NE 0.
      CASE sy-subrc.
        WHEN 1.
          output-message = text-017.
        WHEN 2.
          output-message = text-018.
        WHEN 3.
          output-message = text-019.
      ENDCASE.
    ELSEIF ( g_rolexits  = 'Y' AND rb_orol = 'X' ).
      output-message = text-105.
    ELSE.
      output-message = text-020.
    ENDIF.
    else.
*--Messages for test mode
     if     lf_overwritten = 'X'.
      output-message = text-105.
     else.
      output-message = text-020.
     ENDIF.
    endif.
*  ELSE.
*    output-message = text-103.
  else.
    output-message = 'Role Exists, Not Overwritten'(115).
  endif.
*********************************************

  output-agr_name = pagr_name.
  output-roleid   = l_currentid.
  output-rolecr   = roleid_created.
  output-rolehdr  = role_hdr_created.
  output-roletc   = role_tc_added.
  output-roletxt  = role_txt_added.
  APPEND output.

ENDFORM.                    " import_single_role
*&---------------------------------------------------------------------*
*&      Form  get_nextrid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_nextrid.
  DATA : l_pos TYPE i,
         l_len TYPE i,
*         g_currentrid1 TYPE /psyng/rolehdr-roleid,
         num          TYPE i,
         lv_num       TYPE c,
         lv_num2      TYPE i,
         lv_zeros(20) TYPE c,
         lv_char      TYPE c,
         lv_char1(50) TYPE c,
         lv_num1(20)  TYPE c,
         lv_prelen    TYPE i,
         lv_zeroslen  TYPE i,
         lv_finallen  TYPE i.
  DATA : lv_flag TYPE /psyng/bapiflagx,
         lv_flag1 TYPE /psyng/bapiflagx.
  ADD 1 TO g_ridcounter.

*DHORIONS 2012/01/23 - Make this a little bit more dynamic
  l_pos = strlen( g_ridcounter ).
  l_len = l_pos - g_ridlen.

*adding a check for including prefix if given
  IF NOT n_gn IS INITIAL AND ucrid IS INITIAL.
    IF l_len EQ 0.
      g_currentrid = n_gn.
    ELSE.
      l_pos = l_pos - l_len.
      CONCATENATE n_gn g_ridcounter+l_pos(l_len) INTO g_currentrid.
    ENDIF.

  ELSEIF NOT ucrid IS INITIAL AND n_gn IS INITIAL.
    IF l_len EQ 0.
      g_currentrid = ucrid.
    ELSE.
      l_pos = l_pos - l_len.
      REPLACE '*' INTO ucrid WITH '0'.
      CONCATENATE ucrid g_ridcounter+l_pos(l_len) INTO g_currentrid.
    ENDIF.
  ELSEIF NOT ucrid IS INITIAL AND NOT n_gn IS INITIAL.
*    IF l_len EQ 0.
**    Changes for incrementing the n_gn
*      IF NOT g_currentrid1 IS INITIAL.
*      lv_flag1 = 'X'.
**      incrment counter
*      num = strlen( g_currentrid1 ).
*      DO num TIMES.
*        IF g_currentrid1(1) CA '0123456789'.
*          IF lv_flag IS INITIAL AND g_currentrid1(1) CA '0'.
*            CONCATENATE lv_zeros g_currentrid1(1) INTO lv_zeros.
*          ELSE.
*            lv_flag = 'X'.
*            MOVE g_currentrid1(1) TO lv_num.
*            CONCATENATE lv_num1 lv_num INTO lv_num1.
*            CONDENSE lv_num1 NO-GAPS.
*
*          ENDIF.
*        ELSE.
*          MOVE g_currentrid1(1) TO lv_char.
*          CONCATENATE lv_char1 lv_char INTO lv_char1.
*        ENDIF.
*        SHIFT g_currentrid1 LEFT CIRCULAR.
*      ENDDO.
*
*      ADD 1 TO lv_num1.
*      CONDENSE lv_num1.
*      CONCATENATE lv_zeros lv_num1 INTO lv_num1.
*      CONDENSE lv_num1 NO-GAPS.
*      CONCATENATE lv_char1 lv_num1 INTO g_currentrid1.
*      g_currentrid = g_currentrid1.
*  ENDIF.
*
*      increment counter ends
*      ELSEif g_currentrid1 is initial and lv_flag1 ne 'X' .

    IF g_currentrid1 IS INITIAL.

      g_currentrid1 = n_gn.

    ENDIF.



    num = strlen( g_currentrid1 ).
    DO num TIMES. "#EC PATHLOCK_CI_NO_DOS (HBHALLA)
      IF g_currentrid1(1) CA '0123456789'.
        IF lv_flag IS INITIAL AND g_currentrid1(1) CA '0'.
          CONCATENATE lv_zeros g_currentrid1(1) INTO lv_zeros.
        ELSE.
          lv_flag = 'X'.
          MOVE g_currentrid1(1) TO lv_num.
          CONCATENATE lv_num1 lv_num INTO lv_num1.
          CONDENSE lv_num1 NO-GAPS.

        ENDIF.
      ELSE.
        MOVE g_currentrid1(1) TO lv_char.
        CONCATENATE lv_char1 lv_char INTO lv_char1.
      ENDIF.
      SHIFT g_currentrid1 LEFT CIRCULAR.
    ENDDO.

*    23/01/2018.
    lv_prelen = strlen( lv_char1 ).
    lv_zeroslen = strlen( lv_zeros ).
    lv_finallen = lv_prelen + lv_zeroslen.
    IF lv_finallen = 12.
      SHIFT lv_zeros.
    ENDIF.
*    23/01/2018.

    ADD 1 TO lv_num1.
    CONDENSE lv_num1.
    CONCATENATE lv_zeros lv_num1 INTO lv_num1.
    CONDENSE lv_num1 NO-GAPS.
    CONCATENATE lv_char1 lv_num1 INTO g_currentrid1.
    g_currentrid = g_currentrid1.
*changes end
*    ENDIF.
  ELSE.
    l_pos = l_pos - l_len.
    CONCATENATE n_gn g_ridcounter+l_pos(l_len) INTO g_currentrid.
  ENDIF.





*  CASE ridlen.
*    WHEN 0.
*      CONCATENATE ucrid ridcounter+0(4) INTO currentrid.
*    WHEN 1.
*      CONCATENATE ucrid ridcounter+1(3) INTO currentrid.
*    WHEN 2.
*      CONCATENATE ucrid ridcounter+2(2) INTO currentrid.
*    WHEN 3.
*      CONCATENATE ucrid ridcounter+3(1) INTO currentrid.
*    WHEN OTHERS.
*      add 1 to currentrid.
*  ENDCASE.

ENDFORM.                    " get_nextrid

*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_catalog.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  gs_program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = gs_program
            i_internal_tabname = 'OUTPUT'
            i_inclname         = gs_program
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

  wa_fieldcat_alv-seltext_l = text-040.
  wa_fieldcat_alv-seltext_m = text-040.
  wa_fieldcat_alv-seltext_s = text-041.
  wa_fieldcat_alv-reptext_ddic = text-041.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ROLEID'.

  wa_fieldcat_alv-seltext_l = text-108.
  wa_fieldcat_alv-seltext_m = text-108.
  wa_fieldcat_alv-seltext_s = text-108.
  wa_fieldcat_alv-reptext_ddic = text-109.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TCODE'.

  wa_fieldcat_alv-seltext_l = text-042.
  wa_fieldcat_alv-seltext_m = text-043.
  wa_fieldcat_alv-seltext_s = text-044.
  wa_fieldcat_alv-reptext_ddic = text-044.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ROLECR'.

  wa_fieldcat_alv-seltext_l = text-045.
  wa_fieldcat_alv-seltext_m = text-046.
  wa_fieldcat_alv-seltext_s = text-047.
  wa_fieldcat_alv-reptext_ddic = text-047.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ROLEHDR'.

  wa_fieldcat_alv-seltext_l = text-048.
  wa_fieldcat_alv-seltext_m = text-049.
  wa_fieldcat_alv-seltext_s = text-050.
  wa_fieldcat_alv-reptext_ddic = text-050.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ROLETC'.

  wa_fieldcat_alv-seltext_l = text-051.
  wa_fieldcat_alv-seltext_m = text-052.
  wa_fieldcat_alv-seltext_s = text-053.
  wa_fieldcat_alv-reptext_ddic = text-053.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ROLETXT'.

  wa_fieldcat_alv-seltext_l = text-054.
  wa_fieldcat_alv-seltext_m = text-054.
  wa_fieldcat_alv-seltext_s = text-055.
  wa_fieldcat_alv-reptext_ddic = text-054.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'MESSAGE'.

ENDFORM.                    " build_alv_catalog
*&---------------------------------------------------------------------*
*&      Form  output_using_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_using_alv.
  DATA: alv_layout TYPE slis_layout_alv,
        gs_variant TYPE disvariant.

  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title       = text-021
            i_callback_program = gs_program
            is_layout          = alv_layout
            i_save             = 'A'
            is_variant         = gs_variant
            it_fieldcat        = i_fieldcat_alv
       TABLES
            t_outtab           = output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " output_using_alv
*&---------------------------------------------------------------------*
*&      Form  upload_files
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM upload_files.

  DATA : l_file_rolehdr TYPE string,
         l_file_roletrans TYPE string,
         l_file_roletext TYPE string,
         l_file_roletextsod TYPE string.

  l_file_rolehdr = urhfile.

*BOC:HBHALLA (097)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '60'.
  IF sy-subrc = 0.
  CALL FUNCTION 'GUI_UPLOAD' "#EC SAST_CI_GEN_CHECK
       EXPORTING
            filename                = l_file_rolehdr
            filetype                = 'ASC'
            has_field_separator     = 'X'
            dat_mode                = ' '
       TABLES
            data_tab                = urolehdr
       EXCEPTIONS
            file_open_error         = 1
            file_read_error         = 2
            no_batch                = 3
            gui_refuse_filetransfer = 4
            invalid_type            = 5
            no_authority            = 6
            unknown_error           = 7
            bad_data_format         = 8
            header_not_allowed      = 9
            separator_not_allowed   = 10
            header_too_long         = 11
            unknown_dp_error        = 12
            access_denied           = 13
            dp_out_of_memory        = 14
            disk_full               = 15
            dp_timeout              = 16
            OTHERS                  = 17.

  IF sy-subrc NE 0.
    PERFORM handle_upload_error USING sy-subrc l_file_rolehdr text-056.
    g_keepgoing = 'N'.
    EXIT.
  ENDIF.
  ENDIF.
*EOC:HBHALLA (097)

  l_file_roletrans = urtfile.

*BOC:HBHALLA (097)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '60'.
  IF sy-subrc = 0.
  CALL FUNCTION 'GUI_UPLOAD' "#EC SAST_CI_GEN_CHECK
    EXPORTING
      filename                      = l_file_roletrans
     filetype                      = 'ASC'
     has_field_separator           = 'X'
*   HEADER_LENGTH                 = 0
*   READ_BY_LINE                  = 'X'
     dat_mode                      = ' '
* IMPORTING
*   FILELENGTH                    =
*   HEADER                        =
    TABLES
      data_tab                      = uroletrans
   EXCEPTIONS
     file_open_error               = 1
     file_read_error               = 2
     no_batch                      = 3
     gui_refuse_filetransfer       = 4
     invalid_type                  = 5
     no_authority                  = 6
     unknown_error                 = 7
     bad_data_format               = 8
     header_not_allowed            = 9
     separator_not_allowed         = 10
     header_too_long               = 11
     unknown_dp_error              = 12
     access_denied                 = 13
     dp_out_of_memory              = 14
     disk_full                     = 15
     dp_timeout                    = 16
     OTHERS                        = 17
            .

  IF sy-subrc NE 0.
    PERFORM handle_upload_error USING sy-subrc
    l_file_roletrans text-022.
  ENDIF.
  ENDIF.
*EOC:HBHALLA (097)

  l_file_roletext = urxfile.

*BOC:HBHALLA (097)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '60'.
  IF sy-subrc = 0.
  CALL FUNCTION 'GUI_UPLOAD' "#EC SAST_CI_GEN_CHECK
       EXPORTING
            filename                = l_file_roletext
            filetype                = 'ASC'
            has_field_separator     = 'X'
            dat_mode                = ' '
       TABLES
            data_tab                = gt_uroletext
       EXCEPTIONS
            file_open_error         = 1
            file_read_error         = 2
            no_batch                = 3
            gui_refuse_filetransfer = 4
            invalid_type            = 5
            no_authority            = 6
            unknown_error           = 7
            bad_data_format         = 8
            header_not_allowed      = 9
            separator_not_allowed   = 10
            header_too_long         = 11
            unknown_dp_error        = 12
            access_denied           = 13
            dp_out_of_memory        = 14
            disk_full               = 15
            dp_timeout              = 16
            OTHERS                  = 17.

  IF sy-subrc NE 0.
    PERFORM handle_upload_error USING sy-subrc
    l_file_roletext text-023.
  ENDIF.
  ENDIF.
*EOC:HBHALLA (097)

  l_file_roletextsod = urxfile2.

*BOC:HBHALLA (097)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '60'.
  IF sy-subrc = 0.
  CALL FUNCTION 'GUI_UPLOAD' "#EC SAST_CI_GEN_CHECK
       EXPORTING
            filename                = l_file_roletextsod
            filetype                = 'ASC'
            has_field_separator     = 'X'
            dat_mode                = ' '
       TABLES
            data_tab                = gt_roletextsod
       EXCEPTIONS
            file_open_error         = 1
            file_read_error         = 2
            no_batch                = 3
            gui_refuse_filetransfer = 4
            invalid_type            = 5
            no_authority            = 6
            unknown_error           = 7
            bad_data_format         = 8
            header_not_allowed      = 9
            separator_not_allowed   = 10
            header_too_long         = 11
            unknown_dp_error        = 12
            access_denied           = 13
            dp_out_of_memory        = 14
            disk_full               = 15
            dp_timeout              = 16
            OTHERS                  = 17.

  IF sy-subrc NE 0.
    PERFORM handle_upload_error USING sy-subrc
    l_file_roletextsod text-088.
  ENDIF.
  ENDIF.
*EOC:HBHALLA (097)
ENDFORM.                    " upload_files
*&---------------------------------------------------------------------*
*&      Form  popup_ques_to_continue
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM popup_ques_to_continue.

  DATA: l_popup_question(80).
  DATA: l_popup_answer.

  IF uroletrans[] IS INITIAL.
    MOVE text-024 TO l_popup_question .
    CALL FUNCTION 'POPUP_TO_CONFIRM'
         EXPORTING
              titlebar              = text-025
              text_question         = l_popup_question
              text_button_1         = text-058
              icon_button_1         = 'ICON_CHECKED'
              text_button_2         = text-059
              icon_button_2         = 'ICON_SYSTEM_CANCEL'
              default_button        = '2'
              display_cancel_button = ' '
         IMPORTING
              answer                = l_popup_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND = 1
             OTHERS         = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
    IF l_popup_answer = '2'.
      g_keepgoing = 'N'.
    else.
      g_keepgoing = 'Y'.
    ENDIF.
  ENDIF.

  CHECK g_keepgoing = 'Y'.

  IF gt_uroletext[] IS INITIAL.
    MOVE text-026 TO l_popup_question .
    CALL FUNCTION 'POPUP_TO_CONFIRM'
         EXPORTING
              titlebar              = text-027
              text_question         = l_popup_question
              text_button_1         = text-058
              icon_button_1         = 'ICON_CHECKED'
              text_button_2         = text-059
              icon_button_2         = 'ICON_SYSTEM_CANCEL'
              default_button        = '2'
              display_cancel_button = ' '
         IMPORTING
              answer                = l_popup_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND   = 1
             OTHERS           = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
    IF l_popup_answer = '2'.
      g_keepgoing = 'N'.
    else.
      g_keepgoing = 'Y'.
    ENDIF.
  ENDIF.

ENDFORM.                    " popup_ques_to_continue
*&---------------------------------------------------------------------*
*&      Form  move_files_data_2_itabs
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM move_files_data_2_itabs.
* BOC by RGUPTA on 29.03.22
  DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA On 29.03.22
*convert data to UPPER CASE and move to internal table
  LOOP AT urolehdr.
    CHECK NOT urolehdr-roleid IS INITIAL.

    TRANSLATE urolehdr-roleid TO UPPER CASE.
    TRANSLATE urolehdr-owner TO UPPER CASE.
    TRANSLATE urolehdr-approval TO UPPER CASE.
    TRANSLATE urolehdr-importance TO UPPER CASE.
    TRANSLATE urolehdr-project TO UPPER CASE.
    TRANSLATE urolehdr-rolemodule TO UPPER CASE.
    TRANSLATE urolehdr-saptechname TO UPPER CASE.
    TRANSLATE urolehdr-status TO UPPER CASE.
    MOVE-CORRESPONDING urolehdr TO gt_irolehdr.
    gt_irolehdr-create_usr = l_current_user."sy-uname. C0700
    gt_irolehdr-create_dat = sy-datum.
    gt_irolehdr-create_tim = sy-uzeit.
    APPEND gt_irolehdr.
    DELETE urolehdr.
  ENDLOOP.

*convert data to UPPER CASE and move to internal table
  LOOP AT uroletrans.
    CHECK NOT uroletrans-roleid IS INITIAL.

    TRANSLATE uroletrans-roleid TO UPPER CASE.
    TRANSLATE uroletrans-tcode TO UPPER CASE.
    READ TABLE gt_irolehdr WITH KEY roleid = uroletrans-roleid.
    IF sy-subrc NE 0.
      DELETE uroletrans.
      CONTINUE.
    ENDIF.

    gt_iroletrans-roleid = uroletrans-roleid.
    gt_iroletrans-tcode = uroletrans-tcode.
    APPEND gt_iroletrans.
    DELETE uroletrans.
  ENDLOOP.

*convert data to UPPER CASE and move to internal table
  LOOP AT gt_uroletext.
    CHECK NOT gt_uroletext-roleid IS INITIAL.

    TRANSLATE gt_uroletext-roleid TO UPPER CASE.
    READ TABLE gt_irolehdr WITH KEY roleid = gt_uroletext-roleid.
    IF sy-subrc NE 0.
      DELETE gt_uroletext.
      CONTINUE.
    ENDIF.

    CHECK gt_uroletext-line NE '00000'.
    CONCATENATE gt_uroletext-roleid 'HDR' INTO itexts-textname.
    itexts-object = 'R'.
    itexts-spras = sy-langu.
    itexts-line = gt_uroletext-line.
    itexts-text = gt_uroletext-text.
    APPEND itexts.
    DELETE gt_uroletext.
  ENDLOOP.

*convert data to UPPER CASE and move to internal table
  LOOP AT gt_roletextsod.
    CHECK NOT gt_roletextsod-roleid IS INITIAL.

    TRANSLATE gt_roletextsod-roleid TO UPPER CASE.
    READ TABLE gt_irolehdr WITH KEY roleid = gt_roletextsod-roleid.
    IF sy-subrc NE 0.
      DELETE gt_roletextsod.
      CONTINUE.
    ENDIF.

    CHECK gt_roletextsod-line NE '00000'.
    CONCATENATE gt_roletextsod-roleid 'DESC' INTO itexts-textname.
    itexts-object = 'R'.
    itexts-spras = sy-langu.
    itexts-line = gt_roletextsod-line.
    itexts-text = gt_roletextsod-text.
    APPEND itexts.
    DELETE gt_roletextsod.
  ENDLOOP.

  REFRESH: gt_uroletext, uroletrans, urolehdr, gt_roletextsod.
  CLEAR: gt_uroletext, uroletrans, urolehdr, gt_roletextsod.

  SORT gt_irolehdr.
  DELETE ADJACENT DUPLICATES FROM gt_irolehdr.
  SORT gt_iroletrans.
  DELETE ADJACENT DUPLICATES FROM gt_iroletrans.
  SORT itexts.
  DELETE ADJACENT DUPLICATES FROM itexts.

ENDFORM.                    " move_files_data_2_itabs
*&---------------------------------------------------------------------*
*&      Form  create_sw_rolesids
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM create_sw_rolesids.

 DATA: iirolehdr TYPE STANDARD TABLE OF /psyng/rolehdr WITH HEADER LINE,
                    iiroletrans TYPE STANDARD TABLE OF /psyng/roletrans
                                                       WITH HEADER LINE,
           iitexts TYPE STANDARD TABLE OF /psyng/texts WITH HEADER LINE,
                lt_tstc TYPE SORTED TABLE OF tstc WITH UNIQUE KEY tcode.

  DATA: l_rid_exists,
        l_overwrite.

  IF p_ovrwrt = 'X'.
    l_overwrite = 'X'.
  ELSE.
    l_overwrite = ''.
  ENDIF.

*-get existing tcodes
  IF NOT gt_iroletrans[] IS INITIAL.
    SELECT tcode FROM tstc INTO CORRESPONDING FIELDS OF TABLE lt_tstc
    FOR ALL ENTRIES IN gt_iroletrans WHERE tcode = gt_iroletrans-tcode.
  ENDIF.

  LOOP AT gt_irolehdr.
    REFRESH: iirolehdr, iiroletrans, iitexts.
    CLEAR: iirolehdr, iiroletrans, iitexts, output.

    CALL FUNCTION '/PSYNG/SW_CHECK_SWROLE_EXISTS'
         EXPORTING
              proleid = gt_irolehdr-roleid
         IMPORTING
              exists  = l_rid_exists.

    IF l_rid_exists = 'Y' AND l_overwrite = ''.
      output-agr_name = gt_irolehdr-saptechname.
      output-roleid = gt_irolehdr-roleid.
      output-rolecr = 'N'.
      output-rolehdr = ''.
      output-roletc = ''.
      output-roletxt = ''.
      output-message = text-028.
      APPEND output.
      CONTINUE.
    ELSEIF testrun ='X'.
      output-agr_name = gt_irolehdr-saptechname.
      output-roleid = gt_irolehdr-roleid.
      output-rolecr = 'Y'.
      output-rolehdr = ''.
      output-roletc = ''.
      output-roletxt = ''.
      output-message = text-020.
      APPEND output.
    ENDIF.

    MOVE-CORRESPONDING gt_irolehdr TO iirolehdr.
    APPEND iirolehdr.

    output-agr_name = gt_irolehdr-saptechname.
    output-roleid = gt_irolehdr-roleid.


    LOOP AT gt_iroletrans WHERE roleid = gt_irolehdr-roleid.
*     check if tcode exists.
      READ TABLE lt_tstc WITH KEY tcode = gt_iroletrans-tcode
      BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        MOVE-CORRESPONDING gt_iroletrans TO iiroletrans.
        APPEND iiroletrans.
        output-agr_name = gt_irolehdr-saptechname.
        output-roleid = gt_irolehdr-roleid.
        output-tcode  = gt_iroletrans-tcode.
        output-rolecr = ''.
        output-rolehdr = ''.
        output-roletc = 'Y'.
        output-roletxt = ''.
        output-message = text-107.
        APPEND output.
        CLEAR output.
      ELSE.
        output-agr_name = gt_irolehdr-saptechname.
        output-roleid = gt_irolehdr-roleid.
        output-tcode  = gt_iroletrans-tcode.
        output-rolecr = ''.
        output-rolehdr = ''.
        output-roletc = 'N'.
        output-roletxt = ''.
        output-message = text-106.
        APPEND output.
        CLEAR output.
      ENDIF.
    ENDLOOP.

    LOOP AT itexts WHERE textname(4) = gt_irolehdr-roleid
                     AND object = 'R'.
      MOVE-CORRESPONDING itexts TO iitexts.
      APPEND iitexts.
    ENDLOOP.

    IF  testrun IS INITIAL.
      CALL FUNCTION '/PSYNG/SW_CREATE_SWROLE_FILE'
           EXPORTING
                overwrite               = l_overwrite
           IMPORTING
                roleid_created          = output-rolecr
                roleidexists            = l_rid_exists
                role_hdr_created        = output-rolehdr
                role_tc_added           = output-roletc
                role_txt_added          = output-roletxt
           TABLES
                irolehdr                = iirolehdr
                iroletrans              = iiroletrans
                itexts                  = iitexts
           EXCEPTIONS
                sw_role_exists          = 1
                multiple_roles_provided = 2
                not_authorized          = 3
                OTHERS                  = 4.

      IF sy-subrc <> 0.
        output-rolecr = 'N'.
        CASE sy-subrc.
          WHEN 1.
            output-message = text-017.
          WHEN 2.
            output-message = text-062.
          WHEN 3.
            output-message = text-018.
          WHEN 4.
            output-message = text-063.
        ENDCASE.
      ELSE.
*      output-message = text-020.
      ENDIF.

      APPEND output.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " create_sw_rolesids
*&---------------------------------------------------------------------*
*&      Form  output_uploaded_files
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_uploaded_files.

  WRITE:/ text-064.
  WRITE:/ text-065.
  WRITE:/ text-066.
  SKIP 3.

  WRITE:/ text-067, urhfile.
  SKIP 1.
  LOOP AT urolehdr.
    WRITE:/10 urolehdr.
  ENDLOOP.

  ULINE.
  SKIP 3.

  WRITE:/ text-068, urtfile.
  SKIP 1.
  LOOP AT uroletrans.
    WRITE:/10 uroletrans.
  ENDLOOP.

  ULINE.
  SKIP 3.

  WRITE:/ text-069, urxfile.
  SKIP 1.
  LOOP AT gt_uroletext.
    WRITE:/10 gt_uroletext.
  ENDLOOP.

  WRITE:/ text-089, urxfile2.
  SKIP 1.
  LOOP AT gt_roletextsod.
    WRITE:/10 gt_roletextsod.
  ENDLOOP.

  ULINE.
  SKIP 3.
  WRITE:/ text-066.
  WRITE:/ text-070.
ENDFORM.                    " output_uploaded_files
*&---------------------------------------------------------------------*
*&      Form  download_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM download_roles.
  TYPES: BEGIN OF t_text,
           roleid LIKE /psyng/rolehdr-roleid,
           line LIKE /psyng/texts-line,
           text LIKE /psyng/texts-text,
         END OF t_text.

  DATA: textname TYPE /psyng/texts-textname,
        ls_roletext  TYPE t_text,
        lt_droletext    TYPE TABLE OF t_text WITH HEADER LINE,
        lt_droletextsod TYPE TABLE OF t_text WITH HEADER LINE.

  DATA: BEGIN OF drolehdr OCCURS 0,
          roleid LIKE /psyng/rolehdr-roleid,
          description LIKE /psyng/rolehdr-description,
          owner LIKE /psyng/rolehdr-owner,
          approval LIKE /psyng/rolehdr-approval,
          importance LIKE /psyng/rolehdr-importance,
          project LIKE /psyng/rolehdr-project,
          rolemodule LIKE /psyng/rolehdr-rolemodule,
          saptechname LIKE /psyng/rolehdr-saptechname,
          status LIKE /psyng/rolehdr-status,
        END OF drolehdr.

  DATA: BEGIN OF droletrans OCCURS 0,
          roleid LIKE /psyng/rolehdr-roleid,
          tcode LIKE sy-tcode,
        END OF droletrans.

  DATA : l_file_rolehdr TYPE string,
         l_file_roletrans TYPE string,
         l_file_roletext TYPE string,
         l_file_roletextsod TYPE string.


  AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
           ID 'ACTVT' FIELD '61'
           ID 'Y&SW_ROLID' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  IF sy-subrc NE 0.
    MESSAGE e113(/psyng/sw) WITH text-029.
    STOP.
  ENDIF.

  SELECT * FROM /psyng/rolehdr INTO TABLE gt_irolehdr
           WHERE roleid IN droleids.
  SELECT * FROM /psyng/roletrans INTO TABLE gt_iroletrans
           WHERE roleid IN droleids.
  SORT: gt_irolehdr, gt_iroletrans.

  LOOP AT gt_irolehdr.
    CLEAR textname.
    CONCATENATE gt_irolehdr-roleid 'HDR' INTO textname.
    SELECT * FROM /psyng/texts                       "#EC CI_SEL_NESTED
       APPENDING TABLE itexts
             WHERE textname = textname
               AND object   = 'R'
               AND vrsio = '000'.

    CONCATENATE gt_irolehdr-roleid 'DESC' INTO textname.
    SELECT * FROM /psyng/texts                       "#EC CI_SEL_NESTED
         APPENDING TABLE itexts
             WHERE textname = textname
               AND object   = 'R'
               AND vrsio = '000'.

    MOVE-CORRESPONDING gt_irolehdr TO drolehdr.
    APPEND drolehdr.
    DELETE gt_irolehdr.
  ENDLOOP.

  LOOP AT gt_iroletrans.
    MOVE-CORRESPONDING gt_iroletrans TO droletrans.
    APPEND droletrans.
    DELETE gt_iroletrans.
  ENDLOOP.

  DATA: lv_text(4) TYPE c,
        lv_text1 LIKE /psyng/texts-textname.

  SORT itexts.
  LOOP AT itexts.
    ls_roletext-roleid = itexts-textname(4).
    ls_roletext-line = itexts-line.
    ls_roletext-text = itexts-text.

    IF itexts-textname CS 'HDR'.

      SPLIT itexts-textname AT 'H' INTO  lv_text1 lv_text.
      CONCATENATE 'H' lv_text INTO lv_text.
    ELSE.
      SPLIT itexts-textname AT 'D' INTO  lv_text1 lv_text.
      CONCATENATE 'D' lv_text INTO lv_text.
    ENDIF.

    CASE lv_text.
      WHEN 'HDR'.
        APPEND ls_roletext TO lt_droletext.
      WHEN 'DESC'.
        APPEND ls_roletext TO lt_droletextsod.
    ENDCASE.
    DELETE itexts.
  ENDLOOP.

  IF NOT lt_droletext[] IS INITIAL.

    l_file_roletext = drxfile.
*BOC:HBHALLA (096)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '61'.
  IF sy-subrc = 0.
    CALL FUNCTION 'GUI_DOWNLOAD' "#EC SAST_CI_GEN_CHECK
         EXPORTING
              filename                = l_file_roletext
              filetype                = 'ASC'
              write_field_separator   = 'X'
              dat_mode                = ' '
         TABLES
              data_tab                = lt_droletext
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

    IF sy-subrc NE 0.
      PERFORM handle_download_error USING sy-subrc
                                          l_file_roletext
                                          text-030.
      WRITE:/ text-030.
    ELSE.
      WRITE:/ text-072,
              drxfile.
    ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
  ELSE.
    WRITE:/ text-073.
  ENDIF.


  IF NOT lt_droletextsod[] IS INITIAL.
    l_file_roletext = drxfile2.
*BOC:HBHALLA (096)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '61'.
  IF sy-subrc = 0.
    CALL FUNCTION 'GUI_DOWNLOAD' "#EC SAST_CI_GEN_CHECK
         EXPORTING
              filename                = l_file_roletext
              filetype                = 'ASC'
              write_field_separator   = 'X'
              dat_mode                = ' '
         TABLES
              data_tab                = lt_droletextsod
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

    IF sy-subrc NE 0.
      PERFORM handle_download_error USING sy-subrc
                                          l_file_roletext
                                          text-030.
      WRITE:/ text-030.
    ELSE.
      WRITE:/ text-086,
              drxfile2.
    ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
  ELSE.
    WRITE:/ text-087.
  ENDIF.

  IF NOT droletrans IS INITIAL.

    l_file_roletrans = drtfile.
*BOC:HBHALLA (096)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '61'.
  IF sy-subrc = 0.
    CALL FUNCTION 'GUI_DOWNLOAD' "#EC SAST_CI_GEN_CHECK
      EXPORTING
*   BIN_FILESIZE                  =
        filename                      = l_file_roletrans
       filetype                      = 'ASC'
*   APPEND                        = ' '
       write_field_separator         = 'X'
*   HEADER                        = '00'
*   TRUNC_TRAILING_BLANKS         = ' '
*   WRITE_LF                      = 'X'
*   COL_SELECT                    = ' '
*   COL_SELECT_MASK               = ' '
       dat_mode                      = ' '
* IMPORTING
*   FILELENGTH                    =
      TABLES
        data_tab                      = droletrans
     EXCEPTIONS
       file_write_error              = 1
       no_batch                      = 2
       gui_refuse_filetransfer       = 3
       invalid_type                  = 4
       no_authority                  = 5
       unknown_error                 = 6
       header_not_allowed            = 7
       separator_not_allowed         = 8
       filesize_not_allowed          = 9
       header_too_long               = 10
       dp_error_create               = 11
       dp_error_send                 = 12
       dp_error_write                = 13
       unknown_dp_error              = 14
       access_denied                 = 15
       dp_out_of_memory              = 16
       disk_full                     = 17
       dp_timeout                    = 18
       file_not_found                = 19
       dataprovider_exception        = 20
       control_flush_error           = 21
       OTHERS                        = 22
              .

    IF sy-subrc NE 0.
      PERFORM handle_download_error USING sy-subrc
                                          l_file_roletrans
                                          text-031.
      WRITE:/ text-031.

    ELSE.
      WRITE:/ text-074,
              drtfile.
    ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
  ELSE.
    WRITE:/ text-075.
  ENDIF.

  IF NOT drolehdr IS INITIAL.

    l_file_rolehdr = drhfile.
*BOC:HBHALLA (096)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '61'.
  IF sy-subrc = 0.
    CALL FUNCTION 'GUI_DOWNLOAD' "#EC SAST_CI_GEN_CHECK
         EXPORTING
              filename                = l_file_rolehdr
              filetype                = 'ASC'
              write_field_separator   = 'X'
              dat_mode                = ' '
         TABLES
              data_tab                = drolehdr
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

    IF sy-subrc NE 0.
      PERFORM handle_download_error USING sy-subrc
                                          l_file_rolehdr
                                          text-032.
      WRITE:/ text-032.

    ELSE.
      WRITE:/ text-076,
              drhfile.
    ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
  ELSE.
    WRITE:/ text-077.
  ENDIF.

ENDFORM.                    " download_roles
*27-08-2008 insert code TSEN
*&---------------------------------------------------------------------*
*&      Form  FILE_SELECT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_URHFILE  text
*----------------------------------------------------------------------*
FORM file_select CHANGING i_g_filename TYPE rlgrap-filename
                          i_file_path TYPE rlgrap-filename
                          i_flag_upld_r_dwld.



  DATA :   l_uaction TYPE i,
           l_title TYPE string,
           l_filetable TYPE  filetable,
           l_def_fname TYPE string,
           l_init_dir TYPE string.

  l_def_fname = i_file_path.

  CALL FUNCTION 'LIST_SPLIT_PATH'
       EXPORTING
            filename = i_file_path
       IMPORTING
            pathname = i_file_path.
  DO.
    SHIFT l_def_fname UP TO '\'.
    IF sy-subrc <> 0.
      EXIT.
    ENDIF.
    SHIFT l_def_fname.
  ENDDO.
  l_init_dir = i_file_path.

  IF i_flag_upld_r_dwld = 'X'.

    l_title = text-079.
  ELSE.
    l_title = text-080.
  ENDIF.

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
"#EC SAST_CI_GEN_CHECK (HBHALLA)
 EXPORTING
   window_title            = l_title
   default_extension       = 'txt'
   default_filename        = l_def_fname
   file_filter             = '*.txt'
    initial_directory       = l_init_dir
*    MULTISELECTION          =
 CHANGING
   file_table              = l_filetable
   rc                      = l_uaction
*    USER_ACTION             =
 EXCEPTIONS
   file_open_dialog_failed = 1
   cntl_error              = 2
   error_no_gui            = 3
   OTHERS                  = 4
       .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    READ TABLE l_filetable INDEX 1 INTO i_g_filename.

  ENDIF.
ENDFORM.                    " FILE_SELECT

*---------------------------------------------------------------------*
*       FORM handle_download_error                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  P_SY_SUBRC                                                    *
*  -->  P_FILENAME                                                    *
*  -->  P_MSG                                                         *
*---------------------------------------------------------------------*
FORM handle_download_error USING    p_sy_subrc
                                    p_filename
                                    p_msg.
  DATA: l_msgv1 TYPE bapiret2-message_v1,
        l_msgv2 TYPE bapiret2-message_v2.


  l_msgv1 = p_filename.
  l_msgv2 = p_msg.
  CALL FUNCTION '/PSYNG/BC_003'
       EXPORTING
            i_subrc = sy-subrc
            i_msgty = 'I'
            i_msgv1 = l_msgv1
            i_msgv2 = l_msgv2.
ENDFORM.                    " handle_download_error

*---------------------------------------------------------------------*
*       FORM handle_upload_error                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  P_SY_SUBRC                                                    *
*  -->  P_FILENAME                                                    *
*  -->  P_MSG                                                         *
*---------------------------------------------------------------------*
FORM handle_upload_error USING    p_sy_subrc
                                  p_filename
                                  p_msg.
  DATA: l_msgv1 TYPE bapiret2-message_v1,
        l_msgv2 TYPE bapiret2-message_v2.


  l_msgv1 = p_filename.
  l_msgv2 = p_msg.
  CALL FUNCTION '/PSYNG/BC_004'
       EXPORTING
            i_subrc = sy-subrc
            i_msgty = 'I'
            i_msgv1 = l_msgv1
            i_msgv2 = l_msgv2.
ENDFORM.                    " handle_error
*&---------------------------------------------------------------------*
*&      Form  f_get_number
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f_get_number.
  TYPES: BEGIN OF ty_roleid,
          roleid TYPE /psyng/role_id,
         END OF ty_roleid.
  DATA: lr_roleid TYPE RANGE OF /psyng/role_id,
        lr_roleid_l LIKE LINE OF lr_roleid,
        lt_roleid TYPE STANDARD TABLE OF ty_roleid,
        ls_roleid TYPE ty_roleid,
        lv_char TYPE c VALUE '*',
        lv_char1 TYPE /psyng/role_id,
        lv_char2 TYPE string,
        lv_char3 TYPE /psyng/role_id,
        lv_splitter TYPE i.

       lv_char2 ='aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ'.

       lv_splitter = strlen( ucrid ).

  IF upagr = 'X'.
  CONCATENATE ucrid lv_char INTO lv_char1.

      lr_roleid_l-option = 'CP'.

    lr_roleid_l-sign = 'I'.
    lr_roleid_l-low = lv_char1.
    APPEND lr_roleid_l TO lr_roleid.
    CLEAR: lr_roleid_l.

    SELECT roleid FROM /psyng/rolehdr
                  INTO TABLE lt_roleid
                  WHERE roleid IN lr_roleid.
    IF sy-subrc EQ 0.
      SORT: lt_roleid BY roleid DESCENDING.
      loop at lt_roleid INTO ls_roleid.

       lv_char3 = ls_roleid-roleid.

       shift lv_char3 by lv_splitter places.

      IF NOT lv_char3 CA lv_char2.

      READ TABLE lt_roleid INTO ls_roleid INDEX 1.
      IF sy-subrc EQ 0.
        n_gn = ls_roleid-roleid.
      ENDIF.
      ELSE.

     DELETE lt_roleid WHERE roleid EQ ls_roleid-roleid.
      ENDIF.
      ENDLOOp.
    ENDIF.

  ELSEIF upfile = 'X'.
    IF ucrid1 CS '*'.
      lr_roleid_l-option = 'CP'.
    ELSE.
      lr_roleid_l-option = 'EQ'.
    ENDIF.

    lr_roleid_l-sign = 'I'.
    lr_roleid_l-low = ucrid1.
    APPEND lr_roleid_l TO lr_roleid.
    CLEAR: lr_roleid_l.

    SELECT roleid FROM /psyng/rolehdr
                  INTO TABLE lt_roleid
                  WHERE roleid IN lr_roleid.
    IF sy-subrc EQ 0.
      SORT: lt_roleid BY roleid DESCENDING.
      READ TABLE lt_roleid INTO ls_roleid INDEX 1.
      IF sy-subrc EQ 0.
        n_gn1 = ls_roleid-roleid.
      ENDIF.
    ENDIF.

  ENDIF.

ENDFORM.                    " f_get_number
