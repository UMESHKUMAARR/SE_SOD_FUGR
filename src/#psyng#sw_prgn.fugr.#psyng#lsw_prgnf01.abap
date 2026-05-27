*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_PRGNF01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  display_alv_0100
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv_0100.
  IF gr_alvgrid_100 IS INITIAL .
    CREATE OBJECT gr_event_handler .
    CREATE OBJECT gr_ccont_100
      EXPORTING
        container_name = gc_control_100
      EXCEPTIONS
        cntl_error = 1
        cntl_system_error = 2
        create_error = 3
        lifetime_error = 4
        lifetime_dynpro_dynpro_link = 5
        others = 6 .
    IF sy-subrc <> 0.
*--Cancel entire process, so we never break PFCG
      MESSAGE i002(/psyng/sw) WITH
      'Problem analyzing role. Canceling'(e01).
      SET SCREEN 000.
      LEAVE SCREEN.
    ENDIF.

    CREATE OBJECT gr_alvgrid_100
      EXPORTING
        i_parent = gr_ccont_100
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init = 2
        error_cntl_link = 3
        error_dp_create = 4
        others = 5 .
    IF sy-subrc <> 0.
*--Cancel entire process, so we never break PFCG
      MESSAGE i002(/psyng/sw) WITH
      'Problem analyzing role. Canceling'(e01).
      SET SCREEN 000.
      LEAVE SCREEN.
    ENDIF.
    PERFORM prepare_field_catalog_100 CHANGING gt_fieldcat_100.
    PERFORM prepare_layout_100 CHANGING gs_layout_100.
    PERFORM prepare_sort_100 CHANGING gt_sort_100.
    SET HANDLER gr_event_handler->handle_hotspot_click
                FOR gr_alvgrid_100.
*--Only visible in print or print preview
    SET HANDLER gr_event_handler->handle_print_top_of_list
                FOR gr_alvgrid_100 .

    CALL METHOD gr_alvgrid_100->set_table_for_first_display
    EXPORTING
      is_layout = gs_layout_100
    CHANGING
      it_outtab       = gt_role_conflicts[]
      it_fieldcatalog = gt_fieldcat_100
      it_sort         = gt_sort_100
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error = 2
      too_many_lines = 3
      OTHERS = 4 .
    IF sy-subrc <> 0.
*--Cancel entire process, so we never break PFCG
      MESSAGE i002(/psyng/sw) WITH
      'Problem analyzing role. Canceling'(e01).
      SET SCREEN 000.
      LEAVE SCREEN.
    ENDIF.
  ELSE.
    CALL METHOD gr_alvgrid_100->refresh_table_display
*   EXPORTING
*   IS_STABLE =
*   I_SOFT_REFRESH =
    EXCEPTIONS
      finished = 1
      OTHERS = 2 .
    IF sy-subrc <> 0.
*  --Cancel entire process, so we never break PFCG
      MESSAGE i002(/psyng/sw) WITH
      'Problem analyzing role. Canceling'(e01).
      SET SCREEN 000.
      LEAVE SCREEN.
    ENDIF.
  ENDIF.
ENDFORM.                    " display_alv_0100



*---------------------------------------------------------------------*
*       FORM display_alv_0200                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_alv_0200.
  IF gr_alvgrid_200 IS INITIAL .
    CREATE OBJECT gr_event_handler_200 .
    CREATE OBJECT gr_ccont_200
      EXPORTING
        container_name = gc_control_200
      EXCEPTIONS
        cntl_error = 1
        cntl_system_error = 2
        create_error = 3
        lifetime_error = 4
        lifetime_dynpro_dynpro_link = 5
        others = 6 .
    IF sy-subrc <> 0.
*--Cancel entire process, so we never break PFCG
      MESSAGE i002(/psyng/sw) WITH
      'Problem analyzing role. Canceling'(e01).
      SET SCREEN 000.
      LEAVE SCREEN.
    ENDIF.

    CREATE OBJECT gr_alvgrid_200
      EXPORTING
        i_parent = gr_ccont_200
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init = 2
        error_cntl_link = 3
        error_dp_create = 4
        others = 5 .
    IF sy-subrc <> 0.
*--Cancel entire process, so we never break PFCG
      MESSAGE i002(/psyng/sw) WITH
      'Problem analyzing role. Canceling'(e01).
      SET SCREEN 000.
      LEAVE SCREEN.
    ENDIF.
    PERFORM prepare_field_catalog_200 CHANGING gt_fieldcat_200.
    PERFORM prepare_layout_200 CHANGING gs_layout_200.
    PERFORM prepare_sort_200 CHANGING gt_sort_200.
    SET HANDLER gr_event_handler_200->handle_hotspot_click
                FOR gr_alvgrid_200 .
*--Only visible in print or print preview
    SET HANDLER gr_event_handler_200->handle_print_top_of_list
                FOR gr_alvgrid_200 .

    CALL METHOD gr_alvgrid_200->set_table_for_first_display
    EXPORTING
      is_layout = gs_layout_200
    CHANGING
      it_outtab       = gt_user_conflicts[]
      it_fieldcatalog = gt_fieldcat_200
      it_sort         = gt_sort_200
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error = 2
      too_many_lines = 3
      OTHERS = 4 .
    IF sy-subrc <> 0.
*--Cancel entire process, so we never break PFCG
      MESSAGE i002(/psyng/sw) WITH
      'Problem analyzing role. Canceling'(e01).
      SET SCREEN 000.
      LEAVE SCREEN.
    ENDIF.
  ELSE.
    CALL METHOD gr_alvgrid_200->refresh_table_display
