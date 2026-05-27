*----------------------------------------------------------------------*
* Report  /PSYNG/SW_124                                               *
* AUTHOR: Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

REPORT /psyng/sw_124.

TABLES : /psyng/conflict, /psyng/busarea,/psyng/function.
TYPE-POOLS : slis.

DATA : BEGIN OF gt_conf_count OCCURS 0,
         conflict TYPE /psyng/conflict-conid,
         fcount TYPE i,
       END OF gt_conf_count.

TYPES: BEGIN OF ty_matrix.
        INCLUDE STRUCTURE /psyng/sw_mr_function_matrix.

TYPES: it_colors    TYPE lvc_t_scol,
END OF ty_matrix.


DATA: gt_matrix TYPE TABLE OF ty_matrix WITH HEADER LINE,
      gs_matrix1 LIKE LINE OF gt_matrix,
      gs_matrix12 TYPE ty_matrix.

DATA : gt_conflict TYPE TABLE OF /psyng/conflict
                   WITH HEADER LINE,
       gt_confdet  TYPE TABLE OF /psyng/confdet
                   WITH HEADER LINE,
       gt_functions TYPE TABLE OF /psyng/da_function WITH HEADER LINE,
       gt_fieldcat TYPE lvc_t_fcat,
       gs_fieldcat TYPE lvc_s_fcat,
       g_count TYPE numc4,
       gr_table TYPE REF TO data,
       gr_rec   TYPE REF TO data,
       gr_table2 TYPE REF TO data,
       gr_rec2   TYPE REF TO data,
       gs_fieldname TYPE string,
       gt_fieldcat_alv TYPE slis_t_fieldcat_alv,
       gs_fieldcat_alv TYPE slis_fieldcat_alv,
       gs_layout TYPE slis_layout_alv,
       gv_program         LIKE sy-repid,
       gs_colors    TYPE lvc_s_scol.
FIELD-SYMBOLS : <func> TYPE /psyng/da_confdet,
                <mtr> LIKE gt_matrix.
FIELD-SYMBOLS : <fs_tab> TYPE STANDARD TABLE,
                <fs_tab2> TYPE STANDARD TABLE,
                <fs_rec> TYPE agr_tcodes,
                <fs_rec1> TYPE agr_tcodes,
                <fs_o2> TYPE ANY,
                <fs_o> TYPE ANY,
                <fs_dynfield> TYPE ANY,
                <fs_dynfield_h> TYPE ANY,
                <ta_color> TYPE lvc_t_scol.

RANGES : s_func1 FOR /psyng/function-function,
         s_conf1 FOR /psyng/conflict-conid.
*-- Selection Screen
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
PARAMETERS :  p_system TYPE /psyng/sw_rfcdes-systid,
              sodvrsio TYPE /psyng/sodvrsio.
SELECTION-SCREEN SKIP.
SELECT-OPTIONS:
   spconfs FOR /psyng/conflict-conid    MODIF ID con,
   s_func FOR /psyng/function-function MODIF ID con,
   pappa   FOR /psyng/busarea-busarea   MODIF ID con,
*   proca   FOR /psyng/bus_proce-subarea MODIF ID con,
   cowner  FOR /psyng/conflict-owner    MODIF ID con,
   csens   FOR /psyng/conflict-imp      MODIF ID con,
   s_risk  FOR /psyng/conflict-risk     MODIF ID con,
   cprmit  FOR /psyng/conflict-contid   MODIF ID con.

SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF BLOCK exe WITH FRAME TITLE text-002.

PARAMETERS : p_rid TYPE flag RADIOBUTTON GROUP g1,
             p_rtext TYPE flag RADIOBUTTON GROUP g1,
             p_rsens TYPE flag RADIOBUTTON GROUP g1.

SELECTION-SCREEN END OF BLOCK exe.
SELECTION-SCREEN END OF BLOCK b1.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_system.
  PERFORM f4_system USING 'P_SYSTEM' CHANGING p_system.

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
  PERFORM get_data.
  PERFORM output.



