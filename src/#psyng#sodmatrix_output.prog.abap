*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SODREPORT
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sodmatrix_output LINE-SIZE 255.


***Type pools Declaration.

TYPE-POOLS: slis.                                      "For ALV call

*******Add Global Class
CLASS /PSYNG/SW_CL_CONSTANTS DEFINITION LOAD.    "To check missing text


*Global Declarations for alv

DATA: g_program         LIKE sy-repid.                   "For ALV call

DATA: g_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call

DATA: g_sort TYPE STANDARD TABLE OF slis_sortinfo_alv.

*****Global table for Conflict Details

DATA: gt_confdet TYPE SORTED TABLE OF /psyng/confdet WITH UNIQUE KEY
              conid functionid
              WITH HEADER LINE.

*****Global table for Conflict Header

DATA: gt_conflict TYPE SORTED TABLE OF /psyng/conflict WITH UNIQUE KEY
              conid
              WITH HEADER LINE.

*****Global table for Function Details

DATA: gt_functtran TYPE SORTED TABLE OF /psyng/functtran WITH UNIQUE KEY
               functionid tcode
               WITH HEADER LINE.

*****Global table for Function  Header
DATA: gt_function TYPE SORTED TABLE OF /psyng/function WITH UNIQUE KEY
               function
               WITH HEADER LINE.

*****Global table for  Transactions
DATA: gt_tstct TYPE SORTED TABLE OF tstct WITH UNIQUE KEY
             tcode
             WITH HEADER LINE.

*****Global workarea for  Transactions

DATA: g_wa_tstct TYPE tstct.

********************************************

*****Global table for  Objects
DATA: gt_faobj2 TYPE SORTED TABLE OF /psyng/faobj2 WITH UNIQUE KEY
            funid tcode object valueset field val_from val_to
             WITH HEADER LINE.

***Declaration for Final output internal table
DATA: BEGIN OF gt_output OCCURS 0,
        l_conid        LIKE /psyng/conflict-conid,
        l_cdescription LIKE /psyng/conflict-description,
        l_functionid   LIKE /psyng/confdet-functionid,
        l_fdescription LIKE /psyng/function-description,
        l_tcode        LIKE tstc-tcode,
        l_tdescription LIKE tstct-ttext,
        l_object      LIKE /psyng/faobj2-object,
        l_valueset    LIKE /psyng/faobj2-valueset,
        l_field       LIKE /psyng/faobj2-field,
        l_val_from    LIKE /psyng/faobj2-val_from,
        l_val_to      LIKE /psyng/faobj2-val_to,
        l_obj_or      LIKE /psyng/faobj2-obj_or,
        fld_and        LIKE /psyng/faobj2-fld_and,
      END OF gt_output.

**********************************************
*Option for answer whether  Output IN  ALV OR Stndard format

*DATA: g_answer.


**SELECTION-SCREEN DETAILS

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.

PARAMETERS: p_vrsio LIKE /psyng/functtran-vrsio.

SELECTION-SCREEN END OF BLOCK blk1.

INITIALIZATION.

  PERFORM exelog.

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
*--Register report for Most Used Reports
  CALL FUNCTION '/PSYNG/SW_128'
  EXPORTING
  i_repid       = '/PSYNG/SODMATRIX_OUTPUT'.


  REFRESH:gt_confdet,gt_conflict,gt_functtran,gt_function,gt_faobj2.
  CLEAR:gt_confdet,gt_conflict,gt_functtran,gt_function,gt_faobj2.

***Fetching required data into global tables

  SELECT * FROM /psyng/confdet INTO TABLE gt_confdet WHERE
                                      vrsio = p_vrsio.

*  SELECT * FROM /psyng/conflict INTO TABLE gt_conflict
*         WHERE vrsio = p_vrsio.
  SELECT conid description FROM /psyng/conflict
    INTO CORRESPONDING FIELDS OF TABLE gt_conflict
         WHERE vrsio = p_vrsio.

  SELECT * FROM /psyng/functtran INTO TABLE gt_functtran
         WHERE vrsio = p_vrsio.

*  SELECT * FROM /psyng/function
*     INTO TABLE gt_function
*         WHERE vrsio = p_vrsio.

  SELECT function description FROM /psyng/function
     INTO CORRESPONDING FIELDS OF TABLE gt_function
         WHERE vrsio = p_vrsio.


************************************************************

  SELECT * FROM /psyng/faobj2  INTO TABLE gt_faobj2
           WHERE vrsio = p_vrsio.

  LOOP AT gt_functtran.
    SELECT SINGLE * FROM tstct
                    INTO g_wa_tstct
                    WHERE sprsl = sy-langu AND
                          tcode = gt_functtran-tcode.
    IF sy-subrc = 0.
      INSERT g_wa_tstct INTO TABLE gt_tstct.
    ELSE.
      SELECT SINGLE * FROM tstct
                    INTO g_wa_tstct
                    WHERE sprsl = sy-langu AND
                          tcode = gt_functtran-tcode.
      IF sy-subrc = 0.
        INSERT g_wa_tstct INTO TABLE gt_tstct.
      ELSE.
