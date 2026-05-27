*&---------------------------------------------------------------------*
*& Report  /psyng/sw_110                                         *
*&                                                                     *
*&---------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SODREPORT
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

REPORT  /psyng/sw_110 MESSAGE-ID /psyng/sw.
TABLES : rfcdes.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /PSYNG/BASIS_EXELOG.

DATA : g_ucomm    LIKE sy-ucomm,
       g_repid    LIKE sy-repid,
       g_scanpath TYPE rlgrap-filename,
       g_userpath TYPE rlgrap-filename,
       g_capath   TYPE rlgrap-filename,
       g_cownpath TYPE rlgrap-filename,
       dsp_mng_lock    VALUE 'N',
       dsp_slf_lock    VALUE 'Y',
       gf_mr_installed TYPE flag.
*--Global Tables
DATA : gt_sod_scan   TYPE TABLE OF /psyng/sw_mr_ext_sod_scan
       WITH HEADER LINE,
       gt_ca_scan    TYPE TABLE OF /psyng/sw_mr_ext_ca_scan
       WITH HEADER LINE,
       gt_uinfo      TYPE TABLE OF /psyng/sw_mr_ext_uinfo
       WITH HEADER LINE,
       gt_conowners  TYPE TABLE OF /psyng/sw_mr_ext_conowner
       WITH HEADER LINE,
       g_current_user TYPE sy-uname. "C0700
*--Constants
CONSTANTS :
  g_const_exc_tabname     TYPE tabname VALUE '/PSYNG/SW_MR_EXC',
  g_const_exa_tabname     TYPE tabname VALUE '/PSYNG/SW_MR_EXA',
  g_const_exu_tabname     TYPE tabname VALUE '/PSYNG/SW_MR_EXU',
  g_const_exo_tabname     TYPE tabname VALUE '/PSYNG/SW_MR_EXO'.

*--Upload/Download Block
SELECTION-SCREEN: BEGIN OF BLOCK upd_o WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) upd_but USER-COMMAND upd_but.
SELECTION-SCREEN COMMENT 16(50) text-b01.
PARAMETERS :
  p_up   TYPE flag RADIOBUTTON GROUP ud DEFAULT 'X' MODIF ID upd
  USER-COMMAND dum,
  p_down TYPE flag RADIOBUTTON GROUP ud             MODIF ID upd.
SELECTION-SCREEN: END OF BLOCK upd_o.

*--File Path Block
SELECTION-SCREEN: BEGIN OF BLOCK pat_o WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) pat_but USER-COMMAND pat_but.
SELECTION-SCREEN COMMENT 16(50) text-b02.
PARAMETERS :  scanfil TYPE rlgrap-filename
              LOWER CASE DEFAULT g_scanpath MODIF ID pat.
PARAMETERS :  cafil TYPE rlgrap-filename
              LOWER CASE DEFAULT g_capath MODIF ID pat.
PARAMETERS :  userfil TYPE rlgrap-filename
              LOWER CASE DEFAULT g_userpath MODIF ID pat.
PARAMETERS :  cownfil TYPE rlgrap-filename
              LOWER CASE DEFAULT g_cownpath MODIF ID pat.
SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: END OF BLOCK pat_o.

*--Default Block - Upload
SELECTION-SCREEN: BEGIN OF BLOCK def_o WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) def_but USER-COMMAND def_but.
SELECTION-SCREEN COMMENT 16(50) text-b03.
PARAMETERS : p_comp  TYPE  /psyng/sw_uinfo-company    MODIF ID def,
             p_dep   TYPE  /psyng/sw_uinfo-department MODIF ID def,
             p_class TYPE  /psyng/sw_uinfo-class      MODIF ID def,
             p_syst  TYPE  rfcdes-rfcdest             MODIF ID def.
SELECTION-SCREEN: END OF BLOCK def_o.

*--Download
SELECTION-SCREEN: BEGIN OF BLOCK sel_o WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) sel_but USER-COMMAND sel_but.
SELECTION-SCREEN COMMENT 16(50) text-b04.
PARAMETERS :
             p_vrsio TYPE  /psyng/sodvrsio         MODIF ID sel.
SELECT-OPTIONS :
             p_rfcdes FOR rfcdes-rfcdest MATCHCODE OBJECT
               /psyng/sw_rfcsh           MODIF ID sel.
PARAMETERS : p_valusr TYPE flag                    MODIF ID sel.


SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: END OF BLOCK sel_o.
* BOC by RGUPTA on 05.04.22 for C0700
  INITIALIZATION.
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 05.04.22 for C0700


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
  PERFORM sanitize_input.
  IF p_up = 'X'.
    IF p_syst IS INITIAL.
      MESSAGE e106 WITH 'System Id'(e07).
    ENDIF.
    if gf_mr_installed is initial.
      MESSAGE e106 WITH 'Upload Not allowed when Risk Visualize is not installed'(e99).
    endif.
    PERFORM upload.
  ELSE.
    PERFORM download.
  ENDIF.

