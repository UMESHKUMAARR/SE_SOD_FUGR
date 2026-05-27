class /PSYNG/SW_RULESET_IMPORT definition
  public
  final
  create public .

public section.

  types:
    ty_class_name_table TYPE STANDARD TABLE OF seoclsname .

  methods CONSTRUCTOR
    importing
      !FILENAME type STRING
      !CHECK_CLASS_NAMES type TY_CLASS_NAME_TABLE
      !LOGGER type ref to /PSYNG/SW_RULESET_LOGGER optional .
  class-methods CREATE_WITH_FILENAME
    importing
      !I_FILENAME type STRING
      !I_CHECK_CLASS_NAMES type TY_CLASS_NAME_TABLE
      !I_UPLOAD_FILE type BOOLEAN optional
      !I_NULL type BOOLEAN optional
      !I_CONVERT_DATA type BOOLEAN optional
      !I_TRANSFORM_DATA type BOOLEAN optional
      !I_PROCESS_DATA type BOOLEAN optional
      !I_WRITE_LOG type BOOLEAN optional
      !I_CLEAR_DB_TABLES type BOOLEAN optional
      !I_LOGGER type ref to /PSYNG/SW_RULESET_LOGGER optional
    returning
      value(INSTANCE) type ref to /PSYNG/SW_RULESET_IMPORT .
  methods UPLOAD_FILE .
  methods CHECK_XML_DATA_EXISTS
    returning
      value(R_EXISTS) type BOOLEAN .
  methods CHECK_ABAP_DATA_EXISTS
    returning
      value(R_EXISTS) type BOOLEAN .
  methods CONVERT_XML_DATA .
  methods TRANSFORM_DATA .
  methods PROCESS_DATA
    importing
      !I_CLEAR_DB_TABLES type BOOLEAN optional
      !I_NULL type BOOLEAN optional .
  methods CHECK_DATA
    importing
      !I_ABAP_IMPORT_ENTRY type /PSYNG/SW_IMPORT
      !I_NULL type BOOLEAN optional
    returning
      value(R_DATA_IS_CORRECT) type BOOLEAN .
  methods CLEAR_DATABASE .
  methods INSERT_DATA
    importing
      !I_ABAP_IMPORT_ENTRY type /PSYNG/SW_IMPORT
    returning
      value(R_INSERT_SUCCESSFUL) type BOOLEAN .
  methods DISPLAY_LOG .
  methods GET_LOGGER
    returning
      value(R_LOGGER) type ref to /PSYNG/SW_RULESET_LOGGER .
  methods GET_ABAP_DATA
    returning
      value(R_ABAP_DATA) type /PSYNG/SW_IMPORT_T .
protected section.
private section.

  data XML_FILENAME type STRING .
  data XML_IMPORT_DATA type STRING .
  data ABAP_IMPORT_DATA type /PSYNG/SW_IMPORT_T .
  data CHECK_CLASS_NAMES type TY_CLASS_NAME_TABLE .
  data LOGGER type ref to /PSYNG/SW_RULESET_LOGGER .
ENDCLASS.



CLASS /PSYNG/SW_RULESET_IMPORT IMPLEMENTATION.


  METHOD check_abap_data_exists.
    IF me->abap_import_data IS INITIAL.
      r_exists = ''.
    ELSE.
      r_exists = 'X'.
    ENDIF.

  ENDMETHOD.