*********Case#1994
        IF gt_functtran-tcode  CP
            /psyng/sw_cl_constants=>placeholder_tcode_prefix.
          g_wa_tstct-ttext =
          'Placeholder for objectlevel analysis'(191).
        ELSE.
          g_wa_tstct-ttext =
          'Tcode for cross system analysis'(192).
        ENDIF.
        g_wa_tstct-tcode = gt_functtran-tcode.
*        g_wa_tstct-ttext = text-006.
        INSERT g_wa_tstct INTO TABLE gt_tstct.
      ENDIF.
      CLEAR  g_wa_tstct.
    ENDIF.
  ENDLOOP.

***************************************

*  IF g_answer = '1'." for ALV output

*************************************

  PERFORM format_and_output_alv.

*************************************
*  ELSEIF g_answer = '2'." for Standard output
*
****************************************
*    PERFORM format_stand_output.
*  ENDIF.

TOP-OF-PAGE.

***Printing filed names in output for standard output

  WRITE:/ text-007, text-008, 83 text-009,
        95 text-010, 145 text-011,
        165 text-012, 202 text-023,213 text-025,
        224 text-027, 230 text-029 ,241 text-031,
        250 text-033.


*&---------------------------------------------------------------------*
*&      Form  BUILD_ALV_STUFF
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_stuff.

  DATA: l_wa_fieldcat_alv TYPE slis_fieldcat_alv,
         l_sort            TYPE slis_sortinfo_alv.


  l_wa_fieldcat_alv-seltext_l = text-007.
  l_wa_fieldcat_alv-seltext_m = text-013.
  l_wa_fieldcat_alv-seltext_s = text-014.
  l_wa_fieldcat_alv-reptext_ddic = text-013.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_CONID'.



  l_wa_fieldcat_alv-seltext_l = text-008.
  l_wa_fieldcat_alv-seltext_m = text-015.
  l_wa_fieldcat_alv-seltext_s = text-015.
  l_wa_fieldcat_alv-reptext_ddic = text-015.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_CDESCRIPTION'.



  l_wa_fieldcat_alv-seltext_l = text-009.
  l_wa_fieldcat_alv-seltext_m = text-016.
  l_wa_fieldcat_alv-seltext_s = text-017.
  l_wa_fieldcat_alv-reptext_ddic = text-016.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_FUNCTIONID'.



  l_wa_fieldcat_alv-seltext_l = text-010.
  l_wa_fieldcat_alv-seltext_m = text-018.
  l_wa_fieldcat_alv-seltext_s = text-018.
  l_wa_fieldcat_alv-reptext_ddic = text-018.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_FDESCRIPTION'.


  l_wa_fieldcat_alv-seltext_l = text-023.
  l_wa_fieldcat_alv-seltext_m = text-024.
  l_wa_fieldcat_alv-seltext_s = text-024.
  l_wa_fieldcat_alv-reptext_ddic = text-024.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_OBJECT'.



  l_wa_fieldcat_alv-seltext_l = text-025.
  l_wa_fieldcat_alv-seltext_m = text-026.
  l_wa_fieldcat_alv-seltext_s = text-026.
  l_wa_fieldcat_alv-reptext_ddic = text-026.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_VALUESET'.




  l_wa_fieldcat_alv-seltext_l = text-027.
  l_wa_fieldcat_alv-seltext_m = text-028.
  l_wa_fieldcat_alv-seltext_s = text-028.
  l_wa_fieldcat_alv-reptext_ddic = text-028.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_FIELD'.



  l_wa_fieldcat_alv-seltext_l = text-029.
  l_wa_fieldcat_alv-seltext_m = text-030.
  l_wa_fieldcat_alv-seltext_s = text-030.
  l_wa_fieldcat_alv-reptext_ddic = text-030.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_VAL_FROM'.



  l_wa_fieldcat_alv-seltext_l = text-031.
  l_wa_fieldcat_alv-seltext_m = text-032.
  l_wa_fieldcat_alv-seltext_s = text-032.
  l_wa_fieldcat_alv-reptext_ddic = text-032.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_VAL_TO'.



  l_wa_fieldcat_alv-seltext_l = text-033.
  l_wa_fieldcat_alv-seltext_m = text-034.
  l_wa_fieldcat_alv-seltext_s = text-034.
  l_wa_fieldcat_alv-reptext_ddic = text-034.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_OBJ_OR'.

  l_wa_fieldcat_alv-seltext_l = text-035.
  l_wa_fieldcat_alv-seltext_m = text-036.
  l_wa_fieldcat_alv-seltext_s = text-036.
  l_wa_fieldcat_alv-reptext_ddic = text-036.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'FLD_AND'.

  CLEAR: l_sort, g_sort.
  REFRESH: g_sort.

  l_sort-spos = '1'.
  l_sort-fieldname = 'L_CONID'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'L_CDESCRIPTION'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'L_FUNCTIONID'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '4'.
  l_sort-fieldname = 'L_FDESCRIPTION'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '5'.
  l_sort-fieldname = 'L_TCODE'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

