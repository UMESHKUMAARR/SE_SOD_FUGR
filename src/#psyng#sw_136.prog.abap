REPORT /psyng/sw_136 .
TYPE-POOLS:slis.

DATA:  g_folder            TYPE string,
       g_downloadfailed(3).
DATA : BEGIN OF gt_log OCCURS 0,
         filename  LIKE rlgrap-filename,
         type      LIKE icon-id,
         object    LIKE dd03d-fieldname,
         object_id LIKE t100-text,
         fieldname LIKE dd03d-fieldname,
         value     LIKE t100-text,
         message   LIKE t100-text,
       END OF gt_log,
       ls_set      TYPE /psyng/swcfgset.

SELECTION-SCREEN: BEGIN OF BLOCK cnf WITH FRAME TITLE text-c01.
PARAMETERS :   p_cngset LIKE /psyng/swcfgset-setid OBLIGATORY.
SELECTION-SCREEN: END OF BLOCK cnf.

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
SELECTION-SCREEN COMMENT 3(60) text-010 FOR FIELD testrun.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETER p_noval AS CHECKBOX.
SELECTION-SCREEN COMMENT 3(60) text-001 FOR FIELD p_noval.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK opt.

*---Configuration Files
SELECTION-SCREEN: BEGIN OF BLOCK sodmatrix WITH FRAME TITLE text-b03.

**Configuration Set
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(30) text-f11 FOR FIELD  f_cnfst.
PARAMETERS :  f_cnfst TYPE rlgrap-filename LOWER CASE
DEFAULT 'ConfigurationSet.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

*-- System
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(30) text-f12 FOR FIELD f_sys.
PARAMETERS :  f_sys TYPE rlgrap-filename LOWER CASE
DEFAULT 'ConfigurationSystem.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.
*-- org Elements
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(30) text-f13
                                 FOR FIELD f_org.
PARAMETERS :  f_org TYPE rlgrap-filename LOWER CASE
DEFAULT 'OrganizationalElement.txt' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.
*-- Variable Elements
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(30) text-f14
                                 FOR FIELD f_varbl.
PARAMETERS: f_varbl TYPE rlgrap-filename LOWER CASE
DEFAULT 'VariableElement.txt'.
SELECTION-SCREEN: END OF LINE.
*-- Selected Elements
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(30) text-f15
                                FOR FIELD f_sel.
PARAMETERS: f_sel TYPE rlgrap-filename LOWER CASE
DEFAULT 'SelectedElements.txt'.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK sodmatrix.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR basepath.
  PERFORM dir_select .

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN .
    IF screen-name = 'OVRWRT' OR screen-name = 'TESTRUN'
      OR screen-name =  'P_NOVAL'.
      IF upldtabs = 'X'.
        screen-input = 1 .
      ELSE.
        screen-input = 0 .
        CLEAR : ovrwrt,testrun,p_noval.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
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
    PERFORM download_data.
    PERFORM output_log.
  ENDIF.
*
  IF upldtabs = 'X'.
*--Check Config Set is not published
    CALL FUNCTION '/PSYNG/SW_API_GET_CONFIG_SET'
         EXPORTING
              config_set  = p_cngset
              if_def_conf = ''
         IMPORTING
              es_set      = ls_set.
    IF  ls_set-published IS INITIAL.
      PERFORM upload_data.
    ELSE.
      MESSAGE e113(/psyng/sw) WITH 'Published Config Set '(p01)
                                   p_cngset
                                   'can not be changed'(p02).
      LEAVE LIST-PROCESSING.

    ENDIF.
  ENDIF.

*

********************************************************************
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

ENDFORM.


