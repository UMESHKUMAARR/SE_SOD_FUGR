*----------------------------------------------------------------------
* Report  /PSYNG/SW_047
* AUTHOR: Security Weaver, LLC
*----------------------------------------------------------------------
*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------

REPORT /psyng/sw_047 LINE-SIZE 200.
*This report is obsolete
*TABLES: agr_define,/psyng/position, /psyng/posndet, /psyng/rolehdr,
*        agr_texts.
*
*TYPE-POOLS: slis.                                      "For ALV call
*DATA: gs_program         LIKE sy-repid.                   "For ALV call
*DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
*      gs_variant TYPE disvariant.
*DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
*DATA: g_currentrid TYPE /psyng/rolehdr-roleid,
*      g_ridcounter(4) TYPE n VALUE '0000',
*      g_ridlen TYPE i.
*
*DATA: BEGIN OF t_agrs OCCURS 10,
*        agr_name LIKE agr_define-agr_name,
*        agr_child LIKE agr_define-agr_name,
*        roleid LIKE /psyng/rolehdr-roleid,
*        positionid LIKE /psyng/position-positionid,
*        roletxt LIKE agr_texts-text,
*        flag,
*        message(100),
*      END OF t_agrs.
*
*DATA: BEGIN OF t_agrs1 OCCURS 10,
*        agr_name LIKE agr_define-agr_name,
*        agr_child LIKE agr_define-agr_name,
*        roleid LIKE /psyng/rolehdr-roleid,
*        positionid LIKE /psyng/position-positionid,
*        roletxt LIKE agr_texts-text,
*        flag,
*        message(100),
*      END OF t_agrs1.
*
*DATA: BEGIN OF output OCCURS 10,
*        positionid LIKE /psyng/position-positionid,
*        agr_name LIKE agr_define-agr_name,
*        roleid LIKE /psyng/rolehdr-roleid,
*        agr_child LIKE agr_define-agr_name,
*        roletxt LIKE agr_texts-text,
*        flag,
*        message(100),
*      END OF output.
*DATA: gs_output LIKE output.
*
*
*SELECTION-SCREEN: BEGIN OF BLOCK 1st WITH FRAME TITLE text-003.
*SELECTION-SCREEN: SKIP 1.
*
*SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 3(23) text-000.
*SELECTION-SCREEN POSITION 25.
*SELECT-OPTIONS: proles FOR agr_define-agr_name .
*SELECTION-SCREEN: END OF LINE.
*
*SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 3(23) text-001 FOR FIELD ucrid.
*SELECTION-SCREEN: POSITION 28.
*PARAMETERS: ucrid(3).          "Role ID Prefix
*SELECTION-SCREEN: END OF LINE.
*
*SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 3(23) text-002 FOR FIELD update.
*SELECTION-SCREEN: POSITION 28.
*PARAMETERS: update AS CHECKBOX.
*SELECTION-SCREEN: END OF LINE.
*
*SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 3(60) text-004.
*SELECTION-SCREEN: END OF LINE.
*SELECTION-SCREEN: SKIP 1.
*
**SELECTION-SCREEN: BEGIN OF LINE.
**SELECTION-SCREEN COMMENT 3(23) text-029 FOR FIELD sodvrsio.
**SELECTION-SCREEN: POSITION 28.
**PARAMETERS : sodvrsio like /psyng/position-vrsio.
**SELECTION-SCREEN: END OF LINE.
*
*
*SELECTION-SCREEN: END OF BLOCK 1st.
*
*
*START-OF-SELECTION.
*
*  gs_program = sy-repid.
*  PERFORM get_import_from_pfcg.
*  PERFORM validate_roles.
*  IF update = 'X'.
*    PERFORM update_tables.
*  ENDIF.
*  PERFORM build_alv_catalog.
*  PERFORM output_using_alv.
*
**&---------------------------------------------------------------------*
**&      Form  get_import_from_pfcg
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*FORM get_import_from_pfcg.
*  DATA: iagr_agrs TYPE STANDARD TABLE OF agr_agrs WITH HEADER LINE.
*
*  AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
*           ID 'ACTVT' FIELD '60'
*           ID 'Y&SW_ROLID' DUMMY.
*  IF sy-subrc NE 0.
*    MESSAGE e113(/psyng/sw) WITH text-006.
*    STOP.
*  ENDIF.
*
*  g_ridlen = strlen( ucrid ).
*
*  SELECT * FROM agr_agrs
*           INTO TABLE iagr_agrs
*           WHERE agr_name IN proles.
*
*  SORT: iagr_agrs.
*  DELETE ADJACENT DUPLICATES FROM iagr_agrs.
*
*  LOOP AT iagr_agrs.
*    SELECT * FROM agr_define INTO agr_define
*    WHERE agr_name = iagr_agrs-child_agr.
*      IF agr_define-parent_agr = space.
*        t_agrs-agr_name  = iagr_agrs-agr_name.
*        t_agrs-agr_child = iagr_agrs-child_agr.
*        t_agrs-positionid   = g_currentrid.
*        SELECT SINGLE * FROM agr_texts INTO agr_texts
*        WHERE agr_name = iagr_agrs-agr_name
*        AND spras      = sy-langu
*        AND line       = '00000'.
*        t_agrs-roletxt   = agr_texts-text.
*        APPEND t_agrs.
*      ELSE.
*        t_agrs-agr_name  = iagr_agrs-agr_name.
*        t_agrs-agr_child = agr_define-parent_agr.
*        t_agrs-positionid    = g_currentrid.
*        SELECT SINGLE * FROM agr_texts INTO agr_texts
*        WHERE agr_name = iagr_agrs-agr_name
*        AND spras      = sy-langu
*        AND line       = '00000'.
*        t_agrs-roletxt   = agr_texts-text.
*        APPEND t_agrs.
*      ENDIF.
*    ENDSELECT.
*
*  ENDLOOP.
*ENDFORM.                    " get_import_from_pfcg
**&---------------------------------------------------------------------*
**&      Form  build_alv_catalog
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------
*FORM build_alv_catalog.
*  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
*
*  gs_program = sy-repid.
*
*  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
*       EXPORTING
*            i_program_name     = gs_program
*            i_internal_tabname = 'OUTPUT'
*            i_inclname         = gs_program
*       CHANGING
*            ct_fieldcat        = i_fieldcat_alv.
*
*  wa_fieldcat_alv-seltext_l = text-008.
*  wa_fieldcat_alv-seltext_m = text-009.
*  wa_fieldcat_alv-seltext_s = text-010.
*  wa_fieldcat_alv-reptext_ddic = text-010.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      seltext_l
*                      seltext_m
*                      seltext_s
*                      reptext_ddic
*                   WHERE
*                      fieldname = 'POSITIONID'.
*
*  wa_fieldcat_alv-seltext_l = text-011.
*  wa_fieldcat_alv-seltext_m = text-011.
*  wa_fieldcat_alv-seltext_s = text-012.
*  wa_fieldcat_alv-reptext_ddic = text-012.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      seltext_l
*                      seltext_m
*                      seltext_s
*                      reptext_ddic
*                   WHERE
*                      fieldname = 'AGR_NAME'.
*
*  wa_fieldcat_alv-seltext_l = text-013.
*  wa_fieldcat_alv-seltext_m = text-014.
*  wa_fieldcat_alv-seltext_s = text-014.
*  wa_fieldcat_alv-reptext_ddic = text-014.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      seltext_l
*                      seltext_m
*                      seltext_s
*                      reptext_ddic
*                   WHERE
*                      fieldname = 'ROLEID'.
*
*  wa_fieldcat_alv-seltext_l = text-015.
*  wa_fieldcat_alv-seltext_m = text-015.
*  wa_fieldcat_alv-seltext_s = text-015.
*  wa_fieldcat_alv-reptext_ddic = text-015.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      seltext_l
*                      seltext_m
*                      seltext_s
*                      reptext_ddic
*                   WHERE
*                      fieldname = 'AGR_CHILD'.
*
*
*
*  wa_fieldcat_alv-seltext_l = text-016.
*  wa_fieldcat_alv-seltext_m = text-017.
*  wa_fieldcat_alv-seltext_s = text-018.
*  wa_fieldcat_alv-reptext_ddic = text-018.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      seltext_l
*                      seltext_m
*                      seltext_s
*                      reptext_ddic
*                   WHERE
*                      fieldname = 'ROLETXT'.
*
*  wa_fieldcat_alv-seltext_l = text-019.
*  wa_fieldcat_alv-seltext_m = text-019.
*  wa_fieldcat_alv-seltext_s = text-020.
*  wa_fieldcat_alv-reptext_ddic = text-019.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      seltext_l
*                      seltext_m
*                      seltext_s
*                      reptext_ddic
*                   WHERE
*                      fieldname = 'MESSAGE'.
*
*ENDFORM.                    " build_alv_catalog
**&---------------------------------------------------------------------*
**&      Form  output_using_alv
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*FORM output_using_alv.
*  DATA: alv_layout TYPE slis_layout_alv.
*
*  alv_layout-zebra = 'X'.
*  alv_layout-colwidth_optimize = 'X'.
*
*  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
*       EXPORTING
*            i_grid_title       = text-021
*            i_callback_program = gs_program
*            it_sort            = isort
*            is_layout          = alv_layout
*            i_save             = 'A'
*            is_variant         = gs_variant
*            it_fieldcat        = i_fieldcat_alv
*       TABLES
*            t_outtab           = output.
*
*ENDFORM.                    " output_using_alv
*
**&---------------------------------------------------------------------*
**&      Form  update_tables
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*FORM update_tables.
*  LOOP AT output INTO output.
*    gs_output = output.
*    AT NEW agr_name.
*      IF gs_output-flag = 'Y'.
*        /psyng/position-positionid  = gs_output-positionid.
*        /psyng/position-saptechname = gs_output-agr_name.
*        /psyng/position-description = gs_output-roletxt.
*        /psyng/position-create_usr  = sy-uname.
*        /psyng/position-create_dat  = sy-datum.
*        /psyng/position-create_tim  = sy-uzeit.
*        output = gs_output.
*        INSERT /psyng/position.
*        IF sy-subrc <> 0.
*          output-message = text-023.
*        ELSE.
*          output-message = text-024.
*        ENDIF.
*        MODIFY output.
*      ENDIF.
*    ENDAT.
*    IF gs_output-flag = 'Y'.
*      /psyng/posndet-positionid = gs_output-positionid.
*      /psyng/posndet-roleid     = gs_output-roleid.
*      INSERT /psyng/posndet.
*      IF sy-subrc <> 0.
*        output-message = text-023.
*      ELSE.
*        output-message = text-024.
*      ENDIF.
*      MODIFY output.
*    ENDIF.
*    AT LAST.
*      IF gs_output-flag = 'Y'.
*        /psyng/position-positionid  = gs_output-positionid.
*        /psyng/position-saptechname = gs_output-agr_name.
*        /psyng/position-description = gs_output-roletxt.
*        /psyng/position-create_usr  = sy-uname.
*        /psyng/position-create_dat  = sy-datum.
*        /psyng/position-create_tim  = sy-uzeit.
*        output = gs_output.
*        INSERT /psyng/position.
*        IF sy-subrc <> 0.
*          output-message = text-023.
*        ELSE.
*          output-message = text-024.
*        ENDIF.
*        MODIFY output.
*      ENDIF.
*
*    ENDAT.
*  ENDLOOP.
*ENDFORM.                    " update_tables
*
**&---------------------------------------------------------------------*
**&      Form  validate_roles
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*FORM validate_roles.
*  DATA: first_pass.
*
*  first_pass = space.
*  LOOP AT t_agrs.
*    t_agrs1 = t_agrs.
*    APPEND t_agrs1.
*    AT NEW agr_name.
*      IF first_pass = space.
*        first_pass = 'X'.
*      ELSE.
*        SORT t_agrs1.
*        DELETE ADJACENT DUPLICATES FROM t_agrs1.
*        DELETE t_agrs1 WHERE agr_name = t_agrs-agr_name.
*        PERFORM populate_data.
*      ENDIF.
*    ENDAT.
*    t_agrs1 = t_agrs.
*    APPEND t_agrs1.
*    AT LAST.
*      SORT t_agrs1.
*      DELETE ADJACENT DUPLICATES FROM t_agrs1.
*      PERFORM populate_data.
*    ENDAT.
*  ENDLOOP.
*
*ENDFORM.                    " validate_roles
**&---------------------------------------------------------------------*
**&      Form  populate_data
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*FORM populate_data.
*  DATA: l_flag_p.
*
*  l_flag_p = space.
*  LOOP AT t_agrs1.
**    select single * from /psyng/rolehdr
**     into /psyng/rolehdr
**    where saptechname = t_agrs1-agr_child.
*
*    SELECT SINGLE roleid FROM /psyng/rolehdr         "#EC CI_SEL_NESTED
*     INTO /psyng/rolehdr-roleid
*    WHERE saptechname = t_agrs1-agr_child.
*    IF sy-subrc <> 0.
*      l_flag_p = 'X'.
*    ELSE.
*      t_agrs1-roleid = /psyng/rolehdr-roleid.
*      MODIFY t_agrs1.
*    ENDIF.
*  ENDLOOP.
*  IF l_flag_p = space.
*    PERFORM get_nextrid.
*    LOOP AT t_agrs1.
*      output-agr_name  = t_agrs1-agr_name.
*      output-agr_child = t_agrs1-agr_child.
*      output-positionid = g_currentrid.
*      output-roleid    = t_agrs1-roleid.
*      output-roletxt   = t_agrs1-roletxt.
*      output-flag      = 'Y'.
*      output-message   = text-025.
*      APPEND output.
*    ENDLOOP.
*  ELSE.
*    LOOP AT t_agrs1.
*      output-agr_name  = t_agrs1-agr_name.
*      output-agr_child = t_agrs1-agr_child.
*      output-positionid = space.
*      output-roleid    = t_agrs1-roleid.
*      output-roletxt   = t_agrs1-roletxt.
*      output-flag      = 'N'.
*      output-message   = text-027.
*      IF t_agrs1-roleid = space.
*        output-message   = text-028.
*      ENDIF.
*      APPEND output.
*    ENDLOOP.
*  ENDIF.
*  REFRESH t_agrs1. CLEAR t_agrs1.
*ENDFORM.                    " populate_data
*
**&---------------------------------------------------------------------*
**&      Form  get_nextrid
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------
*FORM get_nextrid.
*
*  ADD 1 TO g_ridcounter.
*
*  CASE g_ridlen.
*    WHEN 0.
*      CONCATENATE ucrid g_ridcounter+0(4) INTO g_currentrid.
*    WHEN 1.
*      CONCATENATE ucrid g_ridcounter+1(3) INTO g_currentrid.
*    WHEN 2.
*      CONCATENATE ucrid g_ridcounter+2(2) INTO g_currentrid.
*    WHEN 3.
*      CONCATENATE ucrid g_ridcounter+3(1) INTO g_currentrid.
*    WHEN OTHERS.
*  ENDCASE.
*
*ENDFORM.                    " get_nextrid
