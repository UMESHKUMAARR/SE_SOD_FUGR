*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_075
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

REPORT /psyng/sw_075 .
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /PSYNG/BASIS_EXELOG.

TYPE-POOLS: slis.                                      "For ALV call
DATA: BEGIN OF gt_out OCCURS 0,
         sel          TYPE c,
         imp          LIKE /psyng/conflict-imp,
         conid        LIKE /psyng/conflict-conid,
         functionid   LIKE /psyng/functtran-functionid,
         tcode        LIKE /psyng/faobj2-tcode,
         enh_tcode    LIKE /psyng/faobj2-tcode,
         objct        LIKE ust12-objct,
         obj_or       LIKE  /psyng/faobj2-obj_or,
         fld_and      like /psyng/faobj2-fld_and,
         valueset     LIKE /psyng/faobj2-valueset,
         field        LIKE ust12-field,
         von          LIKE ust12-von,
         bis          LIKE ust12-bis,
         description  LIKE /psyng/conflict-description,
         enh(1)       TYPE c,
         color_line(4) TYPE c,
      END OF gt_out.

DATA: gt_conflict_fm   TYPE STANDARD TABLE OF /psyng/conflict,
      gt_confdet_fm    TYPE STANDARD TABLE OF /psyng/confdet,
      gt_functtran_fm  TYPE STANDARD TABLE OF /psyng/functtran,
      gt_faobj_fm      TYPE STANDARD TABLE OF /psyng/faobj2,
      gt_tcodes_fm     TYPE STANDARD TABLE OF /psyng/sw_par_tcode_output
                    WITH HEADER LINE,
      gs_out        LIKE LINE OF gt_out                   ,
      g_program       LIKE sy-repid.
DATA: gt_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
      gs_fieldcat_alv   TYPE slis_fieldcat_alv,
      gt_sort          TYPE STANDARD TABLE OF slis_sortinfo_alv,
      g_sort           TYPE slis_sortinfo_alv,
      g_alv_layout       TYPE slis_layout_alv,
      gs_variant       TYPE disvariant,
      gs_tcode         TYPE tcode,
      gs_conid         TYPE /psyng/conflict_id,
     gt_functran_no_enh TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
     gf_tcode_enhanced TYPE flag,
     l_repid LIKE sy-repid.

*indexes
DATA : g_confdet_idx TYPE i,
       g_faobj_idx   TYPE i,
       g_tcode_idx   TYPE i,
       gs_swconfig TYPE /psyng/swconfig,
       gt_excltx TYPE TABLE OF /psyng/sw_excltx WITH HEADER LINE,
       l_num type i.

FIELD-SYMBOLS : <con>       TYPE /psyng/conflict,
                <confdet>   TYPE /psyng/confdet,
                <functtran> TYPE /psyng/functtran,
                <faobj>     TYPE /psyng/faobj2,
                <tcode>     TYPE /psyng/sw_par_tcode_output.



*SELECTION SCREEN.
SELECTION-SCREEN: BEGIN OF BLOCK ver WITH FRAME TITLE text-001.
PARAMETERS : vrsio TYPE   /psyng/sodvrsio .
SELECT-OPTIONS : s_callin FOR gs_tcode.
SELECT-OPTIONS : conid   FOR gs_conid.

SELECTION-SCREEN: END OF BLOCK ver .
SELECTION-SCREEN: BEGIN OF BLOCK enh WITH FRAME TITLE text-002.
PARAMETERS : enh TYPE flag. "only enhanced
PARAMETERS : highl TYPE flag. "highlight enhanced
SELECTION-SCREEN: END OF BLOCK enh .

INITIALIZATION.

  CALL FUNCTION '/PSYNG/SW_034'
       IMPORTING
            e_vrsio = vrsio.


  SELECT * FROM /psyng/sw_excltx INTO CORRESPONDING FIELDS OF
  TABLE gt_excltx.
  LOOP AT gt_excltx.
    MOVE-CORRESPONDING gt_excltx TO s_callin.
    s_callin-option = gt_excltx-type.
    APPEND s_callin.
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
*--Log the execution.
*  2 options : by a single transaction, or in any different way
  describe table s_callin lines l_num.
  if l_num = 1.
    EXELOG sy-repid 'BY_TCODE'.
  else.
    EXELOG sy-repid ''.
  endif.