*---------------------------------------------------------------------*
*       FORM alv_header                                               *
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
    wa-info = 'Downloading Configuration Set'(h01).
  ELSE.
    wa-info = 'Uploading Configuration Set'(h03).
  ENDIF.
  APPEND wa TO header.

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
ENDFORM.
*---------------------------------------------------------------------*
*       FORM upload_data                                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM upload_data.
  DATA: lf_file_not_found TYPE flag.
  DATA:
      lt_swcfgset       TYPE TABLE OF /psyng/swcfgset WITH HEADER LINE,
      lt_swcfgsys       TYPE TABLE OF /psyng/swcfgsys WITH HEADER LINE,
      lt_swcfgoe        TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
      lt_swcfgve        TYPE TABLE OF /psyng/swcfgve WITH HEADER LINE,
      lt_swcfsel        TYPE TABLE OF /psyng/swcfsel WITH HEADER LINE,
      l_answer          TYPE c,
      l_msg             TYPE string,
      l_yes             TYPE string.

  PERFORM upload TABLES   lt_swcfgset
                      USING   f_cnfst
                'No data uploaded from PC for /psyng/swcfgset'(072)
                      CHANGING lf_file_not_found.
  IF lf_file_not_found = 'X'.
  ELSE.
    DELETE lt_swcfgset WHERE setid EQ space.
  ENDIF.


  PERFORM upload TABLES   lt_swcfgsys
                   USING   f_sys
                   'No data uploaded from PC for /psyng/swcfgsys'(073)
                   CHANGING lf_file_not_found.
  IF lf_file_not_found = 'X'.
  ELSE.
    DELETE lt_swcfgsys WHERE setid EQ space.
  ENDIF.

  PERFORM upload TABLES  lt_swcfgoe
                        USING   f_org
                      'No data uploaded from PC for /psyng/swcfgoe'(074)
                        CHANGING lf_file_not_found.
  IF lf_file_not_found = 'X'.
  ELSE.
    DELETE lt_swcfgoe WHERE setid EQ space.
  ENDIF.

  PERFORM upload TABLES   lt_swcfgve
                        USING   f_varbl
                      'No data uploaded from PC for /psyng/swcfgve'(075)
                        CHANGING lf_file_not_found.
  IF lf_file_not_found = 'X'.
  ELSE.
    DELETE lt_swcfgve WHERE setid EQ space.
  ENDIF.

  PERFORM upload TABLES   lt_swcfsel
                        USING   f_sel
                      'No data uploaded from PC for /psyng/swcfsel'(076)
                        CHANGING lf_file_not_found.
  IF lf_file_not_found = 'X'.
  ELSE.
    DELETE lt_swcfsel WHERE setid EQ space.
  ENDIF.


*--skip validation
  IF p_noval IS INITIAL.
    PERFORM validation TABLES
       lt_swcfgset
       lt_swcfgsys
       lt_swcfgoe
       lt_swcfgve
       lt_swcfsel.
  ENDIF.

*-- Test run not checked
  IF testrun IS INITIAL.
* Enque/Deques
    IF ovrwrt <> 'X'.
      CONCATENATE
      'Data will be appended to '(o01)
      'Conf. Set'(o02) p_cngset '.'
      'Do you want to continue?'(l02)
      INTO l_msg SEPARATED BY space.
      l_yes = 'Yes'(103).
    ELSE.
      CONCATENATE
      'Conf. Set'(o02) p_cngset ' will be overwritten'(o04) '.'
      'Do you want to continue?'(l02)
       INTO l_msg SEPARATED BY space.
      l_yes = 'Yes'(103).

    ENDIF.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
         EXPORTING
              titlebar              = 'Do you want to continue?'(l02)
              text_question         = l_msg
              text_button_1         = l_yes
              text_button_2         = 'No'(l04)
              display_cancel_button = ''
         IMPORTING
              answer                = l_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             Text_NOT_FOUND  = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
    IF l_answer = '1'.
      IF ovrwrt = 'X'.
*--Delete existing data
        PERFORM delete_data.
      ENDIF.
