FUNCTION-POOL /psyng/sw_sestore.            "MESSAGE-ID ..
TYPE-POOLS :  shlp.

* egin of Changes for C0765 Changes by GSINGH
DATA: BEGIN OF gt_records OCCURS 0,
*        aid      TYPE /psyng/swreshdr-aid,
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
        origin    TYPE c LENGTH 12, "B16609 for C0633
      END OF gt_records.

DATA: i_server_path(200) TYPE c,
      i_users_count      TYPE i,
      i_aid              TYPE /psyng/seresid.

* end of changes by GSINGH.

* Begin of Changes for C0765 Changes by AKUMAR
TYPES : BEGIN OF ty_output_alv,
          agr_name  TYPE agr_define-agr_name,
        conid     TYPE /psyng/conflict-conid,
        confnum  TYPE /psyng/nr_conflicts,
        mitinum  TYPE /psyng/nr_conflicts,
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
  END OF ty_output_alv,

  tt_output_alv TYPE TABLE OF ty_output_alv.
* end of changes by AKUMAR.

DEFINE log.
  &1-type    = &2.
  &1-id      = &3.
  concatenate &4 &5 &6 &7 into &1-message separated by space.
  append &1.
END-OF-DEFINITION.

DEFINE add_column.

  gs_fieldcat-hotspot   = &1.
  gs_fieldcat-fieldname = &2.
  gs_fieldcat-seltext   = &3.
  gs_fieldcat-coltext   = &3.
  gs_fieldcat-intlen    = &5.
  gs_fieldcat-outputlen = &5.
  gs_fieldcat-fix_column = 'X'.
  gs_fieldcat-lzero = 'X'.
  gs_fieldcat-edit = &6.
  gs_fieldcat-emphasize = '0004'.
  gs_fieldcat-f4availabl = &7.
  gs_fieldcat-style      = &8.
  gs_fieldcat-checkbox   = &9.
  append gs_fieldcat to &4.
END-OF-DEFINITION.

*---screen data declaration

TYPES: BEGIN OF g_resultdtl,
         aid                 TYPE /psyng/swreshdr-aid,
         description         TYPE /psyng/swreshdr-description,
         bname               TYPE /psyng/swreshdr-bname,
         name_text(40)       TYPE c,
         started(20)         TYPE c,
         finished(20)        TYPE c,
         finished_flag       TYPE flag,
         duration            TYPE /psyng/text16,
         sodvrsio            TYPE /psyng/swreshdr-sodvrsio,
         vdescription        TYPE /psyng/swsodvers-vdesc,
         setid               TYPE /psyng/swreshdr-setid,
         sdescription        TYPE /psyng/swreshdr-description,
         kbytes_est(40)      TYPE c,
         retention_days_det  TYPE /psyng/swreshdr-retention_days,
         delete_date_det(12) TYPE c,
         retention_days_sum  TYPE /psyng/swreshdr-retention_days,
         delete_date_sum(12) TYPE c,
         retention_days      TYPE /psyng/swreshdr-retention_days,
         delete_date(12)     TYPE c,
         users_analyzed      TYPE /psyng/swreshdr-users_analyzed,
         conflicted_users    TYPE /psyng/swreshdr-conflicted_users,
         mitigated_users     TYPE /psyng/swreshdr-mitigated_users,
         conflicts           TYPE /psyng/swreshdr-conflicts,
         conflicts_abb       TYPE /psyng/swreshdr-conflicts,"AKUMAR
         mitigated_con       TYPE /psyng/swreshdr-mitigated_con,
         no_restrictions     TYPE /psyng/swreshdr-no_restrictions,
         variant_name        TYPE /psyng/swreshdr-variant_name,
         se_version	         TYPE /psyng/prog_vrsio,
         det_job_success     TYPE i,
         det_job_failed      TYPE i,
       END OF g_resultdtl.
