
*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_127
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

REPORT /psyng/sw_127 .
INCLUDE :
  /psyng/basis_exelog,
  /psyng/sw_config.

TYPE-POOLS:slis.

DATA : BEGIN OF gt_log OCCURS 0,
        filename  LIKE rlgrap-filename,
        type      LIKE icon-id,
        object    LIKE dd03d-fieldname,
        object_id LIKE t100-text,
        message   LIKE t100-text,
      END OF gt_log.


DATA : gt_varel TYPE TABLE OF /psyng/sw_varel WITH HEADER LINE,
       gt_varvr TYPE TABLE OF /psyng/sw_varvr WITH HEADER LINE,
       gf_dflt_varel_skipval TYPE flag,
       gf_dflt_varel_test    TYPE flag.

*-- Selection Screens

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

*--Folder for version header
*SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS :  p_path1(500) TYPE c VISIBLE LENGTH 144 " rlgrap-filename
LOWER CASE DEFAULT 'c:\temp\variable_elements_Rule_Version.txt'
OBLIGATORY.
*SELECTION-SCREEN: END OF LINE.

*--Folder
PARAMETERS :  p_path(500) TYPE c VISIBLE LENGTH 144 " rlgrap-filename
LOWER CASE DEFAULT 'c:\temp\variable_elements.txt' OBLIGATORY.
PARAMETERS : vvrsio TYPE /psyng/ve_vrsio OBLIGATORY.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: ovrwrt AS CHECKBOX.
SELECTION-SCREEN COMMENT 3(60) text-009 FOR FIELD ovrwrt.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: testrun  AS CHECKBOX.
SELECTION-SCREEN COMMENT 3(60) text-117 FOR FIELD testrun.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETER p_noval AS CHECKBOX DEFAULT gf_dflt_varel_skipval.
SELECTION-SCREEN COMMENT 3(60) text-001 FOR FIELD p_noval.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN: END OF BLOCK opt.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_path.
  PERFORM dir_select CHANGING p_path .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_path1.
  PERFORM dir_select CHANGING p_path1 .

AT SELECTION-SCREEN.

*--26.12.2019 skip for upload a version that doesnt exist yet
  IF dnldtabs = 'X'.
    SELECT SINGLE mandt INTO sy-mandt FROM /psyng/sw_varvr
                     WHERE varel_vrsio = vvrsio.
    IF sy-subrc <> 0.
      MESSAGE e351(/psyng/sw) WITH vvrsio.
    ENDIF.
  ENDIF.

INITIALIZATION.

  exelog sy-repid ''.
  se_config_param 'DFLT_VAREL_SKIPVAL' gf_dflt_varel_skipval.
  IF gf_dflt_varel_skipval = 'Y' OR gf_dflt_varel_skipval = 'X'.
    gf_dflt_varel_skipval = 'X'.
  ENDIF.
  se_config_param 'DFLT_VAREL_TEST' gf_dflt_varel_test.
  IF gf_dflt_varel_test = 'Y' OR gf_dflt_varel_test = 'X'.
    gf_dflt_varel_test = 'X'.
  ENDIF.





AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN .
    CASE screen-name.
      WHEN 'OVRWRT' OR 'TESTRUN' OR 'P_NOVAL' OR
           'P_CRTVER' OR 'P_TEXT'.
        IF upldtabs = 'X'.
          screen-input = 1 .
          p_noval = gf_dflt_varel_skipval.
          testrun = gf_dflt_varel_test.
        ELSE.
          screen-input = 0 .
          CLEAR : ovrwrt,p_noval.
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
  IF dnldtabs = 'X'.
    PERFORM download_data USING vvrsio.
  ELSEIF upldtabs = 'X'.
    PERFORM upload_data USING vvrsio.
  ENDIF.
  PERFORM output_log.




*&---------------------------------------------------------------------*
*&      Form  dir_select
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_P_PATH  text
*----------------------------------------------------------------------*
FORM dir_select CHANGING e_path.
  DATA : l_file_path TYPE rlgrap-filename.
  DATA :   l_uaction TYPE i,
           l_title TYPE string,
           l_filetable TYPE  filetable,
           l_def_fname TYPE string,
           l_init_dir TYPE string.

  FIELD-SYMBOLS : <wa> TYPE file_table.

  l_title = 'Open'(043).
  CALL METHOD cl_gui_frontend_services=>file_open_dialog
