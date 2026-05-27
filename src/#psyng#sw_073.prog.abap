*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_073
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
REPORT /psyng/sw_073 .

TABLES: rlgrap, /psyng/swsodorgm.

TYPE-POOLS: slis.                                      "For ALV call
DATA: gs_program         LIKE sy-repid.                   "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
      gs_alv_layout   TYPE slis_layout_alv,            "For ALV call
      g_alv_grid_titl TYPE lvc_title,                  "For ALV call
      wa_fieldcat_alv TYPE slis_fieldcat_alv,
      gs_variant      TYPE disvariant.


DATA: g_answer.
*27-08-2008  insert begin TSEN
DATA: g_file_path LIKE rlgrap-filename.
*27-08-2008 insert end TSEN
DATA: BEGIN OF orgdata OCCURS 0 ,
        mandt        LIKE /psyng/swsodorgm-mandt,
        abb          LIKE /psyng/swsodorgm-abb,
        object       LIKE /psyng/swsodorgm-object,
        varbl        LIKE /psyng/swsodorgm-varbl,
        low          LIKE /psyng/swsodorgm-low,
        high         LIKE /psyng/swsodorgm-high,
        message(220),
      END OF orgdata.

DATA: BEGIN OF orgdata_db OCCURS 0 ,
        mandt        LIKE /psyng/swsodorgm-mandt,
        abb          LIKE /psyng/swsodorgm-abb,
        object       LIKE /psyng/swsodorgm-object,
        varbl        LIKE /psyng/swsodorgm-varbl,
        low          LIKE /psyng/swsodorgm-low,
        high         LIKE /psyng/swsodorgm-high,
        message(220),
      END OF orgdata_db.
DATA:gt_orgdata LIKE TABLE OF orgdata_db WITH HEADER LINE.
SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE text-005.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(21) text-001 FOR FIELD usfilp.
PARAMETER: usfilp  LIKE rlgrap-filename DEFAULT 'c:\temp\org_values.txt'
                     LOWER CASE.  "c:\temp\org_values.txt
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  23(21) button_1 USER-COMMAND valu.
SELECTION-SCREEN: END OF LINE.

PARAMETERS : down  RADIOBUTTON GROUP a USER-COMMAND ud.
PARAMETERS : up  RADIOBUTTON GROUP a.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: ovrwrt AS CHECKBOX.
SELECTION-SCREEN COMMENT 3(60) text-0s9 FOR FIELD ovrwrt.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: testrun  AS CHECKBOX.
SELECTION-SCREEN COMMENT 3(60) text-117 FOR FIELD testrun.
SELECTION-SCREEN: END OF LINE.

*SELECTION-SCREEN BEGIN OF LINE.
*PARAMETER p_noval AS CHECKBOX.
*SELECTION-SCREEN COMMENT 3(60) text-0s1 FOR FIELD p_noval.
*SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK b1.



INITIALIZATION.
  PERFORM init.

AT SELECTION-SCREEN.
  PERFORM sel_screen_actions.
*27-08-2008 tsen delete begin
*AT SELECTION-SCREEN ON VALUE-REQUEST FOR usfilp.
*  PERFORM locate_org_file.
*27-08-2008 tsen delete end.

*27-08-2008 tsen insert begin.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usfilp.
  MOVE 'c:\temp\org_values.txt' TO g_file_path.
  PERFORM file_select CHANGING usfilp g_file_path.
*27-08-2008 tsen insert end.

*--C0522 start
AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN .
    CASE screen-name.
      WHEN 'OVRWRT' OR 'TESTRUN' OR 'P_NOVAL' .
        IF up = 'X'.
          screen-input = 1 .
        ELSE.
          screen-input = 0 .
          CLEAR : ovrwrt,testrun.
        ENDIF.
        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.
*  *-- end

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
  IF up = 'X'.