*Read the enhanced matrix
  CALL FUNCTION '/PSYNG/SW_028'
       EXPORTING
            i_vrsio            = vrsio
            i_enhance          = 'X'
       TABLES
            it_spconfs         = conid
            et_conflict        = gt_conflict_fm
            et_confdet         = gt_confdet_fm
            et_functtran       = gt_functtran_fm
            et_faobj           = gt_faobj_fm
            et_tcodes          = gt_tcodes_fm
            et_functran_no_enh = gt_functran_no_enh.
  SORT gt_functran_no_enh BY functionid tcode.
  SORT gt_faobj_fm BY
  tcode    object field valueset val_from val_to .
  MESSAGE s138(/psyng/sw) WITH
  'Dynamic SOD matrix enhancement complete'(005).

*ignore empty records
  DELETE  gt_functtran_fm WHERE functionid = ''.
  DELETE  gt_conflict_fm  WHERE conid = ''.
*Write enhanced matrix to output table
  LOOP AT gt_conflict_fm ASSIGNING <con>.
    LOOP AT gt_confdet_fm ASSIGNING <confdet> FROM  g_confdet_idx
      WHERE conid = <con>-conid .
      g_confdet_idx = sy-tabix.
      LOOP AT gt_faobj_fm ASSIGNING <faobj> " FROM  g_faobj_idx
        WHERE funid = <confdet>-functionid .

        gs_out-imp         = <con>-imp.
        gs_out-conid       = <con>-conid.
        gs_out-functionid  = <confdet>-functionid.
        gs_out-tcode       = <faobj>-tcode.
        gs_out-objct       = <faobj>-object.
        gs_out-obj_or      = <faobj>-obj_or.
        gs_out-valueset    = <faobj>-valueset.
        gs_out-field       = <faobj>-field.
        gs_out-von         = <faobj>-val_from.
        gs_out-bis         = <faobj>-val_to.
        gs_out-fld_and     = <faobj>-fld_and.
        gs_out-description = <con>-description.
        CLEAR gf_tcode_enhanced.
        READ TABLE gt_tcodes_fm WITH KEY
        calling_tcode = <faobj>-tcode
        TRANSPORTING NO FIELDS.
        g_tcode_idx = sy-tabix
        .

        IF sy-subrc = 0.
*--DHORIONS : check if tcode was not already part of function
          READ TABLE gt_functran_no_enh
          WITH KEY functionid = <confdet>-functionid
                   tcode = <faobj>-tcode
                   BINARY SEARCH.
          IF sy-subrc <> 0.
            gf_tcode_enhanced = 'X'.
          ENDIF.
        ENDIF.
        IF gf_tcode_enhanced IS INITIAL.
*                 Tcode not affected by enhancement
          CLEAR gs_out-color_line .
          CLEAR : gs_out-enh, gs_out-enh_tcode.
        ELSE.
*                 Tcode  affected by enhancement
          IF highl = 'X'.
            gs_out-color_line  = 'C700'.
          ENDIF.
          gs_out-enh = 'X'.
*                get all called tcodes
          LOOP AT gt_tcodes_fm FROM g_tcode_idx WHERE
            calling_tcode = <faobj>-tcode
            .
            gs_out-enh_tcode = gt_tcodes_fm-called_tcode.
*--Dhorions 2015/06/11 - Only show Objects and values that were
*                        tied to original tcode.
            READ TABLE gt_faobj_fm WITH KEY
                       tcode    = gt_tcodes_fm-called_tcode
                       object   = <faobj>-object
                       field    = <faobj>-field
                       valueset = <faobj>-valueset
                       val_from = <faobj>-val_from
                       val_to   = <faobj>-val_to
                       BINARY SEARCH
                       TRANSPORTING NO FIELDS.
            IF sy-subrc = 0.
              APPEND gs_out TO gt_out.
            ELSE.
