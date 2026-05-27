CLASS /psyng/cl_sw_ruleset_convsn DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_log_line,
        work_step TYPE string,
        key       TYPE string.
        INCLUDE TYPE symsg.
      TYPES:    END OF ty_log_line .
   types:
    TY_LOG_TABLE type STANDARD TABLE OF TY_LOG_LINE WITH DEFAULT KEY .
*    TYPES:
*      tt_logs TYPE STANDARD TABLE OF ty_log WITH DEFAULT KEY .

    METHODS constructor
      IMPORTING
        !delete_db TYPE /psyng/bapiflagx DEFAULT ' ' .
    METHODS convert_data
      IMPORTING
        VALUE(i_vrsn)     TYPE /psyng/conflict-vrsio OPTIONAL
        VALUE(i_exstng)   TYPE flag OPTIONAL
        VALUE(i_vrs_desc) TYPE /psyng/swsodvers-vdesc OPTIONAL
        VALUE(i_ovrwrt)   TYPE flag OPTIONAL
        VALUE(i_testrun)  TYPE flag OPTIONAL
        VALUE(i_skp_vald) TYPE flag OPTIONAL
      EXPORTING
        VALUE(exp_log)    TYPE /psyng/sw_tab_gt_log .
    METHODS string_to_tline
      IMPORTING
        !in        TYPE string
        !lang      TYPE lang DEFAULT sy-langu
      RETURNING
        VALUE(out) TYPE tline_tab .
    METHODS log
      IMPORTING
        !i_file      TYPE rlgrap-filename
        !i_type      TYPE icon-id
        !i_object    TYPE dd03d-fieldname
        !i_object_id TYPE t100-text
        !i_field     TYPE dd03d-fieldname
        !i_value     TYPE t100-text
        !i_message   TYPE t100-text
      EXPORTING
        !e_gt_log    TYPE /psyng/sw_tab_gt_log .
    METHODS check_lock
      IMPORTING
        !i_object  TYPE char30
        !p_vrsn    TYPE /psyng/conflict-vrsio
      CHANGING
        !ef_locked TYPE flag
        !e_locks   TYPE i .
    METHODS delete_data
      IMPORTING
        !i_object TYPE char30
        !if_lock  TYPE flag
        !p_vrsn   TYPE /psyng/conflict-vrsio
        !testrun  TYPE c .
    METHODS output_log
      IMPORTING
        !gt_log TYPE /psyng/sw_tab_gt_log .
    METHODS validation
      IMPORTING
        VALUE(i_vrsn)      TYPE /psyng/conflict-vrsio OPTIONAL
        VALUE(iconflict)   TYPE /psyng/sw_tab_conflict OPTIONAL
        VALUE(ifunction)   TYPE /psyng/sw_tab_function OPTIONAL
        VALUE(ifuncttrans) TYPE /psyng/sw_tab_functtran OPTIONAL
        VALUE(ftexts)      TYPE /psyng/sw_tab_texts OPTIONAL
        VALUE(ifaobj)      TYPE /psyng/sw_tab_faobj OPTIONAL
        VALUE(isysfun)     TYPE /psyng/sw_tab_sysfun OPTIONAL
        VALUE(iconfdet)    TYPE /psyng/sw_tab_confdet OPTIONAL
        VALUE(ctexts)      TYPE /psyng/sw_tab_texts OPTIONAL
        VALUE(iconowners)  TYPE /psyng/sw_tab_conowner OPTIONAL
        VALUE(iconpmit)    TYPE /psyng/sw_tab_conpmit OPTIONAL
        VALUE(isyscon)     TYPE /psyng/sw_tab_syscon OPTIONAL
        VALUE(iswaudhdr)   TYPE /psyng/sw_tab_swaudhdr OPTIONAL
        VALUE(iswaudc)     TYPE /psyng/sw_tab_swaudc2 OPTIONAL
        VALUE(atexts)      TYPE /psyng/sw_tab_swaudc2 OPTIONAL
        VALUE(isysca)      TYPE /psyng/sw_tab_sysca OPTIONAL
        VALUE(icritcodes)  TYPE /psyng/sw_tab_critcodes OPTIONAL
        VALUE(ttexts)      TYPE /psyng/sw_tab_texts OPTIONAL
        VALUE(isystcd)     TYPE /psyng/sw_tab_systcd OPTIONAL
      EXPORTING
        VALUE(vald_log)    TYPE /psyng/sw_tab_gt_log .
protected section.

  data DELETE_DB type BOOLEAN .
  data DATA type /PSYNG/SW_IMPORT .
  data LOGGER type ref to /PSYNG/SW_RULESET_LOGGER .
  data CHECKER type ref to /PSYNG/SW_ACL_RULESET_CHECK .

  methods CONV_PROBLEM_TEXT
  abstract
    importing
      !CONV_DATA type /PSYNG/SW_RISK_T_T
      !FULL_DATA type /PSYNG/SW_IMPORT
      !P_VRSN type /PSYNG/CONFLICT-VRSIO
      value(OVRWRT) type C optional
      value(TESTRUN) type C optional
      value(P_NOVAL) type C optional
    exporting
      !IS_CONVERTED type /PSYNG/BAPIFLAGX .
  methods CONV_PROBLEM_HEADER
  abstract
    importing
      !CONV_DATA type /PSYNG/SW_RISK_H_T
      !FULL_DATA type /PSYNG/SW_IMPORT
      !P_VRSN type /PSYNG/CONFLICT-VRSIO
    exporting
      !IS_CONVERTED type /PSYNG/SW_IMPORT .
  methods CONV_SEARCH_RULE_DETAILS
  abstract
    importing
      !CONV_DATA type /PSYNG/SW_AUTH_D_T
      !FULL_DATA type /PSYNG/SW_IMPORT
      !P_VRSN type /PSYNG/CONFLICT-VRSIO
    exporting
      !IS_CONVERTED type /PSYNG/BAPIFLAGX .
  methods CONV_SEARCH_RULE_TEXT
  abstract
    importing
      !CONV_DATA type /PSYNG/SW_AUTH_T_T
      !FULL_DATA type /PSYNG/SW_IMPORT
      !P_VRSN type /PSYNG/CONFLICT-VRSIO
      value(OVRWRT) type /PSYNG/BAPIFLAGX optional
      value(TESTRUN) type /PSYNG/BAPIFLAGX optional
      value(P_NOVAL) type /PSYNG/BAPIFLAGX optional
    exporting
      !IS_CONVERTED type /PSYNG/BAPIFLAGX .
  methods CONV_CONFLICT_DETAILS
  abstract
    importing
      !CONV_DATA type /PSYNG/SW_CONF_D_T
      !FULL_DATA type /PSYNG/SW_IMPORT
      !P_VRSN type /PSYNG/CONFLICT-VRSIO
    exporting
      !IS_CONVERTED type /PSYNG/BAPIFLAGX .
  methods CONV_MATRIX_DETAILS
  abstract
    importing
      !CONV_DATA type /PSYNG/SW_RULE_D_T
      !FULL_DATA type /PSYNG/SW_IMPORT
      !P_VRSN type /PSYNG/CONFLICT-VRSIO
    exporting
      !IS_CONVERTED type /PSYNG/BAPIFLAGX .
  methods CONV_PROCESS_TEXT
  abstract
    importing
      !CONV_DATA type /PSYNG/SW_BUSPRT_T
      !FULL_DATA type /PSYNG/SW_IMPORT
      !P_VRSN type /PSYNG/CONFLICT-VRSIO
    exporting
      !IS_CONVERTED type /PSYNG/BAPIFLAGX .
  methods CONV_PROCESS_HEADER
  abstract
    importing
      !CONV_DATA type /PSYNG/SW_BUSPRO_T
      !FULL_DATA type /PSYNG/SW_IMPORT
      !P_VRSN type /PSYNG/CONFLICT-VRSIO
      value(OVRWRT) type C optional
      value(TESTRUN) type C optional
      value(P_NOVAL) type C optional
    exporting
      !IS_CONVERTED type /PSYNG/BAPIFLAGX .
  methods CONV_CONFLICT_TEXT
  abstract
    importing
      !CONV_DATA type /PSYNG/SW_CONF_T_T
      !FULL_DATA type /PSYNG/SW_IMPORT
      !P_VRSN type /PSYNG/CONFLICT-VRSIO
    exporting
      !IS_CONVERTED type /PSYNG/BAPIFLAGX .
  methods CONV_FUNCTION_DETAILS
  abstract
    importing
      !CONV_DATA type /PSYNG/SW_FUNC_D_T
      !FULL_DATA type /PSYNG/SW_IMPORT
      !P_VRSN type /PSYNG/CONFLICT-VRSIO
    exporting
      !IS_CONVERTED type /PSYNG/BAPIFLAGX .
  methods CONV_FUNCTION_HEADER
  abstract
    importing
      !CONV_DATA type /PSYNG/SW_FUNC_H_T
      !FULL_DATA type /PSYNG/SW_IMPORT
      !P_VRSN type /PSYNG/CONFLICT-VRSIO
      value(OVRWRT) type C optional
      value(TESTRUN) type C optional
      value(P_NOVAL) type C optional
    exporting
      !IS_CONVERTED type /PSYNG/BAPIFLAGX
      value(GT_LOG) type /PSYNG/SW_TAB_GT_LOG .
  methods CONV_FUNCTION_TEXT
  abstract
    importing
      !CONV_DATA type /PSYNG/SW_FUNC_T_T
      !FULL_DATA type /PSYNG/SW_IMPORT
      !P_VRSN type /PSYNG/CONFLICT-VRSIO
    exporting
      !IS_CONVERTED type /PSYNG/BAPIFLAGX .
  methods CONV_SEARCH_RULE_HEADER
  abstract
    importing
      !CONV_DATA type /PSYNG/SW_AUTH_H_T
      !FULL_DATA type /PSYNG/SW_IMPORT
      !P_VRSN type /PSYNG/CONFLICT-VRSIO
      value(OVRWRT) type /PSYNG/BAPIFLAGX optional
      value(TESTRUN) type /PSYNG/BAPIFLAGX optional
      value(P_NOVAL) type /PSYNG/BAPIFLAGX optional
    exporting
      !IS_CONVERTED type /PSYNG/BAPIFLAGX .
  methods CONV_CONFLICT_HEADER
  abstract
    importing
      !CONV_DATA type /PSYNG/SW_CONF_H_T
      !FULL_DATA type /PSYNG/SW_IMPORT
      !P_VRSN type /PSYNG/CONFLICT-VRSIO
      value(OVRWRT) type C optional
      value(TESTRUN) type C optional
      value(P_NOVAL) type C optional
    exporting
      !IS_CONVERTED type /PSYNG/BAPIFLAGX
      value(GT_LOG) type /PSYNG/SW_TAB_GT_LOG .
  methods CONV_MATRIX_TEXT
  abstract
    importing
      !CONV_DATA type /PSYNG/SW_RULE_T_T
      !FULL_DATA type /PSYNG/SW_IMPORT
      !P_VRSN type /PSYNG/CONFLICT-VRSIO
    exporting
      !IS_CONVERTED type /PSYNG/BAPIFLAGX .
  methods CONV_MATRIX_HEADER
  abstract
    importing
      !CONV_DATA type /PSYNG/SW_RULE_H_T
      !FULL_DATA type /PSYNG/SW_IMPORT
      !P_VRSN type /PSYNG/CONFLICT-VRSIO
      value(IV_CHECK) type C optional
      value(I_VDESC) type /PSYNG/SWSODVERS-VDESC optional
      value(OVRWRT) type C optional
      value(TESTRUN) type C optional
      value(P_NOVAL) type C optional
    exporting
      !IS_CONVERTED type /PSYNG/BAPIFLAGX .
