class /PSYNG/SW_DYNAMIC_SELECT definition
  public
  final
  create public .

public section.

  types:
    ty_where_tab TYPE STANDARD TABLE OF
       rsdswhere WITH DEFAULT KEY .
  types:
    BEGIN OF ts_output_role  ,
                agr_name  TYPE agr_define-agr_name,
                conid     TYPE /psyng/conflict-conid,
                confnum   TYPE /psyng/nr_conflicts,
                mitinum   TYPE /psyng/nr_conflicts,
                mitigated TYPE flag,
                funid     TYPE /psyng/faobj2-funid,
                childrole TYPE agr_define-agr_name,
                sysid     TYPE /psyng/sw_rfcdes-systid,
                tcode     TYPE /psyng/faobj2-tcode,
                auth      TYPE /psyng/serrs_authdetail-auth,
                object    TYPE /psyng/faobj2-object,
                field     TYPE /psyng/faobj2-field,
                von       TYPE /psyng/serrs_authdetail-von,
                bis       TYPE /psyng/serrs_authdetail-bis,
                abb       TYPE /psyng/serrs_authdetail-abb,
            END OF ts_output_role .
  types:
    BEGIN OF ts_output_user  ,
                bname     TYPE /psyng/swreshdr-bname,
            conid     TYPE /psyng/conflict-conid,
            confnum   TYPE /psyng/nr_conflicts,
            mitinum   TYPE /psyng/nr_conflicts,
            mitigated TYPE flag,
            funid     TYPE /psyng/faobj2-funid,
            comp_agr  TYPE agr_define-agr_name,
            agr_name  TYPE agr_define-agr_name,
            profname  TYPE agr_prof-profile,
            sysid     TYPE /psyng/sw_rfcdes-systid,
            tcode     TYPE /psyng/faobj2-tcode,
            auth      TYPE /psyng/seres_authdetail-auth,
            object    TYPE /psyng/faobj2-object,
            field     TYPE /psyng/faobj2-field,
            von       TYPE /psyng/seres_authdetail-von,
            bis       TYPE /psyng/seres_authdetail-bis,
            abb       TYPE /psyng/seres_authdetail-abb,
            origin    TYPE c LENGTH 12,
            END OF ts_output_user .
  types:
    tty_output_role TYPE TABLE OF ts_output_role .
  types:
    tty_output_user TYPE TABLE OF ts_output_user .

  class-methods CALLBACK
    importing
      !I_FNAME type RS38L_FNAM optional
      !I_RFCDEST type /PSYNG/RFCDEST optional
      !I_COM type USCOMP optional
    exporting
      !E_TEXT type USCOMP .
  class-methods CALL_PROGRAM
    importing
      !I_PROGRAM type SY-REPID optional .
  class-methods OPEN_DATASET_FOR_ROLE
    importing
      !IV_SERVER_PATH type CHAR200 optional
      !IV_FILENAME type CHAR200 optional
      !IT_OUTPUT_ALV_ROLE type TTY_OUTPUT_ROLE optional .
  class-methods OPEN_DATASET_FOR_USER
    importing
      !IV_SERVER_PATH type CHAR200 optional
      !IV_FILENAME type CHAR200 optional
      !IT_OUTPUT_ALV_USER type TTY_OUTPUT_USER optional .
  class-methods DELETE_INDX_ENTRY
    importing
      !IV_EXPORTID type CHAR50 optional .
  class-methods DYNAMIC_CALL_TXN
    importing
      !I_TCODE type XUTCODE optional
      !I_PROG type PROGRAMM optional .
  class-methods SELECT_INTO_TABLE
    importing
      !I_TABNAME type TABNAME optional
      !IT_WHERE_TAB type TY_WHERE_TAB optional
    exporting
      !E_DATA type ref to DATA
    raising
      CX_SY_DYNAMIC_OSQL_ERROR
      CX_SY_CREATE_DATA_ERROR .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS /PSYNG/SW_DYNAMIC_SELECT IMPLEMENTATION.


  METHOD callback.
    DATA: gf_dyn_class_exists TYPE flag,
          g_classn            TYPE seoclskey.

    g_classn = '/PSYNG/SW_CC_DYNAMIC_SELECT'.
    CALL FUNCTION 'SEO_CLASS_GET'
    EXPORTING
      clskey         = g_classn
    EXCEPTIONS
      not_existing   = 1
      deleted        = 2
      is_interface   = 3
      model_only     = 4
      internal_error = 5
    OTHERS         = 6.
    IF sy-subrc <> 0.
      gf_dyn_class_exists = ''.
    ELSE.
      gf_dyn_class_exists = 'X'.
    ENDIF.

    IF gf_dyn_class_exists = 'X'.

      CALL METHOD (g_classn)=>callback
      EXPORTING
            i_call_back    =   i_fname
            i_com          =   i_com
          IMPORTING
           e_text          =    e_text.
    ELSE.
      g_classn = '/PSYNG/SW_NCC_DYNAMIC_SELECT'.
      CALL FUNCTION 'SEO_CLASS_GET'
      EXPORTING
        clskey         = g_classn
      EXCEPTIONS
        not_existing   = 1
        deleted        = 2
        is_interface   = 3
        model_only     = 4
        internal_error = 5
        OTHERS         = 6.
      IF sy-subrc <> 0.
        gf_dyn_class_exists = ''.
      ELSE.
        gf_dyn_class_exists = 'X'..
      ENDIF.

      IF gf_dyn_class_exists = 'X'.
        CALL METHOD (g_classn)=>callback
          EXPORTING
            i_call_back    =   i_fname
            i_com          =   i_com
          IMPORTING
           e_text          =    e_text.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD call_program.
    "-------------------------------------------------------------------
    " Local Data Declarations
    "-------------------------------------------------------------------
    DATA: gf_dyn_class_exists TYPE flag,
          g_classn            TYPE seoclskey.

    "-------------------------------------------------------------------
    " STEP 1: Process via Clean Core (CC) Class
    " This is the primary execution path for modern SAP environments.
    "-------------------------------------------------------------------
    g_classn = '/PSYNG/SW_CC_DYNAMIC_SELECT'.

    " Validate existence of the Clean Core class in the Data Dictionary
 CALL FUNCTION 'SEO_CLASS_GET'                   "#EC SAST_CI_GEN_CHECK
   EXPORTING
     clskey         = g_classn
   EXCEPTIONS
     not_existing   = 1
     deleted        = 2
     is_interface   = 3
     model_only     = 4
     internal_error = 5
     OTHERS         = 6.

    IF sy-subrc = 0.
      gf_dyn_class_exists = 'X'.
    ELSE.
      gf_dyn_class_exists = ''.
    ENDIF.

    " If CC class exists, call the dynamic selection method
    IF gf_dyn_class_exists = 'X'.
      CALL METHOD (g_classn)=>call_program
        EXPORTING
          i_program = i_program.



    "-------------------------------------------------------------------
      " STEP 2: Fallback to Non-Clean Core (NCC) Class
      " Executes only if the primary CC class is unavailable.

    "-------------------------------------------------------------------
    ELSE.
      g_classn = '/PSYNG/SW_NCC_DYNAMIC_SELECT'.

      " Validate existence of the legacy fallback class
   CALL FUNCTION 'SEO_CLASS_GET'                 "#EC SAST_CI_GEN_CHECK
     EXPORTING
       clskey         = g_classn
     EXCEPTIONS
       not_existing   = 1
       deleted        = 2
       is_interface   = 3
       model_only     = 4
       internal_error = 5
       OTHERS         = 6.

      IF sy-subrc = 0.
        gf_dyn_class_exists = 'X'.
      ELSE.
        gf_dyn_class_exists = ''.
      ENDIF.

      " If fallback NCC class is available, proceed with selection
      IF gf_dyn_class_exists = 'X'.
        CALL METHOD (g_classn)=>call_program
          EXPORTING
            i_program = i_program.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD delete_indx_entry.

    DATA: gf_dyn_class_exists TYPE flag,
          g_classn            TYPE seoclskey.

    g_classn = '/PSYNG/SW_NCC_DYNAMIC_SELECT'.
    CALL FUNCTION 'SEO_CLASS_GET'
    EXPORTING
      clskey         = g_classn
    EXCEPTIONS
      not_existing   = 1
      deleted        = 2
      is_interface   = 3
      model_only     = 4
      internal_error = 5
    OTHERS         = 6.
    IF sy-subrc <> 0.
      gf_dyn_class_exists = ''.
    ELSE.
      gf_dyn_class_exists = 'X'.
    ENDIF.

    IF gf_dyn_class_exists = 'X'.

      CALL METHOD (g_classn)=>delete_indx_entry
      EXPORTING
        iv_exportid      =  iv_exportid   ." Text field length 200

    ENDIF.
  ENDMETHOD.


 METHOD dynamic_call_txn.
   "-------------------------------------------------------------------
   " Local Data Declarations
   "-------------------------------------------------------------------
   DATA: gf_dyn_class_exists TYPE flag,
         g_classn            TYPE seoclskey.

   "-------------------------------------------------------------------
   " STEP 1: Process via Clean Core (CC) Class
   " This is the primary execution path for modern SAP environments.
   "-------------------------------------------------------------------
   g_classn = '/PSYNG/SW_CC_DYNAMIC_SELECT'.

   " Validate existence of the Clean Core class in the Data Dictionary
   CALL FUNCTION 'SEO_CLASS_GET'                 "#EC SAST_CI_GEN_CHECK
     EXPORTING
       clskey         = g_classn
     EXCEPTIONS
       not_existing   = 1
       deleted        = 2
       is_interface   = 3
       model_only     = 4
       internal_error = 5
       OTHERS         = 6.

   IF sy-subrc = 0.
     gf_dyn_class_exists = 'X'.
   ELSE.
     gf_dyn_class_exists = ''.
   ENDIF.

   " If CC class exists, call the dynamic selection method
   IF gf_dyn_class_exists = 'X'.
     CALL METHOD (g_classn)=>dynamic_call_txn
       EXPORTING
         i_tcode = i_tcode
         i_prog  = i_prog.



    "-----------------------------------------------------------------
     " STEP 2: Fallback to Non-Clean Core (NCC) Class
     " Executes only if the primary CC class is unavailable.

    "------------------------------------------------------------------
   ELSE.
     g_classn = '/PSYNG/SW_NCC_DYNAMIC_SELECT'.

     " Validate existence of the legacy fallback class
     CALL FUNCTION 'SEO_CLASS_GET'               "#EC SAST_CI_GEN_CHECK
       EXPORTING
         clskey         = g_classn
       EXCEPTIONS
         not_existing   = 1
         deleted        = 2
         is_interface   = 3
         model_only     = 4
         internal_error = 5
         OTHERS         = 6.

     IF sy-subrc = 0.
       gf_dyn_class_exists = 'X'.
     ELSE.
       gf_dyn_class_exists = ''.
     ENDIF.

     " If fallback NCC class is available, proceed with selection
     IF gf_dyn_class_exists = 'X'.
       CALL METHOD (g_classn)=>dynamic_call_txn
         EXPORTING
           i_tcode = i_tcode
           i_prog  = i_prog.
     ENDIF.
   ENDIF.
 ENDMETHOD.