*-Remove next line, only for setting breakpoint.
              gs_out = gs_out.
            ENDIF.
          ENDLOOP.
        ENDIF.
        IF  enh <> 'X' AND gs_out-enh <> 'X'.
          APPEND gs_out TO gt_out.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDLOOP.

  DELETE gt_out WHERE NOT tcode  IN s_callin.


  g_program = sy-repid.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'GT_OUT'
*              I_STRUCTURE_NAME   = 'LS_OUT'
            i_inclname         = g_program
       CHANGING
            ct_fieldcat        = gt_fieldcat_alv
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

  READ TABLE gt_fieldcat_alv INTO gs_fieldcat_alv
      WITH KEY fieldname = 'OBJ_OR'.
  gs_fieldcat_alv-seltext_l = 'OR?'.
  gs_fieldcat_alv-no_out = 'X'.

  MODIFY gt_fieldcat_alv
  FROM gs_fieldcat_alv  TRANSPORTING
  seltext_l no_out WHERE fieldname = 'OBJ_OR'.





  READ TABLE gt_fieldcat_alv INTO gs_fieldcat_alv
      WITH KEY fieldname = 'ENH'.
  gs_fieldcat_alv-checkbox = 'X'.
  gs_fieldcat_alv-seltext_s =
  gs_fieldcat_alv-seltext_m =
  gs_fieldcat_alv-seltext_l = 'Enhanced'(006).
  gs_fieldcat_alv-just = 'X'.
  MODIFY gt_fieldcat_alv
  FROM gs_fieldcat_alv  TRANSPORTING
  checkbox just seltext_l seltext_s seltext_m WHERE fieldname = 'ENH'.
  READ TABLE gt_fieldcat_alv INTO gs_fieldcat_alv
      WITH KEY fieldname = 'ENH_TCODE'.
  gs_fieldcat_alv-seltext_s = 'Called'(007).
  gs_fieldcat_alv-seltext_m = 'Called'(007).
  gs_fieldcat_alv-seltext_l = 'Called Tcode'(003).

  MODIFY gt_fieldcat_alv
  FROM gs_fieldcat_alv  TRANSPORTING
  seltext_l seltext_s seltext_m
  WHERE fieldname = 'ENH_TCODE'.

  READ TABLE gt_fieldcat_alv INTO gs_fieldcat_alv
      WITH KEY fieldname = 'TCODE'.
  gs_fieldcat_alv-seltext_s = 'Calling'(008).
  gs_fieldcat_alv-seltext_m = 'Calling'(008).
  gs_fieldcat_alv-seltext_l = 'Calling Tcode'(004).
  gs_fieldcat_alv-hotspot   = 'X'.
  MODIFY gt_fieldcat_alv
  FROM gs_fieldcat_alv  TRANSPORTING
  seltext_l seltext_s seltext_m hotspot
  WHERE fieldname = 'TCODE'.

*--Mark the select field
  READ TABLE gt_fieldcat_alv INTO gs_fieldcat_alv
      WITH KEY fieldname = 'SEL'.
