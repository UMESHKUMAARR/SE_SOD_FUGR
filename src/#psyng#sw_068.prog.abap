*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_068
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
REPORT /psyng/sw_068 MESSAGE-ID /psyng/sw.

TABLES : /psyng/position, /psyng/posndet.

DATA : BEGIN OF output OCCURS 0,
        positionid LIKE /psyng/position-positionid,
        description LIKE /psyng/position-description,
        saptechname LIKE /psyng/position-saptechname,
        create_usr LIKE /psyng/position-create_usr,
        create_dat LIKE /psyng/position-create_dat,
        create_tim LIKE /psyng/position-create_tim,
        roleid LIKE /psyng/posndet-roleid,
       END OF output.
DATA: g_file_path LIKE rlgrap-filename,
      g_flag_upld_r_dwld.

DATA:gf_missing_auth TYPE flag.
SELECTION-SCREEN : BEGIN OF BLOCK blk1 WITH FRAME TITLE text-000.
SELECTION-SCREEN : BEGIN OF LINE.
PARAMETERS : dnldtab RADIOBUTTON GROUP a.
SELECTION-SCREEN : COMMENT 3(75) text-001.
SELECTION-SCREEN : END OF LINE.

PARAMETER: p_dposfl  LIKE rlgrap-filename DEFAULT
                     'c:\temp\downloadposition.txt' LOWER CASE.
SELECTION-SCREEN : SKIP 1.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: upldtabs RADIOBUTTON GROUP a.
SELECTION-SCREEN: COMMENT 3(75) text-006.
SELECTION-SCREEN: END OF LINE.

PARAMETER: p_uposfl  LIKE rlgrap-filename DEFAULT
                    'c:\temp\uploadposition.txt' LOWER CASE.
SELECTION-SCREEN : SKIP 1.

PARAMETERS: p_ovrwrt AS CHECKBOX DEFAULT space,
            emtytabs AS CHECKBOX DEFAULT space.

SELECTION-SCREEN : END OF BLOCK blk1.


*21-08-2008 TSEN INSERT BEGIN.
************************** Value request*****************
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_uposfl.
  MOVE 'c:\temp\uploadposition.txt' TO g_file_path.
  g_flag_upld_r_dwld = 'X'.
  PERFORM file_select CHANGING p_uposfl g_file_path g_flag_upld_r_dwld.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_dposfl.
  MOVE 'c:\temp\downloadposition.txt' TO g_file_path.
  CLEAR g_flag_upld_r_dwld.
  PERFORM file_select CHANGING p_dposfl g_file_path g_flag_upld_r_dwld.


*********************************************************
***Changes for f1 help

***AT SELECTION-SCREEN
**F1 help for downloading position ids radio button
AT SELECTION-SCREEN ON HELP-REQUEST FOR  dnldtab.

  PERFORM show_help USING '/PSYNG/SW_068_DPOSFLE'.


**F1 help for uploading position ids radio button
AT SELECTION-SCREEN ON HELP-REQUEST FOR upldtabs.

  PERFORM show_help USING '/PSYNG/SW_068_UPOSFLE'.

*****************************************************
***AT SELECTION-SCREEN
**F1 help for Overwrite Existing Position(s) check box
AT SELECTION-SCREEN ON HELP-REQUEST FOR  p_ovrwrt.

  PERFORM show_help USING '/PSYNG/SW_068_P_OVRWRT'.

**F1 help for Delete all Position ID(s) first check box

AT SELECTION-SCREEN ON HELP-REQUEST FOR emtytabs.

  PERFORM show_help USING '/PSYNG/SW_068_EMTYTABS'.


*****************************************************

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
Clear:gf_missing_auth.
  IF dnldtab = 'X'.
    PERFORM download_to_files.
  ELSEIF upldtabs = 'X'.
    PERFORM upload_to_tables.
  ENDIF.
*************************************
  IF gf_missing_auth = 'X'.
