*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_101
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sw_101.
INCLUDE /psyng/sw_config.
INCLUDE /psyng/basis_exelog.


TABLES: /psyng/mchdr,icon,/psyng/swconfig.
TYPE-POOLS: slis,abap.

DATA : i_fieldcat_alv TYPE slis_t_fieldcat_alv,
       gs_alv_layout TYPE slis_layout_alv,
       wa_fieldcat_alv TYPE slis_t_fieldcat_alv WITH HEADER LINE.
DATA : gt_sort TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA: g_warnings_count TYPE i,
      g_errors_count TYPE i.
CONSTANTS: gc_act_download(2) VALUE 'DL',    "download activity
           gc_act_upload(2)   VALUE 'UL',    "upload activity
           gc_error_icon   TYPE icon-id VALUE  '@0A@',
           gc_warning_icon TYPE icon-id VALUE  '@09@',
           gc_success_icon TYPE icon-id VALUE  '@08@'.

*******New Declarations
DATA: BEGIN OF gc_fields,
             contid(20) TYPE c ,
             conid(20) TYPE c ,
             userid(20) TYPE c ,
             objectid(20) TYPE c,
             tcode(20) TYPE c ,
             repid(20) TYPE c,
             freq(20) TYPE c ,
             type(20) TYPE c,
             inactive(10) TYPE c,
             approver(20) TYPE c,
             auditor(20) TYPE c,
             version(20) TYPE c,
             company(20) TYPE c,
             authid(20) TYPE c,
             fr_date(20) TYPE c,
             to_date(20) TYPE c ,
             no_err(20) TYPE c,
             class(20) TYPE c,
             role(20) TYPE c ,
             obj(20) TYPE c,
           END OF gc_fields.
gc_fields-contid = 'Control ID'(f01).
gc_fields-conid = 'Conflict ID'(f10).
gc_fields-userid = 'User ID'(f02).
gc_fields-objectid = 'Object ID'(f17).
gc_fields-tcode = 'Transaction Code'(f04).
gc_fields-repid = 'Program'(f05).
gc_fields-freq = 'Frequency'(f06).
gc_fields-approver = 'Approver'(f07).
gc_fields-auditor = 'Auditor'(f08).
gc_fields-version = 'Version'(f09).
gc_fields-company = 'Company'(f11).
gc_fields-authid = 'Authorization ID'(f12).
gc_fields-fr_date = 'From Date'(f13).
gc_fields-to_date = 'To Date'(f14).
gc_fields-no_err = ' '.
gc_fields-class = 'Class '(f15).
gc_fields-role = 'Role Name'(f16).
gc_fields-obj = 'Object ID'(f17).
gc_fields-type = 'Mitigation Type'(f18).
gc_fields-inactive = 'Inactive'(f19).


CONSTANTS : gc_mittext_tab TYPE dd02l-tabname VALUE '/PSYNG/TEXTS',
            gc_mithdr_tab TYPE dd02l-tabname VALUE '/PSYNG/MCHDR',
            gc_mittran_tab TYPE dd02l-tabname VALUE '/PSYNG/MCTRAN',
            gc_mitrep_tab TYPE dd02l-tabname VALUE '/PSYNG/MCREPID',
            gc_mitaud_tab TYPE dd02l-tabname VALUE '/PSYNG/MCAUDITOR',
            gc_mituser_tab TYPE dd02l-tabname VALUE '/PSYNG/MCUSER',
            gc_mitgrp_tab TYPE dd02l-tabname VALUE '/PSYNG/MCUSRGRP',
            gc_mitrole_tab TYPE dd02l-tabname VALUE '/PSYNG/MCROLE',
            gc_mitcau_tab TYPE dd02l-tabname VALUE '/PSYNG/MCCAUSER',
            gc_mitcar_tab TYPE dd02l-tabname VALUE '/PSYNG/MCCAROLE',
            "begin of changes DDHIMAN 19.11.18
            gc_mitrvhdr_tab TYPE dd02l-tabname VALUE '/PSYNG/MCRVWHDR'.
"end of changes DDHIMAN 19.11.18


DATA: g_approver TYPE /psyng/mchdr-approver.
TYPES: BEGIN OF t_tstc,
         tcode TYPE tstc-tcode,
       END OF t_tstc.
DATA: g_err_msg(80) TYPE c,
      g_err_value(30) TYPE c.
DATA:g_field(20) TYPE c,
     g_file_name(60) TYPE c.
DATA: g_mit_aprv_eq_usr_msg TYPE /psyng/swconfig-value,
      g_mit_audt_eq_usr_msg TYPE /psyng/swconfig-value,
      g_mit_audt_hdr_list TYPE /psyng/swconfig-value,
      g_mit_valid_for_con TYPE /psyng/swconfig-value,
      g_mit_con_defined_only TYPE /psyng/swconfig-value.
DATA: g_sod_vrsio TYPE  /psyng/swsodvers-vrsio.

DATA: BEGIN OF gt_mchdr OCCURS 0.
        INCLUDE STRUCTURE /psyng/mchdr.
DATA: l_index TYPE i.
DATA: END OF gt_mchdr.

DATA: BEGIN OF gt_mctran OCCURS 0.
        INCLUDE STRUCTURE /psyng/mctran.
DATA: l_index TYPE i.
DATA: END OF gt_mctran.

DATA: BEGIN OF gt_mcrepid OCCURS 0.
        INCLUDE STRUCTURE /psyng/mcrepid.
DATA: l_index TYPE i.
DATA: END OF gt_mcrepid.

DATA: BEGIN OF gt_mcauditor OCCURS 0.
        INCLUDE STRUCTURE /psyng/mcauditor.
DATA: l_index TYPE i.
DATA: END OF gt_mcauditor.

DATA: BEGIN OF gt_mcuser OCCURS 0.
        INCLUDE STRUCTURE /psyng/mcuser.
DATA: l_index TYPE i.
DATA: END OF gt_mcuser.
DATA: gs_mcuser LIKE LINE OF gt_mcuser.
DATA: BEGIN OF gt_mcusrgrp OCCURS 0.
        INCLUDE STRUCTURE /psyng/mcusrgrp.
DATA: l_index TYPE i.
DATA: END OF gt_mcusrgrp.

DATA: BEGIN OF gt_mccauser OCCURS 0.
        INCLUDE STRUCTURE /psyng/mccauser.
DATA: l_index TYPE i.
DATA: END OF gt_mccauser.

DATA: BEGIN OF gt_mcrole OCCURS 0.
        INCLUDE STRUCTURE /psyng/mcrole.
DATA: l_index TYPE i.
DATA: END OF gt_mcrole.

DATA: BEGIN OF gt_mccarole OCCURS 0.
        INCLUDE STRUCTURE /psyng/mccarole.
DATA: l_index TYPE i.
DATA: END OF gt_mccarole.

DATA : gt_cont_ovr TYPE TABLE OF /psyng/mchdr-contid
       WITH HEADER LINE,
       gf_add TYPE flag,
       gf_del TYPE flag.

DATA: g_index TYPE i.

DATA: BEGIN OF gt_mittexts OCCURS 0,
        mandt TYPE sy-mandt,
        contid TYPE /psyng/mchdr-contid,
        object TYPE /psyng/texts-object,
        spras TYPE /psyng/texts-spras,
        line TYPE /psyng/texts-line,
        vrsio TYPE /psyng/texts-vrsio,
        text TYPE /psyng/texts-text,
        l_index TYPE i,
END OF gt_mittexts.

DATA: BEGIN OF gt_nodel OCCURS 0,
        contid TYPE /psyng/mchdr-contid,
      END OF gt_nodel.

DATA: gf_upld_r_dwld TYPE flag VALUE 'X',
      g_ucomm          TYPE sy-ucomm.

********Output table
DATA: BEGIN OF gt_output OCCURS 0,
      l_index TYPE i,
      fl_name LIKE rlgrap-filename,
      id LIKE icon-id,
*      con_id LIKE trdir-name,
      err_fld(20) TYPE c,
      err_val(30) TYPE c,
      err_msg(80) TYPE c,
      sort_file TYPE i,
      END OF gt_output.

*************Tables for validation
*TYPES: BEGIN OF t_tstc,
*         tcode TYPE tstc-tcode,
*       END OF t_tstc.

DATA: gt_tstc TYPE HASHED TABLE OF t_tstc WITH UNIQUE KEY tcode
              WITH HEADER LINE.

DATA: BEGIN OF gt_tadir OCCURS 0,
        obj_name LIKE tadir-obj_name,
      END OF gt_tadir.

DATA: BEGIN OF gt_usr02 OCCURS 0,
        bname LIKE usr02-bname,
      END OF gt_usr02.

DATA: BEGIN OF gt_mchdr_db OCCURS 0,
        contid LIKE /psyng/mchdr-contid,
        description LIKE /psyng/mchdr-description,
      END OF gt_mchdr_db.

DATA: gf_err,g_status.

*DATA : gt_frequencies TYPE TABLE OF dd07v.
DATA : gt_frequencies TYPE TABLE OF /psyng/sw_freq.

"begin of changes DDHIMAN 19.11.2018
DATA: BEGIN OF gt_mcrvwhdr OCCURS 0.
        INCLUDE STRUCTURE /psyng/mcrvwhdr.
DATA: l_index TYPE i.
DATA: END OF gt_mcrvwhdr.

*DATA:s_cmt(50) TYPE c.
*********************************************

SELECTION-SCREEN: BEGIN OF BLOCK 1st WITH FRAME TITLE text-010.

***********************Downloading tables***************************
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: dnldtabs RADIOBUTTON GROUP a DEFAULT 'X' USER-COMMAND updn.
SELECTION-SCREEN: COMMENT 3(76) text-011 FOR FIELD dnldtabs.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(79) text-012.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 1.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: upldtabs RADIOBUTTON GROUP a.
SELECTION-SCREEN: COMMENT 3(76) text-021 FOR FIELD upldtabs.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(79) text-020.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 2.

**---------------------------------------------------------
******Define Path of folder
SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN: COMMENT 3(76) 'Folder'.
SELECTION-SCREEN: COMMENT 1(10) text-153.

PARAMETER: path1  LIKE rlgrap-filename
                   DEFAULT text-154 LOWER CASE MODIF ID ftb.
SELECTION-SCREEN END OF LINE.
**---------------------------------------------------------
*SELECTION-SCREEN: COMMENT 3(76) 'Folder'.
*SELECTION-SCREEN: COMMENT /1(60) s_cmt MODIF ID cm1.

********Define Upload/download Options

SELECTION-SCREEN: SKIP 1.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: ovrwrt AS CHECKBOX USER-COMMAND up1.
SELECTION-SCREEN COMMENT 3(60) text-009 FOR FIELD ovrwrt.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: testrun   AS CHECKBOX USER-COMMAND up2.
SELECTION-SCREEN COMMENT 3(60) text-117 FOR FIELD testrun.
SELECTION-SCREEN: END OF LINE.


**************************************
*****New Check box for Skip Validation
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: skipval   AS CHECKBOX .
SELECTION-SCREEN COMMENT 3(20) text-155 FOR FIELD skipval.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 1.
**************************************
SELECTION-SCREEN: END OF BLOCK 1st.


**********************New Block*************
SELECTION-SCREEN: BEGIN OF BLOCK 2nd WITH FRAME TITLE text-158.

SELECTION-SCREEN: SKIP 1.
**************************************
*****New Check box for Mitigation Header Data
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: mithead  AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(25) text-156 FOR FIELD mithead.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 1.
**************************************

*Mitigation Header
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(28) text-013 FOR FIELD p_mithf.
PARAMETER: p_mithf  LIKE rlgrap-filename LOWER CASE.
SELECTION-SCREEN: END OF LINE.

*Mitigation Texts
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(28) text-003 FOR FIELD p_mitxf.
PARAMETER: p_mitxf  LIKE rlgrap-filename LOWER CASE.
SELECTION-SCREEN: END OF LINE.

*Mitigation Transactions
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(28) text-014 FOR FIELD p_mitdf.
PARAMETER: p_mitdf  LIKE rlgrap-filename LOWER CASE.
SELECTION-SCREEN: END OF LINE.

*Mitigation Reports
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(28) text-017 FOR FIELD p_mitrf.
PARAMETER: p_mitrf LIKE rlgrap-filename LOWER CASE.
SELECTION-SCREEN: END OF LINE.

*Mitigation Auditors
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(28) text-018 FOR FIELD p_mitaf.
PARAMETER: p_mitaf LIKE rlgrap-filename LOWER CASE.
SELECTION-SCREEN: END OF LINE.

"Begin changes DDHIMAN 19.11.18
*Mitigation Review Header
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(28) text-179 FOR FIELD p_mitrhd.
PARAMETER: p_mitrhd LIKE rlgrap-filename LOWER CASE.
SELECTION-SCREEN: END OF LINE.
"End changes DDHIMAN 19.11.18
SELECTION-SCREEN: SKIP 1.
********************************************************************
SELECTION-SCREEN: BEGIN OF BLOCK vrsio WITH FRAME TITLE text-b00.
PARAMETERS :   sodvrsio LIKE /psyng/conflict-vrsio MEMORY
              ID /psyng/vrsio.
SELECTION-SCREEN: END OF BLOCK vrsio.

**************************************
*****New Check box for User Assignment
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: p_usassn  AS CHECKBOX.
***************************************
*
*
*SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(28) text-159  FOR FIELD p_usassn.
PARAMETER: p_usasfl  LIKE rlgrap-filename LOWER CASE.
SELECTION-SCREEN: END OF LINE.
********************************************************************
**************************************
******New Check box for User Group Assignment
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: p_usrgrp  AS CHECKBOX.
***************************************
*
*
*SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(28) text-161 FOR FIELD p_usrgrp.
PARAMETER: p_usgrpf  LIKE rlgrap-filename LOWER CASE.
SELECTION-SCREEN: END OF LINE.
*********************************************************************
******New Check box for Role Assignment
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: p_rlassn  AS CHECKBOX.
***************************************
*
*
*SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(28) text-163 FOR FIELD p_rlassn.
PARAMETER: p_rlassf  LIKE rlgrap-filename LOWER CASE.
SELECTION-SCREEN: END OF LINE.

***************************************
******New Check box for Critical Auth Assignment
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: p_crassn  AS CHECKBOX.
***************************************

**Mitigation Header
*SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(28) text-165 FOR FIELD p_crassn.
PARAMETER: p_crtfl  LIKE rlgrap-filename LOWER CASE.
SELECTION-SCREEN: END OF LINE.

***************************************
******New Check box for Critical Auth Role Assignment
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: p_crtrol  AS CHECKBOX.
***************************************

**Mitigation Header
*SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(28) text-176 FOR FIELD p_crtrol.
PARAMETER: p_crrlfl  LIKE rlgrap-filename LOWER CASE.
SELECTION-SCREEN: END OF LINE.
*********************************************************************
***************************************
SELECTION-SCREEN: END OF BLOCK 2nd.

************************************************************************

*-------------------------- INITIALIZATION ----------------------------*
INITIALIZATION.
  MOVE text-037 TO p_mithf.
  MOVE text-039 TO p_mitxf.
  MOVE text-038 TO p_mitdf.
  MOVE text-040 TO p_mitrf.
  MOVE text-041 TO p_mitaf.
  "Begin changes DDHIMAN 19.11.18
  MOVE text-180 TO p_mitrhd.
  "End changes DDHIMAN 19.11.18
  MOVE text-160 TO p_usasfl.
  MOVE text-162 TO p_usgrpf.
  MOVE text-164 TO p_rlassf.
  MOVE text-166 TO p_crtfl.
  MOVE text-177 TO p_crrlfl.

  LOOP AT SCREEN.
    CHECK screen-name = 'TESTRUN' OR screen-name = 'OVRWRT'
        OR screen-name = 'SKIPVAL'.
    screen-input = 0.
    MODIFY SCREEN.
  ENDLOOP.

*------------------------ AT SELECTION-SCREEN -------------------------*
AT SELECTION-SCREEN.
  g_ucomm = sy-ucomm.

*-------------------- AT SELECTION-SCREEN OUTPUT ----------------------*
AT SELECTION-SCREEN OUTPUT.
*  s_cmt = text-173.
*  IF g_ucomm = 'UPDN'.
  IF dnldtabs = 'X' .
    LOOP AT SCREEN.
      CHECK screen-name = 'TESTRUN' OR screen-name = 'OVRWRT'
      OR screen-name = 'SKIPVAL'.
      screen-input = 0.
      MODIFY SCREEN.
    ENDLOOP.
    CLEAR testrun.
  ELSEIF upldtabs EQ 'X'.
    LOOP AT SCREEN.
      CHECK screen-name = 'TESTRUN' OR screen-name = 'OVRWRT'
      OR screen-name = 'SKIPVAL'.
      screen-input = 1.
      MODIFY SCREEN.
    ENDLOOP.

  ENDIF.
*  ENDIF.
  LOOP AT SCREEN.
    IF screen-group1 = 'CM1'.
      screen-intensified = '1'.
      MODIFY SCREEN.
      CONTINUE.
    ENDIF.
  ENDLOOP.

*  LOOP AT SCREEN.
*    CASE g_ucomm.
*      WHEN 'UP1'.
*        CLEAR testrun.
*        MODIFY SCREEN.
*        CONTINUE.
*      WHEN 'UP2'.
*        CLEAR ovrwrt.
*        MODIFY SCREEN.
*        CONTINUE.
**   when 'UPLD'.
*
*
*    ENDCASE.
*  ENDLOOP.
*   IF g_ucomm = 'UP1'.
**    IF testrun = 'X'.
**      CLEAR ovrwrt.
*    ELSEIF ovrwrt = 'X'.
*      CLEAR testrun.
*    ENDIF.
*    MODIFY SCREEN.
*  ENDLOOP.

  LOOP AT SCREEN.
    IF screen-group1 = 'CM1'.
      screen-intensified = '1'.
      MODIFY SCREEN.
      CONTINUE.
    ENDIF.
  ENDLOOP.

*  DATA:l_len TYPE i,
*       l_val.
*  CHECK path1 NE space.
*  l_len = strlen( path1 ).
*  l_len = l_len - 1.
*  l_val = path1+l_len(1).
*  IF l_val EQ '\'.
*
*  ENDIF.


**************************Folder view
AT SELECTION-SCREEN ON VALUE-REQUEST FOR path1.

  PERFORM select_folder CHANGING path1.
*  CHECK path1 NE space.
*  l_len = strlen( path1 ).
*  l_len = l_len - 1.
*  l_val = path1+l_len(1).
*  IF l_val NE '\'.
*    CONCATENATE path1 '\' INTO path1.
*  ENDIF.

  CONCATENATE path1 text-037 INTO p_mithf.
  CONCATENATE path1 text-039 INTO p_mitxf.
  CONCATENATE path1 text-038 INTO p_mitdf.
  CONCATENATE path1 text-040 INTO p_mitrf.
  CONCATENATE path1 text-041 INTO p_mitaf.
  "Begin changes DDHIMAN 19.11.18
  CONCATENATE path1 text-180 INTO p_mitrhd.
  "End changes DDHIMAN 19.11.18
  CONCATENATE path1 text-160 INTO p_usasfl.
  CONCATENATE path1 text-162 INTO p_usgrpf.
  CONCATENATE path1 text-164 INTO p_rlassf.
  CONCATENATE path1 text-166 INTO p_crtfl.
  CONCATENATE path1 text-177 INTO p_crrlfl.

*--------------- AT SELECTION-SCREEN ON VALUE-REQUEST -----------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_mithf.
  PERFORM file_select CHANGING p_mithf gf_upld_r_dwld.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_mitxf.
  PERFORM file_select CHANGING p_mitxf gf_upld_r_dwld.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_mitdf.
  PERFORM file_select CHANGING p_mitdf gf_upld_r_dwld.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_mitrf.
  PERFORM file_select CHANGING p_mitrf gf_upld_r_dwld.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_mitaf.
  PERFORM file_select CHANGING p_mitaf gf_upld_r_dwld.

  "Begin changes DDHIMAN 19.11.18

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_mitrhd.
  PERFORM file_select CHANGING p_mitrhd gf_upld_r_dwld.
  "End changes DDHIMAN 19.11.18

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_usasfl.
  PERFORM file_select CHANGING p_usasfl gf_upld_r_dwld.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_usgrpf.
  PERFORM file_select CHANGING p_usgrpf gf_upld_r_dwld.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_rlassf.
  PERFORM file_select CHANGING p_rlassf gf_upld_r_dwld.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_crtfl.
  PERFORM file_select CHANGING p_crtfl gf_upld_r_dwld.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_crrlfl.
  PERFORM file_select CHANGING p_crrlfl gf_upld_r_dwld.