TYPES: BEGIN OF ty_role_resultdtl,
         aid                 TYPE /psyng/swrrshdr-aid,
         description         TYPE /psyng/swrrshdr-description,
         bname               TYPE /psyng/swrrshdr-bname,
         name_text(40)       TYPE c,
         started(20)         TYPE c,
         finished(20)        TYPE c,
         finished_flag       TYPE flag,
         duration            TYPE /psyng/text16,
         sodvrsio            TYPE /psyng/swrrshdr-sodvrsio,
         vdescription        TYPE /psyng/swsodvers-vdesc,
         setid               TYPE /psyng/swrrshdr-setid,
         sdescription        TYPE /psyng/swrrshdr-description,
         sysid               TYPE /psyng/swrrshdr-sysid,
         rfcdescription      TYPE  /psyng/sw_rfcdes-description,
         kbytes_est(40)      TYPE c,
         retention_days_det  TYPE /psyng/swreshdr-retention_days,
         delete_date_det(12) TYPE c,
         retention_days_sum  TYPE /psyng/swreshdr-retention_days,
         delete_date_sum(12) TYPE c,
         retention_days      TYPE /psyng/swrrshdr-retention_days,
         delete_date(12)     TYPE c,
         roles_analyzed      TYPE /psyng/swrrshdr-roles_analyzed,
         conflicted_roles    TYPE /psyng/swrrshdr-conflicted_roles,
         mitigated_roles     TYPE /psyng/swrrshdr-mitigated_roles,
         conflicts           TYPE /psyng/swrrshdr-conflicts,
         mitigated_con       TYPE /psyng/swrrshdr-mitigated_con,
         no_restrictions     TYPE /psyng/swrrshdr-no_restrictions,
         variant_name        TYPE /psyng/swrrshdr-variant_name,
         se_version	         TYPE /psyng/prog_vrsio,
         det_job_success     TYPE i,
         det_job_failed      TYPE i,
       END OF ty_role_resultdtl.
DATA: gl_resultdtl      TYPE g_resultdtl,
      gs_role_resultdtl TYPE ty_role_resultdtl,
      gt_swreshdr       TYPE TABLE OF /psyng/swreshdr WITH HEADER LINE,
      gt_swrrshdr       TYPE TABLE OF /psyng/swrrshdr.

DATA: BEGIN OF gt_swresisys OCCURS 0.
        INCLUDE STRUCTURE /psyng/swresisys.
        DATA: description TYPE /psyng/desc,
      END OF gt_swresisys.
DATA: lt_sw_rfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE.
*--- Field catalog objects
DATA: gt_fieldcat       TYPE lvc_t_fcat,
      gt_sort           TYPE lvc_t_sort,
      gs_fieldcat       TYPE lvc_s_fcat,
      s_layout          TYPE lvc_s_layo,
      gr_alvgrid_sys    TYPE REF TO cl_gui_alv_grid,
      gr_ccontainer_sys TYPE REF TO cl_gui_custom_container.

*---------------------------------------------------------------------*
*       CLASS lcl_event_handler DEFINITION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION .
  PUBLIC SECTION .
    METHODS:
*--To add new functional buttons to the ALV toolbar
      handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,
      handle_before_user_command
                  FOR EVENT before_user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm.
  PRIVATE SECTION.
ENDCLASS.

*---------------------------------------------------------------------*
*       CLASS lcl_event_handler IMPLEMENTATION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.

*--Handle Toolbar
  METHOD handle_toolbar.
    PERFORM handle_toolbar USING e_object e_interactive .

  ENDMETHOD .
  METHOD handle_before_user_command .
    IF e_ucomm = '&INFO'.
      CALL FUNCTION '/PSYNG/BASIS_F1_HELP'
        EXPORTING
          dokname = '/PSYNG/SW_138_SYS'.

    ENDIF.
  ENDMETHOD .
ENDCLASS .

*---------------------------------------------------------------------*
*       FORM handle_toolbar                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_OBJECT                                                      *
*  -->  I_INTERACTIVE                                                 *
*---------------------------------------------------------------------*
FORM handle_toolbar  USING
       i_object TYPE REF TO cl_alv_event_toolbar_set i_interactive.
  DELETE i_object->mt_toolbar WHERE function CS '&LOCAL&'.