METHOD check_data.

  DATA: lo_err TYPE REF TO cx_sy_create_object_error,
        lo_check_obj TYPE REF TO /psyng/sw_acl_ruleset_check,
        lv_is_valid  TYPE boolean.
  FIELD-SYMBOLS: <fs_class_name> TYPE seoclsname.

  r_data_is_correct = 'X'.

  TRY.
      LOOP AT me->check_class_names ASSIGNING <fs_class_name>.
        CREATE OBJECT lo_check_obj TYPE (<fs_class_name>)
          EXPORTING
            logger = me->logger.

        lo_check_obj->check_all(
          EXPORTING
            i_check_data  = i_abap_import_entry
            i_null        = i_null
          RECEIVING
            r_is_valid   =   lv_is_valid
        ).
        IF lv_is_valid = ''.
          r_data_is_correct = ''.
        ENDIF.
      ENDLOOP.

    CATCH cx_sy_create_object_error INTO lo_err.
      IF lo_err->kernel_errid = 'CREATE_OBJECT_CLASS_NOT_FOUND'.
        "Logging
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_IMPORT~TRANSFORM_DATA'
            i_msgty = 'E'
            i_msgno = 014
        ).
      ELSE.
        "Logging
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_IMPORT~CHECK_DATA'
            i_msgty = 'E'
            i_msgno = 015
        ).
      ENDIF.
      r_data_is_correct = ''.
  ENDTRY.

  IF <fs_class_name> IS ASSIGNED.
    UNASSIGN <fs_class_name>.
  ENDIF.
ENDMETHOD.


  METHOD check_xml_data_exists.
    IF me->xml_import_data = ''.
      r_exists = ''.
    ELSE.
      r_exists = 'X'.
    ENDIF.
  ENDMETHOD.


METHOD clear_database.

  "Business Process
  DELETE FROM /psyng/sw_buspro.
    IF sy-subrc EQ 0.
       COMMIT WORK .
    ELSE.
       ROLLBACK WORK.
    ENDIF.

  DELETE FROM /psyng/sw_busprt.
    IF sy-subrc EQ 0.
       COMMIT WORK .
    ELSE.
       ROLLBACK WORK.
    ENDIF.


  "Matrix
  DELETE FROM /psyng/sw_rule_h.
    IF sy-subrc EQ 0.
       COMMIT WORK .
    ELSE.
       ROLLBACK WORK.
    ENDIF.
  DELETE FROM /psyng/sw_rule_t.
    IF sy-subrc EQ 0.
       COMMIT WORK .
    ELSE.
       ROLLBACK WORK.
    ENDIF.
  DELETE FROM /psyng/sw_rule_d.
    IF sy-subrc EQ 0.
       COMMIT WORK .
    ELSE.
       ROLLBACK WORK.
    ENDIF.


  "Conflict
  DELETE FROM /psyng/sw_conf_h.
    IF sy-subrc EQ 0.
       COMMIT WORK .
    ELSE.
       ROLLBACK WORK.
    ENDIF.
  DELETE FROM /psyng/sw_conf_t.
    IF sy-subrc EQ 0.
       COMMIT WORK .
    ELSE.
       ROLLBACK WORK.
    ENDIF.
  DELETE FROM /psyng/sw_conf_d.
    IF sy-subrc EQ 0.
       COMMIT WORK .
    ELSE.
       ROLLBACK WORK.
    ENDIF.


  "Function
  DELETE FROM /psyng/sw_func_h.
    IF sy-subrc EQ 0.
       COMMIT WORK .
    ELSE.
       ROLLBACK WORK.
    ENDIF.
  DELETE FROM /psyng/sw_func_t.
    IF sy-subrc EQ 0.
       COMMIT WORK .
    ELSE.
       ROLLBACK WORK.
    ENDIF.
  DELETE FROM /psyng/sw_func_d.
    IF sy-subrc EQ 0.
       COMMIT WORK .
    ELSE.
       ROLLBACK WORK.
    ENDIF.


  "Search Rule
  DELETE FROM /psyng/sw_auth_h.
    IF sy-subrc EQ 0.
       COMMIT WORK .
    ELSE.
       ROLLBACK WORK.
    ENDIF.
  DELETE FROM /psyng/sw_auth_t.
    IF sy-subrc EQ 0.
       COMMIT WORK .
    ELSE.
       ROLLBACK WORK.
    ENDIF.
  DELETE FROM /psyng/sw_auth_d.
    IF sy-subrc EQ 0.
       COMMIT WORK .
    ELSE.
       ROLLBACK WORK.
    ENDIF.


  "Problem
  DELETE FROM /psyng/sw_risk_h.
   IF sy-subrc EQ 0.
       COMMIT WORK .
    ELSE.
       ROLLBACK WORK.
    ENDIF.
  DELETE FROM /psyng/sw_risk_t.
    IF sy-subrc EQ 0.
       COMMIT WORK .
    ELSE.
       ROLLBACK WORK.
    ENDIF.