"#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
        window_title = l_title
        default_extension = '*.XLS'
        multiselection = ' '
    CHANGING
        file_table = l_filetable
        rc         = l_uaction
    EXCEPTIONS
        cntl_error      = 1
        error_no_gui    = 2
        OTHERS          = 3
            .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.


  LOOP AT l_filetable ASSIGNING <wa>.
    CHECK sy-tabix = 1.
    e_path  = <wa>-filename.
  ENDLOOP.
  .

ENDFORM.                    " dir_select
*&---------------------------------------------------------------------*
*&      Form  download_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM download_data
  USING i_varel_vrsio TYPE /psyng/ve_vrsio.

  DATA :l_file_name TYPE string,
        l_msgv     TYPE bapiret2-message_v1,
        l_count TYPE i,
        l_msg TYPE bapiret2-message.

*-- Authority Check to download
  AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
             ID 'ACTVT' FIELD '03'
             ID 'DICBERCLS' FIELD 'Y&S5'.
  IF sy-subrc NE 0.
    MESSAGE e113(/psyng/sw) WITH text-e01 '/psyng/sw_varel'.
    STOP.
  ENDIF.


*-- Get data from data base
  SELECT  * FROM /psyng/sw_varvr
    INTO TABLE gt_varvr
    WHERE varel_vrsio = vvrsio.
*-- Rule version
  l_file_name = p_path1.
*-- Download data from internal table to local file
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
            data_tab                = gt_varvr
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
    l_msgv = l_file_name.
    CALL FUNCTION '/PSYNG/BC_003'
         EXPORTING
              i_subrc     = sy-subrc
              i_msgty     = 'I'
              i_msgv1     = l_msgv
              if_no_popup = 'X'
         IMPORTING
              e_message   = l_msg.
    PERFORM log USING p_path 'E'
                             ''
                             ''
                             ''
                             ''
                             l_msg.

  ELSE.
    PERFORM log USING p_path1 'S'
                             ''
                             ''
                             ''
                             ''
                             'File Downloaded Successfully.'(008).


    MESSAGE s137(/psyng/sw) WITH 'Data successfully downloaded.'(006).

  ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
*-- variable element rule
  SELECT  * FROM /psyng/sw_varel
  INTO TABLE gt_varel
  WHERE varel_vrsio = i_varel_vrsio."#EC SAST_CI_GEN_CHECK

  l_file_name = p_path.

*-- Download data from internal table to local file
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
            data_tab                = gt_varel
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
    l_msgv = l_file_name.
    CALL FUNCTION '/PSYNG/BC_003'
         EXPORTING
              i_subrc     = sy-subrc
              i_msgty     = 'I'
              i_msgv1     = l_msgv
              if_no_popup = 'X'
         IMPORTING
              e_message   = l_msg.
    PERFORM log USING p_path 'E'
                             ''
                             ''
                             ''
                             ''
                             l_msg.

  ELSE.
    PERFORM log USING p_path 'S'
                             ''
                             ''
                             ''
                             ''
                             'File Downloaded Successfully.'(008).


    MESSAGE s137(/psyng/sw) WITH 'Data successfully downloaded.'(006).

  ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
ENDFORM.                    " download_data
*&---------------------------------------------------------------------*
*&      Form  upload_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM upload_data
USING i_varel_vrsio TYPE /psyng/ve_vrsio.
  DATA: l_filename TYPE string.
  FIELD-SYMBOLS : <rec> TYPE /psyng/sw_varel.
  AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
             ID 'ACTVT' FIELD '02'
             ID 'DICBERCLS' FIELD 'Y&S5'.
  IF sy-subrc NE 0.
    MESSAGE e113(/psyng/sw) WITH text-e02 '/psyng/sw_varel'.
    STOP.
  ENDIF.

  REFRESH: gt_varel, gt_varvr.
  CLEAR: gt_varel, gt_varvr.