*   EXPORTING
*   IS_STABLE =
*   I_SOFT_REFRESH =
    EXCEPTIONS
      finished = 1
      OTHERS = 2 .
    IF sy-subrc <> 0.
*  --Cancel entire process, so we never break PFCG
      MESSAGE i002(/psyng/sw) WITH
      'Problem analyzing role. Canceling'(e01).
      SET SCREEN 000.
      LEAVE SCREEN.
    ENDIF.
  ENDIF.
ENDFORM.                    " display_alv_0200


*&---------------------------------------------------------------------*
*&      Form  prepare_field_catalog_100
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_FIELDCAT_100  text
*----------------------------------------------------------------------*
FORM prepare_field_catalog_100
CHANGING et_fieldcat_100 TYPE lvc_t_fcat .
  DATA :  ls_fieldcat_100 LIKE LINE OF  et_fieldcat_100.
  REFRESH : et_fieldcat_100.
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
       EXPORTING
            i_structure_name       = '/PSYNG/SW_OUT_ROUTPUT'
       CHANGING
            ct_fieldcat            = et_fieldcat_100[]
       EXCEPTIONS
            inconsistent_interface = 1
            program_error          = 2
            OTHERS                 = 3.
  IF sy-subrc <> 0.
*  --Cancel entire process, so we never break PFCG
    MESSAGE i002(/psyng/sw) WITH
    'Problem analyzing role. Canceling'(e01).
    SET SCREEN 000.
    LEAVE SCREEN.
  ENDIF.
*--Make necessary changes
  ls_fieldcat_100-no_out = 'X'.
  MODIFY  et_fieldcat_100
                         FROM ls_fieldcat_100
                         TRANSPORTING no_out
                         WHERE  fieldname = 'RFCDEST'  OR
                                fieldname = 'ENHANCED' OR
                                fieldname = 'SIMU'     OR
                                fieldname = 'CONTID'   OR
                                fieldname = 'FUNCTIONID' OR
                                fieldname = 'ORG_ABB'  OR
                                fieldname = 'RISK' OR
                                fieldname = 'CHILD_AGR' OR
                                fieldname = 'SIMU_BEFORE' OR
                                fieldname = 'SIMU_AFTER'.


*--Add some fields
  ls_fieldcat_100-inttype   = 'C' .
  ls_fieldcat_100-outputlen = '10' .
  ls_fieldcat_100-checkbox  = 'X' .
  ls_fieldcat_100-hotspot  = 'X' .
  ls_fieldcat_100-fieldname = 'OLD' .
  ls_fieldcat_100-coltext = 'Before'(t05) .
  ls_fieldcat_100-seltext = 'Before'(t05) .
  APPEND ls_fieldcat_100 TO et_fieldcat_100 .
  ls_fieldcat_100-fieldname = 'NEW' .
  ls_fieldcat_100-coltext = 'After'(t06).
  ls_fieldcat_100-seltext = 'After'(t06).
  APPEND ls_fieldcat_100 TO et_fieldcat_100 .


*--Set correct field order
  ls_fieldcat_100-col_pos = 1.
  ls_fieldcat_100-outputlen = '20'.
  MODIFY et_fieldcat_100 FROM ls_fieldcat_100
                         TRANSPORTING col_pos outputlen
                         WHERE  fieldname = 'AGR_NAME'.

  ADD 1 TO ls_fieldcat_100-col_pos.
  ls_fieldcat_100-outputlen = '30'.
  MODIFY et_fieldcat_100 FROM ls_fieldcat_100
                         TRANSPORTING col_pos outputlen
                         WHERE  fieldname = 'AGR_TEXT'.


  ADD 1 TO ls_fieldcat_100-col_pos.
  MODIFY et_fieldcat_100 FROM ls_fieldcat_100
                         TRANSPORTING col_pos
                         WHERE  fieldname = 'IMP'.

  ADD 1 TO ls_fieldcat_100-col_pos.
  ls_fieldcat_100-hotspot = 'X'.
  MODIFY et_fieldcat_100 FROM ls_fieldcat_100
                         TRANSPORTING col_pos hotspot
                         WHERE  fieldname = 'CONID'.
  ADD 1 TO ls_fieldcat_100-col_pos.
  MODIFY et_fieldcat_100 FROM ls_fieldcat_100
                         TRANSPORTING col_pos
                         WHERE  fieldname = 'DESCRIPTION'.
ENDFORM.                    " prepare_field_catalog_100

*---------------------------------------------------------------------*
*       FORM prepare_field_catalog_200                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_FIELDCAT_200                                               *
*---------------------------------------------------------------------*
FORM prepare_field_catalog_200
CHANGING et_fieldcat_200 TYPE lvc_t_fcat .
  DATA :  ls_fieldcat_200 LIKE LINE OF  et_fieldcat_200.
  REFRESH : et_fieldcat_200.
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
       EXPORTING
            i_structure_name       = '/PSYNG/SW_SOD_OUTPUT_ORG'
       CHANGING
            ct_fieldcat            = et_fieldcat_200[]
       EXCEPTIONS
            inconsistent_interface = 1
            program_error          = 2
            OTHERS                 = 3.
  IF sy-subrc <> 0.
*  --Cancel entire process, so we never break PFCG
    MESSAGE i002(/psyng/sw) WITH
    'Problem analyzing role. Canceling'(e01).
    SET SCREEN 000.
    LEAVE SCREEN.
  ENDIF.