ENDFORM.

DATA: gr_event_handler  TYPE REF TO  lcl_event_handler.

*---screen 100 code to do need to move in other include
MODULE status_0100 OUTPUT.
  SET PF-STATUS '100'.
  SET TITLEBAR '0100'.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE load_result_detail OUTPUT                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE load_result_detail OUTPUT.
  DATA: l_date(10) TYPE c,
        l_time(8)  TYPE c,
        l_datetime TYPE string,
        l_bytes    TYPE p,
        l_kbytes   TYPE p,
        l_mbytes   TYPE p DECIMALS 2,
        l_gbytes   TYPE p DECIMALS 2,
        l_mbytes_c TYPE string,
        l_size     TYPE string,
        l_unit     TYPE string,
        lv_con TYPE /psyng/nr_conflicts,
        lv_con_abb TYPE /psyng/nr_conflicts,
        lv_usrcon_count TYPE i,
        lv_dummy TYPE /psyng/swresuabb-aid.


  CLEAR: gl_resultdtl, l_date, l_time, l_datetime.
  READ TABLE gt_swreshdr INDEX 1.

  MOVE-CORRESPONDING gt_swreshdr TO gl_resultdtl.

*Modifying values of conflicts and conflicts_abb field.
  CLEAR lv_dummy.
  SELECT SINGLE aid
         INTO lv_dummy
         FROM /psyng/swresuabb
         WHERE aid = gt_swreshdr-aid.

  IF sy-subrc = 0. "org check 'X'.

    lv_con_abb = gt_swreshdr-conflicts.

    CLEAR lv_usrcon_count.
    SELECT COUNT(*)
      INTO lv_usrcon_count
      FROM /psyng/swrescon
      WHERE aid = gt_swreshdr-aid.

    IF sy-subrc = 0 AND lv_usrcon_count > 0.
      lv_con = lv_usrcon_count.
    ELSE.
      CLEAR lv_con.
    ENDIF.

  ELSE.

    CLEAR lv_con_abb.
    lv_con = gt_swreshdr-conflicts.

  ENDIF.

  gl_resultdtl-conflicts = lv_con.
  gl_resultdtl-conflicts_abb = lv_con_abb.

  CLEAR gl_resultdtl-finished.
  gl_resultdtl-finished_flag = gt_swreshdr-finished.
*-- start date & time
  WRITE gt_swreshdr-start_date TO l_date.
  WRITE gt_swreshdr-start_time TO l_time.
  CONCATENATE l_date l_time INTO l_datetime SEPARATED BY space.
  gl_resultdtl-started = l_datetime.
  CLEAR: l_date, l_time, l_datetime.

*---end date & time
  WRITE gt_swreshdr-end_date TO l_date.
  WRITE gt_swreshdr-end_time TO l_time.
  CONCATENATE l_date l_time INTO l_datetime SEPARATED BY space.
  gl_resultdtl-finished = l_datetime.
  CLEAR: l_date, l_time, l_datetime.

*---delete date
  WRITE gt_swreshdr-delete_date TO l_date.
  gl_resultdtl-delete_date = l_date.
  CLEAR l_date.

*---Summary deletion date
  IF gt_swreshdr-delete_date_sum NE '00000000'.
    WRITE gt_swreshdr-delete_date_sum TO l_date.
    gl_resultdtl-delete_date_sum = l_date.
    CLEAR l_date.
  ELSE.
    CLEAR gl_resultdtl-delete_date_sum.
  ENDIF.

*---Details deletion date
  IF gt_swreshdr-delete_date_det NE '00000000'.
    WRITE gt_swreshdr-delete_date_det TO l_date.
    gl_resultdtl-delete_date_det = l_date.
    CLEAR l_date.
  ELSE.
    CLEAR gl_resultdtl-delete_date_det.
  ENDIF.
*---size estimation
  l_kbytes = gt_swreshdr-kbytes_est.
