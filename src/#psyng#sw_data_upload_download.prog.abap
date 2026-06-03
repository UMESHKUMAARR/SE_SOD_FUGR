
*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_DATA_UPLOAD_DOWNLOAD
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*
*----------------------------------------------------------------------*
REPORT /psyng/sw_data_upload_download MESSAGE-ID /psyng/sw
                                      LINE-SIZE 170.
DATA : g_folder TYPE string.
TYPE-POOLS:slis, icon, ustyp.
TABLES  sscrfields.
DATA : BEGIN OF gt_log OCCURS 0,
         filename  LIKE rlgrap-filename,
         type      LIKE icon-id,
         object    LIKE dd03d-fieldname,
         object_id LIKE t100-text,
         fieldname LIKE dd03d-fieldname,
         value     LIKE t100-text,
         message   LIKE t100-text,
       END OF gt_log.

DATA : g_append_flag   TYPE c VALUE 'X',
       gs_functxt      TYPE smp_dyntxt,
       g_download_size TYPE i.

DATA : lt_conh TYPE  TABLE OF /psyng/conflict  WITH HEADER LINE,
       lt_funh TYPE  TABLE OF /psyng/function  WITH HEADER LINE,
       lt_fund TYPE  TABLE OF /psyng/functtran WITH HEADER LINE,
       lt_objd TYPE  TABLE OF /psyng/faobj2    WITH HEADER LINE,
       lt_cond TYPE  TABLE OF /psyng/confdet   WITH HEADER LINE,
       lt_cah  TYPE  TABLE OF /psyng/swaudhdr  WITH HEADER LINE,
       lt_cad  TYPE  TABLE OF /psyng/swaudc2   WITH HEADER LINE,
       lt_ct   TYPE  TABLE OF /psyng/critcodes WITH HEADER LINE,
       lt_cr   TYPE  TABLE OF /psyng/criroles  WITH HEADER LINE,
       lt_cp   TYPE TABLE OF /psyng/criprof   WITH HEADER LINE,
       g_current_user TYPE sy-uname. "C0700



*--Selection Screen
SELECTION-SCREEN: FUNCTION KEY 1,
                  FUNCTION KEY 2.

SELECTION-SCREEN: BEGIN OF BLOCK vrsio WITH FRAME TITLE text-b00.
PARAMETERS :   sodvrsio LIKE /psyng/conflict-vrsio OBLIGATORY
MEMORY ID /psyng/vrsio.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(18) text-148 FOR FIELD p_crtver.
SELECTION-SCREEN: POSITION 20.
PARAMETERS :  p_crtver AS CHECKBOX USER-COMMAND ud.
SELECTION-SCREEN: COMMENT 24(16) text-149.
SELECTION-SCREEN: POSITION 41.
PARAMETERS : p_text(80) TYPE c  MODIF ID b1 LOWER CASE  .
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK vrsio.

SELECTION-SCREEN: BEGIN OF BLOCK opt WITH FRAME TITLE text-b01.
*--Download
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: dnldtabs RADIOBUTTON GROUP a USER-COMMAND ud.
SELECTION-SCREEN: COMMENT 3(76) text-011 FOR FIELD dnldtabs.
SELECTION-SCREEN: END OF LINE.
*--Upload
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: upldtabs RADIOBUTTON GROUP a .
SELECTION-SCREEN: COMMENT 3(76) text-021 FOR FIELD upldtabs.
SELECTION-SCREEN: END OF LINE.

*--Backup and Delete
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: emtytabs RADIOBUTTON GROUP a .
SELECTION-SCREEN: COMMENT 3(40) text-018 FOR FIELD emtytabs.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: SKIP 1.

*--Folder
PARAMETERS :  basepath TYPE rlgrap-filename
LOWER CASE DEFAULT 'c:\temp' OBLIGATORY.
SELECTION-SCREEN: SKIP 1.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: ovrwrt AS CHECKBOX.
SELECTION-SCREEN COMMENT 3(60) text-009 FOR FIELD ovrwrt.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: testrun  AS CHECKBOX.
SELECTION-SCREEN COMMENT 3(60) text-117 FOR FIELD testrun.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETER p_noval AS CHECKBOX.
SELECTION-SCREEN COMMENT 3(60) text-001 FOR FIELD p_noval.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN: END OF BLOCK opt.

SELECTION-SCREEN: BEGIN OF BLOCK files WITH FRAME TITLE text-b02.
***SOD Matrix files
SELECTION-SCREEN: BEGIN OF BLOCK sodmatrix WITH FRAME TITLE text-b03.

**function
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_funh TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f01 FOR FIELD f_funh.
PARAMETERS :  fn_funh TYPE rlgrap-filename LOWER CASE
DEFAULT 'FunctionsHeader.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_fund TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f02 FOR FIELD f_fund.
PARAMETERS :  fn_fund TYPE rlgrap-filename LOWER CASE
DEFAULT 'FunctionsDetails.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_funt TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f03 FOR FIELD f_funt.
PARAMETERS :  fn_funt TYPE rlgrap-filename LOWER CASE
DEFAULT 'FunctionsTexts.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

*object
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_objd TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f04 FOR FIELD f_objd.
PARAMETERS :  fn_objd TYPE rlgrap-filename LOWER CASE
DEFAULT 'ObjectDetails.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

* Function Filters
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_fnfltr TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f31 FOR FIELD f_fnfltr.
PARAMETERS :  fn_fflt TYPE rlgrap-filename LOWER CASE
DEFAULT 'FunctionFilters.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

*conflict
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_conh TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f05 FOR FIELD f_conh.
PARAMETERS :  fn_conh TYPE rlgrap-filename LOWER CASE
DEFAULT 'ConflictHeader.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_cond TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f06 FOR FIELD f_cond.
PARAMETERS :  fn_cond TYPE rlgrap-filename LOWER CASE
DEFAULT 'ConflictDetails.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_cont TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f07 FOR FIELD f_cont.
PARAMETERS :  fn_cont TYPE rlgrap-filename LOWER CASE
DEFAULT 'ConflictTexts.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

*conflcit owner
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_cono TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f08 FOR FIELD f_cono.
PARAMETERS :  fn_cono TYPE rlgrap-filename LOWER CASE
DEFAULT 'ConflictOwners.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

*conflcit mitigations
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_conm TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f18 FOR FIELD f_conm.
PARAMETERS :  fn_conm TYPE rlgrap-filename LOWER CASE
DEFAULT 'ConflictMitigations.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

*  conflcit Filters
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_conflt TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f30 FOR FIELD f_conflt.
PARAMETERS :  fn_cnflt TYPE rlgrap-filename LOWER CASE
DEFAULT 'ConflictFilters.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

*  Custom Org Level Determination
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_corg TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f33 FOR FIELD f_corg.
PARAMETERS :  fn_corg TYPE rlgrap-filename LOWER CASE
DEFAULT 'CustomOrgLevelDet.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK sodmatrix.

***Critical Object files
SELECTION-SCREEN: BEGIN OF BLOCK critical WITH FRAME TITLE text-b05.

*critical auth.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_cah TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f09 FOR FIELD f_cah.
PARAMETERS :  fn_cah TYPE rlgrap-filename LOWER CASE
DEFAULT 'CriticalAuthHeader.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_cad TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f10 FOR FIELD f_cad.
PARAMETERS :  fn_cad TYPE rlgrap-filename LOWER CASE
DEFAULT 'CriticalAuthDetails.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_cat TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f11 FOR FIELD f_cat.
PARAMETERS :  fn_cat TYPE rlgrap-filename LOWER CASE
DEFAULT 'CriticalAuthTexts.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_cafltr TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f29 FOR FIELD f_cafltr.
PARAMETERS :  fn_catfl TYPE rlgrap-filename LOWER CASE
DEFAULT 'CriticalAuthFilters.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

*Critical transaction
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_ct TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f12 FOR FIELD f_ct.
PARAMETERS :  fn_ct TYPE rlgrap-filename LOWER CASE
DEFAULT 'CriticalTcodes.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_ctxt TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f13 FOR FIELD f_ctxt.
PARAMETERS :  fn_ctxt TYPE rlgrap-filename LOWER CASE
DEFAULT 'CriticalTcodesTexts.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_ctfltr TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f28 FOR FIELD f_ctfltr.
PARAMETERS :  fn_ctflt TYPE rlgrap-filename LOWER CASE
DEFAULT 'CriticalTcodesFilters.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

*Critical Roles
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_cr TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f14 FOR FIELD f_cr.
PARAMETERS :  fn_cr TYPE rlgrap-filename LOWER CASE
DEFAULT 'CriticalRoles.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_crtxt TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f15 FOR FIELD f_crtxt.
PARAMETERS :  fn_crtxt TYPE rlgrap-filename LOWER CASE
DEFAULT 'CriticalRolesTexts.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

*Critical Profiles
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_cp TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f16 FOR FIELD f_cp.
PARAMETERS :  fn_cp TYPE rlgrap-filename LOWER CASE
DEFAULT 'CriticalProfiles.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: f_cptxt TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-f17 FOR FIELD f_cptxt.
PARAMETERS :  fn_cptxt TYPE rlgrap-filename LOWER CASE
DEFAULT 'CriticalProfilesTexts.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK critical.

SELECTION-SCREEN: END OF BLOCK files.

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

* BOC by RGUPTA on 05.04.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 05.04.22 for C0700

* to activate predefined function keys
  gs_functxt-icon_id   = icon_select_all.
  gs_functxt-quickinfo = 'Select All'.
  gs_functxt-icon_text = 'Select All'.
  sscrfields-functxt_01 = gs_functxt.

  gs_functxt-icon_id   = icon_deselect_all.
  gs_functxt-icon_text = 'Deselect All'.
  gs_functxt-quickinfo = 'Deselect All'.
  sscrfields-functxt_02 = gs_functxt.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR basepath.
  PERFORM dir_select .

AT SELECTION-SCREEN.

  CASE sy-ucomm.

    WHEN 'FC01'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
      f_funh = 'X'.
      f_fund = 'X'.
      f_funt = 'X'.
      f_objd = 'X'.
      f_funt = 'X'.
      f_fnfltr = 'X'.
      f_conh = 'X'.
      f_cond = 'X'.
      f_cont = 'X'.
      f_cono = 'X'.
      f_conm = 'X'.
      f_conflt = 'X'.
      f_cah  = 'X'.
      f_cad  = 'X'.
      f_cat  = 'X'.
      f_cafltr = 'X'.
      f_ct   = 'X'.
      f_ctxt = 'X'.
      f_ctfltr = 'X'.
      f_cr   = 'X'.
      f_crtxt = 'X'.
      f_cp   = 'X'.
      f_cptxt   = 'X'.
* Begin Changes by DDHIMAN 08.11.19
      f_corg = 'X'.
* End Changes by DDHIMAN 08.11.19
    WHEN 'FC02'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
      f_funh = ' '.
      f_fund = ' '.
      f_funt = ' '.
      f_objd = ' '.
      f_funt = ' '.
      f_fnfltr = ' '.
      f_conh = ' '.
      f_cond = ' '.
      f_cont = ' '.
      f_cono = ' '.
      f_conm = ' '.
      f_conflt = ' '.
      f_cah  = ' '.
      f_cad  = ' '.
      f_cat  = ' '.
      f_cafltr = ' '.
      f_ct   = ' '.
      f_ctxt = ' '.
      f_ctfltr = ' '.
      f_cr   = ' '.
      f_crtxt = ' '.
      f_cp   = ' '.
      f_cptxt   = ' '.
* Begin Changes by DDHIMAN 08.11.19
      f_corg = ' '.
* End Changes by DDHIMAN 08.11.19
  ENDCASE.



  IF p_crtver IS INITIAL AND sy-ucomm <> 'UD'.
    SELECT SINGLE mandt INTO sy-mandt FROM /psyng/swsodvers
                  WHERE vrsio = sodvrsio.
    IF sy-subrc <> 0.
      MESSAGE e156(/psyng/sw) WITH sodvrsio.
    ENDIF.
  ELSE.
    IF p_crtver = 'X' AND upldtabs = 'X'.
      SELECT SINGLE mandt INTO sy-mandt FROM /psyng/swsodvers
                    WHERE vrsio = sodvrsio.
      IF sy-subrc = 0.
        MESSAGE e101(/psyng/sw).
      ENDIF.

      IF p_text IS INITIAL.
        LOOP AT SCREEN.
          IF screen-name = 'P_TEXT'.
            screen-input = 1 .
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
        MESSAGE e155(/psyng/sw).
      ENDIF.
    ENDIF.
  ENDIF.


AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN .
    CASE screen-name.
      WHEN 'P_TEXT'.
        IF p_crtver = 'X'.
          screen-input = 1 .
        ELSEIF p_crtver = ' '.
          screen-input = 0 .
        ENDIF.
        MODIFY SCREEN.
      WHEN 'OVRWRT' OR 'TESTRUN' OR 'P_NOVAL' OR
           'P_CRTVER' OR 'P_TEXT'.
        IF upldtabs = 'X'.
          screen-input = 1 .
        ELSE.
          screen-input = 0 .
          CLEAR : ovrwrt,testrun,p_noval,p_crtver,p_text.
        ENDIF.
        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.


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
  IF f_funh <> 'X' AND
     f_fund <> 'X' AND
     f_funt <> 'X' AND
     f_objd <> 'X' AND
     f_funt <> 'X' AND
     f_fnfltr <> 'X' AND
     f_conh <> 'X' AND
     f_cond <> 'X' AND
     f_cont <> 'X' AND
     f_cono <> 'X' AND
     f_conm <> 'X' AND
     f_conflt <> 'X' AND
     f_cah  <> 'X' AND
     f_cad  <> 'X' AND
     f_cat  <> 'X' AND
     f_cafltr <> 'X' AND
     f_ct   <> 'X' AND
     f_ctxt <> 'X' AND
     f_ctfltr <> 'X' AND
     f_cr   <> 'X' AND
     f_crtxt <> 'X' AND
     f_cp   <> 'X' AND
     f_cptxt   <> 'X' AND
     f_corg    <> 'X'.


    MESSAGE s002 WITH
    'Please select at least one checkbox'(s01).
    LEAVE LIST-PROCESSING.
  ENDIF.

  IF dnldtabs = 'X'.
    PERFORM authority_check USING 'DLCONFUN'.
    PERFORM download_data.
  ELSEIF emtytabs = 'X'.
    DATA : l_answer.
    PERFORM authority_check USING 'DCONFUN'.
    PERFORM confirm_delete CHANGING l_answer.
    IF l_answer = '1'.
      PERFORM download_data.
      PERFORM delete_all_data.
    ELSE.
      EXIT.
    ENDIF.
  ELSEIF upldtabs = 'X'.
    PERFORM authority_check USING 'UCONFUN'.
    PERFORM upload_data.
  ENDIF.
  PERFORM output_log.

*---------------------------------------------------------------------*
*       FORM dir_select                                               *
*---------------------------------------------------------------------*
*       Select Directory to download to                               *
*---------------------------------------------------------------------*
*  -->  I_G_FILENAME                                                  *
*  -->  I_FILE_PATH                                                   *
*---------------------------------------------------------------------*
FORM dir_select.
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
ENDFORM.                    " FILE_SELECT
*&---------------------------------------------------------------------*
*&      Form  authority_check
*&---------------------------------------------------------------------*
*       Check authorizations
*----------------------------------------------------------------------*
*      -->P_0764   text
*----------------------------------------------------------------------*
FORM authority_check USING admf.
  DATA: admf_txt(30),
        l_actvt(2).

  CASE admf.
    WHEN 'DCONFUN'.
      l_actvt  = 'DL'.
      admf_txt = text-034.
    WHEN 'UCONFUN'.
      l_actvt  = 'UL'.
      admf_txt = text-035.
    WHEN 'RCONFUN'.
      l_actvt  = 'UL'.
      admf_txt = text-036.
    WHEN 'DLCONFUN'.
      l_actvt  = 'DL'.
      admf_txt = text-037.
    WHEN OTHERS.
  ENDCASE.

  AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
           ID 'Y&SW_ADMF' FIELD admf.

  IF sy-subrc NE 0.
    MESSAGE e108(/psyng/sw) WITH admf_txt.
  ENDIF.

  AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
           ID 'ACTVT' FIELD l_actvt
           ID 'Y&SW_VRSIO' FIELD sodvrsio.
  IF sy-subrc <> 0.
    MESSAGE e108(/psyng/sw) WITH admf_txt text-b00 sodvrsio.
  ENDIF.
ENDFORM.                    " authority_check
*&---------------------------------------------------------------------*
*&      Form  download_data
*&---------------------------------------------------------------------*
*       Load data that will be downloaded
*----------------------------------------------------------------------*
FORM download_data.
DATA : lt_conh             TYPE  TABLE OF /psyng/conflict  WITH HEADER
LINE,
wa_conh             TYPE  /psyng/conflict,
lt_funh             TYPE  TABLE OF /psyng/function  WITH HEADER LINE,
wa_funh             TYPE  /psyng/function,
lt_fund             TYPE  TABLE OF /psyng/functtran WITH HEADER LINE,
lt_funt             TYPE  TABLE OF /psyng/texts     WITH HEADER LINE,
lt_objd             TYPE  TABLE OF /psyng/faobj2    WITH HEADER LINE,
lt_cond             TYPE  TABLE OF /psyng/confdet   WITH HEADER LINE,
lt_cont             TYPE  TABLE OF /psyng/texts     WITH HEADER LINE,
lt_cono             TYPE  TABLE OF /psyng/conowner  WITH HEADER LINE,
lt_conpmit          TYPE  TABLE OF /psyng/conpmit  WITH HEADER LINE,
lt_cah              TYPE  TABLE OF /psyng/swaudhdr  WITH HEADER LINE,
lt_cad              TYPE  TABLE OF /psyng/swaudc2   WITH HEADER LINE,
lt_cat              TYPE  TABLE OF /psyng/texts     WITH HEADER LINE,
lt_ct               TYPE  TABLE OF /psyng/critcodes WITH HEADER LINE,
lt_ctxt             TYPE  TABLE OF /psyng/texts     WITH HEADER LINE,
lt_cr               TYPE  TABLE OF /psyng/criroles  WITH HEADER LINE,
lt_crtxt            TYPE TABLE OF /psyng/texts     WITH HEADER LINE,
lt_cp               TYPE TABLE OF /psyng/criprof   WITH HEADER LINE,
lt_cptxt            TYPE TABLE OF /psyng/texts     WITH HEADER LINE,
lt_syscon           TYPE TABLE OF /psyng/sw_syscon WITH HEADER LINE,
lt_sysfun           TYPE TABLE OF /psyng/sw_sysfun WITH HEADER LINE,
lt_sysca            TYPE TABLE OF /psyng/sw_sysca WITH HEADER LINE,
lt_systcd           TYPE TABLE OF /psyng/sw_systcd WITH HEADER LINE,
l_index             TYPE sy-tabix,
l_downloadfailed(3),
lt_corg             TYPE  TABLE OF /psyng/swsodorgo  WITH HEADER LINE,
ls_corg             TYPE  /psyng/swsodorgo.

* structure for function texts
  DATA: BEGIN OF lt_function_texts OCCURS 0,
          function LIKE /psyng/function-function,
          line     LIKE /psyng/texts-line,
          text     LIKE /psyng/texts-text,
          spras    LIKE /psyng/texts-spras,
        END OF lt_function_texts.

* structure  for conflict texts
  DATA: BEGIN OF lt_conflict_texts OCCURS 0,
          conid LIKE /psyng/conflict-conid,
          line  LIKE /psyng/texts-line,
          text  LIKE /psyng/texts-text,
          spras LIKE /psyng/texts-spras,
        END OF lt_conflict_texts.

* structure for critical auth. texts
  DATA: BEGIN OF lt_cauth_texts OCCURS 0,
          swaudid LIKE /psyng/swaudhdr-swaudid,
          line    LIKE /psyng/texts-line,
          text    LIKE /psyng/texts-text,
          spras   LIKE /psyng/texts-spras,
        END OF lt_cauth_texts.

  DATA: l_text TYPE string.

* structure for critical transaction texts
  DATA : BEGIN OF lt_critrans_texts OCCURS 0,
           tcode LIKE /psyng/critcodes-tcode,
           line  LIKE /psyng/texts-line,
           text  LIKE /psyng/texts-text,
           spras LIKE /psyng/texts-spras,
         END OF lt_critrans_texts.

* structure for critical roles texts
  DATA : BEGIN OF lt_criroles_texts OCCURS 0,
           agr_name LIKE /psyng/criroles-agr_name,
           line     LIKE /psyng/texts-line,
           text     LIKE /psyng/texts-text,
           spras    LIKE /psyng/texts-spras,
         END OF lt_criroles_texts.

* structure for critical profiles texts
  DATA : BEGIN OF lt_criprof_texts OCCURS 0,
           profile LIKE /psyng/criprof-profile,
           line    LIKE /psyng/texts-line,
           text    LIKE /psyng/texts-text,
           spras   LIKE /psyng/texts-spras,
         END OF lt_criprof_texts.

*--Function Headers
  IF f_funh = 'X'.

    SELECT * FROM /psyng/function INTO TABLE lt_funh
      WHERE vrsio = sodvrsio.
    SORT lt_funh.
* Code by Shekhar 23/08/2013 SE 3.1 Development ITEM C5
* Start Fix
    LOOP AT lt_funh INTO wa_funh.
      l_index = sy-tabix.
      AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
              ID 'ACTVT' FIELD 'DL'
              ID 'Y&SW_VRSIO' FIELD sodvrsio
              ID 'Y&SW_FUNCT' FIELD wa_funh-function.
      IF sy-subrc <> 0.
        CONCATENATE text-e14 text-005 INTO l_text.
        PERFORM log USING fn_funh 'E' '' '' wa_funh-function
                                            wa_funh-description
                                            l_text.
        DELETE lt_funh INDEX l_index.
        CLEAR: l_index, wa_funh, l_text.
      ENDIF.
    ENDLOOP.
    PERFORM download TABLES lt_funh
                     USING fn_funh text-112
                     CHANGING l_downloadfailed.
  ENDIF.


*--Function Details
  IF f_fund = 'X'.
    IF NOT f_funh EQ 'X'.
*      SELECT * FROM /psyng/function INTO TABLE lt_funh
*       WHERE vrsio = sodvrsio.

      SELECT mandt
            function
             vrsio
             description
             owner
             busarea
             create_usr
             create_dat
             create_tim
             change_usr
             change_dat
             change_tim
       FROM /psyng/function INTO CORRESPONDING FIELDS OF TABLE lt_funh
       WHERE vrsio = sodvrsio.
      SORT lt_funh.
      LOOP AT lt_funh INTO wa_funh.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
                ID 'ACTVT' FIELD 'DL'
                ID 'Y&SW_VRSIO' FIELD sodvrsio
                ID 'Y&SW_FUNCT' FIELD wa_funh-function.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-005 INTO l_text.
          PERFORM log USING fn_fund 'E' '' ''  wa_funh-function ''
                                               l_text.

          DELETE lt_funh INDEX l_index.
          CLEAR: l_index, wa_funh, l_text.
        ENDIF.
      ENDLOOP.
    ENDIF.

    SELECT * FROM /psyng/functtran INTO TABLE lt_fund
             WHERE vrsio = sodvrsio.
    CLEAR: l_index.
    LOOP AT lt_fund.
      l_index = sy-tabix.
      READ TABLE lt_funh WITH KEY function = lt_fund-functionid.
      IF sy-subrc <> 0.
        DELETE lt_fund WHERE functionid = lt_fund-functionid.
      ENDIF.
*      IF lt_fund-type = ''.
*        IF lt_fund-fioriid = ''.
*          lt_fund-type = 'T'.
*        ELSE.
*          lt_fund-type = 'F'.
*        ENDIF.
*        MODIFY lt_fund INDEX l_index.
*      ENDIF.
    ENDLOOP.
    SORT lt_fund.
    PERFORM download TABLES lt_fund
                   USING fn_fund text-116
                   CHANGING l_downloadfailed.
  ENDIF.
*--Function Texts
  IF f_funt = 'X'.
    IF NOT f_funh EQ 'X'.
*      SELECT * FROM /psyng/function INTO TABLE lt_funh
*       WHERE vrsio = sodvrsio.

      SELECT mandt function
             vrsio
             description
             owner
             busarea
             create_usr
             create_dat
             create_tim
             change_usr
             change_dat
             change_tim
       FROM /psyng/function INTO CORRESPONDING FIELDS OF TABLE lt_funh
       WHERE vrsio = sodvrsio.
      SORT lt_funh.
      LOOP AT lt_funh INTO wa_funh.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
                ID 'ACTVT' FIELD 'DL'
                ID 'Y&SW_VRSIO' FIELD sodvrsio
                ID 'Y&SW_FUNCT' FIELD wa_funh-function.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-005 INTO l_text.
          PERFORM log USING fn_funt 'E' '' '' wa_funh-function
                                            ''
                                            l_text.
          DELETE lt_funh INDEX l_index.
          CLEAR: l_index, wa_funh, l_text.
        ENDIF.
      ENDLOOP.
    ENDIF.

    SELECT * FROM /psyng/texts INTO TABLE lt_funt
    WHERE
      object = 'F'     AND
      vrsio = sodvrsio
*      AND
*      spras = sy-langu
     .
    SORT lt_funt.

    LOOP AT lt_funt.

      READ TABLE lt_funh WITH KEY function =  lt_funt-textname.
      IF sy-subrc <> 0.
        DELETE lt_funt WHERE textname = lt_funt-textname.
      ENDIF.

    ENDLOOP.

    LOOP AT lt_funt .
      lt_function_texts-function = lt_funt-textname(12).
      lt_function_texts-line     = lt_funt-line.
      lt_function_texts-text     = lt_funt-text.
      lt_function_texts-spras    = lt_funt-spras.
      APPEND lt_function_texts.
    ENDLOOP.
    PERFORM download TABLES lt_function_texts
                   USING fn_funt text-022
                   CHANGING l_downloadfailed.
  ENDIF.

*--Object Details

  IF f_objd = 'X'.
    IF NOT f_funh EQ 'X'.