*--rule version
  l_filename = p_path1.
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
            data_tab                = gt_varvr
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
  ELSE.

    DELETE gt_varvr WHERE varel_vrsio EQ space
                      AND description EQ space.
    SORT gt_varvr.
    DELETE ADJACENT DUPLICATES FROM gt_varvr COMPARING ALL FIELDS.

    IF p_noval IS INITIAL.
      IF gt_varvr[] IS INITIAL.
        PERFORM log USING p_path1 'E' '' '' '' '' 'Empty File'(204).
      ENDIF.
    ENDIF.

    IF NOT testrun = 'X'.
      PERFORM db_changes USING i_varel_vrsio.
    ENDIF.
  ENDIF.
  ENDIF.
*EOC:HBHALLA (097)
*--Variable element rule
  l_filename = p_path.
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
            data_tab                = gt_varel
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
  ELSE.

    SORT gt_varel.
    DELETE ADJACENT DUPLICATES FROM gt_varel COMPARING ALL FIELDS.
*--Assign the requested version to each record
    LOOP AT gt_varel ASSIGNING <rec>.
      <rec>-varel_vrsio = i_varel_vrsio.
    ENDLOOP.
    PERFORM data_validations.
    IF NOT testrun = 'X'.
      PERFORM db_changes USING i_varel_vrsio.
    ENDIF.

    IF NOT gt_varel[] IS INITIAL.

      IF NOT gt_varvr[] IS INITIAL. " Header logs only if rules upload
        PERFORM log USING p_path1 'S'
                               ''
                               ''
                               ''
                               ''
                               'File Uploaded Successfully.'(010).
      ENDIF.

      PERFORM log USING p_path 'S'
                             ''
                             ''
                             ''
                             ''
                             'File Uploaded Successfully.'(010).
    MESSAGE s137(/psyng/sw) WITH 'Data successfully uploaded.'(007).

    ENDIF.


  ENDIF.
  ENDIF.
*EOC:HBHALLA (097)
ENDFORM.                    " upload_data
*&---------------------------------------------------------------------*
*&      Form  handle_upload_error
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SY_SUBRC  text
*      -->P_L_FILENAME  text
*      -->P_TEXT_020  text
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

ENDFORM.                    " handle_upload_error
*&---------------------------------------------------------------------*
*&      Form  data_validations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM data_validations.
  DATA : ls_stable TYPE  lvc_s_stbl,
  ls_authx TYPE authx,
  ls_dd01v TYPE  dd01v,
  l_objname TYPE ddobjname,
  l_msgtype TYPE c VALUE 'E'.
  DATA : lt_dd04t TYPE TABLE OF dd04t WITH HEADER LINE,
         lt_dd03t TYPE TABLE OF dd03t WITH HEADER LINE,
         lt_authx TYPE TABLE OF authx WITH HEADER LINE.

  IF p_noval = 'X'.
    l_msgtype = 'W'.
  ENDIF.

*-- Auth elements
  SELECT * FROM authx INTO TABLE lt_authx.

*-- auth fields


  LOOP AT gt_varel.
    IF gt_varel-var_element IS INITIAL.
      PERFORM log USING p_path l_msgtype
                               'SE - Variable Element Name'(l05)
                               ''
                               ''
                               ''
                               'Empty'(l01).
      IF p_noval <> 'X'. "IS INITIAL.
        DELETE gt_varel.
      ENDIF.
      CONTINUE.
    ENDIF.

    IF gt_varel-element IS INITIAL.
      PERFORM log USING p_path l_msgtype
                            gt_varel-field
                           'Auth.Field'(l06)

                           ''
                           ''
                           'Empty'(201).
      IF p_noval <> 'X'. "IS INITIAL.
        DELETE gt_varel.
      ENDIF.
      CONTINUE.
    ELSE.
      READ TABLE lt_authx WITH KEY fieldname = gt_varel-element.
      IF sy-subrc NE 0.
        PERFORM log USING p_path l_msgtype
                          gt_varel-element
                         'Auth.Field'(l06)

                         ''
                         ''
                         'Invalid content for Authorization Field'(202).
        IF p_noval <> 'X' ."IS INITIAL.
          DELETE gt_varel.
        ENDIF.
        CONTINUE.
      ENDIF.
    ENDIF.

    IF gt_varel-field IS INITIAL.
      PERFORM log USING p_path l_msgtype
                        gt_varel-field
                       'Field Name'(l07)

                       ''
                       ''
                       'Empty'(201).
      IF p_noval <> 'X'. "IS INITIAL.
        DELETE gt_varel.
      ENDIF.
      CONTINUE.
    ELSE.