*--Delete fields we don't use
  DELETE et_fieldcat_200 WHERE
    fieldname = 'NAME_TEXT' OR
    fieldname = 'CLASS'     OR
    fieldname = 'FUNID'     OR
    fieldname = 'ORG_ABB'   OR
    fieldname = 'SCANDATE'  OR
    fieldname = 'ORIGIN'    OR
    fieldname = 'SIMU'      OR
    fieldname = 'RFCDEST'   OR
    fieldname = 'COMPANY'   OR
    fieldname = 'DEPARTMENT' OR
    fieldname = 'CENTRAL_UID' OR
    fieldname = 'ER'          OR
    fieldname = 'LEVEL2'      OR
    fieldname = 'LEVEL3'      OR
    fieldname = 'CONTID'      OR
    fieldname = 'USTYP'       OR
    fieldname = 'SIMU_BEFORE' OR
    fieldname = 'SIMU_AFTER'.

*--Make necessary changes
*  ls_fieldcat_200-no_out = 'X'.
  MODIFY  et_fieldcat_200
                         FROM ls_fieldcat_200
                         TRANSPORTING no_out
                         WHERE  fieldname = 'IMPSORT'."  OR
*                                fieldname = 'ENHANCED' OR
*                                fieldname = 'SIMU'     OR
*                                fieldname = 'CONTID'   OR
*                                fieldname = 'FUNCTIONID' OR
*                                fieldname = 'ORG_ABB'  OR
*                                fieldname = 'RISK'.
*--Add some fields
  ls_fieldcat_200-inttype   = 'C' .
  ls_fieldcat_200-outputlen = '10' .
  ls_fieldcat_200-checkbox  = 'X' .
  ls_fieldcat_200-hotspot  = 'X' .
  ls_fieldcat_200-fieldname = 'OLD' .
  ls_fieldcat_200-coltext = 'Before'(t05) .
  ls_fieldcat_200-seltext = 'Before'(t05) .
  APPEND ls_fieldcat_200 TO et_fieldcat_200 .
  ls_fieldcat_200-fieldname = 'NEW' .
  ls_fieldcat_200-coltext = 'After'(t06).
  ls_fieldcat_200-seltext = 'After'(t06).
  APPEND ls_fieldcat_200 TO et_fieldcat_200 .


*--Set correct field order
  ls_fieldcat_200-col_pos = 1.
  ls_fieldcat_200-outputlen = '20'.
  MODIFY et_fieldcat_200 FROM ls_fieldcat_200
                         TRANSPORTING col_pos outputlen
                         WHERE  fieldname = 'BNAME'.

  ADD 1 TO ls_fieldcat_200-col_pos.
  ls_fieldcat_200-checkbox = 'X'.
  MODIFY et_fieldcat_200 FROM ls_fieldcat_200
                         TRANSPORTING col_pos checkbox
                         WHERE  fieldname = 'OLD'.


  ADD 1 TO ls_fieldcat_200-col_pos.
  ls_fieldcat_200-checkbox = 'X'.
  MODIFY et_fieldcat_200 FROM ls_fieldcat_200
                         TRANSPORTING col_pos checkbox
                         WHERE  fieldname = 'NEW'.
  ADD 1 TO ls_fieldcat_200-col_pos.
  MODIFY et_fieldcat_200 FROM ls_fieldcat_200
                         TRANSPORTING col_pos
                         WHERE  fieldname = 'IMP'.



  ADD 1 TO ls_fieldcat_200-col_pos.
  ls_fieldcat_200-hotspot = 'X'.
  MODIFY et_fieldcat_200 FROM ls_fieldcat_200
                         TRANSPORTING col_pos hotspot
                         WHERE  fieldname = 'CONID'.

  ADD 1 TO ls_fieldcat_200-col_pos.
  MODIFY et_fieldcat_200 FROM ls_fieldcat_200
                         TRANSPORTING col_pos
                         WHERE  fieldname = 'CONDESC'.
ENDFORM.                    " prepare_field_catalog_200


*&---------------------------------------------------------------------*
*&      Form  prepare_layout_100
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GS_LAYOUT_100  text
*----------------------------------------------------------------------*
FORM prepare_layout_100 CHANGING es_layout_100 TYPE lvc_s_layo.
  es_layout_100-zebra = 'X' .
  es_layout_100-grid_title = 'SOD Conflicts'(t01) .
  es_layout_100-smalltitle = 'X'.
  es_layout_100-no_toolbar = ''.
ENDFORM.                    " prepare_layout_100

*---------------------------------------------------------------------*
*       FORM prepare_layout_200                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ES_LAYOUT_200                                                 *
*---------------------------------------------------------------------*
FORM prepare_layout_200 CHANGING es_layout_200 TYPE lvc_s_layo.
  es_layout_200-zebra = 'X' .
  es_layout_200-grid_title = 'SOD Conflicts'(t01) .
  es_layout_200-smalltitle = 'X'.
  es_layout_200-no_toolbar = ''.
ENDFORM.                    " prepare_layout_200


*&---------------------------------------------------------------------*
*&      Form  check_for_impacted_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_ROLES  text
*----------------------------------------------------------------------*
FORM check_for_impacted_roles
TABLES   et_roles STRUCTURE /psyng/sw_sel_opts_agr_name
USING    i_rolename TYPE      agr_name.

  DATA : lt_singleroles TYPE TABLE OF /psyng/sw_sel_opts_agr_name,
         lt_comproles TYPE TABLE OF /psyng/sw_sel_opts_agr_name,
         l_answer,
         l_roles TYPE i.

  PERFORM find_impacted_single_roles
              TABLES
                 lt_singleroles
              USING
                 i_rolename.
  PERFORM find_impacted_composite_roles
              TABLES
                 lt_comproles
              USING
                 i_rolename.
  DESCRIBE TABLE lt_singleroles LINES        l_roles.
  IF     l_roles > 1 OR
     NOT lt_comproles[]   IS INITIAL.
    CALL FUNCTION 'POPUP_TO_DECIDE'
      EXPORTING
        textline1               =
        'This change impacts single and derived roles'(m01)
       textline2               =
        'Do you want to analyze the impacted roles'(m02)
        text_option1            = 'All impacted roles'(m03)
        text_option2            = 'Only this role'(m04)
        titel                   = i_rolename
       cancel_display          = ' '
     IMPORTING
      answer                  = l_answer
              .
    IF l_answer = '1'.
      APPEND LINES OF lt_singleroles TO et_roles.
      APPEND LINES OF lt_comproles TO et_roles.
    ENDIF.
  ENDIF.