*      SELECT * FROM /psyng/function INTO TABLE lt_funh
*         WHERE vrsio = sodvrsio.

      SELECT mandt  function
             vrsio
             description
             owner
             busarea
             create_usr
             create_dat
             create_tim
             change_usr
             change_dat
             change_tim
       FROM /psyng/function INTO CORRESPONDING FIELDS OF TABLE lt_funh
       WHERE vrsio = sodvrsio.

      SORT lt_funh.
      LOOP AT lt_funh INTO wa_funh.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
                ID 'ACTVT' FIELD 'DL'
                ID 'Y&SW_VRSIO' FIELD sodvrsio
                ID 'Y&SW_FUNCT' FIELD wa_funh-function.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-005 INTO l_text.
          PERFORM log USING fn_objd 'E' '' ''  wa_funh-function ''
                                               l_text.

          DELETE lt_funh INDEX l_index.
          CLEAR: l_index, wa_funh, l_text.
        ENDIF.
      ENDLOOP.
    ENDIF.

    SELECT * FROM /psyng/faobj2 INTO TABLE lt_objd
      WHERE vrsio = sodvrsio.

    LOOP AT lt_objd.
      READ TABLE lt_funh WITH KEY function = lt_objd-funid.
      IF sy-subrc <> 0.
        DELETE lt_objd WHERE funid = lt_objd-funid.
      ENDIF.
    ENDLOOP.

    SORT lt_objd.
    PERFORM download TABLES lt_objd
                   USING fn_objd text-115
                   CHANGING l_downloadfailed.


  ENDIF.

*--Function Filters
  IF f_fnfltr = 'X'.

    SELECT * FROM /psyng/sw_sysfun INTO TABLE lt_sysfun
      WHERE vrsio = sodvrsio.
    SORT lt_sysfun.


    LOOP AT lt_sysfun .
      l_index = sy-tabix.
      AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
         ID 'ACTVT' FIELD 'DL'
         ID 'Y&SW_VRSIO' FIELD sodvrsio
         ID 'Y&SW_CONID' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        CONCATENATE text-e14 text-t06 INTO l_text.
        PERFORM log USING fn_fflt 'E' '' '' lt_sysfun-function
                                            lt_sysfun-application
                                            l_text.
        DELETE lt_sysfun INDEX l_index.
        CLEAR: l_index, l_text.
      ENDIF.
    ENDLOOP.


    PERFORM download TABLES lt_sysfun
                   USING fn_fflt text-t07
                   CHANGING l_downloadfailed.

  ENDIF.


*--Conflict Headers
  IF f_conh = 'X'.

    SELECT * FROM /psyng/conflict INTO TABLE lt_conh
      WHERE vrsio = sodvrsio.
    SORT lt_conh.

* Code by Shekhar 23/08/2013 SE 3.1 Development ITEM C7
* Start Fix

    LOOP AT lt_conh INTO wa_conh.
      l_index = sy-tabix.
      AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
                  ID 'ACTVT' FIELD 'DL'
                  ID 'Y&SW_CONID' FIELD wa_conh-conid
                  ID 'Y&SW_VRSIO' FIELD sodvrsio.
      IF sy-subrc <> 0.
        CONCATENATE text-e14 text-006 INTO l_text.
        PERFORM log USING fn_conh 'E' '' '' wa_conh-conid
                                            wa_conh-description
                                            l_text.
        DELETE lt_conh INDEX l_index.
        CLEAR: l_index, wa_conh, l_text.
      ENDIF.
    ENDLOOP.


    PERFORM download TABLES lt_conh
                   USING fn_conh text-113
                   CHANGING l_downloadfailed.

  ENDIF.
*--Conflict Details
  IF f_cond = 'X'.
    IF NOT f_conh EQ 'X'.
      SELECT * FROM /psyng/conflict INTO TABLE lt_conh
        WHERE vrsio = sodvrsio.
      SORT lt_conh.

      LOOP AT lt_conh INTO wa_conh.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
                    ID 'ACTVT' FIELD 'DL'
                    ID 'Y&SW_CONID' FIELD wa_conh-conid
                    ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-006 INTO l_text.
          PERFORM log USING fn_cond 'E' '' '' wa_conh-conid
                                            ''
                                            l_text.

          DELETE lt_conh INDEX l_index.
          CLEAR: l_index, wa_conh, l_text.
        ENDIF.
      ENDLOOP.
    ENDIF.

    SELECT * FROM /psyng/confdet INTO TABLE lt_cond
      WHERE vrsio = sodvrsio.
    SORT lt_cond.

    LOOP AT lt_cond.
      READ TABLE lt_conh WITH KEY conid = lt_cond-conid.
      IF sy-subrc <> 0.
        DELETE lt_cond WHERE conid = lt_cond-conid.
      ENDIF.
    ENDLOOP.
    PERFORM download TABLES lt_cond
                   USING fn_cond text-114
                   CHANGING l_downloadfailed.
  ENDIF.

*--Conflict Texts
  IF f_cont = 'X'.
    IF NOT f_conh EQ 'X'.
*      SELECT * FROM /psyng/conflict INTO TABLE lt_conh
*        WHERE vrsio = sodvrsio.
      SELECT mandt conid vrsio description owner imp busarea create_usr
              create_dat
              create_tim
              change_usr
              change_dat
              change_tim
              contid
              inactive
              subarea
              risk
              FROM /psyng/conflict
      INTO CORRESPONDING FIELDS OF TABLE lt_conh
        WHERE vrsio = sodvrsio.
      SORT lt_conh.

      LOOP AT lt_conh INTO wa_conh.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
                    ID 'ACTVT' FIELD 'DL'
                    ID 'Y&SW_CONID' FIELD wa_conh-conid
                    ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-006 INTO l_text.
          PERFORM log USING fn_cont 'E' '' '' wa_conh-conid
                                            ''
                                            l_text.

          DELETE lt_conh INDEX l_index.
          CLEAR: l_index, wa_conh, l_text.
        ENDIF.
      ENDLOOP.
    ENDIF.

    SELECT * FROM /psyng/texts INTO TABLE lt_cont WHERE
     object = 'C'     AND
     vrsio = sodvrsio
*     AND
*     spras = sy-langu
.
    SORT lt_cont.

    LOOP AT lt_cont.
      READ TABLE lt_conh WITH KEY conid = lt_cont-textname.
      IF sy-subrc <> 0.
        DELETE lt_cont WHERE textname = lt_cont-textname.
      ENDIF.
    ENDLOOP.


    LOOP AT lt_cont .
      lt_conflict_texts-conid    = lt_cont-textname(12).
      lt_conflict_texts-line     = lt_cont-line.
      lt_conflict_texts-text     = lt_cont-text.
      lt_conflict_texts-spras     = lt_cont-spras.
      APPEND lt_conflict_texts.
    ENDLOOP.
    PERFORM download TABLES lt_conflict_texts
                   USING fn_cont text-023
                   CHANGING l_downloadfailed.
  ENDIF.

*--Conflict owners
  IF f_cono = 'X'.
    IF NOT f_conh EQ 'X'.
*      SELECT * FROM /psyng/conflict INTO TABLE lt_conh
*        WHERE vrsio = sodvrsio.

      SELECT mandt conid vrsio description owner imp busarea create_usr
              create_dat
              create_tim
              change_usr
              change_dat
              change_tim
              contid
              inactive
              subarea
              risk
              FROM /psyng/conflict
      INTO CORRESPONDING FIELDS OF TABLE lt_conh
        WHERE vrsio = sodvrsio.
      SORT lt_conh.

      LOOP AT lt_conh INTO wa_conh.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
                    ID 'ACTVT' FIELD 'DL'
                    ID 'Y&SW_CONID' FIELD wa_conh-conid
                    ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-006 INTO l_text.
          PERFORM log USING fn_cono 'E' '' '' wa_conh-conid
                                            ''
                                            l_text.
          DELETE lt_conh INDEX l_index.
          CLEAR: l_index, wa_conh, l_text.
        ENDIF.
      ENDLOOP.
    ENDIF.

    SELECT * FROM /psyng/conowner INTO TABLE lt_cono
      WHERE vrsio = sodvrsio.

    LOOP AT lt_cono.
      READ TABLE lt_conh WITH KEY conid = lt_cono-conid.
      IF sy-subrc <> 0.
        DELETE lt_cono WHERE conid = lt_cono-conid.
      ENDIF.
    ENDLOOP.

    SORT lt_cono.
    PERFORM download TABLES lt_cono
                   USING fn_cono text-155
                   CHANGING l_downloadfailed.

  ENDIF.

*--Conflict mitigations
  IF f_conm = 'X'.
    IF NOT f_conh EQ 'X'.
*      SELECT * FROM /psyng/conflict INTO TABLE lt_conh
*        WHERE vrsio = sodvrsio.

      SELECT mandt conid vrsio description owner imp busarea create_usr
              create_dat
              create_tim
              change_usr
              change_dat
              change_tim
              contid
              inactive
              subarea
              risk
              FROM /psyng/conflict
      INTO CORRESPONDING FIELDS OF TABLE lt_conh
        WHERE vrsio = sodvrsio.
      SORT lt_conh.

      LOOP AT lt_conh INTO wa_conh.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
                    ID 'ACTVT' FIELD 'DL'
                    ID 'Y&SW_CONID' FIELD wa_conh-conid
                    ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-006 INTO l_text.
          PERFORM log USING fn_conm 'E' '' '' wa_conh-conid
                                            ''
                                            l_text.
          DELETE lt_conh INDEX l_index.
          CLEAR: l_index, wa_conh, l_text.
        ENDIF.
      ENDLOOP.
    ENDIF.

    SELECT * FROM /psyng/conpmit INTO TABLE lt_conpmit
      WHERE vrsio = sodvrsio.

    LOOP AT lt_conpmit.
      READ TABLE lt_conh WITH KEY conid = lt_conpmit-conid.
      IF sy-subrc <> 0.
        DELETE lt_conpmit WHERE conid = lt_conpmit-conid.
      ENDIF.
    ENDLOOP.

    SORT lt_conpmit.
    PERFORM download TABLES lt_conpmit
                   USING fn_conm text-190
                   CHANGING l_downloadfailed.

  ENDIF.

*--Conflict Filters
  IF f_conflt = 'X'.

    SELECT * FROM /psyng/sw_syscon INTO TABLE lt_syscon
      WHERE vrsio = sodvrsio.
    SORT lt_syscon.


    LOOP AT lt_syscon .
      l_index = sy-tabix.
      AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
         ID 'ACTVT' FIELD 'DL'
         ID 'Y&SW_VRSIO' FIELD sodvrsio
         ID 'Y&SW_CONID' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        CONCATENATE text-e14 text-t06 INTO l_text.
        PERFORM log USING fn_cnflt 'E' '' '' lt_syscon-conid
                                            lt_syscon-application
                                            l_text.
        DELETE lt_syscon INDEX l_index.
        CLEAR: l_index, l_text.
      ENDIF.
    ENDLOOP.


    PERFORM download TABLES lt_syscon
                   USING fn_cnflt text-t08
                   CHANGING l_downloadfailed.

  ENDIF.

* Begin Changes by DDHIMAN 08.11.19
  IF f_corg EQ 'X'.
    SELECT mandt
            vrsio
            conid
            field
            type
            description
            FROM /psyng/swsodorgo
    INTO CORRESPONDING FIELDS OF TABLE lt_corg
      WHERE vrsio = sodvrsio.
    SORT lt_corg.

    LOOP AT lt_corg INTO ls_corg.
      l_index = sy-tabix.
      AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
                  ID 'ACTVT' FIELD 'DL'
                  ID 'Y&SW_CONID' FIELD ls_corg-conid
                  ID 'Y&SW_VRSIO' FIELD sodvrsio.
      IF sy-subrc <> 0.
        CONCATENATE text-e14 text-006 INTO l_text.
        PERFORM log USING fn_corg 'E' '' '' ls_corg-conid
                                          ''
                                          l_text.
        DELETE lt_corg INDEX l_index.
        CLEAR: l_index, ls_corg, l_text.
      ENDIF.
    ENDLOOP.

    PERFORM download TABLES lt_corg
                   USING fn_corg text-155
                   CHANGING l_downloadfailed.

  ENDIF.
* End Changes by DDHIMAN 08.11.19


*--Critical Auth Headers
  IF f_cah = 'X'.
*    SELECT * FROM /psyng/swaudhdr INTO TABLE lt_cah
*      WHERE vrsio = sodvrsio.
    SELECT * FROM /psyng/swaudhdr
     INTO CORRESPONDING FIELDS OF TABLE lt_cah
      WHERE vrsio = sodvrsio.
    SORT lt_cah.

    LOOP AT lt_cah.
      l_index = sy-tabix.
      AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
                   ID 'ACTVT' FIELD 'DL'
                   ID 'Y&SW_AUTID' FIELD lt_cah-swaudid
                   ID 'Y&SW_VRSIO' FIELD sodvrsio.
      IF sy-subrc <> 0.
        CONCATENATE text-e14 text-007 INTO l_text.
        PERFORM log USING fn_cah 'E' '' '' lt_cah-swaudid
                                           lt_cah-description
                                           l_text.
        DELETE lt_cah INDEX l_index.
        CLEAR: l_index, l_text.
      ENDIF.
    ENDLOOP.

    PERFORM download TABLES lt_cah
                   USING fn_cah text-111
                   CHANGING l_downloadfailed.
  ENDIF.

*--Critical Auth Details
  IF f_cad = 'X'.
    IF NOT f_cah EQ 'X'.
      SELECT * FROM /psyng/swaudhdr INTO TABLE lt_cah
       WHERE vrsio = sodvrsio.
      SORT lt_cah.
      LOOP AT lt_cah.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
                     ID 'ACTVT' FIELD 'DL'
                     ID 'Y&SW_AUTID' FIELD lt_cah-swaudid
                     ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-007 INTO l_text.
          PERFORM log USING fn_cad 'E' '' '' lt_cah-swaudid
                                            ''
                                            l_text.

          DELETE lt_cah INDEX l_index.
          CLEAR: l_index, l_text.
        ENDIF.
      ENDLOOP.
    ENDIF.

*    SELECT * FROM /psyng/swaudc2 INTO TABLE lt_cad
*      WHERE vrsio = sodvrsio.

    SELECT * FROM /psyng/swaudc2
     INTO CORRESPONDING FIELDS OF TABLE lt_cad
      WHERE vrsio = sodvrsio.
    SORT lt_cad.

    LOOP AT lt_cad.
      READ TABLE lt_cah WITH KEY swaudid = lt_cad-swaudid.
      IF sy-subrc <> 0.
        DELETE lt_cad WHERE swaudid = lt_cad-swaudid.
      ENDIF.
    ENDLOOP.

    PERFORM download TABLES lt_cad
                   USING fn_cad text-110
                   CHANGING l_downloadfailed.
  ENDIF.

*--Critical Auth Texts
  IF f_cat = 'X'.
    IF NOT f_cah EQ 'X'.
      SELECT * FROM /psyng/swaudhdr INTO TABLE lt_cah
       WHERE vrsio = sodvrsio.
      SORT lt_cah.
      LOOP AT lt_cah.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
                     ID 'ACTVT' FIELD 'DL'
                     ID 'Y&SW_AUTID' FIELD lt_cah-swaudid
                     ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-007 INTO l_text.
          PERFORM log USING fn_cat 'E' '' '' lt_cah-swaudid
                                            ''
                                            l_text.

          DELETE lt_cah INDEX l_index.
          CLEAR: l_index, l_text.
        ENDIF.
      ENDLOOP.
    ENDIF.

    SELECT * FROM /psyng/texts INTO TABLE lt_cat WHERE
      object = 'T'     AND
      vrsio = sodvrsio
*      AND
*      spras = sy-langu
      .
    SORT lt_cat.

    LOOP AT lt_cat.
      READ TABLE lt_cah WITH KEY swaudid = lt_cat-textname.
      IF sy-subrc <> 0.
        DELETE lt_cat WHERE textname = lt_cat-textname.
      ENDIF.
    ENDLOOP.


    LOOP AT lt_cat .
      lt_cauth_texts-swaudid  = lt_cat-textname(12).
      lt_cauth_texts-line     = lt_cat-line.
      lt_cauth_texts-text     = lt_cat-text.
      lt_cauth_texts-spras    = lt_cat-spras.
      APPEND lt_cauth_texts.
    ENDLOOP.
    PERFORM download TABLES lt_cauth_texts
                   USING fn_cat text-023
                   CHANGING l_downloadfailed.
  ENDIF.

*--Critical auth. Filters
  IF f_cafltr = 'X'.

    SELECT * FROM /psyng/sw_sysca INTO TABLE lt_sysca
      WHERE vrsio = sodvrsio.
    SORT lt_sysca.


    LOOP AT lt_sysca .
      l_index = sy-tabix.
      AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
        ID 'ACTVT' FIELD 'DL'
        ID 'Y&SW_VRSIO' FIELD sodvrsio
        ID 'Y&SW_CONID' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        CONCATENATE text-e14 text-t06 INTO l_text.
        PERFORM log USING fn_catfl 'E' '' '' lt_sysca-swaudid
                                            lt_sysca-application
                                            l_text.
        DELETE lt_sysca INDEX l_index.
        CLEAR: l_index, l_text.
      ENDIF.
    ENDLOOP.


    PERFORM download TABLES lt_sysca
                   USING fn_catfl text-t09
                   CHANGING l_downloadfailed.

  ENDIF.


*--Critical Tcodes
  IF f_ct = 'X'.

*    SELECT * FROM /psyng/critcodes INTO TABLE lt_ct
*     WHERE vrsio = sodvrsio.
    SELECT mandt tcode
            vrsio
            owner
            busarea
            imp
            create_usr
            create_dat
            create_tim
            change_usr
            change_dat
            change_tim
 FROM /psyng/critcodes
     INTO CORRESPONDING FIELDS OF TABLE lt_ct
     WHERE vrsio = sodvrsio.

    SORT lt_ct.

    LOOP AT lt_ct.
      l_index = sy-tabix.
      AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
                ID 'ACTVT' FIELD 'DL'
                ID 'Y&SW_VRSIO' FIELD sodvrsio.
      IF sy-subrc <> 0.
        CONCATENATE text-e14 text-008 INTO l_text.
        PERFORM log USING fn_ct 'E' '' '' lt_ct-tcode
                                            sodvrsio
                                            l_text.
        DELETE lt_ct INDEX l_index.
        CLEAR: l_index, l_text, lt_ct.
      ENDIF.
    ENDLOOP.

    PERFORM download TABLES lt_ct
                   USING fn_ct text-109
                   CHANGING l_downloadfailed.
  ENDIF.

*--Critical Tcodes Texts
  IF f_ctxt = 'X'.
    IF NOT f_ct EQ 'X'.
*      SELECT * FROM /psyng/critcodes INTO TABLE lt_ct
*      WHERE vrsio = sodvrsio.
      SELECT mandt tcode
            vrsio
            owner
            busarea
            imp
            create_usr
            create_dat
            create_tim
            change_usr
            change_dat
            change_tim
 FROM /psyng/critcodes
       INTO CORRESPONDING FIELDS OF TABLE lt_ct
       WHERE vrsio = sodvrsio.

      SORT lt_ct.

      LOOP AT lt_ct.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
                    ID 'ACTVT' FIELD 'DL'
                    ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-010 INTO l_text.
          PERFORM log USING fn_ctxt 'E' '' '' lt_ct-tcode
                                            sodvrsio
                                            l_text.

          DELETE lt_ct INDEX l_index.
          CLEAR: l_index, l_text, lt_ct.
        ENDIF.
      ENDLOOP.
    ENDIF.

    SELECT * FROM /psyng/texts
             INTO TABLE lt_ctxt
             WHERE object = 'X' AND
                   vrsio = sodvrsio
*                   AND
*                   spras = sy-langu
                   .

    SORT lt_ctxt.

    LOOP AT lt_ctxt.
      READ TABLE lt_ct WITH KEY tcode = lt_ctxt-textname.
      IF sy-subrc <> 0.
        DELETE lt_ctxt WHERE textname = lt_ctxt-textname.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_ctxt .
      lt_critrans_texts-tcode    = lt_ctxt-textname.
      lt_critrans_texts-line     = lt_ctxt-line.
      lt_critrans_texts-text     = lt_ctxt-text.
      lt_critrans_texts-spras    = lt_ctxt-spras.
      APPEND lt_critrans_texts.
    ENDLOOP.

    PERFORM download TABLES lt_critrans_texts
                   USING fn_ctxt text-024
                   CHANGING l_downloadfailed.
  ENDIF.

*--Critical Roles

  IF f_cr = 'X'.

    SELECT * FROM /psyng/criroles INTO TABLE lt_cr
     WHERE vrsio = sodvrsio.

    SORT lt_cr.

    LOOP AT lt_cr.
      l_index = sy-tabix.
      AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
                ID 'ACTVT' FIELD 'DL'
                ID 'Y&SW_VRSIO' FIELD sodvrsio.
      IF sy-subrc <> 0.
        CONCATENATE text-e14 text-012 INTO l_text.
        PERFORM log USING fn_cr 'E' '' '' lt_cr-agr_name
                                            sodvrsio
                                            l_text.
        DELETE lt_cr INDEX l_index.
        CLEAR: l_index, l_text, lt_cr.
      ENDIF.
    ENDLOOP.

    PERFORM download TABLES lt_cr
                   USING fn_cr text-118
                   CHANGING l_downloadfailed.
  ENDIF.

*--Critical Roles Texts

  IF f_crtxt = 'X'.
    IF NOT f_cr EQ 'X'.
      SELECT * FROM /psyng/criroles INTO TABLE lt_cr
      WHERE vrsio = sodvrsio.

      SORT lt_cr.

      LOOP AT lt_cr.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
                    ID 'ACTVT' FIELD 'DL'
                    ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-012 INTO l_text.
          PERFORM log USING fn_crtxt 'E' '' '' lt_cr-agr_name
                                            sodvrsio
                                            l_text.

          DELETE lt_cr INDEX l_index.
          CLEAR: l_index, l_text , lt_cr.
        ENDIF.
      ENDLOOP.
    ENDIF.

    SELECT * FROM /psyng/texts
             INTO TABLE lt_crtxt
             WHERE object = 'Q' AND
                   vrsio = sodvrsio
*                   AND
*                   spras = sy-langu
                   .

    SORT lt_crtxt.

    LOOP AT lt_crtxt.
      READ TABLE lt_cr WITH KEY agr_name = lt_crtxt-textname.
      IF sy-subrc <> 0.
        DELETE lt_crtxt WHERE textname = lt_crtxt-textname.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_crtxt .
      lt_criroles_texts-agr_name    = lt_crtxt-textname.
      lt_criroles_texts-line     = lt_crtxt-line.
      lt_criroles_texts-text     = lt_crtxt-text.
      lt_criroles_texts-spras     = lt_crtxt-spras.
      APPEND lt_criroles_texts.
    ENDLOOP.

    PERFORM download TABLES lt_criroles_texts
                   USING fn_crtxt text-027
                   CHANGING l_downloadfailed.
  ENDIF.

*--Critical profile

  IF f_cp = 'X'.

    SELECT * FROM /psyng/criprof INTO TABLE lt_cp
     WHERE vrsio = sodvrsio.

    SORT lt_cp.

    LOOP AT lt_cp.
      l_index = sy-tabix.
      AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
                ID 'ACTVT' FIELD 'DL'
                ID 'Y&SW_VRSIO' FIELD sodvrsio.
      IF sy-subrc <> 0.
        CONCATENATE text-e14 text-013 INTO l_text.
        PERFORM log USING fn_cp 'E' '' '' lt_cp-profile
                                            sodvrsio
                                            l_text.
        DELETE lt_cp INDEX l_index.
        CLEAR: lt_cp , l_index, l_text.
      ENDIF.
    ENDLOOP.

    PERFORM download TABLES lt_cp
                   USING fn_cp text-164
                   CHANGING l_downloadfailed.
  ENDIF.

*--Critical profile Texts

  IF f_cptxt = 'X'.
    IF NOT f_cp EQ 'X'.
      SELECT * FROM /psyng/criprof INTO TABLE lt_cp
      WHERE vrsio = sodvrsio.

      SORT lt_cp.

      LOOP AT lt_cp.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
                    ID 'ACTVT' FIELD 'DL'
                    ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-013 INTO l_text.
          PERFORM log USING fn_cptxt 'E' '' '' lt_cp-profile
                                            sodvrsio
                                            l_text.

          DELETE lt_cp INDEX l_index.
          CLEAR: l_index, l_text , lt_cp.
        ENDIF.
      ENDLOOP.
    ENDIF.

    SELECT * FROM /psyng/texts
             INTO TABLE lt_cptxt
             WHERE object = 'P' AND
                   vrsio = sodvrsio
*                   AND
*                   spras = sy-langu
                   .

    SORT lt_cptxt.

    LOOP AT lt_cptxt.
      READ TABLE lt_cp WITH KEY profile = lt_cptxt-textname.
      IF sy-subrc <> 0.
        DELETE lt_cptxt WHERE textname = lt_cptxt-textname.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_cptxt.
      lt_criprof_texts-profile    = lt_cptxt-textname.
      lt_criprof_texts-line     = lt_cptxt-line.
      lt_criprof_texts-text     = lt_cptxt-text.
      lt_criprof_texts-spras     = lt_cptxt-spras.
      APPEND lt_criprof_texts.
    ENDLOOP.

    PERFORM download TABLES lt_criprof_texts
                   USING fn_cptxt text-028
                   CHANGING l_downloadfailed.
  ENDIF.

*--Critical transaction Filters
  IF f_ctfltr = 'X'.

    SELECT * FROM /psyng/sw_systcd INTO TABLE lt_systcd
      WHERE vrsio = sodvrsio.
    SORT lt_systcd.


    LOOP AT lt_systcd .
      l_index = sy-tabix.
      AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
         ID 'ACTVT' FIELD 'DL'
         ID 'Y&SW_VRSIO' FIELD sodvrsio
         ID 'Y&SW_CONID' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        CONCATENATE text-e14 text-t06 INTO l_text.
        PERFORM log USING fn_ctflt 'E' '' '' lt_systcd-tcode
                                             ' '
                                            l_text.
        DELETE lt_systcd INDEX l_index.
        CLEAR: l_index, l_text.
      ENDIF.
    ENDLOOP.


    PERFORM download TABLES lt_systcd
                   USING fn_ctflt text-t10
                   CHANGING l_downloadfailed.

  ENDIF.

ENDFORM.                    " download_data

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
FORM log USING    i_file
                  i_type
                  i_object
                  i_object_id
                  i_field
                  i_value
                  i_message
                  .
  CLEAR gt_log.
  gt_log-filename  = i_file.
  CASE i_type.
    WHEN 'S'."Success
      gt_log-type      =  '@08@'.
    WHEN 'W'."Warning
      gt_log-type      =  '@09@'.
    WHEN 'E'."Error
      gt_log-type      =  '@0A@'.
  ENDCASE.
  gt_log-object    = i_object.
  gt_log-object_id = i_object_id.
  gt_log-fieldname = i_field.
  gt_log-value     = i_value.
  gt_log-message   = i_message.
  APPEND gt_log.