METHOD open_dataset_for_role.


  DATA: gf_dyn_class_exists TYPE flag,
        g_classn            TYPE seoclskey.

  g_classn = '/PSYNG/SW_CC_DYNAMIC_SELECT'.
  CALL FUNCTION 'SEO_CLASS_GET'
  EXPORTING
    clskey         = g_classn
  EXCEPTIONS
    not_existing   = 1
    deleted        = 2
    is_interface   = 3
    model_only     = 4
    internal_error = 5
  OTHERS         = 6.
  IF sy-subrc <> 0.
    gf_dyn_class_exists = ''.
  ELSE.
    gf_dyn_class_exists = 'X'.
  ENDIF.

  IF gf_dyn_class_exists = 'X'.

    CALL METHOD (g_classn)=>open_dataset_for_role
 EXPORTING
   iv_server_path      =  iv_server_path   " Text field length 200
   iv_filename         =  iv_filename  " Text field length 200
   it_output_alv_role  =  it_output_alv_role[].
  ELSE.
    g_classn = '/PSYNG/SW_NCC_DYNAMIC_SELECT'.
    CALL FUNCTION 'SEO_CLASS_GET'
    EXPORTING
      clskey         = g_classn
    EXCEPTIONS
      not_existing   = 1
      deleted        = 2
      is_interface   = 3
      model_only     = 4
      internal_error = 5
      OTHERS         = 6.
    IF sy-subrc <> 0.
      gf_dyn_class_exists = ''.
    ELSE.
      gf_dyn_class_exists = 'X'..
    ENDIF.

    IF gf_dyn_class_exists = 'X'.
      CALL METHOD (g_classn)=>open_dataset_for_role
 EXPORTING
   iv_server_path      =  iv_server_path   " Text field length 200
   iv_filename         =  iv_filename  " Text field length 200
   it_output_alv_role  =  it_output_alv_role[].
    ENDIF.
  ENDIF.