*  gs_fieldcat_alv-checkbox = 'X'.
*  gs_fieldcat_alv-edit     = 'X'.
  gs_fieldcat_alv-seltext_s = 'Select'(009).
  gs_fieldcat_alv-seltext_m = 'Select for Function'(010).
  gs_fieldcat_alv-seltext_l = 'Select for Addition to Function'(011).
  gs_fieldcat_alv-no_out    = 'X'.
  MODIFY gt_fieldcat_alv
  FROM gs_fieldcat_alv  TRANSPORTING
  checkbox edit seltext_l seltext_s seltext_m no_out
  WHERE fieldname = 'SEL'.


  CLEAR: g_sort, gt_sort.
  REFRESH: gt_sort.
  add 1 to g_sort-spos.
  g_sort-fieldname = 'IMP'.
  g_sort-tabname = 'OUTPUTDET4'.
  g_sort-up = 'X'.
  APPEND g_sort TO gt_sort.


  add 1 to g_sort-spos.
  g_sort-fieldname = 'CONID'.
  g_sort-tabname = 'OUTPUTDET4'.
  g_sort-up = 'X'.
  APPEND g_sort TO gt_sort.
  add 1 to g_sort-spos.
  g_sort-fieldname = 'FUNCTIONID'.
  g_sort-tabname = 'OUTPUTDET4'.
  g_sort-up = 'X'.
  APPEND g_sort TO gt_sort.
  add 1 to g_sort-spos.
  g_sort-fieldname = 'TCODE'.
  g_sort-tabname = 'OUTPUTDET4'.
  g_sort-up = 'X'.
  APPEND g_sort TO gt_sort.
  add 1 to g_sort-spos.
  g_sort-fieldname = 'ENH_TCODE'.
  g_sort-tabname = 'OUTPUTDET4'.
  g_sort-up = 'X'.
  APPEND g_sort TO gt_sort.

  add 1 to g_sort-spos.
  g_sort-fieldname = 'OBJCT'.
  g_sort-tabname = 'OUTPUTDET4'.
  g_sort-up = 'X'.
  APPEND g_sort TO gt_sort.
  add 1 to g_sort-spos.
  g_sort-fieldname = 'VALUESET'.
  g_sort-tabname = 'OUTPUTDET4'.
  g_sort-up = 'X'.
  APPEND g_sort TO gt_sort.

  add 1 to g_sort-spos.
  g_sort-fieldname = 'FIELD'.
  g_sort-tabname = 'OUTPUTDET4'.
  g_sort-up = 'X'.
  APPEND g_sort TO gt_sort.
  add 1 to g_sort-spos.
  g_sort-fieldname = 'VON'.
  g_sort-tabname = 'OUTPUTDET4'.
  g_sort-up = 'X'.
  APPEND g_sort TO gt_sort.

  add 1 to g_sort-spos.
  g_sort-fieldname = 'BIS'.
  g_sort-tabname = 'OUTPUTDET4'.
  g_sort-up = 'X'.
  APPEND g_sort TO gt_sort.
  add 1 to g_sort-spos.
  g_sort-fieldname = 'DESCRIPTION'.
  g_sort-tabname = 'OUTPUTDET4'.
  g_sort-up = 'X'.
  APPEND g_sort TO gt_sort.

  add 1 to g_sort-spos.
  g_sort-fieldname = 'FLD_AND'.
  g_sort-tabname   = 'OUTPUTDET4'.
  g_sort-up        = 'X'.
  APPEND g_sort TO gt_sort.


  MOVE 'COLOR_LINE' TO g_alv_layout-info_fieldname.
  g_alv_layout-zebra = 'X'.
  g_alv_layout-colwidth_optimize = 'X'.
  g_alv_layout-box_fieldname     = 'SEL'.
  l_repid = sy-repid.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            it_sort                  = gt_sort
            is_layout                = g_alv_layout
            it_fieldcat              = gt_fieldcat_alv
            i_callback_program       = l_repid
            i_callback_user_command  = 'HOTSPOT_CLICK'
            i_callback_pf_status_set = 'PF_STATUS_SET'
            i_save                   = 'A'
            is_variant               = gs_variant
       TABLES
            t_outtab                 = gt_out
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
*---------------------------------------------------------------------*
*       FORM hotspot_click                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_UCOMM                                                       *
*  -->  IS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM hotspot_click USING i_ucomm LIKE sy-ucomm
                         is_selfield TYPE slis_selfield.
  FIELD-SYMBOLS : <out> LIKE gt_out.
  DATA : lf_first TYPE flag VALUE 'X',
         lf_first_sel TYPE flag VALUE '',
         lv_alvgrid2 TYPE REF TO cl_gui_alv_grid,
         lt_selected TYPE lvc_t_row,
         ls_row TYPE lvc_s_row,
         l_fld TYPE string,
         l_idx TYPE lvc_index,
         lt_out LIKE TABLE  OF gt_out WITH HEADER LINE.