ENDFORM.                    " log
*---------------------------------------------------------------------*
*       FORM output_log                                               *
*---------------------------------------------------------------------*
*       Show log in ALV format                                        *
*---------------------------------------------------------------------*
FORM output_log.
  DATA: ls_variant     TYPE disvariant,
        alv_layout     TYPE slis_layout_alv,
        i_fieldcat_alv TYPE slis_t_fieldcat_alv.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv,
        l_program       LIKE sy-repid.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  l_program = sy-repid.
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
*  PERFORM build_sort_table.
*  PERFORM adjust_columns.
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

ENDFORM.                    " output_log

*&---------------------------------------------------------------------*
*&      Form  download
*&---------------------------------------------------------------------*
*       Download tables
*----------------------------------------------------------------------*
*      -->IT_TABLE          Table to be downloaded
*      -->I_FILENAME        File name
*      -->I_ERR_TEXT        Error text
*      <--E_DOWNLOADFAILED  Download failed indicator
*----------------------------------------------------------------------*
FORM download TABLES   it_table
              USING    i_filename TYPE rlgrap-filename
                       i_err_text
              CHANGING e_downloadfailed.
  DATA: l_filename      TYPE string,
*   DATA: l_filename TYPE rlgrap-filename,
        l_err_mess      TYPE bapiret2-message,
        l_msgv1         TYPE bapiret2-message_v1,
        l_msgv2         TYPE bapiret2-message_v2,
        l_download_size TYPE i,
        l_msg(200)      TYPE c,
        l_text(10)      TYPE c.

  DATA: v_file TYPE string.
  DATA: v_dir TYPE string.

  CONCATENATE basepath '\' i_filename INTO l_filename.

  IF l_filename NP '*.txt'.
    MESSAGE s113(/psyng/sw) WITH 'Invalid Format'(189).
    LEAVE LIST-PROCESSING.
  ENDIF.
  IF it_table[] IS INITIAL.
    e_downloadfailed = 'Yes'(073).
  ENDIF.
  CLEAR l_download_size.
*BOC:HBHALLA (096)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '61'.
  IF sy-subrc = 0.
  CALL FUNCTION 'GUI_DOWNLOAD' "#EC SAST_CI_GEN_CHECK
    EXPORTING
      filename                = l_filename
      filetype                = 'ASC'
      write_field_separator   = 'X'
      dat_mode                = ' '
    IMPORTING
      filelength              = l_download_size
    TABLES
      data_tab                = it_table
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
    e_downloadfailed = 'Yes'(073).
    l_msgv1          = l_filename.
    l_msgv2          = i_err_text.
    CALL FUNCTION '/PSYNG/BC_003'
      EXPORTING
        i_subrc     = sy-subrc
        i_msgty     = 'I'
        i_msgv1     = l_msgv1
        i_msgv2     = l_msgv2
        if_no_popup = 'X'
      IMPORTING
        e_message   = l_err_mess.

    PERFORM log USING l_filename 'E' '' '' '' '' l_err_mess.
  ELSE.
    PERFORM log  USING
      l_filename 'S' '' '' '' ''  text-150.
  ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
ENDFORM.                    " download
*&---------------------------------------------------------------------*
*&      Form  delete_data
*&---------------------------------------------------------------------*
*       Delete SOD Matrix version from database
*----------------------------------------------------------------------*
FORM delete_data USING i_object if_lock.
  CHECK testrun <> 'X'. "no deletion in testrun
  IF if_lock = 'X'.
    MESSAGE e113(/psyng/sw) WITH
    'Deleting data is not allowed;records are locked.'(l07).
  ENDIF.
  IF  i_object = 'CONFLICT'.
    IF f_cond = 'X'.
*      IF NOT lt_cond[] IS INITIAL.
      DELETE FROM /psyng/confdet   WHERE vrsio = sodvrsio.
*      ENDIF.
    ENDIF.
    IF f_conh = 'X'.
*      IF NOT lt_conh IS INITIAL.
      DELETE FROM /psyng/conflict  WHERE vrsio = sodvrsio.
*      ENDIF.
    ENDIF.
    IF f_cono = 'X'.
      DELETE FROM /psyng/conowner  WHERE vrsio = sodvrsio.
    ENDIF.
    IF f_cont = 'X'.
      DELETE FROM /psyng/texts     WHERE vrsio = sodvrsio AND
                                         object = 'C'.
*--DHORIONS 2016/03/16 - Overwrite texts in all languages
*                                         AND spras = sy-langu.
    ENDIF.
*-- Delete Conflict Mitigations
    IF f_conm = 'X'.
      DELETE FROM /psyng/conpmit WHERE vrsio = sodvrsio.
    ENDIF.

    IF f_conflt = 'X'.
      DELETE FROM /psyng/sw_syscon  WHERE vrsio = sodvrsio.
    ENDIF.

  ENDIF.
  IF  i_object = 'FUNCTION'.
    IF f_fund = 'X' .
*      IF NOT lt_fund[] IS INITIAL.
      DELETE FROM /psyng/functtran WHERE vrsio = sodvrsio.
*      END,IF.
    ENDIF.

    IF f_funh = 'X'.
*      IF NOT lt_funh[] IS INITIAL.
      DELETE FROM /psyng/function  WHERE vrsio = sodvrsio.
*      ENDIF.
    ENDIF.
    IF f_objd = 'X'.
*      IF NOT lt_objd[] IS INITIAL.
      DELETE FROM /psyng/faobj2    WHERE vrsio = sodvrsio.
*      ENDIF.
    ENDIF.

    IF f_funt = 'X'.
      DELETE FROM /psyng/texts     WHERE vrsio = sodvrsio AND
                                    object = 'F'.
*--DHORIONS 2016/03/16 - Overwrite texts in all languages
*                                         AND spras = sy-langu.

    ENDIF.

    IF f_fnfltr = 'X'.
      DELETE FROM /psyng/sw_sysfun  WHERE vrsio = sodvrsio.
    ENDIF.

  ENDIF.
  IF  i_object = 'SWAUD'.
    IF f_cah = 'X'.
*      IF NOT lt_cah[] IS INITIAL.
      DELETE FROM /psyng/swaudhdr  WHERE vrsio = sodvrsio.
*      ENDIF.
    ENDIF.

    IF f_cad = 'X'.
*      IF NOT lt_cad[] IS INITIAL.
      DELETE FROM /psyng/swaudc2   WHERE vrsio = sodvrsio.
*      ENDIF.
    ENDIF.

    IF f_cat = 'X'.
      DELETE FROM /psyng/texts     WHERE vrsio = sodvrsio AND
                                    object = 'T'.
*--DHORIONS 2016/03/16 - Overwrite texts in all languages
*                                         AND spras = sy-langu.
    ENDIF.

    IF f_cafltr = 'X'.
      DELETE FROM /psyng/sw_sysca WHERE vrsio = sodvrsio.
    ENDIF.
  ENDIF.

  IF  i_object = 'CRITCODES'.
    IF f_ct = 'X'.
*      IF NOT lt_ct[] IS INITIAL.
      DELETE FROM /psyng/critcodes WHERE vrsio = sodvrsio.
*      ENDIF.
    ENDIF.
  ENDIF.

  IF i_object = 'CRITFLTR'.
    IF f_ctfltr = 'X'.
      DELETE FROM /psyng/sw_systcd  WHERE vrsio = sodvrsio.
    ENDIF.
  ENDIF.

  IF i_object = 'CRITTEXT'.
    IF f_ctxt = 'X'.
      DELETE FROM /psyng/texts   WHERE vrsio = sodvrsio AND
                                    object = 'X'.
*--DHORIONS 2016/03/16 - Overwrite texts in all languages
*                                         AND spras = sy-langu.

    ENDIF.
  ENDIF.

  IF i_object = 'CRIROLES'.
    IF f_cr = 'X'.
*      IF NOT lt_cr[] IS INITIAL.
      DELETE FROM /psyng/criroles WHERE vrsio = sodvrsio.
*      ENDIF.
    ENDIF.
  ENDIF.

  IF i_object = 'CRIRTEXT'.
    IF f_crtxt = 'X'.
      DELETE FROM /psyng/texts   WHERE vrsio = sodvrsio AND
                                    object = 'Q'.
*--DHORIONS 2016/03/16 - Overwrite texts in all languages
*                                         AND spras = sy-langu.


    ENDIF.
  ENDIF.

  IF i_object = 'CRIPROF'.
    IF f_cp = 'X'.
*      IF NOT lt_cp[,] IS INITIAL.
      DELETE FROM /psyng/criprof WHERE vrsio = sodvrsio.
*      ENDIF.
    ENDIF.
  ENDIF.

  IF i_object = 'CRIPTEXT'.
    IF f_cptxt = 'X'.
      DELETE FROM /psyng/texts   WHERE vrsio = sodvrsio AND
                                     object = 'P'.
*--DHORIONS 2016/03/16 - Overwrite texts in all languages
*                                         AND spras = sy-langu.
    ENDIF.
  ENDIF.

  IF f_corg = 'X'.
    DELETE FROM /psyng/swsodorgo  WHERE vrsio = sodvrsio.
  ENDIF.
  COMMIT WORK.
ENDFORM.                    " delete_data
*&---------------------------------------------------------------------*
*&      Form  confirm_delete
*&---------------------------------------------------------------------*
*       Ask user to confirm deleting data from database
*----------------------------------------------------------------------*
FORM confirm_delete CHANGING e_answer.
  DATA: l_question(100).
  MOVE text-025 TO l_question.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = text-026
      text_question         = l_question
      text_button_1         = 'Yes'(073)
      text_button_2         = text-074
      default_button        = '2'
      display_cancel_button = 'X'
    IMPORTING
      answer                = e_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND   = 1
             OTHERS           = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " confirm_delete
*&---------------------------------------------------------------------*
*&      Form  UPLOAD_data
*&---------------------------------------------------------------------*
*       Upload files into SOD Matrix
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM upload_data.
DATA : lt_conh             TYPE  TABLE OF /psyng/conflict
       WITH HEADER LINE,
wa_conh             TYPE  /psyng/conflict,
lt_funh             TYPE  TABLE OF /psyng/function  WITH HEADER LINE,
wa_funh             TYPE  /psyng/function,
lt_fund             TYPE  TABLE OF /psyng/functtran WITH HEADER LINE,
lt_funt             TYPE  TABLE OF /psyng/texts     WITH HEADER LINE,
lt_funt_lang1       TYPE  TABLE OF /psyng/texts     WITH HEADER LINE,
lt_funt_lang2       TYPE  TABLE OF /psyng/texts     WITH HEADER LINE,
lt_objd             TYPE  TABLE OF /psyng/faobj2    WITH HEADER LINE,
lt_sysfun           TYPE TABLE OF /psyng/sw_sysfun WITH HEADER LINE,
lt_cond             TYPE  TABLE OF /psyng/confdet   WITH HEADER LINE,
lt_cont             TYPE  TABLE OF /psyng/texts     WITH HEADER LINE,
lt_cont_lang1       TYPE  TABLE OF /psyng/texts     WITH HEADER LINE,
lt_cont_lang2       TYPE  TABLE OF /psyng/texts     WITH HEADER LINE,
lt_cono             TYPE  TABLE OF /psyng/conowner  WITH HEADER LINE,
lt_syscon           TYPE TABLE OF /psyng/sw_syscon WITH HEADER LINE,
lt_conpmit          TYPE  TABLE OF /psyng/conpmit  WITH HEADER LINE,
lt_cah              TYPE  TABLE OF /psyng/swaudhdr  WITH HEADER LINE,
lt_cad              TYPE  TABLE OF /psyng/swaudc2   WITH HEADER LINE,
lt_cat              TYPE  TABLE OF /psyng/texts     WITH HEADER LINE,
lt_cat_lang1        TYPE  TABLE OF /psyng/texts     WITH HEADER LINE,
lt_cat_lang2        TYPE  TABLE OF /psyng/texts     WITH HEADER LINE,
lt_sysca            TYPE TABLE OF /psyng/sw_sysca WITH HEADER LINE,
lt_ct               TYPE  TABLE OF /psyng/critcodes WITH HEADER LINE,
lt_systcd           TYPE TABLE OF /psyng/sw_systcd WITH HEADER LINE,
lt_ctxt             TYPE  TABLE OF /psyng/texts     WITH HEADER LINE,
lt_ctxt_lang1       TYPE  TABLE OF /psyng/texts     WITH HEADER LINE,
lt_ctxt_lang2       TYPE  TABLE OF /psyng/texts     WITH HEADER LINE,
lt_cr               TYPE  TABLE OF /psyng/criroles  WITH HEADER LINE,
lt_crtxt            TYPE TABLE OF /psyng/texts     WITH HEADER LINE,
lt_crtxt_lang1      TYPE  TABLE OF /psyng/texts    WITH HEADER LINE,
lt_crtxt_lang2      TYPE  TABLE OF /psyng/texts    WITH HEADER LINE,
lt_cp               TYPE TABLE OF /psyng/criprof   WITH HEADER LINE,
lt_cptxt            TYPE TABLE OF /psyng/texts     WITH HEADER LINE,
lt_cptxt_lang1      TYPE  TABLE OF /psyng/texts    WITH HEADER LINE,
lt_cptxt_lang2      TYPE  TABLE OF /psyng/texts    WITH HEADER LINE,
lt_sort_contexts    TYPE  TABLE OF /psyng/texts  WITH HEADER LINE,
wa_sort_contexts    TYPE /psyng/texts,
l_downloadfailed(3),
l_text              TYPE string,
l_index             TYPE sy-tabix,
l_cnt               TYPE n,
l_fioriid_index     TYPE n,
lt_fund_f           TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
lt_fund_f_1         TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
l_fioriid           TYPE /psyng/sw_fioriid,
l_lineno            TYPE i,
lt_corg             TYPE TABLE OF /psyng/swsodorgo WITH HEADER LINE,
ls_corg             TYPE /psyng/swsodorgo,
lt_corg_part        TYPE TABLE OF /psyng/swsodorgo WITH HEADER LINE,
lt_tstc             TYPE TABLE OF tstc.

* structure for function texts
  DATA: BEGIN OF lt_function_texts OCCURS 0,
          function LIKE /psyng/function-function,
          line     LIKE /psyng/texts-line,
          text     LIKE /psyng/texts-text,
          spras    LIKE /psyng/texts-spras,
        END OF lt_function_texts.

* structure for conflict texts
  DATA: BEGIN OF lt_conflict_texts OCCURS 0,
          conid(30) TYPE c, "LIKE /psyng/conflict-conid,
          line      LIKE /psyng/texts-line,
          text      LIKE /psyng/texts-text,
          spras     LIKE /psyng/texts-spras,
        END OF lt_conflict_texts.

* structure for critical auth. texts
  DATA: BEGIN OF lt_cauth_texts OCCURS 0,
          swaudid LIKE /psyng/swaudhdr-swaudid,
          line    LIKE /psyng/texts-line,
          text    LIKE /psyng/texts-text,
          spras   LIKE /psyng/texts-spras,
        END OF lt_cauth_texts.
  DATA: ls_versio TYPE /psyng/swsodvers.

* structure for critical transaction texts
  DATA : BEGIN OF lt_critrans_texts OCCURS 0,
           tcode LIKE /psyng/critcodes-tcode,
           line  LIKE /psyng/texts-line,
           text  LIKE /psyng/texts-text,
           spras LIKE /psyng/texts-spras,
         END OF lt_critrans_texts.

* structure for critical roles texts
  DATA : BEGIN OF lt_criroles_texts OCCURS 0,
           agr_name LIKE /psyng/criroles-agr_name,
           line     LIKE /psyng/texts-line,
           text     LIKE /psyng/texts-text,
           spras    LIKE /psyng/texts-spras,
         END OF lt_criroles_texts.

* structure for critical profiles texts
  DATA : BEGIN OF lt_criprof_texts OCCURS 0,
           profile LIKE /psyng/criprof-profile,
           line    LIKE /psyng/texts-line,
           text    LIKE /psyng/texts-text,
           spras   LIKE /psyng/texts-spras,
         END OF lt_criprof_texts.

  DATA: l_uploadfailed(3),
        lf_locked         TYPE flag,
        l_locks           TYPE i,
        lf_file_not_found TYPE flag.

*--Table with link between function, fiori app and tcode value
  DATA :
    BEGIN OF ls_fioriapp_tcode,
      funid       TYPE /psyng/function_id,
      fioriid     TYPE /psyng/sw_fioriid,
      tcodeinfile TYPE tcode,
      tcode       TYPE tcode,
    END OF   ls_fioriapp_tcode,
    lt_fioriapp_tcode LIKE SORTED TABLE OF ls_fioriapp_tcode
                      WITH UNIQUE KEY funid tcodeinfile.
  FIELD-SYMBOLS : <fund>    TYPE /psyng/functtran,
                  <fs_objd> TYPE /psyng/faobj2.
  IF ovrwrt = 'X'.
    PERFORM authority_check USING 'RCONFUN'.
  ENDIF.



*--Function Header
  IF f_funh = 'X'.
    PERFORM upload TABLES   lt_funh
                   USING    fn_funh
                            text-096
                   CHANGING lf_file_not_found
                   .
    IF lf_file_not_found = 'X'.
      CLEAR f_funh.
    ELSE.

      DELETE lt_funh WHERE function EQ space.
      IF sy-subrc = 0.
        IF lt_funh[] IS INITIAL.
          PERFORM log USING fn_funh 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.

      LOOP AT lt_funh.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
                  ID 'ACTVT' FIELD 'UL'
                  ID 'Y&SW_FUNCT' FIELD lt_funh-function
                  ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-005 INTO l_text.
          PERFORM log USING fn_funh 'E' '' '' lt_funh-function
                                              lt_funh-description
                                              l_text.
          DELETE lt_funh INDEX l_index.
          CLEAR: l_index, l_text.
        ELSE.
          lt_funh-mandt = sy-mandt.
          lt_funh-create_usr = g_current_user."sy-uname. C0700
          lt_funh-create_dat = sy-datum.
          lt_funh-create_tim = sy-uzeit.
          lt_funh-vrsio      = sodvrsio.
          CLEAR: lt_funh-change_usr,
                 lt_funh-change_dat,
                 lt_funh-change_tim.
          MODIFY lt_funh.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded,load from database for validation
    SELECT * FROM /psyng/function INTO TABLE lt_funh
    WHERE vrsio = sodvrsio.
  ENDIF.

*--Function Details
  IF f_fund = 'X'.
    PERFORM upload TABLES lt_fund
                   USING  fn_fund
                          text-099
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_fund.
    ELSE.
      DELETE lt_fund WHERE functionid EQ space.
      IF sy-subrc = 0.
        IF lt_fund[] IS INITIAL.
          PERFORM log USING fn_fund 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.

      LOOP AT lt_fund.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
                    ID 'ACTVT' FIELD 'UL'
                    ID 'Y&SW_FUNCT' FIELD lt_fund-functionid
                    ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-005 INTO l_text.
          PERFORM log USING fn_fund 'E' '' '' lt_fund-functionid
                                              lt_fund-tcode
                                              l_text.
          DELETE lt_fund INDEX l_index.
          CLEAR: l_index, l_text.
        ELSE.
          IF lt_fund-fioriid IS INITIAL AND lt_fund-type = 'F'.
            MOVE 'Fiori ID is mandatory when using Type F'(213)
                   TO l_text.
            PERFORM log USING fn_fund 'E' '' '' lt_fund-functionid
                                                lt_fund-tcode
                                                l_text.
            DELETE lt_fund INDEX l_index.
            CLEAR: l_index, l_text.
          ENDIF.
        ENDIF.
      ENDLOOP.
      lt_fund-vrsio = sodvrsio.
      MODIFY lt_fund TRANSPORTING vrsio WHERE vrsio <> sodvrsio.

    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded, we load it for data verification
    SELECT * FROM /psyng/functtran INTO TABLE lt_fund
      WHERE vrsio = sodvrsio.
  ENDIF.
  IF NOT ovrwrt = 'X'.
*--Read existing tcode values for fiori app ids.
    SELECT * FROM /psyng/functtran INTO TABLE lt_fund_f
        WHERE vrsio = sodvrsio AND
              type  = 'F'.
    SORT lt_fund_f BY functionid fioriid DESCENDING.
  ENDIF.
*--START - Sync Tcode value of new records with
*          those of existing records
*          Also change the value of the tcode field to 1,2,3... instead
*          of what upload file had.
  CLEAR l_index.
  CLEAR l_cnt.
  SORT lt_fund BY functionid tcode.
  LOOP AT lt_fund ASSIGNING <fund>.
    AT NEW functionid.
      l_index = 1.
    ENDAT.
    IF <fund>-type IS INITIAL.
      IF <fund>-fioriid = ''.
        IF <fund>-tcode CP '/PSYNG/-*'.
          <fund>-type = 'P'."placeholder
        ELSE.
          <fund>-type = 'T'."tcode
        ENDIF.
      ELSE.
        <fund>-type = 'F'.
      ENDIF.
    ENDIF.
    IF <fund>-type = 'F'.
*--Check if we already have a tcode value for this fiori app
      READ TABLE lt_fund_f_1 WITH KEY
       functionid = <fund>-functionid
       fioriid    = <fund>-fioriid
       BINARY SEARCH TRANSPORTING tcode.
      IF sy-subrc = 0.
*--        there is already a tcode value for this fiori app
*          (and it's        lt_fund_f_1-tcode)
        ls_fioriapp_tcode-funid       = <fund>-functionid.
        ls_fioriapp_tcode-tcodeinfile = <fund>-tcode.
        ls_fioriapp_tcode-fioriid     = <fund>-fioriid.
        ls_fioriapp_tcode-tcode       = lt_fund_f_1-tcode.
        INSERT ls_fioriapp_tcode INTO TABLE lt_fioriapp_tcode.
*--now change the tcode to what was already used for this fiori app
        <fund>-tcode = lt_fund_f_1-tcode.
      ELSE.
*--This fiori app id wasn't used in this function yet
        ls_fioriapp_tcode-funid        = <fund>-functionid.
        ls_fioriapp_tcode-tcodeinfile = <fund>-tcode.
        ls_fioriapp_tcode-fioriid     = <fund>-fioriid.

*--- Om C0933 Start Changes
*        l_text = l_index.
*        CONCATENATE '/PSYNG/-' l_text INTO ls_fioriapp_tcode-tcode.
*        ADD 1 TO l_index.
        ls_fioriapp_tcode-tcode = <fund>-tcode.
*--- End
        INSERT ls_fioriapp_tcode INTO TABLE lt_fioriapp_tcode.
        <fund>-tcode                 = ls_fioriapp_tcode-tcode.
      ENDIF.
    ENDIF.
  ENDLOOP.


*--Function Texts
  IF f_funt = 'X'.
    PERFORM upload TABLES lt_function_texts
                   USING  fn_funt
                          text-084
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_funt.
    ELSE.

      DELETE lt_function_texts WHERE function EQ space.
      IF sy-subrc = 0.
        IF lt_function_texts[] IS INITIAL.
          PERFORM log USING fn_funt 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.


      LOOP AT lt_function_texts.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
                        ID 'ACTVT' FIELD 'UL'
                       ID 'Y&SW_FUNCT' FIELD lt_function_texts-function
                        ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-005 INTO l_text.
          PERFORM log USING fn_funt 'E' '' '' lt_function_texts-function
                                                                      ''
                                                                 l_text.
          DELETE lt_function_texts INDEX l_index.
          CLEAR: l_index,l_text.
        ELSE.


          lt_funt-textname = lt_function_texts-function.
          lt_funt-object = 'F'.
          lt_funt-spras = lt_function_texts-spras.
          lt_funt-vrsio = sodvrsio.
          lt_funt-line = lt_function_texts-line.
          lt_funt-text = lt_function_texts-text.
          APPEND lt_funt.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded, we load it for data verification
    SELECT * FROM /psyng/texts INTO TABLE lt_funt WHERE
      object = 'F'     AND
      vrsio = sodvrsio AND
      spras = sy-langu.
  ENDIF.

*--Object Details
  IF f_objd = 'X'.
    PERFORM upload TABLES lt_objd
                   USING  fn_objd
                          text-108
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_objd.
    ELSE.

      DELETE lt_objd WHERE funid EQ space.
      IF sy-subrc = 0.
        IF lt_objd[] IS INITIAL.
          PERFORM log USING fn_objd 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.


      LOOP AT lt_objd.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
                        ID 'ACTVT' FIELD 'UL'
                        ID 'Y&SW_FUNCT' FIELD lt_objd-funid
                        ID 'Y&SW_VRSIO' FIELD sodvrsio.

        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-005 INTO l_text.
          PERFORM log USING fn_objd 'E' '' '' lt_objd-funid
                                              ''
                                              l_text.
          DELETE lt_objd INDEX l_index.
          CLEAR: l_index,l_text.
        ELSE.

          lt_objd-mandt = sy-mandt.
          lt_objd-create_usr = g_current_user. "sy-uname. C0700
          lt_objd-create_dat = sy-datum.
          lt_objd-create_tim = sy-uzeit.
          lt_objd-vrsio      = sodvrsio.
          CLEAR: lt_objd-change_usr,
                 lt_objd-change_dat,
                 lt_objd-change_tim.
          MODIFY lt_objd.
        ENDIF.

      ENDLOOP.
*  --Ensure the tcode value for Fiori Apps is in sync with the
*      /psyng/functtran table
      LOOP AT lt_objd ASSIGNING <fs_objd>.
        READ TABLE lt_fioriapp_tcode INTO ls_fioriapp_tcode
        WITH TABLE KEY
         funid        = <fs_objd>-funid
         tcodeinfile  = <fs_objd>-tcode.
        IF sy-subrc = 0.
          <fs_objd>-tcode = ls_fioriapp_tcode-tcode.
        ENDIF.
      ENDLOOP.


    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded, we load it for data verification
    SELECT * FROM /psyng/faobj2 INTO TABLE lt_objd
      WHERE vrsio = sodvrsio.
  ENDIF.


*--function filters
  IF f_fnfltr = 'X'.
    PERFORM upload TABLES lt_sysfun
                   USING  fn_fflt
                          text-t11
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_fnfltr.
    ELSE.

      DELETE lt_sysfun WHERE function EQ space.
      IF sy-subrc = 0.
        IF lt_sysfun[] IS INITIAL.
          PERFORM log USING fn_fflt 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.


      LOOP AT lt_sysfun.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
          ID 'ACTVT' FIELD 'UL'
          ID 'Y&SW_VRSIO' FIELD sodvrsio
          ID 'Y&SW_FUNCT' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)

        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-t06 INTO l_text.
          PERFORM log USING fn_fflt 'E' '' '' lt_sysfun-function
                                              ''
                                              l_text.
          DELETE lt_sysfun INDEX l_index.
          CLEAR: l_index,l_text.
        ENDIF.

      ENDLOOP.