*------------------------ START-OF-SELECTION -------------------------*
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
  exelog sy-repid ''.
  DEFINE translate_line.
    translate &1 to upper case.
    translate &2 to upper case.
    translate &3 to upper case.
    translate &4 to upper case.
  END-OF-DEFINITION.



  DATA:l_len TYPE i,
       l_val.
  IF path1 IS INITIAL.
    MESSAGE s113(/psyng/sw)  WITH text-174 .
    LEAVE LIST-PROCESSING.
  ELSE.
    l_len = strlen( path1 ).
    l_len = l_len - 1.
    l_val = path1+l_len(1).
    IF l_val EQ '\'.
      l_len = strlen( path1 ).
      l_len = l_len - 2.
      l_val = path1+l_len(1).
      IF l_val EQ '\'.
        MESSAGE s113(/psyng/sw) WITH text-174 text-175 .
        LEAVE LIST-PROCESSING.
      ENDIF.
    ELSE.
      CONCATENATE path1 '\' INTO path1.
    ENDIF.
  ENDIF.
********SOD VERSION
  CALL FUNCTION '/PSYNG/SW_034'
       IMPORTING
            e_vrsio = g_sod_vrsio.

  IF dnldtabs EQ 'X'.
    PERFORM download_mit_tables.
  ELSEIF upldtabs EQ 'X'.
    IF skipval EQ 'X'.
      PERFORM confirm_skip_validation.
    ENDIF.
    PERFORM upload_mit_tables.
  ENDIF.

*&---------------------------------------------------------------------*
*&      Form  FILE_SELECT
*&---------------------------------------------------------------------*
*       Call open file dialog
*----------------------------------------------------------------------*
*      <--I_FILENAME          File name
*      <--I_FLAG_UPLD_R_DWLD  Upload/download flag
*----------------------------------------------------------------------*
FORM file_select CHANGING e_filename TYPE rlgrap-filename
                          i_flag_upld_r_dwld.
  DATA: l_uaction   TYPE i,
        l_title     TYPE string,
        l_filetable TYPE filetable,
        l_def_fname TYPE string,
        l_init_dir  TYPE string.
  DATA: l_path TYPE string,
        l_fullpath TYPE string,
        l_result TYPE i.
  l_def_fname = e_filename.
  IF dnldtabs EQ 'X'.
    CLEAR i_flag_upld_r_dwld.
  ELSEIF upldtabs EQ 'X'.
    i_flag_upld_r_dwld = 'X'.
  ENDIF.

  IF i_flag_upld_r_dwld NE 'X'.
    l_title = text-080.
    CALL METHOD cl_gui_frontend_services=>file_save_dialog
"#EC SAST_CI_GEN_CHECK (HBHALLA)
      EXPORTING
           window_title            = l_title
           default_extension       = 'txt'
           default_file_name        = l_def_fname
           file_filter             = '*.txt'
           initial_directory       = l_init_dir
      CHANGING
        filename          = l_def_fname
        path              = l_path
        fullpath          = l_fullpath
        user_action       = l_result
      EXCEPTIONS
        cntl_error        = 1
        error_no_gui      = 2
        OTHERS            = 3
            .
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

    ELSE.
      e_filename = l_def_fname.
    ENDIF.
  ELSE.
    l_title = text-079.

    CALL METHOD cl_gui_frontend_services=>file_open_dialog
"#EC SAST_CI_GEN_CHECK (HBHALLA)
       EXPORTING
         window_title            = l_title
         default_extension       = 'txt'
         default_filename        = l_def_fname
         file_filter             = '*.txt'
         initial_directory       = l_init_dir
       CHANGING
         file_table              = l_filetable
         rc                      = l_uaction
       EXCEPTIONS
         file_open_dialog_failed = 1
         cntl_error              = 2
         error_no_gui            = 3
         OTHERS                  = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
      READ TABLE l_filetable INDEX 1 INTO e_filename.
      DO.
        SEARCH e_filename FOR '\' .
        IF sy-subrc EQ 0.
          sy-fdpos = sy-fdpos + 1.
          e_filename = e_filename+sy-fdpos(*).
        ELSE.
          EXIT.
        ENDIF.
      ENDDO.
    ENDIF.
  ENDIF.

ENDFORM.                    " FILE_SELECT

*&---------------------------------------------------------------------*
*&      Form  authority_check
*&---------------------------------------------------------------------*
*       Check authority
*----------------------------------------------------------------------*
*      -->I_ACTIVITY  Activity
*      -->I_MCID      Mitigation control ID
*----------------------------------------------------------------------*
FORM authority_check USING    i_activity
                              i_mcid TYPE /psyng/mchdr-contid.
  DATA: l_actvt_txt(11).     "activity text


  CHECK NOT i_activity IS INITIAL.
  IF NOT i_mcid IS INITIAL.
    AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
             ID 'ACTVT'      FIELD i_activity
             ID 'Y&SW_CNTID' FIELD i_mcid
             ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e95).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ELSE.
    AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
             ID 'ACTVT'      FIELD i_activity
             ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e95).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ENDIF.

  IF sy-subrc NE 0.
    CASE i_activity.
      WHEN 'DL'.
        l_actvt_txt = text-139.
      WHEN 'UL'.
        l_actvt_txt = text-140.
      WHEN OTHERS.
        CLEAR l_actvt_txt.
    ENDCASE.

*   You are not authorizied for & & &
    IF NOT i_mcid IS INITIAL.
      MESSAGE e108(/psyng/sw) WITH l_actvt_txt i_mcid.
    ELSE.
      MESSAGE e108(/psyng/sw) WITH l_actvt_txt text-055.
    ENDIF.
  ENDIF.
ENDFORM.                    " authority_check

*&---------------------------------------------------------------------*
*&      Form  download_mit_tables
*&---------------------------------------------------------------------*
*       Download tables
*----------------------------------------------------------------------*
FORM download_mit_tables.
  DATA: l_downloadfailed(3) TYPE c,
        lt_mtexts           TYPE TABLE OF /psyng/texts WITH HEADER LINE.
  DATA: l_obj(10),
        l_actvt(2),
        l_file(30),
        l_vrsio(5).
  DATA:   lt_mchdr TYPE TABLE OF /psyng/mchdr.
  DATA:   lt_mctran TYPE TABLE OF /psyng/mctran.
  DATA:   lt_mcrepid TYPE TABLE OF  /psyng/mcrepid.
  DATA:   lt_mcauditor TYPE TABLE OF  /psyng/mcauditor.
  DATA:   lt_mcuser TYPE TABLE OF  /psyng/mcuser.
  DATA:   lt_mcusrgrp TYPE TABLE OF  /psyng/mcusrgrp.
  DATA:   lt_mccauser TYPE TABLE OF  /psyng/mccauser.
  DATA:   lt_mcrole TYPE TABLE OF  /psyng/mcrole,
          lt_mccarole TYPE TABLE OF /psyng/mccarole,
          l_xtab      TYPE x VALUE '09',
          l_tabchar   TYPE c.
  "Begin changes DDHIMAN 19.11.18
  DATA:   lt_mcrvwhdr TYPE TABLE OF /psyng/mcrvwhdr.
  "End changes DDHIMAN 19.11.18
  DATA: BEGIN OF lt_mittexts OCCURS 0 ,
        mandt TYPE sy-mandt,
        contid TYPE /psyng/mchdr-contid,
        object TYPE /psyng/texts-object,
        spras TYPE /psyng/texts-spras,
        line TYPE /psyng/texts-line,
        vrsio TYPE /psyng/texts-vrsio,
        text TYPE /psyng/texts-text,
        END OF lt_mittexts.

  FIELD-SYMBOLS: <tab> TYPE ANY.


  IF ( p_usassn IS INITIAL AND
p_usrgrp IS INITIAL AND
mithead IS INITIAL AND
p_crassn IS INITIAL AND
p_rlassn IS INITIAL AND
p_crtrol IS INITIAL ).
    MESSAGE s135(/psyng/sw) WITH 'Please select a file first'(s01).
    LEAVE LIST-PROCESSING.
  ENDIF.

  IF mithead EQ 'X'.
    ASSIGN l_tabchar TO <tab> CASTING TYPE x.
    <tab> = l_xtab.

    PERFORM authority_check USING gc_act_download /psyng/mchdr-contid.
    SELECT * FROM /psyng/mchdr INTO TABLE lt_mchdr.
    SELECT * FROM /psyng/mctran INTO TABLE lt_mctran.
    SELECT * FROM /psyng/mcrepid INTO TABLE lt_mcrepid.
    SELECT * FROM /psyng/mcauditor INTO TABLE lt_mcauditor.
    "Begin changes DDHIMAN 19.11.18
    SELECT * FROM /psyng/mcrvwhdr INTO TABLE lt_mcrvwhdr.
    "End changes DDHIMAN 19.11.18
    SELECT * FROM /psyng/texts INTO TABLE lt_mtexts     "#EC CI_NOFIRST
          WHERE object = 'M'
*          AND spras = sy-langu
          .
    SORT lt_mtexts BY textname ASCENDING line ASCENDING.
    LOOP AT lt_mtexts.
      MOVE-CORRESPONDING lt_mtexts TO lt_mittexts.
      lt_mittexts-contid = lt_mtexts-textname(12).

*     Remove any tab characters from the text
      DO.
        SEARCH lt_mittexts-text FOR l_tabchar.

        IF sy-subrc <> 0.
          EXIT.
        ELSE.
          CLEAR lt_mittexts-text+sy-fdpos(1).
        ENDIF.
      ENDDO.

      APPEND lt_mittexts.
    ENDLOOP.


    SORT: lt_mchdr, lt_mctran, lt_mcrepid, lt_mcauditor, lt_mittexts.
    PERFORM download TABLES lt_mittexts
                     USING p_mitxf text-022 gc_mittext_tab
                     CHANGING l_downloadfailed.

    PERFORM download TABLES lt_mchdr
                     USING p_mithf text-023 gc_mithdr_tab
                     CHANGING l_downloadfailed.

    PERFORM download TABLES lt_mctran
                     USING p_mitdf text-024 gc_mittran_tab
                     CHANGING l_downloadfailed.

    PERFORM download TABLES lt_mcrepid
                     USING p_mitrf text-025 gc_mitrep_tab
                     CHANGING l_downloadfailed.

    PERFORM download TABLES lt_mcauditor
                     USING p_mitaf text-026 gc_mitaud_tab
                     CHANGING l_downloadfailed.

    "Begin changes DDHIMAN 19.11.18
    PERFORM download TABLES lt_mcrvwhdr
                     USING p_mitrhd text-181 gc_mitrvhdr_tab
                     CHANGING l_downloadfailed.
    "End changes DDHIMAN 19.11.18
  ENDIF.

  l_vrsio = g_sod_vrsio.
  l_actvt = gc_act_download.

  IF p_usassn = 'X'.
    l_obj = 'Y&SW_MITG'.
    g_file_name = p_usasfl.
    PERFORM authority_check_ex USING l_obj l_actvt.

    IF gf_err IS INITIAL.
*      IF sodvrsio IS INITIAL.
*        SELECT * FROM /psyng/mcuser INTO TABLE lt_mcuser.
*      ELSE.
        SELECT * FROM /psyng/mcuser INTO TABLE lt_mcuser
            WHERE vrsio = sodvrsio.
*      ENDIF.
      SORT lt_mcuser.
      PERFORM download TABLES lt_mcuser
                       USING p_usasfl text-167 gc_mituser_tab
                       CHANGING l_downloadfailed.
    ENDIF.
  ENDIF.

  IF p_usrgrp = 'X'.
    l_obj = 'Y&SW_MCUG'.
    g_file_name = p_usgrpf.
    PERFORM authority_check_ex USING l_obj l_actvt.

    IF gf_err IS INITIAL.
*      IF sodvrsio IS INITIAL.
*        SELECT * FROM /psyng/mcusrgrp  INTO TABLE lt_mcusrgrp.
*      ELSE.
        SELECT * FROM /psyng/mcusrgrp  INTO TABLE lt_mcusrgrp
        WHERE vrsio = sodvrsio.
*      ENDIF.
      SORT lt_mcusrgrp.
      PERFORM download TABLES lt_mcusrgrp
                       USING p_usgrpf text-168 gc_mitgrp_tab
                       CHANGING l_downloadfailed.
    ENDIF.
  ENDIF.

  IF p_rlassn = 'X'.
    l_obj = 'Y&SW_MCROL'.
    g_file_name = p_rlassf.
    PERFORM authority_check_ex USING l_obj l_actvt.

    IF gf_err IS INITIAL.
*      IF sodvrsio IS INITIAL.
*        SELECT * FROM /psyng/mcrole INTO TABLE lt_mcrole.
*      ELSE.
        SELECT * FROM /psyng/mcrole INTO TABLE lt_mcrole
        WHERE vrsio =  sodvrsio.
*      ENDIF.
      SORT lt_mcrole.
      PERFORM download TABLES lt_mcrole
                        USING p_rlassf text-169 gc_mitrole_tab
                        CHANGING l_downloadfailed.
    ENDIF.
  ENDIF.
  IF p_crassn = 'X'.
    l_obj = 'Y&SW_MCCAU'.
    g_file_name = p_crtfl.
    PERFORM authority_check_ex USING l_obj l_actvt.

    IF gf_err IS INITIAL.
*      IF sodvrsio IS INITIAL.
*        SELECT * FROM /psyng/mccauser INTO TABLE lt_mccauser.
*      ELSE.
     SELECT * FROM /psyng/mccauser INTO TABLE lt_mccauser WHERE vrsio =
            sodvrsio.
*      ENDIF.
      SORT lt_mccauser.
      PERFORM download TABLES lt_mccauser
                       USING p_crtfl text-170 gc_mitcau_tab
                       CHANGING l_downloadfailed.
    ENDIF.
  ENDIF.
  IF p_crtrol = 'X'.
    l_obj = 'Y&SW_MCCAR'.
    g_file_name = p_crrlfl.
    PERFORM authority_check_ex USING l_obj l_actvt.

    IF gf_err IS INITIAL.
*      IF sodvrsio IS INITIAL.
*        SELECT * FROM /psyng/mccarole INTO TABLE lt_mccarole.
*      ELSE.
     SELECT * FROM /psyng/mccarole INTO TABLE lt_mccarole WHERE vrsio =
            sodvrsio.
*      ENDIF.
      SORT lt_mccarole.
      PERFORM download TABLES lt_mccarole
                       USING p_crrlfl text-178 gc_mitcar_tab
                       CHANGING l_downloadfailed.
    ENDIF.
  ENDIF.

  CHECK NOT gt_output[] IS INITIAL.
  SORT gt_output BY sort_file l_index ASCENDING.
  PERFORM output.

ENDFORM.                    " download_mit_tables

*&---------------------------------------------------------------------*
*&      Form  download
*&---------------------------------------------------------------------*
*       Download to file
*----------------------------------------------------------------------*
*      -->IT_TABLE          Table to download
*      -->I_FILENAME        File name
*      -->I_ERR_TEXT        Error message (in case of failure)
*      <--E_DOWNLOADFAILED  Download failed flag
*----------------------------------------------------------------------*
FORM download TABLES   it_table
              USING    i_filename TYPE rlgrap-filename
                       i_err_text
                       i_tabname TYPE dd02l-tabname
              CHANGING e_downloadfailed.
  DATA: l_filename TYPE string.
  DATA:l_len TYPE i,
       l_val.


  DATA: alv_fldcat TYPE slis_t_fieldcat_alv,
        it_fldcat TYPE lvc_t_fcat.



  DATA : it_details TYPE abap_compdescr_tab,
         wa_details TYPE abap_compdescr.

  DATA : ref_descr TYPE REF TO cl_abap_structdescr.

  DATA: lt_new_table TYPE REF TO data,
        ls_new_line  TYPE REF TO data,
        wa_it_fldcat TYPE lvc_s_fcat,
        curr_line TYPE i.

  FIELD-SYMBOLS: <dyn_table> TYPE STANDARD TABLE,
  <dyn_wa>,
  <dyn_field>,
  <dyn_wa1>,
  <fields> TYPE dbfield.

  DATA : l_tabname TYPE dd02l-tabname,
         lt_fields TYPE TABLE OF dbfield WITH HEADER LINE.


  l_tabname = i_tabname.

  ref_descr ?= cl_abap_typedescr=>describe_by_name( i_tabname ).
  it_details[] = ref_descr->components[].

  LOOP AT it_details INTO wa_details.
    CLEAR wa_it_fldcat.
    wa_it_fldcat-fieldname = wa_details-name .
    APPEND wa_it_fldcat TO it_fldcat .

    lt_fields-name = wa_details-name.
    APPEND lt_fields.

  ENDLOOP.

*Create dynamic internal table and assign to FS
  CALL METHOD cl_alv_table_create=>create_dynamic_table
               EXPORTING
                  it_fieldcatalog = it_fldcat
               IMPORTING
                  ep_table        = lt_new_table.

  ASSIGN lt_new_table->* TO <dyn_table>.
  CREATE DATA ls_new_line LIKE LINE OF <dyn_table>.
  ASSIGN ls_new_line->* TO <dyn_wa>.

**Assigning fields values to work areaa
  LOOP AT lt_fields ASSIGNING <fields>.
    curr_line = sy-tabix.
    ASSIGN COMPONENT sy-tabix OF STRUCTURE <dyn_wa> TO <dyn_wa1>.
    <dyn_wa1> = <fields>.
  ENDLOOP.

  INSERT <dyn_wa> INTO <dyn_table> INDEX 1.

  g_file_name = i_filename.
  CONCATENATE path1 i_filename INTO l_filename.
  CONDENSE l_filename NO-GAPS.

***For Header
*BOC:HBHALLA (096)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '61'.
  IF sy-subrc = 0.
  CALL FUNCTION 'GUI_DOWNLOAD' "#EC SAST_CI_GEN_CHECK
       EXPORTING
            filename                = l_filename
            filetype                = 'ASC'
            append                  = space
            write_field_separator   = 'X'
       TABLES
            data_tab                = <dyn_table>
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
  ENDIF.
*EOC:HBHALLA (096)
*** Data
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
            append                  = 'X'
       TABLES
            data_tab                = it_table
*           fieldnames               = it_head[]
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
    e_downloadfailed = text-073.
*    PERFORM handle_download_error USING sy-subrc l_filename i_err_text.
*        PERFORM download_status USING sy-subrc l_filename i_err_text.
    gf_err = 'E'.
    g_err_msg = i_err_text.
    PERFORM append_output USING i_filename gf_err g_field
                                g_err_value g_err_msg.
  ELSE.
    CLEAR gf_err.
    g_err_msg = text-045.
    g_file_name = l_filename.
    DESCRIBE TABLE it_table LINES g_index.
    PERFORM append_output USING i_filename gf_err g_field
                                g_err_value g_err_msg.
  ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
ENDFORM.                    " download

*&---------------------------------------------------------------------*
*&      Form  handle_download_error
*&---------------------------------------------------------------------*
*       Output proper error message for download
*----------------------------------------------------------------------*
*      -->I_SUBRC     Return code
*      -->I_FILENAME  File name
*      -->I_MSG       Error message
*----------------------------------------------------------------------*
FORM handle_download_error USING    i_subrc TYPE sy-subrc
                                    i_filename TYPE string
                                    i_msg.

  CASE i_subrc.
    WHEN 1.
      MESSAGE i041(/psyng/basis) WITH i_filename i_msg.
    WHEN 2.
      MESSAGE i042(/psyng/basis) WITH i_filename i_msg.
    WHEN 3.
      MESSAGE i043(/psyng/basis) WITH i_filename i_msg.
    WHEN 4.
      MESSAGE i044(/psyng/basis) WITH i_filename i_msg.
    WHEN 5.
      MESSAGE i045(/psyng/basis) WITH i_filename i_msg.
    WHEN 6.
      MESSAGE i046(/psyng/basis) WITH i_filename i_msg.
    WHEN 7 OR 22.
      MESSAGE i047(/psyng/basis) WITH i_filename i_msg.
    WHEN 8.
      MESSAGE i048(/psyng/basis) WITH i_filename i_msg.
    WHEN 9.
      MESSAGE i049(/psyng/basis) WITH i_filename i_msg.
    WHEN 10.
      MESSAGE i050(/psyng/basis) WITH i_filename i_msg.
    WHEN 11.
      MESSAGE i051(/psyng/basis) WITH i_filename i_msg.
    WHEN 12.
      MESSAGE i052(/psyng/basis) WITH i_filename i_msg.
    WHEN 13.
      MESSAGE i053(/psyng/basis) WITH i_filename i_msg.
    WHEN 14.
      MESSAGE i054(/psyng/basis) WITH i_filename i_msg.
    WHEN 15.
      MESSAGE i055(/psyng/basis) WITH i_filename i_msg.
    WHEN 16.
      MESSAGE i056(/psyng/basis) WITH i_filename i_msg.
    WHEN 17.
      MESSAGE i057(/psyng/basis) WITH i_filename i_msg.
    WHEN 18.
      MESSAGE i058(/psyng/basis) WITH i_filename i_msg.
    WHEN 19.
      MESSAGE i059(/psyng/basis) WITH i_filename i_msg.
    WHEN 20.
      MESSAGE i060(/psyng/basis) WITH i_filename i_msg.
    WHEN 21.
      MESSAGE i061(/psyng/basis) WITH i_filename i_msg.
  ENDCASE.