AT SELECTION-SCREEN.
  g_ucomm = sy-ucomm.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR scanfil.
  PERFORM file_select CHANGING scanfil .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR userfil.
  PERFORM file_select CHANGING userfil.

AT SELECTION-SCREEN OUTPUT.
  PERFORM sanitize_input.

  PERFORM handle_button.
  PERFORM handle_sections.
*--If MR is not installed
*  Hide everything related to upload.
  IF gf_mr_installed IS INITIAL.
    LOOP AT SCREEN.
      CASE screen-name.
        WHEN 'P_UP'.
          screen-input = 0.
          MODIFY SCREEN.
          p_down = 'X'.
          CLEAR p_up.
      ENDCASE.
    ENDLOOP.
  ENDIF.
*--The defaults section is only relevant for upload
  LOOP AT SCREEN.
    IF screen-group1 = 'DEF'.
      IF p_down = 'X'.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
*--The selection criteria screen is only relevant for download
    IF screen-group1 = 'SEL' AND screen-group3 <> 'OPU'.
      IF p_up = 'X'.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.


INITIALIZATION.
  g_repid = sy-repid.
  PERFORM check_mr_installation.
  PERFORM set_button_icons.
*--Initialize paths
  CONCATENATE
  'c:\temp\ext_sod_' sy-datum '_' sy-sysid sy-mandt '.txt'
  INTO g_scanpath.
  CONCATENATE
  'c:\temp\ext_ca_' sy-datum '_' sy-sysid sy-mandt '.txt'
  INTO g_capath.
  CONCATENATE
  'c:\temp\ext_userinfo_' sy-datum '_' sy-sysid sy-mandt '.txt'
  INTO g_userpath.

  CONCATENATE
  'c:\temp\ext_conowner_' sy-datum '_' sy-sysid sy-mandt '.txt'
  INTO g_cownpath.

  scanfil = g_scanpath.
  userfil = g_userpath.
  cafil   = g_capath.
  cownfil = g_cownpath.


*---------------------------------------------------------------------*
*       FORM handle_button                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM handle_button.
  CASE g_ucomm.
    WHEN 'UPD_BUT'.
      PERFORM toggle USING upd_but 'UPD_BUT'.
    WHEN 'PAT_BUT'.
      PERFORM toggle USING pat_but 'PAT_BUT'.
    WHEN 'DEF_BUT'.
      PERFORM toggle USING def_but 'DEF_BUT'.
    WHEN 'SEL_BUT'.
      PERFORM toggle USING sel_but 'SEL_BUT'.

  ENDCASE.
  CLEAR g_ucomm.

ENDFORM.                    " handle_button
*---------------------------------------------------------------------*
*       FORM handle_sections                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM handle_sections.
  PERFORM handle_section USING  upd_but 'UPD'.
  PERFORM handle_section USING  pat_but 'PAT'.
  PERFORM handle_section USING  def_but 'DEF'.
  PERFORM handle_section USING  sel_but 'SEL'.

ENDFORM.                    " handle_sections

*---------------------------------------------------------------------*
*       FORM set_button_icons                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM set_button_icons.
  PERFORM init_but USING 'UPD_BUT'  'X' CHANGING upd_but .
  PERFORM init_but USING 'PAT_BUT'  'X' CHANGING pat_but .
  PERFORM init_but USING 'DEF_BUT'  'X' CHANGING def_but .
  PERFORM init_but USING 'SEL_BUT'  'X' CHANGING sel_but .
  PERFORM handle_sections.
ENDFORM.                    " set_button_icons

*---------------------------------------------------------------------*
*       FORM toggle                                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_BUTTON                                                      *
*  -->  I_NAME                                                        *
*---------------------------------------------------------------------*
FORM toggle USING i_button i_name.
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

*---------------------------------------------------------------------*
*       FORM expand                                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  BUTTON                                                        *
*---------------------------------------------------------------------*
FORM expand CHANGING button.
*--Set user button Icon
  CALL FUNCTION 'ICON_CREATE'
       EXPORTING
            name       = 'ICON_COLLAPSE'
            add_stdinf = ''
       IMPORTING
            result     = button
*BOC:HBHALLA (03/12/24)
       EXCEPTIONS
            ICON_NOT_FOUND = 1
            OUTPUTFIELD_TOO_SHORT = 2
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
*EOC:HBHALLA (03/12/24)
ENDFORM.                    " expand
*---------------------------------------------------------------------*
*       FORM collapse                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  BUTTON                                                        *
*---------------------------------------------------------------------*
FORM collapse CHANGING    button.

  CALL FUNCTION 'ICON_CREATE'
       EXPORTING
            name       = 'ICON_EXPAND'
            add_stdinf = ''
       IMPORTING
            result     = button