*B8723 Changes by RA.
      lt_sysfun-vrsio = sodvrsio.
      MODIFY lt_sysfun TRANSPORTING vrsio WHERE vrsio <> sodvrsio.
* Changes end.
    ENDIF.

  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded, we load it for data verification
    SELECT * FROM /psyng/sw_sysfun INTO TABLE lt_sysfun
      WHERE vrsio = sodvrsio.
  ENDIF.


*--Conflict Header
  IF f_conh = 'X'.

    PERFORM upload TABLES lt_conh
                   USING  fn_conh
                          text-102
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_conh.
    ELSE.


      DELETE lt_conh WHERE conid EQ space.
      IF sy-subrc = 0.
        IF lt_conh[] IS INITIAL.
          PERFORM log USING fn_conh 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.

      LOOP AT lt_conh.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
            ID 'ACTVT' FIELD 'UL'
            ID 'Y&SW_CONID' FIELD lt_conh-conid
            ID 'Y&SW_VRSIO' FIELD sodvrsio.

        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-006 INTO l_text.
          PERFORM log USING fn_conh 'E' '' '' lt_conh-conid
                                              lt_conh-description
                                              l_text.
          DELETE lt_conh INDEX l_index.
          CLEAR: l_index,l_text.
        ELSE.
          lt_conh-mandt = sy-mandt.
          lt_conh-create_usr = g_current_user. "sy-uname. C0700
          lt_conh-create_dat = sy-datum.
          lt_conh-create_tim = sy-uzeit.
          lt_conh-vrsio      = sodvrsio.
          TRANSLATE lt_conh-imp TO UPPER CASE.           "#EC TRANSLATE
          CLEAR: lt_conh-change_usr,
                 lt_conh-change_dat,
                 lt_conh-change_tim.
          MODIFY lt_conh.
        ENDIF.

      ENDLOOP.

    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded,load from database for validation
    SELECT * FROM /psyng/conflict INTO TABLE lt_conh
    WHERE vrsio = sodvrsio.
  ENDIF.

*--Conflict Details
  IF f_cond = 'X'.
    PERFORM upload TABLES lt_cond
                   USING  fn_cond
                          text-105
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_cond.
    ELSE.

      DELETE lt_cond WHERE conid EQ space.
      IF sy-subrc = 0.
        IF lt_cond[] IS INITIAL.
          PERFORM log USING fn_cond 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.

      LOOP AT lt_cond.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
            ID 'ACTVT' FIELD 'UL'
            ID 'Y&SW_CONID' FIELD lt_cond-conid
            ID 'Y&SW_VRSIO' FIELD sodvrsio.

        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-006 INTO l_text.
          PERFORM log USING fn_cond 'E' '' '' lt_cond-conid
                                              lt_cond-functionid
                                              l_text.
          DELETE lt_cond INDEX l_index.
          CLEAR: l_index,l_text.
        ENDIF.
      ENDLOOP.
      lt_cond-vrsio = sodvrsio.
      MODIFY lt_cond TRANSPORTING vrsio WHERE vrsio <> sodvrsio.

    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded, we load it for data verification
    SELECT * FROM /psyng/confdet INTO TABLE lt_cond
      WHERE vrsio = sodvrsio.
  ENDIF.

*--Conflict Texts
  DATA: wa_conflict_texts LIKE lt_conflict_texts.


  IF f_cont = 'X'.
    PERFORM upload TABLES lt_conflict_texts
                   USING  fn_cont
                          text-080
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_cont.
    ELSE.
      DELETE lt_conflict_texts WHERE conid EQ space.
      IF sy-subrc = 0.
        IF lt_conflict_texts[] IS INITIAL.
          PERFORM log USING fn_cont 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.


      LOOP AT lt_conflict_texts.
        CLEAR wa_conflict_texts.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
            ID 'ACTVT' FIELD 'UL'
            ID 'Y&SW_CONID' FIELD lt_conflict_texts-conid
            ID 'Y&SW_VRSIO' FIELD sodvrsio.

        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-006 INTO l_text.
          PERFORM log USING fn_cont 'E' '' '' lt_conflict_texts-conid
                                              ''
                                              l_text.
          DELETE lt_conflict_texts INDEX l_index.
          CLEAR: l_index,l_text.
        ELSE.
*          IF ovrwrt = 'X'.
          lt_cont-textname = lt_conflict_texts-conid.
          lt_cont-object = 'C'.
          lt_cont-spras = lt_conflict_texts-spras.
          lt_cont-vrsio = sodvrsio.
          lt_cont-line = lt_conflict_texts-line.
          lt_cont-text = lt_conflict_texts-text.
          APPEND lt_cont.
        ENDIF.

      ENDLOOP.
    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded, we load it for data verification
    SELECT * FROM /psyng/texts INTO TABLE lt_cont WHERE
      object = 'C'     AND
      vrsio = sodvrsio AND
      spras = sy-langu.
  ENDIF.

*--Conflict Owners
  IF f_cono = 'X'.
    PERFORM upload TABLES lt_cono
                   USING  fn_cono
                          text-156
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_cono.
    ELSE.

      DELETE lt_cono WHERE conid EQ space.
      IF sy-subrc = 0.
        IF lt_cono[] IS INITIAL.
          PERFORM log USING fn_cono 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.


      LOOP AT lt_cono.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
            ID 'ACTVT' FIELD 'UL'
            ID 'Y&SW_CONID' FIELD lt_cono-conid
            ID 'Y&SW_VRSIO' FIELD sodvrsio.

        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-006 INTO l_text.
          PERFORM log USING fn_cono 'E' '' '' lt_cono-conid
                                              ''
                                              l_text.
          DELETE lt_cono INDEX l_index.
          CLEAR: l_index,l_text.
        ENDIF.
      ENDLOOP.
      lt_cono-vrsio = sodvrsio.
      MODIFY lt_cono TRANSPORTING vrsio WHERE vrsio <> sodvrsio.

    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded, we load it for data verification
    SELECT * FROM /psyng/conowner INTO TABLE lt_cono
      WHERE vrsio = sodvrsio.
  ENDIF.


*--Conflict Mitigations
  IF f_conm = 'X'.
    PERFORM upload TABLES lt_conpmit
                   USING  fn_conm
                          text-193
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_conm.
    ELSE.
      DELETE lt_conpmit WHERE conid EQ space.
      IF sy-subrc = 0.
        IF lt_conpmit[] IS INITIAL.
          PERFORM log USING fn_conm 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.


      LOOP AT lt_conpmit.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
            ID 'ACTVT' FIELD 'UL'
            ID 'Y&SW_CONID' FIELD lt_conpmit-conid
            ID 'Y&SW_VRSIO' FIELD sodvrsio.

        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-006 INTO l_text.
          PERFORM log USING fn_conm 'E' '' '' lt_conpmit-conid
                                              ''
                                              l_text.
          DELETE lt_conpmit INDEX l_index.
          CLEAR: l_index,l_text.
        ENDIF.
      ENDLOOP.
      lt_conpmit-vrsio = sodvrsio.
      MODIFY lt_conpmit TRANSPORTING vrsio WHERE vrsio <> sodvrsio.

    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded, we load it for data verification
    SELECT * FROM /psyng/conpmit INTO TABLE lt_conpmit
      WHERE vrsio = sodvrsio.
  ENDIF.


*--Conflict filters
  IF f_conflt = 'X'.
    PERFORM upload TABLES lt_syscon
                   USING  fn_cnflt
                          text-t12
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_conflt.
    ELSE.

      DELETE lt_syscon WHERE conid EQ space.
      IF sy-subrc = 0.
        IF lt_syscon[] IS INITIAL.
          PERFORM log USING fn_cnflt 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.


      LOOP AT lt_syscon.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
            ID 'ACTVT'      FIELD 'UL'
            ID 'Y&SW_VRSIO' FIELD sodvrsio
            ID 'Y&SW_FUNCT' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)

        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-t06 INTO l_text.
          PERFORM log USING fn_cnflt 'E' '' '' lt_syscon-conid
                                              ''
                                              l_text.
          DELETE lt_syscon INDEX l_index.
          CLEAR: l_index,l_text.
        ENDIF.

      ENDLOOP.
* B8723 Changes by RA.
      lt_syscon-vrsio = sodvrsio.
      MODIFY lt_syscon TRANSPORTING vrsio WHERE vrsio <> sodvrsio.
* Changes End.
    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded, we load it for data verification
    SELECT * FROM /psyng/sw_syscon INTO TABLE lt_syscon
      WHERE vrsio = sodvrsio.
  ENDIF.
* Custom Org Level Determination
* Beging Changes by DDHIMAN 08.11.19
  IF f_corg = 'X'.
    PERFORM upload TABLES lt_corg
                   USING  fn_corg
                          text-156
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_corg.
    ELSE.
      DELETE lt_corg WHERE conid EQ space.
      IF sy-subrc = 0.
        IF lt_corg[] IS INITIAL.
          PERFORM log USING fn_corg 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.

      LOOP AT lt_corg INTO ls_corg.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
            ID 'ACTVT' FIELD 'UL'
            ID 'Y&SW_CONID' FIELD ls_corg-conid
            ID 'Y&SW_VRSIO' FIELD sodvrsio.

        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-006 INTO l_text.
          PERFORM log USING fn_corg 'E' '' '' ls_corg-conid
                                              ''
                                              l_text.
          DELETE lt_corg INDEX l_index.
          CLEAR: l_index,l_text.
        ENDIF.
      ENDLOOP.
      ls_corg-vrsio = sodvrsio.
      MODIFY lt_corg FROM ls_corg TRANSPORTING vrsio WHERE vrsio <>
sodvrsio.

    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded, we load it for data verification
    SELECT * FROM /psyng/swsodorgo INTO TABLE lt_corg
      WHERE vrsio = sodvrsio.
  ENDIF.
* End Changes by DDHIMAN 08.11.19

*--Critical Auth Header
  IF f_cah = 'X'.
    PERFORM upload TABLES lt_cah
                   USING  fn_cah
                          text-087
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_cah.
    ELSE.
      DELETE lt_cah WHERE swaudid EQ space.
      IF sy-subrc = 0.
        IF lt_cah[] IS INITIAL.
          PERFORM log USING fn_cah 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.


      LOOP AT lt_cah.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
                       ID 'ACTVT' FIELD 'UL'
                       ID 'Y&SW_AUTID' FIELD lt_cah-swaudid
                       ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-007 INTO l_text.
          PERFORM log USING fn_cah 'E' '' '' lt_cah-swaudid
                                             lt_cah-description
                                             l_text.
          DELETE lt_cah INDEX l_index.
          CLEAR: l_index, l_text.
        ELSE.
          lt_cah-mandt = sy-mandt.
          lt_cah-create_usr = g_current_user. "sy-uname. C0700
          lt_cah-create_dat = sy-datum.
          lt_cah-create_tim = sy-uzeit.
          lt_cah-vrsio      = sodvrsio.
          CLEAR: lt_cah-change_usr,
                 lt_cah-change_dat,
                 lt_cah-change_tim.
          MODIFY lt_cah.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded,load from database for validation
    SELECT * FROM /psyng/swaudhdr INTO TABLE lt_cah
    WHERE vrsio = sodvrsio.
  ENDIF.

*--Critical Auth Details
  IF f_cad = 'X'.
    PERFORM upload TABLES lt_cad
                   USING  fn_cad
                          text-090
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_cad.
    ELSE.
      DELETE lt_cad WHERE swaudid EQ space.
      IF sy-subrc = 0.
        IF lt_cad[] IS INITIAL.
          PERFORM log USING fn_cad 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.

      LOOP AT lt_cad.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
                       ID 'ACTVT' FIELD 'UL'
                       ID 'Y&SW_AUTID' FIELD lt_cad-swaudid
                       ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-007 INTO l_text.
          PERFORM log USING fn_cad 'E' '' '' lt_cad-swaudid
                                             lt_cad-tcode
                                             l_text.
          DELETE lt_cad INDEX l_index.
          CLEAR: l_index, l_text.
        ELSE.
          lt_cad-mandt = sy-mandt.
          lt_cad-create_usr = g_current_user. "sy-uname. C0700
          lt_cad-create_dat = sy-datum.
          lt_cad-create_tim = sy-uzeit.
          lt_cad-vrsio      = sodvrsio.
          MODIFY lt_cad.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded, we load it for data verification
    SELECT * FROM /psyng/swaudc2 INTO TABLE lt_cad
      WHERE vrsio = sodvrsio.
  ENDIF.

*--Critical Auth Texts
  IF f_cat = 'X'.
    PERFORM upload TABLES lt_cauth_texts
                   USING  fn_cat
                          text-077
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_cat.
    ELSE.

      DELETE lt_cauth_texts WHERE swaudid EQ space.
      IF sy-subrc = 0.
        IF lt_cauth_texts[] IS INITIAL.
          PERFORM log USING fn_cat 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.


      LOOP AT lt_cauth_texts.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
                         ID 'ACTVT' FIELD 'UL'
                         ID 'Y&SW_AUTID' FIELD lt_cauth_texts-swaudid
                         ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-007 INTO l_text.
          PERFORM log USING fn_cat 'E' '' '' lt_cauth_texts-swaudid
                                             ''
                                             l_text.
          DELETE lt_cauth_texts INDEX l_index.
          CLEAR: l_index, l_text.
        ELSE.
          lt_cat-textname = lt_cauth_texts-swaudid.
          lt_cat-object = 'T'.
          lt_cat-spras = lt_cauth_texts-spras.
          lt_cat-vrsio = sodvrsio.
          lt_cat-line = lt_cauth_texts-line.
          lt_cat-text = lt_cauth_texts-text.
          APPEND lt_cat.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded, we load it for data verification
    SELECT * FROM /psyng/texts INTO TABLE lt_cat WHERE
      object = 'T'     AND
      vrsio = sodvrsio AND
      spras = sy-langu.
  ENDIF.


*--Critical auth. filters
  IF f_cafltr = 'X'.
    PERFORM upload TABLES lt_sysca
                   USING  fn_catfl
                          text-t13
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_cafltr.
    ELSE.

      DELETE lt_sysca WHERE swaudid EQ space.
      IF sy-subrc = 0.
        IF lt_sysca[] IS INITIAL.
          PERFORM log USING fn_catfl 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.


      LOOP AT lt_sysca.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
          ID 'ACTVT' FIELD 'UL'
          ID 'Y&SW_VRSIO' FIELD sodvrsio
          ID 'Y&SW_FUNCT' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)

        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-t06 INTO l_text.
          PERFORM log USING fn_catfl 'E' '' '' lt_sysca-swaudid
                                              ''
                                              l_text.
          DELETE lt_sysca INDEX l_index.
          CLEAR: l_index,l_text.
        ENDIF.

      ENDLOOP.
* B8723 Changes by RA.
      lt_sysca-vrsio = sodvrsio.
      MODIFY lt_sysca TRANSPORTING vrsio WHERE vrsio <> sodvrsio.
* Changes End.
    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded, we load it for data verification
    SELECT * FROM /psyng/sw_sysca INTO TABLE lt_sysca
      WHERE vrsio = sodvrsio.
  ENDIF.


*--Critical Transaction
  IF f_ct = 'X'.
    PERFORM upload TABLES lt_ct
                   USING  fn_ct
                          text-093
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_ct.
    ELSE.

      DELETE lt_ct WHERE tcode EQ space.
      IF sy-subrc = 0.
        IF lt_ct[] IS INITIAL.
          PERFORM log USING fn_ct 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.

      LOOP AT lt_ct.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
                  ID 'ACTVT' FIELD 'UL'
                  ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-008 INTO l_text.
          PERFORM log USING fn_ct 'E' '' '' ''
                                              sodvrsio
                                              l_text.
          DELETE lt_ct INDEX l_index.
          CLEAR: l_index, l_text.
        ELSE.
          lt_ct-mandt = sy-mandt.
          lt_ct-create_usr = g_current_user. "sy-uname. C0700
          lt_ct-create_dat = sy-datum.
          lt_ct-create_tim = sy-uzeit.
          lt_ct-vrsio      = sodvrsio.
          CLEAR: lt_ct-change_usr,
                 lt_ct-change_dat,
                 lt_ct-change_tim.
          MODIFY lt_ct.

        ENDIF.
      ENDLOOP.
    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded,load from database for validation
    SELECT * FROM /psyng/critcodes INTO TABLE lt_ct
    WHERE vrsio = sodvrsio.
  ENDIF.

*--Critical Transactions Texts

  IF f_ctxt = 'X'.
    PERFORM upload TABLES lt_critrans_texts
                   USING  fn_ctxt
                          text-165
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_ctxt.
    ELSE.

      DELETE lt_critrans_texts WHERE tcode EQ space.
      IF sy-subrc = 0.
        IF lt_critrans_texts[] IS INITIAL.
          PERFORM log USING fn_ctxt 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.

      LOOP AT lt_critrans_texts.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
                        ID 'ACTVT' FIELD 'UL'
                        ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-008 INTO l_text.
          PERFORM log USING fn_ctxt 'E' '' '' ''
                                              sodvrsio
                                              l_text.
          DELETE lt_critrans_texts INDEX l_index.
          CLEAR: l_index,l_text.
        ELSE.
          lt_ctxt-textname = lt_critrans_texts-tcode.
          lt_ctxt-object = 'X'.
          lt_ctxt-spras = lt_critrans_texts-spras.
          lt_ctxt-vrsio = sodvrsio.
          lt_ctxt-line = lt_critrans_texts-line.
          lt_ctxt-text = lt_critrans_texts-text.
          APPEND lt_ctxt.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded, we load it for data verification
    SELECT * FROM /psyng/texts INTO TABLE lt_ctxt WHERE
      object = 'X'     AND
      vrsio = sodvrsio AND
      spras = sy-langu.
  ENDIF.


*--Critical transaction filters
  IF f_ctfltr = 'X'.
    PERFORM upload TABLES lt_systcd
                   USING  fn_ctflt
                          text-t13
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_ctfltr.
    ELSE.

      DELETE lt_systcd WHERE tcode EQ space.
      IF sy-subrc = 0.
        IF lt_sysca[] IS INITIAL.
          PERFORM log USING fn_ctflt 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.


      LOOP AT lt_systcd.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
           ID 'ACTVT' FIELD 'UL'
           ID 'Y&SW_VRSIO' FIELD sodvrsio
           ID 'Y&SW_FUNCT' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)

        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-t06 INTO l_text.
          PERFORM log USING fn_ctflt 'E' '' '' lt_systcd-tcode
                                              ''
                                              l_text.
          DELETE lt_systcd INDEX l_index.
          CLEAR: l_index,l_text.
        ENDIF.

      ENDLOOP.
* B8723 Changes by RA.
      lt_systcd-vrsio = sodvrsio.
      MODIFY lt_systcd TRANSPORTING vrsio WHERE vrsio <> sodvrsio.
* Changes End.
    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded, we load it for data verification
    SELECT * FROM /psyng/sw_systcd INTO TABLE lt_systcd
      WHERE vrsio = sodvrsio.
  ENDIF.


* -- Critical Roles

  IF f_cr = 'X'.
    PERFORM upload TABLES lt_cr
                   USING  fn_cr
                          text-166
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_cr.
    ELSE.

      DELETE lt_cr WHERE agr_name EQ space.
      IF sy-subrc = 0.
        IF lt_cr[] IS INITIAL.
          PERFORM log USING fn_cr 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.

      LOOP AT lt_cr.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
                  ID 'ACTVT' FIELD 'UL'
                  ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-012 INTO l_text.
          PERFORM log USING fn_cr 'E' '' '' '' sodvrsio
                                              l_text.
          DELETE lt_cr INDEX l_index.
          CLEAR: l_index, l_text.
        ELSE.
          lt_cr-mandt = sy-mandt.
          lt_cr-vrsio = sodvrsio.
          MODIFY lt_cr.

        ENDIF.
      ENDLOOP.
    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded,load from database for validation

    SELECT * FROM /psyng/criroles INTO TABLE lt_cr
    WHERE vrsio = sodvrsio.

  ENDIF.


* -- Critical Roles Texts

  IF f_crtxt = 'X'.
    PERFORM upload TABLES lt_criroles_texts
                   USING  fn_crtxt
                          text-167
                   CHANGING lf_file_not_found.

    IF lf_file_not_found = 'X'.
      CLEAR f_crtxt.
    ELSE.

      DELETE lt_criroles_texts WHERE agr_name EQ space.
      IF sy-subrc = 0.
        IF lt_criroles_texts[] IS INITIAL.
          PERFORM log USING fn_crtxt 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.

      LOOP AT lt_criroles_texts.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
                        ID 'ACTVT' FIELD 'UL'
                        ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-012 INTO l_text.
          PERFORM log USING fn_crtxt 'E' '' ''
          '' sodvrsio l_text.
          DELETE lt_criroles_texts INDEX l_index.
          CLEAR: l_index,l_text.
        ELSE.
          lt_crtxt-textname = lt_criroles_texts-agr_name.
          lt_crtxt-object = 'Q'.
          lt_crtxt-spras = lt_criroles_texts-spras.
          lt_crtxt-vrsio = sodvrsio.
          lt_crtxt-line = lt_criroles_texts-line.
          lt_crtxt-text = lt_criroles_texts-text.
          APPEND lt_crtxt.
        ENDIF.
      ENDLOOP.
    ENDIF.

  ELSEIF p_noval IS INITIAL.

    SELECT * FROM /psyng/texts
             INTO TABLE lt_crtxt
             WHERE  object = 'Q' AND
                    vrsio = sodvrsio AND
                    spras = sy-langu.

  ENDIF.


*--Critical profiles

  IF f_cp = 'X'.
    PERFORM upload TABLES lt_cp
                   USING  fn_cp
                          text-168
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_cp.
    ELSE.


      DELETE lt_cp WHERE profile EQ space.
      IF sy-subrc = 0.
        IF lt_cp[] IS INITIAL.
          PERFORM log USING fn_cp 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.

      LOOP AT lt_cp.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
                  ID 'ACTVT' FIELD 'UL'
                  ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc <> 0.
          CONCATENATE text-e14 text-013 INTO l_text.
          PERFORM log USING fn_cp 'E' '' '' ''
                                              sodvrsio
                                              l_text.
          DELETE lt_cp INDEX l_index.
          CLEAR: l_index, l_text.
        ELSE.
          lt_cp-mandt = sy-mandt.
          lt_cp-vrsio      = sodvrsio.
          MODIFY lt_cp.

        ENDIF.
      ENDLOOP.
    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded,load from database for validation
    SELECT * FROM /psyng/criprof INTO TABLE lt_cp
    WHERE vrsio = sodvrsio.
  ENDIF.


*--Critical profiles Texts

  IF f_cptxt = 'X'.
    PERFORM upload TABLES lt_criprof_texts
                   USING  fn_cptxt
                          text-169
                   CHANGING lf_file_not_found.
    IF lf_file_not_found = 'X'.
      CLEAR f_cptxt.
    ELSE.

      DELETE lt_criprof_texts WHERE profile EQ space.
      IF sy-subrc = 0.
        IF lt_criprof_texts[] IS INITIAL.
          PERFORM log USING fn_cptxt 'W' '' '' '' '' 'Empty File'(201).
        ENDIF.
      ENDIF.


      LOOP AT lt_criprof_texts.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
                        ID 'ACTVT' FIELD 'UL'
                        ID 'Y&SW_VRSIO' FIELD sodvrsio.
        IF sy-subrc NE 0.
          CONCATENATE text-e14 text-013 INTO l_text.
          PERFORM log USING fn_cptxt 'E' '' '' ''
                                              sodvrsio
                                              l_text.
          DELETE lt_criprof_texts INDEX l_index.
          CLEAR: l_index,l_text.
        ELSE.
          lt_cptxt-textname = lt_criprof_texts-profile.
          lt_cptxt-object = 'P'.
          lt_cptxt-spras = lt_criprof_texts-spras.
          lt_cptxt-vrsio = sodvrsio.
          lt_cptxt-line = lt_criprof_texts-line.
          lt_cptxt-text = lt_criprof_texts-text.
          APPEND lt_cptxt.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ELSEIF p_noval IS INITIAL.
*   If this file is not being uploaded, we load it for data verification
    SELECT * FROM /psyng/texts
    INTO TABLE lt_cptxt
    WHERE object = 'P' AND
    vrsio = sodvrsio AND
    spras = sy-langu.
  ENDIF.


*** Shekhar 26/08/2013 SE 3.1 ITEM C50
***Start
  IF p_crtver = 'X' AND testrun IS INITIAL.
    IF  f_funh  EQ 'X' OR
    f_fund  EQ 'X' OR
    f_funt  EQ 'X' OR
    f_objd  EQ 'X' OR
    f_conh  EQ 'X' OR
    f_cond  EQ 'X' OR
    f_cont  EQ 'X' OR
    f_cono  EQ 'X' OR
    f_conm  EQ 'X' OR
    f_cah   EQ 'X' OR
    f_corg  EQ 'X' OR
    f_cad   EQ 'X' OR
    f_cat   EQ 'X' OR
    f_ct    EQ 'X' OR
    f_ctxt  EQ 'X' OR
    f_cr    EQ 'X' OR
    f_crtxt EQ 'X' OR
    f_cp    EQ 'X' OR
    f_cptxt EQ 'X' OR
    f_ctfltr EQ 'X' OR
    f_cafltr EQ 'X' OR
    f_conflt EQ 'X' OR
    f_fnfltr EQ 'X'.


      DATA: ls_vrsio_o TYPE /psyng/swsodvers,
            ls_vrsio_n TYPE /psyng/swsodvers,
            l_objid    TYPE cdhdr-objectid,
            lt_cdtxt   TYPE TABLE OF cdtxt.

      ls_versio-vrsio = sodvrsio.
      ls_versio-vdesc = p_text.
      l_objid = ls_versio-vrsio.
      SELECT SINGLE * FROM /psyng/swsodvers INTO
      ls_vrsio_o WHERE vrsio = ls_versio-vrsio.
      IF sy-subrc <> 0.
        INSERT /psyng/swsodvers FROM ls_versio.
*    -----change document
        ls_vrsio_n = ls_versio.
        CALL FUNCTION '/PSYNG/VRSIO_WRITE_DOCUMENT'
          EXPORTING
            objectid                = l_objid
            tcode                   = sy-tcode
            utime                   = sy-uzeit
            udate                   = sy-datum
            username                = g_current_user "C0700
            planned_change_number   = ' '
            object_change_indicator = 'I'
            planned_or_real_changes = 'R'
            no_change_pointers      = ' '