ENDMETHOD.


  METHOD constructor.
    me->xml_filename = filename.
    me->check_class_names = check_class_names.
    IF logger IS BOUND.
      me->logger = logger.
    ELSE.
      CREATE OBJECT me->logger.
    ENDIF.
  ENDMETHOD.


  METHOD convert_xml_data.
    DATA: lo_matcher TYPE REF TO cl_abap_matcher.
    DATA: lt_matches TYPE match_result_tab.
    DATA: lv_firstinsertat TYPE i.
    DATA: lv_secondinsertat TYPE i.
    FIELD-SYMBOLS: <fs_match> TYPE match_result.
    DATA: lv_log_msg TYPE string.
    DATA: lv_match_cnt TYPE symsgv.

    DATA: lv_xml_string TYPE string.
    lv_xml_string = me->xml_import_data.

    IF me->xml_import_data <> ''.

      "DELETE UNNECESSARY CODE
      CLEAR: lv_match_cnt, lt_matches, lo_matcher, lv_firstinsertat, lv_secondinsertat.
      lo_matcher = cl_abap_matcher=>create(
        pattern       = '</?asx:[^<]*>'
        text          = lv_xml_string
      ).
      lv_match_cnt  = lo_matcher->replace_all( '' ).
      lv_xml_string = lo_matcher->text.

      "Logging
      CONDENSE lv_match_cnt.
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_IMPORT~CONVERT_XML_DATA'
          i_msgty = 'I'
          i_msgno = 005
          i_msgv1 = lv_match_cnt
      ).

      "CONVERT DATES
      CLEAR: lv_match_cnt, lt_matches, lo_matcher,
             lv_firstinsertat, lv_secondinsertat.
      lo_matcher = cl_abap_matcher=>create(
        pattern       = '[0-9]{8}(?=</EXPORT_DATE>)'
        text          = lv_xml_string
      ).
      lt_matches = lo_matcher->find_all( ).
      LOOP AT lt_matches ASSIGNING <fs_match>.
        lv_firstinsertat = <fs_match>-offset + 4 + ( ( sy-tabix - 1 ) * 2 ).
        lv_secondinsertat = <fs_match>-offset + 6 + ( ( sy-tabix - 1 ) * 2 ).
        CONCATENATE lv_xml_string(lv_firstinsertat) '-'
                    lv_xml_string+lv_firstinsertat(2) '-'
                    lv_xml_string+lv_secondinsertat INTO lv_xml_string.
      ENDLOOP.
*
      "Logging
      lv_match_cnt = lines( lt_matches ).
      CONDENSE lv_match_cnt.
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_IMPORT~CONVERT_XML_DATA'
          i_msgty = 'I'
          i_msgno = 006
          i_msgv1 = lv_match_cnt
      ).

      "CONVERT TIME
      CLEAR: lv_match_cnt, lt_matches, lo_matcher, lv_firstinsertat, lv_secondinsertat.
      lo_matcher = cl_abap_matcher=>create(
        pattern       = '[0-9]{6}(?=</EXPORT_TIME>)'
        text          = lv_xml_string
      ).
      lt_matches = lo_matcher->find_all( ).
      LOOP AT lt_matches ASSIGNING <fs_match>.
        lv_firstinsertat = <fs_match>-offset + 2 + ( ( sy-tabix - 1 ) * 2 ).
        lv_secondinsertat = <fs_match>-offset + 4 + ( ( sy-tabix - 1 ) * 2 ).
        CONCATENATE lv_xml_string(lv_firstinsertat) ':'
                    lv_xml_string+lv_firstinsertat(2) ':'
                    lv_xml_string+lv_secondinsertat INTO lv_xml_string.
      ENDLOOP.

      "Logging
      lv_match_cnt = lines( lt_matches ).
      CONDENSE lv_match_cnt.
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_IMPORT~CONVERT_XML_DATA'
          i_msgty = 'I'
          i_msgno = 007
          i_msgv1 = lv_match_cnt
      ).

      me->xml_import_data = lv_xml_string.
        DO.
          REPLACE ALL OCCURRENCES OF 'ï»¿' IN me->xml_import_data WITH ''.
          IF sy-subrc NE 0. EXIT. ENDIF.
        ENDDO.