*---update in database table
      IF NOT lt_swcfgset[] IS INITIAL AND testrun IS INITIAL.
        lt_swcfgset-setid = p_cngset.
        MODIFY lt_swcfgset TRANSPORTING setid WHERE setid <> p_cngset.
        MODIFY /psyng/swcfgset FROM TABLE lt_swcfgset.
      ENDIF.

      IF NOT lt_swcfgsys[] IS INITIAL AND testrun IS INITIAL.
        lt_swcfgsys-setid = p_cngset.
        MODIFY lt_swcfgsys TRANSPORTING setid WHERE setid <> p_cngset.
        MODIFY /psyng/swcfgsys FROM TABLE lt_swcfgsys.
      ENDIF.

      IF NOT lt_swcfgoe[] IS INITIAL AND testrun IS INITIAL.
        lt_swcfgoe-setid = p_cngset.
        MODIFY lt_swcfgoe TRANSPORTING setid WHERE setid <> p_cngset.
        MODIFY /psyng/swcfgoe FROM TABLE lt_swcfgoe.
      ENDIF.

      IF NOT lt_swcfgve[] IS INITIAL AND testrun IS INITIAL.
        lt_swcfgve-setid = p_cngset.
        MODIFY lt_swcfgve TRANSPORTING setid WHERE setid <> p_cngset.
        MODIFY /psyng/swcfgve FROM TABLE lt_swcfgve.
      ENDIF.

      IF NOT lt_swcfsel[] IS INITIAL AND testrun IS INITIAL.
        lt_swcfsel-setid = p_cngset.
        MODIFY lt_swcfsel TRANSPORTING setid WHERE setid <> p_cngset.
        MODIFY /psyng/swcfsel FROM TABLE lt_swcfsel.
      ENDIF.

    ENDIF.
*-- append in log
    IF l_answer = '1' OR testrun = 'X'.
      IF NOT lt_swcfgset[] IS INITIAL.
        PERFORM log  USING
          f_cnfst 'S' '' '' '' ''
          'Insert into table /psyng/swcfgset successful'(106).
      ENDIF.

      IF NOT lt_swcfgsys[] IS INITIAL.
        PERFORM log  USING
          f_sys 'S' '' '' '' ''
          'Insert into table /psyng/swcfgsys successful'(107).
      ENDIF.

      IF NOT lt_swcfgoe[] IS INITIAL.
        PERFORM log  USING
          f_org 'S' '' '' '' ''
          'Insert into table /psyng/swcfgoe successful'(108).
      ENDIF.

      IF NOT lt_swcfgve[] IS INITIAL.
        PERFORM log  USING
          f_varbl 'S' '' '' '' ''
          'Insert into table /psyng/swcfgve successful'(109).
      ENDIF.
    ENDIF.
  ENDIF.

*---log should display in testrun or l_answer <> '2' means
*---either l_answer will be 1 or if testrun = 'X' then l_answer = space.
  IF l_answer <> '2'.
    PERFORM output_log.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM upload                                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_TABLE                                                      *
*  -->  I_FILENAME                                                    *
*  -->  I_ERR_TEXT                                                    *
*  -->  E_FILE_NOT_FOUND                                              *
*---------------------------------------------------------------------*
FORM upload TABLES   et_table
            USING    i_filename TYPE rlgrap-filename
                     i_err_text
                     CHANGING e_file_not_found TYPE flag.

  DATA: l_filename TYPE string,
        l_err_mess TYPE bapiret2-message,
        l_msgv1    TYPE bapiret2-message_v1,
        l_msgv2    TYPE bapiret2-message_v2,
        l_flag     TYPE c.
  CLEAR: e_file_not_found, l_flag.
  FREE : et_table.
  CONCATENATE basepath '\' i_filename INTO l_filename.

  IF l_filename NP '*.txt'.
*    MESSAGE s113(/psyng/am) WITH 'Invalid Format'.
**    LEAVE LIST-PROCESSING.
    l_flag = 'X'.
  ENDIF.
  IF l_flag IS INITIAL.
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
*      EXIT.
      ENDIF.
    ENDIF.
  ENDIF.
*EOC:HBHALLA (097)
  ELSE.
    l_err_mess = 'Invalid Format'(250).
    PERFORM log USING l_filename 'E' '' '' '' '' l_err_mess.
  ENDIF.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM delete_data                                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM delete_data.
  CHECK testrun <> 'X'. "no deletion in testrun

  DELETE FROM /psyng/swcfgset WHERE setid = p_cngset.
  DELETE FROM /psyng/swcfgsys WHERE setid = p_cngset.
  DELETE FROM /psyng/swcfgoe WHERE setid = p_cngset.
  DELETE FROM /psyng/swcfgve WHERE setid = p_cngset.
  COMMIT WORK.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM validation                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_SWCFGSET                                                    *