*Authorization check for Display table /psyng/swsodorgm
*SF 1665
    AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
               ID 'ACTVT' FIELD '02'
               ID 'DICBERCLS' FIELD 'Y&S5'.
    IF sy-subrc NE 0.
      MESSAGE e113(/psyng/sw) WITH text-e02 '/psyng/swsodorgm'.
      STOP.
    ENDIF.

message i113(/psyng/sw) with
'Leading spaces will be removed from Low and High fields.'(e10).
    gs_program = sy-repid.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = text-016
        text_question         = text-017
        text_button_1         = text-018  "Yes
        text_button_2         = text-019  "No
        default_button        = '2'
        display_cancel_button = ' '
      IMPORTING
        answer                = g_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND = 1
             OTHERS         = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
    PERFORM upload_org_file.

    IF NOT testrun = 'X'.
      PERFORM local_insert.
    ENDIF.

    PERFORM output_uploaddata_via_alv USING text-004.
  ELSEIF down = 'X'.
*Authorization check for Display table /psyng/swsodorgm
*SF 1665
    AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
               ID 'ACTVT' FIELD '03'
               ID 'DICBERCLS' FIELD 'Y&S5'.
    IF sy-subrc NE 0.
      MESSAGE e113(/psyng/sw) WITH text-e01 '/psyng/swsodorgm'.
      STOP.
    ENDIF.
    PERFORM download_org_file.
  ENDIF.


*---------------------------------------------------------------------*
*       FORM init                                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM init.
  MOVE text-010 TO button_1.
ENDFORM.                    " init

*---------------------------------------------------------------------*
*       FORM sel_screen_actions                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM sel_screen_actions.

  CASE sy-ucomm.
    WHEN 'VALU'.
      PERFORM upload_org_file.
      PERFORM output_uploaddata_via_alv USING text-014.
    WHEN OTHERS.
  ENDCASE.

ENDFORM.                    " sel_screen_actions

*27-08-2008 tsen insert begin --------------*
*       FORM locate_org_file                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*FORM locate_org_file.
*
*  CALL FUNCTION 'WS_FILENAME_GET'
*   EXPORTING
**   DEF_FILENAME           = ' '
**   DEF_PATH               = ' '
*     mask                   = ',*.*,*.*.'
*     mode                   = 'O'
*     title                  = text-013
*   IMPORTING
*     filename               = usfilp
**   RC                     =
*   EXCEPTIONS
*     inv_winsys             = 1
*     no_batch               = 2
*     selection_cancel       = 3
*     selection_error        = 4
*     OTHERS                 = 5.
*
*  IF sy-subrc <> 0 AND ( NOT sy-msgty IS INITIAL ) .
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*  ENDIF.
*
*ENDFORM.                    " locate_user_file
**27-08-2008 tsen insert end--------------*

*---------------------------------------------------------------------*
*       FORM upload_org_file                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM upload_org_file.

* upload org file
  DATA: l_filename TYPE string.
  REFRESH: orgdata.
  CLEAR: orgdata.
  MESSAGE i208(00) WITH text-008.  "Attempting to upload user file

  l_filename = usfilp.
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
      data_tab                = orgdata
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
    PERFORM handle_upload_error USING sy-subrc l_filename text-020.
    STOP.
  ENDIF.
  ENDIF.
*EOC:HBHALLA (097)
  SORT orgdata.
  DELETE ADJACENT DUPLICATES FROM orgdata.
  LOOP AT orgdata.
    TRANSLATE orgdata-abb TO UPPER CASE.
    TRANSLATE orgdata-object TO UPPER CASE.
    TRANSLATE orgdata-varbl TO UPPER CASE.
    TRANSLATE orgdata-low TO UPPER CASE.
    CONDENSE orgdata-low.
    TRANSLATE orgdata-high TO UPPER CASE.
    CONDENSE orgdata-high.
    MODIFY orgdata.

    orgdata_db-mandt = sy-mandt.
    MOVE-CORRESPONDING orgdata TO orgdata_db.
    APPEND orgdata_db.

  ENDLOOP.

  LOOP AT orgdata_db.
    IF orgdata_db-abb IS INITIAL.
      orgdata_db-message = text-021 .
      MODIFY orgdata_db TRANSPORTING message.
    ELSEIF orgdata_db-object IS INITIAL.
      orgdata_db-message = text-022 .
      MODIFY orgdata_db TRANSPORTING message.
    ELSEIF orgdata_db-varbl IS INITIAL.
      orgdata_db-message = text-023 .
      MODIFY orgdata_db TRANSPORTING message.
    ELSEIF orgdata_db-low IS INITIAL.
      orgdata_db-message = text-024 .
      MODIFY orgdata_db TRANSPORTING message.
    ELSE.
      APPEND orgdata_db TO gt_orgdata.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " upload_org_file