*  l_sort-spos = '6'.
*  l_sort-fieldname = 'L_TDESCRIPTION'.
*  l_sort-tabname = 'GT_OUTPUTS'.
*  APPEND l_sort TO g_sort.


  l_sort-spos = '7'.
  l_sort-fieldname = 'L_OBJECT'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.


  l_sort-spos = '8'.
  l_sort-fieldname = 'L_VALUESET'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.


  l_sort-spos = '9'.
  l_sort-fieldname = 'L_FIELD'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.


  l_sort-spos = '10'.
  l_sort-fieldname = 'L_VAL_FROM'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.


  l_sort-spos = '11'.
  l_sort-fieldname = 'L_VAL_TO'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.


  l_sort-spos = '12'.
  l_sort-fieldname = 'L_OBJ_OR'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

ENDFORM.                    " BUILD_ALV_STUFF
*&---------------------------------------------------------------------*
*&      Form  format_and_output_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM format_and_output_alv.

****Local stracture for final output

  TYPES: BEGIN OF ls_output_typ,
            l_conid        LIKE /psyng/conflict-conid,
            l_cdescription LIKE /psyng/conflict-description,
            l_functionid   LIKE /psyng/confdet-functionid,
            l_fdescription LIKE /psyng/function-description,
            l_tcode        LIKE tstc-tcode,
            l_tdescription LIKE tstct-ttext,
            l_object       LIKE /psyng/faobj2-object,
            l_valueset     LIKE /psyng/faobj2-valueset,
            l_field        LIKE /psyng/faobj2-field,
            l_val_from     LIKE /psyng/faobj2-val_from,
            l_val_to       LIKE /psyng/faobj2-val_to,
            l_obj_or       LIKE /psyng/faobj2-obj_or,
            fld_and        LIKE /psyng/faobj2-fld_and,
           END OF ls_output_typ.


  DATA: l_alv_layout    TYPE slis_layout_alv,
        l_alv_grid_titl TYPE lvc_title,
        ls_variant    TYPE disvariant,
        l_date(10),
        l_wa_output     TYPE ls_output_typ,
        lt_output     TYPE SORTED TABLE OF ls_output_typ WITH UNIQUE KEY
                      l_conid l_cdescription l_functionid l_fdescription
                      l_tcode l_object l_valueset l_field l_val_from
                      l_val_to
                      WITH HEADER LINE.

************************************************************************
  LOOP AT gt_confdet.
    READ TABLE gt_conflict WITH KEY conid = gt_confdet-conid.
    LOOP AT gt_functtran WHERE functionid = gt_confdet-functionid.
     READ TABLE gt_function WITH KEY function = gt_functtran-functionid.
      READ TABLE gt_tstct WITH KEY tcode = gt_functtran-tcode.

*******************************************************
*DHORIONS 05/10/2011 - Display all details
*      READ TABLE gt_faobj2  WITH KEY funid = gt_functtran-functionid
*                                   tcode = gt_functtran-tcode.
      LOOP AT  gt_faobj2  WHERE funid = gt_functtran-functionid AND
                                   tcode = gt_functtran-tcode.
        l_wa_output-l_conid        = gt_confdet-conid.
        l_wa_output-l_cdescription = gt_conflict-description.
        l_wa_output-l_functionid   = gt_functtran-functionid.
        l_wa_output-l_fdescription = gt_function-description.
        l_wa_output-l_tcode        = gt_functtran-tcode.
        l_wa_output-l_tdescription = gt_tstct-ttext.


**********************************************************
        l_wa_output-l_object     =  gt_faobj2-object.
        l_wa_output-l_valueset   =  gt_faobj2-valueset.
        l_wa_output-l_field      =  gt_faobj2-field.
        l_wa_output-l_val_from   =  gt_faobj2-val_from.
        l_wa_output-l_val_to     =  gt_faobj2-val_to.
        l_wa_output-l_obj_or     =  gt_faobj2-obj_or.
        l_wa_output-fld_and      =  gt_faobj2-fld_and.