*---------------------------------------------------------------------*
*       FORM CONFLICT_HOTSPOT                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM conflict_hotspot USING r_ucomm LIKE sy-ucomm
                                  rs_selfield TYPE slis_selfield.

  DATA : lt_functran TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
         l_text TYPE string.

  RANGES : lr_tcode FOR tstct-tcode.

  CHECK NOT rs_selfield-value IS INITIAL.

  IF p_rtext = 'X'.
    SPLIT rs_selfield-value AT '-' INTO rs_selfield-value l_text.
  ENDIF.

  IF p_rsens = 'X'.
    SPLIT rs_selfield-value AT '-' INTO rs_selfield-value l_text.
  ENDIF.
  REFRESH lr_tcode.
  READ TABLE gt_conflict WITH KEY conid = rs_selfield-value.
  IF sy-subrc = 0.

    lr_tcode-sign = 'I'.
    lr_tcode-option = 'EQ'.
    LOOP AT gt_confdet WHERE conid = gt_conflict-conid.
      REFRESH :lt_functran.
      SELECT * FROM /psyng/functtran                 "#EC CI_SEL_NESTED
       INTO TABLE lt_functran
      WHERE functionid = gt_confdet-functionid
       AND vrsio = sodvrsio.

      LOOP AT lt_functran.
        lr_tcode-low = lt_functran-tcode.
        APPEND lr_tcode.
      ENDLOOP.
    ENDLOOP.

    CALL FUNCTION '/PSYNG/SW_007'
         EXPORTING
              i_conid  = gt_conflict-conid
              i_vrsio  = sodvrsio
         TABLES
              it_tcode = lr_tcode.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_data.
  DATA : lf_invalid_chars TYPE flag,
         lt_rfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
         l_system_msg(72) TYPE c.
*---  get maintain rfc/system
  CLEAR: lt_rfcdes, lt_rfcdes[].
  SELECT SINGLE * FROM /psyng/sw_rfcdes INTO lt_rfcdes
  WHERE systid = p_system.

* if lt_rfcdes is initial.
*  MESSAGE s002(/psyng/sw) with 'Please enter valid System'(v01).
*  LEAVE LIST-PROCESSING.
* endif.

  gv_program = sy-repid.
*--Load sod matrix
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5.
        IF sy-subrc NE 0.
         CASE sy-subrc.
           WHEN OTHERS.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
         ENDCASE.
        ENDIF.
  CALL FUNCTION '/PSYNG/SW_028'
  DESTINATION lt_rfcdes-rfcdest
       EXPORTING
            i_vrsio     = sodvrsio
       TABLES
            it_spconfs  = spconfs
            it_bus_area = pappa
            it_imp      = csens
            it_cowner   = cowner
            it_risk     = s_risk
            it_functions = s_func
            it_contid   = cprmit
            et_conflict = gt_conflict
            et_confdet  = gt_confdet
        EXCEPTIONS
            communication_failure = 1
            system_failure        = 2
            OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
*BOC:HBHALLA (03/12/24)
         IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
               MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
            WHEN 2.
               MESSAGE s002(/psyng/sw) WITH 'System failure'.
            WHEN OTHERS.
               MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
          ENDCASE.
         ENDIF.
*EOC:HBHALLA (03/12/24)


  CHECK NOT gt_confdet[] IS INITIAL.
*  SELECT * FROM /psyng/function INTO TABLE gt_functions
*  FOR ALL ENTRIES IN gt_confdet
*  WHERE vrsio = sodvrsio
*    AND function = gt_confdet-functionid.
*---in SE4.3 taking function from remote
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
                  .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
  CALL FUNCTION '/PSYNG/SW_126'
  DESTINATION lt_rfcdes-rfcdest
   EXPORTING
     i_vrsio           = sodvrsio
     i_function        = 'X'
   TABLES
     it_confdet        = gt_confdet
     et_function       = gt_functions
   EXCEPTIONS
     communication_failure = 1 MESSAGE l_system_msg
     system_failure        = 2 MESSAGE l_system_msg
     OTHERS                = 3."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

*--FROM SE3.5, this report does support '-' in function id's
*  LOOP AT gt_functions WHERE function IN s_func.
*    if gt_functions-function cs '.' or
*       gt_functions-function cs '-'.
*       lf_invalid_chars = 'X'.
*       exit.
*     endif.
*  endloop.
*  if lf_invalid_chars = 'X'.
*    MESSAGE e002(/psyng/sw) WITH 'SOD Matrix Overview not'
*    'supported for functions that contain'
*    '"-" or "." characters'.
*  endif.

  CHECK NOT s_func[] IS INITIAL.
  REFRESH s_func1.
  s_func1[] = s_func[].

  s_func1-sign = 'I'.
  s_func1-option = 'EQ'.

  s_conf1-option = 'EQ'.
  s_conf1-sign = 'I'.