*  l_kbytes = l_bytes / 1024.
  l_mbytes = l_kbytes / 1024.
  l_gbytes = l_mbytes / 1024.
  IF l_gbytes > 1.
    l_mbytes_c = l_gbytes.
    l_unit     = 'Gb'.
  ELSEIF l_mbytes > 1.
    l_mbytes_c = l_mbytes.
    l_unit     = 'Mb'.
  ELSEIF l_kbytes > 0.
    l_mbytes_c = l_kbytes.
    l_unit     = 'Kb'.
*  ELSE.
*    l_mbytes_c = l_bytes.
*    l_unit     = 'B'.
  ENDIF.
  CONCATENATE l_mbytes_c l_unit INTO l_size.
  gl_resultdtl-kbytes_est = l_size.
  CLEAR l_size.

*---user text
  SELECT SINGLE  name_text FROM /psyng/bc_uidn INTO
   (gl_resultdtl-name_text) WHERE bname = gt_swreshdr-bname.

*---sod version text
  SELECT SINGLE vdesc FROM /psyng/swsodvers INTO
  (gl_resultdtl-vdescription) WHERE vrsio = gt_swreshdr-sodvrsio.

*--- configset text
  SELECT SINGLE description FROM /psyng/swcfgset INTO
   (gl_resultdtl-sdescription) WHERE setid = gt_swreshdr-setid.

*--- System information wrt aid
  REFRESH gt_swresisys.
  SELECT sysid FROM  /psyng/swresisys INTO CORRESPONDING FIELDS OF TABLE
           gt_swresisys WHERE aid = gt_swreshdr-aid.

*-- system details
  IF NOT gt_swresisys[] IS INITIAL.
    SELECT description systid
    FROM /psyng/sw_rfcdes INTO CORRESPONDING FIELDS OF
      TABLE lt_sw_rfcdes FOR ALL ENTRIES
      IN gt_swresisys
      WHERE systid = gt_swresisys-sysid.

    LOOP AT  gt_swresisys.
      READ TABLE lt_sw_rfcdes WITH KEY
                        systid = gt_swresisys-sysid.
      IF sy-subrc = 0.
        gt_swresisys-description =  lt_sw_rfcdes-description.
        MODIFY gt_swresisys TRANSPORTING description.
      ENDIF.
    ENDLOOP.
  ENDIF.
  PERFORM display_sys_alv.
ENDMODULE.


*---------------------------------------------------------------------*
*       MODULE user_command_100 INPUT                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  DATA ls_swrrshdr TYPE /psyng/swrrshdr.
  READ TABLE gt_swrrshdr INTO ls_swrrshdr INDEX 1.
  CASE sy-ucomm.
    WHEN 'CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'VARIANT'.
      IF NOT ls_swrrshdr-variant_name IS INITIAL.
        CALL FUNCTION 'RS_VARIANT_DISPLAY'
          EXPORTING
            report               = '/PSYNG/SW_148'
            variant              = ls_swrrshdr-variant_name
          EXCEPTIONS
            no_report            = 1
            report_not_existent  = 2
            report_not_supplied  = 3
            variant_not_existent = 4
            variant_not_supplied = 5
            variant_protected    = 6
            OTHERS               = 7.
        IF sy-subrc <> 0.
          MESSAGE s002(/psyng/sw) WITH
          'Variant could not be displayed'(v02).
        ENDIF.
      ELSE.
        MESSAGE s002(/psyng/sw) WITH
        'Variant name not stored with analysis'(v01).
      ENDIF.

  ENDCASE.
ENDMODULE.

*---------------------------------------------------------------------*
*       FORM display_sys_alv                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_sys_alv.
* CLEAR gs_layout.
  REFRESH : gt_fieldcat.