*BOC:HBHALLA (03/12/24)
       EXCEPTIONS
            ICON_NOT_FOUND = 1
            OUTPUTFIELD_TOO_SHORT = 2
            OTHERS     = 3.
         IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
               MESSAGE s002(/psyng/sw) WITH 'Icon name unknown to system'.
            WHEN 2.
               MESSAGE s002(/psyng/sw) WITH 'Length of field (RESULT) is too small'.
            WHEN OTHERS.
               MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
          ENDCASE.
         ENDIF.
*EOC:HBHALLA (03/12/24)

ENDFORM.                    " collapse
*---------------------------------------------------------------------*
*       FORM handle_section                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_BUTTON                                                      *
*  -->  I_SECTION_NAME                                                *
*---------------------------------------------------------------------*
FORM handle_section USING    i_button
                             i_section_name.
  DATA : l_collapse TYPE flag.

  LOOP AT SCREEN .
    IF screen-group1 = i_section_name.
      IF i_button(3) <> '@3T'.
        screen-invisible = 1.
        screen-active    = 0.
        l_collapse = 'X'.
      ELSE.
        screen-invisible = 0.
        screen-active    = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " toggle_section
*---------------------------------------------------------------------*
*       FORM init_but                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_NAME                                                        *
*  -->  I_DEFAULT_EXPANDED                                            *
*  -->  I_BUTTON                                                      *
*---------------------------------------------------------------------*
FORM init_but USING    i_name
                       i_default_expanded
              CHANGING i_button.

  DATA : ls_state TYPE /psyng/usr_displ,
         l_exp TYPE flag.
  SELECT SINGLE * INTO ls_state
  FROM /psyng/usr_displ
  WHERE
    bname = g_current_user AND "sy-uname AND C0700
    repid = sy-repid AND
    button_name = i_name.
  IF sy-subrc = 0.
    l_exp = ls_state-expanded.
  ELSE.
    l_exp = i_default_expanded.
  ENDIF.

  IF l_exp = 'X'.
    PERFORM expand CHANGING i_button.
  ELSE.
    PERFORM collapse CHANGING i_button.
  ENDIF.

ENDFORM.                    " init_but
*&---------------------------------------------------------------------*
*&      Form  file_select
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_SCANFIL  text
*----------------------------------------------------------------------*
FORM file_select CHANGING e_path.
  DATA : lt_ftab TYPE filetable ,
         ls_ftab LIKE LINE OF lt_ftab,
         l_rc LIKE sy-subrc,
         l_fname TYPE string,
         l_path TYPE string,
         l_fullpath TYPE string.
  IF p_up = 'X'.
    CALL METHOD cl_gui_frontend_services=>file_open_dialog
"#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
*      WINDOW_TITLE            =
      default_extension       = 'txt'
*      DEFAULT_FILENAME        =
*      FILE_FILTER             =
*      INITIAL_DIRECTORY       =
*      MULTISELECTION          =
      CHANGING
        file_table              = lt_ftab
        rc                      = l_rc
*      USER_ACTION             =
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
      READ TABLE lt_ftab INTO ls_ftab INDEX 1.
      IF sy-subrc = 0.
        e_path = ls_ftab-filename.
      ENDIF.
    ENDIF.
  ELSE.
    CALL METHOD cl_gui_frontend_services=>file_save_dialog
"#EC SAST_CI_GEN_CHECK (HBHALLA)
*  EXPORTING
*    WINDOW_TITLE      =
*    DEFAULT_EXTENSION =
*    DEFAULT_FILE_NAME =
*    FILE_FILTER       =
*    INITIAL_DIRECTORY =
      CHANGING
    filename          = l_fname
    path              = l_path
        fullpath      = l_fullpath
*    USER_ACTION       =
      EXCEPTIONS
        cntl_error        = 1
        error_no_gui      = 2
        OTHERS            = 3
            .
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    e_path = l_fullpath.
  ENDIF.
  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      cntl_system_error = 1
      cntl_error        = 2
      OTHERS            = 3
          .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " file_select
*&---------------------------------------------------------------------*
*&      Form  download
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM download.
  DATA : lt_syscandt TYPE TABLE OF /psyng/syscandt  WITH HEADER LINE,
         lt_cratdt   TYPE TABLE OF /psyng/sw_cratdt WITH HEADER LINE,
         lt_rfcs     TYPE TABLE OF rfcdes.
  DATA : lf_sod_downloadfailed  TYPE flag,
         lf_ca_downloadfailed   TYPE flag,
         lf_usr_downloadfailed  TYPE flag,
         lf_cown_downloadfailed TYPE flag.

*--Download SOD Scan Data
  SELECT * FROM /psyng/syscandt
  INTO TABLE lt_syscandt
  WHERE vrsio = p_vrsio.
  LOOP AT lt_syscandt.
    CLEAR gt_sod_scan.
    MOVE-CORRESPONDING lt_syscandt TO gt_sod_scan.
    gt_sod_scan-sysid = p_syst.
    APPEND gt_sod_scan.
  ENDLOOP.
  PERFORM get_sod_auditors TABLES gt_sod_scan.
  PERFORM save_file
              TABLES
                 gt_sod_scan
              USING
                 scanfil
                 'SOD Scan data download failed'(e01)
              CHANGING
                 lf_sod_downloadfailed.
  FREE : gt_sod_scan.