*  -->  I_SWCFGSYS                                                    *
*  -->  I_SWCFGOE                                                     *
*  -->  I_SWCFGVE                                                     *
*---------------------------------------------------------------------*
FORM validation TABLES   i_swcfgset      STRUCTURE /psyng/swcfgset
                         i_swcfgsys      STRUCTURE /psyng/swcfgsys
                         i_swcfgoe       STRUCTURE /psyng/swcfgoe
                         i_swcfgve       STRUCTURE /psyng/swcfgve
                         i_swcfsel       STRUCTURE /psyng/swcfsel.

  DATA: lt_authx TYPE TABLE OF authx WITH HEADER LINE,
        lt_sw_rfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE.

*-- Auth elements
  SELECT * FROM authx INTO TABLE lt_authx.
*-- system
  SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_sw_rfcdes.

*---org elements validation
  LOOP AT i_swcfgoe.
    IF i_swcfgoe-varbl IS INITIAL.
      PERFORM log USING f_org 'E'
                               'Variable'(l07)
                               ''
                               ''
                               ''
                               'Empty'(l01).
      DELETE i_swcfgoe.
      CONTINUE.
    ELSE.
      READ TABLE lt_authx WITH KEY fieldname = i_swcfgoe-varbl.
      IF sy-subrc NE 0.
        PERFORM log USING f_org 'E'
                         'Variable'(l07)
                         i_swcfgoe-varbl
                         ''
                         ''
                         'Invalid Variable'(112).
        DELETE i_swcfgoe.
        CONTINUE.
      ENDIF.
    ENDIF.

    IF i_swcfgoe-abb IS INITIAL.
      PERFORM log USING f_org 'E'
                               'Area Abbreviation'(l13)
                               ''
                               ''
                               ''
                               'Empty'(l01).
      DELETE i_swcfgoe.
      CONTINUE.
    ENDIF.

    IF i_swcfgoe-setid IS INITIAL.
      PERFORM log USING f_org 'E'
                               'Config. Set ID'(l14)
                               ''
                               ''
                               ''
                               'Empty'(l01).
      DELETE i_swcfgoe.
      CONTINUE.
    ELSE.
      READ TABLE i_swcfgset WITH KEY setid = i_swcfgoe-setid.
      IF sy-subrc NE 0.
        PERFORM log USING f_org 'E'
                         'Config. Set ID'(l14)
                         i_swcfgoe-setid
                         ''
                         ''
                         'Invalid Set ID'(119).
        DELETE i_swcfgoe.
        CONTINUE.
      ENDIF.
    ENDIF.

    IF i_swcfgoe-sysid IS INITIAL.
      PERFORM log USING f_org 'E'
                               'System ID'(l05)
                               ''
                               ''
                               ''
                               'Empty'(l01).
      DELETE i_swcfgsys.
      CONTINUE.
    ELSE.
      READ TABLE lt_sw_rfcdes WITH KEY systid = i_swcfgoe-sysid.
      IF sy-subrc NE 0.
        PERFORM log USING f_org 'E'
                         'System ID'(l05)
                         i_swcfgoe-sysid
                         ''
                         ''
                         'Invalid System ID'(123).
        DELETE i_swcfgoe.
        CONTINUE.
      ENDIF.
    ENDIF.
  ENDLOOP.

*  IF sy-subrc <> 0.
*    PERFORM log USING f_org 'E' '' '' '' '' 'Empty File'(201).
*  ENDIF.