*----Preparing field catalog.
  add_column: ' ' 'SYSID' 'System ID'(h02) gt_fieldcat 32 '' '' '' '',
               ' ' 'DESCRIPTION' 'Description '(h03) gt_fieldcat
               32 '' '' '' ''.
  CREATE OBJECT gr_event_handler.

  IF gr_alvgrid_sys IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_ccontainer_sys
      EXPORTING
        container_name              = 'CC_SYSTEM'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        OTHERS                      = 6.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Creating ALV Grid instance
    CREATE OBJECT gr_alvgrid_sys
      EXPORTING
        i_parent          = gr_ccontainer_sys
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----toolbar and info
    SET HANDLER gr_event_handler->handle_toolbar
                           FOR gr_alvgrid_sys.
    SET HANDLER gr_event_handler->handle_before_user_command
                                                     FOR gr_alvgrid_sys.

*--functions
    CALL METHOD gr_alvgrid_sys->set_table_for_first_display
*      EXPORTING
*        is_layout                     = gs_layout
      CHANGING
        it_outtab                     = gt_swresisys[]
        it_fieldcatalog               = gt_fieldcat
*       it_sort                       = gt_sort
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ELSE .
    CALL METHOD gr_alvgrid_sys->set_frontend_fieldcatalog
      EXPORTING
        it_fieldcatalog = gt_fieldcat.

    CALL METHOD gr_alvgrid_sys->refresh_table_display
      EXCEPTIONS
        finished = 1
        OTHERS   = 2.

    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF .

ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  LOAD_ROLE_RESULT_DETAIL  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE load_role_result_detail OUTPUT.
  PERFORM load_role_result_detail.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Form  LOAD_ROLE_RESULT_DETAIL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM load_role_result_detail .
  DATA: l_date(10)  TYPE c,
        l_time(8)   TYPE c,
        l_datetime  TYPE string,
        ls_swrrshdr TYPE /psyng/swrrshdr,
        l_bytes     TYPE p,
        l_kbytes    TYPE p,
        l_mbytes    TYPE p DECIMALS 2,
        l_gbytes    TYPE p DECIMALS 2,
        l_mbytes_c  TYPE string,
        l_size      TYPE string,
        l_unit      TYPE string,
        l_min_gb    TYPE p DECIMALS 2 VALUE '1.00'.


  CLEAR: gs_role_resultdtl, l_date, l_time, l_datetime.
  READ TABLE gt_swrrshdr INTO ls_swrrshdr INDEX 1.

  MOVE-CORRESPONDING ls_swrrshdr TO gs_role_resultdtl.
  CLEAR gs_role_resultdtl-finished.
  gs_role_resultdtl-finished_flag = ls_swrrshdr-finished.
*-- start date & time
  WRITE ls_swrrshdr-start_date TO l_date.
  WRITE ls_swrrshdr-start_time TO l_time.
  CONCATENATE l_date l_time INTO l_datetime SEPARATED BY space.
  gs_role_resultdtl-started = l_datetime.
  CLEAR: l_date, l_time, l_datetime.

*---end date & time
  WRITE ls_swrrshdr-end_date TO l_date.
  WRITE ls_swrrshdr-end_time TO l_time.
  CONCATENATE l_date l_time INTO l_datetime SEPARATED BY space.
  gs_role_resultdtl-finished = l_datetime.
  CLEAR: l_date, l_time, l_datetime.

*---delete date
  WRITE ls_swrrshdr-delete_date TO l_date.
  gs_role_resultdtl-delete_date = l_date.
  CLEAR l_date.
*---Summary deletion date
  IF ls_swrrshdr-delete_date_sum NE '00000000'.
    WRITE ls_swrrshdr-delete_date_sum TO l_date.
    gs_role_resultdtl-delete_date_sum = l_date.
    CLEAR l_date.
  ELSE.
    CLEAR gs_role_resultdtl-delete_date_sum.
  ENDIF.

*---Details deletion date
  IF ls_swrrshdr-delete_date_det NE '00000000'.
    WRITE ls_swrrshdr-delete_date_det TO l_date.
    gs_role_resultdtl-delete_date_det = l_date.
    CLEAR l_date.
  ELSE.
    CLEAR gs_role_resultdtl-delete_date_det.
  ENDIF.