*--Download CA Scan Data
  SELECT * FROM /psyng/sw_cratdt
  INTO TABLE lt_cratdt
  WHERE vrsio = p_vrsio.
  LOOP AT lt_cratdt.
    CLEAR gt_ca_scan.
    MOVE-CORRESPONDING lt_cratdt TO gt_ca_scan.
    gt_ca_scan-sysid = p_syst.
    APPEND gt_ca_scan.
  ENDLOOP.
  PERFORM get_ca_auditors TABLES gt_sod_scan.
  PERFORM save_file
              TABLES
                 gt_ca_scan
              USING
                 cafil
                 'CA Scan data download failed'(e02)
              CHANGING
                 lf_ca_downloadfailed.
  FREE : gt_ca_scan.
*--Download User Data
  PERFORM load_rfc TABLES
    p_rfcdes
    lt_rfcs.

  PERFORM load_users
    TABLES
      lt_rfcs
      gt_uinfo.
  PERFORM save_file
              TABLES
                 gt_uinfo
              USING
                 userfil
                 'User data download failed'(e03)
              CHANGING
                 lf_usr_downloadfailed.

*--Download Conflict Owners
  PERFORM load_conowners
    TABLES gt_conowners.
  PERFORM save_file
              TABLES
                 gt_conowners
              USING
                 cownfil
                 'Conflict Owners download failed'(e04)
              CHANGING
                 lf_cown_downloadfailed.


ENDFORM.                    " download
*---------------------------------------------------------------------*
*       FORM load_rfc                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_USER_RFC                                                   *
*  -->  ET_RFCDES                                                     *
*---------------------------------------------------------------------*
FORM load_rfc
    TABLES
      it_user_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
      et_rfcdes STRUCTURE rfcdes.
  .
  DATA : l_rfcdest TYPE rfcdes-rfcdest,
          l_system_msg(80) TYPE c.
  FIELD-SYMBOLS : <rfcdes> TYPE rfcdes.

  IF NOT it_user_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_user_rfc.
  ENDIF.
*--Get sysid and mandt into field RFCOPTIONS
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
    CALL FUNCTION '/PSYNG/SW_062'
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
          text-e02
          l_rfcdest
          l_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH
          text-e02
          l_rfcdest.
      ENDCASE.
      COMMIT WORK.
    ELSE.
      <rfcdes>-rfcoptions = l_rfcdest.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " validate_user_rfc
*&---------------------------------------------------------------------*
*&      Form  upload
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM upload.
AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
         ID 'Y&SW_ADMF' FIELD 'SUMMTAB'.
IF sy-subrc <> 0.
  MESSAGE e108 WITH 'Upload SOD Scan Data'.
ENDIF.

*--To delete all Data for a system, empty files should be uploaded.
*  Uploading empty files SHOULD NOT BE CONSIDERED AN ERROR
  IF p_syst IS INITIAL.
    MESSAGE e106 WITH 'a System ID'(e09).
*   Please enter & & & &
  ENDIF.
*--Upload SOD Scan table Data
  PERFORM upload_file
              TABLES
                 gt_sod_scan
              USING
                 scanfil
                 'SOD Scan data upload failed'(e04).
*--Set the sysid value
  gt_sod_scan-sysid = p_syst.
  MODIFY gt_sod_scan TRANSPORTING sysid WHERE sysid <> p_syst.
  SORT gt_sod_scan BY sysid bname conid vrsio.
  DELETE ADJACENT DUPLICATES FROM gt_sod_scan
  COMPARING sysid bname conid vrsio.
DELETE FROM (g_const_exc_tabname) WHERE sysid = p_syst. "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
  COMMIT WORK.
  INSERT (g_const_exc_tabname) FROM TABLE gt_sod_scan. "#EC SAST_CI_GEN_CHECK
  COMMIT WORK.
  FREE : gt_sod_scan.
*--Upload CA Scan table Data

  PERFORM upload_file
              TABLES
                 gt_ca_scan
              USING
                 cafil
                 'CA Scan data upload failed'(e05).
*--Set the sysid value
  gt_ca_scan-sysid = p_syst.
  MODIFY gt_ca_scan TRANSPORTING sysid WHERE sysid <> p_syst.
  SORT gt_ca_scan BY sysid bname swaudid vrsio.
  DELETE ADJACENT DUPLICATES FROM gt_ca_scan
  COMPARING sysid bname swaudid vrsio.
DELETE FROM (g_const_exa_tabname) WHERE sysid = p_syst."#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
  COMMIT WORK.

  INSERT (g_const_exa_tabname) FROM TABLE gt_ca_scan. "#EC SAST_CI_GEN_CHECK
  COMMIT WORK.
  FREE : gt_ca_scan.
*--Upload User Data

  PERFORM upload_file
              TABLES
                 gt_uinfo
              USING
                userfil
                 'User data upload failed'(e06).