CONSTANTS : lc_fld(33) VALUE '(SAPLSLVC_FULLSCREEN)GT_GRID-GRID'.
*--Get a reference to the ALV Grid
  FIELD-SYMBOLS <g_grid> TYPE REF TO cl_gui_alv_grid.
*  l_fld = '(SAPLSLVC_FULLSCREEN)GT_GRID-GRID'.
  ASSIGN  (lc_fld) TO <g_grid>."#EC PATHLOCK_CI_DYN_ACCES
*--Get the selected rows
  CALL METHOD <g_grid>->get_selected_rows
  IMPORTING
  et_index_rows = lt_selected.


  CASE i_ucomm.
    WHEN 'ADD2FUNC'.
      LOOP AT lt_selected INTO ls_row.
        READ TABLE gt_out INDEX ls_row-index.
        CHECK gt_out-tcode <> gt_out-enh_tcode AND
               gt_out-enh = 'X'.
        APPEND gt_out TO lt_out.
      ENDLOOP.
      PERFORM add_data_to_matrix TABLES lt_out.
  ENDCASE.
  CASE is_selfield-fieldname.
    WHEN 'TCODE'.
      READ TABLE gt_out INDEX is_selfield-tabindex.
*--When a tcode is clicked, all records
*  for that called/calling tcode combo
*  are marked as selected if the first one is not selected.
*  If the first one is selected, all records are deselected
      LOOP AT gt_out ASSIGNING <out>
        WHERE tcode     = is_selfield-value AND
              enh_tcode = gt_out-enh_tcode  AND
              enh = 'X'.
        l_idx = sy-tabix.
        CHECK <out>-tcode <> <out>-enh_tcode.
        IF lf_first = 'X'.
          READ TABLE lt_selected WITH KEY INDEX = l_idx
          TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            lf_first_sel = 'X'.
          ELSE.
            CLEAR lf_first_sel.
          ENDIF.
          CLEAR lf_first.
        ENDIF.
        IF lf_first_sel = 'X'.
*--Deselect
          DELETE lt_selected WHERE index = l_idx.
        ELSE.
          ls_row-index = l_idx.
          APPEND ls_row TO lt_selected.
        ENDIF.
      ENDLOOP.
  ENDCASE.
  SORT lt_selected.
*--Set the selected rows
  CALL METHOD <g_grid>->set_selected_rows
  EXPORTING
  it_index_rows = lt_selected.

*  CALL METHOD <g_grid>->refresh_table_display.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM pf_status_set                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  RT_EXTAB                                                      *
*---------------------------------------------------------------------*
FORM pf_status_set USING rt_extab TYPE slis_t_extab.

  SET PF-STATUS 'STANDARD' .

ENDFORM. "PF_STATUS_SET


*---------------------------------------------------------------------*
*       FORM add_data_to_matrix                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_DATA                                                       *
*---------------------------------------------------------------------*
FORM add_data_to_matrix TABLES
  it_data.
  DATA :
  lt_data         LIKE TABLE OF gt_out            WITH HEADER LINE,
  lt_funcs        LIKE TABLE OF gt_out            WITH HEADER LINE,
  lf_auth_failure TYPE flag,
  lt_functtran    TYPE TABLE OF /psyng/functtran  WITH HEADER LINE,
  lt_faobj        TYPE TABLE OF /psyng/faobj2     WITH HEADER LINE,
  lt_texts        TYPE TABLE OF /psyng/texts      WITH HEADER LINE,
  l_msg           TYPE string,
  ls_func         TYPE /psyng/function,
  lf_valid        TYPE flag,
  ls_version      type /PSYNG/SWSODVERS.

  IF it_data[] IS INITIAL.
    MESSAGE e113(/psyng/sw) WITH
    'No valid (enhanced) Records are selected'(e01).
  ELSE.
*--Check if this version can be modified
    select single * from /PSYNG/SWSODVERS
    into ls_version where vrsio = vrsio.
    if ls_version-noedit = 'X'.