*  **SF 1665
  MESSAGE s398(00) WITH
*      'Analysis Complete.'(083)
      'Missing some user authorizations'(084).
 ENDIF.
*************************************
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
*&      Form  download_to_files
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM download_to_files.
  DATA : BEGIN OF position OCCURS 0.
          INCLUDE STRUCTURE /psyng/position.
  DATA : END OF position.

  DATA : BEGIN OF posndet1 OCCURS 0.
          INCLUDE STRUCTURE /psyng/posndet.
  DATA : END OF posndet1.

  DATA : l_filename TYPE string,
         l_msgv     TYPE bapiret2-message_v1.


  SELECT * FROM /psyng/position INTO TABLE position.
  IF sy-subrc = 0.
    SORT: position.
    LOOP AT position.
      SELECT * FROM /psyng/posndet     "#EC CI_SEL_NESTED
                   WHERE positionid = position-positionid.
        posndet1-positionid = /psyng/posndet-positionid.
        posndet1-roleid = /psyng/posndet-roleid.
        APPEND posndet1.
      ENDSELECT.
    ENDLOOP.
  ENDIF.

  SORT: position, posndet1.
  LOOP AT position .
    LOOP AT posndet1 WHERE positionid = position-positionid.
      MOVE-CORRESPONDING position TO output.
      MOVE-CORRESPONDING posndet1 TO output.
      APPEND output.
    ENDLOOP.


  ENDLOOP.


  REFRESH : position, posndet1.
  CLEAR : position, posndet1.


  l_filename = p_dposfl.
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
            data_tab                = output
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
    l_msgv = l_filename.
    CALL FUNCTION '/PSYNG/BC_003'
         EXPORTING
              i_subrc = sy-subrc
              i_msgty = 'I'
              i_msgv1 = l_msgv.
  ENDIF.
  ENDIF.
*EOC:HBHALLA (096)

ENDFORM.                    " download_to_files
*&---------------------------------------------------------------------*
*&      Form  upload_to_tables
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM upload_to_tables.
  DATA : BEGIN OF position1 OCCURS 0.
          INCLUDE STRUCTURE /psyng/position.
  DATA : END OF position1.

  DATA : BEGIN OF posndet OCCURS 0.
          INCLUDE STRUCTURE /psyng/posndet.
  DATA : END OF posndet.

  DATA : uploadfailed(3).

  DATA : l_filename TYPE string,
         l_msgv     TYPE bapiret2-message_v1,
         l_current_user TYPE sy-uname. "C0700

* BOC by RGUPTA on 04.04.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 04.04.22 for C0700
  l_filename = p_uposfl.

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
            data_tab                = output
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
    l_msgv = l_filename.
    CALL FUNCTION '/PSYNG/BC_004'
         EXPORTING
              i_subrc = sy-subrc
              i_msgty = 'I'
              i_msgv1 = l_msgv.
  ENDIF.
  ENDIF.
*EOC:HBHALLA (097)

  SORT output.
  DELETE ADJACENT DUPLICATES FROM output COMPARING ALL FIELDS.

  IF emtytabs = 'X'.

    IF NOT output[] IS INITIAL.
      SELECT * FROM /psyng/position INTO TABLE position1.

      LOOP AT position1.
        TRANSLATE position1-positionid TO UPPER CASE.
***********************
**Authorization check for Create/Change SW Positions
**SF 1665
  AUTHORITY-CHECK OBJECT 'Y&SW_POSH'
             ID 'ACTVT' FIELD '02'
             ID 'Y&SW_POSID' field position1-positionid.
 IF sy-subrc EQ 0.
**SF 1665
* ***********************

        SELECT * FROM /psyng/posndet    "#EC CI_SEL_NESTED
             WHERE positionid = position1-positionid.
          posndet-positionid = /psyng/posndet-positionid.
          posndet-roleid = /psyng/posndet-roleid.
          APPEND posndet.
        ENDSELECT.