*---------------------------------------------------------------------*
*       FORM output_uploaddata_via_alv                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  OUTPUTTITLE                                                   *
*---------------------------------------------------------------------*
FORM output_uploaddata_via_alv USING outputtitle.

  CLEAR: i_fieldcat_alv, wa_fieldcat_alv.
  gs_program = sy-repid.
  gs_alv_layout-zebra = 'X'.
  gs_alv_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name     = gs_program
      i_internal_tabname = 'ORGDATA_DB'
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

  CHECK sy-subrc = 0.

*  wa_fieldcat_alv-seltext_m = text-020.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      seltext_l
*                      seltext_m
*                      seltext_s
*                      reptext_ddic
*                   WHERE
*                      fieldname = 'UMESSAGE'.
*
*  wa_fieldcat_alv-seltext_m = text-021.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      seltext_l
*                      seltext_m
*                      seltext_s
*                      reptext_ddic
*                   WHERE
*                      fieldname = 'RMESSAGE'.
*
*  wa_fieldcat_alv-seltext_m = text-022.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      seltext_l
*                      seltext_m
*                      seltext_s
*                      reptext_ddic
*                   WHERE
*                      fieldname = 'PASSWORD'.


  MOVE outputtitle TO g_alv_grid_titl.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_grid_title            = g_alv_grid_titl
      i_callback_program      = gs_program
      i_callback_user_command = 'USER_DOUBLE_CLICK'
      is_layout               = gs_alv_layout
      i_save                  = 'A'
      is_variant              = gs_variant
      it_fieldcat             = i_fieldcat_alv
    TABLES
      t_outtab                = orgdata_db
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " output_via_alv
*&---------------------------------------------------------------------*
*&      Form  local_insert
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM local_insert.

*  MESSAGE i208(00) WITH 'Insert goes here'.

*---c0522
  IF ovrwrt = 'X'.
    DELETE FROM /psyng/swsodorgm
  WHERE abb > space.
  ENDIF.
*---end

  SORT gt_orgdata.
  DELETE ADJACENT DUPLICATES FROM gt_orgdata.
*  LOOP AT orgdata_db.
*    SELECT SINGLE * FROM /psyng/swsodorgm WHERE
*           abb = orgdata_db-abb AND
*           object = orgdata_db-object AND
*           varbl = orgdata_db-varbl AND
*           low = orgdata_db-low.
*
*    CHECK sy-subrc = 0.
*    DELETE orgdata_db.
*
*  ENDLOOP.

*  INSERT /psyng/swsodorgm FROM TABLE orgdata_db.
  MODIFY /psyng/swsodorgm FROM TABLE gt_orgdata.
  COMMIT WORK.

  IF sy-subrc NE 0.
    MESSAGE i208(00) WITH text-009.
  ELSE.
    MESSAGE i208(00) WITH text-011.
  ENDIF.
ENDFORM.                    " local_insert