*-- Fetch Conids Involved for this function
  LOOP AT gt_confdet WHERE functionid IN s_func.
    s_conf1-low = gt_confdet-conid.
    APPEND s_conf1.
  ENDLOOP.

  SORT s_conf1 BY low.
  DELETE ADJACENT DUPLICATES FROM s_conf1.

  DELETE gt_confdet WHERE NOT conid IN s_conf1.


  LOOP AT gt_functions WHERE function IN s_func.
    LOOP AT gt_confdet WHERE functionid = gt_functions-function.
      LOOP AT gt_confdet WHERE conid    =  gt_confdet-conid.
        s_func1-low = gt_confdet-functionid.
        APPEND s_func1.
      ENDLOOP.
    ENDLOOP.
  ENDLOOP.



ENDFORM.                    " get_data


DEFINE clean_funid.
  while &1 cs '-'.
    replace '-' with '_' into &1.
  endwhile.
END-OF-DEFINITION.
*&---------------------------------------------------------------------*
*&      Form  output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM output.

  DATA:  lf_counterx TYPE i,
         ls_color TYPE lvc_s_scol,
         l_funfieldname  TYPE string.

*--Create ALV Field Catalog
  IF NOT gt_functions[] IS INITIAL.
    gs_fieldcat-fieldname = 'FUNCTION'.
    gs_fieldcat-seltext   = 'Function'.
    gs_fieldcat-intlen    = 100.
    gs_fieldcat-fix_column = 'X'.
    gs_fieldcat-emphasize = '0004'.
    APPEND gs_fieldcat TO gt_fieldcat.

    gs_fieldcat-fieldname = 'DESCRIPTION'.
    gs_fieldcat-seltext   = 'Description'.
    gs_fieldcat-intlen    = 100.
    gs_fieldcat-fix_column = 'X'.
    gs_fieldcat-emphasize = '0004'.
    APPEND gs_fieldcat TO gt_fieldcat.


    SORT gt_functions BY function.
    LOOP AT gt_functions WHERE function IN s_func1.

      gs_fieldcat-fieldname = gt_functions-function.
      clean_funid gs_fieldcat-fieldname.
      gs_fieldcat-seltext   = gt_functions-function.
      IF p_rid = 'X'.
        gs_fieldcat-intlen    = 12.
      ELSE.
        gs_fieldcat-intlen    = 80.
      ENDIF.
      gs_fieldcat-fix_column = 'X'.
      gs_fieldcat-emphasize = '0004'.
      gs_fieldcat-hotspot   = 'X'.
      APPEND gs_fieldcat TO gt_fieldcat.
    ENDLOOP.

    gs_fieldcat-tech = 'X'.
    gs_fieldcat-fieldname = 'COLORS'.
    gs_fieldcat-ref_field = 'COLTAB'.
    gs_fieldcat-ref_table = 'CALENDAR_TYPE'.
    gs_fieldcat-scrtext_s = gs_fieldcat-scrtext_m =
    gs_fieldcat-scrtext_l = 'COLOR'.
    APPEND gs_fieldcat TO gt_fieldcat.

*--Create a dynamic table to contain our data
    CALL METHOD cl_alv_table_create=>create_dynamic_table
    EXPORTING
      it_fieldcatalog           = gt_fieldcat
    IMPORTING
      ep_table                  = gr_table
    EXCEPTIONS
      generate_subpool_dir_full = 1
      OTHERS                    = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    ASSIGN gr_table->* TO <fs_tab>.
    CREATE DATA gr_rec LIKE LINE OF <fs_tab>.
    ASSIGN gr_rec->* TO <fs_o>.


*--Create matrix view
    LOOP AT gt_functions WHERE function IN s_func1.
      gt_matrix-funid_horizontal = gt_functions-function.
      LOOP AT gt_confdet WHERE functionid = gt_matrix-funid_horizontal.
        gt_matrix-conid = gt_confdet-conid.
        LOOP AT gt_confdet ASSIGNING <func>
        WHERE conid      =  gt_confdet-conid AND
              functionid <> gt_confdet-functionid.
          gt_matrix-funid_vertical =    <func>-functionid.


*--Check if record is in table in reverse
*          READ TABLE gt_matrix WITH KEY
*            funid_vertical   =  gt_matrix-funid_horizontal
*            funid_horizontal =  gt_matrix-funid_vertical
*            conid            =  gt_matrix-conid
*            TRANSPORTING NO FIELDS.
*          IF sy-subrc <> 0.
          READ TABLE gt_functions WITH KEY function =
                 gt_matrix-funid_horizontal.
          IF sy-subrc = 0.
            READ TABLE gt_functions WITH KEY function =
                   gt_matrix-funid_vertical.
            IF sy-subrc = 0.
              APPEND gt_matrix.
            ENDIF.
          ENDIF.