*           UPD_ICDTXT_VRSIO        = ' '
            n_psyng_swsodvers       = ls_vrsio_n
            o_psyng_swsodvers       = ls_vrsio_o
            upd_psyng_swsodvers     = 'I'
          TABLES
            icdtxt_vrsio            = lt_cdtxt.
      ELSE.
        MODIFY /psyng/swsodvers FROM ls_versio.
        ls_vrsio_n = ls_versio.
        CALL FUNCTION '/PSYNG/VRSIO_WRITE_DOCUMENT'
          EXPORTING
            objectid                = l_objid
            tcode                   = sy-tcode
            utime                   = sy-uzeit
            udate                   = sy-datum
            username                = g_current_user "C0700
            planned_change_number   = ' '
            object_change_indicator = 'I'
            planned_or_real_changes = 'R'
            no_change_pointers      = ' '
*           UPD_ICDTXT_VRSIO        = ' '
            n_psyng_swsodvers       = ls_vrsio_n
            o_psyng_swsodvers       = ls_vrsio_o
            upd_psyng_swsodvers     = 'I'
          TABLES
            icdtxt_vrsio            = lt_cdtxt.
      ENDIF.
    ELSE.
    ENDIF.
  ENDIF.

****End
*--Sort and delete dupes

 SORT : lt_conh,lt_funh,lt_fund,lt_funt,lt_objd,lt_cond,lt_cont,lt_cono,
        lt_cah,lt_cad,lt_cat,lt_ct , lt_ctxt , lt_cr ,  lt_crtxt, lt_cp,
        lt_cptxt, lt_conpmit, lt_syscon, lt_sysfun, lt_sysca, lt_systcd,
        lt_corg.

  DELETE ADJACENT DUPLICATES FROM lt_conh COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_funh COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_fund COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_funt COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_objd COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_cond COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_cont COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_cono COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_conpmit COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_cah  COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_cad  COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_cat  COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_ct   COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_ctxt COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_cr   COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_crtxt COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_cp    COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_cptxt COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_syscon COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_sysfun COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_sysca COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM lt_systcd COMPARING ALL FIELDS.
* Beging Changes by DDHIMAN 08.11.19
  DELETE ADJACENT DUPLICATES FROM lt_corg COMPARING ALL FIELDS.
* End Changes by DDHIMAN 08.11.19

  IF p_noval IS INITIAL.
    PERFORM validation TABLES
    lt_conh
    lt_funh
    lt_fund
    lt_funt
    lt_objd
    lt_sysfun
    lt_cond
    lt_cont
    lt_cono
    lt_conpmit
    lt_syscon
    lt_cah
    lt_cad
    lt_cat
    lt_sysca
    lt_ct
    lt_ctxt
    lt_systcd
    lt_cr
    lt_crtxt
    lt_cp
    lt_cptxt
    lt_corg.

  ENDIF.


  IF testrun IS INITIAL.
*--Adding data to the database.
*--Critical Authorizations
    PERFORM check_lock USING 'SWAUD' sodvrsio
    CHANGING lf_locked l_locks.
    DATA : l_msg    TYPE string,
           l_answer TYPE c.
    l_msg = l_locks.
    CONCATENATE l_msg 'Crit Auth(s) are locked by other users'(l08)
    INTO l_msg SEPARATED BY space.
    IF lf_locked <> 'X'.
      l_answer = 1.
    ELSE.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar      = l_msg
          text_question = 'Do you want to continue?'(l02)
          text_button_1 = 'Yes'(l03)
          text_button_2 = 'No'(l04)
        IMPORTING
          answer        = l_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND     = 1
             OTHERS             = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
    ENDIF.
    IF l_answer = '1'.
      IF ovrwrt = 'X' .
*--Delete existing data
        PERFORM delete_data USING 'SWAUD' lf_locked .
      ENDIF.

      DATA : l_criauth_added      TYPE c,
             l_criauth_hdr_added  TYPE c,
             l_criauth_txt_added  TYPE c,
             l_criauth_objs_added TYPE c,
             lt_cat_part          TYPE TABLE OF /psyng/texts,
             lt_cad_part          TYPE TABLE OF /psyng/swaudc2,
             l_cah_uploaded       TYPE i,
             l_cad_uploaded       TYPE i,
             l_cat_uploaded       TYPE i,
             l_sysca_uploaded     TYPE i.

      LOOP AT lt_cah.
        CLEAR :
        l_criauth_added,
        l_criauth_hdr_added,
        l_criauth_txt_added,
        l_criauth_objs_added.

        CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_AUTHS'
          EXPORTING
            wa_swaudid            = lt_cah
            i_vrsio               = sodvrsio
            f_cat                 = f_cat
          IMPORTING
            criauth_added         = l_criauth_added
            criauth_hdr_added     = l_criauth_hdr_added
          EXCEPTIONS
            target_not_specified  = 1
            not_authorized        = 2
            authid_already_exists = 3
*           locked                = 4
            OTHERS                = 5.
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
              PERFORM log  USING
                fn_cah  'E' 'Critical Auth Object ID:'(141)
                 lt_cah-swaudid '' ''  text-a02.
            WHEN 2.
              PERFORM log  USING
                fn_cah  'E' 'Critical Auth Object ID:'(141)
                lt_cah-swaudid '' ''  text-a01.
            WHEN 3.
              PERFORM log  USING
                fn_cah  'E' 'Critical Auth Object ID:'(141)
                lt_cah-swaudid '' ''  text-a13.
            WHEN 4.
              PERFORM log  USING
                fn_cah  'E' 'Critical Auth Object ID:'(141)
                lt_cah-swaudid '' ''  text-a15.
            WHEN OTHERS.
              PERFORM log  USING
                fn_cah  'E' 'Critical Auth Object ID:'(141)
                 lt_cah-swaudid '' ''  text-a04.
          ENDCASE.
        ENDIF.


        REFRESH :lt_cat_part,  lt_cad_part.
        IF f_cat = 'X'.
          LOOP AT lt_cat WHERE textname = lt_cah-swaudid.
            APPEND lt_cat TO lt_cat_part.
          ENDLOOP.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_AUTHS'
            EXPORTING
              wa_swaudid            = lt_cah
              i_vrsio               = sodvrsio
              f_cat                 = f_cat
            IMPORTING
*             criauth_added         = l_criauth_added
*             criauth_hdr_added     = l_criauth_hdr_added
              criauth_txt_added     = l_criauth_txt_added
*             criauth_objs_added    = l_criauth_objs_added
            TABLES
              texts                 = lt_cat_part
*             swaudc2               = lt_cad_part
*             HISTORY               =
            EXCEPTIONS
              target_not_specified  = 1
              not_authorized        = 2
              authid_already_exists = 3
*             locked                = 4
              OTHERS                = 5.
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                PERFORM log  USING
                  fn_cat  'E' 'Critical Auth Object ID:'(141)
                   lt_cah-swaudid '' ''  text-a02.
              WHEN 2.
                PERFORM log  USING
                  fn_cat  'E' 'Critical Auth Object ID:'(141)
                  lt_cah-swaudid '' ''  text-a01.
              WHEN 3.
                PERFORM log  USING
                  fn_cat  'E' 'Critical Auth Object ID:'(141)
                  lt_cah-swaudid '' ''  text-a13.
              WHEN 4.
                PERFORM log  USING
                  fn_cat  'E' 'Critical Auth Object ID:'(141)
                  lt_cah-swaudid '' ''  text-a15.
              WHEN OTHERS.
                PERFORM log  USING
                  fn_cat  'E' 'Critical Auth Object ID:'(141)
                   lt_cah-swaudid '' ''  text-a04.
            ENDCASE.
          ENDIF.

        ENDIF.
        IF f_cad = 'X'.
          LOOP AT lt_cad WHERE swaudid = lt_cah-swaudid.
            APPEND lt_cad TO lt_cad_part.
          ENDLOOP.

          CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_AUTHS'
            EXPORTING
              wa_swaudid            = lt_cah
              i_vrsio               = sodvrsio
              f_cat                 = f_cat
            IMPORTING
*             criauth_added         = l_criauth_added
*             criauth_hdr_added     = l_criauth_hdr_added
*             criauth_txt_added     = l_criauth_txt_added
              criauth_objs_added    = l_criauth_objs_added
            TABLES
*             texts                 = lt_cat_part
              swaudc2               = lt_cad_part
*             HISTORY               =
            EXCEPTIONS
              target_not_specified  = 1
              not_authorized        = 2
              authid_already_exists = 3
*             locked                = 4
              OTHERS                = 5.
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                PERFORM log  USING
                  fn_cad  'E' 'Critical Auth Object ID:'(141)
                   lt_cah-swaudid '' ''  text-a02.
              WHEN 2.
                PERFORM log  USING
                  fn_cad  'E' 'Critical Auth Object ID:'(141)
                  lt_cah-swaudid '' ''  text-a01.
              WHEN 3.
                PERFORM log  USING
                  fn_cad  'E' 'Critical Auth Object ID:'(141)
                  lt_cah-swaudid '' ''  text-a13.
              WHEN 4.
                PERFORM log  USING
                  fn_cad  'E' 'Critical Auth Object ID:'(141)
                  lt_cah-swaudid '' ''  text-a15.
              WHEN OTHERS.
                PERFORM log  USING
                  fn_cad  'E' 'Critical Auth Object ID:'(141)
                   lt_cah-swaudid '' ''  text-a04.
            ENDCASE.
          ENDIF.
        ENDIF.

*        CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_AUTHS'
*          EXPORTING
*            wa_swaudid                  = lt_cah
*           i_vrsio                      = sodvrsio
*           f_cat                        = f_cat
*         IMPORTING
*           criauth_added               = l_criauth_added
*           criauth_hdr_added           = l_criauth_hdr_added
*           criauth_txt_added           = l_criauth_txt_added
*           criauth_objs_added          = l_criauth_objs_added
*          TABLES
*            texts                       =  lt_cat_part
*            swaudc2                     = lt_cad_part
**       HISTORY                     =
*         EXCEPTIONS
*           target_not_specified        = 1
*           not_authorized              = 2
*           authid_already_exists       = 3
*           locked                      = 4
*           OTHERS                      = 5
*                  .
*        IF sy-subrc <> 0.
*          CASE sy-subrc.
*            WHEN 1.
*              PERFORM log  USING
*                fn_cah  'E' 'Critical Auth Object ID:'(141)
*                 lt_cah-swaudid '' ''  text-a02.
*            WHEN 2.
*              PERFORM log  USING
*                fn_cah  'E' 'Critical Auth Object ID:'(141)
*                lt_cah-swaudid '' ''  text-a01.
*            WHEN 3.
*              PERFORM log  USING
*                fn_cah  'E' 'Critical Auth Object ID:'(141)
*                lt_cah-swaudid '' ''  text-a13.
*            WHEN 4.
*              PERFORM log  USING
*                fn_cah  'E' 'Critical Auth Object ID:'(141)
*                lt_cah-swaudid '' ''  text-a15.
*            WHEN OTHERS.
*              PERFORM log  USING
*                fn_cah  'E' 'Critical Auth Object ID:'(141)
*                 lt_cah-swaudid '' ''  text-a04.
*          ENDCASE.
*        ELSE.
        IF sy-subrc = 0.
          ADD 1 TO l_cah_uploaded.
          IF f_cat = 'X'.
            IF l_criauth_txt_added <> 'Y'.
              PERFORM log  USING
                fn_cat  'E' lt_cah-swaudid
                lt_cah-swaudid '' ''  text-a16.
            ELSE.
              ADD 1 TO l_cat_uploaded.
            ENDIF.
          ENDIF.
          IF f_cad = 'X' .
            IF l_criauth_objs_added <> 'Y'.
              PERFORM log  USING
                fn_cad  'W' 'Critical Auth Object ID:'(141)
                lt_cah-swaudid '' ''  text-a14.
            ELSE.
              ADD 1 TO l_cad_uploaded.
            ENDIF.
          ENDIF.
        ENDIF.

        IF f_cafltr = 'X'.
          LOOP AT lt_sysca.
            ADD 1 TO l_sysca_uploaded.
          ENDLOOP.
          MODIFY /psyng/sw_sysca FROM TABLE lt_sysca.
        ENDIF.

      ENDLOOP.

      IF lt_cah[] IS INITIAL AND ovrwrt = 'X' .
        IF f_cad = 'X' OR f_cat = 'X'
           OR f_cafltr = 'X'.
          PERFORM log  USING
             'CR Auth Header' 'W' '' '' '' ''  text-204.
        ENDIF.
      ENDIF.

*   system filter
      IF l_sysca_uploaded > 0 AND f_cafltr = 'X'.
        PERFORM log  USING
         fn_catfl 'S' '' '' '' ''  text-195.
      ENDIF.

      IF l_cah_uploaded  > 0 AND f_cah = 'X'.

        PERFORM log  USING
          fn_cah 'S' '' '' '' ''  text-085.
      ENDIF.
      IF l_cad_uploaded  > 0 AND f_cad = 'X'.

        PERFORM log  USING
          fn_cad 'S' '' '' '' ''  text-088.
      ENDIF.

      IF l_cat_uploaded  > 0 AND f_cat = 'X'.

        PERFORM log  USING
          fn_cat 'S' '' '' '' ''  text-075.

      ENDIF.


*---critical trans system filter
      IF f_ctfltr = 'X'.
        PERFORM check_lock USING 'CRICFLTR' sodvrsio
                             CHANGING lf_locked l_locks.
        CLEAR l_msg.
        CONCATENATE l_msg
        'CR system filters are locked by other users'(l95)
        INTO l_msg SEPARATED BY space.
        IF lf_locked <> 'X'.
          l_answer = 1.
        ELSE.
          CALL FUNCTION 'POPUP_TO_CONFIRM'
            EXPORTING
              titlebar      = l_msg
              text_question = 'Do you want to continue?'(l02)
              text_button_1 = 'Yes'(l03)
              text_button_2 = 'No'(l04)
            IMPORTING
              answer        = l_answer
            EXCEPTIONS
             TEXT_NOT_FOUND    = 1
             OTHERS        = 2.
"(++)BOC UMITTAL SE VF scan-25/11/2024
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        ENDIF.

        IF l_answer = '1'.

          IF ovrwrt = 'X'.
*--Delete existing data
            PERFORM delete_data USING 'CRITFLTR' lf_locked.
          ENDIF.
          IF f_ctfltr = 'X'.
            MODIFY /psyng/sw_systcd FROM TABLE lt_systcd.

            IF NOT lt_systcd[] IS INITIAL..
              PERFORM log  USING
               fn_ctflt 'S' '' '' '' ''  text-198.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
*--Critical transactions

      IF f_ct = 'X'.


        PERFORM check_lock USING 'CRITCODES' sodvrsio
                           CHANGING lf_locked l_locks.
        CLEAR l_msg.
        CONCATENATE l_msg
        'Critical Transactions are locked by other users'(l06)
        INTO l_msg SEPARATED BY space.
        IF lf_locked <> 'X'.
          l_answer = 1.
        ELSE.
          CALL FUNCTION 'POPUP_TO_CONFIRM'
            EXPORTING
              titlebar      = l_msg
              text_question = 'Do you want to continue?'(l02)
              text_button_1 = 'Yes'(l03)
              text_button_2 = 'No'(l04)
            IMPORTING
              answer        = l_answer
     EXCEPTIONS
             TEXT_NOT_FOUND    = 1
             OTHERS        = 2.
"(++)BOC UMITTAL SE VF scan-25/11/2024
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        ENDIF.
        IF l_answer = '1'.

          IF ovrwrt = 'X'.
*--Delete existing data
            PERFORM delete_data USING 'CRITCODES' lf_locked.
            CLEAR g_append_flag.
          ENDIF.

          DATA : l_critran_added    TYPE c,
                 l_critran_modif    TYPE c,
                 l_critxt_added     TYPE c,
                 l_critran_uploaded TYPE i,
                 l_critxt_uploaded  TYPE i.


          IF  f_ct = 'X' .


            CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_TCODES'
              EXPORTING
                i_vrsio             = sodvrsio
                append_flag         = g_append_flag
              IMPORTING
                critran_added       = l_critran_added
                critran_modif       = l_critran_modif
                critxt_added        = l_critxt_added
              TABLES
                critcodes           = lt_ct
              EXCEPTIONS
*               not_authorized_to_import = 1
                empty_list_provided = 2
                OTHERS              = 3.

            IF sy-subrc <> 0.
              CASE sy-subrc.
                WHEN 1.
                  PERFORM log  USING
                    fn_ct  'E' '' '' '' ''  text-a01.
                WHEN 2.
                  PERFORM log  USING
                    fn_ct  'E' '' '' '' ''  text-a12.
                WHEN OTHERS.
                  PERFORM log  USING
                    fn_ct  'E' '' '' '' ''  text-a04.
              ENDCASE.
            ELSE.
              IF f_ct = 'X'.
                IF l_critran_added = 'Y' OR l_critran_modif = 'Y'.
                  PERFORM log  USING
                    fn_ct 'S' '' '' '' ''  text-091.
                ELSE.
                  PERFORM log  USING
                    fn_ct 'E' '' '' '' ''  text-092.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.

        ENDIF.
      ENDIF.

*-- Critical transaction Text

      IF f_ctxt = 'X'.

        PERFORM check_lock USING 'CRITTEXT' sodvrsio
                           CHANGING lf_locked l_locks.
        CLEAR l_msg.
        CONCATENATE l_msg
        'Critical Transactions are locked by other users'(l06)
        INTO l_msg SEPARATED BY space.
        IF lf_locked <> 'X'.
          l_answer = 1.
        ELSE.
          CALL FUNCTION 'POPUP_TO_CONFIRM'
            EXPORTING
              titlebar       = l_msg
              text_question  = 'Do you want to continue?'(l02)
              text_button_1  = 'Yes'(l03)
              text_button_2  = 'No'(l04)
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
        ENDIF.
        IF l_answer = '1'.

          IF ovrwrt = 'X'.
*            --delete existing data
            PERFORM delete_data USING 'CRITTEXT' lf_locked.
            CLEAR g_append_flag.
          ENDIF.

          IF f_ctxt = 'X'.

            CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_TCODES'
              EXPORTING
                i_vrsio             = sodvrsio
                append_flag         = g_append_flag
              IMPORTING
                critran_added       = l_critran_added
                critxt_added        = l_critxt_added
              TABLES
                texts               = lt_ctxt
              EXCEPTIONS
*               not_authorized_to_import = 1
                empty_list_provided = 2
                OTHERS              = 3.


            IF sy-subrc <> 0.
              CASE sy-subrc.
                WHEN 1.
                  PERFORM log  USING
                    fn_ctxt  'E' '' '' '' ''  text-a01.
                WHEN 2.
                  PERFORM log  USING
                    fn_ctxt  'E' '' '' '' ''  text-a12.
                WHEN OTHERS.
                  PERFORM log  USING
                    fn_ctxt  'E' '' '' '' ''  text-a04.
              ENDCASE.
            ELSE.
              IF f_ctxt = 'X'.
                IF l_critxt_added = 'Y'.
                  PERFORM log  USING
                  fn_ctxt 'S' '' '' '' ''  text-170.
                ELSE.
                  PERFORM log  USING
                  fn_ctxt 'E' '' '' '' ''  text-171.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.

        ENDIF.
      ENDIF.

*--Critical roles

      IF f_cr = 'X'.
        PERFORM check_lock USING 'CRIROLES' sodvrsio
                           CHANGING lf_locked l_locks.
        CLEAR l_msg.
        CONCATENATE l_msg
        'Critical Roles are locked by other users'(l71)
        INTO l_msg SEPARATED BY space.
        IF lf_locked <> 'X'.
          l_answer = 1.
        ELSE.
          CALL FUNCTION 'POPUP_TO_CONFIRM'
            EXPORTING
              titlebar      = l_msg
              text_question = 'Do you want to continue?'(l02)
              text_button_1 = 'Yes'(l03)
              text_button_2 = 'No'(l04)
            IMPORTING
              answer        = l_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND      = 1
             OTHERS              = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        ENDIF.
        IF l_answer = '1'.

          IF ovrwrt = 'X'.
*--Delete existing data
            PERFORM delete_data USING 'CRIROLES' lf_locked.
            CLEAR g_append_flag.
          ENDIF.

          DATA : l_crirole_added    TYPE c,
                 l_crirole_modif    TYPE c,
                 l_crirtxt_added    TYPE c,
                 l_crirole_uploaded TYPE i,
                 l_crirtxt_uploaded TYPE i.

          IF  f_cr = 'X'.

            CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_ROLES'
              EXPORTING
                i_vrsio             = sodvrsio
                append_flag         = g_append_flag
              IMPORTING
                crirole_added       = l_crirole_added
                crirole_modif       = l_crirole_modif
                critxt_added        = l_crirtxt_added
              TABLES
                criroles            = lt_cr
              EXCEPTIONS
*               not_authorized_to_import = 1
                empty_list_provided = 2
                OTHERS              = 3.

            IF sy-subrc <> 0.
              CASE sy-subrc.
                WHEN 1.
                  PERFORM log  USING
                    fn_cr  'E' '' '' '' ''  text-a01.
                WHEN 2.
                  PERFORM log  USING
                    fn_cr  'E' '' '' '' ''  text-a17.
                WHEN OTHERS.
                  PERFORM log  USING
                    fn_cr  'E' '' '' '' ''  text-a04.
              ENDCASE.
            ELSE.
              IF f_cr = 'X'.
                IF l_crirole_added = 'Y' OR l_crirole_modif = 'Y'.
                  PERFORM log  USING
                    fn_cr 'S' '' '' '' ''  text-172.
                ELSE.
                  PERFORM log  USING
                    fn_cr 'E' '' '' '' ''  text-175.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.

        ENDIF.
      ENDIF.

*--Critical Role Text

      IF f_crtxt = 'X'.
        PERFORM check_lock USING 'CRIRTEXT' sodvrsio
                           CHANGING lf_locked l_locks.
        CLEAR l_msg.
        CONCATENATE l_msg
        'Critical Roles are locked by other users'(l71)
        INTO l_msg SEPARATED BY space.
        IF lf_locked <> 'X'.
          l_answer = 1.
        ELSE.
          CALL FUNCTION 'POPUP_TO_CONFIRM'
            EXPORTING
              titlebar      = l_msg
              text_question = 'Do you want to continue?'(l02)
              text_button_1 = 'Yes'(l03)
              text_button_2 = 'No'(l04)
            IMPORTING
              answer        = l_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND      = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        ENDIF.
        IF l_answer = '1'.

          IF ovrwrt = 'X'.
*--Delete existing data
            PERFORM delete_data USING 'CRIRTEXT' lf_locked.
            CLEAR g_append_flag.
          ENDIF.

          IF f_crtxt = 'X'.

            CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_ROLES'
              EXPORTING
                i_vrsio             = sodvrsio
                append_flag         = g_append_flag
              IMPORTING
                crirole_added       = l_crirole_added
                critxt_added        = l_crirtxt_added
              TABLES
                texts               = lt_crtxt
              EXCEPTIONS
*               not_authorized_to_import = 1
                empty_list_provided = 2
                OTHERS              = 3.

            IF sy-subrc <> 0.
              CASE sy-subrc.
                WHEN 1.
                  PERFORM log  USING
                    fn_crtxt  'E' '' '' '' ''  text-a01.
                WHEN 2.
                  PERFORM log  USING
                    fn_crtxt  'E' '' '' '' ''  text-a17.
                WHEN OTHERS.
                  PERFORM log  USING
                    fn_crtxt  'E' '' '' '' ''  text-a04.
              ENDCASE.
            ELSE.
              IF f_crtxt = 'X'.
                IF l_crirtxt_added = 'Y'.
                  PERFORM log  USING
                  fn_crtxt 'S' '' '' '' ''  text-174.
                ELSE.
                  PERFORM log  USING
                  fn_crtxt 'E' '' '' '' ''  text-173.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.

        ENDIF.
      ENDIF.


*--Critical profile

      IF f_cp = 'X'.
        PERFORM check_lock USING 'CRIPROF' sodvrsio
                           CHANGING lf_locked l_locks.
        CLEAR l_msg.
        CONCATENATE l_msg
        'Critical Profiles are locked by other users'(l76)
        INTO l_msg SEPARATED BY space.
        IF lf_locked <> 'X'.
          l_answer = 1.
        ELSE.
          CALL FUNCTION 'POPUP_TO_CONFIRM'
            EXPORTING
              titlebar      = l_msg
              text_question = 'Do you want to continue?'(l02)
              text_button_1 = 'Yes'(l03)
              text_button_2 = 'No'(l04)
            IMPORTING
              answer        = l_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND   = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        ENDIF.
        IF l_answer = '1'.

          IF ovrwrt = 'X'.
*--Delete existing data
            PERFORM delete_data USING 'CRIPROF' lf_locked.
            CLEAR g_append_flag.
          ENDIF.

          DATA : l_criprof_added    TYPE c,
                 l_criprof_modif    TYPE c,
                 l_criptxt_added    TYPE c,
                 l_criprof_uploaded TYPE i,
                 l_criptxt_uploaded TYPE i.


          IF  f_cp = 'X'.

            CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_PROFILES'
              EXPORTING
                i_vrsio             = sodvrsio
                append_flag         = g_append_flag
              IMPORTING
                criprof_added       = l_criprof_added
                criprof_modif       = l_criprof_modif
                critxt_added        = l_criptxt_added
              TABLES
                criprof             = lt_cp
              EXCEPTIONS
*               not_authorized_to_import = 1
                empty_list_provided = 2
                OTHERS              = 3.

            IF sy-subrc <> 0.
              CASE sy-subrc.
                WHEN 1.
                  PERFORM log  USING
                    fn_cp  'E' '' '' '' ''  text-a01.
                WHEN 2.
                  PERFORM log  USING
                    fn_cp  'E' '' '' '' ''  text-a17.
                WHEN OTHERS.
                  PERFORM log  USING
                    fn_cp  'E' '' '' '' ''  text-a04.
              ENDCASE.
            ELSE.
              IF f_cp = 'X'.
                IF l_criprof_added = 'Y' OR l_criprof_modif = 'Y'.
                  PERFORM log  USING
                    fn_cp 'S' '' '' '' ''  text-176.
                ELSE.
                  PERFORM log  USING
                    fn_cp 'E' '' '' '' ''  text-177.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.

        ENDIF.
      ENDIF.

*-- Critical Profile Text

      IF f_cptxt = 'X'.
        PERFORM check_lock USING 'CRIPTEXT' sodvrsio
                           CHANGING lf_locked l_locks.
        CLEAR l_msg.
        CONCATENATE l_msg
        'Critical Profiles are locked by other users'(l76)
        INTO l_msg SEPARATED BY space.
        IF lf_locked <> 'X'.
          l_answer = 1.
        ELSE.
          CALL FUNCTION 'POPUP_TO_CONFIRM'
            EXPORTING
              titlebar      = l_msg
              text_question = 'Do you want to continue?'(l02)
              text_button_1 = 'Yes'(l03)
              text_button_2 = 'No'(l04)
            IMPORTING
              answer        = l_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND   = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        ENDIF.
        IF l_answer = '1'.

          IF ovrwrt = 'X'.