ENDFORM.                    " handle_download_error

*&---------------------------------------------------------------------*
*&      Form  upload_mit_tables
*&---------------------------------------------------------------------*
*       Upload to database
*----------------------------------------------------------------------*
FORM upload_mit_tables.
  TABLES:/psyng/mcuser.

  DATA: BEGIN OF lt_cont OCCURS 0,
          contid TYPE /psyng/mchdr-contid,
        END OF lt_cont.

  DATA: l_uploadfailed(3) TYPE c,
      lt_mchdr_del      TYPE TABLE OF /psyng/mchdr     WITH HEADER LINE,
      lt_mctran_del     TYPE TABLE OF /psyng/mctran    WITH HEADER LINE,
      lt_mcrepid_del    TYPE TABLE OF /psyng/mcrepid   WITH HEADER LINE,
      lt_mcauditor_del  TYPE TABLE OF /psyng/mcauditor WITH HEADER LINE,
      lt_texts          TYPE TABLE OF /psyng/texts     WITH HEADER LINE,
      lt_mcauditor      TYPE TABLE OF /psyng/mcauditor WITH HEADER LINE,
      lt_mctran         TYPE TABLE OF /psyng/mctran    WITH HEADER LINE,
      lt_mcrepid        TYPE TABLE OF /psyng/mcrepid   WITH HEADER LINE,
      lt_mcuser         TYPE TABLE OF /psyng/mcuser    WITH HEADER LINE,
      lt_mcuser_save    TYPE TABLE OF /psyng/mcuser    WITH HEADER LINE,
      lt_mcusrgrp       TYPE TABLE OF /psyng/mcusrgrp  WITH HEADER LINE,
      lt_mcusrgrp_save  TYPE TABLE OF /psyng/mcusrgrp  WITH HEADER LINE,
      lt_mcrole         TYPE TABLE OF /psyng/mcrole    WITH HEADER LINE,
      lt_mcrole_save    TYPE TABLE OF /psyng/mcrole    WITH HEADER LINE,
      lt_mccauser       TYPE TABLE OF /psyng/mccauser  WITH HEADER LINE,
      lt_mccauser_save  TYPE TABLE OF /psyng/mccauser  WITH HEADER LINE,
      lt_mccarole       TYPE TABLE OF /psyng/mccarole  WITH HEADER LINE,
      lt_mccarole_save  TYPE TABLE OF /psyng/mccarole  WITH HEADER LINE,
      lt_mcuser_del     TYPE TABLE OF /psyng/mcuser    WITH HEADER LINE,
      lt_mcusrgrp_del   TYPE TABLE OF /psyng/mcusrgrp  WITH HEADER LINE,
      lt_mcrole_del     TYPE TABLE OF /psyng/mcrole    WITH HEADER LINE,
      lt_mccauser_del   TYPE TABLE OF /psyng/mccauser  WITH HEADER LINE,
      lt_mccarole_del   TYPE TABLE OF /psyng/mccarole  WITH HEADER LINE.

  DATA: ls_mchdr LIKE LINE OF gt_mchdr,
        ls_mchdr_save TYPE /psyng/mchdr,
        ls_mctran LIKE LINE OF gt_mctran,
        ls_mcrepid LIKE LINE OF gt_mcrepid,
        ls_mcauditor LIKE LINE OF gt_mcauditor,
        ls_mcuser LIKE LINE OF gt_mcuser,
        ls_mcusrgrp LIKE LINE OF gt_mcusrgrp,
        ls_mccauser LIKE LINE OF gt_mccauser,
        ls_mccarole LIKE LINE OF gt_mccarole,
        ls_mcrole LIKE LINE OF gt_mcrole,
        ls_mittexts LIKE LINE OF gt_mittexts,
        ls_mchdr_assign TYPE /psyng/mchdr.
  "Begin changes DDHIMAN 19.11.18
  DATA: lt_mcrvwhdr_del  TYPE TABLE OF /psyng/mcrvwhdr WITH HEADER LINE,
        lt_mcrvwhdr  TYPE TABLE OF /psyng/mcrvwhdr   WITH HEADER LINE,
        ls_mcrhdr TYPE /psyng/mcrvwhdr,
        ls_mcrhdr_save TYPE /psyng/mcrvwhdr.
  "End changes DDHIMAN 19.11.18
  DATA:l_index TYPE i.
  DATA: err_msg(60) TYPE c,
        err_value(20) TYPE c.
  DATA:l_field(20) TYPE c,
       l_answer.



*  DATA:ls_mcuser LIKE LINE OF gt_mcuser.
  DATA: base_index TYPE string,
        dupl_index TYPE string.
  DATA:lf_update TYPE c.
  DATA: l_act_upload(2)   VALUE 'UL'.    "upload activity
  DATA: l_obj(10),
        l_actvt(2),
        l_file(30),
        l_vrsio(5).

  IF ( p_usassn IS INITIAL AND
  p_usrgrp IS INITIAL AND
  mithead IS INITIAL AND
  p_crassn IS INITIAL AND
  p_rlassn IS INITIAL AND
  p_crtrol IS INITIAL ).
    MESSAGE s133(/psyng/sw) WITH 'Please select a file first'(s01).
    LEAVE LIST-PROCESSING.
  ENDIF.

  IF mithead EQ 'X'.
    PERFORM authority_check USING gc_act_upload /psyng/mchdr-contid.

    PERFORM upload TABLES gt_mchdr
                   USING p_mithf text-096.
    CLEAR:l_index, g_index.
    IF NOT gt_mchdr[] IS INITIAL.
********* Adding Index
      DELETE gt_mchdr WHERE contid EQ space.

      LOOP AT gt_mchdr.
        l_index = l_index + 1.
        gt_mchdr-l_index = l_index.
        MODIFY gt_mchdr.
      ENDLOOP.
      CLEAR l_index.
    ENDIF.

    IF gt_mchdr[] IS INITIAL.
      gf_err = 'W'.
      PERFORM append_output USING p_mithf 'W' ''
            '' 'Empty File'(150).
    ENDIF.
***************************************
***************************************
    PERFORM upload TABLES gt_mittexts
                   USING p_mitxf text-097.
    CLEAR:l_index, g_index.

** Mitigation Texts
    IF NOT gt_mittexts[] IS INITIAL.

      DELETE gt_mittexts WHERE contid EQ space.

      LOOP AT gt_mittexts.
        l_index = l_index + 1.
        gt_mittexts-l_index = l_index.
        MODIFY gt_mittexts.
      ENDLOOP.
      CLEAR l_index.
    ENDIF.

    IF gt_mittexts[] IS INITIAL.
      gf_err = 'W'.
      PERFORM append_output USING p_mitxf 'W' ''
            '' 'Empty File'(150).
    ENDIF.

** Mitigation Tcodes
    PERFORM upload TABLES gt_mctran
                   USING p_mitdf text-098.
    CLEAR:l_index, g_index.
    IF NOT gt_mctran[] IS INITIAL.
      DELETE gt_mctran WHERE contid EQ space.

      LOOP AT gt_mctran.
        l_index = l_index + 1.
        gt_mctran-l_index = l_index.
        MODIFY gt_mctran.
      ENDLOOP.
    ENDIF.

    IF gt_mctran[] IS INITIAL.
      gf_err = 'W'.
      PERFORM append_output USING p_mitdf 'W' ''
            '' 'Empty File'(150).
    ENDIF.

** Mitigation Reports
    PERFORM upload TABLES gt_mcrepid
                   USING p_mitrf text-099.
    CLEAR:l_index, g_index.
    IF NOT gt_mcrepid[] IS INITIAL.
      DELETE gt_mcrepid WHERE contid EQ space.

      LOOP AT gt_mcrepid.
        l_index = l_index + 1.
        gt_mcrepid-l_index = l_index.
        MODIFY gt_mcrepid.
      ENDLOOP.
    ENDIF.

    IF gt_mcrepid[] IS INITIAL.
      gf_err = 'W'.
      PERFORM append_output USING p_mitrf 'W' ''
            '' 'Empty File'(150).
    ENDIF.

** Mitigation Auditors
    PERFORM upload TABLES gt_mcauditor
                   USING p_mitaf text-100.
    CLEAR:l_index, g_index.
    IF NOT gt_mcauditor[] IS INITIAL.
      DELETE gt_mcauditor WHERE contid EQ space.

      LOOP AT gt_mcauditor.
        l_index = l_index + 1.
        gt_mcauditor-l_index = l_index.
        MODIFY gt_mcauditor.
      ENDLOOP.
      CLEAR l_index.
    ENDIF.
    IF gt_mcauditor[] IS INITIAL.
      gf_err = 'W'.
      PERFORM append_output USING p_mitaf 'W' ''
            '' 'Empty File'(150).
    ENDIF.

    "Begin changes DDHIMAN 19.11.18
** Mitigation Review Header
    PERFORM upload TABLES gt_mcrvwhdr
                   USING p_mitrhd text-183.
    CLEAR:l_index, g_index.
    IF NOT gt_mcrvwhdr[] IS INITIAL.
      DELETE gt_mcrvwhdr WHERE contid EQ space.

      LOOP AT gt_mcrvwhdr.
        l_index = l_index + 1.
        gt_mcrvwhdr-l_index = l_index.
        MODIFY gt_mcrvwhdr.
      ENDLOOP.
      CLEAR l_index.
    ENDIF.
    IF gt_mcrvwhdr[] IS INITIAL.
      gf_err = 'W'.
      PERFORM append_output USING p_mitrhd 'W' ''
            '' 'Empty File'(150).
    ENDIF.

    "End changes DDHIMAN 19.11.18
  ENDIF.

  l_vrsio = g_sod_vrsio.
  l_actvt = gc_act_upload.

*--User Assginment Upload
  IF p_usassn EQ 'X'.
    l_obj = 'Y&SW_MITG'.
    g_file_name = p_usasfl.
    PERFORM authority_check_ex USING l_obj l_actvt.
    IF gf_err EQ space.
      PERFORM upload TABLES gt_mcuser
                       USING p_usasfl text-267.
      CLEAR:l_index, g_index,gf_err.
      IF NOT gt_mcuser[] IS INITIAL.
        DELETE gt_mcuser WHERE contid EQ space.

        LOOP AT gt_mcuser.
          l_index = l_index + 1.
          gt_mcuser-l_index = l_index.
          translate_line gt_mcuser-contid
                         gt_mcuser-conid
                         gt_mcuser-userid
                         gt_mcuser-auditor.
          MODIFY gt_mcuser.
        ENDLOOP.
        CLEAR l_index.
      ENDIF.

      IF gt_mcuser[] IS INITIAL.
        gf_err = 'W'.
        PERFORM append_output USING p_usasfl 'W' ''
              '' 'Empty File'(150).
      ENDIF.
    ENDIF.
***************************************

  ENDIF.


********************************
*********User Group Upload
********************************
  IF p_usrgrp EQ 'X'.
    l_obj = 'Y&SW_MCUG'.
    g_file_name = p_usgrpf.
    PERFORM authority_check_ex USING l_obj l_actvt.
    IF gf_err EQ space.
      PERFORM upload TABLES gt_mcusrgrp
                       USING p_usgrpf text-268.
      CLEAR:l_index, g_index,gf_err.
      IF NOT gt_mcusrgrp[] IS INITIAL.

        DELETE gt_mcusrgrp WHERE contid EQ space.
        LOOP AT gt_mcusrgrp.
          l_index = l_index + 1.
          gt_mcusrgrp-l_index = l_index.

          translate_line gt_mcusrgrp-contid
                         gt_mcusrgrp-conid
                         gt_mcusrgrp-class
                         gt_mcusrgrp-auditor.
          MODIFY gt_mcusrgrp.
        ENDLOOP.
        CLEAR l_index.
      ENDIF.

      IF gt_mcusrgrp[] IS INITIAL.
        gf_err = 'W'.
        PERFORM append_output USING p_usgrpf 'W' ''
              '' 'Empty File'(150).
      ENDIF.
    ENDIF.
***************************************
  ENDIF.

********************************
*********Role Assginment Upload
********************************
  IF p_rlassn EQ 'X'.
    g_file_name = p_rlassf.
    l_obj = 'Y&SW_MCROL'.
    PERFORM authority_check_ex USING l_obj l_actvt.
    IF gf_err EQ space.
      PERFORM upload TABLES gt_mcrole
                       USING p_rlassf text-269.
      CLEAR:l_index, g_index,gf_err.
      IF NOT gt_mcrole[] IS INITIAL.
        DELETE gt_mcrole WHERE contid EQ space.

        LOOP AT gt_mcrole.
          l_index = l_index + 1.
          gt_mcrole-l_index = l_index.
          translate_line gt_mcrole-contid
                       gt_mcrole-conid
                       gt_mcrole-agr_name
                       gt_mcrole-auditor.
          MODIFY gt_mcrole.
        ENDLOOP.
        CLEAR l_index.
      ENDIF.

      IF gt_mcrole[] IS INITIAL.
        gf_err = 'W'.
        PERFORM append_output USING p_rlassf 'W' ''
              '' 'Empty File'(150).
      ENDIF.
    ENDIF.
***************************************
  ENDIF.
********************************
*********Critical Auth Assginment Upload
********************************
  IF p_crassn EQ 'X'.
    g_file_name = p_crtfl.
    l_file = text-165.
    l_obj = 'Y&SW_MCCAU'.
    PERFORM authority_check_ex USING l_obj l_actvt.
    IF gf_err EQ space.
      PERFORM upload TABLES gt_mccauser
                      USING p_crtfl text-270.
      CLEAR:l_index, g_index,gf_err.
      IF NOT gt_mccauser[] IS INITIAL.

        DELETE gt_mccauser WHERE contid EQ space.
        LOOP AT gt_mccauser.
          l_index = l_index + 1.
          gt_mccauser-l_index = l_index.
          translate_line gt_mccauser-contid
                         gt_mccauser-swaudid
                         gt_mccauser-userid
                         gt_mccauser-auditor.
          MODIFY gt_mccauser.
        ENDLOOP.
        CLEAR l_index.
      ENDIF.

      IF gt_mccauser[] IS INITIAL.
        gf_err = 'W'.
        PERFORM append_output USING p_crtfl 'W' ''
              '' 'Empty File'(150).
      ENDIF.
    ENDIF.
***************************************
  ENDIF.

********************************
*********Critical Auth Role Assginment Upload
********************************
  IF p_crtrol EQ 'X'.
    g_file_name = p_crrlfl.
    l_file = text-176.
    l_obj = 'Y&SW_MCCAR'.
    PERFORM authority_check_ex USING l_obj l_actvt.
    IF gf_err EQ space.
      PERFORM upload TABLES gt_mccarole
                      USING p_crrlfl text-271.
      CLEAR:l_index, g_index,gf_err.
      IF NOT gt_mccarole[] IS INITIAL.

        DELETE gt_mccarole WHERE contid EQ space.
        LOOP AT gt_mccarole.
          l_index = l_index + 1.
          gt_mccarole-l_index = l_index.
          translate_line gt_mccarole-contid
                         gt_mccarole-swaudid
                         gt_mccarole-agr_name
                         gt_mccarole-auditor.
          MODIFY gt_mccarole.
        ENDLOOP.
        CLEAR l_index.
      ENDIF.

      IF gt_mccarole[] IS INITIAL.
        gf_err = 'W'.
        PERFORM append_output USING p_crrlfl 'W' ''
              '' 'Empty File'(150).
      ENDIF.
    ENDIF.
***************************************
  ENDIF.

  IF skipval IS INITIAL.
    PERFORM validation.
  ENDIF.

****************************