ENDFORM.                    " check_for_impacted_roles


*&---------------------------------------------------------------------*
*&      Form  find_impacted_single_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_SROLE  text
*      -->P_L_ROLENAME  text
*----------------------------------------------------------------------*
FORM find_impacted_single_roles
  TABLES   et_sroles  STRUCTURE /psyng/range_agr_name
  USING    i_rolename TYPE      agr_name.

  DATA : lt_derived_roles TYPE TABLE OF agr_define WITH HEADER LINE.


  SELECT agr_name parent_agr FROM agr_define         "#EC CI_SEL_NESTED
         INTO CORRESPONDING FIELDS OF TABLE lt_derived_roles
         WHERE
*agr_name   IN it_srole
*           AND
           parent_agr =  i_rolename.
  et_sroles-sign   = 'I'.
  et_sroles-option = 'EQ'.
  LOOP AT lt_derived_roles.
    et_sroles-low = lt_derived_roles-agr_name.
    APPEND et_sroles.
  ENDLOOP.
*--Add the role itsself
*  IF i_rolename IN it_srole.
  et_sroles-low = i_rolename.
  APPEND et_sroles.
*  ENDIF.
  SORT et_sroles.
  DELETE ADJACENT DUPLICATES FROM et_sroles.
ENDFORM.                    " find_impacted_single_roles
*&---------------------------------------------------------------------*
*&      Form  find_impacted_composite_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_CROLE  text
*      -->P_LT_CROLE  text
*      -->P_L_ROLENAME  text
*----------------------------------------------------------------------*
FORM find_impacted_composite_roles
  TABLES  et_croles  STRUCTURE /psyng/range_agr_name
  USING    i_rolename TYPE      agr_name.



  DATA:
  lt_parent_roles TYPE TABLE OF agr_agrs WITH HEADER LINE,
  lt_derived_roles TYPE TABLE OF /psyng/range_agr_name WITH HEADER LINE.

*--Find all derived roles
  PERFORM find_impacted_single_roles
              TABLES
                 lt_derived_roles
              USING
                 i_rolename.
  lt_derived_roles-sign = 'I'.
  lt_derived_roles-option = 'EQ'.
  lt_derived_roles-low = i_rolename.
  APPEND lt_derived_roles.

  SELECT agr_name FROM agr_agrs                      "#EC CI_SEL_NESTED
  INTO CORRESPONDING FIELDS OF TABLE lt_parent_roles
  WHERE
    child_agr IN lt_derived_roles  AND
*    agr_name  IN it_crole          AND
    attributes <> 'X'. "X means NOT ACTIVE!!!

  et_croles-sign   = 'I'.
  et_croles-option = 'EQ'.
  LOOP AT lt_parent_roles.
    et_croles-low = lt_parent_roles-agr_name.
    APPEND et_croles.
  ENDLOOP.
  SORT et_croles.
  DELETE ADJACENT DUPLICATES FROM et_croles.
ENDFORM.                    " find_impacted_composite_roles
*&---------------------------------------------------------------------*
*&      Form  prepare_sort_100
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_SORT_100  text
*----------------------------------------------------------------------*
FORM prepare_sort_100 CHANGING et_sort_100 TYPE lvc_t_sort.
  REFRESH : et_sort_100.
  DATA : ls_sort TYPE lvc_s_sort.
  ls_sort-spos = 0.
  ls_sort-up        = 'X'.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'AGR_NAME'.
  APPEND ls_sort TO et_sort_100.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'AGR_TEXT'.
  APPEND ls_sort TO et_sort_100.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'CONID'.
  APPEND ls_sort TO et_sort_100.


  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'DESCRIPTION'.
  APPEND ls_sort TO et_sort_100.



ENDFORM.                    " prepare_sort_100

*---------------------------------------------------------------------*
*       FORM prepare_sort_200                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SORT_200                                                   *
*---------------------------------------------------------------------*
FORM prepare_sort_200 CHANGING et_sort_200 TYPE lvc_t_sort.
  REFRESH : et_sort_200.
  DATA : ls_sort TYPE lvc_s_sort.
  ls_sort-spos = 0.
  ls_sort-up        = 'X'.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'BNAME'.
  APPEND ls_sort TO et_sort_200.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'IMPSORT'.
  APPEND ls_sort TO et_sort_200.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'CONID'.
  APPEND ls_sort TO et_sort_200.


  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'CONDESC'.
  APPEND ls_sort TO et_sort_200.



ENDFORM.                    " prepare_sort_200