ENDMETHOD.


  METHOD open_dataset_for_user.

    DATA: gf_dyn_class_exists TYPE flag,
          g_classn            TYPE seoclskey.

    g_classn = '/PSYNG/SW_CC_DYNAMIC_SELECT'.
    CALL FUNCTION 'SEO_CLASS_GET'
      EXPORTING
        clskey         = g_classn
      EXCEPTIONS
        not_existing   = 1
        deleted        = 2
        is_interface   = 3
        model_only     = 4
        internal_error = 5
      OTHERS         = 6.
    IF sy-subrc <> 0.
      gf_dyn_class_exists = ''.
    ELSE.
      gf_dyn_class_exists = 'X'.
    ENDIF.

    IF gf_dyn_class_exists = 'X'.

      CALL METHOD (g_classn)=>open_dataset_for_user
        EXPORTING
          iv_server_path      =  iv_server_path
          iv_filename         =  iv_filename
          it_output_alv_user  =  it_output_alv_user[].
    ELSE.
      g_classn = '/PSYNG/SW_NCC_DYNAMIC_SELECT'.
      CALL FUNCTION 'SEO_CLASS_GET'
        EXPORTING
          clskey         = g_classn
        EXCEPTIONS
          not_existing   = 1
          deleted        = 2
          is_interface   = 3
          model_only     = 4
          internal_error = 5
          OTHERS         = 6.
      IF sy-subrc <> 0.
        gf_dyn_class_exists = ''.
      ELSE.
        gf_dyn_class_exists = 'X'..
      ENDIF.

      IF gf_dyn_class_exists = 'X'.
        CALL METHOD (g_classn)=>open_dataset_for_user
          EXPORTING
            iv_server_path      =  iv_server_path
            iv_filename         =  iv_filename
            it_output_alv_user  =  it_output_alv_user[].
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD select_into_table.
    DATA: gf_dyn_class_exists TYPE flag,
          g_classn            TYPE seoclskey.

    g_classn = '/PSYNG/SW_CC_DYNAMIC_SELECT'.
  CALL FUNCTION 'SEO_CLASS_GET'                  "#EC SAST_CI_GEN_CHECK
  EXPORTING
    clskey         = g_classn
  EXCEPTIONS
    not_existing   = 1
    deleted        = 2
    is_interface   = 3
    model_only     = 4
    internal_error = 5
    OTHERS         = 6.
    IF sy-subrc <> 0.
      gf_dyn_class_exists = ''.
    ELSE.
      gf_dyn_class_exists = 'X'.
    ENDIF.
    IF gf_dyn_class_exists = 'X'.

      CALL METHOD (g_classn)=>select_into_table
        EXPORTING
          i_tabname         = i_tabname
          it_where_tab      = it_where_tab
        IMPORTING
          e_data            = e_data.
    ELSE.
      g_classn = '/PSYNG/SW_NCC_DYNAMIC_SELECT'.
  CALL FUNCTION 'SEO_CLASS_GET'                  "#EC SAST_CI_GEN_CHECK
    EXPORTING
      clskey         = g_classn
    EXCEPTIONS
      not_existing   = 1
      deleted        = 2
      is_interface   = 3
      model_only     = 4
      internal_error = 5
      OTHERS         = 6.
      IF sy-subrc <> 0.
        gf_dyn_class_exists = ''.
      ELSE.
        gf_dyn_class_exists = 'X'.
      ENDIF.

      IF gf_dyn_class_exists = 'X'.

        CALL METHOD (g_classn)=>select_into_table
          EXPORTING
          i_tabname         = i_tabname
          it_where_tab      = it_where_tab
        IMPORTING
          e_data            = e_data.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