************************************************************
        INSERT l_wa_output INTO TABLE lt_output.

        CLEAR l_wa_output.
      ENDLOOP.
      IF sy-subrc <> 0.
        CLEAR l_wa_output.
        l_wa_output-l_conid        = gt_confdet-conid.
        l_wa_output-l_cdescription = gt_conflict-description.
        l_wa_output-l_functionid   = gt_functtran-functionid.
        l_wa_output-l_fdescription = gt_function-description.
        l_wa_output-l_tcode        = gt_functtran-tcode.
        l_wa_output-l_tdescription = gt_tstct-ttext.
        INSERT l_wa_output INTO TABLE lt_output.
      ENDIF.
    ENDLOOP.
    IF sy-subrc <> 0.
      CLEAR l_wa_output.
      l_wa_output-l_conid        = gt_confdet-conid.
      l_wa_output-l_cdescription = gt_conflict-description.
      l_wa_output-l_functionid   = gt_functtran-functionid.
      l_wa_output-l_fdescription = text-019.
      INSERT l_wa_output INTO TABLE lt_output.
    ENDIF.
  ENDLOOP.


  REFRESH gt_output.
  CLEAR   gt_output.


  gt_output[] = lt_output[].

  REFRESH lt_output.

  CLEAR   lt_output.

  g_program = sy-repid.

  l_alv_layout-zebra = 'X'.
  l_alv_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'GT_OUTPUT'
            i_inclname         = g_program
       CHANGING
            ct_fieldcat        = g_fieldcat_alv
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

**************************************************

  PERFORM build_alv_stuff.

  WRITE sy-datum TO l_date.

  CONCATENATE text-020 p_vrsio text-022 l_date
                INTO l_alv_grid_titl SEPARATED BY space.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title           = l_alv_grid_titl
            i_callback_program     = g_program
            i_callback_top_of_page = 'ALV_HEADER'
            it_sort                = g_sort
            is_layout              = l_alv_layout
            it_fieldcat            = g_fieldcat_alv
            i_save                 = 'A'
            is_variant             = ls_variant
       TABLES
            t_outtab               = gt_output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.


ENDFORM.                    " format_and_output_alv


*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        l_date(12) TYPE c.

  wa-typ = 'H'.
  wa-info = 'SOD Matrix in Security Weaver'(h01).
  APPEND wa TO header.
*SOD Version.
  wa-typ = 'S'.
  wa-key = 'Sod Version'(h02).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = p_vrsio.
  CONCATENATE p_vrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*Date
  wa-typ = 'S'.
  wa-key = 'Date'(h03).
  WRITE sy-datum TO l_date.
  wa-info = l_date.
  APPEND wa TO header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = header.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  format_stand_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM format_stand_output.


  WRITE:/ text-021, sy-datum.
  ULINE.

  LOOP AT gt_confdet.
    AT NEW conid.
      ULINE.
      SKIP 2.
      WRITE:/ gt_confdet-conid.
      READ TABLE gt_conflict WITH KEY conid = gt_confdet-conid
                                            BINARY SEARCH.
      IF sy-subrc = 0.
        WRITE: 12 gt_conflict-description.
      ENDIF.
    ENDAT.
    LOOP AT gt_functtran WHERE functionid = gt_confdet-functionid.
      AT NEW functionid.
        WRITE:/83 gt_functtran-functionid.
        READ TABLE gt_function WITH KEY
                            function = gt_functtran-functionid
             BINARY SEARCH.
        IF sy-subrc = 0.
          WRITE: 95 gt_function-description.
        ENDIF.
      ENDAT.
********************************************************

      WRITE:/145 gt_functtran-tcode.
      READ TABLE gt_tstct WITH KEY tcode = gt_functtran-tcode
                                BINARY SEARCH.
      IF sy-subrc = 0.
        WRITE:165 gt_tstct-ttext.
      ENDIF.

*************************************************************
      READ TABLE gt_faobj2  WITH KEY funid = gt_functtran-functionid
                           tcode = gt_functtran-tcode  BINARY SEARCH.

      IF sy-subrc = 0.
        WRITE:202 gt_faobj2-object.
        WRITE:214 gt_faobj2-valueset.
        WRITE:223 gt_faobj2-field.
        WRITE:230 gt_faobj2-val_from.
        WRITE:241 gt_faobj2-val_to.
        WRITE:250 gt_faobj2-obj_or.
      ENDIF.


***************************************************************
    ENDLOOP.
    IF sy-subrc <> 0.
      WRITE:/83 gt_confdet-functionid.
      WRITE: 95 text-019.
    ENDIF.
  ENDLOOP.

**************************************************************
ENDFORM.                    " format_stand_output
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE,
        l_current_user TYPE sy-uname. "C0700
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 29.03.22 for C0700

  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = l_current_user."sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.
  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = exelog.
  COMMIT WORK.
ENDFORM.                    " exelog