*      REPLACE ALL OCCURRENCES OF 'ï»¿' IN me->xml_import_data WITH ''.
    ENDIF.
  ENDMETHOD.


  METHOD create_with_filename.
    CREATE OBJECT instance
      EXPORTING
        filename          = i_filename
        check_class_names = i_check_class_names
        logger            = i_logger.

    IF i_upload_file = 'X'.
      instance->upload_file( ). "uplaod the file
    ENDIF.

    IF i_convert_data = 'X'.
      IF instance->check_xml_data_exists( ) = 'X'.
        instance->convert_xml_data( ).  "Convert the XML data
      ELSE.
        "Logging
        instance->logger->add_log_line(
          EXPORTING
            i_work_step =
            '/PSYNG/SW_RULESET_IMPORT~CREATE_WITH_FILENAME'
            i_msgty = 'W'
            i_msgno = 000
        ).
      ENDIF.
    ENDIF.


    IF i_transform_data = 'X'.
      IF instance->check_xml_data_exists( ) = 'X'.
        instance->transform_data( ). "Transform the Data
      ELSE.
        "Logging
        instance->logger->add_log_line(
          EXPORTING
            i_work_step =
            '/PSYNG/SW_RULESET_IMPORT~CREATE_WITH_FILENAME'
            i_msgty = 'W'
            i_msgno = 001
        ).
      ENDIF.
    ENDIF.

    IF i_process_data = 'X'.
      IF instance->check_abap_data_exists( ) = 'X'.
        instance->process_data(
          EXPORTING
            i_clear_db_tables =    i_clear_db_tables
            i_null            =    i_null
        ).
        "Process the data
      ELSE.
        "Logging
        instance->logger->add_log_line(
          EXPORTING
            i_work_step =
            '/PSYNG/SW_RULESET_IMPORT~CREATE_WITH_FILENAME'
            i_msgty = 'W'
            i_msgno = 002
        ).
      ENDIF.
    ENDIF.


    IF i_process_data = 'X'.
      instance->display_log( )."Display logs in ALV
    ENDIF.

  ENDMETHOD.


  METHOD display_log.
    me->logger->display_log( ).
  ENDMETHOD.


  method GET_ABAP_DATA.
   r_abap_data = me->abap_import_data.
  endmethod.


  METHOD get_logger.
    r_logger = me->logger.
  ENDMETHOD.


  METHOD insert_data.


    DATA lv_subrc_count TYPE i VALUE 0.

    DATA lo_err TYPE REF TO cx_sy_open_sql_db.

    TRY.

        "Business Process
        INSERT /psyng/sw_buspro FROM TABLE i_abap_import_entry-bus_process_header.
        lv_subrc_count = lv_subrc_count + sy-subrc.
        INSERT /psyng/sw_busprt FROM TABLE i_abap_import_entry-bus_process_text.
        lv_subrc_count = lv_subrc_count + sy-subrc.

        "Matrix
        INSERT /psyng/sw_rule_h  FROM TABLE i_abap_import_entry-matrix_header.
        lv_subrc_count = lv_subrc_count + sy-subrc.
        INSERT /psyng/sw_rule_t  FROM TABLE i_abap_import_entry-matrix_text.
        lv_subrc_count = lv_subrc_count + sy-subrc.
        INSERT /psyng/sw_rule_d  FROM TABLE i_abap_import_entry-matrix_details.
        lv_subrc_count = lv_subrc_count + sy-subrc.

        "Conflict
        INSERT /psyng/sw_conf_h  FROM TABLE i_abap_import_entry-conflict_header.
        lv_subrc_count = lv_subrc_count + sy-subrc.
        INSERT /psyng/sw_conf_t  FROM TABLE i_abap_import_entry-conflict_text.
        lv_subrc_count = lv_subrc_count + sy-subrc.
        INSERT /psyng/sw_conf_d  FROM TABLE i_abap_import_entry-conflict_details.
        lv_subrc_count = lv_subrc_count + sy-subrc.

        "Function
        INSERT /psyng/sw_func_h  FROM TABLE i_abap_import_entry-function_header.
        lv_subrc_count = lv_subrc_count + sy-subrc.
        INSERT /psyng/sw_func_t  FROM TABLE i_abap_import_entry-function_text.
        lv_subrc_count = lv_subrc_count + sy-subrc.
        INSERT /psyng/sw_func_d  FROM TABLE i_abap_import_entry-function_details.
        lv_subrc_count = lv_subrc_count + sy-subrc.

        "Search Rule
        INSERT /psyng/sw_auth_h  FROM TABLE i_abap_import_entry-search_rule_header.
        lv_subrc_count = lv_subrc_count + sy-subrc.
        INSERT /psyng/sw_auth_t  FROM TABLE i_abap_import_entry-search_rule_text.
        lv_subrc_count = lv_subrc_count + sy-subrc.
        INSERT /psyng/sw_auth_d  FROM TABLE i_abap_import_entry-search_rule_details.
        lv_subrc_count = lv_subrc_count + sy-subrc.

        "Problem
        INSERT /psyng/sw_risk_h  FROM TABLE i_abap_import_entry-problem_header.
        lv_subrc_count = lv_subrc_count + sy-subrc.
        INSERT /psyng/sw_risk_t  FROM TABLE i_abap_import_entry-problem_text.
        lv_subrc_count = lv_subrc_count + sy-subrc.

      CATCH cx_sy_open_sql_db INTO lo_err.
        IF lo_err->kernel_errid = 'DBIF_RSQL_KEY_ALREADY_EXISTS'.
          "Logging
          me->logger->add_log_line(
            EXPORTING
              i_work_step = '/PSYNG/SW_RULESET_IMPORT~INSERT_DATA'
              i_msgty = 'E'
              i_msgno = 019
          ).
        ENDIF.
        lv_subrc_count = 1.
    ENDTRY.

    IF lv_subrc_count = 0.
      COMMIT WORK.
      r_insert_successful = 'X'.
    ELSE.
      ROLLBACK WORK.
      r_insert_successful = ''.
    ENDIF.

  ENDMETHOD.