*---------------------------------------------------------------------*
*       FORM analyze_role                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_ACTIVITY_GROUP                                              *
*  -->  I_TRANSACTION                                                 *
*---------------------------------------------------------------------*
FORM analyze_role TABLES   it_roles STRUCTURE agr_define
                  USING    i_activity_group TYPE agr_name
                           i_transaction
                           i_vrsio TYPE /psyng/sodvrsio
                           if_allow_conflicts TYPE flag
                  CHANGING ef_stop TYPE flag
                  .
  DATA : lt_roles     TYPE TABLE OF /psyng/sw_sel_opts_agr_name
                      WITH HEADER LINE,
         ls_role     TYPE agr_define.
  REFRESH : gt_role_conflicts, lt_roles.
  CLEAR gf_stop.
  g_transaction = i_transaction.
  gf_allow_conflicts = if_allow_conflicts.
  g_vrsio = i_vrsio.


  IF i_activity_group = '' AND NOT it_roles[] IS INITIAL.
    lt_roles-sign   = 'I'.
    lt_roles-option = 'EQ'.
    LOOP AT it_roles INTO ls_role.
      lt_roles-low    = ls_role-agr_name.
      COLLECT lt_roles.
      PERFORM check_for_impacted_roles
    TABLES lt_roles USING ls_role-agr_name.
    ENDLOOP.
  ELSE.
    lt_roles-sign   = 'I'.
    lt_roles-option = 'EQ'.
    lt_roles-low    = i_activity_group.
    COLLECT lt_roles.

    PERFORM check_for_impacted_roles
      TABLES lt_roles USING i_activity_group.
  ENDIF.

*--Analyze these roles for conflicts
  REFRESH  gt_role_conflicts.
  CALL FUNCTION '/PSYNG/SW_036'
       EXPORTING
            vrsio          = i_vrsio
       TABLES
            it_roles       = lt_roles
            ot_routput_sum = gt_role_conflicts.
  DATA : l_count TYPE i.
  DESCRIBE TABLE gt_role_conflicts LINES l_count.
  IF l_count > 0.
    CALL SCREEN '0100' STARTING AT 10 10.
    IF i_transaction = 'SE10'.
*--Only when releasing a transport do we have the ability to prevent the
*  user from continuing
      ef_stop = gf_stop.
    ENDIF.


  ELSE.
    MESSAGE i002(/psyng/sw) WITH
    'Separations Enforcer role analysis:'
    'No issues found'.
  ENDIF.

ENDFORM.                    " analyze_role
*&---------------------------------------------------------------------*
*&      Form  handle_role_conid_click
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_E_ROW_ID  text
*      -->P_E_COLUMN_ID  text
*      -->P_ES_ROW_NO  text
*----------------------------------------------------------------------*
FORM handle_role_conid_click USING
    i_row_id TYPE lvc_s_row
    i_column_id TYPE lvc_s_col
    is_row_no TYPE lvc_s_roid.
  READ TABLE gt_role_conflicts INDEX is_row_no-row_id .
  IF sy-subrc = 0 AND i_column_id-fieldname = 'CONID' .
    SUBMIT /psyng/sod_syswide_byrole
      WITH role     = gt_role_conflicts-agr_name
      WITH spconfs  = gt_role_conflicts-conid
      WITH singrol  = 'X'
      WITH comprol  = 'X'
      WITH sodvrsio = g_vrsio
      WITH shodet   = 'X'
      WITH shosum   = ''
      WITH xmc      = ''
      AND RETURN.

  ENDIF.

ENDFORM.                    " handle_role_conid_click


*---------------------------------------------------------------------*
*       FORM handle_user_conid_click                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_ROW_ID                                                      *
*  -->  I_COLUMN_ID                                                   *
*  -->  IS_ROW_NO                                                     *
*---------------------------------------------------------------------*
FORM handle_user_conid_click USING
    i_row_id TYPE lvc_s_row
    i_column_id TYPE lvc_s_col
    is_row_no TYPE lvc_s_roid.
  DATA : lt_seltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.
  READ TABLE gt_user_conflicts INDEX is_row_no-row_id .
  IF sy-subrc = 0.

    IF i_column_id-fieldname = 'CONID' AND gt_user_conflicts-new <> 'X'.
      MESSAGE s002(/psyng/sw) WITH
  'This conflict doesn''t exist after the change.'(m10)
'Click the ''Before'' checkbox to view'(m11)
  .
      EXIT.
    ELSE.

      lt_seltab-selname = 'SHODET'.
      lt_seltab-kind    = 'P'.
      lt_seltab-sign    = 'I'.
      lt_seltab-option  = 'EQ'.
      lt_seltab-low     = 'X'.
      APPEND lt_seltab.


      lt_seltab-selname = 'P_ABAP'.
      lt_seltab-kind    = 'P'.
      lt_seltab-sign    = 'I'.
      lt_seltab-option  = 'EQ'.
      lt_seltab-low     = 'X'.
      APPEND lt_seltab.

      lt_seltab-selname = 'SHOSUM'.
      lt_seltab-kind    = 'P'.
      lt_seltab-sign    = 'I'.
      lt_seltab-option  = 'EQ'.
      lt_seltab-low     = ''.
      APPEND lt_seltab.


      lt_seltab-selname = 'PBNAME'.
      lt_seltab-kind    = 'S'.
      lt_seltab-sign    = 'I'.
      lt_seltab-option  = 'EQ'.
      lt_seltab-low     = gt_user_conflicts-bname.
      APPEND lt_seltab.


      lt_seltab-selname = 'SPCONFS'.
      lt_seltab-kind    = 'S'.
      lt_seltab-sign    = 'I'.
      lt_seltab-option  = 'EQ'.
      lt_seltab-low     = gt_user_conflicts-conid.
      APPEND lt_seltab.

      lt_seltab-selname = 'SODVRSIO'.        "SOD Version
      lt_seltab-kind    = 'P'.
      lt_seltab-sign    = 'I'.
      lt_seltab-option  = 'EQ'.
      lt_seltab-low     = g_vrsio.
      APPEND lt_seltab.

      lt_seltab-selname = 'COMPROL'.
      lt_seltab-kind    = 'P'.
      lt_seltab-sign    = 'I'.
      lt_seltab-option  = 'EQ'.
      lt_seltab-low     = 'X'.
      APPEND lt_seltab.

      lt_seltab-selname = 'SINGROL'.
      lt_seltab-kind    = 'P'.
      lt_seltab-sign    = 'I'.
      lt_seltab-option  = 'EQ'.
      lt_seltab-low     = 'X'.
      APPEND lt_seltab.