*27-08-2008 INSERT BEGIN TSEN
*&---------------------------------------------------------------------*
*&      Form  file_select
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_USFILP  text
*      <--P_FILE_PATH  text
*----------------------------------------------------------------------*
FORM file_select CHANGING i_g_filename TYPE rlgrap-filename
                          i_file_path TYPE rlgrap-filename.

  DATA : l_uaction   TYPE i,
         l_title     TYPE string,
         l_filetable TYPE  filetable,
         l_def_fname TYPE string,
         l_init_dir  TYPE string.

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
  l_title = text-013.

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
    READ TABLE l_filetable INDEX 1 INTO i_g_filename.

  ENDIF.
ENDFORM.                    " file_select
*27-08-2008 INSERT END TSEN

*&---------------------------------------------------------------------*
*&      Form  handle_upload_error
*&---------------------------------------------------------------------*
*       Defined error messages for exceptions
*----------------------------------------------------------------------*

FORM handle_upload_error USING    p_sy_subrc
                                  p_filename
                                  p_msg.
  CASE p_sy_subrc.
    WHEN 1.
      MESSAGE i021(/psyng/basis) WITH p_filename p_msg.
    WHEN 2.
      MESSAGE i022(/psyng/basis) WITH p_filename p_msg.
    WHEN 3.
      MESSAGE i023(/psyng/basis) WITH p_filename p_msg.
    WHEN 4.
      MESSAGE i024(/psyng/basis) WITH p_filename p_msg.
    WHEN 5.
      MESSAGE i025(/psyng/basis) WITH p_filename p_msg.
    WHEN 6.
      MESSAGE i026(/psyng/basis) WITH p_filename p_msg.
    WHEN 7 OR 17.
      MESSAGE i027(/psyng/basis) WITH p_filename p_msg.
    WHEN 8.
      MESSAGE i028(/psyng/basis) WITH p_filename p_msg.
    WHEN 9.
      MESSAGE i029(/psyng/basis) WITH p_filename p_msg.
    WHEN 10.
      MESSAGE i030(/psyng/basis) WITH p_filename p_msg.
    WHEN 11.
      MESSAGE i031(/psyng/basis) WITH p_filename p_msg.
    WHEN 12.
      MESSAGE i032(/psyng/basis) WITH p_filename p_msg.
    WHEN 13.
      MESSAGE i033(/psyng/basis) WITH p_filename p_msg.
    WHEN 14.
      MESSAGE i034(/psyng/basis) WITH p_filename p_msg.
    WHEN 15.
      MESSAGE i035(/psyng/basis) WITH p_filename p_msg.
    WHEN 16.
      MESSAGE i036(/psyng/basis) WITH p_filename p_msg.
  ENDCASE.

ENDFORM.                    " handle_error

*&---------------------------------------------------------------------
*
*&      Form  download
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
*      -->P_GT_POSITIONHDR  text
*      -->P_L_FILENAME  text
*----------------------------------------------------------------------
*
FORM download TABLES it_data
              USING  p_filename.

  DATA :l_file_name TYPE string,
        l_msgv      TYPE bapiret2-message_v1.

  l_file_name = p_filename.

*BOC:HBHALLA (096)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '61'.
  IF sy-subrc = 0.
  CALL FUNCTION 'GUI_DOWNLOAD' "#EC SAST_CI_GEN_CHECK
    EXPORTING
      filename                = l_file_name
      filetype                = 'ASC'
      write_field_separator   = 'X'
      dat_mode                = ' '
    TABLES
      data_tab                = it_data
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
    l_msgv = p_filename.
    CALL FUNCTION '/PSYNG/BC_003'
      EXPORTING
        i_subrc = sy-subrc
        i_msgty = 'I'
        i_msgv1 = l_msgv.
  ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
ENDFORM.                    " download
*&---------------------------------------------------------------------*
*&      Form  download_org_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM download_org_file.
  DATA : lt_org TYPE TABLE OF /psyng/swsodorgm.
  SELECT  * FROM /psyng/swsodorgm INTO TABLE lt_org .
  PERFORM download TABLES lt_org USING usfilp.
  MESSAGE s137(/psyng/sw) WITH 'Data successfully downloaded.'(006).
*   & & &

ENDFORM.                    " download_org_file