METHOD process_data.

  FIELD-SYMBOLS: <fs_import_line>  TYPE /psyng/sw_import.
  DATA: lv_import_lines TYPE i.
  DATA : lv_flag TYPE BOOLEAN.

  CLEAR : lv_import_lines.
  lv_import_lines = lines( me->abap_import_data ).
  IF lv_import_lines = 1.
    READ TABLE me->abap_import_data ASSIGNING <fs_import_line> INDEX 1.
    CLEAR lv_flag.
    me->check_data(
      Exporting
       i_abap_import_entry = <fs_import_line>
       i_null              = i_null
     RECEIVING
        r_data_is_correct = lv_flag

   ).
   IF lv_flag EQ 'X'.
      IF i_clear_db_tables = 'X'.
        me->clear_database( ).
        "Logging
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_IMPORT~PROCESS_DATA'
            i_msgty = 'I'
            i_msgno = 017
        ).
      ENDIF.
      IF me->insert_data( <fs_import_line> ) = 'X'.
        "Logging
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_IMPORT~PROCESS_DATA'
            i_msgty = 'I'
            i_msgno = 018
        ).
      ELSE.
        "Logging
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_IMPORT~PROCESS_DATA'
            i_msgty = 'E'
            i_msgno = 011
        ).
      ENDIF.
    ELSE.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_IMPORT~PROCESS_DATA'
          i_msgty = 'E'
          i_msgno = 012
      ).
    ENDIF.
  ELSE.
    "Logging
    DATA: lv_lines TYPE symsgv.
    lv_lines = lv_import_lines.
    CONDENSE lv_lines.
    me->logger->add_log_line(
      EXPORTING
        i_work_step = '/PSYNG/SW_RULESET_IMPORT~PROCESS_DATA'
        i_msgty = 'E'
        i_msgno = 013
        i_msgv1 = lv_lines
    ).
  ENDIF.