*--If we're looking for OLD results, simulate undoing the changes
      IF i_column_id-fieldname =  'OLD'.
        IF NOT gt_roles_adding[] IS INITIAL.
          lt_seltab-kind    = 'P'.
          lt_seltab-sign    = 'I'.
          lt_seltab-option  = 'EQ'.
          lt_seltab-selname = 'AR_RFCS1'.
          lt_seltab-low     =  'LOCAL'.
          APPEND lt_seltab.
          lt_seltab-selname = 'AR_RFCD1'.
          lt_seltab-low     =  'LOCAL'.
          APPEND lt_seltab.
          lt_seltab-selname = 'BYSIMU'.
          lt_seltab-low     =  'X'.
          APPEND lt_seltab.


          LOOP AT gt_roles_adding .
            lt_seltab-selname = 'AR_ROL_1'.
            lt_seltab-kind    = 'S'.
            lt_seltab-sign    = gt_roles_adding-sign.
            lt_seltab-option  = gt_roles_adding-option.
            lt_seltab-low     = gt_roles_adding-low.
            lt_seltab-high    = gt_roles_adding-high.
            APPEND lt_seltab.
          ENDLOOP.
        ENDIF.

        IF NOT gt_roles_removing[] IS INITIAL.
          lt_seltab-kind    = 'P'.
          lt_seltab-sign    = 'I'.
          lt_seltab-option  = 'EQ'.
*          lt_seltab-selname = 'RR_RFC_1'.
*          lt_seltab-low     =  ''.
*          APPEND lt_seltab.
          lt_seltab-selname = 'BYRSIMU'.
          lt_seltab-low     =  'X'.
          APPEND lt_seltab.

          LOOP AT gt_roles_removing .
            lt_seltab-selname = 'RR_ROL_1'.
            lt_seltab-kind    = 'S'.
            lt_seltab-sign    = gt_roles_removing-sign.
            lt_seltab-option  = gt_roles_removing-option.
            lt_seltab-low     = gt_roles_removing-low.
            lt_seltab-high    = gt_roles_removing-high.
            APPEND lt_seltab.
          ENDLOOP.
        ENDIF.
      ENDIF.
      IF i_column_id-fieldname = 'OLD' AND gt_user_conflicts-old <> 'X'.
        MESSAGE s002(/psyng/sw) WITH
'This conflict didn''t exist before the change.'(m12)
'Click the ''After'' checkbox to view'(m13)
    .
        EXIT.
      ENDIF.
      SUBMIT /psyng/sodreport_org WITH SELECTION-TABLE lt_seltab
                  AND RETURN.
    ENDIF.
  ENDIF.
ENDFORM.                    " handle_role_conid_click

*&---------------------------------------------------------------------*
*&      Form  analyze_user
*&---------------------------------------------------------------------*
*Only the new added roles are in the ACTIVITY_GROUPS table
*the COLL_AGR flag determines if this is direct assignment
*There is no indicator if we're adding or removing this role, so we need
*to find this out from the agr_users table :
* - if the record is already there with the same dates : we're removing
* - if the record is already there with different dates : we're updating
* - if the record is not there yet, we're adding.
*----------------------------------------------------------------------*
*      -->P_ACTIVITY_GROUPS  text
*      -->P_0090   text
*      -->P_L_SOD_VERSION  text
*----------------------------------------------------------------------*
FORM analyze_user TABLES   it_activity_groups STRUCTURE str_agrs
                  USING    i_tcode
                           i_sod_version.

  DATA : l_uname           TYPE xubname,
         lt_existing_roles TYPE TABLE OF agr_users WITH HEADER LINE.
* BOC by RGUPTA on 08.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 08.04.22 for C0700
  g_vrsio = i_sod_version.
*--get username
  READ TABLE it_activity_groups INDEX 1.
  IF sy-subrc = 0.
    l_uname = it_activity_groups-uname.
  ENDIF.
  DELETE it_activity_groups WHERE org_flag = 'C'.

*--get users existing roles
  SELECT * FROM agr_users INTO TABLE lt_existing_roles WHERE uname =
  l_uname AND col_flag <> 'X'.
  REFRESH : gt_roles_adding, gt_roles_removing.
  PERFORM get_user_simulation
    TABLES it_activity_groups
           lt_existing_roles
           gt_roles_adding
           gt_roles_removing
           gt_roles_before.

*--Now we know how to simulate the user
*--We'll do two separate analysis, one "before", as the user is now
*--Because, as soon as a commit happens, the actual user's role are
*  updated, we'll do an reverse simulation to how it was before
*  the commit

*TODO : Make this show the correct results before and after
* 10/29/2014 : Dump at 3F's -reported by Dries.- HS
*COMMIT WORK.
*--One with the simulated changes
  DATA :
*        lt_user_con_before TYPE TABLE OF /psyng/sw_sod_output_org
*                            WITH HEADER LINE,
*         lt_user_con_after TYPE TABLE OF /psyng/sw_sod_output_org
*                            WITH HEADER LINE,
         lt_users           TYPE TABLE OF /psyng/sw_sel_opts_xubname
                            WITH HEADER LINE.
  DATA : l_task_before TYPE string,
         l_task_after TYPE string.
  lt_users-sign   = 'I'.
  lt_users-option = 'EQ'.
  lt_users-low    = l_uname.
  APPEND lt_users.

  CONCATENATE sy-uzeit l_current_user "sy-uname C0700
   'BEFORE' INTO l_task_before.
  CONCATENATE sy-uzeit l_current_user "sy-uname C0700
   'AFTER' INTO l_task_after.

  REFRESH : gt_user_con_before, gt_user_con_after.