*---size estimation
  l_kbytes = ls_swrrshdr-kbytes_est.
  l_mbytes = l_kbytes / 1024.
  l_gbytes = l_mbytes / 1024.
  IF l_gbytes > l_min_gb .
    l_mbytes_c = l_gbytes.
    l_unit     = 'Gb'.
  ELSEIF l_mbytes > 1.
    l_mbytes_c = l_mbytes.
    l_unit     = 'Mb'.
  ELSEIF l_kbytes > 0.
    l_mbytes_c = l_kbytes.
    l_unit     = 'Kb'.
  ENDIF.
  CONCATENATE l_mbytes_c l_unit INTO l_size.
  gs_role_resultdtl-kbytes_est = l_size.
  CLEAR l_size.

*---user text
  SELECT SINGLE  name_text FROM /psyng/bc_uidn INTO
   (gs_role_resultdtl-name_text) WHERE bname = ls_swrrshdr-bname.

*---sod version text
  SELECT SINGLE vdesc FROM /psyng/swsodvers INTO
  (gs_role_resultdtl-vdescription) WHERE vrsio = ls_swrrshdr-sodvrsio.

*--- configset text
  SELECT SINGLE description FROM /psyng/swcfgset INTO
   (gs_role_resultdtl-sdescription) WHERE setid = ls_swrrshdr-setid.

*--- System information wrt aid
  SELECT SINGLE description
  FROM /psyng/sw_rfcdes INTO (gs_role_resultdtl-rfcdescription)
  WHERE systid = ls_swrrshdr-sysid.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  DATA ls_swreshdr TYPE /psyng/swreshdr.
  READ TABLE gt_swreshdr INTO ls_swreshdr INDEX 1.
  CASE sy-ucomm.
    WHEN 'CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'VARIANT'.
      IF NOT ls_swreshdr-variant_name IS INITIAL.
        CALL FUNCTION 'RS_VARIANT_DISPLAY'
          EXPORTING
            report               = '/PSYNG/SW_140'
            variant              = ls_swreshdr-variant_name
          EXCEPTIONS
            no_report            = 1
            report_not_existent  = 2
            report_not_supplied  = 3
            variant_not_existent = 4
            variant_not_supplied = 5
            variant_protected    = 6
            OTHERS               = 7.
        IF sy-subrc <> 0.
          MESSAGE s002(/psyng/sw) WITH
          'Variant could not be displayed'(v02).
        ENDIF.
      ELSE.
        MESSAGE s002(/psyng/sw) WITH
        'Variant name not stored with analysis'(v01).
      ENDIF.

  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Form  CREATE_FILE_ON_SERVER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ET_OUTPUT_RECORDS  text
*----------------------------------------------------------------------*
FORM create_file_on_server  TABLES et_output_records STRUCTURE gt_records
                        USING i_server_path i_users_count i_aid
                        CHANGING lv_file_count TYPE i .
  DATA : lv_file_seq         TYPE string,
         lv_filename(200)    TYPE c,
         lv_server_path(200) TYPE c,
         lf_line(750)        TYPE c.
  CONSTANTS lc_hiphen(1) VALUE '_'.
* Increase the file counter when new file is created
  lv_file_count = lv_file_count + 1.
  IF lv_file_count = 1.
MESSAGE s002(/psyng/sw) WITH 'Exporting SOD user data to '(i03) i_server_path.
MESSAGE s002(/psyng/sw) WITH 'Batch Size(Records): '(i09) i_users_count.
  ENDIF.
* Reasign the file counter to character field counter for Concatenation logic
  lv_file_seq = lv_file_count.
* Create file name with Result id, date, timeand file sequence number
  CONCATENATE 'STORE_SOD_USER_RESULTS'(i04)
               lc_hiphen
               i_aid
               lc_hiphen
               sy-datum
               sy-uzeit
               lc_hiphen
               lv_file_seq
               '.txt'
               INTO lv_filename.
  lv_server_path = i_server_path.