private section.

  types:
    STR_TAB TYPE STANDARD TABLE OF string .

  methods CONV_ALL
    importing
      value(CONV_DATA) type /PSYNG/SW_IMPORT optional
      value(I_VRSIO) type /PSYNG/CONFLICT-VRSIO optional
      value(I_CHKBOX) type /PSYNG/BAPIFLAGX optional
      value(I_VRSIO_DESC) type /PSYNG/SWSODVERS-VDESC optional
      value(I_OVERWRITE) type /PSYNG/BAPIFLAGX optional
      value(I_TEST) type /PSYNG/BAPIFLAGX optional
      value(I_VALD) type /PSYNG/BAPIFLAGX optional
    exporting
      value(OUT_LOG) type /PSYNG/SW_TAB_GT_LOG
      value(IS_CONVERTED) type /PSYNG/BAPIFLAGX .
  methods STRING_TO_SHORT_LINES
    importing
      !STR type STRING
    exporting
      value(STR_TAB) type /PSYNG/CL_SW_RULESET_CONVSN=>STR_TAB .
  methods READ_DATA .
  methods CLEAR_DATABASE .
ENDCLASS.



CLASS /PSYNG/CL_SW_RULESET_CONVSN IMPLEMENTATION.


  method CHECK_LOCK.
    DATA : l_gname      TYPE seqg3-gname,
         lt_seqg3     TYPE TABLE OF seqg3 ,
         ls_seqg3     TYPE seqg3 ,
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
      LOOP AT lt_seqg3 INTO ls_seqg3.
        CASE i_object.
          WHEN 'FUNCTION'.
            ls_function = ls_seqg3-gtarg.
            IF ls_function-vrsio = p_vrsn.
              ADD 1 TO l_locks.
            ENDIF.
          WHEN 'CONFLICT'.
            ls_conflict = ls_seqg3-gtarg.
            IF ls_conflict-vrsio = p_vrsn.
              ADD 1 TO l_locks.
            ENDIF.
          WHEN 'SWAUD'.
            ls_swaud = ls_seqg3-gtarg.
            IF ls_swaud-vrsio = p_vrsn.
              ADD 1 TO l_locks.
            ENDIF.
          WHEN 'CRITCODES'.
            ls_critcodes = ls_seqg3-gtarg.
            IF ls_critcodes-vrsio = p_vrsn.
              ADD 1 TO l_locks.
            ENDIF.
          WHEN 'CRIROLES'.
            ls_criroles = ls_seqg3-gtarg.
            IF ls_criroles-vrsio = p_vrsn.
              ADD 1 TO l_locks.
            ENDIF.

          WHEN 'CRIPROF'.
            ls_criprof = ls_seqg3-gtarg.
            IF ls_criprof-vrsio = p_vrsn.
              ADD 1 TO l_locks.
            ENDIF.

          WHEN 'CRITTEXT'.
            ls_texts = ls_seqg3-gtarg.
            IF ls_texts-vrsio = p_vrsn.
              ADD 1 TO l_locks.
            ENDIF.


          WHEN 'CRIRTEXT'.

            ls_texts = ls_seqg3-gtarg.
            IF ls_texts-vrsio = p_vrsn.
              ADD 1 TO l_locks.
            ENDIF.


          WHEN 'CRIPTEXT'.

            ls_texts = ls_seqg3-gtarg.
            IF ls_texts-vrsio = p_vrsn.
              ADD 1 TO l_locks.
            ENDIF.

          WHEN 'FNFLTR'.

            ls_sysfun = ls_seqg3-gtarg.
            IF ls_sysfun-vrsio = p_vrsn.
              ADD 1 TO l_locks.
            ENDIF.

          WHEN 'CONFLTR'.

            ls_syscon = ls_seqg3-gtarg.
            IF ls_syscon-vrsio = p_vrsn.
              ADD 1 TO l_locks.
            ENDIF.

          WHEN 'CRITFLTR'.

            ls_systcd = ls_seqg3-gtarg.
            IF ls_systcd-vrsio = p_vrsn.
              ADD 1 TO l_locks.
            ENDIF.

          WHEN 'CAFLTR'.

            ls_sysca = ls_seqg3-gtarg.
            IF ls_sysca-vrsio = p_vrsn.
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
  endmethod.


  METHOD clear_database.
    DELETE FROM /psyng/sw_auth_h WHERE search_rule LIKE '%'.
    DELETE FROM /psyng/sw_auth_t WHERE search_rule LIKE '%'.
    DELETE FROM /psyng/sw_auth_d WHERE search_rule LIKE '%'.
    DELETE FROM /psyng/sw_buspro WHERE busprocid LIKE '%'.
    DELETE FROM /psyng/sw_busprt WHERE busprocid LIKE '%'.
    DELETE FROM /psyng/sw_conf_h WHERE sod_conflict LIKE '%'.
    DELETE FROM /psyng/sw_conf_t WHERE sod_conflict LIKE '%'.
    DELETE FROM /psyng/sw_conf_d WHERE sod_conflict LIKE '%'.
    DELETE FROM /psyng/sw_func_h WHERE sod_function LIKE '%'.
    DELETE FROM /psyng/sw_func_t WHERE sod_function LIKE '%'.
    DELETE FROM /psyng/sw_func_d WHERE sod_function LIKE '%'.
    DELETE FROM /psyng/sw_risk_h WHERE risk_id LIKE '%'.
    DELETE FROM /psyng/sw_risk_t WHERE risk_id LIKE '%'.
    DELETE FROM /psyng/sw_rule_h WHERE rulesetid LIKE '%'.
    DELETE FROM /psyng/sw_rule_t WHERE rulesetid LIKE '%'.
    DELETE FROM /psyng/sw_rule_d WHERE rulesetid LIKE '%'.
  ENDMETHOD.


  method CONSTRUCTOR.
      me->logger = logger.

      me->checker = checker.

      me->delete_db = delete_db.
*
      me->read_data( ).
  endmethod.


  method CONVERT_DATA.

*=========== DATA DECLARATION ============

  DATA all_converted TYPE c.   "var. to confirm conversion of all tables

*============ METHOD CALL ================