*   Get fields name
      IF NOT gt_varel-element IS INITIAL.
**1.Get the table name
*        SELECT SINGLE * FROM authx INTO ls_authx
*        WHERE fieldname =  gt_varel-element.
*        IF ls_authx-checktable IS INITIAL.
*          l_objname =  gt_varel-element.
*          CALL FUNCTION 'DDIF_DOMA_GET'
*               EXPORTING
*                    name          = l_objname
*               IMPORTING
*                    dd01v_wa      = ls_dd01v
*               EXCEPTIONS
*                    illegal_input = 1
*                    OTHERS        = 2.
*          IF sy-subrc <> 0.
*            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*          ENDIF.
*          ls_authx-checktable = ls_dd01v-entitytab.
*        ENDIF.
*2. Get the fields of that table

        SELECT dd03l~fieldname  dd03t~ddtext FROM dd03l
        LEFT JOIN dd03t ON
                  dd03l~tabname   = dd03t~tabname   AND
                  dd03l~fieldname = dd03t~fieldname AND
                  dd03t~ddlanguage = sy-langu
         INTO CORRESPONDING FIELDS OF TABLE lt_dd03t
         WHERE dd03l~tabname = gt_varel-tabname."#EC SAST_CI_GEN_CHECK


        READ TABLE lt_dd03t WITH KEY fieldname = gt_varel-field.
        IF sy-subrc NE 0.
          PERFORM log USING p_path l_msgtype
                     gt_varel-field
                    'Field Name'(l07)


                  ''
                  ''
                  'Invalid'(203).
          IF p_noval <> 'X'. "IS INITIAL.
            DELETE gt_varel.
          ENDIF.
          CONTINUE.
        ENDIF.
      ENDIF.
    ENDIF.
*--Low value can be empty
*    IF gt_varel-val_from IS INITIAL.
*      PERFORM log USING p_path 'E'
*                        gt_varel-field
*                       'Low Value'(012)
*
*                       ''
*                       ''
*                       'Empty'(201).
*      DELETE gt_varel.
*      CONTINUE.
*    ENDIF.

  ENDLOOP.
  IF sy-subrc NE 0.
    PERFORM log USING p_path 'E' '' '' '' '' 'Empty File'(204).
  ENDIF.

ENDFORM.                    " data_validations
*&---------------------------------------------------------------------*
*&      Form  db_changes
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM db_changes USING i_varel_vrsio TYPE /psyng/ve_vrsio.
  IF ovrwrt = 'X'.

    DELETE FROM /psyng/sw_varvr
    WHERE varel_vrsio = vvrsio.

    DELETE  FROM /psyng/sw_varel
    WHERE varel_vrsio = vvrsio.
    COMMIT WORK.
  ENDIF.

  SORT gt_varvr.
  DELETE ADJACENT DUPLICATES FROM gt_varvr.

  SORT gt_varel.
  DELETE ADJACENT DUPLICATES FROM gt_varel.

*     Insert from internal table
  IF NOT gt_varvr[] IS INITIAL.
    gt_varvr-varel_vrsio = vvrsio.
    MODIFY gt_varvr TRANSPORTING varel_vrsio
              WHERE varel_vrsio <> vvrsio.
    MODIFY /psyng/sw_varvr FROM TABLE gt_varvr.
    COMMIT WORK.
  ENDIF.
  IF NOT gt_varel[] IS INITIAL.
    gt_varel-varel_vrsio = vvrsio.
    MODIFY gt_varel TRANSPORTING varel_vrsio
                WHERE varel_vrsio <> vvrsio.
    MODIFY /psyng/sw_varel FROM TABLE gt_varel.
    COMMIT WORK.
    MESSAGE s120(/psyng/sw).
  ENDIF.