*--Before analysis, simulate undoing the changes
  CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
      STARTING NEW TASK l_task_before
      PERFORMING get_results_before ON END OF TASK
   EXPORTING
     i_vrsio                     =  i_sod_version
*     i_shomit                    = 'X'
*BOC:HBHALLA (PN-11449)(01/08/25)
*SE SOD Check integration with SU01 to work with expired/locked users
     i_validuser                 = ' '
     i_exlckusr                  = ' '
     i_outvdate                  = ' '
*EOC:HBHALLA (PN-11449)(01/08/25)
   TABLES
     it_users                    = lt_users
     et_outputdet                = gt_user_con_before
     it_simu_role_removal        = gt_roles_removing
     it_simu_role_addition       = gt_roles_adding
  .
  ADD 1 TO g_tasks.


*--After analysis (after the changes are committed
  CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
      STARTING NEW TASK l_task_after
      PERFORMING get_results_after ON END OF TASK

   EXPORTING
     i_vrsio                     =  i_sod_version
*     i_shomit                    = 'X'
*BOC:HBHALLA (PN-11449)(01/08/25)
*SE SOD Check integration with SU01 to work with expired/locked users
     i_validuser                 = ' '
     i_exlckusr                  = ' '
     i_outvdate                  = ' '
*EOC:HBHALLA (PN-11449)(01/08/25)
   TABLES
     it_users                    = lt_users
     et_outputdet                = gt_user_con_after
            .
  ADD 1 TO g_tasks.

  WAIT UNTIL g_tasks = 0.
  SORT  gt_user_con_after  BY conid.
  SORT  gt_user_con_before BY conid.
  REFRESH : gt_user_conflicts.
  LOOP AT gt_user_con_after.
    CLEAR gt_user_conflicts.
    MOVE-CORRESPONDING gt_user_con_after TO gt_user_conflicts.
    READ TABLE gt_user_con_before
    WITH KEY conid = gt_user_con_after-conid
    BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
*--Conflict is added
      gt_user_conflicts-new = 'X'.
      CLEAR gt_user_conflicts-old.
    ELSE.
*--Conflict is unchanged
      gt_user_conflicts-new = 'X'.
      gt_user_conflicts-old = 'X'.
    ENDIF.
    APPEND gt_user_conflicts.
  ENDLOOP.
  LOOP AT gt_user_con_before.
    CLEAR gt_user_conflicts.
    MOVE-CORRESPONDING gt_user_con_before TO gt_user_conflicts.
    READ TABLE gt_user_con_after
    WITH KEY conid = gt_user_con_before-conid
    BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
*--Conflict is removed
      gt_user_conflicts-old = 'X'.
      CLEAR gt_user_conflicts-new.
      APPEND gt_user_conflicts.
    ENDIF.
  ENDLOOP.
  IF NOT gt_user_conflicts[] IS INITIAL.
    CALL SCREEN '0200' STARTING AT 10 10.
  ENDIF.
ENDFORM.                    " analyze_user
*&---------------------------------------------------------------------*
*&      Form  check_other_active_assignment
*&---------------------------------------------------------------------*
* Check if there already is an active assignment for this role that is *
* active and different from the one we're checking
*----------------------------------------------------------------------*
*      -->P_LT_EXISTING_ROLES  text
*      -->P_IT_ACTIVITY_GROUPS  text
*      -->P_LT_EXISTING_ROLES  text
*----------------------------------------------------------------------*
FORM check_other_active_assignment
TABLES   it_existing_roles STRUCTURE agr_users
USING    is_activity_group TYPE str_agrs
         is_existing_role  TYPE agr_users
CHANGING ef_exists         .
  CLEAR   ef_exists.
 LOOP AT it_existing_roles "#EC CI_NOORDER
 WHERE agr_name =  is_activity_group-agr_name
                                       AND
                            (     from_dat <> is_existing_role-from_dat
                                 OR to_dat   <> is_existing_role-to_dat
                                       )
                                       AND
                                       (   from_dat   <= sy-datum
                                         AND to_dat   >= sy-datum
                                       ).
    ef_exists = 'X'.
    EXIT. "#EC CI_NOORDER
  ENDLOOP.

ENDFORM.                    " check_other_active_assignment
*&---------------------------------------------------------------------*
*&      Form  get_user_simulation
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_ACTIVITY_GROUPS  text
*      -->P_LT_EXISTING_ROLES  text
*      -->P_LT_ROLES_ADDING  text
*      -->P_LT_ROLES_REMOVING  text
*----------------------------------------------------------------------*
FORM get_user_simulation
TABLES   it_activity_groups STRUCTURE str_agrs
         lt_existing_roles STRUCTURE agr_users
         lt_roles_adding STRUCTURE /psyng/sw_role_addition_simu
         lt_roles_removing STRUCTURE /psyng/sw_role_removal_simu
         lt_roles_before STRUCTURE /psyng/sw_role_addition_simu.
  DATA : lf_exists         TYPE flag.

*--Prepopulate common fields
  lt_roles_adding-source_rfcdest = 'LOCAL'.
  lt_roles_adding-target_rfcdest = 'LOCAL'.
  lt_roles_adding-sign           = 'I'.
  lt_roles_adding-option         = 'EQ'.
  lt_roles_before-source_rfcdest = 'LOCAL'.
  lt_roles_before-target_rfcdest = 'LOCAL'.
  lt_roles_before-sign           = 'I'.
  lt_roles_before-option         = 'EQ'.
  lt_roles_removing-rfcdest      = 'LOCAL'.
  lt_roles_removing-sign         = 'I'.
  lt_roles_removing-option       = 'EQ'.


*--determine the roles the user will ll have after this change
  LOOP AT it_activity_groups.
    READ TABLE lt_existing_roles WITH KEY
      agr_name  = it_activity_groups-agr_name.
    IF sy-subrc <> 0.
*--This role is being added
      lt_roles_adding-low = it_activity_groups-agr_name.
      APPEND lt_roles_adding.
    ELSE.
      IF lt_existing_roles-from_dat <> it_activity_groups-from_dat AND
         lt_existing_roles-to_dat   <> it_activity_groups-to_dat   AND
         sy-datum                   >= it_activity_groups-from_dat AND
         sy-datum                   <= it_activity_groups-to_dat   AND
         NOT
         (
         sy-datum                   >= lt_existing_roles-from_dat  AND
         sy-datum                   <= lt_existing_roles-to_dat
         ).
*--The role was inactive before, and becomes active now
        lt_roles_adding-low = it_activity_groups-agr_name.
        APPEND lt_roles_adding.
      ELSE.
       IF lt_existing_roles-from_dat <> it_activity_groups-from_dat AND
          lt_existing_roles-to_dat   <> it_activity_groups-to_dat   AND
           sy-datum                  >= lt_existing_roles-from_dat  AND
             sy-datum                <= lt_existing_roles-to_dat    AND
                         NOT
                         (
          sy-datum                   >= it_activity_groups-from_dat AND
                  sy-datum                 <= it_activity_groups-to_dat
                         ).
*--The role was active before, and becomes inactive now
*--We also need to check if there was another record active
*  for this role
          PERFORM check_other_active_assignment
            TABLES lt_existing_roles
            USING it_activity_groups
                  lt_existing_roles
            CHANGING lf_exists.
          IF lf_exists IS INITIAL.
*            lt_roles_removing-low = it_activity_groups-agr_name.
*            APPEND lt_roles_removing.
            lt_roles_adding-low = it_activity_groups-agr_name.
            APPEND lt_roles_adding.
          ENDIF.
        ENDIF.
      ENDIF.
      IF lt_existing_roles-from_dat = it_activity_groups-from_dat AND
         lt_existing_roles-to_dat   = it_activity_groups-to_dat   AND
         sy-datum                   >= lt_existing_roles-from_dat AND
         sy-datum                   <= lt_existing_roles-to_dat.
*--This role is being removed, and was active before
        PERFORM check_other_active_assignment
          TABLES lt_existing_roles
          USING it_activity_groups
                lt_existing_roles
          CHANGING lf_exists.
        IF lf_exists IS INITIAL.
*          lt_roles_removing-low = it_activity_groups-agr_name.
*          APPEND lt_roles_removing.
          lt_roles_removing-low = it_activity_groups-agr_name.
          APPEND lt_roles_removing.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.


  LOOP AT lt_existing_roles.
    lt_roles_before-low = lt_existing_roles-agr_name.
    COLLECT lt_roles_before.
  ENDLOOP.

ENDFORM.                    " get_user_simulation
*&---------------------------------------------------------------------*
*&      Form  top_of_list_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM top_of_list_roles.
  DATA : l_con TYPE i,
         l_rol TYPE i.
  DESCRIBE TABLE gt_role_conflicts LINES l_con.
  SORT gt_role_conflicts BY agr_name.
  LOOP AT gt_role_conflicts.
    AT NEW agr_name.
      ADD 1 TO l_rol.
    ENDAT.
  ENDLOOP.
  WRITE : / 'Roles analyzed :'(rt1), l_rol.
  WRITE : / 'Conflicts Found :'(rt2), l_con.
ENDFORM.                    " top_of_list_roles
*&---------------------------------------------------------------------*
*&      Form  top_of_list_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM top_of_list_users.
  DATA : l_con TYPE i,
         l_user TYPE i,
         l_new TYPE i,
         l_removed TYPE i.
  DESCRIBE TABLE gt_user_conflicts LINES l_con.
  SORT gt_user_conflicts BY bname.
  LOOP AT gt_user_conflicts.
    AT NEW bname.
      ADD 1 TO l_user.
    ENDAT.
    IF gt_user_conflicts-new = 'X' AND
       gt_user_conflicts-old <> 'X'.
      ADD 1 TO l_new.
    ENDIF.
    IF gt_user_conflicts-new <> 'X' AND
       gt_user_conflicts-old = 'X'.
      ADD 1 TO l_removed.
    ENDIF.
  ENDLOOP.
  WRITE : / 'Users analyzed :'(ut1), l_user.
  WRITE : / 'Conflicts Found :'(ut2), l_con.
  WRITE : / 'New Conflicts :'(ut3), l_new.
  WRITE : / 'Removed Conflicts :'(ut4), l_removed.

ENDFORM.                    " top_of_list_users

*---------------------------------------------------------------------*
*       FORM get_results_before                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  TASKNAME                                                      *
*---------------------------------------------------------------------*
FORM get_results_before USING taskname.
  DATA : l_system_msg(80) TYPE c.

  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
      TABLES
          et_outputdet                = gt_user_con_before
      EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3.

  SUBTRACT 1 FROM g_tasks.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_results_after                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  TASKNAME                                                      *
*---------------------------------------------------------------------*
FORM get_results_after USING taskname.
  DATA : l_system_msg(80) TYPE c.
  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
      TABLES
          et_outputdet                = gt_user_con_after
      EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3.

  SUBTRACT 1 FROM g_tasks.
ENDFORM.