*--Set the sysid value
*  and overwrite class, comp and dep if provided in selection screen
  gt_uinfo-sysid = p_syst.
  gt_uinfo-class = p_class.
  gt_uinfo-company = p_comp.
  gt_uinfo-department = p_dep.
  MODIFY gt_uinfo TRANSPORTING sysid
  WHERE sysid <> p_syst.

  IF NOT p_class IS INITIAL.
    MODIFY gt_uinfo TRANSPORTING class
    WHERE class <> p_class.
  ENDIF.
  IF NOT p_comp IS INITIAL.
    MODIFY gt_uinfo TRANSPORTING company
    WHERE company <> p_comp.
  ENDIF.
  IF NOT p_dep IS INITIAL.
    MODIFY gt_uinfo TRANSPORTING department
    WHERE department <> p_dep.
  ENDIF.

  SORT gt_uinfo BY sysid bname.
  DELETE ADJACENT DUPLICATES FROM gt_uinfo COMPARING sysid bname.


DELETE FROM (g_const_exu_tabname) WHERE sysid = p_syst."#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
  COMMIT WORK.

INSERT (g_const_exu_tabname) FROM TABLE gt_uinfo."#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
  COMMIT WORK.
  FREE : gt_uinfo.

*--Upload Conflict Owner Data

  PERFORM upload_file
            TABLES
               gt_conowners
            USING
              cownfil
               'Conflict Owner data upload failed'(e08).
*--Set the sysid value
  gt_conowners-sysid = p_syst.
  MODIFY gt_conowners TRANSPORTING sysid WHERE sysid <> p_syst.
*--Modify the company
  IF NOT p_comp IS INITIAL.
    gt_conowners-company = p_comp.
    MODIFY gt_conowners TRANSPORTING company
    WHERE company <> p_comp.
  ENDIF.

  SORT gt_conowners BY sysid  vrsio conid owner.
  DELETE ADJACENT DUPLICATES FROM gt_conowners
  COMPARING sysid  vrsio conid owner.
DELETE FROM (g_const_exo_tabname) WHERE sysid = p_syst."#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
  COMMIT WORK.
INSERT (g_const_exo_tabname) FROM TABLE gt_conowners."#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
  COMMIT WORK.
  FREE : gt_conowners.



  MESSAGE s113(/psyng/sw) WITH 'Upload Finished'(s01).
  COMMIT WORK.

ENDFORM.                    " upload
*---------------------------------------------------------------------*
*       FORM get_sod_auditors                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SOD_SCAN                                                   *
*---------------------------------------------------------------------*
FORM get_sod_auditors TABLES et_sod_scan STRUCTURE
/psyng/sw_mr_ext_sod_scan
.
  DATA : lt_usr    TYPE TABLE OF /psyng/sw_sel_opts_xubname
                   WITH HEADER LINE,
         lt_confs  TYPE TABLE OF /psyng/sw_sel_opts_conid
                   WITH HEADER LINE,
         lt_confs_part
                   TYPE TABLE OF /psyng/sw_sel_opts_conid
                   WITH HEADER LINE,
         lt_contid TYPE TABLE OF /psyng/sw_sel_opts_contid
                   WITH HEADER LINE,
         lt_mcuser TYPE TABLE OF /psyng/mitigation_assignment
                   WITH HEADER LINE,
         lt_mcuser_part
                   TYPE TABLE OF /psyng/mitigation_assignment
                   WITH HEADER LINE           .
  FIELD-SYMBOLS : <sod_scan> TYPE /psyng/sw_mr_ext_sod_scan.
  lt_usr-sign   = 'I'.
  lt_usr-option = 'EQ'.
  lt_confs-sign   = 'I'.
  lt_confs-option = 'EQ'.
  lt_contid-sign   = 'I'.
  lt_contid-option = 'EQ'.
  LOOP AT et_sod_scan.
    CHECK NOT et_sod_scan-contid IS INITIAL.
    lt_confs-low  = et_sod_scan-conid.
    COLLECT lt_confs.
  ENDLOOP.
  LOOP AT lt_confs.
    REFRESH : lt_confs_part,lt_usr,lt_contid .
    LOOP AT et_sod_scan WHERE conid = lt_confs-low AND
                             contid  <> ''.
      lt_usr-low    = et_sod_scan-bname.
      lt_contid-low = et_sod_scan-contid.
      COLLECT : lt_usr, lt_contid.
    ENDLOOP.

    APPEND lt_confs TO lt_confs_part.
    CALL FUNCTION '/PSYNG/SW_071'
         EXPORTING
              i_vrsio    = p_vrsio
         TABLES
              it_users   = lt_usr
              it_confs   = lt_confs_part
              et_mcusers = lt_mcuser_part
              it_contid  = lt_contid.
    APPEND LINES OF lt_mcuser_part TO lt_mcuser.
    REFRESH lt_mcuser_part.
  ENDLOOP.

  SORT lt_mcuser BY userid conid contid.

  LOOP AT et_sod_scan ASSIGNING <sod_scan>.
    CHECK NOT <sod_scan>-contid IS INITIAL.
    READ TABLE lt_mcuser WITH KEY userid = <sod_scan>-bname
                                  conid  = <sod_scan>-conid
                                  contid = <sod_scan>-contid
                                  BINARY SEARCH.
    IF sy-subrc = 0.
      <sod_scan>-auditor = lt_mcuser-auditor.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " get_auditor