* Create Final dataset along with server path and file name
  CONCATENATE lv_server_path lv_filename INTO lv_server_path.
  CONDENSE lv_server_path NO-GAPS.
* Create the file on the server path
*BOC UMITTAL CLEAN CORE FIXES 11/03/2026
  CALL METHOD /psyng/sw_dynamic_select=>open_dataset_for_user
    EXPORTING
      iv_server_path      =  lv_server_path   " Text field length 200
      iv_filename         =  lv_filename  " Text field length 200
      it_output_alv_user  =  et_output_records[].

*  OPEN DATASET lv_server_path
*   FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.     "#EC SAST_CI_GEN_CHECK
*  CONDENSE lv_filename NO-GAPS.
*  MESSAGE s002(/psyng/sw) WITH 'Creating the below file...'(i10).
*  MESSAGE lv_filename TYPE 'S'.
*  COMMIT WORK.
** Create the header of the file
*  CONCATENATE 'User ID'(t19)
*              'Conflicts'(t20)
*              'Mitigated Conflicts'(t21)
*              'Conflict'(t04)
*              'Mitigated'(t05)
*              'Function'(t06)
*              'Composite Role'(t07)
*              'Role'(t08)
*              'Profile'(t09)
*              'System'(t10)
*              'Tcode'(t11)
*              'Abbr.'(t12)
*              'Authrorization'(t13)
*              'Object'(t14)
*              'Field'(t15)
*              'Value From'(t16)
*              'Value To'(t17)
*              'Origin'(t18)
*              INTO lf_line
*              SEPARATED BY '|'.
*  TRANSFER lf_line TO lv_server_path. "#EC PATHLOCK_CI_NO_DOS (HBHALLA)
*  CLEAR lf_line.
*  LOOP AT et_output_records.
*    DATA: lv_confnum(6),
*          lv_mitinum(6).
** Reasign the conflcts/mitigated conflits numbers to character fields for Concatenation logic
*    lv_confnum = et_output_records-confnum.
*    lv_mitinum = et_output_records-mitinum.
** Create final record for the file
*    CONCATENATE et_output_records-bname
*                lv_confnum
*                lv_mitinum
*                et_output_records-conid
*                et_output_records-mitigated
*                et_output_records-funid
*                et_output_records-comp_agr
*                et_output_records-agr_name
*                et_output_records-profname
*                et_output_records-sysid
*                et_output_records-tcode
*                et_output_records-abb
*                et_output_records-auth
*                et_output_records-object
*                et_output_records-field
*                et_output_records-von
*                et_output_records-bis
*                et_output_records-origin
*                INTO lf_line
*                SEPARATED BY '|'.
** Remove any extra space and transfer the records to dataset
*    CONDENSE lf_line NO-GAPS.
*   TRANSFER lf_line TO lv_server_path. "#EC PATHLOCK_CI_NO_DOS (HBHALLA)
*    CLEAR: lf_line, lv_confnum.
*  ENDLOOP.
** Close the dataset/file  after all records are transfered
*  CLOSE DATASET lv_server_path.
*  IF sy-subrc EQ 0.
*    MESSAGE s002(/psyng/sw) WITH 'Closing the above file...'(i06).
*    COMMIT WORK.
*  ENDIF.
*  CLEAR: lv_server_path,
*         lv_filename.
*EOC UMITTAL CLEAN CORE FIXES 11/03/2026
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CREATE_ROLE_FILE_ON_SERVER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_OUTPUT_ALV[]  text
*      -->P_I_SERVER_PATH  text
*      -->P_I_ROLES_COUNT  text
*      -->P_I_AID  text
*      <--P_L_FILE_COUNT  text
*----------------------------------------------------------------------*
FORM create_role_file_on_server USING lt_output_alv TYPE tt_output_alv
                                 i_server_path i_roles_count i_aid
                        CHANGING l_file_count TYPE i.

  DATA : l_file_count_str TYPE string, "type casting purpose
        lv_filename(200)    TYPE c,
        lv_server_path(200) TYPE c,
        lf_line(750)        TYPE c,    "To store one record
        lv_confnum(6),
        lv_mitinum(6),
        ls_output_alv LIKE LINE OF lt_output_alv.

  CONSTANTS lc_underscore(1) VALUE '_'.

  ADD 1 TO l_file_count.

  IF l_file_count = 1.
    MESSAGE s002(/psyng/sw) WITH 'Exporting SOD role data to '(i12)
                                                          i_server_path.
    MESSAGE s002(/psyng/sw) WITH 'Batch Size(Records): '(i09)
                                                          i_roles_count.
  ENDIF.