ENDMETHOD.


METHOD transform_data.

  DATA:  lo_exception     TYPE REF TO cx_root,
         lo_mat_exception TYPE REF TO cx_st_match_element,
         lo_des_exception TYPE REF TO cx_st_deserialization_error,
         lv_expected TYPE symsgv,
         lv_actual   TYPE symsgv,
         lv_path     TYPE symsgv.
  IF me->xml_import_data <> ''.
    TRY.
        "DATA-TRANSFORMATION
        CALL TRANSFORMATION /psyng/sw_ruleset_transform
        SOURCE XML me->xml_import_data
        RESULT policy_data = me->abap_import_data.

      CATCH cx_st_match_element INTO lo_mat_exception.
        CLEAR me->abap_import_data.
        "Logging
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_IMPORT~TRANSFORM_DATA'
            i_msgty = 'E'
            i_msgno = 008
        ).
        CLEAR : lv_expected , lv_actual.
        lv_expected = lo_mat_exception->expected_name.
        lv_actual   = lo_mat_exception->actual_name.
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_IMPORT~TRANSFORM_DATA'
            i_msgty = 'E'
            i_msgno = 016
            i_msgv1 = lv_expected
            i_msgv2 = lv_actual
        ).
      CATCH cx_st_deserialization_error INTO lo_des_exception.
        CLEAR me->abap_import_data.
        "Logging

        CLEAR lv_path.
        lv_path = lo_des_exception->xml_path.
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_IMPORT~TRANSFORM_DATA'
            i_msgty = 'E'
            i_msgno = 009
            i_msgv1 = lv_path
        ).
      CATCH cx_root INTO lo_exception.
        CLEAR me->abap_import_data.
        "Logging
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_IMPORT~TRANSFORM_DATA'
            i_msgty = 'E'
            i_msgno = 010
        ).
    ENDTRY.
  ENDIF.
ENDMETHOD.


  METHOD upload_file.
    DATA: lt_binary_table TYPE swxmlcont,
          lv_binary_size  TYPE i,
          lv_xml_string   TYPE string,
          lv_filename     TYPE symsgv.


    "FILE_UPLOAD
    CLEAR : lt_binary_table[],lv_binary_size.
*BOC:HBHALLA (097)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '60'.
  IF sy-subrc = 0.
    CALL FUNCTION 'GUI_UPLOAD' "#EC SAST_CI_GEN_CHECK
      EXPORTING
        filename            = me->xml_filename
        filetype            = 'BIN'
        has_field_separator = ' '
        header_length       = 0
      IMPORTING
        filelength          = lv_binary_size
      TABLES
        data_tab            = lt_binary_table
      EXCEPTIONS
        OTHERS              = 1.

    IF sy-subrc <> 0.
      "Logging

      CLEAR : lv_filename.
      lv_filename = me->xml_filename.
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_IMPORT~UPLOAD_FILE'
          i_msgty     = 'E'    " Message Type
          i_msgno     = 003    " Message Number
          i_msgv1     = lv_filename   " Message Variable
      ).
      RETURN.
    ENDIF.
  ENDIF.
*EOC:HBHALLA (097)
    "FILE-CONVERSION
    CLEAR : lv_xml_string.
    CALL FUNCTION 'SCMS_BINARY_TO_STRING'
      EXPORTING
        input_length = lv_binary_size
      IMPORTING
        text_buffer  = lv_xml_string
      TABLES
        binary_tab   = lt_binary_table
      EXCEPTIONS
        failed       = 1
        OTHERS       = 2.

    IF sy-subrc <> 0.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_IMPORT~UPLOAD_FILE'
          i_msgty = 'E'
          i_msgno = 004
      ).
      RETURN.
    ENDIF.

    CLEAR : me->xml_import_data.
    me->xml_import_data = lv_xml_string.
  ENDMETHOD.
ENDCLASS.