*          ENDIF.
        ENDLOOP.
        IF sy-subrc NE 0.
*-- Single Sided Conflict
          gt_matrix-funid_vertical = gt_confdet-functionid.
*          READ TABLE gt_matrix WITH KEY
*               funid_vertical   =  gt_matrix-funid_horizontal
*               funid_horizontal =  gt_matrix-funid_vertical
*               conid            =  gt_matrix-conid
*               TRANSPORTING NO FIELDS.
*          IF sy-subrc <> 0.
          READ TABLE gt_functions WITH KEY function =
                 gt_matrix-funid_horizontal.
          IF sy-subrc = 0.
            READ TABLE gt_functions WITH KEY function =
                   gt_matrix-funid_vertical.
            IF sy-subrc = 0.
              APPEND gt_matrix.
            ENDIF.
          ENDIF.
*          ENDIF.

        ENDIF.
      ENDLOOP.
    ENDLOOP.

*-- Count function for coloring purpose
    LOOP AT gt_confdet.
      AT NEW conid.
        CLEAR lf_counterx.
        LOOP AT gt_confdet WHERE conid = gt_confdet-conid.
          lf_counterx = lf_counterx + 1.
        ENDLOOP.
        IF lf_counterx GE 3.
          LOOP AT gt_matrix INTO gs_matrix12
          WHERE conid = gt_confdet-conid.
            gs_colors-fname = gs_matrix12-funid_horizontal.
            gs_colors-color-col = 6.
            gs_colors-color-int = 0.
            APPEND gs_colors TO gs_matrix12-it_colors.
            MODIFY gt_matrix FROM gs_matrix12 TRANSPORTING it_colors.
            CLEAR lf_counterx.
            REFRESH gs_matrix12-it_colors.
          ENDLOOP.
        ENDIF.
      ENDAT.
    ENDLOOP.

    SORT gt_matrix BY funid_horizontal funid_vertical.
*--Make sure we display everything in the lower left triangle

    DATA : l_funid TYPE /psyng/function_id.
    SORT gt_matrix BY  funid_horizontal funid_vertical .
    LOOP AT gt_functions WHERE function IN s_func1.
      LOOP AT gt_matrix WHERE funid_vertical = gt_functions-function.

       ASSIGN COMPONENT 'FUNCTION' OF STRUCTURE <fs_o> TO <fs_dynfield>.
        <fs_dynfield> = gt_functions-function.
        UNASSIGN <fs_dynfield>.

    ASSIGN COMPONENT 'DESCRIPTION' OF STRUCTURE <fs_o> TO <fs_dynfield>.
        <fs_dynfield> = gt_functions-description(80).
        UNASSIGN <fs_dynfield>.

       ASSIGN COMPONENT 'FUNCTION' OF STRUCTURE <fs_o> TO <fs_dynfield>.

        <fs_dynfield> =  gt_matrix-funid_vertical.
        UNASSIGN <fs_dynfield>.
        l_funfieldname = gt_matrix-funid_horizontal.
        clean_funid l_funfieldname.
*        ASSIGN COMPONENT gt_matrix-funid_horizontal OF STRUCTURE
        ASSIGN COMPONENT l_funfieldname OF STRUCTURE
           <fs_o> TO <fs_dynfield>.
        IF NOT <fs_dynfield> IS INITIAL.