*--The actual modifications to the database
  IF ovrwrt = 'X' .
    IF gt_mchdr[] IS INITIAL OR
       gt_mcuser[] IS INITIAL OR
       gt_mcusrgrp[] IS INITIAL OR
       gt_mcrole[] IS INITIAL OR
       gt_mccauser[] IS INITIAL OR
       "Begin changes DDHIMAN 19.11.18
       gt_mcrvwhdr[] IS INITIAL.
      "End changes DDHIMAN 19.11.18
      CALL FUNCTION 'POPUP_TO_CONFIRM'
           EXPORTING
                titlebar              = text-w04
                text_question         = text-w05
                text_button_1         = 'Yes'
                icon_button_1         = 'ICON_SYSTEM_OKAY'
                text_button_2         = 'No'
                icon_button_2         = 'ICON_SYSTEM_CANCEL'
                display_cancel_button = ' '
                popup_type            = 'ICON_MESSAGE_WARNING'
           IMPORTING
                answer                = l_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND = 1
             OTHERS         = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      IF l_answer = 2.
        LEAVE LIST-PROCESSING.
      ENDIF.
    ENDIF.

    IF mithead = 'X'.
      SELECT * FROM /psyng/mchdr INTO TABLE lt_mchdr_del.

      LOOP AT gt_nodel.
        DELETE lt_mchdr_del WHERE contid = gt_nodel-contid.
      ENDLOOP.

      LOOP AT lt_mchdr_del.
        g_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
          ID 'ACTVT' FIELD '06'
          ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
          ID 'Y&SW_CNTID' FIELD lt_mchdr_del-contid.
        IF sy-subrc <> 0.
          err_value = lt_mchdr_del-contid.
          err_msg = 'Not Authorized to delete mitigation'(e36).
          gf_err = 'E'.
          l_field = text-f01.
          PERFORM append_output USING g_file_name gf_err l_field
                                      err_value err_msg.
        ELSE.

          IF testrun = ' '.
            CALL FUNCTION '/PSYNG/SW_CR_DELETE_MIT_CTRL'
                 EXPORTING
                      i_contid       = lt_mchdr_del-contid
                 EXCEPTIONS
                      not_authorized = 1
                      not_exist      = 2
                      locked         = 3
                      OTHERS         = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.
    SELECT contid FROM /psyng/mchdr INTO TABLE gt_cont_ovr
   ORDER BY contid.

    IF p_usassn EQ 'X'.

      SELECT * FROM /psyng/mcuser INTO TABLE lt_mcuser_del.

      LOOP AT lt_mcuser_del.
        g_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
          ID 'ACTVT'      FIELD '06'
          ID 'Y&SW_VRSIO' FIELD lt_mcuser_del-vrsio
          ID 'Y&SW_CNTID' FIELD lt_mcuser_del-contid
          ID 'Y&SW_CONID' FIELD lt_mcuser_del-conid
          ID 'Y&SW_BNAME' FIELD lt_mcuser_del-userid
          ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)

        IF sy-subrc <> 0.
          err_value = lt_mchdr_del-contid.
          err_msg = 'Not Authorized to delete user assignment'(e40).
          gf_err = 'E'.
          l_field = text-f01.
          PERFORM append_output USING g_file_name gf_err l_field
                                      err_value err_msg.
        ELSE.

          IF testrun = ' '.

            MOVE-CORRESPONDING lt_mcuser_del TO ls_mchdr_assign.

            CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
                 EXPORTING
                      is_mchdr             = ls_mchdr_assign
                      if_del_assgn_only    = 'X'
                 TABLES
                      it_mcuser            = lt_mcuser_del
                 EXCEPTIONS
                      target_not_specified = 1
                      not_authorized       = 2
                      locked               = 3
                      OTHERS               = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
          ENDIF.

        ENDIF.
      ENDLOOP.
    ENDIF.

    IF p_usrgrp EQ 'X'.

      SELECT * FROM /psyng/mcusrgrp INTO TABLE lt_mcusrgrp_del.

      LOOP AT lt_mcusrgrp_del.
        g_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCUG'
             ID 'ACTVT'      FIELD '06'
             ID 'Y&SW_VRSIO' FIELD lt_mcusrgrp_del-vrsio
             ID 'Y&SW_CNTID' FIELD lt_mcusrgrp_del-contid
             ID 'Y&SW_CONID' FIELD lt_mcusrgrp_del-conid
             ID 'Y&SW_CLASS' FIELD lt_mcusrgrp_del-class.

        IF sy-subrc <> 0.
          err_value = lt_mchdr_del-contid.
         err_msg = 'Not Authorized to delete Usergroup assignment'(e41)
                                    .
          gf_err = 'E'.
          l_field = text-f01.
          PERFORM append_output USING g_file_name gf_err l_field
                                      err_value err_msg.
        ELSE.

          IF testrun = ' '.

            MOVE-CORRESPONDING lt_mcusrgrp_del TO ls_mchdr_assign.

            CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
                 EXPORTING
                      is_mchdr             = ls_mchdr_assign
                      if_del_assgn_only    = 'X'
                 TABLES
                      it_mcusrgrp          = lt_mcusrgrp_del
                 EXCEPTIONS
                      target_not_specified = 1
                      not_authorized       = 2
                      locked               = 3
                      OTHERS               = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
          ENDIF.

        ENDIF.
      ENDLOOP.
    ENDIF.

    IF p_rlassn EQ 'X'.

      SELECT * FROM /psyng/mcrole INTO TABLE lt_mcrole_del.

      LOOP AT lt_mcrole_del.
        g_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCROL'
                          ID 'ACTVT'      FIELD '06'
                          ID 'Y&SW_VRSIO' FIELD lt_mcrole_del-vrsio
                          ID 'Y&SW_CNTID' FIELD lt_mcrole_del-contid
                          ID 'Y&SW_CONID' FIELD lt_mcrole_del-conid
                          ID 'ACT_GROUP'  FIELD lt_mcrole_del-agr_name.


        IF sy-subrc <> 0.
          err_value = lt_mchdr_del-contid.
          err_msg = 'Not Authorized to delete Role assignment'(e42)
 .
          gf_err = 'E'.
          l_field = text-f01.
          PERFORM append_output USING g_file_name gf_err l_field
                                      err_value err_msg.
        ELSE.

          IF testrun = ' '.

            MOVE-CORRESPONDING lt_mcrole_del TO ls_mchdr_assign.

            CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
                 EXPORTING
                      is_mchdr             = ls_mchdr_assign
                      if_del_assgn_only    = 'X'
                 TABLES
                      it_mcrole            = lt_mcrole_del
                 EXCEPTIONS
                      target_not_specified = 1
                      not_authorized       = 2
                      locked               = 3
                      OTHERS               = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
          ENDIF.

        ENDIF.
      ENDLOOP.
    ENDIF.

    IF p_crassn EQ 'X'.

      SELECT * FROM /psyng/mccauser INTO TABLE lt_mccauser_del.

      LOOP AT lt_mccauser_del.
        g_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCCAU'
                 ID 'ACTVT'      FIELD '06'
                 ID 'Y&SW_VRSIO' FIELD lt_mccauser_del-vrsio
                 ID 'Y&SW_SWAUD' FIELD lt_mccauser_del-swaudid
                 ID 'Y&SW_CNTID' FIELD lt_mccauser_del-contid
                 ID 'Y&SW_BNAME' FIELD lt_mccauser_del-userid.


        IF sy-subrc <> 0.
          err_value = lt_mchdr_del-contid.
        err_msg = 'Not Authorized to delete Crit.Auth. assignment'(e43)
                                                                       .
          gf_err = 'E'.
          l_field = text-f01.
          PERFORM append_output USING g_file_name gf_err l_field
                                      err_value err_msg.
        ELSE.

          IF testrun = ' '.

            MOVE-CORRESPONDING lt_mccauser_del TO ls_mchdr_assign.

            CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
                 EXPORTING
                      is_mchdr             = ls_mchdr_assign
                      if_del_assgn_only    = 'X'
                 TABLES
                      it_mccauser          = lt_mccauser_del
                 EXCEPTIONS
                      target_not_specified = 1
                      not_authorized       = 2
                      locked               = 3
                      OTHERS               = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
          ENDIF.

        ENDIF.
      ENDLOOP.
    ENDIF.

    IF p_crtrol EQ 'X'.

      SELECT * FROM /psyng/mccarole INTO TABLE lt_mccarole_del.

      LOOP AT lt_mccarole_del.
        g_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCCAR'
                 ID 'ACTVT'      FIELD '06'
                 ID 'Y&SW_VRSIO' FIELD lt_mccarole_del-vrsio
                 ID 'Y&SW_SWAUD' FIELD lt_mccarole_del-swaudid
                 ID 'Y&SW_CNTID' FIELD lt_mccarole_del-contid
                 ID 'ACT_GROUP'  FIELD lt_mccarole_del-agr_name.
        IF sy-subrc <> 0.
          err_value = lt_mchdr_del-contid.
          err_msg =
             'Not Authorized to delete Crit.Auth. role assignment'(e44).
          gf_err = 'E'.
          l_field = text-f01.
          PERFORM append_output USING g_file_name gf_err l_field
                                      err_value err_msg.
        ELSE.

          IF testrun = ' '.

            MOVE-CORRESPONDING lt_mccarole_del TO ls_mchdr_assign.

            CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
                 EXPORTING
                      is_mchdr             = ls_mchdr_assign
                      if_del_assgn_only    = 'X'
                 TABLES
                      it_mccarole          = lt_mccarole_del
                 EXCEPTIONS
                      target_not_specified = 1
                      not_authorized       = 2
                      locked               = 3
                      OTHERS               = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
          ENDIF.

        ENDIF.
      ENDLOOP.
    ENDIF.


  ENDIF.





  g_index = 0.
  LOOP AT gt_mchdr.
    ADD 1 TO g_index.
    MOVE-CORRESPONDING gt_mchdr TO ls_mchdr_save.

    LOOP AT gt_mcauditor INTO lt_mcauditor
            WHERE contid = ls_mchdr_save-contid.
      APPEND lt_mcauditor.
    ENDLOOP.

    LOOP AT gt_mctran INTO lt_mctran
            WHERE contid = ls_mchdr_save-contid.
      APPEND lt_mctran.
    ENDLOOP.

    LOOP AT gt_mcrepid INTO lt_mcrepid
            WHERE contid = ls_mchdr_save-contid.
      APPEND lt_mcrepid.
    ENDLOOP.

    LOOP AT gt_mittexts WHERE contid = ls_mchdr_save-contid.
      lt_texts-textname = gt_mittexts-contid.
      lt_texts-object   = 'M'.
      lt_texts-spras    = gt_mittexts-spras.
      lt_texts-line     = gt_mittexts-line.
      lt_texts-text     = gt_mittexts-text.
      APPEND lt_texts.
    ENDLOOP.
    "Begin changes DDHIMAN 19.11.18
    READ TABLE gt_mcrvwhdr INTO ls_mcrhdr WITH KEY contid =
ls_mchdr_save-contid.
    IF testrun = ' '.
      CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
           EXPORTING
                is_mchdr             = ls_mchdr_save
                if_add_assgn_only    = 'X'
                is_mcrvwhdr          = ls_mcrhdr
           TABLES
                it_mcauditor         = lt_mcauditor
                it_mctran            = lt_mctran
                it_mcrepid           = lt_mcrepid
                it_texts             = lt_texts
           EXCEPTIONS
                target_not_specified = 1
                not_authorized       = 2
                locked               = 3
                OTHERS               = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
    ENDIF.
    CLEAR ls_mcrhdr.
    "End changes DDHIMAN 19.11.18
    REFRESH: lt_mcauditor, lt_mctran, lt_mcrepid, lt_texts.
  ENDLOOP.

*** Have to save each assignment table separately ***

*--Get companies a user is assigned to
  DATA : lt_swuinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
  LOOP AT gt_mcuser.
    lt_swuinfo-bname = gt_mcuser-userid.
    COLLECT lt_swuinfo.
  ENDLOOP.
  IF NOT lt_swuinfo[] IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_USER_INFO'
         EXPORTING
              i_name_only  = 'X'
              i_mr_company = 'X'
         TABLES
              sw_uinfo     = lt_swuinfo.
  ENDIF.
*   User assignments
  g_index = 0.
  LOOP AT gt_mcuser.
    g_file_name = p_usasfl.
    ADD 1 TO g_index.
    READ TABLE lt_swuinfo WITH KEY bname = gt_mcuser-userid.
    AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
             ID 'ACTVT'      FIELD l_act_upload
             ID 'Y&SW_VRSIO' FIELD gt_mcuser-vrsio
             ID 'Y&SW_CNTID' FIELD gt_mcuser-contid
             ID 'Y&SW_CONID' FIELD gt_mcuser-conid
             ID 'Y&SW_BNAME' FIELD gt_mcuser-userid
             ID 'Y&SW_COMP'  FIELD lt_swuinfo-company.
    IF sy-subrc NE 0.
*You are not authorizied to & & & &
*        g_index = ls_mcuser-l_index.
      err_value = ''."not a specific field

      err_msg = 'Not Authorized to upload User Assignment'(e32).
      gf_err = 'E'.
      l_field = ''."not a specific field
      PERFORM append_output USING g_file_name gf_err l_field
                                  err_value err_msg.
      DELETE gt_mcuser WHERE l_index EQ g_index.
    ELSE.
      MOVE-CORRESPONDING gt_mcuser TO lt_mcuser.
      APPEND lt_mcuser.
      lt_cont-contid = gt_mcuser-contid.
      COLLECT lt_cont.
    ENDIF.

    AT LAST.

      IF ovrwrt = 'X'.
        REFRESH lt_cont.
        lt_cont[] = gt_cont_ovr[].
        CLEAR gf_add.
        CLEAR gf_del.
      ELSE.
        gf_add = 'X'.
        CLEAR gf_del.
      ENDIF.

      LOOP AT lt_cont.
        SELECT SINGLE * INTO ls_mchdr_save           "#EC CI_SEL_NESTED
               FROM /psyng/mchdr
                      WHERE contid = lt_cont-contid.

        LOOP AT lt_mcuser INTO lt_mcuser_save
                WHERE contid = lt_cont-contid.
          APPEND lt_mcuser_save.
        ENDLOOP.
        IF testrun = ' '.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
               EXPORTING
                    is_mchdr             = ls_mchdr_save
                    if_add_assgn_only    = gf_add
                    if_del_assgn_only    = gf_del
               TABLES
                    it_mcuser            = lt_mcuser_save
               EXCEPTIONS
                    target_not_specified = 1
                    not_authorized       = 2
                    locked               = 3
                    OTHERS               = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        ENDIF.
        REFRESH lt_mcuser_save.
      ENDLOOP.

      REFRESH: lt_cont, lt_mcuser, lt_mcuser_save.
    ENDAT.
  ENDLOOP.

*   User groups
  ls_mcusrgrp-l_index  = 0.
  LOOP AT gt_mcusrgrp.
    ADD 1 TO ls_mcusrgrp-l_index .
    g_file_name = p_usgrpf.
    AUTHORITY-CHECK OBJECT 'Y&SW_MCUG'
             ID 'ACTVT' FIELD l_act_upload
             ID 'Y&SW_VRSIO' FIELD gt_mcusrgrp-vrsio
             ID 'Y&SW_CNTID' FIELD gt_mcusrgrp-contid
             ID 'Y&SW_CONID' FIELD gt_mcusrgrp-conid
             ID 'Y&SW_CLASS' FIELD gt_mcusrgrp-class.
    IF sy-subrc NE 0.
*You are not authorizied to & & & &
      g_index = ls_mcusrgrp-l_index.
      err_value = ''."not a specific field
      err_msg = 'Not Authorized to upload Usergroup Assignment'(e33).
      gf_err = 'E'.
      l_field = ''."not a specific field
      PERFORM append_output USING g_file_name gf_err l_field
                                  err_value err_msg.
      DELETE gt_mcusrgrp WHERE l_index EQ g_index.
    ELSE.
      MOVE-CORRESPONDING gt_mcusrgrp TO lt_mcusrgrp.
      APPEND lt_mcusrgrp.
      lt_cont-contid = gt_mcusrgrp-contid.
      COLLECT lt_cont.
    ENDIF.

    AT LAST.
      IF ovrwrt = 'X'.
        REFRESH lt_cont.
        lt_cont[] = gt_cont_ovr[].
        CLEAR gf_add.
        CLEAR gf_del.
      ELSE.
        gf_add = 'X'.
        CLEAR gf_del.
      ENDIF.

      LOOP AT lt_cont.
        SELECT SINGLE * INTO ls_mchdr_save           "#EC CI_SEL_NESTED
           FROM /psyng/mchdr
                      WHERE contid = lt_cont-contid.

        LOOP AT lt_mcusrgrp INTO lt_mcusrgrp_save
                WHERE contid = lt_cont-contid.
          APPEND lt_mcusrgrp_save.
        ENDLOOP.
        IF testrun = ' '.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
               EXPORTING
                    is_mchdr             = ls_mchdr_save
                    if_add_assgn_only    = gf_add
                    if_del_assgn_only    = gf_del
               TABLES
                    it_mcusrgrp          = lt_mcusrgrp_save
               EXCEPTIONS
                    target_not_specified = 1
                    not_authorized       = 2
                    locked               = 3
                    OTHERS               = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        ENDIF.
        REFRESH lt_mcusrgrp_save.
      ENDLOOP.

      REFRESH: lt_cont, lt_mcusrgrp, lt_mcusrgrp_save.
    ENDAT.
  ENDLOOP.

*   Roles
  g_index = 0.
  LOOP AT gt_mcrole.
    g_file_name = p_rlassf.
    ADD 1 TO g_index.

    AUTHORITY-CHECK OBJECT 'Y&SW_MCROL'
             ID 'ACTVT' FIELD l_act_upload
             ID 'Y&SW_VRSIO' FIELD gt_mcrole-vrsio
             ID 'Y&SW_CNTID' FIELD gt_mcrole-contid
             ID 'Y&SW_CONID' FIELD gt_mcrole-conid
             ID 'ACT_GROUP'  FIELD gt_mcrole-agr_name.
    IF sy-subrc NE 0.
*You are not authorizied to & & & &
*        g_index = ls_mcrole-l_index.
      err_value = ''."not a specific field
      err_msg = 'Not Authorized to upload Role Assignment'(e34).
      gf_err = 'E'.
      l_field = ''."not a specific field
      PERFORM append_output USING g_file_name gf_err l_field
                                  err_value err_msg.
      DELETE gt_mcrole WHERE l_index EQ g_index.
    ELSE.
      MOVE-CORRESPONDING gt_mcrole TO lt_mcrole.
      APPEND lt_mcrole.
      lt_cont-contid = lt_mcrole-contid.
      COLLECT lt_cont.
    ENDIF.

    AT LAST.
      IF ovrwrt = 'X'.
        REFRESH lt_cont.
        lt_cont[] = gt_cont_ovr[].
        CLEAR gf_add.
        CLEAR gf_del.
      ELSE.
        gf_add = 'X'.
        CLEAR gf_del.
      ENDIF.

      LOOP AT lt_cont.
        SELECT SINGLE * INTO ls_mchdr_save           "#EC CI_SEL_NESTED
          FROM /psyng/mchdr
                      WHERE contid = lt_cont-contid.

        LOOP AT lt_mcrole INTO lt_mcrole_save
                WHERE contid = lt_cont-contid.
          APPEND lt_mcrole_save.
        ENDLOOP.
        IF testrun = ' '.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
               EXPORTING
                    is_mchdr             = ls_mchdr_save
                    if_add_assgn_only    = gf_add
                    if_del_assgn_only    = gf_del
               TABLES
                    it_mcrole            = lt_mcrole_save
               EXCEPTIONS
                    target_not_specified = 1
                    not_authorized       = 2
                    locked               = 3
                    OTHERS               = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        ENDIF.
        REFRESH lt_mcrole_save.
      ENDLOOP.

      REFRESH: lt_cont, lt_mcrole, lt_mcrole_save.
    ENDAT.
  ENDLOOP.

* Critical auths assignments to users
  ls_mccauser-l_index = 0.
  LOOP AT gt_mccauser.
    g_file_name = p_crtfl.
    ADD 1 TO ls_mccauser-l_index.
    AUTHORITY-CHECK OBJECT 'Y&SW_MCCAU'
             ID 'ACTVT' FIELD l_act_upload
             ID 'Y&SW_VRSIO' FIELD gt_mccauser-vrsio
             ID 'Y&SW_SWAUD' FIELD gt_mccauser-swaudid
             ID 'Y&SW_CNTID' FIELD gt_mccauser-contid
             ID 'Y&SW_BNAME' FIELD gt_mccauser-userid.
    IF sy-subrc NE 0.
*You are not authorizied to & & & &
      g_index = ls_mccauser-l_index.
      err_value = ''."not a specific field
      err_msg =
      'Not Authorized to upload Crit. Auth. user Assignment'(e35).
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err l_field
                                  err_value err_msg.
      DELETE gt_mccauser WHERE l_index EQ g_index.
    ELSE.
      MOVE-CORRESPONDING gt_mccauser TO lt_mccauser.
      APPEND lt_mccauser.
      lt_cont-contid = lt_mccauser-contid.
      COLLECT lt_cont.
    ENDIF.

    AT LAST.

      IF ovrwrt = 'X'.
        REFRESH lt_cont.
        lt_cont[] = gt_cont_ovr[].
        CLEAR gf_add.
        CLEAR gf_del.
      ELSE.
        gf_add = 'X'.
        CLEAR gf_del.
      ENDIF.

      LOOP AT lt_cont.
        SELECT SINGLE * INTO ls_mchdr_save           "#EC CI_SEL_NESTED
           FROM /psyng/mchdr
                      WHERE contid = lt_cont-contid.

        LOOP AT lt_mccauser INTO lt_mccauser_save
                WHERE contid = lt_cont-contid.
          APPEND lt_mccauser_save.
        ENDLOOP.
        IF testrun = ' '.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
               EXPORTING
                    is_mchdr             = ls_mchdr_save
                    if_add_assgn_only    = gf_add
                    if_del_assgn_only    = gf_del
               TABLES
                    it_mccauser          = lt_mccauser_save
               EXCEPTIONS
                    target_not_specified = 1
                    not_authorized       = 2
                    locked               = 3
                    OTHERS               = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        ENDIF.
        REFRESH lt_mccauser_save.
      ENDLOOP.

      REFRESH: lt_cont, lt_mccauser, lt_mccauser_save.
    ENDAT.
  ENDLOOP.

* Critical auths assigment to roles
  ls_mccarole-l_index = 0.
  LOOP AT gt_mccarole.
    g_file_name = p_crrlfl.
    ADD 1 TO ls_mccarole-l_index.

    AUTHORITY-CHECK OBJECT 'Y&SW_MCCAR'
             ID 'ACTVT' FIELD l_act_upload
             ID 'Y&SW_VRSIO' FIELD gt_mccarole-vrsio
             ID 'Y&SW_SWAUD' FIELD gt_mccarole-swaudid
             ID 'Y&SW_CNTID' FIELD gt_mccarole-contid
             ID 'ACT_GROUP'  FIELD gt_mccarole-agr_name.
    IF sy-subrc NE 0.
*You are not authorizied to & & & &
      g_index = ls_mccarole-l_index.
      err_value = ''."not a specific field
      err_msg =
      'Not Authorized to upload Crit. Auth. role Assignment'(e45).
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err l_field
                                  err_value err_msg.
      DELETE gt_mccarole WHERE l_index EQ g_index.
    ELSE.
      MOVE-CORRESPONDING gt_mccarole TO lt_mccarole.
      APPEND lt_mccarole.
      lt_cont-contid = lt_mccarole-contid.
      COLLECT lt_cont.
    ENDIF.

    AT LAST.

      IF ovrwrt = 'X'.
        REFRESH lt_cont.
        lt_cont[] = gt_cont_ovr[].
        CLEAR gf_add.
        CLEAR gf_del.
      ELSE.
        gf_add = 'X'.
        CLEAR gf_del.
      ENDIF.

      LOOP AT lt_cont.
        SELECT SINGLE * INTO ls_mchdr_save FROM /psyng/mchdr
                      WHERE contid = lt_cont-contid.

        LOOP AT lt_mccarole INTO lt_mccarole_save
                WHERE contid = lt_cont-contid.
          APPEND lt_mccarole_save.
        ENDLOOP.
        IF testrun = ' '.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
               EXPORTING
                    is_mchdr             = ls_mchdr_save
                    if_add_assgn_only    = gf_add
                    if_del_assgn_only    = gf_del
               TABLES
                    it_mccarole          = lt_mccarole_save
               EXCEPTIONS
                    target_not_specified = 1
                    not_authorized       = 2
                    locked               = 3
                    OTHERS               = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        ENDIF.
        REFRESH lt_mccarole_save.
      ENDLOOP.

      REFRESH: lt_cont, lt_mccarole, lt_mccarole_save.
    ENDAT.
  ENDLOOP.

  IF mithead = 'X'.
    IF NOT gt_mchdr[] IS INITIAL.
      PERFORM check_sucess  USING p_mithf.
    ENDIF.
    IF NOT gt_mittexts[] IS INITIAL.
      PERFORM check_sucess  USING p_mitxf.
    ENDIF.
    IF NOT gt_mctran[] IS INITIAL.
      PERFORM check_sucess  USING p_mitdf.
    ENDIF.
    IF NOT gt_mcrepid[] IS INITIAL.
      PERFORM check_sucess  USING p_mitrf.
    ENDIF.
    IF NOT gt_mcauditor[] IS INITIAL.
      PERFORM check_sucess  USING p_mitaf.
    ENDIF.
    "Begin of changes DDHIMAN 19.11.18
    IF NOT gt_mcrvwhdr[] IS INITIAL.
      PERFORM check_sucess  USING p_mitrhd.
    ENDIF.
    "End changes DDHIMAN 19.11.18
  ENDIF.

  IF p_usassn  = 'X' AND NOT gt_mcuser[] IS INITIAL.
    PERFORM check_sucess  USING p_usasfl.
  ENDIF.
  IF p_usrgrp   = 'X' AND NOT gt_mcusrgrp[] IS INITIAL.
    PERFORM check_sucess  USING p_usgrpf.
  ENDIF.
  IF p_rlassn  = 'X' AND NOT gt_mcrole[] IS INITIAL.
    PERFORM check_sucess  USING p_rlassf.
  ENDIF.
  IF p_crassn  = 'X' AND NOT gt_mccauser[] IS INITIAL.
    PERFORM check_sucess  USING p_crtfl.
  ENDIF.
  IF p_crtrol  = 'X' AND NOT gt_mccarole[] IS INITIAL.
    PERFORM check_sucess  USING p_crrlfl.
  ENDIF.

  CHECK NOT gt_output[] IS INITIAL.
  SORT gt_output BY sort_file l_index ASCENDING.
  PERFORM output.