*---------------------------------------------------------------------*
*       FORM get_ca_auditors                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_CA_SCAN                                                    *
*---------------------------------------------------------------------*
FORM get_ca_auditors TABLES et_ca_scan STRUCTURE
/psyng/sw_mr_ext_ca_scan
.
  DATA : lt_usr    TYPE TABLE OF /psyng/sw_sel_opts_xubname
                   WITH HEADER LINE,
         lt_auds   TYPE TABLE OF /psyng/range_swaudid
                   WITH HEADER LINE,
         lt_auds_part
                   TYPE TABLE OF /psyng/range_swaudid
                   WITH HEADER LINE,

         lt_contid TYPE TABLE OF /psyng/sw_sel_opts_contid
                   WITH HEADER LINE,
         lt_mcuser TYPE TABLE OF /psyng/mitigation_assignment
                   WITH HEADER LINE,
         lt_mcuser_part TYPE TABLE OF /psyng/mitigation_assignment
                   WITH HEADER LINE.
  FIELD-SYMBOLS : <ca_scan> TYPE /psyng/sw_mr_ext_ca_scan.
  lt_usr-sign   = 'I'.
  lt_usr-option = 'EQ'.
  lt_auds-sign   = 'I'.
  lt_auds-option = 'EQ'.
  lt_contid-sign   = 'I'.
  lt_contid-option = 'EQ'.
  LOOP AT et_ca_scan.
    CHECK NOT et_ca_scan-contid IS INITIAL.
    lt_auds-low   = et_ca_scan-swaudid.
    COLLECT lt_auds.
  ENDLOOP.

  LOOP AT lt_auds.
    REFRESH : lt_auds_part,lt_usr,lt_contid.
    APPEND lt_auds TO lt_auds_part.
    LOOP AT et_ca_scan WHERE swaudid = lt_auds-low AND
                             contid  <> ''.
      lt_usr-low    = et_ca_scan-bname.
      lt_contid-low = et_ca_scan-contid.
      COLLECT : lt_usr, lt_contid.
    ENDLOOP.

    CALL FUNCTION '/PSYNG/SW_096'
         EXPORTING
              i_vrsio    = p_vrsio
         TABLES
              it_users   = lt_usr
              it_auds    = lt_auds_part
              et_mcusers = lt_mcuser_part
              it_contid  = lt_contid.
    APPEND LINES OF lt_mcuser_part TO lt_mcuser.
    REFRESH lt_mcuser_part.
  ENDLOOP.
  SORT lt_mcuser BY userid swaudid contid.

  LOOP AT et_ca_scan ASSIGNING <ca_scan>.
    CHECK NOT <ca_scan>-contid IS INITIAL.
    READ TABLE lt_mcuser WITH KEY userid  = <ca_scan>-bname
                                  swaudid = <ca_scan>-swaudid
                                  contid  = <ca_scan>-contid
                                  BINARY SEARCH.
    IF sy-subrc = 0.
      <ca_scan>-auditor = lt_mcuser-auditor.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " get_auditor



*---------------------------------------------------------------------*
*       FORM save_file                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_TABLE                                                      *
*  -->  I_FILENAME                                                    *
*  -->  I_ERR_TEXT                                                    *
*  -->  E_DOWNLOADFAILED                                              *
*---------------------------------------------------------------------*
FORM save_file TABLES  it_table
              USING    i_filename TYPE rlgrap-filename
                       i_err_text TYPE string
              CHANGING e_downloadfailed.
  DATA: l_filename TYPE string,
        l_err_mess TYPE bapiret2-message,
        l_msgv1    TYPE bapiret2-message_v1,
        l_msgv2    TYPE bapiret2-message_v2.

  l_filename = i_filename.
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
              if_no_popup = ' '
         IMPORTING
              e_message   = l_err_mess.
*    PERFORM log USING l_filename 'E' '' '' '' '' l_err_mess.
  ELSE.
*    PERFORM log  USING
*      l_filename 'S' '' '' '' ''
*      'Download is Completed Successfully'(150).

  ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
ENDFORM.

*---------------------------------------------------------------------*
*       FORM upload_file                                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_TABLE                                                      *
*  -->  I_FILENAME                                                    *
*  -->  I_ERR_TEXT                                                    *
*---------------------------------------------------------------------*
FORM upload_file TABLES   et_table
            USING    i_filename TYPE rlgrap-filename
                     i_err_text.
  DATA: l_filename TYPE string,
        l_err_mess TYPE bapiret2-message,
        l_msgv1    TYPE bapiret2-message_v1,
        l_msgv2    TYPE bapiret2-message_v2.

  FREE : et_table.