ENDFORM.                    " db_changes
*&---------------------------------------------------------------------*
*&      Form  log
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_PATH  text
*      -->P_0794   text
*      -->P_0795   text
*      -->P_0796   text
*      -->P_0797   text
*      -->P_0798   text
*      -->P_0799   text
*----------------------------------------------------------------------*
FORM log USING        i_file
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
*  gt_log-fieldname = i_field.
*  gt_log-value     = i_value.
  gt_log-message   = i_message.
  APPEND gt_log.
ENDFORM.                    " log
*&---------------------------------------------------------------------*
*&      Form  output_log
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM output_log.
  DATA: ls_variant TYPE disvariant,
         l_alv_layout      TYPE slis_layout_alv,
         i_fieldcat_alv  TYPE slis_t_fieldcat_alv.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv,
  l_program LIKE sy-repid.
  l_alv_layout-zebra = 'X'.
  l_alv_layout-colwidth_optimize = 'X'.
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

*--Apply proper labels to field catalog.
  DEFINE alv_text.
    wa_fieldcat_alv-fieldname = &1.
    wa_fieldcat_alv-seltext_s   = &2.
    wa_fieldcat_alv-seltext_m   = &2.
    wa_fieldcat_alv-seltext_l   = &2.
    modify   i_fieldcat_alv from wa_fieldcat_alv
    transporting seltext_s seltext_m seltext_l
    where fieldname = &1.
  END-OF-DEFINITION.
  alv_text :
    'OBJECT'    'Value'(c01),
    'OBJECT_ID' 'Field Name'(c02).
*--Hide the filename field
  wa_fieldcat_alv-no_out = 'X'.
  MODIFY   i_fieldcat_alv FROM wa_fieldcat_alv
  TRANSPORTING no_out
  WHERE fieldname = 'FILENAME'.

  SORT gt_log.
  DELETE ADJACENT DUPLICATES FROM gt_log.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_top_of_page = 'ALV_HEADER'
            i_callback_program     = l_program
            is_layout              = l_alv_layout
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

*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: l_header TYPE slis_t_listheader,
        l_wa TYPE slis_listheader,
        l_count TYPE i,
        l_c_count TYPE string,
        l_alv_grid_titl2   TYPE lvc_title.
  .
*TITLE AREA

  l_wa-typ = 'H'.
  IF dnldtabs EQ 'X'.
    l_wa-info = 'Download'(011).
  ELSE.
    l_wa-info = 'Upload'(021).
  ENDIF.
  APPEND l_wa TO l_header.

*Errors
  CLEAR l_count.
  LOOP AT gt_log WHERE type = '@0A@'.
    ADD 1 TO l_count.
  ENDLOOP.
  l_c_count = l_count.
  l_wa-typ = 'S'.
  l_wa-key = 'Errors'(h05).
  l_wa-info = l_c_count.
  APPEND l_wa TO l_header.
*Warnings
  CLEAR l_count.
  LOOP AT gt_log WHERE type = '@09@'.
    ADD 1 TO l_count.
  ENDLOOP.
  l_c_count = l_count.
  l_wa-typ = 'S'.
  l_wa-key = 'Warnings'(h06).
  l_wa-info = l_c_count.
  APPEND l_wa TO l_header.

*-- Records counts
  CLEAR: l_c_count,l_count.
  DESCRIBE TABLE gt_varel LINES l_count.
  l_c_count = l_count.
  l_wa-typ = 'S'.
  IF dnldtabs EQ 'X'.
    l_wa-key = 'Records Downloaded - '(h08).
  ELSE.
    l_wa-key = 'Records Uploaded - '(h07).
  ENDIF.
  l_wa-info = l_c_count.
  APPEND l_wa TO l_header.

*--File Names
  l_wa-typ = 'S'.
  l_wa-key = 'Rule Version File'(h10).
  l_wa-info = p_path1.
  APPEND l_wa TO l_header.
  l_wa-typ = 'S'.
  l_wa-key = 'Rules File'(h11).
  l_wa-info = p_path.
  APPEND l_wa TO l_header.



  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = l_header.
*            i_logo             = 'Z_3SW_LOGO_JPG'.

ENDFORM.