*--Delete existing data
            PERFORM delete_data USING 'CRIPTEXT' lf_locked.
            CLEAR g_append_flag.
          ENDIF.

          IF f_cptxt = 'X'.

            CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_PROFILES'
              EXPORTING
                i_vrsio             = sodvrsio
                append_flag         = g_append_flag
              IMPORTING
                criprof_added       = l_criprof_added
                critxt_added        = l_criptxt_added
              TABLES
                texts               = lt_cptxt
              EXCEPTIONS
*               not_authorized_to_import = 1
                empty_list_provided = 2
                OTHERS              = 3.


            IF sy-subrc <> 0.
              CASE sy-subrc.
                WHEN 1.
                  PERFORM log  USING
                    fn_cptxt  'E' '' '' '' ''  text-a01.
                WHEN 2.
                  PERFORM log  USING
                    fn_cptxt  'E' '' '' '' ''  text-a17.
                WHEN OTHERS.
                  PERFORM log  USING
                    fn_cptxt  'E' '' '' '' ''  text-a04.
              ENDCASE.
            ELSE.
              IF f_cptxt = 'X'.
                IF l_criptxt_added = 'Y'.
                  PERFORM log  USING
                  fn_cptxt 'S' '' '' '' ''  text-178.
                ELSE.
                  PERFORM log  USING
                  fn_cptxt 'E' '' '' '' ''  text-179.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.

        ENDIF.
      ENDIF.

*--Functions


      PERFORM check_lock USING 'FUNCTION' sodvrsio
                         CHANGING lf_locked l_locks.
      l_msg = l_locks.
      CONCATENATE l_msg 'Functions are locked by other users'(l01)
      INTO l_msg SEPARATED BY space.
      IF lf_locked <> 'X'.
        l_answer = 1.
      ELSE.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar      = l_msg
            text_question = 'Do you want to continue?'(l02)
            text_button_1 = 'Yes'(l03)
            text_button_2 = 'No'(l04)
          IMPORTING
            answer        = l_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      ENDIF.
      IF l_answer = '1'.

        IF ovrwrt = 'X'.
*--Delete existing data
          PERFORM delete_data USING 'FUNCTION' lf_locked.
        ENDIF.

        DATA : l_funid_added      TYPE c,
               l_funid_hdr_added  TYPE c,
               l_funid_tc_added   TYPE c,
               l_funid_txt_added  TYPE c,
               l_funct_objs_added TYPE c,
               lt_funt_part       TYPE TABLE OF /psyng/texts,
               lt_fund_part       TYPE TABLE OF /psyng/functtran,
               lt_objd_part       TYPE TABLE OF /psyng/faobj2,
               l_funh_uploaded    TYPE i,
               l_fund_uploaded    TYPE i,
               l_funt_uploaded    TYPE i,
               l_objd_uploaded    TYPE i,
               l_sysfun_uploaded  TYPE i.

        LOOP AT lt_funh.
          CLEAR :
          l_funid_added,
          l_funid_hdr_added,
          l_funid_tc_added,
          l_funid_txt_added,
          l_funct_objs_added ,
          l_sysfun_uploaded.

          CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
            EXPORTING
              wa_function             = lt_funh
              i_vrsio                 = sodvrsio
              i_langu                 = sy-langu
              f_funt                  = f_funt
            IMPORTING
              funid_added             = l_funid_added
              funid_hdr_added         = l_funid_hdr_added
*             funid_tc_added          = l_funid_tc_added
*             funid_txt_added         = l_funid_txt_added
*             funct_objs_added        = l_funct_objs_added
*               TABLES
*             texts                   = lt_funt_part
*             functtran               = lt_fund_part
*             faobj                   = lt_objd_part
            EXCEPTIONS
              target_not_specified    = 1
              not_authorized          = 2
              function_already_exists = 3
              locked                  = 4
              OTHERS                  = 5.
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                PERFORM log  USING
                  fn_funh  'E' 'SOD Function ID :'(125)
                  lt_funh-function '' ''  text-a02.
              WHEN 2.
                PERFORM log  USING
                  fn_funh  'E' 'SOD Function ID :'(125)
                  lt_funh-function '' ''  text-a01.
              WHEN 3.
                PERFORM log  USING
                  fn_funh  'E' 'SOD Function ID :'(125)
                  lt_funh-function '' ''  text-a03.
              WHEN 4.
                PERFORM log  USING
                  fn_funh  'E' 'SOD Function ID :'(125)
                  lt_funh-function '' ''  text-a15.
              WHEN OTHERS.
                PERFORM log  USING
                  fn_funh  'E' 'SOD Function ID :'(125)
                  lt_funh-function '' ''  text-a04.
            ENDCASE.
          ENDIF.

          REFRESH :lt_funt_part,  lt_fund_part, lt_objd_part.
          IF f_funt = 'X'.
            LOOP AT lt_funt WHERE textname = lt_funh-function.
              APPEND lt_funt TO lt_funt_part.
            ENDLOOP.

            CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
              EXPORTING
                wa_function             = lt_funh
                i_vrsio                 = sodvrsio
                i_langu                 = sy-langu
                f_funt                  = f_funt
              IMPORTING
*               funid_added             = l_funid_added
*               funid_hdr_added         = l_funid_hdr_added
*               funid_tc_added          = l_funid_tc_added
                funid_txt_added         = l_funid_txt_added
*               funct_objs_added        = l_funct_objs_added
              TABLES
                texts                   = lt_funt_part
*               functtran               = lt_fund_part
*               faobj                   = lt_objd_part
              EXCEPTIONS
                target_not_specified    = 1
                not_authorized          = 2
                function_already_exists = 3
                locked                  = 4
                OTHERS                  = 5.
            IF sy-subrc <> 0.
              CASE sy-subrc.
                WHEN 1.
                  PERFORM log  USING
                    fn_funt  'E' 'SOD Function ID :'(125)
                    lt_funh-function '' ''  text-a02.
                WHEN 2.
                  PERFORM log  USING
                    fn_funt  'E' 'SOD Function ID :'(125)
                    lt_funh-function '' ''  text-a01.
                WHEN 3.
                  PERFORM log  USING
                    fn_funt  'E' 'SOD Function ID :'(125)
                    lt_funh-function '' ''  text-a03.
                WHEN 4.
                  PERFORM log  USING
                    fn_funt  'E' 'SOD Function ID :'(125)
                    lt_funh-function '' ''  text-a15.
                WHEN OTHERS.
                  PERFORM log  USING
                    fn_funt  'E' 'SOD Function ID :'(125)
                    lt_funh-function '' ''  text-a04.
              ENDCASE.
            ENDIF.
          ENDIF.



          IF f_fund = 'X'.
            LOOP AT lt_fund WHERE functionid = lt_funh-function.
              APPEND lt_fund TO lt_fund_part.
            ENDLOOP.

            CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
              EXPORTING
                wa_function             = lt_funh
                i_vrsio                 = sodvrsio
                i_langu                 = sy-langu
                f_funt                  = f_funt
              IMPORTING
*               funid_added             = l_funid_added
*               funid_hdr_added         = l_funid_hdr_added
                funid_tc_added          = l_funid_tc_added
*               funid_txt_added         = l_funid_txt_added
*               funct_objs_added        = l_funct_objs_added
              TABLES
*               texts                   = lt_funt_part
                functtran               = lt_fund_part
*               faobj                   = lt_objd_part
              EXCEPTIONS
                target_not_specified    = 1
                not_authorized          = 2
                function_already_exists = 3
                locked                  = 4
                OTHERS                  = 5.
            IF sy-subrc <> 0.
              CASE sy-subrc.
                WHEN 1.
                  PERFORM log  USING
                    fn_fund  'E' 'SOD Function ID :'(125)
                    lt_funh-function '' ''  text-a02.
                WHEN 2.
                  PERFORM log  USING
                    fn_fund  'E' 'SOD Function ID :'(125)
                    lt_funh-function '' ''  text-a01.
                WHEN 3.
                  PERFORM log  USING
                    fn_fund  'E' 'SOD Function ID :'(125)
                    lt_funh-function '' ''  text-a03.
                WHEN 4.
                  PERFORM log  USING
                    fn_fund  'E' 'SOD Function ID :'(125)
                    lt_funh-function '' ''  text-a15.
                WHEN OTHERS.
                  PERFORM log  USING
                    fn_fund  'E' 'SOD Function ID :'(125)
                    lt_funh-function '' ''  text-a04.
              ENDCASE.
            ENDIF.
          ENDIF.

          IF f_objd = 'X'.
            LOOP AT lt_objd WHERE funid = lt_funh-function.
              APPEND lt_objd TO lt_objd_part.
            ENDLOOP.

            CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
              EXPORTING
                wa_function             = lt_funh
                i_vrsio                 = sodvrsio
                i_langu                 = sy-langu
                f_funt                  = f_funt
              IMPORTING
*               funid_added             = l_funid_added
*               funid_hdr_added         = l_funid_hdr_added
*               funid_tc_added          = l_funid_tc_added
*               funid_txt_added         = l_funid_txt_added
                funct_objs_added        = l_funct_objs_added
              TABLES
*               texts                   = lt_funt_part
*               functtran               = lt_fund_part
                faobj                   = lt_objd_part
              EXCEPTIONS
                target_not_specified    = 1
                not_authorized          = 2
                function_already_exists = 3
                locked                  = 4
                OTHERS                  = 5.
            IF sy-subrc <> 0.
              CASE sy-subrc.
                WHEN 1.
                  PERFORM log  USING
                    fn_objd  'E' 'SOD Function ID :'(125)
                    lt_funh-function '' ''  text-a02.
                WHEN 2.
                  PERFORM log  USING
                    fn_objd  'E' 'SOD Function ID :'(125)
                    lt_funh-function '' ''  text-a01.
                WHEN 3.
                  PERFORM log  USING
                    fn_objd  'E' 'SOD Function ID :'(125)
                    lt_funh-function '' ''  text-a03.
                WHEN 4.
                  PERFORM log  USING
                    fn_objd  'E' 'SOD Function ID :'(125)
                    lt_funh-function '' ''  text-a15.
                WHEN OTHERS.
                  PERFORM log  USING
                    fn_objd  'E' 'SOD Function ID :'(125)
                    lt_funh-function '' ''  text-a04.
              ENDCASE.
            ENDIF.
          ENDIF.

*          CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
*               EXPORTING
*                    wa_function             = lt_funh
*                    i_vrsio                 = sodvrsio
*                    i_langu                 = sy-langu
*                    f_funt                  = f_funt
*               IMPORTING
*                    funid_added             = l_funid_added
*                    funid_hdr_added         = l_funid_hdr_added
*                    funid_tc_added          = l_funid_tc_added
*                    funid_txt_added         = l_funid_txt_added
*                    funct_objs_added        = l_funct_objs_added
*               TABLES
*                    texts                   = lt_funt_part
*                    functtran               = lt_fund_part
*                    faobj                   = lt_objd_part
*               EXCEPTIONS
*                    target_not_specified    = 1
*                    not_authorized          = 2
*                    function_already_exists = 3
*                    locked                  = 4
*                    OTHERS                  = 5.
*          IF sy-subrc <> 0.
*            CASE sy-subrc.
*              WHEN 1.
*                PERFORM log  USING
*                  fn_funh  'E' 'SOD Function ID :'(125)
*                  lt_funh-function '' ''  text-a02.
*              WHEN 2.
*                PERFORM log  USING
*                  fn_funh  'E' 'SOD Function ID :'(125)
*                  lt_funh-function '' ''  text-a01.
*              WHEN 3.
*                PERFORM log  USING
*                  fn_funh  'E' 'SOD Function ID :'(125)
*                  lt_funh-function '' ''  text-a03.
*              WHEN 4.
*                PERFORM log  USING
*                  fn_funh  'E' 'SOD Function ID :'(125)
*                  lt_funh-function '' ''  text-a15.
*              WHEN OTHERS.
*                PERFORM log  USING
*                  fn_funh  'E' 'SOD Function ID :'(125)
*                  lt_funh-function '' ''  text-a04.
*            ENDCASE.
*          ELSE.
          IF sy-subrc = 0.
            ADD 1 TO l_funh_uploaded.
            IF f_funt = 'X'.
              IF l_funid_txt_added <> 'Y'.
                PERFORM log  USING
                  fn_funt  'W' 'SOD Function ID :'(125)
                  lt_funh-function '' ''  text-a05.
              ELSE.
                ADD 1 TO l_funt_uploaded.
              ENDIF.
            ENDIF.
            IF f_fund = 'X' .
*              IF l_funid_tc_added <> 'Y'.
*                PERFORM log  USING
*                  fn_fund  'W' 'SOD Function ID :'(125)
*                  lt_funh-function '' ''  text-a06.
*              ELSE.
              ADD 1 TO l_fund_uploaded.
*              ENDIF.
            ENDIF.
            IF f_objd = 'X'.
              IF l_funct_objs_added <> 'Y'.
                PERFORM log  USING
                  fn_objd  'W' 'SOD Function ID :'(125)
                  lt_funh-function '' ''  text-a07.
              ELSE.
                ADD 1 TO l_objd_uploaded.
              ENDIF.
            ENDIF.
          ENDIF.

          IF f_fnfltr = 'X'.
            IF NOT lt_sysfun[] IS INITIAL.
              LOOP AT lt_sysfun.
                ADD 1 TO l_sysfun_uploaded.
              ENDLOOP.
            ENDIF.
            MODIFY /psyng/sw_sysfun FROM TABLE lt_sysfun.
          ENDIF.

        ENDLOOP.

        IF lt_funh[] IS INITIAL AND ovrwrt = 'X'.
          PERFORM log  USING
                    'Function Header' 'W' '' '' '' ''  text-202.
        ENDIF.

*****---system filter
        IF l_sysfun_uploaded > 0 AND f_fnfltr = 'X'.
          PERFORM log  USING
           fn_fflt 'S' '' '' '' ''  text-196.
        ENDIF.
*     end

        IF l_funh_uploaded  > 0 AND f_funh = 'X'.
          PERFORM log  USING
            fn_funh 'S' '' '' '' ''  text-094.
        ENDIF.
        IF l_fund_uploaded  > 0 AND f_fund = 'X'.
          PERFORM log  USING
            fn_fund 'S' '' '' '' ''  text-097.
        ENDIF.
        IF l_objd_uploaded  > 0 AND f_objd = 'X'.
          PERFORM log  USING
            fn_objd 'S' '' '' '' ''  text-106.
        ENDIF.

        IF l_funt_uploaded  > 0 AND f_funt = 'X'.
          PERFORM log  USING
            fn_funt 'S' '' '' '' ''  text-081.
        ENDIF.
      ENDIF.
    ENDIF.


*--Conflicts
    PERFORM check_lock USING 'CONFLICT' sodvrsio
    CHANGING lf_locked l_locks.
    l_msg = l_locks.
    CONCATENATE l_msg 'Conflict(s) are locked by other users'(l05)
    INTO l_msg SEPARATED BY space.
    IF lf_locked <> 'X'.
      l_answer = 1.
    ELSE.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar      = l_msg
          text_question = 'Do you want to continue?'(l02)
          text_button_1 = 'Yes'(l03)
          text_button_2 = 'No'(l04)
        IMPORTING
          answer        = l_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND  = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
    ENDIF.
    IF l_answer = '1'.
      IF ovrwrt = 'X'.
*--Delete existing data
        PERFORM delete_data USING 'CONFLICT' lf_locked.
      ENDIF.

      DATA : l_conid_added     TYPE c,
             l_conid_hdr_added TYPE c,
             l_conid_fun_added TYPE c,
             l_conid_txt_added TYPE c,
             l_conowner_added  TYPE c,
             l_conpmit_added   TYPE c,
             l_corg_added      TYPE c,
             lt_cont_part      TYPE TABLE OF /psyng/texts,
             lt_cond_part      TYPE TABLE OF /psyng/confdet,
             lt_cono_part      TYPE TABLE OF /psyng/conowner,
             lt_conpmit_part   TYPE TABLE OF /psyng/conpmit,
             l_conh_uploaded   TYPE i,
             l_cond_uploaded   TYPE i,
             l_cont_uploaded   TYPE i,
             l_cono_uploaded   TYPE i,
             l_conm_uploaded   TYPE i,
             l_syscon_uploaded TYPE i,
             l_corg_uploaded   TYPE i.
*BOC UMITTAL SE-CAC Integration for mass upload 05/03/2026
 DATA : lv_cfg_dflt_sod TYPE /psyng/param_value,
        lv_versio TYPE /psyng/sodvrsio,
        lo_obj TYPE REF TO /psyng/se_cac_intg.
*EOC UMITTAL SE-CAC Integration for mass upload 05/03/2026
      LOOP AT lt_conh.
        CLEAR :
        l_conid_added,
        l_conid_hdr_added,
        l_conid_fun_added,
        l_conid_txt_added,
        l_conowner_added,
        l_conpmit_added,
        l_corg_added.
        CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
          EXPORTING
            wa_conflict           = lt_conh
            i_vrsio               = sodvrsio
            f_cont                = f_cont
          IMPORTING
            conid_added           = l_conid_added
            conid_hdr_added       = l_conid_hdr_added
*           conid_fun_added       = l_conid_fun_added
*           conid_txt_added       = l_conid_txt_added
*           conowner_added        = l_conowner_added
*              TABLES
*           texts                 = lt_cont_part
**                  confdet               = lt_cond_part
**                  conowner              = lt_cono_part
          EXCEPTIONS
            target_not_specified  = 1
            target_already_exists = 2
            not_authorized        = 3
            locked                = 4
            OTHERS                = 5.
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
              PERFORM log  USING
                fn_conh  'E' 'Conflict ID :'(137)
                lt_conh-conid '' ''  text-a02.
            WHEN 2.
              PERFORM log  USING
                fn_conh  'E' 'Conflict ID :'(137)
                lt_conh-conid '' ''  text-a08.
            WHEN 3.
              PERFORM log  USING
                fn_conh  'E' 'Conflict ID :'(137)
                lt_conh-conid '' ''  text-a01.
            WHEN 4.
              PERFORM log  USING
                fn_conh  'E' 'Conflict ID :'(137)
                lt_conh-conid '' ''  text-a15.

            WHEN OTHERS.
              PERFORM log  USING
                fn_conh  'E' 'Conflict ID :'(137)
                lt_conh-conid '' ''  text-a04.
          ENDCASE.
        ENDIF.

        REFRESH :lt_cont_part,  lt_cond_part, lt_cono_part.
        IF f_cont = 'X'.
          LOOP AT lt_cont WHERE textname = lt_conh-conid.
            APPEND lt_cont TO lt_cont_part.
          ENDLOOP.

          CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
            EXPORTING
              wa_conflict           = lt_conh
              i_vrsio               = sodvrsio
              f_cont                = f_cont
            IMPORTING
*             conid_added           = l_conid_added
*             conid_hdr_added       = l_conid_hdr_added
*             conid_fun_added       = l_conid_fun_added
              conid_txt_added       = l_conid_txt_added
*             conowner_added        = l_conowner_added
            TABLES
              texts                 = lt_cont_part
*             confdet               = lt_cond_part
*             conowner              = lt_cono_part
            EXCEPTIONS
              target_not_specified  = 1
              target_already_exists = 2
              not_authorized        = 3
              locked                = 4
              OTHERS                = 5.
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                PERFORM log  USING
                  fn_cont  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a02.
              WHEN 2.
                PERFORM log  USING
                  fn_cont  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a08.
              WHEN 3.
                PERFORM log  USING
                  fn_cont  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a01.
              WHEN 4.
                PERFORM log  USING
                  fn_cont  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a15.

              WHEN OTHERS.
                PERFORM log  USING
                  fn_cont  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a04.
            ENDCASE.
          ENDIF.
        ENDIF.
        IF f_cond = 'X'.
          LOOP AT lt_cond WHERE conid = lt_conh-conid.
            APPEND lt_cond TO lt_cond_part.
          ENDLOOP.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
            EXPORTING
              wa_conflict           = lt_conh
              i_vrsio               = sodvrsio
              f_cont                = f_cont
            IMPORTING
*             conid_added           = l_conid_added
*             conid_hdr_added       = l_conid_hdr_added
              conid_fun_added       = l_conid_fun_added
*             conid_txt_added       = l_conid_txt_added
*             conowner_added        = l_conowner_added
            TABLES
*             texts                 = lt_cont_part
              confdet               = lt_cond_part
*             conowner              = lt_cono_part
            EXCEPTIONS
              target_not_specified  = 1
              target_already_exists = 2
              not_authorized        = 3
              locked                = 4
              OTHERS                = 5.
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                PERFORM log  USING
                  fn_cond  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a02.
              WHEN 2.
                PERFORM log  USING
                  fn_cond  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a08.
              WHEN 3.
                PERFORM log  USING
                  fn_cond  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a01.
              WHEN 4.
                PERFORM log  USING
                  fn_cond  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a15.

              WHEN OTHERS.
                PERFORM log  USING
                  fn_cond  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a04.
            ENDCASE.
          ENDIF.

        ENDIF.
        IF f_cono = 'X'.
          LOOP AT lt_cono WHERE conid = lt_conh-conid.
            APPEND lt_cono TO lt_cono_part.
          ENDLOOP.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
            EXPORTING
              wa_conflict           = lt_conh
              i_vrsio               = sodvrsio
              f_cont                = f_cont
            IMPORTING
*             conid_added           = l_conid_added
*             conid_hdr_added       = l_conid_hdr_added
*             conid_fun_added       = l_conid_fun_added
*             conid_txt_added       = l_conid_txt_added
              conowner_added        = l_conowner_added
            TABLES
*             texts                 = lt_cont_part
*             confdet               = lt_cond_part
              conowner              = lt_cono_part
            EXCEPTIONS
              target_not_specified  = 1
              target_already_exists = 2
              not_authorized        = 3
              locked                = 4
              OTHERS                = 5.
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                PERFORM log  USING
                  fn_cono  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a02.
              WHEN 2.
                PERFORM log  USING
                  fn_cono  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a08.
              WHEN 3.
                PERFORM log  USING
                  fn_cono  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a01.
              WHEN 4.
                PERFORM log  USING
                  fn_cono  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a15.

              WHEN OTHERS.
                PERFORM log  USING
                  fn_cono  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a04.
            ENDCASE.
          ENDIF.

        ENDIF.

        IF f_conm = 'X'.
          LOOP AT lt_conpmit WHERE conid = lt_conh-conid.
            APPEND lt_conpmit TO lt_conpmit_part.
          ENDLOOP.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
            EXPORTING
              wa_conflict           = lt_conh
              i_vrsio               = sodvrsio
              f_cont                = f_cont
            IMPORTING
              conpmit_added         = l_conpmit_added
            TABLES
              conpmit               = lt_conpmit_part
            EXCEPTIONS
              target_not_specified  = 1
              target_already_exists = 2
              not_authorized        = 3
              locked                = 4
              OTHERS                = 5.
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                PERFORM log  USING
                  fn_conm  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a02.
              WHEN 2.
                PERFORM log  USING
                  fn_conm  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a08.
              WHEN 3.
                PERFORM log  USING
                  fn_conm  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a01.
              WHEN 4.
                PERFORM log  USING
                  fn_conm  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a15.

              WHEN OTHERS.
                PERFORM log  USING
                  fn_conm  'E' 'Conflict ID :'(137)
                  lt_conh-conid '' ''  text-a04.
            ENDCASE.
          ENDIF.

        ENDIF.

        IF sy-subrc = 0.
          ADD 1 TO l_conh_uploaded.
          IF f_cont = 'X'.
            IF l_conid_txt_added <> 'Y'.
              PERFORM log  USING
                fn_cont  'W' 'Conflict ID :'(137)
                lt_conh-conid '' ''  text-a09.
            ELSE.
              ADD 1 TO l_cont_uploaded.
            ENDIF.
          ENDIF.
          IF f_cond = 'X' .
*            IF l_conid_fun_added <> 'Y'.
*           if we're re-uploading the
*           existing functions, this would not be Y and this message was
*           confusinh
            IF lt_cond_part[] IS INITIAL.
              PERFORM log  USING
                fn_cond  'W' 'Conflict ID :'(137)
                lt_conh-conid '' ''
                'No Functions added for this Conflict'(a10).
            ELSE.
              ADD 1 TO l_cond_uploaded.
            ENDIF.
          ENDIF.
          IF f_cono = 'X'.
            IF l_conowner_added <> 'Y'.
              PERFORM log  USING
                fn_cono  'W' 'Conflict ID :'(137)
                lt_conh-conid '' ''
                'No owners added for this conflict'(a11).
            ELSE.
              ADD 1 TO l_cono_uploaded.
            ENDIF.
          ENDIF.
          IF f_conm = 'X'.
            IF l_conpmit_added <> 'Y'.
              PERFORM log  USING
                fn_conm  'W' 'Conflict ID :'(137)
                lt_conh-conid '' ''
                'No Proposed Mitigations added for this conflict'(p12).
            ELSE.
              ADD 1 TO l_conm_uploaded.
            ENDIF.
          ENDIF.
        ENDIF.

        IF f_conflt = 'X'.
          LOOP AT lt_syscon.
            ADD 1 TO l_syscon_uploaded.
          ENDLOOP.
          MODIFY /psyng/sw_syscon FROM TABLE lt_syscon.
        ENDIF.

* Begin Changes by DDHIMAN 08.11.19
        IF f_corg = 'X'.
          LOOP AT lt_corg WHERE conid = lt_conh-conid.
            APPEND lt_corg TO lt_corg_part.
          ENDLOOP.
          LOOP AT lt_corg_part.
            CALL FUNCTION '/PSYNG/SW_ADD_CUSTOM_ORG'
              EXPORTING
                ls_corg     = lt_corg_part
                i_vrsio     = sodvrsio
                f_corg      = f_corg
              IMPORTING
                fcorg_added = l_corg_added.
          ENDLOOP.
        ENDIF.
* End Changes by DDHIMAN 08.11.19
      ENDLOOP.

*BOC UMITTAL SE-CAC Integration for mass upload 05/03/2026
        " Get DFLT_GLOBAL_VERSION configuration
        CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
          EXPORTING
            i_parameter = 'DFLT_GLOBAL_VERSION'
          IMPORTING
            e_value = lv_cfg_dflt_sod.
        lv_versio = lv_cfg_dflt_sod.
        IF  lv_versio EQ sodvrsio.
          CREATE OBJECT lo_obj.
          CALL METHOD lo_obj->call_se_integration
            EXPORTING
              sod_versio = sodvrsio    " SOD Version
            .
        ENDIF.