*   Version & cannot be edited - display only
      MESSAGE e134(/psyng/sw) WITH vrsio.
    else.
    lt_data[]  = it_data[].
    SORT lt_data.
    DELETE ADJACENT DUPLICATES FROM lt_data.
    lt_funcs[] = lt_data[].
    SORT lt_funcs BY functionid.
    DELETE ADJACENT DUPLICATES FROM lt_funcs COMPARING functionid.
    LOOP AT lt_funcs.
*--Auth Check
      AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
               ID 'ACTVT'      FIELD '02'
               ID 'Y&SW_VRSIO' FIELD vrsio
               ID 'Y&SW_FUNCT' FIELD lt_funcs-functionid.
      IF sy-subrc <> 0.
        lf_auth_failure = 'X'.
        MESSAGE w108(/psyng/sw) WITH 'Edit'
        'function' lt_funcs-functionid.
*   You are not authorized to & & & &
      ELSE.
        lf_valid = 'X'.
        REFRESH : lt_functtran, lt_faobj,lt_texts.
*--Load the existing function
        CALL FUNCTION '/PSYNG/SW_CR_READ_FUNCTIONID'
             EXPORTING
                  functionid            = lt_funcs-functionid
                  i_vrsio               = vrsio
             IMPORTING
                  wa_function           = ls_func
             TABLES
                  texts                 = lt_texts
                  functtran             = lt_functtran
                  faobj                 = lt_faobj
             EXCEPTIONS
                  function_doesnt_exist = 1
                  not_authorized        = 2
                  OTHERS                = 3.
        IF sy-subrc <> 0.
          CASE  sy-subrc.
            WHEN 1.
              l_msg = 'Function ID Not specified'(e01).
            WHEN 2.
              l_msg = 'No Authorization'(e02).
            WHEN 3.
              l_msg = 'Unknown Error'(e05).
          ENDCASE.
          CLEAR lf_valid.
          MESSAGE w002(/psyng/sw) WITH
          'Could not update function'
          lt_funcs-functionid
          l_msg.
        ENDIF.

        CHECK lf_valid = 'X'.
*--Add the new functions and objects
        LOOP AT lt_data WHERE functionid = lt_funcs-functionid.
          MOVE-CORRESPONDING lt_data TO lt_functtran.
          lt_functtran-vrsio = vrsio.
          lt_functtran-mandt = sy-mandt.
          MOVE-CORRESPONDING lt_data TO lt_faobj.
          lt_faobj-mandt    = sy-mandt.
          lt_faobj-funid    = lt_funcs-functionid.
          lt_faobj-object   = lt_data-objct.
          lt_faobj-VAL_FROM = lt_data-von.
          lt_faobj-VAL_TO   = lt_data-bis.
          lt_faobj-vrsio    = vrsio.
          append lt_functtran.
          append lt_faobj.
        ENDLOOP.
        sort : lt_functtran, lt_faobj.
        ls_func-function = lt_funcs-functionid.

*--Save the function
        CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
             EXPORTING
                  wa_function             = ls_func
                  i_vrsio                 = vrsio
                  flag                    = ''
             TABLES
                  texts                   = lt_texts
                  functtran               = lt_functtran
                  faobj                   = lt_faobj
             EXCEPTIONS
                  target_not_specified    = 1
                  not_authorized          = 2
                  function_already_exists = 3
                  locked                  = 4
                  OTHERS                  = 5.
        IF sy-subrc <> 0.
          CASE  sy-subrc.
            WHEN 1.
              l_msg = 'Function ID Not specified'(e01).
            WHEN 2.
              l_msg = 'No Authorization'(e02).
            WHEN 3.
              l_msg = 'Already exists'(e03).
            WHEN 4.
              l_msg = 'Function is locked'(e04).
            WHEN 5.
              l_msg = 'Unknown Error'(e05).
          ENDCASE.
          MESSAGE w002(/psyng/sw) WITH
          'Could not update function'
          lt_funcs-functionid
          l_msg.
        ELSE.
          MESSAGE s002(/psyng/sw) WITH
          'Function' lt_funcs-functionid 'succesfully updated' .
        ENDIF.
       endif.

    ENDLOOP.
      ENDIF.
  ENDIF.
ENDFORM.