*  CONCATENATE basepath '\' i_filename INTO l_filename.
  l_filename = i_filename.
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
    l_msgv1 = l_filename.
    l_msgv2 = i_err_text.
    CALL FUNCTION '/PSYNG/BC_004'
         EXPORTING
              i_subrc = sy-subrc
              i_msgty = 'I'
              i_msgv1 = l_msgv1
              i_msgv2 = l_msgv2
*              if_no_popup = 'X'
         IMPORTING
              e_message   = l_err_mess.
*    PERFORM log USING l_filename 'E' '' '' '' '' l_err_mess.
  ENDIF.
  ENDIF.
*EOC:HBHALLA (097)
ENDFORM.                    " upload


*&---------------------------------------------------------------------*
*&      Form  load_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_RFCS  text
*      -->P_GT_UINFO_REMOTE  text
*----------------------------------------------------------------------*
FORM load_users TABLES
  it_rfcdes       STRUCTURE rfcdes
  et_uinfo STRUCTURE /psyng/sw_mr_ext_uinfo.
  FIELD-SYMBOLS : <des> TYPE rfcdes.
  DATA : lt_swuinfo TYPE TABLE OF /psyng/sw_uinfo
         WITH HEADER LINE,
         lt_userinformation TYPE TABLE OF /psyng/sw_uinfo_remote
         WITH HEADER LINE,
         lf_validuser TYPE flag.
  DATA: ls_swconfig TYPE /psyng/da_swconfig,
        lt_rfcdes TYPE TABLE OF rfcdes WITH HEADER LINE,
        l_local TYPE rfcdest,
        l_prio TYPE i.

*--check if local system is in table, if not add it
  READ TABLE it_rfcdes WITH KEY rfcdest = 'LOCAL'.
  IF sy-subrc <> 0.
    it_rfcdes-rfcdest = 'LOCAL'.
    CONCATENATE sy-sysid sy-mandt INTO it_rfcdes-rfcoptions.
    APPEND it_rfcdes.
  ENDIF.
*--get System Id and Client of remote systems
  LOOP AT it_rfcdes ASSIGNING <des>.
    CHECK <des>-rfcoptions IS INITIAL.
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
    CALL FUNCTION '/PSYNG/SW_062'
    DESTINATION <des>-rfcdest
     IMPORTING
       e_rfcdest       = <des>-rfcoptions. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
  ENDLOOP.

*--ignore rfc destinations pointing to the local system
  CONCATENATE sy-sysid sy-mandt INTO l_local.
  DELETE  it_rfcdes WHERE rfcoptions = l_local
  AND rfcdest <> 'LOCAL'.


*--Load user information per system
  PERFORM get_sw_repo_config.
  LOOP AT it_rfcdes.
    FREE : lt_swuinfo.
    IF it_rfcdes-rfcdest = 'LOCAL'.
      CALL FUNCTION '/PSYNG/SW_USER_INFO'
           EXPORTING
                i_mr_company    = 'X'
                i_mr_department = 'X'
                i_name_only     = 'X'
           TABLES
                sw_uinfo        = lt_swuinfo.
    ELSE.
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
      CALL FUNCTION '/PSYNG/SW_USER_INFO'
      DESTINATION it_rfcdes-rfcdest
       EXPORTING
         i_mr_company              = 'X'
         i_mr_department           = 'X'
         i_name_only               = 'X'
        TABLES
          sw_uinfo                 = lt_swuinfo
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
    ENDIF.
    lt_userinformation-rfcdest = it_rfcdes-rfcoptions.
    LOOP AT lt_swuinfo.
      IF p_valusr IS INITIAL.
        lf_validuser = 'X'.
      ELSE.
        PERFORM user_check_validity
        USING lt_swuinfo
        CHANGING lf_validuser.
      ENDIF.

      IF lf_validuser = 'X'.
        MOVE-CORRESPONDING lt_swuinfo TO lt_userinformation.
        APPEND lt_userinformation.
      ENDIF.
    ENDLOOP.
  ENDLOOP.
*--Determine parameter for priority of systems
*user attributes (company, user group) shall be determined in the
*following sequence:
* The sort key for the local system is determined by the config
* parameter SW_LOCAL_SYSTEM_SORT,
*( if it is not available, the default blank value will be used, making
*  the local system always having the highest priority)
*For all remote systems, the sort key that will be used is the RFC
* destination name.

*--Get configured sort criteria for local system
*  IF if_remote_only IS INITIAL.
  CONCATENATE sy-sysid sy-mandt  INTO l_local.
  se_config_param 'SW_LOCAL_SYSTEM_SORT' ls_swconfig-value.

  READ TABLE it_rfcdes
  ASSIGNING <des>
  WITH KEY rfcoptions = l_local.
  IF sy-subrc <> 0.
    lt_rfcdes-rfcoptions = l_local.
    APPEND it_rfcdes.
    READ TABLE it_rfcdes
    ASSIGNING <des>
    WITH KEY rfcoptions = l_local.
  ENDIF.
  IF ls_swconfig-value <> '' AND sy-subrc = 0.
    <des>-rfcdest = ls_swconfig-value.
  ELSE.
    CLEAR <des>-rfcdest.
  ENDIF.
