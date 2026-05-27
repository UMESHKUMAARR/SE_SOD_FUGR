*&---------------------------------------------------------------------*
*&  Include           /PSYNG/SW_IBS_RULE_IMP
*&---------------------------------------------------------------------*
*PERFORM top-of-page.
FORM top-of-page.

  DATA: lt_comment TYPE TABLE OF slis_listheader,

        ls_comment TYPE slis_listheader.

  " TYP type are 'S'election, 'H'eader, 'A'ction

  ls_comment-typ = 'H'.
  ls_comment-info = 'LOG TABLE'.
  APPEND ls_comment TO lt_comment.
  CLEAR ls_comment.

  ls_comment-typ = 'S'.
  ls_comment-key = 'SOD Version: '(h01).
  ls_comment-info = p_vrsn.
  APPEND ls_comment TO lt_comment.
  CLEAR ls_comment.

  ls_comment-typ = 'S'.
  ls_comment-key = 'Version Description: '(h02).
  SELECT SINGLE vdesc INTO lv_vrs_desc FROM /psyng/swsodvers
                WHERE vrsio = p_vrsn.
  ls_comment-info = lv_vrs_desc.
  APPEND ls_comment TO lt_comment.
  CLEAR ls_comment.

  ls_comment-typ = 'S'.
  ls_comment-key = 'Errors: '(h03).
  ls_comment-info = lv_count_error.
  APPEND ls_comment TO lt_comment.
  CLEAR ls_comment.

  ls_comment-typ = 'S'.
  ls_comment-key = 'Warnings: '(h04).
  ls_comment-info = lv_count_warning.
  APPEND ls_comment TO lt_comment.
  CLEAR ls_comment.

  "umittal 03 May 2024
  IF p_noval EQ 'X'.
    ls_comment-typ = 'S'.
    ls_comment-key = 'Validations (ON/OFF):'.
    ls_comment-info = 'OFF'.
    APPEND ls_comment TO lt_comment.
    CLEAR ls_comment.

  ELSE.
    ls_comment-typ = 'S'.
    ls_comment-key = 'Validations (ON/OFF):'.
    ls_comment-info = 'ON'.
    APPEND ls_comment TO lt_comment.
    CLEAR ls_comment.
  ENDIF.

  IF p_tstrun IS INITIAL.
    ls_comment-typ = 'S'.
    ls_comment-key = 'Test Run (ON/OFF):'.
    ls_comment-info = 'OFF'.
    APPEND ls_comment TO lt_comment.
    CLEAR ls_comment.
  ELSE.
    ls_comment-typ = 'S'.
    ls_comment-key = 'Test Run (ON/OFF):'.
    ls_comment-info = 'ON'.
    APPEND ls_comment TO lt_comment.
    CLEAR ls_comment.
  ENDIF.

  "umittal 03 May 2024

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_comment.
ENDFORM.

FORM output_log TABLES gt_log.

  lv_count_error = 0.
  lv_count_warning = 0.


  LOOP AT gt_log INTO ls_gt_log.
    IF ls_gt_log-type = '@0A@'.
      lv_count_error = lv_count_error + 1.
    ELSEIF ls_gt_log-type = '@09@'.
      lv_count_warning = lv_count_warning + 1.
    ENDIF.
    CLEAR ls_gt_log.
  ENDLOOP.



  alv_layout-zebra = 'X'.             " Zebra Layout of ALV
  alv_layout-colwidth_optimize = 'X'. " Column width optimize
  l_program = sy-repid.               " self report as callback prgrm

*Field Catalog creating by using 'field_cat' macros defined earlier
  field_cat: '1' 'FILENAME'  'Target Table'(a01) 60,
             '2' 'TYPE'      'Type'(a02) 5,
             '3' 'OBJECT'    'Object'(a03) 30,
             '4' 'OBJECT_ID'  'Object ID'(a04) 20,
             '5' 'FIELDNAME' 'Fieldname'(a05) 20,
             '6' 'VALUE'     'Value'(a06) 30,
             '7' 'MESSAGE'   'Message'(a07) 80.




*'REUSE_ALV_GRID_DISPLAY' Function call for ALV creation
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program     = l_program
      is_layout              = alv_layout
      it_fieldcat            = lt_fieldcatalog
      i_save                 = 'X'
      is_variant             = ls_variant
      i_callback_top_of_page = 'TOP-OF-PAGE'
    TABLES
      t_outtab               = gt_log  " itab of log table
    EXCEPTIONS
      program_error          = 1
      OTHERS                 = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM.