*--- variable elements validations
  LOOP AT i_swcfgve.
    IF i_swcfgve-setid IS INITIAL.
      PERFORM log USING f_varbl 'E'
                               'Config. Set ID'(l14)
                               ''
                               ''
                               ''
                               'Empty'(l01).
      DELETE i_swcfgve.
      CONTINUE.
    ELSE.
      READ TABLE i_swcfgset WITH KEY setid = i_swcfgve-setid.
      IF sy-subrc NE 0.
        PERFORM log USING f_varbl 'E'
                         'Config. Set ID'(l14)
                          i_swcfgve-setid
                         ''
                         ''
                         'Invalid Set ID'(119).
        DELETE i_swcfgve.
        CONTINUE.
      ENDIF.
    ENDIF.

    IF i_swcfgve-sysid IS INITIAL.
      PERFORM log USING f_varbl 'E'
                               'System ID'(l05)
                               ''
                               ''
                               ''
                               'Empty'(l01).
      DELETE i_swcfgsys.
      CONTINUE.
    ELSE.
      READ TABLE lt_sw_rfcdes WITH KEY systid = i_swcfgve-sysid.
      IF sy-subrc NE 0.
        PERFORM log USING f_varbl 'E'
                         'System ID'(l05)
                         i_swcfgve-sysid
                         ''
                         ''
                         'Invalid System ID'(123).
        DELETE i_swcfgve.
        CONTINUE.
      ENDIF.
    ENDIF.


    IF i_swcfgve-var_element IS INITIAL.
      PERFORM log USING f_varbl 'E'
                               'Variable'(l07)
                               ''
                               ''
                               ''
                               'Empty'(l01).
      DELETE i_swcfgve.
      CONTINUE.
    ENDIF.
  ENDLOOP.
*  IF sy-subrc <> 0.
*    PERFORM log USING f_varbl 'E' '' '' '' '' 'Empty File'(201).
*  ENDIF.

*--- system validation
  LOOP AT i_swcfgsys.
    IF i_swcfgsys-sysid IS INITIAL.
      PERFORM log USING f_sys 'E'
                               'System ID'(l05)
                               ''
                               ''
                               ''
                               'Empty'(l01).
      DELETE i_swcfgsys.
      CONTINUE.
    ELSE.
      READ TABLE lt_sw_rfcdes WITH KEY systid = i_swcfgsys-sysid.
      IF sy-subrc NE 0.
        PERFORM log USING f_sys 'E'
                         'System ID'(l05)
                         i_swcfgsys-sysid
                         ''
                         ''
                         'Invalid System ID'(123).
        DELETE i_swcfgsys.
        CONTINUE.
      ENDIF.
    ENDIF.

    IF i_swcfgsys-setid IS INITIAL.
      PERFORM log USING f_sys 'E'
                               'Config. Set ID'(l14)
                               ''
                               ''
                               ''
                               'Empty'(l01).
      DELETE i_swcfgsys.
      CONTINUE.
    ELSE.
      READ TABLE i_swcfgset WITH KEY setid = i_swcfgsys-setid.
      IF sy-subrc NE 0.
        PERFORM log USING f_sys 'E'
                         'Config. Set ID'(l14)
                         i_swcfgoe-setid
                         ''
                         ''
                         'Invalid Set ID'(119).
        DELETE i_swcfgsys.
        CONTINUE.
      ENDIF.

    ENDIF.
  ENDLOOP.
*  IF sy-subrc <> 0.
*    PERFORM log USING f_sys 'E' '' '' '' '' 'Empty File'(201).
*  ENDIF.

  LOOP AT i_swcfgset.
    IF i_swcfgset-setid IS INITIAL.
      PERFORM log USING f_cnfst 'E'
                               'Config. Set ID'(l14)
                               ''
                               ''
                               ''
                               'Empty'(l01).
      DELETE i_swcfgset.
      CONTINUE.
    ENDIF.

    IF i_swcfgset-create_date > sy-datum.
      PERFORM log USING f_cnfst 'E'
                               'Create Date'(122)
                               ''
                               ''
                               ''
                            'Cannot be greater than current date'(l21).
      DELETE i_swcfgset.
      CONTINUE.
    ENDIF.

    IF i_swcfgset-change_date > sy-datum.
      PERFORM log USING f_cnfst 'E'
                               'Change Date'(120)
                               ''
                               ''
                               ''
                            'Cannot be greater than current date'(l21).
      DELETE i_swcfgset.
      CONTINUE.
    ENDIF.

  ENDLOOP.