*  ENDIF.
  l_prio = 0.
*  SORT lt_rfcdes BY rfcdest.
  SORT it_rfcdes BY rfcdest.
  LOOP AT it_rfcdes.
    ADD 1 TO l_prio.
    lt_userinformation-prio = l_prio.
    MODIFY lt_userinformation
    TRANSPORTING prio
    WHERE
    rfcdest = it_rfcdes-rfcoptions.
  ENDLOOP.
*--Only keep record with highest priority for each user
  SORT lt_userinformation BY bname prio.
  DELETE ADJACENT DUPLICATES FROM  lt_userinformation COMPARING bname.
  LOOP AT lt_userinformation.
    MOVE-CORRESPONDING lt_userinformation TO et_uinfo.
    APPEND et_uinfo.
  ENDLOOP.
  FREE :  lt_userinformation.

ENDFORM.                    " load_users


*---------------------------------------------------------------------*
*       FORM get_sw_repo_config                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_sw_repo_config.
  se_config_param 'REP_USR_LOK_DSP_MGR' dsp_mng_lock.
  se_config_param 'REP_USR_LOK_DSP_SLF' dsp_slf_lock.
ENDFORM.                    " get_sw_repo_conifg
*---------------------------------------------------------------------*
*       FORM user_check_validity                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IS_SWUINFO                                                    *
*  -->  EF_VALIDUSER                                                  *
*---------------------------------------------------------------------*
FORM user_check_validity USING    is_swuinfo TYPE /psyng/sw_uinfo
                         CHANGING ef_validuser TYPE flag.
  CLEAR ef_validuser.
  CONSTANTS :
*--UFLAG user locking hex values
    lc_yulock   TYPE x VALUE '80',       "Locked by failed login.
    lc_yusloc   TYPE x VALUE '40',       "Locked by Administrator
    lc_yugloc   TYPE x VALUE '20'.       "Locked by CUA administrator
  DATA : l_uflag TYPE x.

*--Check if a user is an active dialog user
  CHECK is_swuinfo-ustyp = 'A'.
  DATA : ls_swuinfo TYPE        /psyng/sw_uinfo.
  ls_swuinfo = is_swuinfo.
  IF ls_swuinfo-gltgv IS INITIAL.
    ls_swuinfo-gltgv = '00010101'.
  ENDIF.
  IF ls_swuinfo-gltgb IS INITIAL.
    ls_swuinfo-gltgb = '99991231'.
  ENDIF.

  IF ls_swuinfo-gltgv <= sy-datum AND ls_swuinfo-gltgb >= sy-datum.
    l_uflag = ls_swuinfo-uflag."Unicode
    IF l_uflag O lc_yusloc OR "locked by admin
       l_uflag O lc_yugloc.   "locked by CUA admin
      IF dsp_mng_lock = 'Y'.
        ef_validuser = 'X'.
      ENDIF.
    ELSEIF l_uflag O lc_yulock."locked by failed logins
      IF dsp_slf_lock = 'Y'.
        ef_validuser = 'X'.
      ENDIF.
    ELSE.
*  --       User is active
      ef_validuser = 'X'.
    ENDIF.
  ENDIF.

ENDFORM.                    " user_check_validity
*---------------------------------------------------------------------*
*       FORM check_mr_installation                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM check_mr_installation.
  DATA : lf_mr_installed TYPE flag,
         l_vrsio TYPE /psyng/prog_vrsio.
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
       EXPORTING
            i_module         = 'MR'
       IMPORTING
            e_installed      = lf_mr_installed
            e_module_version = l_vrsio.

  IF lf_mr_installed = 'X' AND l_vrsio > '1.2PS4B'.
    gf_mr_installed = 'X'.
  ELSE.
    CLEAR gf_mr_installed.
  ENDIF.

ENDFORM.                    " check_mr_installation
*---------------------------------------------------------------------*
*       FORM load_conowners                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_CONOWNERS                                                  *
*---------------------------------------------------------------------*
FORM load_conowners TABLES
  et_conowners STRUCTURE /psyng/sw_mr_ext_conowner.

  SELECT * FROM /psyng/conowner INTO
  CORRESPONDING FIELDS OF TABLE et_conowners
  WHERE vrsio = p_vrsio.
ENDFORM.                    " load_conowners
*&---------------------------------------------------------------------*
*&      Form  sanitize_input
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM sanitize_input.
*-These fields should always be upper case
  TRANSLATE p_syst  TO UPPER CASE.
  TRANSLATE p_comp  TO UPPER CASE.
  TRANSLATE p_dep   TO UPPER CASE.
  TRANSLATE p_class TO UPPER CASE.
ENDFORM.                    " sanitize_input