*--Type casting
  l_file_count_str = l_file_count.

*--Create filename
  CONCATENATE 'STORE_SOD_ROLE_RESULTS'(i11)
             lc_underscore
             i_aid
             lc_underscore
             sy-datum
             sy-uzeit
             lc_underscore
             l_file_count_str
             '.txt'
             INTO lv_filename.

  lv_server_path = i_server_path.
  CONCATENATE lv_server_path lv_filename INTO lv_server_path.
  CONDENSE lv_server_path NO-GAPS.
*BOC UMITTAL CLEAN CORE FIXES 11/03/2026
  CALL METHOD /psyng/sw_dynamic_select=>open_dataset_for_role
    EXPORTING
      iv_server_path      =  lv_server_path   " Text field length 200
      iv_filename         =  lv_filename  " Text field length 200
      it_output_alv_role  =  lt_output_alv[].

** Create the file on the server path
*  OPEN DATASET lv_server_path
*   FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.     "#EC SAST_CI_GEN_CHECK
*  CONDENSE lv_filename NO-GAPS.
*  MESSAGE s002(/psyng/sw) WITH 'Creating the below file...'(i10).
*  MESSAGE lv_filename TYPE 'S'.
*  COMMIT WORK.
*
** Create the header of the file
*  CONCATENATE 'Role ID'(t23)
*              'Conflicts'(t20)
*              'Mitigated Conflicts'(t21)
*              'Conflict'(t04)
*              'Function'(t06)
*              'Child Role'(t22)
*              'System'(t10)
*              'Tcode'(t11)
*              'Abbr.'(t12)
*              'Authrorization'(t13)
*              'Object'(t14)
*              'Field'(t15)
*              'Value From'(t16)
*              'Value To'(t17)
*              INTO lf_line
*              SEPARATED BY '|'.
*
*  TRANSFER lf_line TO lv_server_path. "#EC PATHLOCK_CI_NO_DOS (HBHALLA)
*  CLEAR lf_line.
*
**--Creating records into file
*  LOOP AT lt_output_alv INTO ls_output_alv.
*
*    lv_confnum = ls_output_alv-confnum.
*    lv_mitinum = ls_output_alv-mitinum.
*
*    CONCATENATE ls_output_alv-agr_name
*                lv_confnum
*                lv_mitinum
*                ls_output_alv-conid
*                ls_output_alv-funid
*                ls_output_alv-childrole
*                ls_output_alv-sysid
*                ls_output_alv-tcode
*                ls_output_alv-abb
*                ls_output_alv-auth
*                ls_output_alv-object
*                ls_output_alv-field
*                ls_output_alv-von
*                ls_output_alv-bis
*                INTO lf_line
*                SEPARATED BY '|'.
*
*    CONDENSE lf_line NO-GAPS.
*   TRANSFER lf_line TO lv_server_path. "#EC PATHLOCK_CI_NO_DOS (HBHALLA)
*    CLEAR: lf_line, lv_confnum, lv_mitinum.
*
*  ENDLOOP.
*
*  CLOSE DATASET lv_server_path.
*  IF sy-subrc EQ 0.
*    MESSAGE s002(/psyng/sw) WITH 'Closing the above file...'(i06).
*    COMMIT WORK.
*  ENDIF.
*  CLEAR: lv_server_path,
*         lv_filename.
*EOC UMITTAL CLEAN CORE FIXES 11/03/2026
ENDFORM.