***************************
***SF 1665
 ELSE.
  gf_missing_auth = 'X'.
 ENDIF.
**SF 1665
* ***********************
      ENDLOOP.
      DELETE /psyng/position FROM TABLE position1.
      DELETE /psyng/posndet FROM TABLE posndet.
      COMMIT WORK.
    ENDIF.
  ENDIF.

  SORT output BY positionid.
  IF NOT output[] IS INITIAL.
    LOOP AT output.
***********************
**Authorization check for Create/Change SW Positions
**SF 1665
  AUTHORITY-CHECK OBJECT 'Y&SW_POSH'
             ID 'ACTVT' FIELD '02'
             ID 'Y&SW_POSID' field output-positionid.
  IF sy-subrc EQ 0.
**SF 1665
************************
      AT NEW positionid.

        IF p_ovrwrt = 'X'.
        DELETE FROM /psyng/posndet        "#EC CI_IMUD_NESTED
          WHERE positionid = output-positionid.
        ENDIF.
      ENDAT.
************************
**SF 1665
 ELSE.
  gf_missing_auth = 'X'.
 ENDIF.
**SF 1665
************************
**Authorization check for Create/Change SW Positions
**SF 1665
  AUTHORITY-CHECK OBJECT 'Y&SW_POSH'
             ID 'ACTVT' FIELD '01'
             ID 'Y&SW_POSID' field output-positionid.
  IF sy-subrc EQ 0.
**SF 1665
************************

      /psyng/position-positionid = output-positionid.
      TRANSLATE /psyng/position-positionid TO UPPER CASE.
      /psyng/position-description = output-description.
      /psyng/position-saptechname = output-saptechname.
      /psyng/position-create_usr = output-create_usr.
      /psyng/position-create_dat = output-create_dat.
      /psyng/position-create_tim = output-create_tim.
      /psyng/position-change_usr = l_current_user."sy-uname. C0700
      /psyng/position-change_dat = sy-datum.
      /psyng/position-change_tim = sy-uzeit.
***********************************
**SF 1665
 ELSE.
  gf_missing_auth = 'X'.
 ENDIF.
**SF 1665
************************
      IF p_ovrwrt IS INITIAL.
        INSERT /psyng/position.
      ELSE.
        MODIFY /psyng/position.
      ENDIF.

*  Validate role exists
      SELECT SINGLE mandt INTO sy-mandt    "#EC CI_SEL_NESTED
             FROM /psyng/rolehdr
                    WHERE roleid = output-roleid.
      IF sy-subrc = 0.
        TRANSLATE /psyng/posndet-positionid TO UPPER CASE.
        /psyng/posndet-positionid = output-positionid.
        /psyng/posndet-roleid     = output-roleid.
        INSERT /psyng/posndet.
      ELSE.
        MESSAGE i135 WITH text-019 output-roleid text-020.
      ENDIF.
    ENDLOOP.

    IF sy-subrc = 0.
      COMMIT WORK.
      IF sy-subrc = 0.
        MESSAGE i138 WITH text-015.
      ELSE.
        uploadfailed = 'YES'.
        MESSAGE i135 WITH text-009.
      ENDIF.
    ELSE.
      uploadfailed = 'YES'.
      MESSAGE i136 WITH text-009.
    ENDIF.
  ELSE.
    MESSAGE i137 WITH text-011.
  ENDIF.

  REFRESH : output, posndet, position1.
  CLEAR : output, posndet, position1.

ENDFORM.                    " upload_to_tables
*&---------------------------------------------------------------------*
*&      Form  FILE_SELECT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_DPOSFLE  text
*      <--P_FILE_PATH  text
*      <--P_FLAG_UPLD_R_DWLD  text
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

    l_title = text-018.
  ELSE.
    l_title = text-017.
  ENDIF.

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
   OTHERS                  = 4
       .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    READ TABLE l_filetable INDEX 1 INTO i_g_filename.

  ENDIF.
ENDFORM.                    " FILE_SELECT