*  all_converted = me->conv_all(
     me->conv_all(
     EXPORTING    conv_data    = me->data
                  i_vrsio      =  i_vrsn     " SOD Version Export
                  i_chkbox     =  i_exstng   " Existing version descrp
                  i_vrsio_desc =  i_vrs_desc " New version description
                  i_overwrite  =  i_ovrwrt   " Overwrite Version
                  i_test       =  i_testrun  " Testrun
                  i_vald       =  i_skp_vald " Skip validations
     IMPORTING    out_log      =  exp_log    " Log table
                  is_converted = all_converted
                   ).
  IF all_converted = 'X'.

    IF me->delete_db = 'X'.
       me->clear_database( ).                " Delete Meta Data
    ENDIF.

  ENDIF.

  endmethod.


METHOD conv_all.

  DATA: converted  TYPE c,
        func_log   TYPE TABLE OF /psyng/sw_gt_log,
        "itab for func tables log
        cnflct_log TYPE TABLE OF /psyng/sw_gt_log,
        "itab for cnflct tables log
        ls_log     TYPE /psyng/sw_gt_log,
        "wa for log table
        admf_txt(30),
        l_actvt(2).
  CLEAR is_converted.
  is_converted = 'X'.  "Initializtion of var.

*Authority Check to Overwrite tables.
  IF i_overwrite = 'X'.

    l_actvt  = 'UL'.
    admf_txt = text-036.

    AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
             ID 'Y&SW_ADMF' FIELD 'RCONFUN'.

    IF sy-subrc NE 0.
      MESSAGE e108(/psyng/sw) WITH admf_txt.
    ENDIF.

    AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
             ID 'ACTVT' FIELD l_actvt
             ID 'Y&SW_VRSIO' FIELD i_vrsio.
    IF sy-subrc <> 0.
      MESSAGE e108(/psyng/sw) WITH admf_txt text-b00 i_vrsio.
    ENDIF.

  ENDIF.

*--Method to convert matrix_header to /PSYNG/SWSODVERS
  CLEAR converted.
  me->conv_matrix_header(
    EXPORTING
      conv_data = conv_data-matrix_header "relevant data from structure
      full_data = conv_data               "whole structure data
      p_vrsn    = i_vrsio                 "sod version
      iv_check = i_chkbox                 "existing version description
      i_vdesc  = i_vrsio_desc             "new version description
      ovrwrt   = i_overwrite              "overwrite tables for version
      testrun  = i_test                   "testrun
      p_noval  = i_vald                   "skip validations
    IMPORTING
      is_converted = converted            "conversion success or not
  ).
  IF converted = ''.
    is_converted = ''.
  ENDIF.

*--Method to convert process_header to /PSYNG/BUSAREA
  CLEAR converted.
  me->conv_process_header(
 EXPORTING
  conv_data = conv_data-bus_process_header"relevant data from structure
  full_data = conv_data                   "whole structure data
  p_vrsn    = i_vrsio                     "sod version
  ovrwrt   = i_overwrite                  "overwrite tables for version
  testrun  = i_test                       "testrun
  p_noval  = i_vald                       "skip validations
 IMPORTING
   is_converted = converted                "conversion success or not
  ).
  IF converted = ''.
    is_converted = ''.
  ENDIF.

*Method to convert function_header, details & text
*to /PSYNG/FUNCTTRAN,/PSYNG/FAOBJ2,/PSYNG/FUNCTION & /PSYNG/TEXTS
  CLEAR converted.
  me->conv_function_header(
    EXPORTING
     conv_data = conv_data-function_header"relevant data from structure
     full_data = conv_data                "whole structure data
     p_vrsn    = i_vrsio                  "sod version
     ovrwrt    =  i_overwrite             "overwrite tables for version
     testrun   =  i_test                  "testrun
     p_noval   =  i_vald                  "skip validations
    IMPORTING
      is_converted = converted             "conversion success or not
      gt_log       = func_log              "log table for functions
  ).
  IF converted = ''.
    is_converted = ''.
  ENDIF.

  LOOP AT func_log INTO ls_log.
    APPEND ls_log TO out_log.
    CLEAR ls_log.
  ENDLOOP.


*Method to convert conflict_header, details & text
*to /PSYNG/CONFLICT,/PSYNG/CONFDET & /PSYNG/TEXTS
  CLEAR converted.
  me->conv_conflict_header(
    EXPORTING
     conv_data = conv_data-conflict_header"relevant data from structure
     full_data = conv_data                "whole structure data
     p_vrsn    = i_vrsio                  "sod version
     ovrwrt    =  i_overwrite             "overwrite tables for version
     testrun   =  i_test                  "testrun
     p_noval   =  i_vald                  "skip validations
    IMPORTING
      is_converted = converted             "conversion success or not
      gt_log       = cnflct_log            "log table for conflicts
  ).
  IF converted = ''.
    is_converted = ''.
  ENDIF.


  LOOP AT cnflct_log INTO ls_log.  " Appending conflict logs to out_log
    APPEND ls_log TO out_log.
    CLEAR ls_log.
  ENDLOOP.


*Method to convert search_rule_text to /PSYNG/TEXTS
  CLEAR converted.
  me->conv_search_rule_text(
    EXPORTING
    conv_data = conv_data-search_rule_text"relevant data from structure
    full_data = conv_data                 "whole structure data
    p_vrsn    = i_vrsio                   "sod version
    ovrwrt    =  i_overwrite              "overwrite tables for version
    testrun   =  i_test                   "testrun
    p_noval   =  i_vald                   "skip validations
    IMPORTING
      is_converted = converted             "conversion success or not
  ).
  IF converted = ''.
    is_converted = ''.
  ENDIF.

*Method to convert problem_text to /PSYNG/TEXTS
  CLEAR converted.
  me->conv_problem_text(
    EXPORTING
      conv_data = conv_data-problem_text"relevant data from structure
      full_data = conv_data             "whole structure data
      p_vrsn    = i_vrsio               "sod version
      ovrwrt    =  i_overwrite          "overwrite tables for version
      testrun   =  i_test               "testrun
      p_noval   =  i_vald               "skip validations
    IMPORTING
      is_converted = converted          "conversion success or not
  ).
  IF converted = ''.
    is_converted = ''.
  ENDIF.


  SORT: out_log.         " SORT final log table
  DELETE ADJACENT DUPLICATES FROM out_log COMPARING ALL FIELDS.
  DELETE out_log WHERE object EQ space.



ENDMETHOD.


  METHOD delete_data.


  CHECK testrun <> 'X'. "no deletion in testrun
    IF if_lock = 'X'.
      MESSAGE e113(/psyng/sw) WITH
      'Deleting data is not allowed;records are locked.'(l07).
    ENDIF.
    IF  i_object = 'CONFLICT'.
      DELETE FROM /psyng/confdet   WHERE vrsio = p_vrsn.
      DELETE FROM /psyng/conflict  WHERE vrsio = p_vrsn.
      DELETE FROM /psyng/conowner  WHERE vrsio = p_vrsn.
      DELETE FROM /psyng/texts     WHERE vrsio = p_vrsn AND
                                         object = 'C'.
*-- Delete Conflict Mitigations
      DELETE FROM /psyng/conpmit WHERE vrsio = p_vrsn.
      DELETE FROM /psyng/sw_syscon  WHERE vrsio = p_vrsn.
    ENDIF.
    IF  i_object = 'FUNCTION'.
      DELETE FROM /psyng/functtran WHERE vrsio = p_vrsn.
      DELETE FROM /psyng/function  WHERE vrsio = p_vrsn.
      DELETE FROM /psyng/faobj2    WHERE vrsio = p_vrsn.
      DELETE FROM /psyng/texts     WHERE vrsio = p_vrsn AND
                                    object = 'F'.
      DELETE FROM /psyng/sw_sysfun  WHERE vrsio = p_vrsn.

    ENDIF.
    IF  i_object = 'SWAUD'.
      DELETE FROM /psyng/swaudhdr  WHERE vrsio = p_vrsn.
      DELETE FROM /psyng/swaudc2   WHERE vrsio = p_vrsn.
      DELETE FROM /psyng/texts     WHERE vrsio = p_vrsn AND
                                    object = 'T'.

      DELETE FROM /psyng/sw_sysca WHERE vrsio = p_vrsn.
    ENDIF.

    IF  i_object = 'CRITCODES'.
      DELETE FROM /psyng/critcodes WHERE vrsio = p_vrsn.
    ENDIF.

    IF i_object = 'CRITFLTR'.
      DELETE FROM /psyng/sw_systcd  WHERE vrsio = p_vrsn.
    ENDIF.

    IF i_object = 'CRITTEXT'.
      DELETE FROM /psyng/texts   WHERE vrsio = p_vrsn AND
                                    object = 'X'.
    ENDIF.

    IF i_object = 'CRIROLES'.
      DELETE FROM /psyng/criroles WHERE vrsio = p_vrsn.
    ENDIF.

    IF i_object = 'CRIRTEXT'.
      DELETE FROM /psyng/texts   WHERE vrsio = p_vrsn AND
                                    object = 'Q'.

    ENDIF.

    IF i_object = 'CRIPROF'.
      DELETE FROM /psyng/criprof WHERE vrsio = p_vrsn.
    ENDIF.

    IF i_object = 'CRIPTEXT'.
      DELETE FROM /psyng/texts   WHERE vrsio = p_vrsn AND
                                     object = 'P'.
    ENDIF.
    DELETE FROM /psyng/swsodorgo  WHERE vrsio = p_vrsn.

    COMMIT WORK.
  ENDMETHOD.


  METHOD log.
    DATA gt_log TYPE /psyng/sw_gt_log.

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

    APPEND gt_log TO e_gt_log.
  ENDMETHOD.


  method OUTPUT_LOG.
    type-POOLs SLIS.
    DATA:   ls_variant     TYPE disvariant,      " ALV variant
        alv_layout     TYPE slis_layout_alv, " ALV layout
        l_program      LIKE sy-repid.

DATA: lt_fieldcatalog TYPE TABLE OF slis_fieldcat_alv, " itab fieldcat
ls_fieldcatalog TYPE slis_fieldcat_alv.                " wa fieldcat

DEFINE field_cat.   " fieldcat MACROS

 ls_fieldcatalog-col_pos = &1.               " column position
 ls_fieldcatalog-fieldname = &2.
 ls_fieldcatalog-seltext_m   = &3.
  ls_fieldcatalog-seltext_s   = &3.
   ls_fieldcatalog-seltext_l   = &3.
* ls_fieldcatalog-coltext   = &3.
  ls_fieldcatalog-intlen    = &4.
  ls_fieldcatalog-outputlen = &4.
  ls_fieldcatalog-fix_column = 'X'.
  ls_fieldcatalog-lzero = 'X'.
append ls_fieldcatalog to lt_fieldcatalog.

clear ls_fieldcatalog.

END-OF-DEFINITION.

  alv_layout-zebra = 'X'.             " Zebra Layout of ALV
  alv_layout-colwidth_optimize = 'X'. " Column width optimize
  l_program = sy-repid.               " self report as callback prgrm

*Field Catalog creating by using 'field_cat' macros defined earlier
  field_cat: '1' 'FILENAME' 'Target Table'(a01) 40,
              '2' 'TYPE'    'Type'(a02) 5,
              '3' 'OBJECT'  'Object'(a03) 30,
              '4' 'OBJCT_ID' 'Object ID'(a04) 20,
              '5' 'FIELDNAME' 'Fieldname'(a05) 20,
              '6' 'VALUE'     'Value'(a06) 30,
             '7' 'MESSAGE'    'Message'(a07) 80.


*===========================

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name     = l_program
      i_internal_tabname = 'GT_LOG'
      i_inclname         = l_program
    CHANGING
      ct_fieldcat        = lt_fieldcatalog
"(++)BOC UMITTAL SE VF scan-25/11/2024
    EXCEPTIONS
      INCONSISTENT_INTERFACE = 1
      PROGRAM_ERROR          = 2
      OTHERS                 = 3 .
    IF sy-subrc <> 0.
         MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
     ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.        .            "i_fieldcat_alv.
*  PERFORM build_sort_table.
*  PERFORM adjust_columns.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_top_of_page = 'ALV_HEADER'
      i_callback_program     = l_program
      is_layout              = alv_layout
      it_fieldcat            = lt_fieldcatalog         "i_fieldcat_alv
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
"(++)EOC UMITTAL SE VF scan-25/11/2024.        .
  endmethod.


  METHOD read_data.

    SELECT *
    FROM /psyng/sw_buspro
    INTO TABLE me->data-bus_process_header.

    SELECT *
    FROM /psyng/sw_busprt
    INTO TABLE me->data-bus_process_text.

    SELECT *
    FROM /psyng/sw_rule_h
    INTO TABLE me->data-matrix_header.

    SELECT *
    FROM /psyng/sw_rule_t
    INTO TABLE me->data-matrix_text.

    SELECT *
    FROM /psyng/sw_rule_d
    INTO TABLE me->data-matrix_details.

    SELECT *
    FROM /psyng/sw_conf_h
    INTO TABLE me->data-conflict_header.

    SELECT *
    FROM /psyng/sw_conf_t
    INTO TABLE me->data-conflict_text.

    SELECT *
    FROM /psyng/sw_conf_d
    INTO TABLE me->data-conflict_details.

    SELECT *
    FROM /psyng/sw_func_h
    INTO TABLE me->data-function_header.

    SELECT *
    FROM /psyng/sw_func_t
    INTO TABLE me->data-function_text.

    SELECT *
    FROM /psyng/sw_func_d
    INTO TABLE me->data-function_details.

    SELECT *
    FROM /psyng/sw_auth_h
    INTO TABLE me->data-search_rule_header.

    SELECT *
    FROM /psyng/sw_auth_t
    INTO TABLE me->data-search_rule_text.

    SELECT *
    FROM /psyng/sw_auth_d
    INTO TABLE me->data-search_rule_details.

    SELECT *
    FROM /psyng/sw_risk_h
    INTO TABLE me->data-problem_header.

    SELECT *
    FROM /psyng/sw_risk_t
    INTO TABLE me->data-problem_text.
  ENDMETHOD.


  method STRING_TO_SHORT_LINES.

  CONSTANTS: max_str_len      TYPE I VALUE 132.
  CONSTANTS: string_space(1)  TYPE C VALUE ' '.

  DATA: first_split   TYPE /psyng/cl_sw_ruleset_convsn=>str_tab.
  DATA: curr_str_len  TYPE I.
  DATA: curr_str_char TYPE C.
  DATA: curr_str      TYPE string.

  FIELD-SYMBOLS: <curr_str> TYPE string.

  SPLIT str AT cl_abap_char_utilities=>newline INTO TABLE first_split.

  LOOP AT first_split ASSIGNING <curr_str>.
    curr_str = <curr_str>.
    WHILE STRLEN( curr_str ) > max_str_len.
      curr_str_len = max_str_len.
      curr_str_char = curr_str+curr_str_len(1).
      WHILE curr_str_char <> string_space AND curr_str_len > 0.
        curr_str_len = curr_str_len - 1.
        curr_str_char = curr_str+curr_str_len(1).
      ENDWHILE.
      APPEND curr_str+0(curr_str_len) TO str_tab.
      curr_str_len = curr_str_len + 1.
      curr_str = curr_str+curr_str_len.
    ENDWHILE.
    APPEND curr_str TO str_tab.
  ENDLOOP.

  endmethod.


  METHOD string_to_tline.

    DATA: str_tab TYPE STANDARD TABLE OF string.

    FIELD-SYMBOLS: <tline> TYPE tline.

    me->string_to_short_lines(
      EXPORTING
        str = in
      IMPORTING
        str_tab = str_tab
    ).

    CALL FUNCTION 'CONVERT_STREAM_TO_ITF_TEXT'
      EXPORTING
        stream_lines = str_tab
        lf           = 'X'
        language     = lang
      TABLES
        itf_text     = out.

    LOOP AT out ASSIGNING <tline>.
*      IF <tline> CP '<(>&<)>'.
*BOC UMITTAL SE VF scan changes-25/11/2024
      DO.
        REPLACE ALL OCCURRENCES OF '<(>&<)>' IN <tline> WITH '&'.
        IF sy-subrc NE 0. EXIT. ENDIF.
      ENDDO.
*        REPLACE ALL OCCURRENCES OF '<(>&<)>' IN <tline> WITH '&'.
*      ENDIF.

*      IF <tline> CP '<(><<)>'.
       DO.
        REPLACE ALL OCCURRENCES OF '<(><<)>' IN <tline> WITH '<'.
        IF sy-subrc NE 0. EXIT. ENDIF.
      ENDDO.
*        REPLACE ALL OCCURRENCES OF '<(><<)>' IN <tline> WITH '<'.
*      ENDIF.

*      IF <tline> CP ',<(>,<)>'.
       DO.
        REPLACE ALL OCCURRENCES OF ',<(>,<)>' IN <tline> WITH ',,'.
        IF sy-subrc NE 0. EXIT. ENDIF.
       ENDDO.
*        REPLACE ALL OCCURRENCES OF ',<(>,<)>' IN <tline> WITH ',,'.
*      ENDIF.
*EOC UMITTAL SE VF scan changes-25/11/2024
    ENDLOOP.
  ENDMETHOD.


  METHOD validation.

    DATA: itstc    TYPE SORTED TABLE OF tstc WITH UNIQUE KEY tcode,
          ls_itstc TYPE tstc.
*        WITH HEADER LINE.

    DATA : iagr_define    TYPE HASHED TABLE OF agr_define WITH UNIQUE KEY agr_name,
           ls_iagr_define TYPE  agr_define.
*        WITH HEADER LINE.

    DATA : iprof    TYPE SORTED TABLE OF usr10 WITH NON-UNIQUE KEY profn,
           ls_iprof TYPE usr10.
*         WITH HEADER LINE.


    TYPES: BEGIN OF ty_busarea ,
             busarea TYPE /psyng/busarea-busarea,
           END OF ty_busarea.

    DATA: lt_busarea TYPE TABLE OF ty_busarea.

    TYPES: BEGIN OF ty_dd07l,
             domvalue_l TYPE dd07l-domvalue_l,
           END OF ty_dd07l.

    DATA: lt_dd07l TYPE TABLE OF ty_dd07l.

    TYPES: BEGIN OF ty_usr02,
             bname TYPE usr02-bname,
           END OF ty_usr02.

    DATA: lt_usr02 TYPE TABLE OF ty_usr02.

    TYPES: BEGIN OF ty_funid,
             function    TYPE /psyng/function-function,
             description TYPE /psyng/function-description,
           END OF ty_funid.

    DATA: lt_funid TYPE TABLE OF ty_funid.

    TYPES: BEGIN OF ty_functtran,
             functionid TYPE /psyng/function-function,
             tcode      TYPE tstc-tcode,
           END OF ty_functtran.

    DATA: lt_functtran TYPE TABLE OF ty_functtran.

    DATA : lt_risk TYPE TABLE OF /psyng/sw_risk,
           ls_risk TYPE TABLE OF /psyng/sw_risk.
*        WITH HEADER LINE.

    TYPES: BEGIN OF ty_tobj,
             objct TYPE tobj-objct,
             fiel1 TYPE tobj-fiel1,
             fiel2 TYPE tobj-fiel2,
             fiel3 TYPE tobj-fiel3,
             fiel4 TYPE tobj-fiel4,
             fiel5 TYPE tobj-fiel5,
             fiel6 TYPE tobj-fiel6,
             fiel7 TYPE tobj-fiel7,
             fiel8 TYPE tobj-fiel8,
             fiel9 TYPE tobj-fiel9,
             fiel0 TYPE tobj-fiel0,
           END OF ty_tobj.

    DATA: lt_tobj TYPE STANDARD TABLE OF ty_tobj.
    DATA: ls_tobj TYPE ty_tobj.

    TYPES: BEGIN OF ty_mchdr,
             contid TYPE /psyng/mchdr-contid,
           END OF ty_mchdr.

    DATA: lt_mchdr TYPE TABLE OF ty_mchdr.

    TYPES: BEGIN OF ty_conid,
             conid       TYPE /psyng/conflict-conid,
             description TYPE /psyng/conflict-description,
           END OF ty_conid.

    DATA: lt_conid TYPE TABLE OF ty_conid.


    TYPES: BEGIN OF ty_swaudhdr,
             swaudid     TYPE /psyng/swaudhdr-swaudid,
             description TYPE /psyng/swaudhdr-description,
             tcode       TYPE /psyng/swaudhdr-tcode,
           END OF ty_swaudhdr.

    DATA: lt_swaudhdr TYPE TABLE OF ty_swaudhdr.

    TYPES: BEGIN OF ty_ct,
             tcode TYPE  /psyng/critcodes-tcode,
             vrsio TYPE  /psyng/critcodes-vrsio,
           END OF ty_ct.

    DATA: lt_ct TYPE TABLE OF ty_ct.

    TYPES: BEGIN OF ty_cr,
             agr_name TYPE  /psyng/criroles-agr_name,
             vrsio    TYPE  /psyng/criroles-vrsio,
           END OF ty_cr.

    DATA: lt_cr TYPE TABLE OF ty_cr.

    TYPES: BEGIN OF ty_cp,
             profile TYPE  /psyng/criprof-profile,
             vrsio   TYPE  /psyng/criroles-vrsio,
           END OF ty_cp.

    DATA: lt_cp TYPE TABLE OF ty_cp.


    DATA: l_flg_no_dat,
          l_flg_del_dat,
          l_indx        LIKE sy-tabix,
          l_msg         TYPE string.

    DATA: r_field TYPE RANGE OF /psyng/swsodorgo-field,
          r_type  TYPE RANGE OF /psyng/swsodorgo-type.

    DATA: lt_gt_log TYPE TABLE OF /PSYNG/SW_GT_LOG,
          ls_gt_log TYPE /PSYNG/SW_GT_LOG,
          gt_log    TYPE STANDARD TABLE OF /PSYNG/SW_GT_LOG.

* Get master data for validations
    SELECT tcode FROM tstc INTO CORRESPONDING FIELDS OF TABLE itstc.

    SELECT agr_name FROM agr_define
                          INTO CORRESPONDING FIELDS OF TABLE iagr_define.

    SELECT profn FROM usr10
                         INTO CORRESPONDING FIELDS OF TABLE iprof.


    SELECT tcode vrsio FROM /psyng/critcodes INTO TABLE lt_ct
                WHERE vrsio = i_vrsn.

    SELECT agr_name vrsio FROM /psyng/criroles INTO TABLE lt_cr
                WHERE vrsio = i_vrsn.

    SELECT profile vrsio FROM /psyng/criprof INTO TABLE lt_cp
                WHERE vrsio = i_vrsn.


    SELECT bname FROM usr02 INTO TABLE lt_usr02.

    SELECT busarea FROM /psyng/busarea INTO TABLE lt_busarea.

    SELECT risk FROM /psyng/sw_risk INTO CORRESPONDING FIELDS OF
    TABLE lt_risk.

    SELECT function description FROM /psyng/function INTO TABLE lt_funid
           WHERE vrsio = i_vrsn.

    SELECT domvalue_l FROM dd07l INTO TABLE lt_dd07l
    WHERE domname = '/PSYNG/IMPORTANCE'
    AND  as4local = 'A'."#EC SAST_CI_GEN_CHECK

    SELECT objct fiel1 fiel2 fiel3 fiel4 fiel5 fiel6 fiel7 fiel8
           fiel9 fiel0
      FROM tobj
      INTO TABLE lt_tobj.

    SELECT contid FROM /psyng/mchdr INTO TABLE lt_mchdr.

    SELECT conid description FROM /psyng/conflict INTO TABLE lt_conid
           WHERE vrsio = i_vrsn.

    SELECT swaudid description tcode FROM /psyng/swaudhdr INTO TABLE
   lt_swaudhdr
                 WHERE vrsio = i_vrsn.

    SELECT functionid tcode FROM /psyng/functtran INTO TABLE lt_functtran
  WHERE vrsio = i_vrsn.

    SORT: lt_usr02    BY bname,
          lt_funid    BY function,
          lt_dd07l    BY domvalue_l,
          lt_tobj     BY objct,
          lt_mchdr    BY contid,
          lt_conid    BY conid,
          lt_swaudhdr BY swaudid,
*        itstc       BY tcode,
          lt_risk     BY risk,
          lt_busarea  BY busarea,
          lt_ct       BY tcode vrsio,
          lt_cr       BY agr_name vrsio,
          lt_cp       BY profile vrsio,
          iagr_define BY agr_name,
          isysfun     BY function,
          isyscon     BY conid,
          isysca      BY swaudid,
          isystcd     BY tcode,
          lt_functtran BY functionid tcode.

* Check all necessary records

    DATA: ls_func TYPE /psyng/function.
    DATA lv_objctid TYPE t100-text.
    DATA lv_value TYPE t100-text.
    DATA: lv_message TYPE t100-text.
*  IF f_funh = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT ifunction INTO ls_func.
      CLEAR: l_flg_del_dat.
      l_indx = sy-tabix.
      IF NOT ls_func-owner IS INITIAL .
        READ TABLE lt_usr02 WITH KEY bname = ls_func-owner BINARY SEARCH
                                                   TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.

          lv_objctid = ls_func-function.
          lv_value = ls_func-owner.

          me->log(
          EXPORTING  i_file = 'Function Header- /psyng/function'
                     i_type = 'E'
                     i_object = 'Function ID :'(129)
                     i_object_id = lv_objctid
                     i_field = 'Owner :'(120)
                     i_value = lv_value
                     i_message = 'Not Found'(121)
          IMPORTING  e_gt_log  = lt_gt_log
                     ).
          LOOP AT lt_gt_log INTO ls_gt_log.
            APPEND ls_gt_log TO gt_log.
            CLEAR: ls_gt_log.
          ENDLOOP.
          CLEAR: lt_gt_log.

          CLEAR: lv_objctid, lv_value.

        ENDIF.
      ENDIF.
      IF NOT ls_func-busarea IS INITIAL.
        READ TABLE lt_busarea WITH KEY busarea = ls_func-busarea
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.

          lv_objctid = ls_func-function.
          lv_value = ls_func-busarea.

          me->log(
          EXPORTING  i_file = 'Function Header- /psyng/function'
                     i_type = 'E'
                     i_object = 'Function ID :'(129)
                     i_object_id = lv_objctid
                     i_field = ' Application Area :'(122)
                     i_value = lv_value
                     i_message = 'Not Found'(121)
          IMPORTING  e_gt_log  = lt_gt_log
                     ).
          LOOP AT lt_gt_log INTO ls_gt_log.
            APPEND ls_gt_log TO gt_log.
            CLEAR: ls_gt_log.
          ENDLOOP.
          CLEAR: lt_gt_log.

          CLEAR: lv_objctid, lv_value.

        ENDIF.
      ELSE.
        l_flg_no_dat = 'X'.
        CONCATENATE 'Not Found'(121) '- will still be inserted'(147)
        INTO l_msg SEPARATED BY space.

        lv_objctid = ls_func-function.
        lv_value = ls_func-busarea.
        lv_message = l_msg.

        me->log(
        EXPORTING  i_file = 'Function Header- /psyng/function'
                   i_type = 'W'
                   i_object = 'Function ID :'(129)
                   i_object_id = lv_objctid
                   i_field = ' Application Area :'(122)
                   i_value = lv_value
                   i_message = lv_message
        IMPORTING  e_gt_log  = lt_gt_log
                   ).
        LOOP AT lt_gt_log INTO ls_gt_log.
          APPEND ls_gt_log TO gt_log.
          CLEAR: ls_gt_log.
        ENDLOOP.
        CLEAR: lt_gt_log.

        CLEAR: lv_objctid, lv_value,lv_message.

      ENDIF.
      IF l_flg_del_dat = 'X'.
        DELETE ifunction INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT ifunction[] IS INITIAL.

      me->log(
      EXPORTING  i_file = 'Function Header- /psyng/function'
                 i_type = 'S'
                 i_object = 'Function Header'(119)
                 i_object_id = ''
                 i_field = ''
                 i_value = ''
                 i_message = 'No errors found in file'(123)
      IMPORTING  e_gt_log  = lt_gt_log
                 ).
      LOOP AT lt_gt_log INTO ls_gt_log.
        APPEND ls_gt_log TO gt_log.
        CLEAR: ls_gt_log.
      ENDLOOP.
      CLEAR: lt_gt_log.

    ENDIF.

***  for Function details **********

    DATA: ls_functtrans TYPE /psyng/functtran.

*  IF f_fund = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT ifuncttrans INTO ls_functtrans.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE lt_funid WITH KEY function = ls_functtrans-functionid
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        READ TABLE ifunction WITH KEY function = ls_functtrans-functionid
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.

          lv_objctid = ls_functtrans-functionid.

          me->log(
          EXPORTING  i_file = 'Function Header- /psyng/functtran'
                     i_type = 'E'
                     i_object = 'SOD Function ID :'(125)
                     i_object_id = lv_objctid
                     i_field = ''
                     i_value = ''
                     i_message = 'Not Found'(121)
          IMPORTING  e_gt_log  = lt_gt_log
                     ).
          LOOP AT lt_gt_log INTO ls_gt_log.
            APPEND ls_gt_log TO gt_log.
            CLEAR: ls_gt_log.
          ENDLOOP.
          CLEAR: lt_gt_log.

          CLEAR: lv_objctid, lv_value,lv_message.

        ENDIF.
      ENDIF.
      READ TABLE itstc WITH KEY tcode = ls_functtrans-tcode
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0 AND NOT ls_functtrans-tcode CP '/PSYNG/-*'.
        l_flg_no_dat = 'X'.
        CONCATENATE
        'Not Found'(121)
        '- will still be inserted'(147)
        INTO l_msg SEPARATED BY space.

        lv_objctid = ls_functtrans-functionid.
        lv_value = ls_functtrans-tcode.
        lv_message = l_msg.

        me->log(
        EXPORTING  i_file = 'Function Header- /psyng/functtran'
                   i_type = 'W'
                   i_object = 'SOD Function ID :'(125)
                   i_object_id = lv_objctid
                   i_field = 'Tcode :'(126)
                   i_value = lv_value
                   i_message = lv_message
        IMPORTING  e_gt_log  = lt_gt_log
                   ).
        LOOP AT lt_gt_log INTO ls_gt_log.
          APPEND ls_gt_log TO gt_log.
          CLEAR: ls_gt_log.
        ENDLOOP.
        CLEAR: lt_gt_log.

        CLEAR: lv_objctid, lv_value,lv_message.

      ENDIF.
      IF l_flg_del_dat = 'X'.
        DELETE ifuncttrans INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' '  AND NOT ifuncttrans[] IS INITIAL.

      me->log(
      EXPORTING  i_file = 'Function Header- /psyng/functtran'
                 i_type = 'S'
                 i_object = 'Function details'(124)
                 i_object_id = ''
                 i_field = ''
                 i_value = ''
                 i_message = 'No errors found in file'(123)
      IMPORTING  e_gt_log  = lt_gt_log
                 ).
      LOOP AT lt_gt_log INTO ls_gt_log.
        APPEND ls_gt_log TO gt_log.
        CLEAR: ls_gt_log.
      ENDLOOP.
      CLEAR: lt_gt_log.

    ENDIF.
*  ENDIF.
***  for Function texts  **********
    DATA: ls_texts TYPE /psyng/texts.
*  IF f_funt = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT ftexts INTO ls_texts.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE lt_funid WITH KEY function = ls_texts-textname
      TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        READ TABLE ifunction WITH KEY function = ls_texts-textname
        TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.

          lv_objctid =  ls_texts-textname.
          lv_value = ls_texts-text.

          me->log(
          EXPORTING  i_file = 'Function Header- /psyng/texts'
                     i_type = 'E'
                     i_object = 'SOD Function ID :'(125)
                     i_object_id = lv_objctid
                     i_field = 'Function texts:'(127)
                     i_value = lv_value
                     i_message = 'Not Found'(121)
          IMPORTING  e_gt_log  = lt_gt_log
                     ).
          LOOP AT lt_gt_log INTO ls_gt_log.
            APPEND ls_gt_log TO gt_log.
            CLEAR: ls_gt_log.
          ENDLOOP.
          CLEAR: lt_gt_log.

          CLEAR: lv_objctid, lv_value,lv_message.

        ENDIF.
      ENDIF.
      IF l_flg_del_dat = 'X'.
        DELETE ftexts INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT ftexts[] IS INITIAL.

      me->log(
      EXPORTING  i_file = 'Function Header- /psyng/texts'
                 i_type = 'S'
                 i_object = 'Function texts:'(127)
                 i_object_id = ''
                 i_field = ''
                 i_value = ''
                 i_message = 'No errors found in file'(123)
      IMPORTING  e_gt_log  = lt_gt_log
                 ).
      LOOP AT lt_gt_log INTO ls_gt_log.
        APPEND ls_gt_log TO gt_log.
        CLEAR: ls_gt_log.
      ENDLOOP.
      CLEAR: lt_gt_log.

    ENDIF.
*  ENDIF.
************Object details ******************************
    DATA: ls_faobj TYPE /psyng/faobj2.
    DATA: lv_fld   TYPE dd03d-fieldname.
    SORT ifuncttrans BY functionid tcode.
*  IF f_objd = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT ifaobj INTO ls_faobj.
      l_indx = sy-tabix.

      IF l_indx >= 5.
        EXIT.
      ENDIF.

      CLEAR: l_flg_del_dat.

*-- Check for Tcode function relation
      READ TABLE lt_functtran WITH KEY functionid = ls_faobj-funid
            tcode = ls_faobj-tcode BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        READ TABLE ifuncttrans WITH KEY functionid = ls_faobj-funid
        tcode = ls_faobj-tcode BINARY SEARCH TRANSPORTING NO FIELDS..
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.

          lv_objctid =  ls_faobj-funid.
          lv_fld = ls_faobj-tcode.

          me->log(
          EXPORTING  i_file = 'Function Header- /psyng/faobj2'
                     i_type = 'E'
                     i_object = 'Function ID :'(129)
                     i_object_id = lv_objctid
                     i_field = lv_fld
                     i_value = ''
                     i_message = 'Tcode is not linked to the function'(205)
          IMPORTING  e_gt_log  = lt_gt_log
                     ).
          LOOP AT lt_gt_log INTO ls_gt_log.
            APPEND ls_gt_log TO gt_log.
            CLEAR: ls_gt_log.
          ENDLOOP.
          CLEAR: lt_gt_log.

          CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

        ENDIF.
      ENDIF.
*-- End checking

      READ TABLE lt_funid WITH KEY function = ls_faobj-funid
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        READ TABLE ifunction WITH KEY function = ls_faobj-funid
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.

          lv_objctid =  ls_faobj-funid.

          me->log(
          EXPORTING  i_file = 'Function Header- /psyng/faobj2'
                     i_type = 'E'
                     i_object = 'Function ID :'(129)
                     i_object_id = lv_objctid
                     i_field = ''
                     i_value = ''
                     i_message = 'Not Found'(121)
          IMPORTING  e_gt_log  = lt_gt_log
                     ).
          LOOP AT lt_gt_log INTO ls_gt_log.
            APPEND ls_gt_log TO gt_log.
            CLEAR: ls_gt_log.
          ENDLOOP.
          CLEAR: lt_gt_log.

          CLEAR: lv_objctid,lv_fld,lv_value,lv_message.


        ENDIF.
      ENDIF.
      READ TABLE itstc WITH KEY tcode = ls_faobj-tcode
                BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0 AND NOT ls_faobj-tcode CP '/PSYNG/-*'.
        l_flg_no_dat = 'X'.
        CONCATENATE 'Not Found'(121) '- will still be inserted'(147)
        INTO l_msg SEPARATED BY space.

        lv_objctid =  ls_faobj-funid.
        lv_value = ls_faobj-tcode.
        lv_message = l_msg.

        me->log(
        EXPORTING  i_file = 'Function Header- /psyng/faobj2'
                   i_type = 'W'
                   i_object = 'Function ID :'(129)
                   i_object_id = lv_objctid
                   i_field = 'Tcode :'(126)
                   i_value = lv_value
                   i_message = lv_message
        IMPORTING  e_gt_log  = lt_gt_log
                   ).
        LOOP AT lt_gt_log INTO ls_gt_log.
          APPEND ls_gt_log TO gt_log.
          CLEAR: ls_gt_log.
        ENDLOOP.
        CLEAR: lt_gt_log.

        CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

      ENDIF.
      READ TABLE lt_tobj WITH KEY objct = ls_faobj-object
                 BINARY SEARCH TRANSPORTING NO FIELDS.  "need to have all fields
      IF sy-subrc <> 0.
        l_flg_del_dat = ' '.
        l_flg_no_dat  = 'X'.
        CONCATENATE 'Not Found'(121) '- will still be inserted'(147)
        INTO l_msg SEPARATED BY space.

        lv_objctid =  ls_faobj-funid.
        lv_value = ls_faobj-object.
        lv_message = l_msg.

        me->log(
        EXPORTING  i_file = 'Function Header- /psyng/faobj2'
                   i_type = 'W'
                   i_object = 'Function ID :'(129)
                   i_object_id = lv_objctid
                   i_field = ' Object :'(129)
                   i_value = lv_value
                   i_message = lv_message
        IMPORTING  e_gt_log  = lt_gt_log
                   ).
        LOOP AT lt_gt_log INTO ls_gt_log.
          APPEND ls_gt_log TO gt_log.
          CLEAR: ls_gt_log.
        ENDLOOP.
        CLEAR: lt_gt_log.

        CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

      ELSE.
        LOOP AT lt_tobj INTO ls_tobj.
          CASE ls_faobj-field.
            WHEN ls_tobj-fiel1 OR ls_tobj-fiel2 OR ls_tobj-fiel3
              OR ls_tobj-fiel4 OR ls_tobj-fiel5 OR ls_tobj-fiel6
              OR ls_tobj-fiel7 OR ls_tobj-fiel8 OR ls_tobj-fiel9
              OR ls_tobj-fiel0.

            WHEN OTHERS.
              l_flg_del_dat = 'X'.
              l_flg_no_dat = 'X'.

              lv_objctid =  ls_faobj-funid.
              lv_value = ls_faobj-field.

              me->log(
              EXPORTING  i_file = 'Function Header- /psyng/faobj2'
                         i_type = 'W'
                         i_object = 'Function ID :'(129)
                         i_object_id = lv_objctid
                         i_field = 'Field :'(130)
                         i_value = lv_value
                         i_message = 'Not Found'(121)
              IMPORTING  e_gt_log  = lt_gt_log
                         ).
              LOOP AT lt_gt_log INTO ls_gt_log.
                APPEND ls_gt_log TO gt_log.
                CLEAR: ls_gt_log.
              ENDLOOP.
              CLEAR: lt_gt_log.

              CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

          ENDCASE.
        ENDLOOP.
      ENDIF.
      IF NOT ( ls_faobj-obj_or  = ' '  OR
               ls_faobj-obj_or  = 'OR' OR
               ls_faobj-obj_or  = 'AND' ).
        l_flg_del_dat = 'X'.
        l_flg_no_dat = 'X'.

        lv_objctid =  ls_faobj-funid.
        lv_value   = ls_faobj-obj_or.

        me->log(
        EXPORTING  i_file = 'Function Header- /psyng/faobj2'
                   i_type = 'E'
                   i_object = 'Function ID :'(129)
                   i_object_id = lv_objctid
                   i_field = 'OBJ_OR:'(131)
                   i_value = lv_value
                   i_message = 'Not Found'(121)
        IMPORTING  e_gt_log  = lt_gt_log
                   ).
        LOOP AT lt_gt_log INTO ls_gt_log.
          APPEND ls_gt_log TO gt_log.
          CLEAR: ls_gt_log.
        ENDLOOP.
        CLEAR: lt_gt_log.

        CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

      ENDIF.
*--Don't allow 000 or blanks in valueset,
* those are not displayed in maintenance screen
      IF ls_faobj-valueset = '000' OR ls_faobj-valueset = ''.
        l_flg_del_dat = 'X'.
        l_flg_no_dat = 'X'.

        lv_objctid =  ls_faobj-funid.
        lv_value = ls_faobj-valueset.

        me->log(
        EXPORTING  i_file = 'Function Header- /psyng/faobj2'
                   i_type = 'E'
                   i_object = 'Function ID :'(129)
                   i_object_id = lv_objctid
                   i_field = 'VALUESET:'(162)
                   i_value = lv_value
                   i_message = 'Cannot be blank or 000'(163)
        IMPORTING  e_gt_log  = lt_gt_log
                   ).
        LOOP AT lt_gt_log INTO ls_gt_log.
          APPEND ls_gt_log TO gt_log.
          CLEAR: ls_gt_log.
        ENDLOOP.
        CLEAR: lt_gt_log.

        CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

      ENDIF.

*-- Change activity less then 10 to double digit
      IF ls_faobj-field = 'ACTVT'.
        CONDENSE : ls_faobj-val_from, ls_faobj-val_to.
        IF ls_faobj-val_from CO '0123456789 '.
          IF ls_faobj-val_from BETWEEN 0 AND 9
          AND ls_faobj-val_from(1) <> 0 .
            CONCATENATE '0' ls_faobj-val_from INTO ls_faobj-val_from.
          ENDIF.
        ENDIF.
        IF ls_faobj-val_to CO '0123456789 '.
          IF ls_faobj-val_to BETWEEN 0 AND 9
          AND ls_faobj-val_to(1) <> 0 .
            CONCATENATE '0' ls_faobj-val_to INTO ls_faobj-val_to.
          ENDIF.
        ENDIF.
        MODIFY ifaobj FROM ls_faobj TRANSPORTING val_from val_to.
      ENDIF.


      IF l_flg_del_dat = 'X'.
        DELETE ifaobj INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' '  AND NOT ifaobj[] IS INITIAL.
      me->log(
      EXPORTING  i_file = 'Function Header- /psyng/faobj2'
                 i_type = 'S'
                 i_object = 'Object details'(128)
                 i_object_id = ''
                 i_field = ''
                 i_value = ''
                 i_message = 'No errors found in file'(123)
      IMPORTING  e_gt_log  = lt_gt_log
                 ).
      LOOP AT lt_gt_log INTO ls_gt_log.
        APPEND ls_gt_log TO gt_log.
        CLEAR: ls_gt_log.
      ENDLOOP.
      CLEAR: lt_gt_log.

      CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

    ENDIF.
*  ENDIF.


***********Conflict header ***************************
    DATA: ls_conflict TYPE /psyng/conflict.
*  IF f_conh = 'X'.
    CLEAR: l_flg_no_dat.


    LOOP AT iconflict INTO ls_conflict.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      IF NOT ls_conflict-owner IS INITIAL .
        READ TABLE lt_usr02 WITH KEY bname = ls_conflict-owner BINARY SEARCH
                                                   TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          lv_objctid =  ls_conflict-conid.
          lv_value = ls_conflict-owner.

          me->log(
          EXPORTING  i_file = 'Conflict Header- /psyng/conflict'
                     i_type = 'E'
                     i_object = 'Conflict ID :'(137)
                     i_object_id = lv_objctid
                     i_field = 'Owner :'(120)
                     i_value = lv_value
                     i_message = 'Not Found'(121)
          IMPORTING  e_gt_log  = lt_gt_log
                     ).
          LOOP AT lt_gt_log INTO ls_gt_log.
            APPEND ls_gt_log TO gt_log.
            CLEAR: ls_gt_log.
          ENDLOOP.
          CLEAR: lt_gt_log.

          CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

        ENDIF.
      ENDIF.
      DATA l_sense TYPE dd07l.

      IF NOT ls_conflict-imp IS INITIAL.
        READ TABLE lt_dd07l INTO l_sense WITH KEY domvalue_l = ls_conflict-imp
                                                              BINARY SEARCH.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          CONCATENATE 'Not Found'(121) ''
          INTO l_msg SEPARATED BY space.

          lv_objctid =  ls_conflict-conid.
          lv_value = ls_conflict-imp.
          lv_message = l_msg.

          me->log(
          EXPORTING  i_file = 'Conflict Header- /psyng/conflict'
                     i_type = 'E'
                     i_object = 'Conflict ID :'(137)
                     i_object_id = lv_objctid
                     i_field = 'Sensitivity level :'(132)
                     i_value = lv_value
                     i_message = lv_message
          IMPORTING  e_gt_log  = lt_gt_log
                     ).
          LOOP AT lt_gt_log INTO ls_gt_log.
            APPEND ls_gt_log TO gt_log.
            CLEAR: ls_gt_log.
          ENDLOOP.
          CLEAR: lt_gt_log.

          CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

        ENDIF.
      ELSE.
        l_flg_no_dat = 'X'.
        CONCATENATE 'Not Found'(121) '- will still be inserted'(147)
        INTO l_msg SEPARATED BY space.
        lv_objctid =  ls_conflict-conid.
        lv_value = ls_conflict-imp.
        lv_message = l_msg.

        me->log(
        EXPORTING  i_file = 'Conflict Header- /psyng/conflict'
                   i_type = 'W'
                   i_object = 'Conflict ID :'(137)
                   i_object_id = lv_objctid
                   i_field = 'Sensitivity level :'(132)
                   i_value = lv_value
                   i_message = lv_message
        IMPORTING  e_gt_log  = lt_gt_log
                   ).
        LOOP AT lt_gt_log INTO ls_gt_log.
          APPEND ls_gt_log TO gt_log.
          CLEAR: ls_gt_log.
        ENDLOOP.
        CLEAR: lt_gt_log.

        CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

      ENDIF.

      DATA l_busarea LIKE lt_busarea.
      IF NOT ls_conflict-busarea IS INITIAL.
        READ TABLE lt_busarea WITH KEY busarea = ls_conflict-busarea
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.
          CONCATENATE 'Not Found'(121) ''
          INTO l_msg SEPARATED BY space.

          lv_objctid =  ls_conflict-conid.
          lv_value = ls_conflict-busarea.
          lv_message = l_msg.

          me->log(
          EXPORTING  i_file = 'Conflict Header- /psyng/conflict'
                     i_type = 'E'
                     i_object = 'Conflict ID :'(137)
                     i_object_id = lv_objctid
                     i_field = ' Application Area :'(122)
                     i_value = lv_value
                     i_message = lv_message
          IMPORTING  e_gt_log  = lt_gt_log
                     ).
          LOOP AT lt_gt_log INTO ls_gt_log.
            APPEND ls_gt_log TO gt_log.
            CLEAR: ls_gt_log.
          ENDLOOP.
          CLEAR: lt_gt_log.

          CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

        ENDIF.
      ELSE.
        l_flg_no_dat = 'X'.
        CONCATENATE 'Not Found'(121) '- will still be inserted'(147)
        INTO l_msg SEPARATED BY space.

        lv_objctid =  ls_conflict-conid.
        lv_value = ls_conflict-busarea.
        lv_message = l_msg.

        me->log(
        EXPORTING  i_file = 'Conflict Header- /psyng/conflict'
                   i_type = 'W'
                   i_object = 'Conflict ID :'(137)
                   i_object_id = lv_objctid
                   i_field = ' Application Area :'(122)
                   i_value = lv_value
                   i_message = lv_message
        IMPORTING  e_gt_log  = lt_gt_log
                   ).
        LOOP AT lt_gt_log INTO ls_gt_log.
          APPEND ls_gt_log TO gt_log.
          CLEAR: ls_gt_log.
        ENDLOOP.
        CLEAR: lt_gt_log.

        CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

      ENDIF.
      IF NOT ls_conflict-risk IS INITIAL.
        READ TABLE lt_risk WITH KEY risk = ls_conflict-risk
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_no_dat = 'X'.
          CONCATENATE 'Not Found'(121) '- will still be inserted'(147)
          INTO l_msg SEPARATED BY space.
          lv_objctid =  ls_conflict-conid.
*          lv_fld = ls_faobj-tcode.
          lv_value = ls_conflict-risk.
          lv_message = l_msg.

          me->log(
          EXPORTING  i_file = 'Conflict Header- /psyng/conflict'
                     i_type = 'W'
                     i_object = 'Conflict ID :'(137)
                     i_object_id = lv_objctid
                     i_field = ' Risk Scenario :'(160)
                     i_value = lv_value
                     i_message = lv_message
          IMPORTING  e_gt_log  = lt_gt_log
                     ).
          LOOP AT lt_gt_log INTO ls_gt_log.
            APPEND ls_gt_log TO gt_log.
            CLEAR: ls_gt_log.
          ENDLOOP.
          CLEAR: lt_gt_log.

          CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

        ENDIF.
      ENDIF.


      IF NOT ls_conflict-contid IS INITIAL.
        READ TABLE lt_mchdr WITH KEY contid = ls_conflict-contid
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.

          lv_objctid =  ls_conflict-conid.
          lv_value = ls_conflict-contid.

          me->log(
          EXPORTING  i_file = 'Conflict Header- /psyng/conflict'
                     i_type = 'E'
                     i_object = 'Conflict ID :'(137)
                     i_object_id = lv_objctid
                     i_field = 'Mitigating Control ID :'(133)
                     i_value = lv_value
                     i_message = 'Not Found'(121)
          IMPORTING  e_gt_log  = lt_gt_log
                     ).
          LOOP AT lt_gt_log INTO ls_gt_log.
            APPEND ls_gt_log TO gt_log.
            CLEAR: ls_gt_log.
          ENDLOOP.
          CLEAR: lt_gt_log.

          CLEAR: lv_objctid,lv_fld,lv_value,lv_message.
        ENDIF.
      ENDIF.

      IF NOT ( ls_conflict-inactive = ' ' OR ls_conflict-inactive = 'X' ).
        l_flg_del_dat = 'X'.
        l_flg_no_dat = 'X'.

        lv_objctid =  ls_conflict-conid.
        lv_value = ls_conflict-inactive.

        me->log(
        EXPORTING  i_file = 'Conflict Header- /psyng/conflict'
                   i_type = 'E'
                   i_object = 'Conflict ID :'(137)
                   i_object_id = lv_objctid
                   i_field = 'Inactive:'(134)
                   i_value = lv_value
                   i_message = 'Not Found'(121)
        IMPORTING  e_gt_log  = lt_gt_log
                   ).
        LOOP AT lt_gt_log INTO ls_gt_log.
          APPEND ls_gt_log TO gt_log.
          CLEAR: ls_gt_log.
        ENDLOOP.
        CLEAR: lt_gt_log.

        CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

      ENDIF.
      IF l_flg_del_dat = 'X'.
        DELETE iconflict INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' '  AND NOT iconflict[] IS INITIAL.
      me->log(
      EXPORTING  i_file = 'Conflict Header- /psyng/conflict'
                 i_type = 'S'
                 i_object = 'Conflict header'(135)
                 i_object_id = ''
                 i_field = ''
                 i_value = ''
                 i_message = 'No errors found in file'(123)
      IMPORTING  e_gt_log  = lt_gt_log
                 ).
      LOOP AT lt_gt_log INTO ls_gt_log.
        APPEND ls_gt_log TO gt_log.
        CLEAR: ls_gt_log.
      ENDLOOP.
      CLEAR: lt_gt_log.

      CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

    ENDIF.
*  ENDIF.
********************  Conflict details **************************
    DATA: ls_confdet TYPE /psyng/confdet.
*  IF f_cond = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT iconfdet INTO ls_confdet.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE lt_conid WITH KEY conid = ls_confdet-conid
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        READ TABLE iconflict WITH KEY conid = ls_confdet-conid
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.

          lv_objctid =  ls_confdet-conid.

          me->log(
          EXPORTING  i_file = 'Conflict Header- /psyng/confdet'
                     i_type = 'E'
                     i_object = 'Conflict ID :'(137)
                     i_object_id = lv_objctid
                     i_field = ''
                     i_value = ''
                     i_message = 'Not Found'(121)
          IMPORTING  e_gt_log  = lt_gt_log
                     ).
          LOOP AT lt_gt_log INTO ls_gt_log.
            APPEND ls_gt_log TO gt_log.
            CLEAR: ls_gt_log.
          ENDLOOP.
          CLEAR: lt_gt_log.

          CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

        ENDIF.
      ENDIF.
      READ TABLE lt_funid WITH KEY function = ls_confdet-functionid
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        READ TABLE ifunction WITH KEY function = ls_confdet-functionid
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.

          lv_objctid =  ls_confdet-conid.
          lv_value = ls_confdet-functionid.

          me->log(
          EXPORTING  i_file = 'Conflict Header- /psyng/confdet'
                     i_type = 'E'
                     i_object = 'Conflict ID :'(137)
                     i_object_id = lv_objctid
                     i_field = 'Function ID :'(125)
                     i_value = lv_value
                     i_message = 'Not Found'(121)
          IMPORTING  e_gt_log  = lt_gt_log
                     ).
          LOOP AT lt_gt_log INTO ls_gt_log.
            APPEND ls_gt_log TO gt_log.
            CLEAR: ls_gt_log.
          ENDLOOP.
          CLEAR: lt_gt_log.

          CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

        ENDIF.
      ENDIF.
      IF l_flg_del_dat = 'X'.
        DELETE iconfdet INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT iconfdet[] IS INITIAL.
      me->log(
      EXPORTING  i_file = 'Conflict Header- /psyng/confdet'
                 i_type = 'S'
                 i_object = 'Conflict details'(136)
                 i_object_id = ''
                 i_field = ''
                 i_value = ''
                 i_message = 'No errors found in file'(123)
      IMPORTING  e_gt_log  = lt_gt_log
                 ).
      LOOP AT lt_gt_log INTO ls_gt_log.
        APPEND ls_gt_log TO gt_log.
        CLEAR: ls_gt_log.
      ENDLOOP.
      CLEAR: lt_gt_log.

      CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

    ENDIF.
*  ENDIF.

*  ***************Conflict texts *****************************
    DATA: ls_ctexts TYPE /psyng/texts.
*  IF f_cont = 'X'.
    CLEAR: l_flg_no_dat.
    LOOP AT ctexts INTO ls_ctexts.
      l_indx = sy-tabix.
      CLEAR: l_flg_del_dat.
      READ TABLE lt_conid WITH KEY conid = ls_ctexts-textname
      TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        READ TABLE iconflict WITH KEY conid = ls_ctexts-textname
        TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          l_flg_del_dat = 'X'.
          l_flg_no_dat = 'X'.

          lv_objctid =  ls_ctexts-textname.
          lv_value = ls_ctexts-text.

          me->log(
          EXPORTING  i_file = 'Conflict Header- /psyng/texts'
                     i_type = 'E'
                     i_object = 'Conflict ID :'(137)
                     i_object_id = lv_objctid
                     i_field = 'Conflict Text :'(138)
                     i_value = lv_value
                     i_message = 'Not Found'(121)
          IMPORTING  e_gt_log  = lt_gt_log
                     ).
          LOOP AT lt_gt_log INTO ls_gt_log.
            APPEND ls_gt_log TO gt_log.
            CLEAR: ls_gt_log.
          ENDLOOP.
          CLEAR: lt_gt_log.

          CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

        ENDIF.
      ENDIF.
      IF l_flg_del_dat = 'X'.
        DELETE ctexts INDEX l_indx.
      ENDIF.
    ENDLOOP.
    IF l_flg_no_dat = ' ' AND NOT ctexts[] IS INITIAL.

      me->log(
      EXPORTING  i_file = 'Conflict Header- /psyng/texts'
                 i_type = 'S'
                 i_object = 'Conflict texts '(138)
                 i_object_id = ''
                 i_field = ''
                 i_value = ''
                 i_message = 'No errors found in file'(123)
      IMPORTING  e_gt_log  = lt_gt_log
                 ).
      LOOP AT lt_gt_log INTO ls_gt_log.
        APPEND ls_gt_log TO gt_log.
        CLEAR: ls_gt_log.
      ENDLOOP.
      CLEAR: lt_gt_log.

      CLEAR: lv_objctid,lv_fld,lv_value,lv_message.

    ENDIF.
*  ENDIF.

    SORT: gt_log.

    DELETE ADJACENT DUPLICATES FROM gt_log COMPARING ALL FIELDS.

    DELETE gt_log WHERE object EQ space.

    LOOP AT gt_log INTO ls_gt_log.
      APPEND ls_gt_log TO vald_log.
      CLEAR: ls_gt_log.
    ENDLOOP.
    CLEAR:  gt_log.
    CLEAR: gt_log.


  ENDMETHOD.
ENDCLASS.