ENDFORM.                    " upload_mit_tables

*&---------------------------------------------------------------------*
*&      Form  upload
*&---------------------------------------------------------------------*
*       Retrieve data from file
*----------------------------------------------------------------------*
*      -->ET_TABLE    Table
*      -->I_FILENAME  File name
*      -->I_ERR_TEXT  Error message (in case of failure
*----------------------------------------------------------------------*
FORM upload TABLES   et_table
            USING    i_filename TYPE rlgrap-filename
                     i_err_text.
  DATA: l_filename TYPE string.
*  DATA:l_len TYPE i,
*       l_val.
*  l_len = strlen( path1 ).
*  l_len = l_len - 1.
*  l_val = path1+l_len(1).
*  IF l_val NE '\'.
*    MESSAGE s113(/psyng/sw) WITH text-174.
*    LEAVE LIST-PROCESSING.
*  ENDIF.

  CONCATENATE path1 i_filename INTO l_filename.
  CONDENSE l_filename NO-GAPS.

  i_filename = l_filename.
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
    PERFORM handle_upload_error USING sy-subrc l_filename.
    gf_err = 'E'.
    g_err_msg = i_err_text.
    g_file_name = l_filename.
    PERFORM append_output USING g_file_name gf_err g_field
                                g_err_value g_err_msg.
  ENDIF.
  ENDIF.
*EOC:HBHALLA (097)
  DELETE et_table INDEX 1.
  i_filename = l_filename.
ENDFORM.                    " upload

*&---------------------------------------------------------------------*
*&      Form  handle_upload_error
*&---------------------------------------------------------------------*
*       Output proper error message for upload
*----------------------------------------------------------------------*
*      -->I_SUBRC     Return code
*      -->I_FILENAME  File name
*      -->I_MSG       Error text
*----------------------------------------------------------------------*
FORM handle_upload_error USING    i_subrc TYPE sy-subrc
                                  i_filename TYPE string.
  CASE i_subrc.
    WHEN 1.
      MESSAGE i021(/psyng/basis) WITH i_filename.
    WHEN 2.
      MESSAGE i022(/psyng/basis) WITH i_filename.
    WHEN 3.
      MESSAGE i023(/psyng/basis) WITH i_filename.
    WHEN 4.
      MESSAGE i024(/psyng/basis) WITH i_filename.
    WHEN 5.
      MESSAGE i025(/psyng/basis) WITH i_filename.
    WHEN 6.
      MESSAGE i026(/psyng/basis) WITH i_filename.
    WHEN 7 OR 17.
      MESSAGE i027(/psyng/basis) WITH i_filename.
    WHEN 8.
      MESSAGE i028(/psyng/basis) WITH i_filename.
    WHEN 9.
      MESSAGE i029(/psyng/basis) WITH i_filename.
    WHEN 10.
      MESSAGE i030(/psyng/basis) WITH i_filename.
    WHEN 11.
      MESSAGE i031(/psyng/basis) WITH i_filename.
    WHEN 12.
      MESSAGE i032(/psyng/basis) WITH i_filename.
    WHEN 13.
      MESSAGE i033(/psyng/basis) WITH i_filename.
    WHEN 14.
      MESSAGE i034(/psyng/basis) WITH i_filename.
    WHEN 15.
      MESSAGE i035(/psyng/basis) WITH i_filename.
    WHEN 16.
      MESSAGE i036(/psyng/basis) WITH i_filename.
  ENDCASE.
ENDFORM.                    " handle_upload_error

*&---------------------------------------------------------------------*
*&      Form  validation
*&---------------------------------------------------------------------*
*       Perform validations
*----------------------------------------------------------------------*
FORM validation.
  DATA  ls_swconfig TYPE /psyng/swconfig.
  se_config_param 'MIT_APRV_EQ_USR_MSG' g_mit_aprv_eq_usr_msg.
  se_config_param 'MIT_AUDT_EQ_USR_MSG' g_mit_audt_eq_usr_msg.
  se_config_param 'MIT_AUDT_HDR_LIST' g_mit_audt_hdr_list.
  se_config_param 'MIT_VALID_FOR_CON' ls_swconfig-value.
  se_config_param 'MIT_CON_DEFINED_ONLY' g_mit_con_defined_only.
  IF ls_swconfig-value = 'W' OR
     ls_swconfig-value = 'S' OR
     ls_swconfig-value = 'E'.
    g_mit_valid_for_con = ls_swconfig-value.
  ELSE.
    g_mit_valid_for_con = 'W'.
  ENDIF.


********Master data*********

  SELECT bname FROM usr02 INTO TABLE gt_usr02.
  SELECT contid description FROM /psyng/mchdr INTO TABLE gt_mchdr_db.

  SORT: gt_usr02 BY bname,
        gt_mchdr_db BY contid.



****************Mitigation header************

  IF mithead EQ 'X'.

    PERFORM validate_delete.

****************  Get Master Data
    SELECT tcode FROM tstc INTO CORRESPONDING FIELDS OF TABLE gt_tstc.
    SELECT obj_name FROM tadir INTO TABLE gt_tadir
           WHERE pgmid = 'R3TR' AND object = 'PROG'.

    SELECT * FROM /psyng/sw_freq INTO TABLE gt_frequencies.
    SORT: gt_tadir BY obj_name.

******************Mitigation Header Data********************
    IF  NOT gt_mchdr[] IS INITIAL.
      PERFORM validate_mitigation_header.
    ENDIF.
    IF  NOT gt_mittexts[] IS INITIAL.
      PERFORM validate_mitigation_texts.
    ENDIF.
    IF  NOT gt_mctran[] IS INITIAL.
      PERFORM validate_mitigation_trans.
    ENDIF.
    IF  NOT gt_mcrepid[] IS INITIAL.
      PERFORM validate_mitigation_reports.
    ENDIF.
    IF  NOT  gt_mcauditor[] IS INITIAL.
      PERFORM validate_mitigation_auditors.
    ENDIF.

    "Begin changes DDHIMAN 19.11.18
    IF  NOT  gt_mcrvwhdr[] IS INITIAL.
      PERFORM validate_mitigation_review_hdr.
    ENDIF.
    "End changes DDHIMAN 19.11.18
************************************************************
  ENDIF.

**********************user assign*********************
  IF p_usassn EQ 'X'.
    CHECK NOT gt_mcuser[] IS INITIAL.
    PERFORM validate_user_assign.
  ENDIF.
**********************User Group*********************
  IF p_usrgrp  EQ 'X'.
    CHECK NOT gt_mcusrgrp[] IS INITIAL.
    PERFORM validate_user_group.
  ENDIF.
**********************User Role******************
  IF p_rlassn EQ 'X'.
    CHECK NOT gt_mcrole[] IS INITIAL.
    PERFORM validate_user_role.
  ENDIF.
**********************Critical Authorization User*********************
  IF p_crassn EQ 'X'.
    CHECK NOT gt_mccauser[] IS INITIAL.
    PERFORM validate_crit_auth_usr.
  ENDIF.
**********************Critical Authorization Role*********************
  IF p_crtrol EQ 'X'.
    CHECK NOT gt_mccarole[] IS INITIAL.
    PERFORM validate_crit_auth_role.
  ENDIF.
******************

ENDFORM.                    " validation

*&---------------------------------------------------------------------*
*&      Form  validate_delete
*&---------------------------------------------------------------------*
*       Check that mitigation control IDs are not assigned
*----------------------------------------------------------------------*
FORM validate_delete.
  CHECK ovrwrt = 'X' AND NOT gt_mchdr[] IS INITIAL.

  SELECT DISTINCT contid INTO gt_nodel-contid FROM /psyng/mcuser.
    COLLECT gt_nodel.
  ENDSELECT.

  SELECT DISTINCT contid INTO gt_nodel-contid FROM /psyng/mcusrgrp.
    COLLECT gt_nodel.
  ENDSELECT.

  SELECT DISTINCT contid INTO gt_nodel-contid FROM /psyng/mccauser.
    COLLECT gt_nodel.
  ENDSELECT.

  SELECT DISTINCT contid INTO gt_nodel-contid FROM /psyng/mcrole.
    COLLECT gt_nodel.
  ENDSELECT.

ENDFORM.                    " validate_delete
*&---------------------------------------------------------------------*
*&      Form  select_folder
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_PATH1  text
*----------------------------------------------------------------------*
FORM select_folder CHANGING i_folder_path TYPE rlgrap-filename.

  DATA: l_init_folder TYPE string,
        l_selected_folder TYPE string,
        l_title TYPE string.
  IF upldtabs EQ 'X'.
    l_title = text-t00.
  ELSE.
    l_title = text-t01.
  ENDIF.

  l_init_folder = i_folder_path.

  CALL METHOD cl_gui_frontend_services=>directory_browse
"#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
    window_title    = l_title
      initial_folder  = l_init_folder
    CHANGING
      selected_folder = l_selected_folder
    EXCEPTIONS
      cntl_error      = 1
      error_no_gui    = 2
      OTHERS          = 3
          .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
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

  i_folder_path = l_selected_folder.

ENDFORM.                    " select_folder

*&---------------------------------------------------------------------*
*&      Form  TOP-OF-PAGE
*&---------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
*      -->HEADER  text
*----------------------------------------------------------------------*

FORM top-of-page.
  DATA: t_header TYPE slis_t_listheader,
        wa_header TYPE slis_listheader.
*        g_sod_vrsio TYPE  /psyng/swsodvers-vrsio.

********ALV HEADER
  wa_header-typ  = 'H'.
  wa_header-info = 'Uploading Mitigation Controls/Assignments'(h09).
  APPEND wa_header TO t_header.
  CLEAR wa_header.

********SOD VERSION
*  wa_header-typ  = 'S'.
*  wa_header-key = 'SOD Version: '.
**  CALL FUNCTION '/PSYNG/SW_034'
**       IMPORTING
**            e_vrsio = g_sod_vrsio.
*  wa_header-info = g_sod_vrsio.
*  APPEND wa_header TO t_header.
*  CLEAR wa_header.
*
********WARINGS
  wa_header-typ  = 'S'.
  wa_header-key = 'Warnings: '.
  wa_header-info = g_warnings_count.
  APPEND wa_header TO t_header.
  CLEAR wa_header.
********ERRORS
  wa_header-typ  = 'S'.
  wa_header-key = 'Errors: '.
  wa_header-info = g_errors_count.
  APPEND wa_header TO t_header.
  CLEAR wa_header.

  IF testrun = 'X'.
    wa_header-typ  = 'A'.
    wa_header-info = 'Test run'(h10).
    APPEND wa_header TO t_header.
  ENDIF.


  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = t_header.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  validate_mitigation_header
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM validate_mitigation_header.
  DATA:lt_mit_typ TYPE TABLE OF /psyng/sw_mctype WITH HEADER LINE.

  g_file_name = p_mithf.
  gt_mchdr-l_index = 0.
  SELECT * FROM /psyng/sw_mctype INTO TABLE lt_mit_typ.

  LOOP AT gt_mchdr.
*    TRANSLATE gt_mchdr TO UPPER CASE.
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-contid.
    g_index = gt_mchdr-l_index.
    IF gt_mchdr-contid IS INITIAL.
      g_err_msg = text-047.
      g_err_value = ''.
      gf_err = 'E'.
*      g_index = gt_mchdr-l_index.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      CLEAR: g_err_msg,g_err_value,gf_err.
      DELETE gt_mchdr WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.



    IF NOT gt_mchdr-approver IS INITIAL.
      g_field = gc_fields-approver.
      PERFORM validate_userid CHANGING gt_mchdr-approver
                                    gf_err.
      IF gf_err EQ 'E'.
*        err_msg = text-121.
        g_err_value = gt_mchdr-approver.
        CONCATENATE g_field text-121 INTO g_err_msg.
*        g_index = gt_mchdr-l_index.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        CLEAR: g_err_msg,g_err_value,gf_err.
        DELETE gt_mchdr WHERE l_index EQ g_index.
        CONTINUE.

      ENDIF.
    ELSE.
    ENDIF.
***Validate Mitigation type
    IF NOT gt_mchdr-type IS INITIAL.
      g_field = gc_fields-type.
      READ TABLE lt_mit_typ WITH KEY type = gt_mchdr-type .
      IF sy-subrc NE 0.
        gf_err = 'E'.
        g_err_value = gt_mchdr-type.
        CONCATENATE g_field text-121 INTO g_err_msg.
*        g_index = gt_mchdr-l_index.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        CLEAR: g_err_msg,g_err_value,gf_err.
        DELETE gt_mchdr WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ENDIF.

** Validate Inactive field

    IF NOT gt_mchdr-inactive IS INITIAL.
      IF gt_mchdr-inactive NE 'X'.
        g_field = gc_fields-inactive.
        gf_err = 'E'.
        g_err_value = gt_mchdr-inactive.
        g_err_msg = text-e37.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        CLEAR: g_err_msg,g_err_value,gf_err.
        DELETE gt_mchdr WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ENDIF.

  ENDLOOP.
  DESCRIBE TABLE gt_mchdr LINES g_index.
*  PERFORM check_sucess.

ENDFORM.                    " validate_mitigation_header
*&---------------------------------------------------------------------*
*&      Form  validate_Mitigation_Texts
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM validate_mitigation_texts.
  g_file_name = p_mitxf.
  gt_mittexts-l_index = 0.
  LOOP AT gt_mittexts.
    TRANSLATE gt_mittexts-contid TO UPPER CASE.
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-contid.
    g_index = gt_mittexts-l_index.
    IF NOT gt_mittexts-contid IS INITIAL.
      PERFORM validate_contid_header_2 USING gt_mittexts-contid
                                             gf_err.
      IF gf_err = 'E'.
        g_err_msg = 'Control ID does not exist'(e13).
        g_err_value = gt_mcuser-contid.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mcuser WHERE l_index EQ g_index.
        CONTINUE.
*      ELSEIF gf_err = 'W'.
*        err_msg = 'Control ID does not exist'(e13).
*        err_value = gt_mcuser-contid.
*        l_field = c_fields-contid.
*        PERFORM append_output USING g_file_name gf_err l_field
*                                    err_value err_msg.
**        DELETE gt_mcuser WHERE l_index EQ g_index.
**        CONTINUE.
*      ELSEIF gf_err = 'S'.
**-- No Validation or message required
      ENDIF.

    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
*      g_index = gt_mittexts-l_index.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mittexts WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.

  ENDLOOP.
*  DESCRIBE TABLE gt_mcrepid LINES g_index.
*  PERFORM check_sucess.

ENDFORM.                    " validate_Mitigation_Texts
*&---------------------------------------------------------------------*
*&      Form  VALIDATE_MITIGATION_TRANS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM validate_mitigation_trans.
  g_file_name = p_mitdf.
  gt_mctran-l_index = 0.
  LOOP AT gt_mctran.
*    TRANSLATE gt_mctran TO UPPER CASE.
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-contid.
    g_index = gt_mctran-l_index.
****    Validate Conflict ID
    IF NOT gt_mctran-contid IS INITIAL.
      PERFORM validate_contid_header_2 USING gt_mctran-contid
                                             gf_err.
      IF gf_err = 'E'.
        g_err_msg = 'Control ID does not exist'(e13).
        g_err_value = gt_mcuser-contid.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mcuser WHERE l_index EQ g_index.
        CONTINUE.
*      ELSEIF gf_err = 'W'.
*        err_msg = 'Control ID does not exist'(e13).
*        err_value = gt_mcuser-contid.
*        l_field = c_fields-contid.
*        PERFORM append_output USING g_file_name gf_err l_field
*                                    err_value err_msg.
**        DELETE gt_mcuser WHERE l_index EQ g_index.
**        CONTINUE.
*      ELSEIF gf_err = 'S'.
**-- No Validation or message required
      ENDIF.

    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
*      g_index = gt_mctran-l_index.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mctran WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.
*******************
    IF NOT gt_mctran-tcode IS INITIAL.
      PERFORM validate_tcode USING gt_mctran-tcode
                                   gf_err.

      IF gf_err EQ 'E'.

*        err_msg = text-121.
        g_err_value = gt_mctran-tcode.
        g_field = gc_fields-tcode.
        CONCATENATE g_field text-121 INTO g_err_msg.
*        g_index = gt_mctran-l_index.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        CLEAR: g_err_msg,g_err_value,gf_err.
        DELETE gt_mctran WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
*      g_index = gt_mctran-l_index.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mctran WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.

*--Check frequency
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-freq.
    IF NOT gt_mctran-frequency IS INITIAL.
      PERFORM validate_frequencies  USING gt_mctran-frequency
                                          gf_err.
      g_err_value = gt_mctran-frequency.
      IF gf_err EQ 'E'.

        g_field = gc_fields-freq.
        CONCATENATE g_field text-121 INTO g_err_msg.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        CLEAR: g_err_msg,g_err_value,gf_err.
        DELETE gt_mctran WHERE l_index EQ g_index.
      ENDIF.
    ELSE.
    ENDIF.

  ENDLOOP.
*  DESCRIBE TABLE  gt_mctran LINES g_index.
*  PERFORM check_sucess.

ENDFORM.                    " VALIDATE_MITIGATION_TRANS
*&---------------------------------------------------------------------*
*&      Form  validate_Mitigation_Reports
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM validate_mitigation_reports.
  g_file_name = p_mitrf.
  gt_mcrepid-l_index = 0.
  LOOP AT gt_mcrepid.
*    TRANSLATE gt_mcrepid TO UPPER CASE.
    g_index = gt_mcrepid-l_index.
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-contid.
    IF NOT gt_mcrepid-contid IS INITIAL.
      PERFORM validate_contid_header_2 USING gt_mcrepid-contid
                                             gf_err.
      IF gf_err = 'E'.
        g_err_msg = 'Control ID does not exist'(e13).
        g_err_value = gt_mcuser-contid.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mcuser WHERE l_index EQ g_index.
        CONTINUE.
*      ELSEIF gf_err = 'W'.
*        err_msg = 'Control ID does not exist'(e13).
*        err_value = gt_mcuser-contid.
*        l_field = c_fields-contid.
*        PERFORM append_output USING g_file_name gf_err l_field
*                                    err_value err_msg.
**        DELETE gt_mcuser WHERE l_index EQ g_index.
**        CONTINUE.
*      ELSEIF gf_err = 'S'.
**-- No Validation or message required
      ENDIF.

    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
*      g_index = gt_mcrepid-l_index.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcrepid WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.
**      Validate Report ID
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-repid.
    IF NOT gt_mcrepid-repid IS INITIAL.
      PERFORM validate_report USING gt_mcrepid-repid
                                            gf_err.

      IF gf_err EQ 'E'.
*        err_msg = text-121.
        g_err_value = gt_mcrepid-repid.
        g_field = gc_fields-repid.
        CONCATENATE g_field text-121 INTO g_err_msg.
*        g_index = gt_mcrepid-l_index.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mcrepid WHERE l_index EQ g_index.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
*      g_index = gt_mcrepid-l_index.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcrepid WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.

*--Check frequency
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-freq.
    IF NOT gt_mcrepid-frequency IS INITIAL.
      PERFORM validate_frequencies  USING gt_mcrepid-frequency
                                          gf_err.
      g_err_value = gt_mcrepid-frequency.

      IF gf_err EQ 'E'.

*        err_msg = text-121.
        g_field = gc_fields-freq.
        CONCATENATE g_field text-121 INTO g_err_msg.
*        g_index = gt_mcrepid-l_index.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        CLEAR: g_err_msg,g_err_value,gf_err.
        DELETE gt_mcrepid WHERE l_index EQ g_index.
      ENDIF.
    ELSE.
    ENDIF.
  ENDLOOP.
*  DESCRIBE TABLE gt_mcrepid LINES g_index.
*  PERFORM check_sucess.


ENDFORM.                    " validate_Mitigation_Reports
*&---------------------------------------------------------------------*
*&      Form  validate_Mitigation_Auditors
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM validate_mitigation_auditors.
  g_file_name = p_mitaf.
  LOOP AT gt_mcauditor.
*    TRANSLATE gt_mcauditor TO UPPER CASE.
    g_index = gt_mcauditor-l_index.
**Validate Control ID
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-contid.
    IF NOT gt_mcauditor-contid IS INITIAL.
      PERFORM validate_contid_header_2 USING gt_mcauditor-contid
                                             gf_err.
      g_err_value = gt_mcauditor-contid.
      IF gf_err = 'E'.
        g_err_msg = 'Control ID does not exist'(e13).
        g_err_value = gt_mcuser-contid.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mcuser WHERE l_index EQ g_index.
        CONTINUE.
*      ELSEIF gf_err = 'W'.
*        err_msg = 'Control ID does not exist'(e13).
*        err_value = gt_mcuser-contid.
*        l_field = c_fields-contid.
*        PERFORM append_output USING g_file_name gf_err l_field
*                                    err_value err_msg.
**        DELETE gt_mcuser WHERE l_index EQ g_index.
**        CONTINUE.
*      ELSEIF gf_err = 'S'.
**-- No Validation or message required
      ENDIF.

    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcauditor WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.
**Validate auditor
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-auditor.

    IF gt_mcauditor-auditor IS INITIAL.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcauditor WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.

*    IF NOT gt_mcauditor-auditor IS INITIAL.
*"THIS IS DUE TO THE REMOTE MITIGATION ASSIGNMENTS
*      PERFORM validate_userid CHANGING gt_mcauditor-auditor
*                                    gf_err.
*      err_value = gt_mcauditor-auditor.
*
*      IF gf_err EQ 'E'.
*
**        err_msg = text-121.
*        l_field = c_fields-auditor.
*        CONCATENATE l_field text-121 INTO err_msg.
*        PERFORM append_output USING g_file_name gf_err l_field
*                                    err_value err_msg.
*        CLEAR: err_msg,err_value,gf_err.
*        DELETE gt_mcauditor WHERE l_index EQ g_index.
*      ENDIF.
*    ELSE.
*    ENDIF.
  ENDLOOP.
*  DESCRIBE TABLE gt_mcauditor LINES g_index.
*  PERFORM check_sucess.


ENDFORM.                    " validate_Mitigation_Auditors
*&---------------------------------------------------------------------*
*&      Form  validate_user_assign
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM validate_user_assign.
  DATA:l_vrs(3) TYPE c.
  CLEAR g_index.
  g_file_name = p_usasfl.
  LOOP AT  gt_mcuser.
    CLEAR l_vrs.
    g_index = gt_mcuser-l_index.
    CLEAR: g_err_msg,g_err_value,gf_err.
*_____Validate User ID_____
    g_field = gc_fields-userid.
    IF NOT gt_mcuser-userid IS INITIAL.
      PERFORM validate_userid CHANGING gt_mcuser-userid
                                    gf_err.
      IF gf_err EQ 'E'.
*        err_msg = text-121.
        g_err_value = gt_mcuser-userid.
        CONCATENATE g_field text-121 INTO g_err_msg.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.

        DELETE gt_mcuser WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcuser WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.


*_____Validate Control ID_____
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-contid.
    IF NOT gt_mcuser-contid IS INITIAL.
*      SELECT SINGLE mandt INTO sy-mandt              "#EC CI_SEL_NESTED
*          FROM /psyng/mchdr
*                  WHERE contid = gt_mcuser-contid.
*      IF sy-subrc NE 0.

      PERFORM validate_contid_header_2 USING gt_mcuser-contid
                                             gf_err.

      IF gf_err = 'E'.
        g_err_msg = 'Control ID does not exist'(e13).
        g_err_value = gt_mcuser-contid.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mcuser WHERE l_index EQ g_index.
        CONTINUE.
*      ELSEIF gf_err = 'W'.
*        err_msg = 'Control ID does not exist'(e13).
*        err_value = gt_mcuser-contid.
*        l_field = c_fields-contid.
*        PERFORM append_output USING g_file_name gf_err l_field
*                                    err_value err_msg.
**        DELETE gt_mcuser WHERE l_index EQ g_index.
**        CONTINUE.
*      ELSEIF gf_err = 'S'.
**-- No Validation or message required
      ENDIF.

      SELECT SINGLE approver INTO g_approver         "#EC CI_SEL_NESTED
         FROM /psyng/mchdr
           WHERE contid = gt_mcuser-contid.
      IF sy-subrc NE 0.
        gf_err = 'E'.

        g_err_msg = 'Invalid Control ID'(e26).
        g_err_value = gt_mcuser-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcuser WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.
*_____Validate Conflict ID_____
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-conid.
    IF NOT gt_mcuser-conid IS INITIAL.
      PERFORM validate_conid_vrs USING gt_mcuser-conid
                                       gt_mcuser-vrsio
                                       gf_err.
      IF gf_err EQ 'E'.

        g_err_msg = 'Conflict ID does not match with version'(e27).
       CONCATENATE gt_mcuser-conid '-' gt_mcuser-vrsio INTO g_err_value.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.

        DELETE gt_mcuser WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcuser WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.
*     *_____validate version_____
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-version.
    l_vrs = gt_mcuser-vrsio.
    IF NOT l_vrs EQ space.


      PERFORM validate_conid_contid_vrs USING gt_mcuser-conid
                                              gt_mcuser-contid
                                              gt_mcuser-vrsio
                                              gf_err.
      IF gf_err EQ 'E'.
        g_err_msg =
        'Proposed Mitigation is not defined for Conflict ID'(e11).
        CONCATENATE gt_mcuser-conid '-' gt_mcuser-contid '-'
        gt_mcuser-vrsio INTO g_err_value.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.

        CLEAR: g_err_msg,g_err_value,gf_err.


        DELETE gt_mcuser WHERE l_index EQ g_index.
        CONTINUE.
      ELSEIF gf_err EQ 'W'.
        g_err_msg =
  'Proposed Mitigation is not defined for Conflictid'(e11).
        CONCATENATE gt_mcuser-conid '-' gt_mcuser-contid '-'
        gt_mcuser-vrsio INTO g_err_value.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.

        CLEAR: g_err_msg,g_err_value,gf_err.
      ELSEIF gf_err = 'S'.
*-- No Validation or message required

      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcuser WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.


*  * Check that the user ID is not the same as the approver ID

    IF gt_mcuser-userid = g_approver.
      gf_err = g_mit_aprv_eq_usr_msg.

**      PERFORM get_apr_msgtyp USING gf_err.
      IF NOT gf_err IS INITIAL.

        g_err_msg = 'User ID same as Approver ID'(e23).
        CONCATENATE gt_mcuser-userid '-'  g_approver
        INTO g_err_value.
        g_field = gc_fields-conid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        IF gf_err EQ 'E'.
          CLEAR: g_err_msg,g_err_value,gf_err.
          DELETE gt_mcuser WHERE l_index EQ g_index.
          CONTINUE.
        ENDIF.
      ENDIF.
      CLEAR gf_err.
    ENDIF.
*_____Validate Auditor_____
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-auditor.
    IF NOT gt_mcuser-auditor IS INITIAL.
*  * Check that the user ID is not the same as the Auditor ID
      IF gt_mcuser-userid = gt_mcuser-auditor.
        gf_err = g_mit_audt_eq_usr_msg.

        IF NOT gf_err IS INITIAL.

          g_err_msg = 'User ID same as Auditor ID'(e30).
          CONCATENATE gt_mcuser-userid '-'  gt_mcuser-auditor
          INTO g_err_value.
          g_field = gc_fields-userid.
          PERFORM append_output USING g_file_name gf_err g_field
                                      g_err_value g_err_msg.
          IF gf_err EQ 'E'.
            CLEAR: g_err_msg,g_err_value,gf_err.
            DELETE gt_mcuser WHERE l_index EQ g_index.
            CONTINUE.
          ENDIF.
        ENDIF.
        CLEAR gf_err.
*"THIS IS DUE TO THE REMOTE MITIGATION ASSIGNMENTS
*      ELSE.
*        PERFORM validate_userid CHANGING gt_mcuser-auditor
*                                      gf_err.
*        IF gf_err EQ 'E'.
**        err_msg = text-121.
*          err_value = gt_mcuser-auditor.
*          CONCATENATE l_field text-121 INTO err_msg.
*          PERFORM append_output USING g_file_name gf_err l_field
*                                      err_value err_msg.
*
*          DELETE gt_mcuser WHERE l_index EQ g_index.
*          CONTINUE.
*        ENDIF.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcuser WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.

*Extended check for auditor

*      gf_err = mit_audt_hdr_list.
    IF g_mit_audt_hdr_list EQ 'Y'.
      PERFORM extended_auditor_check USING gt_mcuser-userid
                                           gt_mcuser-contid
                                           gt_mcuser-auditor
                                           gf_err.
      IF NOT gf_err IS INITIAL.

        g_err_msg = text-e12.
        CONCATENATE gt_mcuser-userid '-'  gt_mcuser-auditor
        INTO g_err_value.
        g_field = gc_fields-auditor.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.

        CLEAR: g_err_msg,g_err_value,gf_err.
        DELETE gt_mcuser WHERE l_index EQ g_index.

      ENDIF.
      CLEAR gf_err.
    ENDIF.


    PERFORM validate_date USING gt_mcuser-from_date
                                gt_mcuser-to_date
                                g_field gf_err
                                g_err_value g_err_msg.
    IF NOT gf_err IS INITIAL.

      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.

      CLEAR: g_err_msg,g_err_value,gf_err.
      DELETE gt_mcuser WHERE l_index EQ g_index.

    ENDIF.
  ENDLOOP.
*  DESCRIBE TABLE gt_mcuser LINES g_index.
*  PERFORM check_sucess.

ENDFORM.                    " validate_user_assign
*&---------------------------------------------------------------------*
*&      Form  validate_user_group
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM validate_user_group.
  DATA:l_vrs(3) TYPE c.
  g_file_name = p_usgrpf.
  LOOP AT gt_mcusrgrp.
*    TRANSLATE gt_mcusrgrp TO UPPER CASE.
    g_index = gt_mcusrgrp-l_index.
    CLEAR: g_err_msg,g_err_value,gf_err.
* Validate user Group
*_____Validate Auditor_____
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-class.
    IF NOT gt_mcusrgrp-class IS INITIAL.

      SELECT SINGLE mandt INTO sy-mandt FROM usgrp   "#EC CI_SEL_NESTED
                    WHERE usergroup = gt_mcusrgrp-class.
      IF sy-subrc <> 0.
        gf_err = 'E'.
        g_err_msg = 'User Group does not exist'(e28).
        g_err_value = gt_mcusrgrp-class.
        g_field = gc_fields-class.

        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mcusrgrp WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcusrgrp WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.

* Validate mitigating control ID
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-contid.
    IF NOT gt_mcusrgrp-contid IS INITIAL.
*      SELECT SINGLE mandt INTO sy-mandt              "#EC CI_SEL_NESTED
*       FROM /psyng/mchdr
*                  WHERE contid = gt_mcusrgrp-contid.
*      IF sy-subrc NE 0.
      PERFORM validate_contid_header_2 USING gt_mcusrgrp-contid
                                             gf_err.

      IF gf_err = 'E'.
        g_err_msg = 'Control ID does not exist'(e13).
        g_err_value = gt_mcusrgrp-contid.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mcuser WHERE l_index EQ g_index.
        CONTINUE.
*      ELSEIF gf_err = 'W'.
*        err_msg = 'Control ID does not exist'(e13).
*        err_value = gt_mcuser-contid.
*        l_field = c_fields-contid.
*        PERFORM append_output USING g_file_name gf_err l_field
*                                    err_value err_msg.
**        DELETE gt_mcuser WHERE l_index EQ g_index.
**        CONTINUE.
*      ELSEIF gf_err = 'S'.
**-- No Validation or message required
      ENDIF.

      SELECT SINGLE approver INTO g_approver         "#EC CI_SEL_NESTED
         FROM /psyng/mchdr
                  WHERE contid = gt_mcusrgrp-contid.
      IF sy-subrc NE 0.
        gf_err = 'E'.
        g_err_msg = 'No approver found for Control ID'(e15).
        g_err_value = gt_mcusrgrp-contid.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mcusrgrp WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.

    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcusrgrp WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.

* Validate conflict ID
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-conid.
    IF NOT gt_mcusrgrp-conid IS INITIAL.
      g_field = gc_fields-version.
      IF NOT gt_mcusrgrp-conid IS INITIAL.

*      PERFORM validate_conid_contid_vrs USING gt_mcuser-conid
*                                              gt_mcuser-contid
*                                              gt_mcuser-vrsio
*                                              gf_err.
*      IF NOT gf_err IS INITIAL.
*
*    err_msg = 'Proposed Mitigation is not defined for Conflict ID'(e11)
*.
*        CONCATENATE gt_mcuser-conid '-' gt_mcuser-contid '-'
*        gt_mcuser-vrsio INTO err_value.
*        l_field = c_fields-contid.

        PERFORM validate_conid_vrs USING gt_mcusrgrp-conid
                                         gt_mcusrgrp-vrsio
                                         gf_err.
        IF gf_err EQ 'E'.

          g_err_msg = 'Conflict ID does not match with version'(e27).
          CONCATENATE gt_mcusrgrp-conid '-' gt_mcusrgrp-vrsio
          INTO g_err_value.
          g_field = gc_fields-conid.
          PERFORM append_output USING g_file_name gf_err g_field
                                      g_err_value g_err_msg.

          CLEAR: g_err_msg,g_err_value,gf_err.
          DELETE gt_mcusrgrp WHERE l_index EQ g_index.
          CONTINUE.
        ENDIF.
      ELSE.
        CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
        gf_err = 'E'.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mcusrgrp WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcusrgrp WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.

*****Validate Auditor
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-auditor.
    IF NOT gt_mcusrgrp-auditor IS INITIAL.

      IF NOT gt_mcusrgrp-auditor IS INITIAL.
*--Check if we need to validate the auditor
*      IF gf_val_mit_aud IS INITIAL.
*        PERFORM get_val_mit_aud.
*      ENDIF.

        IF g_mit_audt_hdr_list = 'Y'.
          SELECT SINGLE mandt INTO sy-mandt          "#EC CI_SEL_NESTED
          FROM /psyng/mcauditor
                        WHERE contid  = gt_mcusrgrp-contid
                          AND auditor = gt_mcusrgrp-auditor.
          IF NOT sy-subrc = 0.
            gf_err = 'E'.
            g_err_msg = 'Invalid Auditor'.
            g_err_value = gt_mcusrgrp-auditor.
            g_field = gc_fields-auditor.
            PERFORM append_output USING g_file_name gf_err g_field
                                        g_err_value g_err_msg.
            CLEAR: g_err_msg,g_err_value,gf_err.
            DELETE gt_mcusrgrp WHERE l_index EQ g_index.
            CONTINUE.
          ENDIF.
*"THIS IS DUE TO THE REMOTE MITIGATION ASSIGNMENTS
*        ELSE.
*          PERFORM validate_userid CHANGING gt_mcuser-auditor
*                                        gf_err.
*          IF gf_err EQ 'E'.
**        err_msg = text-121.
*            err_value = gt_mcusrgrp-auditor.
*            CONCATENATE l_field text-121 INTO err_msg.
*            PERFORM append_output USING g_file_name gf_err l_field
*                                        err_value err_msg.
*
*            DELETE gt_mcusrgrp WHERE l_index EQ g_index.
*            CONTINUE.
*          ENDIF.
        ENDIF.
      ELSE.
*   Check that at least one auditor is maintained for the
*   mitigating control ID
        SELECT SINGLE mandt INTO sy-mandt            "#EC CI_SEL_NESTED
         FROM /psyng/mcauditor
                      WHERE contid = gt_mcusrgrp-contid.
        IF sy-subrc <> 0.
          gf_err = 'E'.
      g_err_msg = 'No Editor Maintained for Mitigation Control ID'(e31).
          g_err_value = gt_mcusrgrp-contid.
          g_field = gc_fields-contid.
          PERFORM append_output USING g_file_name gf_err g_field
                                      g_err_value g_err_msg.
          CLEAR: g_err_msg,g_err_value,gf_err.
          DELETE gt_mcusrgrp WHERE l_index EQ g_index.
          CONTINUE.
        ENDIF.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcusrgrp WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.


*     *_____validate version_____
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-version.
    l_vrs = gt_mcusrgrp-vrsio.
    IF NOT l_vrs EQ space.


      PERFORM validate_conid_contid_vrs USING gt_mcusrgrp-conid
                                              gt_mcusrgrp-contid
                                              gt_mcusrgrp-vrsio
                                              gf_err.
      IF gf_err EQ 'E'.

  g_err_msg = 'Proposed Mitigation is not defined for Conflict ID'(e11).
        CONCATENATE gt_mcusrgrp-conid '-' gt_mcusrgrp-contid '-'
        gt_mcusrgrp-vrsio INTO g_err_value.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.

        CLEAR: g_err_msg,g_err_value,gf_err.


        DELETE gt_mcusrgrp WHERE l_index EQ g_index.
        CONTINUE.
      ELSEIF gf_err EQ 'W'.
   g_err_msg = 'Proposed Mitigation is not defined for Conflictid'(e11).
        CONCATENATE gt_mcusrgrp-conid '-' gt_mcusrgrp-contid '-'
        gt_mcusrgrp-vrsio INTO g_err_value.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.

        CLEAR: g_err_msg,g_err_value,gf_err.
      ELSEIF gf_err = 'S'.
*-- No Validation or message required

      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcuser WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.


*********Date validation
    PERFORM validate_date USING gt_mcusrgrp-from_date
                                gt_mcusrgrp-to_date
                                g_field
                                gf_err
                                g_err_value
                                g_err_msg.
    IF NOT gf_err IS INITIAL.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      CLEAR: g_err_msg,g_err_value,gf_err.
      DELETE gt_mcusrgrp WHERE l_index EQ g_index.
    ENDIF.
  ENDLOOP.
*  DESCRIBE TABLE gt_mcusrgrp LINES g_index.

*  PERFORM check_sucess.

ENDFORM.                    " validate_user_group
*&---------------------------------------------------------------------*
*&      Form  validate_user_role
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM validate_user_role.
  DATA:l_vers(3) TYPE c.
  g_file_name = p_rlassf.
  CLEAR: g_err_msg,g_err_value,gf_err.
  LOOP AT gt_mcrole.
*    TRANSLATE gt_mcrole TO UPPER CASE.
    g_index = gt_mcrole-l_index.
* Validate role
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-role.
    IF NOT gt_mcrole-agr_name IS INITIAL.

      SELECT SINGLE mandt INTO sy-mandt FROM agr_define
                    WHERE agr_name = gt_mcrole-agr_name.
      IF sy-subrc <> 0.
        gf_err = 'E'.
        g_err_msg = 'Invalid Role name'(e18).
        g_err_value = gt_mcrole-agr_name.
        g_field = gc_fields-role.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mcrole WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcrole WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.
* Validate conflict ID
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-conid.
    IF NOT gt_mcrole-conid IS INITIAL.

      PERFORM validate_conid_vrs USING gt_mcrole-conid
                                       gt_mcrole-vrsio
                                       gf_err.
      IF gf_err EQ 'E'.

        g_err_msg = 'Conflict ID does not match with version'(e19).
       CONCATENATE gt_mcrole-conid '-' gt_mcrole-vrsio INTO g_err_value
    .
        g_field = gc_fields-conid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        CLEAR: g_err_msg,g_err_value,gf_err.
        DELETE gt_mcrole WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcrole WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.

* Validate mitigating control ID
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-contid.
    IF NOT gt_mcrole-contid IS INITIAL.
*      SELECT SINGLE mandt INTO sy-mandt              "#EC CI_SEL_NESTED
*         FROM /psyng/mchdr
*              WHERE contid = gt_mcrole-contid.
*      IF sy-subrc NE 0.
*        gf_err = 'E'.
      PERFORM validate_contid_header_2 USING gt_mcrole-contid
                                             gf_err.

      IF gf_err = 'E'.
        g_err_msg = 'Control ID does not exist'(e13).
        g_err_value = gt_mcrole-contid.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mcrole WHERE l_index EQ g_index.
        CONTINUE.
*      ELSEIF gf_err = 'W'.
*        err_msg = 'Control ID does not exist'(e13).
*        err_value = gt_mcuser-contid.
*        l_field = c_fields-contid.
*        PERFORM append_output USING g_file_name gf_err l_field
*                                    err_value err_msg.
**        DELETE gt_mcuser WHERE l_index EQ g_index.
**        CONTINUE.
*      ELSEIF gf_err = 'S'.
**-- No Validation or message required
      ENDIF.


      SELECT SINGLE approver INTO g_approver         "#EC CI_SEL_NESTED
         FROM /psyng/mchdr
                  WHERE contid = gt_mcrole-contid.
      IF sy-subrc NE 0.
        gf_err = 'E'.
        g_err_msg = 'No approver found for Control ID'(e15).
        g_err_value = gt_mcrole-contid.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        CLEAR: g_err_msg,g_err_value,gf_err.
        DELETE gt_mcrole WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcrole WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.

*  Check for the Control id corresponds to Conflict ID
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-version.
    l_vers = gt_mcrole-vrsio.
    IF NOT l_vers EQ space.

      PERFORM validate_conid_contid_vrs USING gt_mcrole-conid
                                              gt_mcrole-contid
                                              gt_mcrole-vrsio
                                              gf_err.
      IF gf_err EQ 'E'.

  g_err_msg = 'Proposed Mitigation is not defined for Conflict ID'(e11).
        CONCATENATE gt_mcrole-conid '-' gt_mcrole-contid '-'
        gt_mcrole-vrsio INTO g_err_value.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.

        DELETE gt_mcrole WHERE l_index EQ g_index.
        CONTINUE.


      ELSEIF gf_err EQ 'W'.
  g_err_msg = 'Proposed Mitigation is not defined for Conflict ID'(e11).
        CONCATENATE gt_mcrole-conid '-' gt_mcrole-contid '-'
        gt_mcrole-vrsio INTO g_err_value.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
      ELSEIF gf_err = 'S'.
*-- No Validation or message required

      ENDIF.
      CLEAR: g_err_msg,g_err_value,gf_err.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcrole WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.

    IF NOT gt_mcrole-auditor IS INITIAL.
*--Check if we need to validate the auditor
      CLEAR: g_err_msg,g_err_value,gf_err.
      g_field = gc_fields-auditor.
      IF NOT gt_mcrole-auditor IS INITIAL.

        IF g_mit_audt_hdr_list = 'Y'.
          SELECT SINGLE mandt INTO sy-mandt          "#EC CI_SEL_NESTED
             FROM /psyng/mcauditor
                        WHERE contid  = gt_mcrole-contid
                          AND auditor = gt_mcrole-auditor.
          IF NOT sy-subrc = 0.
            gf_err = 'E'.
            g_err_msg = 'Invalid Auditor'(e20).
            g_err_value = gt_mcrole-auditor.
            g_field = gc_fields-auditor.
            PERFORM append_output USING g_file_name gf_err g_field
                                        g_err_value g_err_msg.
            CLEAR: g_err_msg,g_err_value,gf_err.
            DELETE gt_mcrole WHERE l_index EQ g_index.
            CONTINUE.
          ENDIF.
*"THIS IS DUE TO THE REMOTE MITIGATION ASSIGNMENTS
*        ELSE.
*          PERFORM validate_userid CHANGING gt_mcrole-auditor
*                                        gf_err.
*          IF gf_err EQ 'E'.
**        err_msg = text-121.
*            err_value = gt_mcrole-auditor.
*            CONCATENATE l_field text-121 INTO err_msg.
*            PERFORM append_output USING g_file_name gf_err l_field
*                                        err_value err_msg.
*            CLEAR: err_msg,err_value,gf_err.
*            DELETE gt_mcrole WHERE l_index EQ g_index.
*            CONTINUE.
*          ENDIF.

        ENDIF.
      ELSE.
*   Check that at least one auditor is maintained for the
*   mitigating control ID
        SELECT SINGLE mandt INTO sy-mandt            "#EC CI_SEL_NESTED
         FROM /psyng/mcauditor
                      WHERE contid = gt_mcrole-contid.
        IF sy-subrc <> 0.
          gf_err = 'E'.
     g_err_msg = 'No Auditor Maintained for Mitigation Control ID'(e21).
          g_err_value = gt_mcrole-contid.
          g_field = gc_fields-contid.
          PERFORM append_output USING g_file_name gf_err g_field
                                      g_err_value g_err_msg.
          CLEAR: g_err_msg,g_err_value,gf_err.
          DELETE gt_mcrole WHERE l_index EQ g_index.
          CONTINUE.
        ENDIF.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcrole WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.
******Date Validation
    PERFORM validate_date USING gt_mcrole-from_date
                              gt_mcrole-to_date
                              g_field
                              gf_err
                              g_err_value
                              g_err_msg.
    IF NOT gf_err IS INITIAL.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      CLEAR: g_err_msg,g_err_value,gf_err.
      DELETE gt_mcrole WHERE l_index EQ g_index.

    ENDIF.
  ENDLOOP.
*  DESCRIBE TABLE gt_mcrole LINES g_index.
*  PERFORM check_sucess.

ENDFORM.                    " validate_user_role
*&---------------------------------------------------------------------*
*&      Form  validate_crit_auth_usr
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM validate_crit_auth_usr.
  DATA:l_vers(3) TYPE c.
  g_file_name = p_crtfl.
  LOOP AT gt_mccauser.
*    TRANSLATE gt_mccauser TO UPPER CASE.
    g_index = gt_mccauser-l_index.
* Validate object ID
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-obj.
    IF NOT gt_mccauser-swaudid IS INITIAL.
      g_field = gc_fields-version.
      l_vers = gt_mccauser-vrsio.
      IF  NOT l_vers EQ space.

        SELECT SINGLE mandt INTO sy-mandt            "#EC CI_SEL_NESTED
             FROM /psyng/swaudhdr
                      WHERE vrsio   = gt_mccauser-vrsio
                        AND swaudid = gt_mccauser-swaudid.
        IF sy-subrc <> 0.
          gf_err = 'E'.
          g_err_msg = 'Invalid Object ID'(e22).
          g_err_value = gt_mccauser-swaudid.
          g_field = gc_fields-obj.
          PERFORM append_output USING g_file_name gf_err g_field
                                      g_err_value g_err_msg.
          CLEAR: g_err_msg,g_err_value,gf_err.
          DELETE gt_mccauser WHERE l_index EQ g_index.
          CONTINUE.
        ENDIF.
      ELSE.
        CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
        gf_err = 'E'.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mccauser WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.

    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mccauser WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.

* Validate mitigating control ID
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-contid.
    IF NOT gt_mccauser-contid IS INITIAL.
      SELECT SINGLE approver INTO g_approver         "#EC CI_SEL_NESTED
           FROM /psyng/mchdr
                  WHERE contid = gt_mccauser-contid.
      IF sy-subrc NE 0.
        gf_err = 'E'.
        g_err_msg = 'No approver found for Control ID'(e15).
        g_err_value = gt_mccauser-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mccauser WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mccauser WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.

*    Validating User ID
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-userid.
    IF NOT gt_mccauser-userid IS INITIAL.

      PERFORM validate_userid CHANGING gt_mccauser-userid
                                          gf_err.
      g_err_value = gt_mccauser-userid.
      IF gf_err EQ 'E'.

*        err_msg = text-121.
        g_field = gc_fields-userid.
        CONCATENATE g_field text-121 INTO g_err_msg.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        CLEAR: g_err_msg,g_err_value,gf_err.
        DELETE gt_mccauser WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mccauser WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.
***Validate Auditor
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-auditor.
    IF NOT gt_mccauser-auditor IS INITIAL.
*--Check if we need to validate the auditor
      IF g_mit_audt_hdr_list = 'Y'.
        SELECT SINGLE mandt INTO sy-mandt            "#EC CI_SEL_NESTED
            FROM /psyng/mcauditor
                      WHERE contid  = gt_mccauser-contid
                        AND auditor = gt_mccauser-auditor.
        IF NOT sy-subrc = 0.
          gf_err = 'E'.
          g_err_msg = 'Invalid Auditor'.
          g_err_value = gt_mccauser-auditor.
          g_field = gc_fields-auditor.
          PERFORM append_output USING g_file_name gf_err g_field
                                      g_err_value g_err_msg.
          CLEAR: g_err_msg,g_err_value,gf_err.
          DELETE gt_mccauser WHERE l_index EQ g_index.
          CONTINUE.
        ENDIF.
*"THIS IS DUE TO THE REMOTE MITIGATION ASSIGNMENTS
*      ELSE.
*        PERFORM validate_userid CHANGING gt_mccauser-auditor
*                                      gf_err.
*        IF gf_err EQ 'E'.
**        err_msg = text-121.
*          err_value = gt_mccauser-auditor.
*          CONCATENATE l_field text-121 INTO err_msg.
*          PERFORM append_output USING g_file_name gf_err l_field
*                                      err_value err_msg.
*          CLEAR: err_msg,err_value,gf_err.
*          DELETE gt_mccauser WHERE l_index EQ g_index.
*          CONTINUE.
*        ENDIF.
      ENDIF.
    ELSE.
*   Check that at least one auditor is maintained for the
*   mitigating control ID
      SELECT SINGLE mandt INTO sy-mandt              "#EC CI_SEL_NESTED
             FROM /psyng/mcauditor
                    WHERE contid = gt_mccauser-contid.
      IF sy-subrc <> 0.
        gf_err = 'E'.
      g_err_msg = 'No Editor Maintained for Mitigation Control ID'(e31).
        g_err_value = gt_mccauser-contid.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        CLEAR: g_err_msg,g_err_value,gf_err.
        DELETE gt_mccauser WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ENDIF.
*****      Validate Date
    PERFORM validate_date USING gt_mccauser-from_date
                              gt_mccauser-to_date
                              g_field
                              gf_err
                              g_err_value
                              g_err_msg.
    IF NOT gf_err IS INITIAL.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      CLEAR: g_err_msg,g_err_value,gf_err.
      DELETE gt_mccauser WHERE l_index EQ g_index.
    ENDIF.
*  * Check that the user ID is not the same as the approver ID

    IF gt_mccauser-userid = g_approver.
      gf_err = g_mit_aprv_eq_usr_msg.

**      PERFORM get_apr_msgtyp USING gf_err.
      IF NOT gf_err IS INITIAL.
        g_err_msg = 'User ID same as Approver ID'(e23).
        CONCATENATE gt_mccauser-userid '-'  g_approver
        INTO g_err_value.
        g_field = gc_fields-conid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        IF gf_err EQ 'E'.
          CLEAR: g_err_msg,g_err_value,gf_err.
          DELETE gt_mccauser WHERE l_index EQ g_index.
          CONTINUE.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.
  DESCRIBE TABLE gt_mccauser LINES g_index.
*  PERFORM check_sucess.
ENDFORM.                    " validate_crit_auth_usr

*&---------------------------------------------------------------------*
*&      Form  validate_crit_auth_role
*&---------------------------------------------------------------------*
*       Validate Critical Auth role assignments
*----------------------------------------------------------------------*
FORM validate_crit_auth_role.
  DATA: l_vers(3) TYPE c.


  g_file_name = p_crrlfl.

  LOOP AT gt_mccarole.
    g_index = gt_mccarole-l_index.

*    Validate vrsio
    CLEAR: g_err_msg, g_err_value, gf_err.
    g_field = gc_fields-version.
    l_vers = gt_mccarole-vrsio.

    IF NOT l_vers EQ space.
      SELECT SINGLE mandt INTO sy-mandt              "#EC CI_SEL_NESTED
           FROM /psyng/swsodvers
                  WHERE vrsio = gt_mccarole-vrsio.
      IF sy-subrc NE 0.
        gf_err    = 'E'.
*        err_msg   = 'No approver found for Control ID'(e15).
        g_err_msg   = 'Version does not exist'(e38).
        g_err_value = gt_mccarole-vrsio.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mccarole WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mccarole WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.


*   Validate object ID
    CLEAR: g_err_msg, g_err_value, gf_err.
    g_field = gc_fields-obj.
    IF NOT gt_mccarole-swaudid IS INITIAL.
      g_field = gc_fields-version.
      l_vers = gt_mccarole-vrsio.

      IF NOT l_vers EQ space.
        SELECT SINGLE mandt INTO sy-mandt            "#EC CI_SEL_NESTED
             FROM /psyng/swaudhdr
                      WHERE vrsio   = gt_mccarole-vrsio
                        AND swaudid = gt_mccarole-swaudid.
        IF sy-subrc <> 0.
          gf_err    = 'E'.
          g_err_msg   = 'Invalid Object ID'(e22).
          g_err_value = gt_mccarole-swaudid.
          g_field   = gc_fields-obj.
          PERFORM append_output USING g_file_name gf_err g_field
                                      g_err_value g_err_msg.
          CLEAR: g_err_msg, g_err_value, gf_err.
          DELETE gt_mccarole WHERE l_index EQ g_index.
          CONTINUE.
        ENDIF.
      ELSE.
        CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
        gf_err = 'E'.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mccarole WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mccarole WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.

*   Validate mitigating control ID
    CLEAR: g_err_msg, g_err_value, gf_err.
    g_field = gc_fields-contid.
    IF NOT gt_mccarole-contid IS INITIAL.
      SELECT SINGLE approver INTO g_approver         "#EC CI_SEL_NESTED
           FROM /psyng/mchdr
                  WHERE contid = gt_mccarole-contid.
      IF sy-subrc NE 0.
        gf_err    = 'E'.
*        err_msg   = 'No approver found for Control ID'(e15).
        g_err_msg   = 'Control ID does not exist'(e16).
        g_err_value = gt_mccarole-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mccarole WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mccarole WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.

*   Validating Role
    CLEAR: g_err_msg, g_err_value, gf_err.
    g_field = gc_fields-userid.
    IF NOT gt_mccarole-agr_name IS INITIAL.
      SELECT SINGLE mandt INTO sy-mandt FROM agr_define
                    WHERE agr_name = gt_mccarole-agr_name.
      IF sy-subrc <> 0.
        gf_err    = 'E'.
        g_err_msg   = 'Invalid Role name'(e18).
        g_err_value = gt_mccarole-agr_name.
        g_field   = gc_fields-role.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mccarole WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mccarole WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.

*   Validate Auditor
    CLEAR: g_err_msg, g_err_value, gf_err.
    g_field = gc_fields-auditor.

    IF NOT gt_mccarole-auditor IS INITIAL.
*
      SELECT SINGLE mandt INTO sy-mandt FROM usr02
       WHERE bname EQ gt_mccarole-auditor.
      IF sy-subrc EQ 0.
*-----Check if we need to validate the auditor
        IF g_mit_audt_hdr_list = 'Y'.
          SELECT SINGLE mandt INTO sy-mandt          "#EC CI_SEL_NESTED
              FROM /psyng/mcauditor
                        WHERE contid  = gt_mccarole-contid
                          AND auditor = gt_mccarole-auditor.
          IF NOT sy-subrc = 0.
            gf_err    = 'E'.
            g_err_msg   = 'Invalid Auditor'.
            g_err_value = gt_mccarole-auditor.
            g_field   = gc_fields-auditor.
            PERFORM append_output USING g_file_name gf_err g_field
                                        g_err_value g_err_msg.
            CLEAR: g_err_msg, g_err_value, gf_err.
            DELETE gt_mccarole WHERE l_index EQ g_index.
            CONTINUE.
          ENDIF.
        ENDIF.
      ELSE.
        gf_err    = 'E'.
        g_err_msg = 'Auditor does not exist in User Master'(e39).
        g_err_value = gt_mccarole-auditor.
        g_field   = gc_fields-auditor.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        CLEAR: g_err_msg, g_err_value, gf_err.
        DELETE gt_mccarole WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ELSE.
*     Check that at least one auditor is maintained for the
*     mitigating control ID
      SELECT SINGLE mandt INTO sy-mandt              "#EC CI_SEL_NESTED
             FROM /psyng/mcauditor
                    WHERE contid = gt_mccarole-contid.
      IF sy-subrc <> 0.
        gf_err    = 'E'.
      g_err_msg = 'No Editor Maintained for Mitigation Control ID'(e31).
        g_err_value = gt_mccarole-contid.
        g_field   = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        CLEAR: g_err_msg, g_err_value, gf_err.
        DELETE gt_mccarole WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.
    ENDIF.

*   Validate Date
    PERFORM validate_date USING gt_mccarole-from_date
                                gt_mccarole-to_date
                                g_field
                                gf_err
                                g_err_value
                                g_err_msg.
    IF NOT gf_err IS INITIAL.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      CLEAR: g_err_msg, g_err_value, gf_err.
      DELETE gt_mccarole WHERE l_index EQ g_index.
    ENDIF.
  ENDLOOP.

  DESCRIBE TABLE gt_mccarole LINES g_index.
ENDFORM.                    " validate_crit_auth_role

*&---------------------------------------------------------------------*
*&      Form  check_sucess
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM check_sucess USING i_filename.
  CLEAR g_index.
  READ TABLE gt_output WITH KEY fl_name = i_filename
                                id      = gc_error_icon.
  IF sy-subrc NE 0.
    CLEAR: g_err_msg,g_err_value,gf_err,g_field.
    g_err_value = 'No Errors'.
    IF dnldtabs EQ 'X'.
      g_err_msg = text-045.
    ELSE.
      g_err_msg = text-048.
    ENDIF.
    PERFORM append_output USING i_filename gf_err g_field
                                g_err_value g_err_msg.
  ENDIF.
ENDFORM.                    " check_sucess
*&---------------------------------------------------------------------*
*&      Form  authority_check_ex
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->L_OBJ  text
*      -->L_ACTVT  text
*      -->L_VRSIO  text
*----------------------------------------------------------------------*
FORM authority_check_ex USING    l_obj
                                 l_actvt.
*                                 l_vrsio.
*  DATA:l_err_text(30),
*       l_activity(10).
  DATA: err_msg(60) TYPE c,
        err_value(20) TYPE c.
  DATA:l_field(20) TYPE c.
  CLEAR: err_msg,err_value,gf_err.

  AUTHORITY-CHECK OBJECT l_obj
           ID 'ACTVT'      FIELD l_actvt
           ID 'Y&SW_VRSIO' DUMMY
           ID 'Y&SW_CNTID' DUMMY
           ID 'Y&SW_CONID' DUMMY
           ID 'Y&SW_BNAME' DUMMY
           ID 'Y&SW_COMP'  DUMMY
           ID 'ACT_GROUP'  DUMMY. "#EC SAST_CI_GEN_CHECK
  IF sy-subrc NE 0.
    CLEAR g_index.
    gf_err = 'E'.
    IF l_actvt = 'UL'.
      err_msg = text-e08.
    ELSE.
      err_msg = text-e07.
    ENDIF.
    err_value = ''.
    IF NOT g_file_name CS '\'.
      CONCATENATE path1 g_file_name  INTO g_file_name.
    ENDIF.
    PERFORM append_output USING g_file_name gf_err l_field
                                err_value err_msg.

*    CASE g_file_name.
*      WHEN 'usrasfl'.
*        CONCATENATE l_activity text-e03 l_vrsio INTO l_err_text.
*        CONDENSE l_err_text.
*      WHEN 'usrgrpfl'.
*        CONCATENATE l_activity text-e04 l_vrsio INTO l_err_text.
*        CONDENSE l_err_text.
*      WHEN 'rolassfl'.
*        CONCATENATE l_activity text-e05 l_vrsio INTO l_err_text.
*        CONDENSE l_err_text.
*      WHEN 'crtfl'.
*        CONCATENATE l_activity text-e06 l_vrsio INTO l_err_text.
*        CONDENSE l_err_text.
*    ENDCASE.
*         You are not authorizied to & & & &
*    MESSAGE w108(/psyng/sw) WITH l_err_text.
  ENDIF.

ENDFORM.                    " authority_check_ex
*&---------------------------------------------------------------------*
*&      Form  confirm_skip_validation
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM confirm_skip_validation.
  DATA: l_ans.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
       EXPORTING
            titlebar              = text-w00
            text_question         = text-w01
            text_button_1         = 'Yes'
            icon_button_1         = 'ICON_SYSTEM_OKAY'
            text_button_2         = 'No'
            icon_button_2         = 'ICON_SYSTEM_CANCEL'
            display_cancel_button = ' '
            popup_type            = 'ICON_MESSAGE_WARNING'
       IMPORTING
            answer                = l_ans
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND   = 1
             OTHERS           = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  IF l_ans = 2.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.                    " confirm_skip_validation
*&---------------------------------------------------------------------*
*&      Form  download_status
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SY_SUBRC  text

*----------------------------------------------------------------------*
FORM download_status USING    sy_subrc.
  IF sy-subrc EQ 0.
    CHECK g_status NE 'X'.
    MESSAGE i113(/psyng/sw) WITH text-045.
    g_status = 'X'.
  ELSE.
    MESSAGE i113(/psyng/sw) WITH text-046.
  ENDIF.

ENDFORM.                    " download_status
*&---------------------------------------------------------------------*
*&      Form  directory_check
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM directory_check.

*  TYPE-POOLS: abap.

  DATA: l_rc TYPE abap_bool.
  DATA: l_file TYPE string.
  l_file = path1.
  CALL METHOD cl_gui_frontend_services=>file_exist
"#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
      file            = l_file
    RECEIVING
      result          = l_rc
*    EXCEPTIONS
*      CNTL_ERROR      = 1
*      ERROR_NO_GUI    = 2
*      WRONG_PARAMETER = 3
*      others          = 4
          .
*  IF sy-subrc <> 0.
**   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
**              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*  ENDIF.
*
*  CALL METHOD cl_gui_frontend_services=>directory_exist
*    EXPORTING
*      directory            = dir
*    RECEIVING
*      result               = rc
*    EXCEPTIONS
*      cntl_error           = 1
*      error_no_gui         = 2
*      wrong_parameter      = 3
*      not_supported_by_gui = 4
*      OTHERS               = 5.
  IF l_rc NE 'X'.

    MESSAGE  s113(/psyng/sw) WITH text-174.

  ENDIF.
ENDFORM.                    " directory_check

*&---------------------------------------------------------------------*
*&      Form  append_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_MITHFLE  text
*      -->P_GF_ERR  text
*      -->P_CONTID  text
*      -->P_ERR_VALUE  text
*      -->P_ERR_MSG  text
*----------------------------------------------------------------------*
FORM append_output USING    p_fl_name
                            p_gf_err
                            p_fld_name
                            p_err_value
                            p_err_msg.

  gt_output-fl_name = p_fl_name.

  CASE p_gf_err.
    WHEN 'E'.
      gt_output-id = '@0A@'.
      g_errors_count = g_errors_count + 1.
    WHEN 'W'.
      gt_output-id = '@09@'.
      g_warnings_count = g_warnings_count + 1.
    WHEN OTHERS.
      gt_output-id = '@08@'.
  ENDCASE.

  CASE p_fl_name.
    WHEN  p_mithf.
      gt_output-sort_file = 1.
    WHEN p_mitxf.
      gt_output-sort_file = 2.
    WHEN  p_mitdf.
      gt_output-sort_file = 3.
    WHEN p_mitrf.
      gt_output-sort_file = 4.
    WHEN  p_mitaf.
      gt_output-sort_file = 5.
    WHEN  p_usasfl.
      gt_output-sort_file = 6.
    WHEN  p_usgrpf.
      gt_output-sort_file = 7.
    WHEN  p_rlassf.
      gt_output-sort_file = 8.
    WHEN  p_crtfl.
      gt_output-sort_file = 9.
    WHEN  p_crrlfl.
      gt_output-sort_file = 10.
    WHEN   p_mitrhd.
      gt_output-sort_file = 11.
  ENDCASE.

*      con_id LIKE trdir-name,
  gt_output-err_fld = p_fld_name.
  gt_output-err_val = p_err_value.
  gt_output-err_msg = p_err_msg.
  gt_output-l_index = g_index.
  APPEND gt_output.
  CLEAR gt_output.
ENDFORM.                    " append_output
*&---------------------------------------------------------------------*
*&      Form  validate_userid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_USERID  text
*      -->P_GF_ERR  text
*----------------------------------------------------------------------*
FORM validate_userid CHANGING    p_userid
                              gf_err.

  TRANSLATE p_userid TO UPPER CASE.
  READ TABLE gt_usr02 WITH KEY bname = p_userid
             BINARY SEARCH TRANSPORTING NO FIELDS.
  IF sy-subrc NE 0.
    gf_err = 'E'.
  ENDIF.

ENDFORM.                    " validate_userid
*&---------------------------------------------------------------------*
*&      Form  VALIDATE_CONTID_HEADER_2
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CONTID  text
*      -->P_GF_ERR  text
*----------------------------------------------------------------------*
FORM validate_contid_header_2 USING    p_contid
                                       gf_err.

  READ TABLE gt_mchdr_db WITH KEY contid = p_contid
             BINARY SEARCH.

  IF sy-subrc <> 0.
    READ TABLE gt_mchdr WITH KEY contid = p_contid
               BINARY SEARCH.
    IF sy-subrc <> 0.
      gf_err = 'E'."mit_valid_for_con.
    ENDIF.
  ENDIF.
ENDFORM.                    " VALIDATE_CONTID_HEADER_2
*&---------------------------------------------------------------------*
*&      Form  validate_tcode
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_TCODE  text
*      -->P_GF_ERR  text
*----------------------------------------------------------------------*
FORM validate_tcode USING    p_tcode
                             gf_err.

  READ TABLE gt_tstc WITH TABLE KEY tcode = p_tcode
             TRANSPORTING NO FIELDS.
  IF sy-subrc <> 0.
    gf_err = 'E'.
  ENDIF.
ENDFORM.                    " validate_tcode
*&---------------------------------------------------------------------*
*&      Form  validate_frequencies
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_FREQUENCY  text
*      -->P_GF_ERR  text
*----------------------------------------------------------------------*
FORM validate_frequencies USING    p_frequency
                                   gf_err.
*  READ TABLE gt_frequencies WITH KEY domvalue_l =  p_frequency
*                TRANSPORTING NO FIELDS.
  READ TABLE gt_frequencies WITH KEY freq =  p_frequency
                TRANSPORTING NO FIELDS.
  IF sy-subrc <> 0.
    gf_err = 'E'.
  ENDIF.

ENDFORM.                    " validate_frequencies
*&---------------------------------------------------------------------*
*&      Form  validate_report
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_REPID  text
*      -->P_GF_ERR  text
*----------------------------------------------------------------------*
FORM validate_report USING    p_repid
                              gf_err.

  READ TABLE gt_tadir WITH KEY obj_name = p_repid
             BINARY SEARCH TRANSPORTING NO FIELDS.
  IF sy-subrc <> 0.
    gf_err = 'E'.
  ENDIF.

ENDFORM.                    " validate_report
*&---------------------------------------------------------------------*
*&      Form  output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM output.
  DATA: ls_program TYPE sy-repid.

  ls_program = sy-repid.

  CLEAR : wa_fieldcat_alv, i_fieldcat_alv.

  ls_program = sy-repid.

  SORT gt_output BY sort_file l_index ASCENDING.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = ls_program
            i_internal_tabname = 'GT_OUTPUT'
            i_inclname         = ls_program
       CHANGING
            ct_fieldcat        = i_fieldcat_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             INCONSISTENT_INTERFACE = 1
             PROGRAM_ERROR          = 2
             OTHERS                 = 3 .
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  PERFORM column_titles.
*  PERFORM sort_table.

  gs_alv_layout-zebra = 'X'.
  gs_alv_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program     = ls_program
            i_callback_top_of_page = 'TOP-OF-PAGE'  "see FORM
            is_layout              = gs_alv_layout
            i_save                 = 'A'
*            is_variant             = gs_variant
            it_fieldcat            = i_fieldcat_alv
*            it_sort                = sort
       TABLES
            t_outtab               = gt_output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  FREE : gt_output.
  REFRESH gt_output.

ENDFORM.                    " output
*&---------------------------------------------------------------------*
*&      Form  validate_conid_vrs
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CONID  text
*      -->P_VRSIO  text
*      -->GF_ERR  text
*----------------------------------------------------------------------*
FORM validate_conid_vrs USING    p_conid
                                 p_vrsio
                                 gf_err.

  SELECT SINGLE mandt INTO sy-mandt                  "#EC CI_SEL_NESTED
     FROM /psyng/conflict
                WHERE conid = p_conid
                  AND vrsio = p_vrsio.
  IF sy-subrc <> 0.

    gf_err = 'E'.
  ENDIF.
ENDFORM.                    " validate_conid_vrs
*&---------------------------------------------------------------------*
*&      Form  validate_contid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CONTID  text
*      -->P_GF_ERR  text
*----------------------------------------------------------------------*
FORM validate_contid USING    p_contid
                              gf_err.

  READ TABLE gt_mchdr_db WITH KEY contid = p_contid
             BINARY SEARCH.

  IF sy-subrc <> 0.
    gf_err = 'E'.
  ENDIF.

ENDFORM.                    " validate_contid
*&---------------------------------------------------------------------*
*&      Form  validate_conid_contid_vrs
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CONID  text
*      -->P_CONTID  text
*      -->P_VRSIO  text
*      -->P_GF_ERR  text
*----------------------------------------------------------------------*
FORM validate_conid_contid_vrs USING    p_conid
                                        p_contid
                                        p_vrsio
                                        gf_err.

  CHECK g_mit_con_defined_only = 'Y'.
  SELECT SINGLE mandt FROM /psyng/conflict           "#EC CI_SEL_NESTED
   INTO sy-mandt
       WHERE ( contid = p_contid OR contid = ' ' )
         AND   conid  = p_conid
         AND   vrsio  = p_vrsio.
  IF sy-subrc <> 0.
    SELECT SINGLE mandt FROM /psyng/conpmit
      INTO sy-mandt
         WHERE contid = p_contid
         AND   conid  = p_conid
         AND   vrsio  = p_vrsio.
    IF sy-subrc <> 0.
      gf_err = g_mit_valid_for_con."'W'.
    ENDIF.
  ENDIF.
ENDFORM.                    " validate_conid_contid_vrs
*&---------------------------------------------------------------------*
*&      Form  extended_auditor_check
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_USERID  text
*      -->P_CONTID  text
*      -->P_AUDITOR  text
*      -->P_GF_ERR  text
*----------------------------------------------------------------------*
FORM extended_auditor_check USING    p_userid
                                     p_contid
                                     p_auditor
                                     gf_err.
  DATA :lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.

*--Get the company
  lt_uinfo-bname = p_userid.
  APPEND lt_uinfo.
  CALL FUNCTION '/PSYNG/SW_USER_INFO'
       EXPORTING
            i_name_only  = 'X'
            i_mr_company = 'X'
       TABLES
            sw_uinfo     = lt_uinfo.

  READ TABLE lt_uinfo INDEX 1 TRANSPORTING company.

  SELECT SINGLE mandt INTO sy-mandt                  "#EC CI_SEL_NESTED
     FROM /psyng/mcauditor
                WHERE contid  = p_contid
                  AND auditor = p_auditor
                  AND ( company = lt_uinfo-company
                     OR company = space ).
  IF NOT sy-subrc = 0.
    gf_err = 'E'.
  ENDIF.

ENDFORM.                    " extended_auditor_check
*&---------------------------------------------------------------------*
*&      Form  validate_date
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_FROM_DATE  text
*      -->P_TO_DATE  text
*      -->P_L_FIELD  text
*      -->P_GF_ERR  text
*      -->P_ERR_VALUE  text
*      -->P_ERR_MSG  text
*      -->P_ENDLOOP  text
*----------------------------------------------------------------------*
FORM validate_date USING    l_from_date
                            l_to_date
                            l_field gf_err
                            err_value err_msg.

  DATA:l_date TYPE d.
*
*  l_from_date = p_from_date.
*  l_to_date  = p_to_date..

  l_field = 'From Date'.
  IF NOT l_from_date IS INITIAL.
    l_date = l_from_date.
    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
         EXPORTING
              date                      = l_date
         EXCEPTIONS
              plausibility_check_failed = 1
              OTHERS                    = 2.
    IF sy-subrc <> 0.
      gf_err = 'E'.
      err_value = l_from_date.
      err_msg = 'invalid date format'(e24).
      EXIT.
    ENDIF.
  ELSE.
    CONCATENATE l_field ' cannot be initial'(e01) INTO err_msg.
    gf_err = 'E'.
    EXIT.
  ENDIF.

**Validate from date.
  l_field = 'To Date'.

  IF NOT l_to_date IS INITIAL.

    l_date = l_to_date.

    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
         EXPORTING
              date                      = l_date
         EXCEPTIONS
              plausibility_check_failed = 1
              OTHERS                    = 2.
    IF sy-subrc <> 0.
      gf_err = 'E'.
      err_value = l_to_date.
      err_msg = 'Invalid date format'(e24).
      EXIT.
    ENDIF.
  ELSE.
    CONCATENATE l_field ' cannot be initial'(e01) INTO err_msg.
    gf_err = 'E'.
    EXIT.
  ENDIF.

**  IF l_to_date GT 0 AND l_from_date GT 0.
***  IF l_to_date GT 0 OR
***  l_from_date  GT 0.
  IF l_to_date < l_from_date.
    gf_err = 'E'.
    CONCATENATE l_from_date '-' l_to_date INTO err_value.
*      err_value = l_date.
    err_msg = 'Invalid date range'(e25).
    EXIT.
  ELSEIF l_to_date < sy-datum.
    gf_err = 'E'.
    MOVE l_to_date TO err_value.
    err_msg  = 'To Date should be greater than current date'.
    EXIT.
  ENDIF.
**
**
**  IF l_to_date GT 0 AND l_from_date EQ 0.
***    IF l_to_date < l_from_date.
***      err_flag = 'X'.
***      CONCATENATE l_from_date '-' l_to_date INTO err_value.
***      error_type = text-ed3."
***      EXIT.
**    IF l_to_date < sy-datum.
**      err_flag = 'X'.
**      CONCATENATE l_from_date '-' l_to_date INTO err_value.
**      error_type = text-ed3.
**      EXIT.
**    ELSE.
**      l_from_date = sy-datum.
**    ENDIF.
**
**  ELSEIF l_to_date EQ 0 AND l_from_date GT 0.
**    IF  l_from_date GT 99991231.
**      err_flag = 'X'.
**      CONCATENATE l_from_date '-' l_to_date INTO err_value.
***      err_value = l_date.
**      error_type = text-ed2.
**      EXIT.
**    ELSE.
**      l_to_date = '99991231'.
**    ENDIF.
**  ENDIF.
**
***  IF l_to_date GT 0 AND l_from_date EQ 0.
**
**  IF l_to_date EQ 0 AND l_from_date EQ 0.
**    l_from_date = sy-datum.
**    l_to_date = '99991231'.
**  ENDIF.


ENDFORM.                    " validate_date
*&---------------------------------------------------------------------*
*&      Form  column_titles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM column_titles.
  CHECK sy-subrc = 0.
  wa_fieldcat_alv-col_pos = '1'.
  wa_fieldcat_alv-seltext_s = text-h01.
  wa_fieldcat_alv-seltext_m = text-h01.
  wa_fieldcat_alv-seltext_l = text-h01.
  wa_fieldcat_alv-reptext_ddic = text-h01.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                          TRANSPORTING
                              col_pos
                              seltext_s
                              seltext_m
                              seltext_l
                              reptext_ddic
                          WHERE fieldname = 'FL_NAME'.

*****************************************
  IF upldtabs EQ 'X'.
    CHECK sy-subrc = 0.
    wa_fieldcat_alv-col_pos = '2'.
    wa_fieldcat_alv-seltext_s = text-h06.
    wa_fieldcat_alv-seltext_m = text-h06.
    wa_fieldcat_alv-seltext_l = text-h06.
    wa_fieldcat_alv-reptext_ddic = text-h06.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                            TRANSPORTING
                                col_pos
                                seltext_s
                                seltext_m
                                seltext_l
                                reptext_ddic
                            WHERE fieldname = 'L_INDEX'.
  ELSE.
    CHECK sy-subrc = 0.
    wa_fieldcat_alv-col_pos = '2'.
    wa_fieldcat_alv-seltext_s = text-h08.
    wa_fieldcat_alv-seltext_m = text-h08.
    wa_fieldcat_alv-seltext_l = text-h07.
    wa_fieldcat_alv-reptext_ddic = text-h07.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                            TRANSPORTING
                                col_pos
                                seltext_s
                                seltext_m
                                seltext_l
                                reptext_ddic
                            WHERE fieldname = 'L_INDEX'.
  ENDIF.
*****************************************
  CHECK sy-subrc = 0.
  wa_fieldcat_alv-col_pos = '3'.
  wa_fieldcat_alv-seltext_s = text-h02.
  wa_fieldcat_alv-seltext_m = text-h02.
  wa_fieldcat_alv-seltext_l = text-h02.
  wa_fieldcat_alv-reptext_ddic = text-h02.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                          TRANSPORTING
                              col_pos
                              seltext_s
                              seltext_m
                              seltext_l
                              reptext_ddic
                          WHERE fieldname = 'ID'.

*****************************************
  IF upldtabs EQ 'X'.
    CHECK sy-subrc = 0.
    wa_fieldcat_alv-col_pos = '4'.
    wa_fieldcat_alv-seltext_s = text-h03.
    wa_fieldcat_alv-seltext_m = text-h03.
    wa_fieldcat_alv-seltext_l = text-h03.
    wa_fieldcat_alv-reptext_ddic = text-h03.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                            TRANSPORTING
                                col_pos
                                seltext_s
                                seltext_m
                                seltext_l
                                reptext_ddic
                            WHERE fieldname = 'ERR_FLD'.
  ELSE.
    CLEAR wa_fieldcat_alv.
    wa_fieldcat_alv-no_out = 'X'.
    wa_fieldcat_alv-tech = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                            TRANSPORTING
                                no_out
                                tech
                            WHERE fieldname = 'ERR_FLD'.
  ENDIF.
*****************************************
  IF upldtabs EQ 'X'.

    CHECK sy-subrc = 0.
    wa_fieldcat_alv-col_pos = '5'.
    wa_fieldcat_alv-seltext_s = text-h04.
    wa_fieldcat_alv-seltext_m = text-h04.
    wa_fieldcat_alv-seltext_l = text-h04.
    wa_fieldcat_alv-reptext_ddic = text-h04.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                            TRANSPORTING
                                col_pos
                                seltext_s
                                seltext_m
                                seltext_l
                                reptext_ddic
                            WHERE fieldname = 'ERR_VAL'.

  ELSE.
    CLEAR wa_fieldcat_alv.
    wa_fieldcat_alv-no_out = 'X'.
    wa_fieldcat_alv-tech = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                            TRANSPORTING
                                no_out
                                tech
                            WHERE fieldname = 'ERR_VAL'.
  ENDIF.
*****************************************
  CHECK sy-subrc = 0.
  wa_fieldcat_alv-col_pos = '6'.
  wa_fieldcat_alv-seltext_s = text-h05.
  wa_fieldcat_alv-seltext_m = text-h05.
  wa_fieldcat_alv-seltext_l = text-h05.
  wa_fieldcat_alv-reptext_ddic = text-h05.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                          TRANSPORTING
                              col_pos
                              seltext_s
                              seltext_m
                              seltext_l
                              reptext_ddic
                          WHERE fieldname = 'ERR_MSG'.

*****************************************
*****************************************
  CHECK sy-subrc = 0.
  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-no_out = 'X'.
  wa_fieldcat_alv-tech = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                          TRANSPORTING
                              no_out
                              tech
                          WHERE fieldname = 'SORT_FILE'.

*****************************************

ENDFORM.                    " column_titles
*&---------------------------------------------------------------------*
*&      Form  sort_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM sort_table.
  DATA : l_sort TYPE slis_sortinfo_alv.

  l_sort-spos = '1'.
  l_sort-fieldname = 'FL_NAME'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_sort.

ENDFORM.                    " sort_table

*&---------------------------------------------------------------------*
*&      Form  validate_mitigation_review_hdr
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM validate_mitigation_review_hdr.
  g_file_name = p_mitrhd.
  LOOP AT gt_mcrvwhdr.
    g_index = gt_mcrvwhdr-l_index.
**Validate Control ID
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-contid.
    IF NOT gt_mcrvwhdr-contid IS INITIAL.
      PERFORM validate_contid_header_2 USING gt_mcrvwhdr-contid
                                             gf_err.
      g_err_value = gt_mcrvwhdr-contid.
      IF gf_err = 'E'.
        g_err_msg = 'Control ID does not exist'(e13).
        g_err_value = gt_mcuser-contid.
        g_field = gc_fields-contid.
        PERFORM append_output USING g_file_name gf_err g_field
                                    g_err_value g_err_msg.
        DELETE gt_mcuser WHERE l_index EQ g_index.
        CONTINUE.
      ENDIF.

    ELSE.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcrvwhdr WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.
**Validate auditor
    CLEAR: g_err_msg,g_err_value,gf_err.
    g_field = gc_fields-auditor.

    IF gt_mcrvwhdr-contid IS INITIAL.
      CONCATENATE g_field ' cannot be initial'(e01) INTO g_err_msg.
      gf_err = 'E'.
      PERFORM append_output USING g_file_name gf_err g_field
                                  g_err_value g_err_msg.
      DELETE gt_mcrvwhdr WHERE l_index EQ g_index.
      CONTINUE.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " validate_mitigation_review_hdr