*EOC UMITTAL SE-CAC Integration for mass upload 05/03/2026


      IF f_conh = 'X'.
        IF lt_conh[] IS INITIAL AND ovrwrt = 'X'.
          PERFORM log  USING
                   'Conflict Header' 'W' '' '' '' ''  text-203.

        ENDIF.
      ENDIF.
***----system filter
      IF l_syscon_uploaded > 0 AND f_conflt = 'X'.
*        MODIFY /psyng/sw_syscon FROM TABLE lt_syscon.
        PERFORM log  USING
         fn_cnflt 'S' '' '' '' ''  text-197.
      ENDIF.
*     end

      IF l_conh_uploaded  > 0 AND f_conh = 'X'.
        PERFORM log  USING
          fn_conh 'S' '' '' '' ''  text-100.
      ENDIF.
      IF l_cont_uploaded  > 0 AND f_cont = 'X'.
        PERFORM log  USING
          fn_cont 'S' '' '' '' ''  text-078.
      ENDIF.
      IF l_cond_uploaded  > 0 AND f_cond = 'X'.
        PERFORM log  USING
          fn_cond 'S' '' '' '' ''  text-103.
      ENDIF.

      IF l_cono_uploaded  > 0 AND f_cono = 'X'.
        PERFORM log  USING
          fn_cono 'S' '' '' '' ''  text-157.
      ENDIF.

      IF l_conm_uploaded  > 0 AND f_conm = 'X'.
        PERFORM log  USING
          fn_conm 'S' '' '' '' ''  text-192.
      ENDIF.

      IF l_corg_added = 'Y' AND f_corg = 'X'.
        PERFORM log  USING
            fn_corg 'S' '' '' '' ''  text-206.
      ENDIF.

      IF l_corg_added = ' ' AND f_corg = 'X'.
        PERFORM log  USING
            fn_corg 'E' '' '' '' ''  text-207.
      ENDIF.

    ENDIF.
  ENDIF.


  DATA : l_total_uploaded TYPE i.
  l_total_uploaded = l_conh_uploaded +
  l_cont_uploaded +
  l_cond_uploaded +
  l_cono_uploaded +
  l_conm_uploaded +
  l_funh_uploaded +
  l_fund_uploaded +
  l_funt_uploaded +
  l_objd_uploaded +
  l_cah_uploaded +
  l_cad_uploaded +
  l_cat_uploaded.


ENDFORM.                    " UPLOAD_data
*&---------------------------------------------------------------------*
*&      Form  upload
*&---------------------------------------------------------------------*
*       Upload files
*----------------------------------------------------------------------*
*      <--ET_TABLE    Table to be uploaded
*      -->I_FILENAME  File name
*      -->I_ERR_TEXT  Error text
*----------------------------------------------------------------------*
FORM upload TABLES   et_table
            USING    i_filename TYPE rlgrap-filename
                     i_err_text
            CHANGING e_file_not_found TYPE flag.
  DATA: l_filename TYPE string,
        l_err_mess TYPE bapiret2-message,
        l_msgv1    TYPE bapiret2-message_v1,
        l_msgv2    TYPE bapiret2-message_v2.
  CLEAR e_file_not_found.
  FREE : et_table.
* To support Macbook file path C0590 by RGUPTA

  IF basepath CS '/'.
    CONCATENATE basepath '/' i_filename INTO l_filename.
  ELSE.
    CONCATENATE basepath '\' i_filename INTO l_filename.
  ENDIF.
  IF l_filename NP '*.txt'.
    MESSAGE s113(/psyng/sw) WITH 'Invalid Format'.
    LEAVE LIST-PROCESSING.
  ENDIF.

*BOC:HBHALLA (097)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '60'.
  IF sy-subrc = 0.
  CALL FUNCTION 'GUI_UPLOAD' "#EC SAST_CI_GEN_CHECK
    EXPORTING
      filename                = l_filename
      filetype                = 'ASC'
      has_field_separator     = 'X'
      dat_mode                = ' '
    TABLES
      data_tab                = et_table
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

  IF sy-subrc <> 0.
    e_file_not_found = 'X'.
    l_msgv1 = l_filename.
    l_msgv2 = i_err_text.
    CALL FUNCTION '/PSYNG/BC_004'
      EXPORTING
        i_subrc     = sy-subrc
        i_msgty     = 'I'
        i_msgv1     = l_msgv1
        i_msgv2     = l_msgv2
        if_no_popup = 'X'
      IMPORTING
        e_message   = l_err_mess.
    PERFORM log USING l_filename 'E' '' '' '' '' l_err_mess.
  ELSE.

    IF et_table[] IS INITIAL.

      PERFORM log USING i_filename 'W' '' '' '' '' 'Empty File'(201).
      EXIT.
    ENDIF.

  ENDIF.
  ENDIF.
*EOC:HBHALLA (097)
ENDFORM.                    " upload
*&---------------------------------------------------------------------*
*&      Form  validation
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_CONH  text
*      -->P_LT_FUNH  text
*      -->P_LT_FUND  text
*      -->P_LT_FUNT  text
*      -->P_LT_OBJD  text
*      -->P_LT_COND  text
*      -->P_LT_CONT  text
*      -->P_LT_CONO  text
*      -->P_LT_CAH  text
*      -->P_LT_CAD  text
*      -->P_LT_CAT  text
*      -->P_LT_CT  text
*----------------------------------------------------------------------*
FORM validation TABLES   iconflict   STRUCTURE /psyng/conflict
                         ifunction   STRUCTURE /psyng/function
                         ifuncttrans STRUCTURE /psyng/functtran
                         ftexts      STRUCTURE /psyng/texts
                         ifaobj      STRUCTURE /psyng/faobj2
                         isysfun    STRUCTURE /psyng/sw_sysfun
                         iconfdet    STRUCTURE /psyng/confdet
                         ctexts      STRUCTURE /psyng/texts
                         iconowners  STRUCTURE /psyng/conowner
                         iconpmit    STRUCTURE /psyng/conpmit
                         isyscon     STRUCTURE /psyng/sw_syscon
                         iswaudhdr   STRUCTURE /psyng/swaudhdr
                         iswaudc     STRUCTURE /psyng/swaudc2
                         atexts      STRUCTURE /psyng/texts
                         isysca      STRUCTURE /psyng/sw_sysca
                         icritcodes  STRUCTURE /psyng/critcodes
                         ttexts      STRUCTURE /psyng/texts
                         isystcd     STRUCTURE /psyng/sw_systcd
                         icriroles   STRUCTURE  /psyng/criroles
                         rtexts      STRUCTURE /psyng/texts
                         icriprofs   STRUCTURE /psyng/criprof
                         ptexts      STRUCTURE /psyng/texts
                         lt_corg     STRUCTURE /psyng/swsodorgo.

  DATA: itstc TYPE HASHED TABLE OF tstc WITH UNIQUE KEY tcode
        WITH HEADER LINE.

  DATA : iagr_define TYPE HASHED TABLE OF agr_define
         WITH UNIQUE KEY agr_name WITH HEADER LINE.

  DATA : iprof TYPE SORTED TABLE OF usr10
         WITH NON-UNIQUE KEY profn WITH HEADER LINE.


  DATA: BEGIN OF lt_busarea OCCURS 0,
          busarea LIKE /psyng/busarea-busarea,
        END OF lt_busarea.

  DATA: BEGIN OF lt_dd07l OCCURS 0,
          domvalue_l LIKE dd07l-domvalue_l,
        END OF lt_dd07l.

  DATA: BEGIN OF lt_usr02 OCCURS 0,
          bname LIKE usr02-bname,
        END OF lt_usr02.

  DATA: BEGIN OF lt_funid OCCURS 0,
          function    LIKE /psyng/function-function,
          description LIKE /psyng/function-description,
        END OF lt_funid.

  DATA: BEGIN OF lt_functtran OCCURS 0,
          functionid LIKE /psyng/function-function,
          tcode      LIKE tstc-tcode,
        END OF lt_functtran.

  DATA : lt_risk TYPE TABLE OF /psyng/sw_risk WITH HEADER LINE,
*Begin of Addition:HBHALLA(PN-17063)(01/06/26)
         lt_dup_fiori TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
         ls_func TYPE /psyng/functtran.
*End of Addition:HBHALLA(PN-17063)(01/06/26)

  DATA: BEGIN OF lt_tobj OCCURS 0,
          objct LIKE tobj-objct,
          fiel1 LIKE tobj-fiel1,
          fiel2 LIKE tobj-fiel2,
          fiel3 LIKE tobj-fiel3,
          fiel4 LIKE tobj-fiel4,
          fiel5 LIKE tobj-fiel5,
          fiel6 LIKE tobj-fiel6,
          fiel7 LIKE tobj-fiel7,
          fiel8 LIKE tobj-fiel8,
          fiel9 LIKE tobj-fiel9,
          fiel0 LIKE tobj-fiel0,
        END OF lt_tobj.

  DATA: BEGIN OF lt_mchdr OCCURS 0,
          contid LIKE /psyng/mchdr-contid,
        END OF lt_mchdr.

  DATA: BEGIN OF lt_conid OCCURS 0,
          conid       LIKE /psyng/conflict-conid,
          description LIKE /psyng/conflict-description,
        END OF lt_conid.

  DATA: BEGIN OF lt_swaudhdr OCCURS 0,
          swaudid     LIKE /psyng/swaudhdr-swaudid,
          description LIKE /psyng/swaudhdr-description,
          tcode       LIKE /psyng/swaudhdr-tcode,
        END OF lt_swaudhdr.

  DATA: BEGIN OF lt_ct OCCURS 0,
          tcode LIKE  /psyng/critcodes-tcode,
          vrsio LIKE  /psyng/critcodes-vrsio,
        END OF lt_ct.

  DATA: BEGIN OF lt_cr OCCURS 0,
          agr_name LIKE  /psyng/criroles-agr_name,
          vrsio    LIKE  /psyng/criroles-vrsio,
        END OF lt_cr.

  DATA: BEGIN OF lt_cp OCCURS 0,
          profile LIKE  /psyng/criprof-profile,
          vrsio   LIKE  /psyng/criroles-vrsio,
        END OF lt_cp.


  DATA: l_flg_no_dat,
        l_flg_del_dat,
        l_indx        LIKE sy-tabix,
        l_msg         TYPE string.

  RANGES: r_field FOR /psyng/swsodorgo-field,
          r_type  FOR /psyng/swsodorgo-type.

* Get master data for validations
  SELECT tcode FROM tstc INTO CORRESPONDING FIELDS OF TABLE itstc.

  SELECT agr_name FROM agr_define
                        INTO CORRESPONDING FIELDS OF TABLE iagr_define.

  SELECT profn FROM usr10
                       INTO CORRESPONDING FIELDS OF TABLE iprof.


  SELECT tcode vrsio FROM /psyng/critcodes INTO TABLE lt_ct
              WHERE vrsio = sodvrsio.

  SELECT agr_name vrsio FROM /psyng/criroles INTO TABLE lt_cr
              WHERE vrsio = sodvrsio.

  SELECT profile vrsio FROM /psyng/criprof INTO TABLE lt_cp
              WHERE vrsio = sodvrsio.


  SELECT bname FROM usr02 INTO TABLE lt_usr02.

  SELECT busarea FROM /psyng/busarea INTO TABLE lt_busarea.

  SELECT risk FROM /psyng/sw_risk INTO CORRESPONDING FIELDS OF
  TABLE lt_risk.

  SELECT function description FROM /psyng/function INTO TABLE lt_funid
         WHERE vrsio = sodvrsio.

  SELECT domvalue_l FROM dd07l INTO TABLE lt_dd07l
  WHERE domname = '/PSYNG/IMPORTANCE'
  AND  as4local = 'A'."#EC SAST_CI_GEN_CHECK

  SELECT objct fiel1 fiel2 fiel3 fiel4 fiel5 fiel6 fiel7 fiel8
         fiel9 fiel0
    FROM tobj
    INTO TABLE lt_tobj.

  SELECT contid FROM /psyng/mchdr INTO TABLE lt_mchdr.

  SELECT conid description FROM /psyng/conflict INTO TABLE lt_conid
         WHERE vrsio = sodvrsio.

  SELECT swaudid description tcode FROM /psyng/swaudhdr INTO TABLE
 lt_swaudhdr
               WHERE vrsio = sodvrsio.

  SELECT functionid tcode FROM /psyng/functtran INTO TABLE lt_functtran
WHERE vrsio = sodvrsio.

  SORT: lt_usr02    BY bname,
        lt_funid    BY function,
        lt_dd07l    BY domvalue_l,
        lt_tobj     BY objct,
        lt_mchdr    BY contid,
        lt_conid    BY conid,
        lt_swaudhdr BY swaudid,
        itstc       BY tcode,
        lt_risk     BY risk,
        lt_busarea  BY busarea,
        lt_ct       BY tcode vrsio,
        lt_cr       BY agr_name vrsio,
        lt_cp       BY profile vrsio,
        iagr_define BY agr_name,
        isysfun  BY function,
        isyscon  BY conid,
        isysca  BY swaudid,
        isystcd BY tcode,
        lt_functtran BY functionid tcode.

* Check all necessary records
  IF f_funh = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT ifunction.
      CLEAR: l_flg_del_dat.
      l_indx = sy-tabix.
      IF NOT ifunction-owner IS INITIAL .
      READ TABLE lt_usr02 WITH KEY bname = ifunction-owner BINARY SEARCH
                                                 TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
           fn_funh
           'E'
           'SOD Function ID :'(125)
           ifunction-function
           'Owner :'(120)
           ifunction-owner
           'Not Found'(121).
        ENDIF.
      ENDIF.
      IF NOT ifunction-busarea IS INITIAL.
        READ TABLE lt_busarea WITH KEY busarea = ifunction-busarea
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
            fn_funh
            'E'
            'SOD Function ID :'(125)
            ifunction-function
            ' Application Area :'(122)
            ifunction-busarea
            'Not Found'(121).
        ENDIF.
      ELSE.
        l_flg_no_dat = 'X'.
        CONCATENATE 'Not Found'(121) '- will still be inserted'(147)
        INTO l_msg SEPARATED BY space.
        PERFORM log  USING
        fn_funh
        'W'
        'SOD Function ID :'(125)
        ifunction-function
        ' Application Area :'(122)
        ifunction-busarea
        l_msg.
      ENDIF.
      IF l_flg_del_dat = 'X'.
        DELETE ifunction INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT ifunction[] IS INITIAL.

      PERFORM log  USING
        fn_funh
        'S'
        'Function Header'(119)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.
  ENDIF.
***  for Function details **********
  IF f_fund = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT ifuncttrans.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE lt_funid WITH KEY function = ifuncttrans-functionid
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        READ TABLE ifunction WITH KEY function = ifuncttrans-functionid
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
            fn_fund
            'E'
            'SOD Function ID :'(125)
            ifuncttrans-functionid
            ''
            ''
            'Not Found'(121).


        ENDIF.
      ENDIF.
      READ TABLE itstc WITH TABLE KEY tcode = ifuncttrans-tcode
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0 AND NOT ifuncttrans-tcode CP '/PSYNG/-*'.
        l_flg_no_dat = 'X'.
        CONCATENATE
        'Not Found'(121)
        '- will still be inserted'(147)
        INTO l_msg SEPARATED BY space.
        PERFORM log  USING
          fn_fund
          'W'
          'SOD Function ID :'(125)
          ifuncttrans-functionid
          'Tcode :'(126)
          ifuncttrans-tcode
          l_msg.

      ENDIF.
      IF l_flg_del_dat = 'X'.
        DELETE ifuncttrans INDEX l_indx.
      ENDIF.

*Begin of Addition:HBHALLA(PN-17063)(01/06/26)
IF ifuncttrans-type = 'F' AND ifuncttrans-fioriid IS NOT INITIAL.
 IF ifuncttrans-tcode+8 = ifuncttrans-fioriid.
 READ TABLE lt_dup_fiori WITH KEY
 functionid = ifuncttrans-functionid
 tcode = ifuncttrans-tcode
 vrsio = ifuncttrans-vrsio
 type = ifuncttrans-type
 fioriid = ifuncttrans-fioriid BINARY SEARCH.
  IF sy-subrc <> 0.
   LOOP AT ifuncttrans INTO ls_func
   WHERE functionid = ifuncttrans-functionid
   AND tcode <> ifuncttrans-tcode
   AND vrsio = ifuncttrans-vrsio
   AND type = ifuncttrans-type
   AND fioriid = ifuncttrans-fioriid.
      APPEND ls_func TO lt_dup_fiori.
   ENDLOOP.
   SORT lt_dup_fiori.
  ENDIF.
 ENDIF.
ENDIF.
*End of Addition:HBHALLA(PN-17063)(01/06/26)

    ENDLOOP.

*Begin of Addition:HBHALLA(PN-17063)(01/06/26)
SORT lt_dup_fiori.
DELETE ADJACENT DUPLICATES FROM lt_dup_fiori COMPARING ALL FIELDS.
  LOOP AT lt_dup_fiori.
    clear l_msg.
        CONCATENATE
        'Duplicate Fiori Entries for'
        lt_dup_fiori-fioriid
        '- will be deleted'
        INTO l_msg SEPARATED BY space.
        PERFORM log  USING
          fn_fund
          'W'
          'SOD Function ID :'(125)
          lt_dup_fiori-functionid
          'Tcode :'(126)
          lt_dup_fiori-tcode
          l_msg.
     DELETE TABLE ifuncttrans FROM lt_dup_fiori.
  ENDLOOP.
*End of Addition:HBHALLA(PN-17063)(01/06/26)

    IF l_flg_no_dat = ' '  AND NOT ifuncttrans[] IS INITIAL.

      PERFORM log  USING
        fn_fund
        'S'
        'Function details'(124)
        ''
        ''
        ''
        'No errors found in file'(123).
    ENDIF.
  ENDIF.
***  for Function texts  **********
  IF f_funt = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT ftexts.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE lt_funid WITH KEY function = ftexts-textname.
      IF sy-subrc <> 0.
        READ TABLE ifunction WITH KEY function = ftexts-textname.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
            fn_funt
            'E'
            'SOD Function ID :'(125)
            ftexts-textname
            'Function texts:'(127)
            ftexts-text
            'Not Found'(121).

        ENDIF.
      ENDIF.
      IF l_flg_del_dat = 'X'.
        DELETE ftexts INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT ftexts[] IS INITIAL.


      PERFORM log  USING
        fn_funt
        'S'
        'Function texts:'(127)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.
  ENDIF.
*************Object details ******************************
  SORT ifuncttrans BY functionid tcode.
  IF f_objd = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT ifaobj.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.

*-- Check for Tcode function relation
      READ TABLE lt_functtran WITH KEY functionid = ifaobj-funid
            tcode = ifaobj-tcode BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        READ TABLE ifuncttrans WITH KEY functionid = ifaobj-funid
        tcode = ifaobj-tcode BINARY SEARCH TRANSPORTING NO FIELDS..
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
            fn_objd
            'E'
            'Function ID :'(125)
            ifaobj-funid
            ifaobj-tcode
            ''
            'Tcode is not linked to the function'(205).
        ENDIF.
      ENDIF.
*-- End checking

      READ TABLE lt_funid WITH KEY function = ifaobj-funid
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        READ TABLE ifunction WITH KEY function = ifaobj-funid
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
            fn_objd
            'E'
            'Function ID :'(125)
            ifaobj-funid
            ''
            ''
            'Not Found'(121).
        ENDIF.
      ENDIF.
      READ TABLE itstc WITH TABLE KEY tcode = ifaobj-tcode
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0 AND NOT ifaobj-tcode CP '/PSYNG/-*'.
        l_flg_no_dat = 'X'.
        CONCATENATE 'Not Found'(121) '- will still be inserted'(147)
        INTO l_msg SEPARATED BY space.
        PERFORM log  USING
          fn_objd
          'W'
          'Function ID :'(125)
          ifaobj-funid
          ' Tcode :'(126)
          ifaobj-tcode
          l_msg.

      ENDIF.
      READ TABLE lt_tobj WITH KEY objct = ifaobj-object
                 BINARY SEARCH .  "need to have all fields
      IF sy-subrc <> 0.
*Dhorions 2011/10/17 ->Allow unexisting objects
        l_flg_del_dat = ' '.
        l_flg_no_dat  = 'X'.
        CONCATENATE 'Not Found'(121) '- will still be inserted'(147)
        INTO l_msg SEPARATED BY space.
        PERFORM log  USING
          fn_objd
          'W'
          'Function ID :'(125)
          ifaobj-funid
          ' Object :'(129)
          ifaobj-object
          l_msg.

      ELSE.
        CASE ifaobj-field.
          WHEN lt_tobj-fiel1 OR lt_tobj-fiel2 OR lt_tobj-fiel3
            OR lt_tobj-fiel4 OR lt_tobj-fiel5 OR lt_tobj-fiel6
            OR lt_tobj-fiel7 OR lt_tobj-fiel8 OR lt_tobj-fiel9
            OR lt_tobj-fiel0.

          WHEN OTHERS.
            l_flg_del_dat = 'X'.
            l_flg_no_dat = 'X'.
            PERFORM log  USING
              fn_objd
              'W'
              'Function ID :'(125)
              ifaobj-funid
              'Field :'(130)
              ifaobj-field
              'Not Found'(121).

        ENDCASE.

      ENDIF.
      IF NOT ( ifaobj-obj_or  = ' ' OR ifaobj-obj_or  = 'OR' ).
        l_flg_del_dat = 'X'.
        l_flg_no_dat = 'X'.
        PERFORM log  USING
          fn_objd
          'E'
          'Function ID :'(125)
          ifaobj-funid
          'OBJ_OR:'(131)
          ifaobj-obj_or
          'Not Found'(121).

      ENDIF.
*--Don't allow 000 or blanks in valueset,
* those are not displayed in maintenance screen
      IF ifaobj-valueset = '000' OR ifaobj-valueset = ''.
        l_flg_del_dat = 'X'.
        l_flg_no_dat = 'X'.
        PERFORM log  USING
          fn_objd
          'E'
          'Function ID :'(125)
          ifaobj-funid
          'VALUESET:'(162)
          ifaobj-valueset
          'Cannot be blank or 000'(163).
      ENDIF.

*-- Change activity less then 10 to double digit
      IF ifaobj-field = 'ACTVT'.
        CONDENSE : ifaobj-val_from, ifaobj-val_to.
        IF ifaobj-val_from CO '0123456789 '.
          IF ifaobj-val_from BETWEEN 0 AND 9
          AND ifaobj-val_from(1) <> 0 .
            CONCATENATE '0' ifaobj-val_from INTO ifaobj-val_from.
          ENDIF.
        ENDIF.
        IF ifaobj-val_to CO '0123456789 '.
          IF ifaobj-val_to BETWEEN 0 AND 9
          AND ifaobj-val_to(1) <> 0 .
            CONCATENATE '0' ifaobj-val_to INTO ifaobj-val_to.
          ENDIF.
        ENDIF.
        MODIFY ifaobj TRANSPORTING val_from val_to.
      ENDIF.


      IF l_flg_del_dat = 'X'.
        DELETE ifaobj INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' '  AND NOT ifaobj[] IS INITIAL.
      PERFORM log  USING
        fn_objd
        'S'
        'Object details'(128)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.
  ENDIF.

**********  Function system filter

  IF f_fnfltr = 'X'.
    IF NOT isysfun[] IS INITIAL.
      PERFORM log  USING
        fn_fflt
        'S'
        'Function system filters'(f25)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.
  ENDIF.
* Custom Org Level Det.
  IF f_corg = 'X'.
    r_type-sign = 'I'.
    r_type-option = 'EQ'.
    r_type-low    = 'FIELD'.
    APPEND r_type.
    CLEAR r_type.

    r_type-sign = 'I'.
    r_type-option = 'EQ'.
    r_type-low    = 'REL'.
    APPEND r_type.
    CLEAR r_type.

    r_field-sign = 'I'.
    r_field-option = 'EQ'.
    r_field-low = 'BUKRS'.
    APPEND r_field.

    r_field-sign = 'I'.
    r_field-option = 'EQ'.
    r_field-low = 'EKORG'.
    APPEND r_field.

    r_field-sign = 'I'.
    r_field-option = 'EQ'.
    r_field-low = 'WERKS'.
    APPEND r_field.

    r_field-sign = 'I'.
    r_field-option = 'EQ'.
    r_field-low = 'IWERK'.
    APPEND r_field.

    r_field-sign = 'I'.
    r_field-option = 'EQ'.
    r_field-low = 'GSBER'.
    APPEND r_field.

    r_field-sign = 'I'.
    r_field-option = 'EQ'.
    r_field-low = 'SPART'.
    APPEND r_field.

    r_field-sign = 'I'.
    r_field-option = 'EQ'.
    r_field-low = 'VTWEG'.
    APPEND r_field.

    r_field-sign = 'I'.
    r_field-option = 'EQ'.
    r_field-low = 'KKBER'.
    APPEND r_field.

    r_field-sign = 'I'.
    r_field-option = 'EQ'.
    r_field-low = 'KOKRS'.
    APPEND r_field.

    r_field-sign = 'I'.
    r_field-option = 'EQ'.
    r_field-low = 'VKORG'.
    APPEND r_field.

    r_field-sign = 'I'.
    r_field-option = 'EQ'.
    r_field-low = 'VSTEL'.
    APPEND r_field.


    LOOP AT lt_corg.
      l_indx = sy-tabix.
      READ TABLE lt_conid WITH KEY conid = lt_corg-conid.
      IF sy-subrc <> 0.
        READ TABLE iconflict WITH KEY conid = lt_corg-conid.
        IF sy-subrc <> 0.

          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.

          PERFORM log USING
            fn_corg
            'E'
            'Conflict ID :'(137)
            lt_corg-conid
            ''
                           ''
            'Not Found'(121).
        ENDIF.
      ENDIF.
      IF NOT lt_corg-type IN r_type.
        l_flg_del_dat = 'X'.
        l_flg_no_dat = 'X'.
        PERFORM log USING
          fn_corg
          'E'
          'Org Level Field:'(208)
          lt_corg-type
          '' ''
          'Not Found'(121).
      ELSEIF NOT lt_corg-field IN r_field.
        l_flg_del_dat = 'X'.
        l_flg_no_dat = 'X'.
        PERFORM log USING
          fn_corg
          'E'
          'Org Level Type:'(209)
          lt_corg-field
          '' ''
          'Not Found'(121).
      ENDIF.
      IF l_flg_del_dat = 'X'.
        DELETE lt_corg INDEX l_indx.
      ENDIF.
    ENDLOOP.
  ENDIF.