*  IF i_swcfgset[] IS INITIAL.
*    PERFORM log USING f_cnfst 'E' '' '' '' '' 'Empty File'(201).
*  ENDIF.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM download_data                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM download_data.
  DATA:
      lt_swcfgset       TYPE TABLE OF /psyng/swcfgset WITH HEADER LINE,
      lt_swcfgsys       TYPE TABLE OF /psyng/swcfgsys WITH HEADER LINE,
      lt_swcfgoe        TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
      lt_swcfgve        TYPE TABLE OF /psyng/swcfgve WITH HEADER LINE,
      lt_swcsel         TYPE TABLE OF /psyng/swcfsel WITH HEADER LINE.

  SELECT * FROM /psyng/swcfgset INTO TABLE lt_swcfgset
  WHERE setid = p_cngset .
  PERFORM download TABLES lt_swcfgset
                    USING f_cnfst
                    'Unable to download Configuration Set file'(t24)
                    CHANGING g_downloadfailed.

  SELECT * FROM /psyng/swcfgsys INTO TABLE lt_swcfgsys
  WHERE setid = p_cngset.
  PERFORM download TABLES lt_swcfgsys
                 USING f_sys
                 'Unable to download Configuration System file'(t25)
                 CHANGING g_downloadfailed.

  SELECT * FROM /psyng/swcfgoe INTO TABLE lt_swcfgoe
  WHERE setid = p_cngset .
  PERFORM download TABLES lt_swcfgoe
                 USING f_org
                 'Unable to download Organizational Elements file'(t26)
                 CHANGING g_downloadfailed.

  SELECT * FROM /psyng/swcfgve INTO TABLE lt_swcfgve
  WHERE setid = p_cngset .
  PERFORM download TABLES lt_swcfgve
                 USING f_varbl
                 'Unable to download Variable Elements file'(t27)
                 CHANGING g_downloadfailed.

  SELECT * FROM /psyng/swcfsel INTO TABLE lt_swcsel
  WHERE setid = p_cngset .
  PERFORM download TABLES lt_swcsel
                 USING f_sel
                 'Unable to download Selected Elements file'(t28)
                 CHANGING g_downloadfailed.


ENDFORM.


*---------------------------------------------------------------------*
*       FORM download                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_TABLE                                                      *
*  -->  I_FILENAME                                                    *
*  -->  I_ERR_TEXT                                                    *
*  -->  E_DOWNLOADFAILED                                              *
*---------------------------------------------------------------------*
FORM download TABLES   it_table
              USING    i_filename TYPE rlgrap-filename
                       i_err_text
              CHANGING e_downloadfailed.

  DATA: l_filename TYPE string,
          l_err_mess TYPE bapiret2-message,
          l_msgv1    TYPE bapiret2-message_v1,
          l_msgv2    TYPE bapiret2-message_v2.

  DATA: v_file TYPE string.
  DATA: v_dir TYPE string.

  CONCATENATE basepath '\' i_filename INTO l_filename.

  IF l_filename NP '*.txt'.
    MESSAGE s113(/psyng/sw) WITH 'Invalid Format'(013).
    LEAVE LIST-PROCESSING.
  ENDIF.
  IF it_table[] IS INITIAL.
    e_downloadfailed = 'Yes'(014).
  ENDIF.
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
    e_downloadfailed = 'Yes'(014).
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
      l_filename 'S' '' '' '' ''  text-015.

  ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
ENDFORM.

*---------------------------------------------------------------------*
*       FORM log                                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_FILE                                                        *
*  -->  I_TYPE                                                        *
*  -->  I_OBJECT                                                      *
*  -->  I_OBJECT_ID                                                   *
*  -->  I_FIELD                                                       *
*  -->  I_VALUE                                                       *
*  -->  I_MESSAGE                                                     *
*---------------------------------------------------------------------*
FORM log USING   i_file
                  i_type
                  i_object
                  i_object_id
                  i_field
                  i_value
                  i_message.

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
*       FORM dir_select                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM dir_select.
  DATA : l_file_path TYPE rlgrap-filename.
  l_file_path = basepath.


  DATA :   l_uaction   TYPE i,
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
ENDFORM.