*--This should handle combinations that are in more than 1 conflict,
*  not sure if it works correctly
          APPEND <fs_o> TO <fs_tab>.
          CLEAR <fs_o>.
          IF NOT <ta_color> IS INITIAL.
            REFRESH <ta_color>.
          ENDIF.


       ASSIGN COMPONENT 'FUNCTION' OF STRUCTURE <fs_o> TO <fs_dynfield>.
          <fs_dynfield> = gt_functions-function.
          UNASSIGN <fs_dynfield>.

    ASSIGN COMPONENT 'DESCRIPTION' OF STRUCTURE <fs_o> TO <fs_dynfield>.
          <fs_dynfield> = gt_functions-description(80).
          UNASSIGN <fs_dynfield>.

       ASSIGN COMPONENT 'FUNCTION' OF STRUCTURE <fs_o> TO <fs_dynfield>.

          <fs_dynfield> =  gt_matrix-funid_vertical.
          UNASSIGN <fs_dynfield>.

        ENDIF.

        ASSIGN COMPONENT l_funfieldname OF STRUCTURE
         <fs_o> TO <fs_dynfield>.
        IF p_rid = 'X'.
          <fs_dynfield> = gt_matrix-conid.
        ELSEIF p_rtext = 'X'.
          READ TABLE gt_conflict WITH KEY conid = gt_matrix-conid.
          IF sy-subrc = 0.
            CONCATENATE gt_matrix-conid '-' gt_conflict-description(65)
                      INTO <fs_dynfield> SEPARATED BY space.
          ENDIF.
        ELSE.
          READ TABLE gt_conflict WITH KEY conid = gt_matrix-conid.
          IF sy-subrc = 0.
            IF NOT gt_conflict-imp IS INITIAL.
              CONCATENATE gt_matrix-conid '-' gt_conflict-imp
                INTO <fs_dynfield> SEPARATED BY space.
            ELSE.
              CONCATENATE gt_matrix-conid '-' 'NA'
               INTO <fs_dynfield> SEPARATED BY space.
            ENDIF.
          ENDIF.
        ENDIF.

        UNASSIGN <fs_dynfield>.
        ASSIGN COMPONENT  'COLORS' OF STRUCTURE
         <fs_o> TO <ta_color>.

*-- Pass Color Values
        LOOP AT gt_matrix-it_colors INTO ls_color
        WHERE fname = gt_matrix-funid_horizontal.
          APPEND ls_color TO <ta_color>.
        ENDLOOP.
      ENDLOOP.
      IF sy-subrc = 0.
        APPEND <fs_o> TO <fs_tab>.
        REFRESH <ta_color>.
        CLEAR <fs_o>.
      ENDIF.
    ENDLOOP.

    IF <fs_tab>[] IS INITIAL.
      MESSAGE s002(/psyng/sw) WITH
           'No Data found for the corresponding input'(003).
      LEAVE LIST-PROCESSING.
      else.
       MESSAGE s002(/psyng/sw) WITH
           'Data loaded'(004).
    ENDIF.

*--Create a field catalog
    LOOP AT gt_fieldcat INTO gs_fieldcat.
      MOVE-CORRESPONDING gs_fieldcat TO gs_fieldcat_alv.
      gs_fieldcat_alv-seltext_s = gs_fieldcat-seltext.
      gs_fieldcat_alv-seltext_m = gs_fieldcat-seltext.
      gs_fieldcat_alv-seltext_l = gs_fieldcat-seltext.
      gs_fieldcat_alv-do_sum = 'X'.
      APPEND gs_fieldcat_alv TO gt_fieldcat_alv.
    ENDLOOP.

    gs_layout-zebra = 'X'.
    gs_layout-colwidth_optimize = 'X'.
    gs_layout-coltab_fieldname = 'COLORS'.

*--Output ALV
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
         EXPORTING
              it_fieldcat             = gt_fieldcat_alv[]
              is_layout               = gs_layout
              i_callback_program      = gv_program
              i_callback_user_command = 'CONFLICT_HOTSPOT'
         TABLES
              t_outtab                = <fs_tab>
         EXCEPTIONS
              program_error           = 1
              OTHERS                  = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    REFRESH s_func1.
  ELSE.
    MESSAGE s002(/psyng/sw) WITH
     'No Data found for the corresponding input'(003).
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.                    " output

*---------------------------------------------------------------------*
*       FORM f4_system                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  FIELDNAME                                                     *
*  -->  E_VALUE                                                       *
*---------------------------------------------------------------------*
FORM f4_system USING    fieldname
                 CHANGING e_value.

  DATA: BEGIN OF lt_values OCCURS 0,
            line(255) TYPE c,
          END OF lt_values.
  DATA: lt_fields    TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return    TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_sw_rfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE.

  SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_sw_rfcdes.
  LOOP AT lt_sw_rfcdes.
    lt_values-line = lt_sw_rfcdes-rfcdest.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-rfcname.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-description.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-systid.
    APPEND lt_values.
  ENDLOOP.

  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'RFCDEST'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'RFCNAME'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'DESCRIPTION'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYSTID'.
  APPEND lt_fields.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield        = 'SYSTID'
       TABLES
            value_tab       = lt_values
            field_tab       = lt_fields
            return_tab      = lt_return
       EXCEPTIONS
            parameter_error = 1
            no_values_found = 2
            OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_value = lt_return-fieldval.
ENDFORM.
