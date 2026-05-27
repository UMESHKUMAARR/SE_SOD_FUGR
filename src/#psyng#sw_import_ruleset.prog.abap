*&---------------------------------------------------------------------*
*& Report  /PSYNG/SW_IMPORT_RULESET
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT /psyng/sw_import_ruleset MESSAGE-ID /psyng/sw NO STANDARD PAGE
HEADING.

INCLUDE /psyng/sw_import_top. "Data declaration
INCLUDE /psyng/sw_import_sel. "Selection-Screen
INCLUDE /psyng/sw_import_f01. "Subroutines

* -----------------------------------------------------------------


INITIALIZATION.
"Check wheather user is authorized to run the report.
AUTHORITY-CHECK OBJECT 'S_TCODE'
                    ID 'TCD' FIELD '/PSYNG/SW_IMP_RULSET'.
IF sy-subrc <> 0.
  MESSAGE e077(s#) WITH '/PSYNG/SW_IMP_RULSET'(004).
  LEAVE LIST-PROCESSING.
ENDIF.

AT SELECTION-SCREEN OUTPUT.

  PERFORM sel_screen_output.

AT SELECTION-SCREEN.
"File path should not be empty.
  PERFORM vaildate_file_path.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_upload.
  "FILE_BROWSER
  CALL FUNCTION '/SAPDMC/LSM_F4_FRONTEND_FILE'
    EXPORTING
      pathname         = 'C:\Users\%USERPROFILE%\Desktop\'
    CHANGING
      pathfile         = p_upload
    EXCEPTIONS
      canceled_by_user = 1
      system_error     = 2
      OTHERS           = 3.
    IF sy-subrc EQ 1.
      MESSAGE 'Upload cancelled by User'(T02) TYPE 'I' DISPLAY LIKE 'E'
      .
      LEAVE TO SCREEN '1000'.
    ELSEIF sy-subrc EQ 2.
      MESSAGE 'System Error'(T03) TYPE 'I' DISPLAY LIKE 'E'.
      LEAVE TO SCREEN '1000'.
    ELSEIF sy-subrc GT 2.
      MESSAGE 'Error occurred while browsing file'(T04) TYPE 'I' DISPLAY
      LIKE 'E'.
      LEAVE TO SCREEN '1000'.
   ENDIF.
* -----------------------------------------------------------------

START-OF-SELECTION.

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute '(005) sy-repid.
    EXIT.
  ENDIF.
  CLEAR : gv_filename.
  gv_filename = p_upload.

  CLEAR gt_class_names[].
  IF p_meta = 'X'.
    APPEND '/PSYNG/SW_RULESET_CHECK_META' TO gt_class_names.
  ENDIF.

  CLEAR go_import_obj.
  go_import_obj = /psyng/sw_ruleset_import=>create_with_filename(
                   i_filename          = gv_filename
                   "File name from selection screen
                   i_check_class_names = gt_class_names
                   "Classes to check meta data
                   i_clear_db_tables   = p_clr_db
                   "Check from selection screen to clear DB or not
                   i_upload_file       = 'X'
                   "Uploading file and reading the data
                   i_null              = p_null
                   i_convert_data      = 'X'
                   "Conversion to XML data
                   i_transform_data    = 'X'
                   "Transform the XML data to ABAP data
                   i_process_data      = 'X'
                   "Process the ABAP data
                   i_write_log         = 'X' ).         "Write the logs



* -----------------------------------------------------------------