***********Conflict header ***************************
  IF f_conh = 'X'.
    CLEAR: l_flg_no_dat.


    LOOP AT iconflict.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      IF NOT iconflict-owner IS INITIAL .
      READ TABLE lt_usr02 WITH KEY bname = iconflict-owner BINARY SEARCH
                                                 TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
            fn_conh
            'E'
            'Conflict ID :'(137)
            iconflict-conid
            'Owner :'(120)
            iconflict-owner
            'Not Found'(121).

        ENDIF.
      ENDIF.
      DATA l_sense TYPE dd07l.

      IF NOT iconflict-imp IS INITIAL.
    READ TABLE lt_dd07l INTO l_sense WITH KEY domvalue_l = iconflict-imp
                                                          BINARY SEARCH.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          CONCATENATE 'Not Found'(121) ''
          INTO l_msg SEPARATED BY space.
          PERFORM log  USING
            fn_conh
            'E'
            'Conflict ID :'(137)
            iconflict-conid
            'Sensitivity level :'(132)
            iconflict-imp
            l_msg.
        ENDIF.
      ELSE.
        l_flg_no_dat = 'X'.
        CONCATENATE 'Not Found'(121) '- will still be inserted'(147)
        INTO l_msg SEPARATED BY space.
        PERFORM log  USING
          fn_conh
          'W'
          'Conflict ID :'(137)
          iconflict-conid
          'Sensitivity level :'(132)
          iconflict-imp
          l_msg.

      ENDIF.

      DATA l_busarea LIKE lt_busarea.
      IF NOT iconflict-busarea IS INITIAL.
        READ TABLE lt_busarea WITH KEY busarea = iconflict-busarea
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          CONCATENATE 'Not Found'(121) ''
          INTO l_msg SEPARATED BY space.
          PERFORM log  USING
            fn_conh
            'E'
            'Conflict ID :'(137)
            iconflict-conid
            ' Application Area :'(122)
            iconflict-busarea
            l_msg.
        ENDIF.
      ELSE.
        l_flg_no_dat = 'X'.
        CONCATENATE 'Not Found'(121) '- will still be inserted'(147)
        INTO l_msg SEPARATED BY space.
        PERFORM log  USING
          fn_conh
          'W'
          'Conflict ID :'(137)
          iconflict-conid
          ' Application Area :'(122)
          iconflict-busarea
          l_msg.
      ENDIF.
      IF NOT iconflict-risk IS INITIAL.
        READ TABLE lt_risk WITH KEY risk = iconflict-risk
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_no_dat = 'X'.
          CONCATENATE 'Not Found'(121) '- will still be inserted'(147)
          INTO l_msg SEPARATED BY space.
          PERFORM log  USING
            fn_conh
            'W'
            'Conflict ID :'(137)
            iconflict-conid
            ' Risk Scenario :'(160)
            iconflict-risk
            l_msg.

        ENDIF.
      ENDIF.


      IF NOT iconflict-contid IS INITIAL.
        READ TABLE lt_mchdr WITH KEY contid = iconflict-contid
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
            fn_conh
            'E'
            'Conflict ID :'(137)
            iconflict-conid
            'Mitigating Control ID :'(133)
            iconflict-contid
            'Not Found'(121).



        ENDIF.
      ENDIF.

      IF NOT ( iconflict-inactive = ' ' OR iconflict-inactive = 'X' ).
        l_flg_del_dat = 'X'.
        l_flg_no_dat = 'X'.
        PERFORM log  USING
          fn_conh
          'E'
          'Conflict ID :'(137)
          iconflict-conid
          'Inactive:'(134)
          iconflict-inactive
          'Not Found'(121).

      ENDIF.
      IF l_flg_del_dat = 'X'.
        DELETE iconflict INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' '  AND NOT iconflict[] IS INITIAL.

      PERFORM log  USING
        fn_conh
        'S'
        'Conflict header'(135)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.
  ENDIF.
********************  Conflict details **************************
  IF f_cond = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT iconfdet.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE lt_conid WITH KEY conid = iconfdet-conid
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        READ TABLE iconflict WITH KEY conid = iconfdet-conid
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
            fn_cond
            'E'
            'Conflict ID :'(137)
            iconfdet-conid
            ''
            ''
            'Not Found'(121).

        ENDIF.
      ENDIF.
      READ TABLE lt_funid WITH KEY function = iconfdet-functionid
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        READ TABLE ifunction WITH KEY function = iconfdet-functionid
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
            fn_cond
            'E'
            'Conflict ID :'(137)
            iconfdet-conid
            'Function ID :'(125)
            iconfdet-functionid
            'Not Found'(121).

        ENDIF.
      ENDIF.
      IF l_flg_del_dat = 'X'.
        DELETE iconfdet INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT iconfdet[] IS INITIAL.
      PERFORM log  USING
        fn_cond
        'S'
        'Conflict details'(136)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.
  ENDIF.
********************  Conflict owners **************************
  IF f_cono = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT iconowners.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE lt_conid WITH KEY conid = iconowners-conid
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        READ TABLE iconflict WITH KEY conid = iconowners-conid
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
            fn_cono
            'E'
            'Conflict ID :'(137)
            iconowners-conid
            ''
            ''
            'Not Found'(121).


        ENDIF.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT iconowners[] IS INITIAL.
      PERFORM log  USING
        fn_cono
        'S'
        'Conflict owners'(159)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.

  ENDIF.


********************  Conflict mitigations **************************
  IF f_conm = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT iconpmit.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE lt_conid WITH KEY conid = iconpmit-conid
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        READ TABLE iconflict WITH KEY conid = iconpmit-conid
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
            fn_cono
            'E'
            'Conflict ID :'(137)
            iconpmit-conid
            ''
            ''
            'Not Found'(121).


        ENDIF.
      ENDIF.
      IF sy-subrc = 0.
*-- Check for Mitigation ID
        CLEAR: l_flg_del_dat.
        READ TABLE lt_mchdr WITH KEY contid = iconpmit-contid
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
            fn_cono
            'E'
            'Mitigation Control ID :'(133)
            iconpmit-contid
            ''
            ''
            'Not Found'(121).
        ENDIF.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT iconpmit[] IS INITIAL.
      PERFORM log  USING
        fn_conm
        'S'
        'Conflict Mitigations'(194)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.

  ENDIF.


***************Conflict texts *****************************
  IF f_cont = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT ctexts.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE lt_conid WITH KEY conid = ctexts-textname.
      IF sy-subrc <> 0.
        READ TABLE iconflict WITH KEY conid = ctexts-textname.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
            fn_cont
            'E'
            'Conflict ID :'(137)
            ctexts-textname
            'Conflict Text :'(138)
            ctexts-text
            'Not Found'(121).

        ENDIF.
      ENDIF.
      IF l_flg_del_dat = 'X'.
        DELETE ctexts INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT ctexts[] IS INITIAL.
      PERFORM log  USING
        fn_cont
        'S'
        'Conflict texts '(138)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.
  ENDIF.

***  for conflict system filter  **********
  IF f_conflt = 'X'.

    IF NOT isyscon[] IS INITIAL.

      PERFORM log  USING
        fn_cnflt
        'S'
        'Conflict system filters'(f26)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.
  ENDIF.

******************* Critical auth header *************************
  IF f_cah = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT iswaudhdr.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.

      IF iswaudhdr-tcode <> '*'.
        READ TABLE itstc WITH TABLE  KEY tcode = iswaudhdr-tcode
                   TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_no_dat = 'X'.
          CONCATENATE 'Not Found'(121) '- will still be inserted'(147)
          INTO l_msg SEPARATED BY space.
          PERFORM log  USING
            fn_cah
            'W'
            'Critical Auth Object ID:'(141)
            iswaudhdr-swaudid
            ' Tcode :'(126)
            iswaudhdr-tcode
            l_msg.
        ENDIF.
      ENDIF.

      IF l_flg_del_dat = 'X'.
        DELETE iswaudhdr INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT iswaudhdr[] IS INITIAL.
      PERFORM log  USING
        fn_cah
        'S'
        'Critical auth header '(139)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.
  ENDIF.
******************** Critical auth detail  ********************

  IF f_cad = 'X'.

    CLEAR: l_flg_no_dat.
    LOOP AT iswaudc.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE lt_swaudhdr WITH KEY swaudid = iswaudc-swaudid
                                      tcode   = iswaudc-tcode
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        READ TABLE iswaudhdr WITH KEY
                  swaudid = iswaudc-swaudid
                  tcode   = iswaudc-tcode
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
            fn_cad
            'W'
            'Critical Auth Object ID:'(141)
            iswaudc-swaudid
            ' Tcode :'(126)
            iswaudc-tcode
            'Not Found'(121).

        ENDIF.
      ENDIF.
      READ TABLE itstc WITH TABLE KEY tcode = iswaudc-tcode
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0 AND iswaudc-tcode <> '*'. "dhorions 20091105
        "allow * tcode
        l_flg_del_dat = 'X'.
        l_flg_no_dat = 'X'.
        PERFORM log  USING
          fn_cad
          'W'
          'Critical Auth Object ID:'(141)
          iswaudc-swaudid
          ' Tcode :'(126)
          iswaudc-tcode
          'Not Found'(121).

      ENDIF.
      READ TABLE lt_tobj WITH KEY objct = iswaudc-object
                 BINARY SEARCH .  "need to have all fields
      IF sy-subrc <> 0.
*        flg_del_dat = 'X'.
        l_flg_del_dat = ' '.
        l_flg_no_dat = 'X'.
        CONCATENATE 'Not Found'(121) '- will still be inserted'(147)
           INTO l_msg SEPARATED BY space.
        PERFORM log  USING
          fn_cad
          'W'
          'Critical Auth Object ID:'(141)
          iswaudc-swaudid
          'Object :'(129)
          iswaudc-object
          l_msg.


      ELSE.
        CASE iswaudc-field.
          WHEN lt_tobj-fiel1 OR lt_tobj-fiel2 OR lt_tobj-fiel3
            OR lt_tobj-fiel4 OR lt_tobj-fiel5 OR lt_tobj-fiel6
            OR lt_tobj-fiel7 OR lt_tobj-fiel8 OR lt_tobj-fiel9
            OR lt_tobj-fiel0.

          WHEN OTHERS.
            l_flg_del_dat = 'X'.
            l_flg_no_dat = 'X'.
            PERFORM log  USING
              fn_cad
              'W'
              'Critical Auth Object ID:'(141)
              iswaudc-swaudid
              ' Field :'(130)
              iswaudc-field
              'Not Found'(121).

        ENDCASE.
      ENDIF.

      IF l_flg_del_dat = 'X'.
        DELETE iswaudc INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT iswaudc[] IS INITIAL.
      PERFORM log  USING
        fn_cad
        'S'
        'Critical Auth Detail '(140)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.
  ENDIF.

***************** Critical auth texts ***************
  IF f_cat = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT atexts.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE lt_swaudhdr WITH KEY swaudid = atexts-textname.
      IF sy-subrc <> 0.
        READ TABLE iswaudhdr WITH KEY swaudid = atexts-textname.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
            fn_cat
            'E'
            'Critical Auth Object ID:'(141)
            atexts-textname
            'Critical auth texts :'(142)
            atexts-text
            'Not Found'(121).

        ENDIF.
      ENDIF.
      IF l_flg_del_dat = 'X'.
        DELETE atexts INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT atexts[] IS INITIAL.
      PERFORM log  USING
        fn_cat
        'S'
        'Critical auth Text '(142)
        ''
        ''
        ''
        'No errors found in file'(123).
    ENDIF.
  ENDIF.

***  for Critical auth system filter  **********
  IF f_cafltr = 'X'.
    CLEAR: l_flg_no_dat.


    IF NOT isysca[] IS INITIAL.
      PERFORM log  USING
        fn_catfl
        'S'
        'Critical Auth. system filters'(f32)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.
  ENDIF.

********************** Critical transaction *****************

  IF f_ct = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT icritcodes.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE lt_ct WITH KEY tcode = icritcodes-tcode
           TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.



        READ TABLE itstc WITH TABLE KEY tcode = icritcodes-tcode
                  TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
*        flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          CONCATENATE
              'Not Found'(121)
              '- will still be inserted'(147)
                    INTO l_msg SEPARATED BY space.
          PERFORM log  USING
              fn_ct
              'W'
              'Critical Transaction'(143)
              ' '
              'Tcode :'(126)
              icritcodes-tcode
              l_msg.
        ENDIF.
      ENDIF.


      IF NOT icritcodes-imp IS INITIAL.
        READ TABLE lt_dd07l WITH KEY domvalue_l = icritcodes-imp
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          PERFORM log  USING
            fn_ct
            'E'
            text-143
            icritcodes-tcode
            'Sensitivity level :'(132)
            icritcodes-imp
            'Not Found'(121).

        ENDIF.
      ENDIF.

      IF l_flg_del_dat = 'X'.
        DELETE icritcodes INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT icritcodes[] IS INITIAL.
      PERFORM log  USING
        fn_ct
        'S'
        'Critical Transaction'(143)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.

  ENDIF.

********************** Critical transaction Texts *****************

  IF f_ctxt = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT ttexts.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE icritcodes WITH KEY tcode = ttexts-textname.
      IF sy-subrc <> 0.
        l_flg_del_dat = 'X'.
        l_flg_no_dat = 'X'.
        PERFORM log  USING
          fn_ctxt
          'E'
          'Critical Transaction:'(143)
          ttexts-textname
          'Critical transaction texts:'(184)
          ttexts-text
          'Not Found'(121).

      ENDIF.
      IF l_flg_del_dat = 'X'.
        DELETE ttexts INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT ttexts[] IS INITIAL.
      PERFORM log  USING
        fn_ctxt
        'S'
        'Critical transaction texts:'(184)
        ''
        ''
        ''
        'No errors found in file'(123).
    ENDIF.
  ENDIF.

***  for Critical transaction system filter  **********
  IF  f_ctfltr  = 'X'.

    IF NOT isystcd[] IS INITIAL.
      PERFORM log  USING
        fn_ctflt
        'S'
        'CT system filters'(f27)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.
  ENDIF.



********************** Critical Roles *****************
  IF f_cr = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT icriroles.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE lt_cr WITH KEY agr_name = icriroles-agr_name
           TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.


        READ TABLE iagr_define WITH TABLE KEY
                                      agr_name = icriroles-agr_name
                  TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
*        flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          CONCATENATE
              'Not Found'(121)
              '- will still be inserted'(147)
                    INTO l_msg SEPARATED BY space.
          PERFORM log  USING
              fn_cr
              'W'
              'Critical Role'(180)
              ' '
              'Role :'(182)
              icriroles-agr_name
              l_msg.
        ENDIF.
      ENDIF.

      IF l_flg_del_dat = 'X'.
        DELETE icriroles INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT icriroles[] IS INITIAL.
      PERFORM log  USING
        fn_cr
        'S'
        'Critical Role'(180)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.

  ENDIF.


*********************** Critical role text *****************

  IF f_crtxt = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT rtexts.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE icriroles WITH KEY agr_name = rtexts-textname.
      IF sy-subrc <> 0.
        l_flg_del_dat = 'X'.
        l_flg_no_dat = 'X'.
        PERFORM log  USING
          fn_crtxt
          'E'
          'Critical Role:'(185)
          rtexts-textname
          'Critical role texts:'(186)
          rtexts-text
          'Not Found'(121).

      ENDIF.

      IF l_flg_del_dat = 'X'.
        DELETE rtexts INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT rtexts[] IS INITIAL.
      PERFORM log  USING
        fn_crtxt
        'S'
        'Critical role texts:'(186)
        ''
        ''
        ''
        'No errors found in file'(123).
    ENDIF.
  ENDIF.




*  ********************** Critical Profiles *****************
  IF f_cp = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT icriprofs.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE lt_cp WITH KEY profile = icriprofs-profile
           TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.


        READ TABLE iprof WITH TABLE KEY profn = icriprofs-profile
                  TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
*        flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          CONCATENATE
              'Not Found'(121)
              '- will still be inserted'(147)
                    INTO l_msg SEPARATED BY space.
          PERFORM log  USING
              fn_cp
              'W'
              'Critical Profile'(181)
              ' '
              'Profile :'(183)
              icriprofs-profile
              l_msg.
        ENDIF.


        IF l_flg_del_dat = 'X'.
          DELETE icriprofs INDEX l_indx.
        ENDIF.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT icriprofs[] IS INITIAL.
      PERFORM log  USING
        fn_cp
        'S'
        'Critical Profile'(181)
        ''
        ''
        ''
        'No errors found in file'(123).

    ENDIF.

  ENDIF.

*  *********************** Critical profile text *****************

  IF f_cptxt = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT ptexts.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE icriprofs WITH KEY profile = ptexts-textname.
      IF sy-subrc <> 0.
        l_flg_del_dat = 'X'.
        l_flg_no_dat = 'X'.
        PERFORM log  USING
          fn_cptxt
          'E'
          'Critical Profile:'(187)
          ptexts-textname
          'Critical profile texts:'(188)
          ptexts-text
          'Not Found'(121).

      ENDIF.

      IF l_flg_del_dat = 'X'.
        DELETE ptexts INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT ptexts[] IS INITIAL.
      PERFORM log  USING
        fn_cptxt
        'S'
        'Critical profile texts:'(188)
        ''
        ''
        ''
        'No errors found in file'(123).
    ENDIF.
  ENDIF.


ENDFORM.                    " validation

*---------------------------------------------------------------------*
*       FORM ALV_HEADER                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: header         TYPE slis_t_listheader,
        wa             TYPE slis_listheader,
        l_count        TYPE i,
        c_count        TYPE string,
        alv_grid_titl2 TYPE lvc_title.
  .
*TITLE AREA

  wa-typ = 'H'.
  IF dnldtabs EQ 'X'.
    wa-info = 'Downloading Conflict Repository'(h01).
  ELSEIF emtytabs EQ 'X'.
    wa-info = 'Clear Conflict Repository'(h02).
  ELSE.
    wa-info = 'Uploading Conflict Repository'(h03).
  ENDIF.
  APPEND wa TO header.
*SOD Version.
  wa-typ = 'S'.
  wa-key = 'Sod Version'(h04).
  wa-info = sodvrsio.
  APPEND wa TO header.
*Errors
  CLEAR l_count.
  LOOP AT gt_log WHERE type = '@0A@'.
    ADD 1 TO l_count.
  ENDLOOP.
  c_count = l_count.
  wa-typ = 'S'.
  wa-key = 'Errors'(h05).
  wa-info = c_count.
  APPEND wa TO header.
*Warnings
  CLEAR l_count.
  LOOP AT gt_log WHERE type = '@09@'.
    ADD 1 TO l_count.
  ENDLOOP.
  c_count = l_count.
  wa-typ = 'S'.
  wa-key = 'Warnings'(h06).
  wa-info = c_count.
  APPEND wa TO header.


  IF testrun = 'X'.
    wa-typ  = 'A'.
    wa-info = 'Test run'(h07).
    APPEND wa TO header.
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = header.
*            i_logo             = 'Z_3SW_LOGO_JPG'.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  check_lock
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_2186   text
*      -->P_SODVRSIO  text
*      <--P_LF_LOCKED  text
*----------------------------------------------------------------------*
FORM check_lock USING    i_object
                         i_sodvrsio
                CHANGING ef_locked
                         e_locks.
  DATA : l_gname      LIKE seqg3-gname,
         lt_seqg3     TYPE TABLE OF seqg3 WITH HEADER LINE,
         ls_function  TYPE /psyng/function,
         ls_conflict  TYPE /psyng/conflict,
         ls_swaud     TYPE /psyng/swaudhdr,
         ls_critcodes TYPE /psyng/critcodes,
         ls_criroles  TYPE /psyng/criroles,
         ls_criprof   TYPE /psyng/criprof,
         ls_texts     TYPE /psyng/texts,
         ls_syscon    TYPE /psyng/sw_syscon,
         ls_sysfun    TYPE /psyng/sw_sysfun,
         ls_sysca     TYPE /psyng/sw_sysca,
         ls_systcd    TYPE /psyng/sw_systcd,
         l_locks      TYPE i.
*ENQUEUE_REPORT
  CASE i_object.
    WHEN 'FUNCTION'.
      l_gname = '/PSYNG/FUNCTION'.
    WHEN 'CONFLICT'.
      l_gname = '/PSYNG/CONFLICT'.
    WHEN 'SWAUD'.
      l_gname = '/PSYNG/SWAUDHDR'.

    WHEN 'CRITCODES'.
      l_gname = '/PSYNG/CRITCODES'.
    WHEN 'CRICFLTR'.
      l_gname = '/PSYNG/SW_SYSTCD'.
    WHEN 'CRIROLES'.
      l_gname = '/PSYNG/CRIROLES'.

    WHEN 'CRIPROF'.

      l_gname = '/PSYNG/CRIPROF'.

    WHEN 'CRITTEXT'.

      l_gname = '/PSYNG/TEXTS'.

    WHEN 'CRIRTEXT'.

      l_gname = '/PSYNG/TEXTS'.

    WHEN 'CRIPTEXT'.

      l_gname = '/PSYNG/TEXTS'.

    WHEN OTHERS.
  ENDCASE.
  CALL FUNCTION 'ENQUEUE_REPORT'
    EXPORTING
*     GCLIENT               = SY-MANDT
      gname                 = l_gname
*     GTARG                 = ' '
      guname                = '*'
*   IMPORTING
*     NUMBER                =
*     SUBRC                 =
    TABLES
      enq                   = lt_seqg3
    EXCEPTIONS
      communication_failure = 1
      system_failure        = 2
      OTHERS                = 3.
  IF sy-subrc = 0.
    IF NOT lt_seqg3[] IS INITIAL.
      LOOP AT lt_seqg3.
        CASE i_object.
          WHEN 'FUNCTION'.
            ls_function = lt_seqg3-gtarg.
            IF ls_function-vrsio = i_sodvrsio.
              ADD 1 TO l_locks.
            ENDIF.
          WHEN 'CONFLICT'.
            ls_conflict = lt_seqg3-gtarg.
            IF ls_conflict-vrsio = i_sodvrsio.
              ADD 1 TO l_locks.
            ENDIF.
          WHEN 'SWAUD'.
            ls_swaud = lt_seqg3-gtarg.
            IF ls_swaud-vrsio = i_sodvrsio.
              ADD 1 TO l_locks.
            ENDIF.
          WHEN 'CRITCODES'.
            ls_critcodes = lt_seqg3-gtarg.
            IF ls_critcodes-vrsio = i_sodvrsio.
              ADD 1 TO l_locks.
            ENDIF.
          WHEN 'CRIROLES'.
            ls_criroles = lt_seqg3-gtarg.
            IF ls_criroles-vrsio = i_sodvrsio.
              ADD 1 TO l_locks.
            ENDIF.

          WHEN 'CRIPROF'.
            ls_criprof = lt_seqg3-gtarg.
            IF ls_criprof-vrsio = i_sodvrsio.
              ADD 1 TO l_locks.
            ENDIF.

          WHEN 'CRITTEXT'.
            ls_texts = lt_seqg3-gtarg.
            IF ls_texts-vrsio = i_sodvrsio.
              ADD 1 TO l_locks.
            ENDIF.


          WHEN 'CRIRTEXT'.

            ls_texts = lt_seqg3-gtarg.
            IF ls_texts-vrsio = i_sodvrsio.
              ADD 1 TO l_locks.
            ENDIF.


          WHEN 'CRIPTEXT'.

            ls_texts = lt_seqg3-gtarg.
            IF ls_texts-vrsio = i_sodvrsio.
              ADD 1 TO l_locks.
            ENDIF.

          WHEN 'FNFLTR'.

            ls_sysfun = lt_seqg3-gtarg.
            IF ls_sysfun-vrsio = i_sodvrsio.
              ADD 1 TO l_locks.
            ENDIF.

          WHEN 'CONFLTR'.

            ls_syscon = lt_seqg3-gtarg.
            IF ls_syscon-vrsio = i_sodvrsio.
              ADD 1 TO l_locks.
            ENDIF.

          WHEN 'CRITFLTR'.

            ls_systcd = lt_seqg3-gtarg.
            IF ls_systcd-vrsio = i_sodvrsio.
              ADD 1 TO l_locks.
            ENDIF.

          WHEN 'CAFLTR'.

            ls_sysca = lt_seqg3-gtarg.
            IF ls_sysca-vrsio = i_sodvrsio.
              ADD 1 TO l_locks.
            ENDIF.
          WHEN OTHERS.
        ENDCASE.
      ENDLOOP.

    ENDIF.
  ENDIF.
  e_locks = l_locks.
  IF l_locks > 0.
    ef_locked = 'X'.
  ELSE.
    CLEAR  ef_locked .
  ENDIF.
ENDFORM.                    " check_lock
*&---------------------------------------------------------------------*
*&      Form  delete_all_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM delete_all_data.
  DATA : lf_locked TYPE flag,
         l_locks   TYPE i.


  PERFORM check_lock USING 'SWAUD' sodvrsio
  CHANGING lf_locked l_locks.
  PERFORM delete_data USING 'SWAUD' lf_locked.

  PERFORM check_lock USING 'CONFLICT' sodvrsio
  CHANGING lf_locked l_locks.
  PERFORM delete_data USING 'CONFLICT' lf_locked.

  PERFORM check_lock USING 'FUNCTION' sodvrsio
  CHANGING lf_locked l_locks.
  PERFORM delete_data USING 'FUNCTION' lf_locked.

  PERFORM check_lock USING 'CRITCODES' sodvrsio
  CHANGING lf_locked l_locks.
  PERFORM delete_data USING 'CRITCODES' lf_locked.

  PERFORM check_lock USING 'CRITTEXT' sodvrsio
  CHANGING lf_locked l_locks.
  PERFORM delete_data USING 'CRITTEXT' lf_locked.


  PERFORM check_lock USING 'CRIROLES' sodvrsio
  CHANGING lf_locked l_locks.
  PERFORM delete_data USING 'CRIROLES' lf_locked.

  PERFORM check_lock USING 'CRIRTEXT' sodvrsio
  CHANGING lf_locked l_locks.
  PERFORM delete_data USING 'CRIRTEXT' lf_locked.


  PERFORM check_lock USING 'CRIPROF' sodvrsio
  CHANGING lf_locked l_locks.
  PERFORM delete_data USING 'CRIPROF' lf_locked.

  PERFORM check_lock USING 'CRIPTEXT' sodvrsio
  CHANGING lf_locked l_locks.
  PERFORM delete_data USING 'CRIPTEXT' lf_locked.

  PERFORM check_lock USING 'CRITFLTR' sodvrsio
   CHANGING lf_locked l_locks.
  PERFORM delete_data USING 'CRITFLTR' lf_locked.

ENDFORM.                    " delete_all_data
