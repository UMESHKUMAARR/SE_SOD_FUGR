
*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SECUWELLI01
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*
*----------------------------------------------------------------------*

*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SECUWELLI01                                         *
*----------------------------------------------------------------------*
* INPUT MODULE FOR TABSTRIP 'YX_SECTAB': GETS ACTIVE TAB
MODULE yx_sectab_active_tab_get INPUT.
  CASE ok_code.
    WHEN c_yx_sectab-tab1.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab1.
    WHEN c_yx_sectab-tab2.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab2.
    WHEN c_yx_sectab-tab3.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab3.
    WHEN c_yx_sectab-tab4.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab4.
    WHEN c_yx_sectab-tab5.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab5.
    WHEN c_yx_sectab-tab6.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab6.
    WHEN c_yx_sectab-tab7.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab7.
    WHEN c_yx_sectab-tab8.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab8.
  ENDCASE.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
*BOC UMITTAL 14/01/2025 ATC BMW checks PN 11269
  CONSTANTS : lc_func(4) VALUE 'FUNC',
              lc_conf(4) VALUE 'CONF',
              lc_mitc(4) VALUE 'MITC',
              lc_rlhdr(5) VALUE 'RLHDR',
              lc_rltxn(5) VALUE 'RLTXN'.

  CASE ok_code.
*    WHEN 'FUNC'.
    WHEN lc_func.
      CALL SCREEN '0201'.

*    WHEN 'CONF'. "#EC SAST_CI_GEN_CHECK
    WHEN lc_conf. "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (06/12/24)
      CALL SCREEN '0202'.

*    WHEN 'MITC'. "#EC SAST_CI_GEN_CHECK
    WHEN lc_mitc. "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (06/12/24)
      CALL SCREEN '0203'.

    WHEN lc_rlhdr. "#EC SAST_CI_GEN_CHECK
*    WHEN 'RLHDR'. "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (06/12/24)
      CALL SCREEN '0301'.

*    WHEN 'RLTXN'. "#EC SAST_CI_GEN_CHECK
    WHEN lc_rltxn. "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (06/12/24)
      CALL SCREEN '0302'.
*    WHEN 'ADVSIM'.
*      CALL FUNCTION '/PSYNG/SW_080'.

  ENDCASE.
*EOC UMITTAL 14/01/2025 ATC BMW checks PN 11269
ENDMODULE.                 " USER_COMMAND_0100  INPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0101  INPUT
*&---------------------------------------------------------------------*
*       Handle user commands for screen 101
*----------------------------------------------------------------------*
MODULE user_command_0101 INPUT.
  CASE ok_code.
    WHEN 'SWURL'.
      CALL FUNCTION 'CALL_BROWSER'
        EXPORTING
          url                    = text-005
        EXCEPTIONS
          frontend_not_supported = 1
          frontend_error         = 2
          prog_not_found         = 3
          no_batch               = 4
          unspecified_error      = 5
          OTHERS                 = 6.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0101  INPUT

*&---------------------------------------------------------------------*
*&      Module  COMMAND_EDITOR312  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE command_editor312 INPUT.
* move text from edit control to table i_text
  PERFORM get_editor_text.
ENDMODULE.                 " COMMAND_EDITOR312  INPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0201  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0201 INPUT.
  PERFORM user_command_0201.
ENDMODULE.                 " USER_COMMAND_0201  INPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0202  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0202 INPUT.
  PERFORM user_command_0202.
ENDMODULE.                 " USER_COMMAND_0202  INPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0208  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0208 INPUT.
  DATA l_flag TYPE flag VALUE 'X'.           "HBHALLA
  PERFORM user_command_0208 CHANGING l_flag. "HBHALLA
ENDMODULE.                 " USER_COMMAND_0208  INPUT

MODULE user_command_0229 INPUT.

*BOC HBHALLA 14/01/2025 ATC checks PN 11269
 CONSTANTS: lc_dell(4) VALUE 'DELL',
            lc_insr(4) VALUE 'INSR'.

  CASE sy-ucomm.
*    WHEN 'DELL'.
    WHEN lc_dell.

      READ TABLE g_trans_itab WITH KEY flag = gc_select.
      DELETE g_trans_itab WHERE flag = 'X'.

      IF sy-subrc <> 0.
        CLEAR : ok_code, sy-ucomm.
        MESSAGE e161(/psyng/sw).
      ELSE.
        DESCRIBE TABLE g_trans_itab LINES critrans-lines.
        gf_data_change = 'X'.
      ENDIF.
*    WHEN 'INSR'.
    WHEN lc_insr.
*      ADD 20 TO critrans-lines.
      LOOP AT g_trans_itab WHERE flag = 'X'.
        CLEAR g_trans_itab-flag.
        MODIFY g_trans_itab.
      ENDLOOP.

      DESCRIBE TABLE g_trans_itab LINES critrans-lines.
      PERFORM insert_row_into_tc USING  'CRITRANS' 'G_TRANS_ITAB'.
      gf_data_change = 'X'.
  ENDCASE.
*EOC HBHALLA 14/01/2025 ATC checks PN 11269

ENDMODULE.


MODULE user_command_0230 INPUT.
  DATA: l_selline        TYPE i.

  CASE ok_code. "C1321 BUG
    WHEN 'INFO'.
      GET CURSOR LINE l_selline.
*--BOC AKUMAR C1321
      l_selline = l_selline + fioriapps-top_line - 1.
*--EOC AKUMAR C1321
      READ TABLE gt_fiori_app INDEX l_selline .
      IF sy-subrc = 0.
        CALL FUNCTION '/PSYNG/SW_FIORIAPP_SHOW'
          EXPORTING
            i_fioriid = gt_fiori_app-fioriid
          EXCEPTIONS
            not_found = 1
            OTHERS    = 2.
        IF sy-subrc <> 0.
          MESSAGE i113(/psyng/sw) WITH
               'Detail not found'(a01).
        ENDIF.
      ELSE.
*---to do
      ENDIF.
    WHEN 'DEFINE_APP'.
      CALL FUNCTION '/PSYNG/SW_FIORIAPP_EDIT'
*       EXPORTING
*         I_FIORIID       =
        .
    WHEN 'DELL'.
      READ TABLE gt_fiori_app WITH KEY flag = gc_select.
      DELETE gt_fiori_app WHERE flag = 'X'.
      IF sy-subrc <> 0.
        CLEAR : ok_code, sy-ucomm.
        MESSAGE e161(/psyng/sw).
      ELSE.
        DESCRIBE TABLE gt_fiori_app LINES fioriapps-lines.
        gf_data_change = 'X'.
      ENDIF.

    WHEN 'INSR'.
      LOOP AT gt_fiori_app WHERE flag = 'X'.
        CLEAR gt_fiori_app-flag.
        MODIFY gt_fiori_app.
      ENDLOOP.

      DESCRIBE TABLE gt_fiori_app LINES fioriapps-lines.
      PERFORM insert_row_into_tc USING  'FIORIAPPS' 'GT_FIORI_APP'.
      gf_data_change = 'X'.
  ENDCASE.
ENDMODULE.
* INPUT MODULE FOR TABLECONTROL 'TRANS': MODIFY TABLE
MODULE trans_modify INPUT.

  IF tstct-tcode IS INITIAL   AND ok_code NE 'DELL'.
    DELETE g_trans_itab INDEX critrans-current_line.
    DESCRIBE TABLE g_trans_itab LINES critrans-lines.
    EXIT.
  ENDIF.

* Mark entry for deletion without validations
  IF ok_code = 'DELL'.
    g_trans_itab-tcode = tstct-tcode.
    g_trans_itab-flag = 'X'.
    MODIFY g_trans_itab
    INDEX critrans-current_line
    TRANSPORTING tcode flag.
*TRANSPORTING flag WHERE tcode = tstct-tcode.
    IF sy-subrc <> 0.
      APPEND g_trans_itab.
      IF gf_dispchg = gc_change.
        gf_data_change = gc_select.
      ENDIF.
    ENDIF.
    EXIT.
  ENDIF.

  CLEAR g_trans_itab.
  MOVE-CORRESPONDING tstct TO g_trans_wa.

  g_trans_itab-tcode = tstct-tcode.
*  g_trans_itab-imp   = g_trans_itab-imp.
*  g_trans_itab-owner = g_trans_itab-owner.
*  g_trans_itab-description = g_trans_itab-description.

  CLEAR g_trans_itab-ttext.
  SELECT SINGLE ttext INTO g_trans_itab-ttext FROM tstct
  WHERE tcode = tstct-tcode
  AND sprsl = sy-langu.
  IF sy-subrc <> 0.
*--TCOde does not exist in this system
    IF tstct-tcode  CP
        /psyng/sw_cl_constants=>placeholder_tcode_prefix.
      g_trans_itab-ttext =
      'Placeholder for object level analysis'(191).
    ELSE.
      g_trans_itab-ttext =
      'Tcode for cross system analysis'(192).
    ENDIF.
  ENDIF.

* Check for existing entry
  LOOP AT g_trans_itab WHERE tcode = g_trans_itab-tcode.
    IF sy-tabix <> critrans-current_line.
      CLEAR : ok_code, sy-ucomm.
      MESSAGE e101(/psyng/sw).
    ENDIF.
  ENDLOOP.
  MODIFY g_trans_itab INDEX critrans-current_line.
  IF sy-subrc <> 0.
    APPEND g_trans_itab.
  ENDIF.
*===========================================================
* Add new function module here
  IF ok_code = 'ENTER'.
    PERFORM get_parameter.
  ENDIF.
*===========================================================


ENDMODULE.

MODULE app_modify INPUT.
  IF /psyng/sw_fioria-fioriid IS INITIAL AND ok_code NE 'DELL'.
    DELETE gt_fiori_app INDEX fioriapps-current_line.
    DESCRIBE TABLE gt_fiori_app LINES fioriapps-lines.
    EXIT.
  ENDIF.
* Mark entry for deletion without validations
  IF ok_code = 'DELL'.
    gt_fiori_app-fioriid = /psyng/sw_fioria-fioriid.
    gt_fiori_app-flag = 'X'.
    MODIFY gt_fiori_app INDEX fioriapps-current_line
    TRANSPORTING fioriid flag.
    IF sy-subrc <> 0.
      APPEND gt_fiori_app.
      IF gf_dispchg = gc_change.
        gf_data_change = gc_select.
      ENDIF.
    ENDIF.
    EXIT.
  ENDIF.

  CLEAR gt_fiori_app.
  MOVE-CORRESPONDING /psyng/sw_fioria TO gs_fiori_wa.
  gt_fiori_app-fioriid = /psyng/sw_fioria-fioriid.
  CLEAR gt_fiori_app-appname.
  SELECT SINGLE appname INTO gt_fiori_app-appname FROM /psyng/sw_fioria
  WHERE fioriid = /psyng/sw_fioria-fioriid.

  LOOP AT gt_fiori_app WHERE fioriid = gt_fiori_app-fioriid.
    IF sy-tabix <> fioriapps-current_line.
      MESSAGE e101(/psyng/sw).
    ENDIF.
  ENDLOOP.

  MODIFY gt_fiori_app INDEX fioriapps-current_line.
  IF sy-subrc <> 0.
    APPEND gt_fiori_app.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  IMP_MODIFY  INPUT
*&---------------------------------------------------------------------*
*       Modify Importance field for Critical Transactions
*----------------------------------------------------------------------*
MODULE imp_modify INPUT.
  MODIFY g_trans_itab FROM g_trans_wa INDEX critran-current_line
         TRANSPORTING imp.
ENDMODULE.                 " IMP_MODIFY  INPUT

*====================================================================
* INPUT MODULE FOR TABLECONTROL 'CRITROLE': MARK TABLE
MODULE criroles_mark INPUT.
  MODIFY g_criroles_itab
    FROM g_critrole_wa
    INDEX critrole-current_line.
*    TRANSPORTING FLAG.
ENDMODULE.

* INPUT MODULE FOR TABLECONTROL 'TRANS': MODIFY TABLE
MODULE critrole_modify INPUT.
  gf_data_change = gc_select.
  CLEAR g_criroles_itab.

* Mark entry for deletion without validations
  IF ok_code = 'DELL'.
    g_criroles_itab-agr_name = agr_texts-agr_name.
    g_criroles_itab-flag = 'X'.
    MODIFY g_criroles_itab INDEX critrole-current_line.
    IF sy-subrc <> 0.
      APPEND g_criroles_itab.
    ENDIF.

    EXIT.
  ENDIF.

  IF agr_texts-agr_name IS INITIAL.
    DELETE g_criroles_itab INDEX critrole-current_line.
    EXIT.
  ENDIF.

  MOVE-CORRESPONDING agr_texts TO g_critrole_wa.
  g_critrole_wa-text = agr_texts-text.
  g_criroles_itab-agr_name = agr_texts-agr_name.

  CLEAR g_criroles_itab-text.
  SELECT SINGLE text INTO g_criroles_itab-text FROM agr_texts
  WHERE agr_name  = g_criroles_itab-agr_name
  AND spras = sy-langu
  AND line = 0.

* Removing validation as part of SE 3.1

  SELECT SINGLE mandt INTO sy-mandt FROM agr_define
                WHERE agr_name = agr_texts-agr_name.
  IF sy-subrc <> 0.
*--Role does not exist in this system
    g_criroles_itab-text =
    'Role for cross system analysis'(299).
  ENDIF.
*  ENDIF.

* Check for existing entry
*BOC: HBHALLA
IF gt_criroles_bckup[] IS INITIAL.
  LOOP AT g_criroles_itab WHERE agr_name = g_criroles_itab-agr_name.
    IF sy-tabix <> critrole-current_line.
      MESSAGE e101(/psyng/sw).
    ENDIF.
  ENDLOOP.
ELSE.
  READ TABLE gt_criroles_bckup WITH KEY agr_name = g_criroles_itab-agr_name.
    IF sy-subrc = 0.
      CLEAR : ok_code, sy-ucomm.
      LOOP AT SCREEN.
        IF SCREEN-NAME EQ 'AGR_TEXTS-AGR_NAME'.
          CLEAR: AGR_TEXTS-AGR_NAME.
        ENDIF.
      ENDLOOP.
      MESSAGE e099(/psyng/sw) WITH g_criroles_itab-agr_name.
    ENDIF.
ENDIF.
*End Of Change: HBHALLA

  MODIFY g_criroles_itab INDEX critrole-current_line.
  IF sy-subrc <> 0.
    APPEND g_criroles_itab.
  ENDIF.

*BOC: HBHALLA
 IF gt_criroles_bckup[] IS NOT INITIAL.
    APPEND g_criroles_itab TO gt_criroles_bckup[].
 ENDIF.
*END OF CHANGE: HBHALLA

ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE critprof_modify INPUT                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE critprof_modify INPUT.
  gf_data_change = gc_select.

  usr11-profn = g_profile.



* Mark entry for deletion without validations
  IF ok_code = 'DELL'.
    g_criprofs_itab-profn = usr11-profn.
    g_criprofs_itab-flag = 'X'.
    MODIFY g_criprofs_itab INDEX critprof-current_line TRANSPORTING
profn flag.
    IF sy-subrc <> 0.
      APPEND g_criprofs_itab.
    ENDIF.

    EXIT.
  ENDIF.

  IF usr11-profn IS INITIAL.
    DELETE g_criprofs_itab INDEX critprof-current_line.
    EXIT.
  ENDIF.

  MOVE-CORRESPONDING usr11 TO g_critprof_wa.
  g_critprof_wa-ptext = usr11-ptext.
*  g_critprof_wa-imp  = g_criprofs_itab-imp.
  g_criprofs_itab-profn = usr11-profn.
  CLEAR g_criprofs_itab-flag.

*  g_criprofs_itab-description = g_critprof_wa-description.

  CLEAR g_criprofs_itab-ptext.
  SELECT SINGLE ptext INTO g_criprofs_itab-ptext FROM usr11
  WHERE profn  = g_criprofs_itab-profn
  AND langu = sy-langu
  AND aktps = 'A'.

* Verify that profile exists
  SELECT SINGLE mandt INTO sy-mandt FROM usr10
                WHERE profn = usr11-profn
                  AND aktps = 'A'.
  IF sy-subrc <> 0.
*--Profile  does not exist in this system
    g_criprofs_itab-ptext =
    'Profile for cross system analysis'(300).
  ENDIF.

* Check for existing entry
*BOC: HBHALLA
IF gt_criprofs_bckup[] IS INITIAL.
  LOOP AT g_criprofs_itab WHERE profn = g_criprofs_itab-profn.
    IF sy-tabix <> critprof-current_line.
      MESSAGE e101(/psyng/sw).
    ENDIF.
  ENDLOOP.
ELSE.
  READ TABLE gt_criprofs_bckup WITH KEY profn = g_criprofs_itab-profn.
    IF sy-subrc = 0.
      CLEAR : ok_code, sy-ucomm.
      LOOP AT SCREEN.
        IF SCREEN-NAME EQ 'G_PROFILE'.
          CLEAR: G_PROFILE.
        ENDIF.
      ENDLOOP.
      MESSAGE e099(/psyng/sw) WITH g_criprofs_itab-profn.
    ENDIF.
ENDIF.
*End Of Change: HBHALLA

  MODIFY g_criprofs_itab INDEX critprof-current_line.
  IF sy-subrc <> 0.
    APPEND g_criprofs_itab.
  ENDIF.

*BOC: HBHALLA
 IF gt_criprofs_bckup[] IS NOT INITIAL.
    APPEND g_criprofs_itab TO gt_criprofs_bckup[].
 ENDIF.
*END OF CHANGE: HBHALLA

ENDMODULE.

*=====================================================================
* INPUT MODULE FOR TABLECONTROL 'FUNCT': MODIFY TABLE
MODULE funct_modify INPUT.
  gf_data_change = gc_select.

* Mark entry for deletion without validations
  IF ok_code = 'DELL'.
    g_funct_itab-flag = 'X'.
    MODIFY g_funct_itab INDEX funct-current_line
    TRANSPORTING flag.

    IF sy-subrc <> 0.
      APPEND g_funct_itab.
    ENDIF.
    CLEAR g_funct_itab-flag.
    EXIT.
  ENDIF.

  IF /psyng/functtran-functionid IS INITIAL.
    DELETE g_funct_itab INDEX funct-current_line.
    DESCRIBE TABLE g_funct_itab LINES funct-lines.
    EXIT.
  ENDIF.

  MOVE-CORRESPONDING /psyng/functtran TO g_funct_wa.
  MOVE-CORRESPONDING /psyng/function  TO g_funct_wa.


  SELECT SINGLE description INTO g_funct_itab-description
           FROM /psyng/function
          WHERE function = /psyng/functtran-functionid
            AND vrsio    = g_sod_vrsio.

  g_funct_itab-function = /psyng/functtran-functionid.

  IF sy-subrc <> 0.
    CLEAR g_funct_itab-description.
  ENDIF.

  MODIFY g_funct_itab INDEX funct-current_line
  TRANSPORTING function description.

  IF sy-subrc <> 0.
    APPEND g_funct_itab.
  ENDIF.

* Check for existing entry
  LOOP AT g_funct_itab WHERE function = g_funct_itab-function.
    IF sy-tabix <> funct-current_line.
      MESSAGE e101(/psyng/sw).
    ENDIF.
  ENDLOOP.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0301  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0301 INPUT.
  PERFORM user_command_0301.
ENDMODULE.                 " USER_COMMAND_0301  INPUT

* INPUT MODULE FOR TABSTRIP 'ROLEHDR': GETS ACTIVE TAB
MODULE rolehdr_active_tab_get INPUT.
  CASE ok_code.
    WHEN c_rolehdr-tab1.
      g_rolehdr-pressed_tab = c_rolehdr-tab1.
    WHEN c_rolehdr-tab2.
      g_rolehdr-pressed_tab = c_rolehdr-tab2.
  ENDCASE.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0312  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0312 INPUT.
  CASE ok_code.
    WHEN c_rolehdr-tab1.
      g_rolehdr-pressed_tab = c_rolehdr-tab1.
    WHEN c_rolehdr-tab2.
      g_rolehdr-pressed_tab = c_rolehdr-tab2.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0312  INPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0302  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0302 INPUT.
  PERFORM user_command_0302.
ENDMODULE.                 " USER_COMMAND_0302  INPUT

* INPUT MODULE FOR TABLECONTROL 'ROLE_TRANS': MODIFY TABLE
MODULE role_trans_modify INPUT.
  gf_data_change = gc_select.

  IF tstct-tcode IS INITIAL.
    DELETE g_trans_itab INDEX role_trans-current_line.
    EXIT.
  ENDIF.

* Mark entry for deletion without validations
  IF ok_code = 'DELALL'.
    g_role_trans_itab-flag = 'X'.
    MODIFY g_role_trans_itab INDEX role_trans-current_line.
    IF sy-subrc <> 0.
      APPEND g_role_trans_itab.
    ENDIF.

    EXIT.
  ENDIF.

  MOVE-CORRESPONDING tstct TO g_role_trans_wa.

  g_role_trans_itab-tcode = tstct-tcode.

  CLEAR g_role_trans_itab-ttext.
  SELECT SINGLE ttext INTO g_role_trans_itab-ttext FROM tstct
  WHERE tcode = tstct-tcode
  AND sprsl = sy-langu.

* Check for existing entry
  LOOP AT g_role_trans_itab WHERE tcode = g_role_trans_itab-tcode.
    IF sy-tabix <> role_trans-current_line.
      MESSAGE e101(/psyng/sw).
    ENDIF.
  ENDLOOP.
  MODIFY g_role_trans_itab INDEX role_trans-current_line.
  IF sy-subrc <> 0.
    APPEND g_role_trans_itab.
  ENDIF.



ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  GET_FIELD_CURSOR  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_field_cursor INPUT.
  GET CURSOR FIELD cursor_field .
  GET CURSOR LINE  cursor_line  .
  IF ok_code = '' . "#EC SAST_CI_GEN_CHECK (HBHALLA)
    cursor_line = cursor_line + 1.
  ENDIF.
  j = 0.
ENDMODULE.                 " GET_FIELD_CURSOR  INPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0104  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0104 INPUT.
  PERFORM user_command_0104.
ENDMODULE.                 " USER_COMMAND_0104  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHANGE_FLAG  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE change_flag INPUT.
  PERFORM exit_without_save.
  IF gf_answer <> 1.
    CASE sy-dynnr.
      WHEN '0104'.
        /psyng/posndet-positionid = /psyng/position-positionid.
      WHEN '0105'.
        /psyng/user-userid = userid.
      WHEN '0201'.
        /psyng/functtran-functionid = /psyng/function-function.
      WHEN '0202'.
        /psyng/confdet-conid = /psyng/conflict-conid.
      WHEN '0301' OR '0302'.
        /psyng/roletrans-roleid = /psyng/rolehdr-roleid.
    ENDCASE.

    EXIT.
  ENDIF.

  PERFORM refresh_tree_change.
*  first_time = space.
  REFRESH i_text.
  REFRESH conflict.
  REFRESH conflict2.
  REFRESH g_role_trans_itab.
  REFRESH g_jobtxn_itab.
* User must enter ID unless navigating to a different tab
  IF ok_code NS '_FC'.
    CASE sy-dynnr.
      WHEN '0104'.
*******************
*      Case#1939
*      Prevent exclude check for 'FIND' Button
        CHECK ok_code NE 'FIND'.
*******************
        IF /psyng/posndet-positionid IS INITIAL.
          MESSAGE e106(/psyng/sw) WITH text-007.
        ENDIF.

      WHEN '0201'.
        IF /psyng/functtran-functionid IS INITIAL.
          MESSAGE e106(/psyng/sw) WITH text-004.
        ENDIF.

      WHEN '0202' .
      WHEN '0203'.
        IF /psyng/mchdr-contid IS INITIAL.
          MESSAGE e106(/psyng/sw) WITH text-011.
        ENDIF.
*        IF /psyng/confdet-conid IS INITIAL.
*          MESSAGE e106(/psyng/sw) WITH 'Conflict ID'(006).
*        ENDIF.
    ENDCASE.
  ENDIF.
ENDMODULE.                 " CHANGE_FLAG  INPUT

*&---------------------------------------------------------------------*
*&      Module  ROLE_TRANS_CHANGE_COL_ATTR  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE role_trans_change_col_attr INPUT.
  LOOP AT SCREEN.
    IF screen-name = 'TSTCT-TCODE'.
      LOOP AT   g_role_trans_itab.
        IF screen-name = 'TSTCT-TCODE'.
          screen-input = '1'.
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
ENDMODULE.                 " ROLE_TRANS_CHANGE_COL_ATTR  INPUT

*&---------------------------------------------------------------------*
*&      Module  PAI_100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pai_100 INPUT.
  DATA: return_code TYPE i.
* CL_GUI_CFW=>DISPATCH must be called if events are registered
* that trigger PAI
* this method calls the event handler method of an event
  CALL METHOD cl_gui_cfw=>dispatch
    IMPORTING
      return_code = return_code.
  IF return_code <> cl_gui_cfw=>rc_noevent.
    " a control event occured => exit PAI
    CLEAR g_ok_code.
    EXIT.
  ENDIF.

  CASE g_ok_code.
    WHEN 'BACK'. " Finish program
      IF NOT g_left_custom_container IS INITIAL.
        " destroy tree containers (detroys contained tree control, too)
        CALL METHOD g_left_custom_container->free
          EXCEPTIONS
            cntl_system_error = 1
            cntl_error        = 2.
        IF sy-subrc <> 0.
*          MESSAGE A000.
        ENDIF.
        CALL METHOD g_right_custom_container->free
          EXCEPTIONS
            cntl_system_error = 1
            cntl_error        = 2.
        IF sy-subrc <> 0.
*          MESSAGE A000.
        ENDIF.
        CLEAR g_left_custom_container.
        CLEAR g_right_tree.
        CLEAR g_left_custom_container.
        CLEAR g_right_tree.
      ENDIF.
      LEAVE PROGRAM.
  ENDCASE.

* CAUTION: clear ok code!
*  CLEAR OK_CODE.
*
ENDMODULE.                 " PAI_100  INPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0105  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0105 INPUT.
  PERFORM user_command_0105.
ENDMODULE.                 " USER_COMMAND_0105  INPUT



*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0206  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0206 INPUT.
  CONCATENATE /psyng/roletrans-roleid /psyng/conflict-conid
              INTO usr_mit.
  populated = 'X'.
  CASE ok_code.
    WHEN 'REFRESH'.
      first_time = space.
*      FIRST_MIT = SPACE.
      REFRESH i_text.
    WHEN 'ENTER'.
      REFRESH i_text.
      SELECT * FROM /psyng/texts
             WHERE textname = usr_mit
               AND object   = 'M'
               AND vrsio    = g_sod_vrsio
               AND spras    = sy-langu
               ORDER BY line.
        i_text = /psyng/texts-text.
        APPEND i_text.
      ENDSELECT.
    WHEN 'DELETE'.
      DELETE FROM /psyng/texts WHERE textname = usr_mit
                               AND   object   = 'M'
                               AND   vrsio    = g_sod_vrsio.
    WHEN 'CREATE'.
      PERFORM get_editor_text.
      DELETE FROM /psyng/texts WHERE textname =  usr_mit
                               AND   object   = 'M'
                               AND   vrsio    = g_sod_vrsio.

      /psyng/texts-vrsio    = g_sod_vrsio.
      /psyng/texts-textname = usr_mit.
      /psyng/texts-object   = 'M'.
      /psyng/texts-spras    = sy-langu.
      LOOP AT i_text.
        IF sy-tabix > 0.
          /psyng/texts-line = sy-tabix.
          /psyng/texts-text = i_text-text.
          INSERT /psyng/texts.
        ENDIF.
      ENDLOOP.
    WHEN 'SAVE'.
      PERFORM get_editor_text.
      DELETE FROM /psyng/texts WHERE textname =  usr_mit
                               AND   object   = 'M'
                               AND   vrsio    = g_sod_vrsio
                               AND   spras    = sy-langu.

      /psyng/texts-vrsio    = g_sod_vrsio.
      /psyng/texts-textname = usr_mit.
      /psyng/texts-object   = 'M'.
      /psyng/texts-spras    = sy-langu.
      LOOP AT i_text.
        IF sy-tabix > 0.
          /psyng/texts-line = sy-tabix.
          /psyng/texts-text = i_text-text.
          INSERT /psyng/texts.
        ENDIF.
      ENDLOOP.
    WHEN 'FS'.
      g_fullscreen = '0206'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.
    WHEN OTHERS.
      CLEAR populated.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0206  INPUT



*&---------------------------------------------------------------------*
*&      Module  SODFUN_ACTIVE_TAB_GET  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE sodfun_active_tab_get INPUT.
  CASE ok_code.
    WHEN c_sodfun-tab1.
      g_sodfun-pressed_tab = c_sodfun-tab1.
    WHEN c_sodfun-tab2.
      g_sodfun-pressed_tab = c_sodfun-tab2.
    WHEN c_sodfun-tab4.
      g_sodfun-pressed_tab = c_sodfun-tab4.
    WHEN c_sodfun-tab5.
      g_sodfun-pressed_tab = c_sodfun-tab5.
    WHEN c_sodfun-tab6.
      g_sodfun-pressed_tab = c_sodfun-tab6.
  ENDCASE.
ENDMODULE.                 " SODFUN_ACTIVE_TAB_GET  INPUT

*&---------------------------------------------------------------------*
*&      Module  MITCON_ACTIVE_TAB_GET  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE mitcon_active_tab_get INPUT.
  CASE ok_code.
    WHEN c_mitcon-tab1.
      g_mitcon-pressed_tab = c_mitcon-tab1.
    WHEN c_mitcon-tab2.
      g_mitcon-pressed_tab = c_mitcon-tab2.
    WHEN c_mitcon-tab3.
      g_mitcon-pressed_tab = c_mitcon-tab3.
    WHEN c_mitcon-tab4.
      g_mitcon-pressed_tab = c_mitcon-tab4.
    WHEN c_mitcon-tab5.
      g_mitcon-pressed_tab = c_mitcon-tab5.
    WHEN c_mitcon-tab6.
      g_mitcon-pressed_tab = c_mitcon-tab6.
    WHEN c_mitcon-tab7.
      g_mitcon-pressed_tab = c_mitcon-tab7.
  ENDCASE.
ENDMODULE.                 " MITCON_ACTIVE_TAB_GET  INPUT

*&---------------------------------------------------------------------*
*&      Module  INIT_SCREENS  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_screens INPUT.
  CLEAR populated.
  IF ok_code(9) = 'SECTAB_FC'.
    CONCATENATE 'YX_' ok_code INTO ok_code.
  ELSEIF ok_code(6) = 'SODFUN'.
    g_sodfun-pressed_tab = ok_code.
    ok_code = 'YX_SECTAB_FC2'.
  ELSEIF ok_code(6) = 'MITCON'.
    g_sodfun-pressed_tab = 'SODFUN_FC4'.
    g_mitcon-pressed_tab = ok_code.
    ok_code = 'YX_SECTAB_FC2'.
  ELSEIF ok_code(5) = 'ROLES'.
    g_roles-pressed_tab = ok_code.
    ok_code = 'YX_SECTAB_FC3'.
  ELSEIF ok_code = 'SETVRSIO'.
    PERFORM set_version.
  ENDIF.
ENDMODULE.                 " INIT_SCREENS  INPUT

*&---------------------------------------------------------------------*
*&      Module  ROLES_ACTIVE_TAB_GET  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE roles_active_tab_get INPUT.
  CASE ok_code.
    WHEN c_roles-tab1.
      g_roles-pressed_tab = c_roles-tab1.
    WHEN c_roles-tab2.
      g_roles-pressed_tab = c_roles-tab2.
  ENDCASE.
ENDMODULE.                 " ROLES_ACTIVE_TAB_GET  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHECK_TRANS  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_trans INPUT.
  IF mark_col = 'X'.
    g_trans_itab-flag = 'X'.
    MODIFY g_trans_itab INDEX critrans-current_line TRANSPORTING flag.
*  ELSE.
*    CLEAR g_trans_itab-flag.
*    MODIFY g_trans_itab INDEX critrans-current_line TRANSPORTING flag.
  ENDIF.
ENDMODULE.                 " CHECK_TRANS  INPUT

MODULE check_apps INPUT.
  IF mark_col = 'X'.
    gt_fiori_app-flag = 'X'.
    MODIFY gt_fiori_app INDEX fioriapps-current_line TRANSPORTING flag.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  CHECK_CRITROLE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_critrole INPUT.
  IF mark_col = 'X'.
    g_criroles_itab-flag = 'X'.
    MODIFY g_criroles_itab INDEX critrole-current_line TRANSPORTING flag
                                                                       .
  ENDIF.
ENDMODULE.                 " CHECK_critrole  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHECK_CRITPROF  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_critprof INPUT.
  IF mark_col = 'X'.
    g_criprofs_itab-flag = 'X'.
   MODIFY g_criprofs_itab INDEX critprof-current_line TRANSPORTING flag.
    CLEAR g_criprofs_itab-flag.
  ENDIF.
ENDMODULE.                 " CHECK_critprof  INPUT


*&---------------------------------------------------------------------*
*&      Module  CHECK_FUNCT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_funct INPUT.
  IF mark_col = 'X'.
    g_funct_itab-flag = 'X'.
    MODIFY g_funct_itab INDEX funct-current_line
       TRANSPORTING flag.
    CLEAR g_funct_itab-flag.
  ENDIF.
**  Begin of additions 12/20/04
*  IF OK_CODE = 'SHTCOD'.
*    CLEAR G_FUNCT_ITAB-FLAG.
*    MODIFY G_FUNCT_ITAB INDEX FUNCT-CURRENT_LINE.
***  End of additions 12/20/04
*  ENDIF.
ENDMODULE.                 " CHECK_FUNCT  INPUT

*&---------------------------------------------------------------------*
*&      Module  CHECK_CONFLICT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_conflict INPUT.
  IF mark_col = 'X'.
    g_role_trans_itab-flag = 'X'.
    MODIFY g_role_trans_itab INDEX role_trans-current_line
          TRANSPORTING flag.
  ENDIF.
ENDMODULE.                 " CHECK_CONFLICT  INPUT

*&---------------------------------------------------------------------*
*&      Module  GET_FIELD_CONFLICT_DISP  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_field_conflict_disp INPUT.
  GET CURSOR FIELD cursor_field .
  GET CURSOR LINE  cursor_line  .
  cursor_line = cursor_line + conflict_disp-top_line - 1.
  IF ok_code = '' . "#EC SAST_CI_GEN_CHECK (HBHALLA)
    cursor_line = cursor_line + 1.
  ENDIF.
  j = 0.
ENDMODULE.                 " GET_FIELD_CONFLICT_DISP  INPUT

*&---------------------------------------------------------------------*
*&      Module  GET_FIELD_JOBCONFLICT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_field_jobconflict INPUT.
  GET CURSOR FIELD cursor_field .
  GET CURSOR LINE  cursor_line  .
  cursor_line = cursor_line + jobconflict-top_line - 1.
  IF ok_code = '' . "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (06/12/24)
    cursor_line = cursor_line + 1.
  ENDIF.
  j = 0.
ENDMODULE.                 " GET_FIELD_JOBCONFLICT INPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0107  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0107 INPUT.
  PERFORM set_state USING sy-ucomm.

  DATA : lt_seltab TYPE TABLE OF rsparams WITH HEADER LINE,
         l_repid   LIKE sy-repid,
         l_auth_param TYPE flag.
  CLEAR l_auth_param.

  populated = 'X'.

  CASE ok_code.
    WHEN 'SOD050'.
      SUBMIT /psyng/sw_050 VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'SODORG'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
      SUBMIT /psyng/sodreport_org VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'DSWRL'.
      SUBMIT /psyng/sw_021 VIA SELECTION-SCREEN
      AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'SYNROLE'.
      SUBMIT /psyng/synch_role_position VIA SELECTION-SCREEN
      AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'SYNCH'.
      FREE : lt_seltab.
      lt_seltab-kind    = 'P'.
      lt_seltab-sign    = 'I'.
      lt_seltab-option  = 'EQ'.
      lt_seltab-low     = 'X'.

      lt_seltab-selname = 'USER'.
      APPEND lt_seltab.
      lt_seltab-selname = 'ROLE'.
      APPEND lt_seltab.
      lt_seltab-selname = 'POSIT'.
      APPEND lt_seltab.


      SUBMIT /psyng/weavsync VIA SELECTION-SCREEN
      WITH SELECTION-TABLE lt_seltab
      AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'UPDOWNLD'.
      SUBMIT /psyng/sw_data_upload_download VIA SELECTION-SCREEN
             WITH sodvrsio = g_sod_vrsio
             AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'PDIAG'.
      SUBMIT /psyng/sw_093 VIA SELECTION-SCREEN
             WITH p_vrsin = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'LMTRX'.
      SUBMIT /psyng/sw_sodmatrix_overview WITH p_vrsio = g_sod_vrsio
      VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'CADET'.
      SUBMIT /psyng/sw_106 WITH p_vrsio = g_sod_vrsio
             AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'RVSM'.
      SUBMIT /psyng/sw_010 VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'SWCAR'.
      SUBMIT /psyng/car VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'ADMIN'.
      SUBMIT /psyng/sw_141 VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'FABAP'.
*--Run the best ABAP source scan report available.
      SELECT SINGLE name FROM trdir INTO l_repid
      WHERE name = 'RPR_ABAP_SOURCE_SCAN'."#EC SAST_CI_GEN_CHECK
      IF sy-subrc = 0.
        SUBMIT rpr_abap_source_scan VIA SELECTION-SCREEN AND RETURN.
      ELSE.
        SELECT SINGLE name FROM trdir INTO l_repid
        WHERE name = 'EWUCU02B'."#EC SAST_CI_GEN_CHECK
        IF sy-subrc = 0.
          SUBMIT ewucu02b VIA SELECTION-SCREEN AND RETURN.
        ELSE.
          SELECT SINGLE name FROM trdir INTO l_repid
          WHERE name = 'RSRSCAN1'."#EC SAST_CI_GEN_CHECK
          IF sy-subrc = 0.
            SUBMIT rsrscan1 VIA SELECTION-SCREEN AND RETURN.
          ELSE.
            MESSAGE i002(/psyng/sw) WITH
          'This functionality is not available in this SAP version'(s01)
            '&' '&' '&'.

          ENDIF.
        ENDIF.
      ENDIF.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'UNUSDA'.
      SUBMIT /psyng/sw_unused_auths VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'DELSCN'.
      SUBMIT /psyng/sw_delete_syscandt VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'MCREPO'.
      SUBMIT /psyng/sw_003 VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'MCREPOADV'.
      SUBMIT /psyng/sw_105 VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'INACT'.
      SUBMIT /psyng/user_logon_monitor VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'BKJOBU'.
      SUBMIT /psyng/sw_015 VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'MULTU'.
      SUBMIT /psyng/sw_016 VIA SELECTION-SCREEN
      AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'EMLTEXT'.
      SUBMIT /psyng/sw_107 AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'TRANSPORT'.
      SUBMIT /psyng/sw_048 VIA SELECTION-SCREEN
             WITH p_vrsio  = g_sod_vrsio
             AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'SWCNFG'.

* Opl 549 16.02.2023 start
      AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
             ID 'Y&SW_ADMF' FIELD 'CFGPARMD'.
      IF sy-subrc = 0.
        l_auth_param = 'X'.
      ENDIF.

*---if user has change access allow him to display
      IF l_auth_param IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
                   ID 'Y&SW_ADMF' FIELD 'CFGPARAM'.
        IF sy-subrc = 0.
          l_auth_param = 'X'.
        ENDIF.
        IF l_auth_param IS INITIAL.
          AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
                  ID 'Y&SW_ADMF' FIELD 'CFGPARMC'.
          IF sy-subrc = 0.
            l_auth_param = 'X'.
          ENDIF.
        ENDIF.
      ENDIF.
*---Om end
      IF l_auth_param = 'X'.
        SUBMIT /psyng/sw_142 AND RETURN.
        CLEAR: gf_val_mit_aud, g_apr_same_usr_msg, g_aud_same_usr_msg.
        CLEAR: ok_code, sy-ucomm.
      ELSE.
        CLEAR: ok_code, sy-ucomm.
        MESSAGE e108(/psyng/sw) WITH
*       BOC by GSINGH on 08.02.2023 for B17173 - Display config Parameters message should come instead of Change
*        'Change Configuration Parameters'(e36).
          'Display Configuration Parameters'(e39).
*       EOC by GSINGH.
      ENDIF.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'CFGAPA'.
      CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
        EXPORTING
          action                       = 'S'
          view_name                    = '/PSYNG/BUSAREA'
        EXCEPTIONS
          client_reference             = 1
          foreign_lock                 = 2
          invalid_action               = 3
          no_clientindependent_auth    = 4
          no_database_function         = 5
          no_editor_function           = 6
          no_show_auth                 = 7
          no_tvdir_entry               = 8
          no_upd_auth                  = 9
          only_show_allowed            = 10
          system_failure               = 11
          unknown_field_in_dba_sellist = 12
          view_not_found               = 13
          OTHERS                       = 14.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'CFGSTA'.
      CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
        EXPORTING
          action                       = 'S'
          view_name                    = '/PSYNG/SW_STA01'
        EXCEPTIONS
          client_reference             = 1
          foreign_lock                 = 2
          invalid_action               = 3
          no_clientindependent_auth    = 4
          no_database_function         = 5
          no_editor_function           = 6
          no_show_auth                 = 7
          no_tvdir_entry               = 8
          no_upd_auth                  = 9
          only_show_allowed            = 10
          system_failure               = 11
          unknown_field_in_dba_sellist = 12
          view_not_found               = 13
          OTHERS                       = 14.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'CFGPRJ'.
      CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
        EXPORTING
          action                       = 'S'
          view_name                    = '/PSYNG/SW_PRJ01'
        EXCEPTIONS
          client_reference             = 1
          foreign_lock                 = 2
          invalid_action               = 3
          no_clientindependent_auth    = 4
          no_database_function         = 5
          no_editor_function           = 6
          no_show_auth                 = 7
          no_tvdir_entry               = 8
          no_upd_auth                  = 9
          only_show_allowed            = 10
          system_failure               = 11
          unknown_field_in_dba_sellist = 12
          view_not_found               = 13
          OTHERS                       = 14.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'SWSPC'.
      CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
        EXPORTING
          action                       = 'S'
          view_name                    = '/PSYNG/BUS_PROCE'
        EXCEPTIONS
          client_reference             = 1
          foreign_lock                 = 2
          invalid_action               = 3
          no_clientindependent_auth    = 4
          no_database_function         = 5
          no_editor_function           = 6
          no_show_auth                 = 7
          no_tvdir_entry               = 8
          no_upd_auth                  = 9
          only_show_allowed            = 10
          system_failure               = 11
          unknown_field_in_dba_sellist = 12
          view_not_found               = 13
          OTHERS                       = 14.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'CUSCON'.                               "Custom Conflicts
      SUBMIT /psyng/sw_063 WITH p_vrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'SODVERS'.
      SUBMIT /psyng/sw_084 AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'SW_080'.                "Copy versions
* Check for create authority
      AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
          ID 'ACTVT' FIELD '01'
          ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        MESSAGE e108(/psyng/sw) WITH 'Create SOD Versions'(e51).
      ELSE.
        SUBMIT /psyng/sw_080 VIA SELECTION-SCREEN AND RETURN.
        CLEAR: ok_code, sy-ucomm.
      ENDIF.


    WHEN 'SW_081'.                "Compare versions
      SUBMIT /psyng/sw_081 VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'SW_091'.                "Mitigations monitor
      SUBMIT /psyng/sw_091 VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'SW_092'.                "Schedule User History job mit monitor
      SUBMIT /psyng/sw_mitigation_monitor
             VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'SW_098'.                "Maintain risk scenarios
      SUBMIT /psyng/sw_098 AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'SW_100'.                "Maintain mitigation types
      SUBMIT /psyng/sw_100 AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'VAREL'.                "Maintain Variable Elements
      SUBMIT /psyng/sw_126 AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'AUTOORG'.               "Maintain Auto Org
      SUBMIT /psyng/sw_auto_org
      WITH
        sodvrsio  EQ g_sod_vrsio
      WITH
        p_nodefv EQ 'X'
      VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'SWFREQ'.                "Maintain mitigation Frequency
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SWFREQ'.
      IF sy-subrc <> 0.
        CLEAR: ok_code, sy-ucomm.
        MESSAGE e077(s#) WITH '/PSYNG/SWFREQ'.
      ELSE.
        CALL TRANSACTION '/PSYNG/SWFREQ'.
      ENDIF.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'RFC'.
      SUBMIT /psyng/sw_rfc_maintain_alv AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'FS'.
      g_fullscreen = '0107'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.
    WHEN 'MITRVW'.
      SUBMIT /psyng/sw_133 VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'CFGSET'.
      SUBMIT /psyng/sw_135 "VIA SELECTION-SCREEN AND RETURN.
      WITH p_vrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'CFG_CMP'.
      SUBMIT /psyng/sw_146 VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'CFG_CUS'.
*Begin of Addition:HBHALLA(PN-17933)(27/02/26)
  AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
  ID 'Y&SW_ADMF' FIELD 'CUSTORG'.
    IF sy-subrc = 0.
      SUBMIT /psyng/se_maintain_corg VIA SELECTION-SCREEN AND RETURN.
    ELSE.
      AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
       ID 'Y&SW_ADMF' FIELD 'CUSTORGD'.
      IF sy-subrc = 0.
        SUBMIT /psyng/se_maintain_corg VIA SELECTION-SCREEN AND RETURN.
      ELSE.
      AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
       ID 'Y&SW_ADMF' FIELD 'CUSTORGC'.
      IF sy-subrc = 0.
        SUBMIT /psyng/se_maintain_corg VIA SELECTION-SCREEN AND RETURN.
      ELSE.
        CLEAR: ok_code, sy-ucomm.
        MESSAGE e108(/psyng/sw) WITH
        'Display Custom Org Logic'(e40).
      ENDIF.
      ENDIF.
    ENDIF.
*End of Addition:HBHALLA(PN-17933)(27/02/26)
      CLEAR: ok_code, sy-ucomm.
    WHEN 'DELSTORED'.
      SUBMIT /psyng/sw_139 VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'DELSTOREDR'.
      SUBMIT /psyng/sw_151 VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'APILOGD'.
      SUBMIT /psyng/basis_log_api VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'APILOGC'.
      SUBMIT /psyng/basis_del_log_api VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'CFGDST'.
      AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
             ID 'Y&SW_ADMF' FIELD 'DISTCON'.
      IF sy-subrc = 0.
        SUBMIT /psyng/sw_145 VIA SELECTION-SCREEN AND RETURN.
      ELSE.
        CLEAR: ok_code, sy-ucomm.
        MESSAGE e108(/psyng/sw) WITH
        'Distribute Configurations'(e37).
      ENDIF.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'SYSTYP'.
      CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
        EXPORTING
          action                       = 'S'
          view_name                    = '/PSYNG/SW_SYSTYP'
        EXCEPTIONS
          client_reference             = 1
          foreign_lock                 = 2
          invalid_action               = 3
          no_clientindependent_auth    = 4
          no_database_function         = 5
          no_editor_function           = 6
          no_show_auth                 = 7
          no_tvdir_entry               = 8
          no_upd_auth                  = 9
          only_show_allowed            = 10
          system_failure               = 11
          unknown_field_in_dba_sellist = 12
          view_not_found               = 13
          OTHERS                       = 14.
      IF sy-subrc <> 0.
        CLEAR: ok_code, sy-ucomm.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'SYSCAT'.
      CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
        EXPORTING
          action                       = 'S'
          view_name                    = '/PSYNG/SW_SYSCAT'
        EXCEPTIONS
          client_reference             = 1
          foreign_lock                 = 2
          invalid_action               = 3
          no_clientindependent_auth    = 4
          no_database_function         = 5
          no_editor_function           = 6
          no_show_auth                 = 7
          no_tvdir_entry               = 8
          no_upd_auth                  = 9
          only_show_allowed            = 10
          system_failure               = 11
          unknown_field_in_dba_sellist = 12
          view_not_found               = 13
          OTHERS                       = 14.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      CLEAR: ok_code, sy-ucomm.
    WHEN 'ENHUP'.
      SUBMIT /psyng/sw_147 VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
"BOC UMITTAL 11 Dec 2023
    WHEN 'SYNCUP'.
*      SUBMIT /psyng/sw_162 AND RETURN.
*BOC UMITTAL PN 11269 BMW ATC CHECKS
*AUTH grp added before call txn
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD'
        FIELD '/PSYNG/SW_162'.
      IF sy-subrc <> 0.
        MESSAGE e088(/psyng/sw) WITH '/PSYNG/SW_162'.
      ELSE.
        CALL TRANSACTION '/PSYNG/SW_162'.
      ENDIF.
*EOC UMITTAL PN 11269 BMW ATC CHECKS
      CLEAR: ok_code, sy-ucomm.
"EOC UMITTAL 11 Dec 2023
    WHEN 'RBA'.
     AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/BC_BA_MNT'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/BC_BA_MNT'.
      ELSE.
        CALL TRANSACTION '/PSYNG/BC_BA_MNT'.
      ENDIF.
      CLEAR: ok_code, sy-ucomm.
    WHEN OTHERS.
      CLEAR populated.

  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0107  INPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0106  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0106 INPUT.
  DATA: lf_ta_installed TYPE /psyng/bapiflagx.

*BOC HBHALLA 29/01/2025 ATC checks PN 11269
  CONSTANTS: lc_mu(4) VALUE 'MU_*'.
*  IF sy-ucomm CP 'MU_*' .
  IF sy-ucomm CP lc_mu .
*EOC HBHALLA 29/01/2025 ATC checks PN 11269


*--One of the 'Most Used'-buttons is clicked
*  We modify the sy-ucomm field so normal processing can continue
    READ TABLE gt_buttons WITH KEY button_id = sy-ucomm.
    sy-ucomm = gt_buttons-ok_code.
    ok_code  = gt_buttons-ok_code.
  ENDIF.
  PERFORM set_state USING sy-ucomm.
  populated = 'X'.

*BOC HBHALLA 14/01/2025 ATC checks PN 11269
  CONSTANTS: lc_138(6) VALUE 'SW_138',
             lc_137(6) VALUE 'SW_137',
             lc_140(6) VALUE 'SW_140',
             lc_149(6) VALUE 'SW_149',
             lc_150(6) VALUE 'SW_150',
             lc_148(6) VALUE 'SW_148',
             lc_swamenu(7) VALUE 'SWAMENU',
             lc_sumrpt(6) VALUE 'SUMRPT',
             lc_usrrpt(6) VALUE 'USRRPT',
             lc_rlerpt(6) VALUE 'RLERPT',
             lc_psnrpt(6) VALUE 'PSNRPT',
             lc_usrpt(5) VALUE 'USRPT',
             lc_criprof(7) VALUE 'CRIPROF',
             lc_criroles(8) VALUE 'CRIROLES',
             lc_newuid(6) VALUE 'NEWUID',
             lc_sumryrpt(8) VALUE 'SUMRYRPT',
             lc_transum(7) VALUE 'TRANSUM',
             lc_critical(8) VALUE 'CRITICAL',
             lc_criticar(8) VALUE 'CRITICAR',
             lc_sauthmon(8) VALUE 'SAUTHMON',
             lc_sauthmonrole(12) VALUE 'SAUTHMONROLE',
             lc_sodcritauth(11) VALUE 'SODCRITAUTH',
             lc_uauth(5) VALUE 'UAUTH',
             lc_mgrph(5) VALUE 'MGRPH',
             lc_byhist(6) VALUE 'BYHIST',
             lc_vwhist(6) VALUE 'VWHIST',
             lc_inact(5) VALUE 'INACT',
             lc_bkjobu(6) VALUE 'BKJOBU',
             lc_multu(5) VALUE 'MULTU',
             lc_dualu(5) VALUE 'DUALU',
             lc_sodsmrp(7) VALUE 'SODSMRP',
             lc_sodsmrprole(11) VALUE 'SODSMRPROLE',
             lc_grugrp(6) VALUE 'GRUGRP',
             lc_grprar(6) VALUE 'GRPRAR',
             lc_grapar(6) VALUE 'GRAPAR',
             lc_exehist(7) VALUE 'EXEHIST',
             lc_byrole(6) VALUE 'BYROLE',
             lc_mithdrrpt(9) VALUE 'MITHDRRPT',
             lc_advsim(6) VALUE 'ADVSIM',
             lc_fs(2) VALUE 'FS',
             lc_cnfltrpt(8) VALUE 'CNFLTRPT',
             lc_mcrepoadv(9) VALUE 'MCREPOADV',"<HBHALLA>++ PN-15936
             lc_audit(5) VALUE 'AUDIT',
             lc_roleeff(7) VALUE 'ROLEEFF',
             lc_funcrep(7) VALUE 'FUNCREP',
             lc_byprof(6) VALUE 'BYPROF',
             lc_funcrrep(8) VALUE 'FUNCRREP',
             lc_mitrev(6) VALUE 'MITREV'.

  CASE ok_code.
*    WHEN 'SW_138'.
    WHEN lc_138.
      SUBMIT /psyng/sw_138 "VIA SELECTION-SCREEN
      WITH p_vrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'SW_137'.
    WHEN lc_137.
      SUBMIT /psyng/sw_137 VIA SELECTION-SCREEN
      AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'SW_140'.
    WHEN lc_140.
      SUBMIT /psyng/sw_140 VIA SELECTION-SCREEN
       WITH p_vrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'SW_149'.
    WHEN lc_149.
      SUBMIT /psyng/sw_149 "VIA SELECTION-SCREEN
      WITH p_vrsio = g_sod_vrsio
      AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'SW_150'.
    WHEN lc_150.
      SUBMIT /psyng/sw_150 VIA SELECTION-SCREEN
      AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'SW_148'.
    WHEN lc_148.
      SUBMIT /psyng/sw_148 VIA SELECTION-SCREEN
       WITH p_vrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'SWAMENU'.
    WHEN lc_swamenu.
      PERFORM call_area_menu.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'SUMRPT'.
    WHEN lc_sumrpt.
      SUBMIT /psyng/sodreport_sys_wide_org VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'USRRPT'.
    WHEN lc_usrrpt.
      SUBMIT /psyng/sodreport_org VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio
      AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'RLERPT'.
    WHEN lc_rlerpt.
      SUBMIT /psyng/sw_022 VIA SELECTION-SCREEN
      AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'PSNRPT'.
    WHEN lc_psnrpt.
      SUBMIT /psyng/sw_023 VIA SELECTION-SCREEN
      AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'USRPT'.
    WHEN lc_usrpt.
      SUBMIT /psyng/sw_024 VIA SELECTION-SCREEN
      AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'CRIPROF'.
    WHEN lc_criprof.
      SUBMIT /psyng/sw_030 VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'CRIROLES'.
    WHEN lc_criroles.
      SUBMIT /psyng/sw_031 VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'NEWUID'.
    WHEN lc_newuid.
      SUBMIT /psyng/sw_032 VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'SUMRYRPT'.
    WHEN lc_sumryrpt.
      SUBMIT /psyng/sumryrpt VIA SELECTION-SCREEN
      WITH p_vrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.

*    WHEN 'TRANSUM'.
    WHEN lc_transum.
      SUBMIT /psyng/user_exe_tcode VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'CRITICAL'.
    WHEN lc_critical.
      SUBMIT /psyng/cri_tcode_list VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'CRITICAR'.
    WHEN lc_criticar.
      SUBMIT /psyng/cri_tcode_list_byrole VIA SELECTION-SCREEN
      WITH p_sodvrs = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'SAUTHMON'.
    WHEN lc_sauthmon.
      SUBMIT /psyng/sw_crit_auths VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'SAUTHMONROLE'.
    WHEN lc_sauthmonrole.
      SUBMIT /psyng/sw_crit_auths_byrole VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'SODCRITAUTH'.
    WHEN lc_sodcritauth.
      SUBMIT /psyng/sw_099 VIA SELECTION-SCREEN
      WITH p_vrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'UAUTH'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
    WHEN lc_uauth. "#EC SAST_CI_GEN_CHECK (HBHALLA)
      SUBMIT /psyng/sw_auth_count VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'MGRPH'.
    WHEN lc_mgrph.
      SUBMIT /psyng/sod_mang_repo
      WITH sodvrsio = g_sod_vrsio  AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'BYHIST'.
    WHEN lc_byhist.
      SUBMIT /psyng/sodreport_by_history VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio  AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'VWHIST'.
    WHEN lc_vwhist.
      CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
        EXPORTING
          i_module    = 'TA'
        IMPORTING
          e_installed = lf_ta_installed.
      IF lf_ta_installed = 'X' AND gf_use_ta_history = 'X'.
        SUBMIT /psyng/bc_usrhis_36 VIA SELECTION-SCREEN AND RETURN.
      ELSE.
        SUBMIT /psyng/sw_017 VIA SELECTION-SCREEN
          WITH sodvrsio = g_sod_vrsio AND RETURN.
      ENDIF.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'INACT'.
    WHEN lc_inact.
      SUBMIT /psyng/user_logon_monitor VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'BKJOBU'.
    WHEN lc_bkjobu.
      SUBMIT /psyng/sw_015 VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'MULTU'.
    WHEN lc_multu.
      SUBMIT /psyng/sw_016 VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'DUALU'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
    WHEN lc_dualu. "#EC SAST_CI_GEN_CHECK (HBHALLA)
      SUBMIT /psyng/sw_018 VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'SODSMRP'.
    WHEN lc_sodsmrp.
      SUBMIT /psyng/sw_sod_sum_rp VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'SODSMRPROLE'.
    WHEN lc_sodsmrprole.
      SUBMIT /psyng/sw_sod_sum_role VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'GRUGRP'.
    WHEN lc_grugrp.
      SUBMIT /psyng/sw_033 WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'GRPRAR'.
    WHEN lc_grprar.
      SUBMIT /psyng/sw_034 WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'GRAPAR'.
    WHEN lc_grapar.
      SUBMIT /psyng/sw_035 WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'EXEHIST'.
    WHEN lc_exehist.
      SUBMIT /psyng/sw_040 VIA SELECTION-SCREEN
      WITH p_vrsio = g_sod_vrsio
      AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'BYROLE'.
    WHEN lc_byrole.
      SUBMIT /psyng/sod_syswide_byrole WITH sodvrsio = g_sod_vrsio
             VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'MITHDRRPT'.
    WHEN lc_mithdrrpt.
      SUBMIT /psyng/sw_102 VIA SELECTION-SCREEN
      AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'ADVSIM'.
    WHEN lc_advsim.
      CALL FUNCTION '/PSYNG/SW_080'
        EXPORTING
          i_sodvrsio = g_sod_vrsio.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'FS'.
    WHEN lc_fs.
      g_fullscreen = '0106'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.
*    WHEN 'CNFLTRPT'.
    WHEN lc_cnfltrpt.
      SUBMIT /psyng/cnfltrpt VIA SELECTION-SCREEN
      WITH p_vrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'USRPT'.
    WHEN lc_usrpt.
      SUBMIT /psyng/sw_024 VIA SELECTION-SCREEN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'PSNRPT'.
    WHEN lc_psnrpt.
      SUBMIT /psyng/sw_023 VIA SELECTION-SCREEN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'RLERPT'.
    WHEN lc_rlerpt.
      SUBMIT /psyng/sw_022 VIA SELECTION-SCREEN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'MCREPOADV'.
    WHEN lc_mcrepoadv.
      SUBMIT /psyng/sw_105 VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'AUDIT'.
    WHEN lc_audit.
      SUBMIT /psyng/sw_043 VIA SELECTION-SCREEN
      WITH p_vrsio = g_sod_vrsio AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'ROLEEFF'.
    WHEN lc_roleeff.
*--SE3.4PS3 - One CO report replaces both the old SE and TA reports
      SUBMIT /psyng/bc_role_efficiency
      WITH p_sodvrs = g_sod_vrsio
      WITH p_fromse = 'X'
      VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'FUNCREP'.
    WHEN lc_funcrep.
      SUBMIT /psyng/sw_095 VIA SELECTION-SCREEN
      WITH sodvrsio = g_sod_vrsio
      AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'BYPROF'.
    WHEN lc_byprof.
      SUBMIT /psyng/sodreport_by_profile WITH sodvrsio = g_sod_vrsio
         VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'FUNCRREP'.
    WHEN lc_funcrrep.
      SUBMIT /psyng/sw_129 VIA SELECTION-SCREEN
           WITH sodvrsio = g_sod_vrsio
            AND RETURN.
      CLEAR: ok_code, sy-ucomm.
*    WHEN 'MITREV'.
    WHEN lc_mitrev.
      SUBMIT /psyng/sw_132 VIA SELECTION-SCREEN
           WITH s_sod = g_sod_vrsio
            AND RETURN.
      CLEAR: ok_code, sy-ucomm.
    WHEN OTHERS.
      CLEAR populated.

  ENDCASE.
*EOC HBHALLA 14/01/2025 ATC checks PN 11269
ENDMODULE.                 " USER_COMMAND_0106  INPUT

*&---------------------------------------------------------------------*
*&      Module  DATA_CHANGED  INPUT
*&---------------------------------------------------------------------*
*       Data on screen was changed
*----------------------------------------------------------------------*
MODULE data_changed INPUT.
  IF gf_dispchg = gc_change.
    gf_data_change = gc_select.
  ENDIF.
ENDMODULE.                 " DATA_CHANGED  INPUT

*&---------------------------------------------------------------------*
*&      Module  exit  INPUT
*&---------------------------------------------------------------------*
*       Exit from transaction
*----------------------------------------------------------------------*
MODULE exit INPUT.
  gf_answer = 1.

* If data was changed, ask if user wants to exit without saving
  IF gf_data_change = gc_select.
*    CALL FUNCTION 'POPUP_TO_CONFIRM'
*         EXPORTING
*              text_question         = text-003
*              text_button_1         = text-001
*              icon_button_1         = 'ICON_CHECKED'
*              text_button_2         = text-002
*              icon_button_2         = 'ICON_INCOMPLETE'
*              default_button        = '1'
*              display_cancel_button = ' '
*         IMPORTING
*              answer                = gf_answer
*         EXCEPTIONS
*              text_not_found        = 1
*              OTHERS                = 2.
*    IF sy-subrc <> 0.
*      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*    ENDIF.
  ENDIF.

  IF gf_answer = 1.
    LEAVE TO SCREEN 0.
    EXIT.
  ELSE.
    CLEAR: g_yx_sectab-pressed_tab, g_sodfun-pressed_tab.
  ENDIF.
ENDMODULE.                 " exit  INPUT

*&---------------------------------------------------------------------*
*&      Module  mctran_mark  INPUT
*&---------------------------------------------------------------------*
MODULE mctran_mark INPUT.
  IF gt_mctran-sel = 'X'.
    MODIFY gt_mctran INDEX tc_mctran-current_line.
  ENDIF.
ENDMODULE.                 " mctran_mark  INPUT

*&---------------------------------------------------------------------*
*&      Module  mctran_modify  INPUT
*&---------------------------------------------------------------------*
MODULE mctran_modify INPUT.
  IF ok_code = 'MCTRAN_DELE'.
    gt_mctran-sel = 'X'.
    APPEND gt_mctran.
    EXIT.
  ENDIF.


  IF gt_mctran-tcode IS INITIAL AND ok_code NE 'MCTRAN_DELE'.
    DELETE gt_mctran INDEX tc_mctran-current_line.      "#EC CI_NOORDER
    EXIT.
  ENDIF.

  SELECT SINGLE tcode INTO tstct-tcode FROM tstc
                WHERE tcode = gt_mctran-tcode.
  IF sy-subrc <> 0.
    MESSAGE e343(s#) WITH gt_mctran-tcode.
  ENDIF.

  READ TABLE gt_mctran INDEX tc_mctran-current_line
             TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    MODIFY gt_mctran INDEX tc_mctran-current_line.
  ELSE.
    READ TABLE gt_mctran WITH KEY tcode = gt_mctran-tcode.
    IF sy-subrc = 0.
      MESSAGE e101(/psyng/sw).
    ENDIF.

    APPEND gt_mctran.
  ENDIF.

  gf_data_change = gc_select.
ENDMODULE.                 " mctran_modify  INPUT

*&---------------------------------------------------------------------*
*&      Module  mcrepid_mark  INPUT
*&---------------------------------------------------------------------*
MODULE mcrepid_mark INPUT.
  IF gt_mcrepid-sel = 'X'.
    MODIFY gt_mcrepid INDEX tc_mcrepid-current_line.
  ENDIF.
ENDMODULE.                 " mcrepid_mark  INPUT

*&---------------------------------------------------------------------*
*&      Module  mcauditor_mark  INPUT
*&---------------------------------------------------------------------*
MODULE mcauditor_mark INPUT.
  IF gt_mcauditor-sel = 'X'.
    MODIFY gt_mcauditor INDEX tc_mcauditor-current_line.
  ENDIF.
ENDMODULE.                 " mcauditor_mark  INPUT

*&---------------------------------------------------------------------*
*&      Module  mcrepid_modify  INPUT
*&---------------------------------------------------------------------*
MODULE mcrepid_modify INPUT.

  IF ok_code = 'MCREPID_DELE'.
    gt_mcrepid-sel = 'X'.
    APPEND gt_mcrepid.
    EXIT.
  ENDIF.

  IF gt_mcrepid-repid IS INITIAL AND ok_code NE 'MCREPID_DELE'.
    DELETE gt_mcrepid INDEX tc_mcrepid-current_line.    "#EC CI_NOORDER
    EXIT.
  ENDIF.


  SELECT SINGLE name INTO gt_mcrepid-repid FROM trdir
                WHERE name = gt_mcrepid-repid."#EC SAST_CI_GEN_CHECK
  IF sy-subrc <> 0.
    MESSAGE e017(ds) WITH gt_mcrepid-repid.
  ENDIF.


  READ TABLE gt_mcrepid INDEX tc_mcrepid-current_line
             TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    MODIFY gt_mcrepid INDEX tc_mcrepid-current_line.
  ELSE.
    READ TABLE gt_mcrepid WITH KEY repid = gt_mcrepid-repid.
    IF sy-subrc = 0.
      MESSAGE e101(/psyng/sw).
    ENDIF.

    APPEND gt_mcrepid.
  ENDIF.

  gf_data_change = gc_select.
ENDMODULE.                 " mcrepid_modify  INPUT

*&---------------------------------------------------------------------*
*&      Module  mcauditor_modify  INPUT
*&---------------------------------------------------------------------*
MODULE mcauditor_modify INPUT.
  IF gt_mcauditor-auditor IS INITIAL AND ok_code NE 'MCAUDITOR_DELE'.
    DELETE gt_mcauditor INDEX tc_mcauditor-current_line. "#EC CI_NOORDER
    EXIT.
  ENDIF.


* If sending emails, validate auditor user ID
  IF gt_mcauditor-ma_email = 'X'.
    SELECT SINGLE mandt INTO sy-mandt FROM usr02
                  WHERE bname = gt_mcauditor-auditor.
    IF sy-subrc <> 0.
      MESSAGE e124(01) WITH gt_mcauditor-auditor.
    ENDIF.
  ENDIF.


  PERFORM get_comp_name CHANGING gt_mcauditor-company
                                 gt_mcauditor-comp_name.

*  Check Existing entry

  CLEAR : wa_mcauditor.
  LOOP AT gt_mcauditor INTO wa_mcauditor
                        WHERE auditor = gt_mcauditor-auditor
                          AND company = gt_mcauditor-company.
    IF sy-tabix <> tc_mcauditor-current_line.
      MESSAGE e101(/psyng/sw).
    ENDIF.
  ENDLOOP.

  READ TABLE gt_mcauditor INDEX tc_mcauditor-current_line
             TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    gt_mcauditor-contid = /psyng/mchdr-contid.
    MODIFY gt_mcauditor INDEX tc_mcauditor-current_line.
  ELSE.
    READ TABLE gt_mcauditor WITH KEY auditor = gt_mcauditor-auditor
                                     company = gt_mcauditor-company.
    IF sy-subrc = 0.
      MESSAGE e101(/psyng/sw).
    ENDIF.

    IF g_dflt_mit_ma_email IS INITIAL.
      CLEAR g_config_value.
      se_config_param 'DFLT_MIT_MA_EMAIL' g_config_value.
      g_dflt_mit_ma_email = g_config_value.
    ENDIF.

    IF g_dflt_mit_ma_email = 'Y'.
      gt_mcauditor-ma_email = 'X'.
    ENDIF.



    gt_mcauditor-contid = /psyng/mchdr-contid.
    APPEND gt_mcauditor.
    first_time = 'X'.
  ENDIF.

  gf_mcaud_chg = 'X'.
ENDMODULE.                 " mcauditor_modify  INPUT

*&---------------------------------------------------------------------*
*&      Module  user_command_0211  INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0211 INPUT.
  PERFORM user_command_0211.
ENDMODULE.                 " user_command_0211  INPUT

*&---------------------------------------------------------------------*
*&      Module  mcuser_mark  INPUT
*&---------------------------------------------------------------------*
MODULE mcuser_mark INPUT.
  IF gt_mcuser-sel = 'X'.
    IF ok_code = 'REPLACE'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
      READ TABLE gt_mcuser INDEX tc_mcuser-current_line.
      IF gt_mcuser-sel <> 'X'.
        MESSAGE e398(00) WITH text-e10.
      ENDIF.
    ENDIF.

    MODIFY gt_mcuser INDEX tc_mcuser-current_line.
  ENDIF.
ENDMODULE.                 " mcuser_mark  INPUT

*&---------------------------------------------------------------------*
*&      Module  mcuser_modify  INPUT
*&---------------------------------------------------------------------*
MODULE mcuser_modify INPUT.
  MODIFY gt_mcuser INDEX tc_mcuser-current_line.
ENDMODULE.                 " mcuser_modify  INPUT

*&---------------------------------------------------------------------*
*&      Module  mcusrgrp_mark  INPUT
*&---------------------------------------------------------------------*
MODULE mcusrgrp_mark INPUT.
  IF gt_mcusrgrp-sel = 'X'.
    IF ok_code = 'REPLACE'. "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (06/12/24)
      READ TABLE gt_mcusrgrp INDEX tc_mcusrgrp-current_line.
      IF gt_mcusrgrp-sel <> 'X'.
        MESSAGE e398(00) WITH text-e10.
      ENDIF.
    ENDIF.

    MODIFY gt_mcusrgrp INDEX tc_mcusrgrp-current_line.
  ENDIF.
ENDMODULE.                 " mcusrgrp_mark  INPUT

*&---------------------------------------------------------------------*
*&      Module  mcusrgrp_modify  INPUT
*&---------------------------------------------------------------------*
MODULE mcusrgrp_modify INPUT.
  MODIFY gt_mcusrgrp INDEX tc_mcusrgrp-current_line.
ENDMODULE.                 " mcusrgrp_modify  INPUT

*&---------------------------------------------------------------------*
*&      Module  mcrole_modify  INPUT
*&---------------------------------------------------------------------*
MODULE mcrole_modify INPUT.
  MODIFY gt_mcrole INDEX tc_mcrole-current_line.
ENDMODULE.                 " mcrole_modify  INPUT

*&---------------------------------------------------------------------*
*&      Module  user_command_0212  INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0212 INPUT.
  PERFORM user_command_0212.
ENDMODULE.                 " user_command_0212  INPUT

*&---------------------------------------------------------------------*
*&      Module  user_command_0222  INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0222 INPUT.
  PERFORM user_command_0222.
ENDMODULE.                 " user_command_0222  INPUT

*&---------------------------------------------------------------------*
*&      Module  user_command_0223  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0223 INPUT.
  PERFORM user_command_0223.
ENDMODULE.                 " user_command_0223  INPUT

*&---------------------------------------------------------------------*
*&      Module  user_command_0224  INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0224 INPUT.
  PERFORM user_command_0224.
ENDMODULE.                 " user_command_0224  INPUT

*&---------------------------------------------------------------------*
*&      Module  user_command_0225  INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0225 INPUT.
  PERFORM user_command_0225.
ENDMODULE.                 " user_command_0225  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_mcontid  INPUT
*&---------------------------------------------------------------------*
*       Dropdown F4 help for mitigating control ID
*----------------------------------------------------------------------*
MODULE f4_mcontid INPUT.
  REFRESH: gt_fields, gt_values.
  gt_fields-tabname = '/PSYNG/MCHDR'.
  gt_fields-fieldname = 'CONTID'.
  gt_fields-selectflag = 'X'.
  APPEND gt_fields.
  gt_fields-tabname = '/PSYNG/MCHDR'.
  gt_fields-fieldname = 'DESCRIPTION'.
  gt_fields-selectflag = ''.
  APPEND gt_fields.
  gt_fields-tabname = '/PSYNG/MCHDR'.
  gt_fields-fieldname = 'INACTIVE'.
  gt_fields-selectflag = ''.
  APPEND gt_fields.

* Get values / text for mitigating control ID's
  SELECT * INTO TABLE gl_mchdr FROM /psyng/mchdr.
*  WHERE inactive IS null
*  OR inactive EQ space.
  SORT gl_mchdr BY contid.

  LOOP AT gl_mchdr.
    gt_values-line = gl_mchdr-contid.
    APPEND gt_values.
    gt_values-line = gl_mchdr-description.
    APPEND gt_values.
    gt_values-line = gl_mchdr-inactive.
    APPEND gt_values.

  ENDLOOP.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
    EXPORTING
      titel                     = text-t02
    IMPORTING
      select_value              = /psyng/mchdr-contid
    TABLES
      fields                    = gt_fields
      valuetab                  = gt_values
    EXCEPTIONS
      field_not_in_ddic         = 1
      more_then_one_selectfield = 2
      no_selectfield            = 3
      OTHERS                    = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDMODULE.                 " f4_mcontid  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_repid  INPUT
*&---------------------------------------------------------------------*
*       Dropdown F4 help for program
*----------------------------------------------------------------------*
MODULE f4_repid INPUT.

  REFRESH: gt_fields, gt_values.
  gt_fields-tabname = 'TRDIRT'.
  gt_fields-fieldname = 'NAME'.
  gt_fields-selectflag = 'X'.
  APPEND gt_fields.
  gt_fields-tabname = 'TRDIRT'.
  gt_fields-fieldname = 'TEXT'.
  gt_fields-selectflag = ''.
  APPEND gt_fields.
* Get values / text for programs
  SELECT * INTO gl_trdirt FROM trdirt WHERE sprsl = sy-langu.
    gt_values-line = gl_trdirt-name.
    APPEND gt_values.
    gt_values-line = gl_trdirt-text.
    APPEND gt_values.
  ENDSELECT.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
    EXPORTING
      titel                     = text-t01
    IMPORTING
      select_value              = gt_mcrepid-repid
    TABLES
      fields                    = gt_fields
      valuetab                  = gt_values
    EXCEPTIONS
      field_not_in_ddic         = 1
      more_then_one_selectfield = 2
      no_selectfield            = 3
      OTHERS                    = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDMODULE.                 " f4_repid  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0209  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0209 INPUT.
  PERFORM user_command_0209.
ENDMODULE.                 " USER_COMMAND_0209  INPUT
*&---------------------------------------------------------------------*
*&      Form  get_parameter
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_parameter.
  DATA: o_tcode LIKE tstct-tcode.
*Only execute in change mode
  CHECK gf_dispchg = gc_change.
  TABLES: tstcp.

*Start of changes vk
  DATA: BEGIN OF lt_tcode_temp OCCURS 0,
          tcode TYPE tcode,
        END OF lt_tcode_temp,
        lt_source_tcode TYPE
TABLE OF /psyng/bc_para_to_source_tcode WITH HEADER LINE.

  CLEAR:lt_tcode_temp,lt_tcode_temp[],o_tcode.

  lt_tcode_temp-tcode = g_trans_itab-tcode.
  APPEND lt_tcode_temp.

  CALL FUNCTION '/PSYNG/BC_GET_SOURCE_TCODE'
    TABLES
      it_parameter_tcode = lt_tcode_temp
      et_source_tcode    = lt_source_tcode.


  READ TABLE lt_source_tcode INDEX 1.
  IF sy-subrc = 0.
    o_tcode   = lt_source_tcode-tcode.
  ENDIF.


  IF o_tcode NE space.
*--check if function already contains tcode
    READ TABLE g_trans_itab WITH KEY tcode = o_tcode.
    CHECK sy-subrc <> 0.
    PERFORM pop_up_confirm USING o_tcode.
    IF gf_answer = 1.
      g_trans_itab-tcode = o_tcode.
      CLEAR : g_trans_itab-ttext,
              g_trans_itab-flag.
      SELECT SINGLE ttext INTO g_trans_itab-ttext FROM tstct
      WHERE tcode = o_tcode
      AND sprsl = sy-langu.
      old_trans_current_line = critrans-current_line.
      APPEND g_trans_itab.
      DESCRIBE TABLE g_trans_itab LINES critrans-lines.
    ENDIF.
  ENDIF.

*End of changes
ENDFORM.                    " get_parameter
*&---------------------------------------------------------------------*
*&      Form  pop_up_confirm
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM pop_up_confirm USING o_tcode.
  DATA: new_text(200).
  DATA: title(50) .
  title = 'Add Source Transaction? '(201).
  CONCATENATE text-020 g_trans_itab-tcode text-021
  o_tcode text-022 INTO new_text.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = title
      text_question         = new_text
      text_button_1         = text-001
      icon_button_1         = 'ICON_CHECKED'
      text_button_2         = text-002
      icon_button_2         = 'ICON_INCOMPLETE'
      default_button        = '1'
      display_cancel_button = ' '
    IMPORTING
      answer                = gf_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " pop_up_confirm

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0210  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0210 INPUT.
  DATA l_cr_flag TYPE flag VALUE 'X'.                   "HBHALLA
  DATA: l_index TYPE i,
        l_line  TYPE /psyng/texts-line.                 "HBHALLA
  PERFORM user_command_0210 CHANGING l_cr_flag l_index l_line. "HBHALLA

*  DATA: l_filename      LIKE rlgrap-filename,
*        lt_file         LIKE g_criroles_itab OCCURS 0 WITH HEADER LINE,
*        success         VALUE 'Y',
*        l_file_criroles TYPE string,
*        ls_filename     TYPE string.
*
*  RANGES : lr_vrsio FOR /psyng/critcodes-vrsio.
*
*  crt_dte = sy-datum.
*  crt_tme = sy-uzeit.
*  populated = 'X'.
*
*
*  CASE ok_code.
*    WHEN 'INSR'.
*
*      AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
*                  ID 'ACTVT' FIELD '01'
*                  ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
*      IF sy-subrc NE 0.
*        CLEAR : ok_code, sy-ucomm.
*        MESSAGE e108(/psyng/sw) WITH text-120.
*      ENDIF.
*
*      LOOP AT g_criroles_itab WHERE flag = 'X'.
*        CLEAR g_criroles_itab-flag.
*        MODIFY g_criroles_itab.
*      ENDLOOP..
*
*
**      ADD 20 TO critrole-lines.
*      DESCRIBE TABLE g_criroles_itab LINES critrole-lines.
*      PERFORM insert_row_into_tc USING  'CRITROLE' 'G_CRIROLES_ITAB'.
*
*    WHEN 'DELL'.
*
*
*      AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
*                  ID 'ACTVT' FIELD '06'
*                  ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
*      IF sy-subrc NE 0.
*        CLEAR : ok_code, sy-ucomm.
*        MESSAGE e108(/psyng/sw) WITH text-121.
*      ENDIF.
*
*      READ TABLE g_criroles_itab WITH KEY flag = 'X'.
*      IF sy-subrc <> 0.
*        MESSAGE i161(/psyng/sw).
*        EXIT.
*      ENDIF.
*
*      CALL FUNCTION 'POPUP_TO_CONFIRM'
*        EXPORTING
*          titlebar              = text-027
*          text_question         = text-q01
*          text_button_1         = text-123
*          icon_button_1         = 'ICON_DELETE'
*          text_button_2         = text-124
*          icon_button_2         = 'ICON_SYSTEM_CANCEL'
*          default_button        = '2'
*          display_cancel_button = ' '
*        IMPORTING
*          answer                = popup_answer.
*      CHECK popup_answer = '1'.
*
*      DELETE g_criroles_itab WHERE flag = 'X'.
*      DESCRIBE TABLE g_criroles_itab LINES critrole-lines.
*      MESSAGE s121(/psyng/sw) WITH 'Role(s)'.
*
*    WHEN 'SAVE'.
*
**      DELETE FROM /psyng/criroles WHERE agr_name > space
**                                    AND vrsio    = g_sod_vrsio.
*
*
*      LOOP AT g_criroles_itab.
*        gt_crit_roles-agr_name = g_criroles_itab-agr_name.
*        gt_crit_roles-vrsio = g_sod_vrsio.
*        gt_crit_roles-owner = g_criroles_itab-owner.
*        gt_crit_roles-imp = g_criroles_itab-imp.
*        APPEND gt_crit_roles.
*      ENDLOOP.
*
*      CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_ROLES'
*        EXPORTING
*          i_vrsio             = g_sod_vrsio
*          APPEND_FLAG              = 'X'        "HBHALLA
** IMPORTING
**         CRIROLE_ADDED       =
**         CRIROLE_MODIF       =
**         CRIROLE_DEL         =
*        TABLES
*          criroles            = gt_crit_roles
*          texts               = gt_texts_cr
*        EXCEPTIONS
*          empty_list_provided = 1
*          OTHERS              = 2.
*      IF sy-subrc = 0.
*        MESSAGE s120(/psyng/sw).  " Data Saved
*      ENDIF.
*
*
****   SE 3.1 DEVELOPEMNT ITEM C43 Code by Shekhar 17/10/2013
****   ITEM C47 Start fix
*
*      DELETE g_criroles_itab WHERE agr_name = space.
*      DESCRIBE TABLE g_criroles_itab LINES critrole-lines.
*
*
*
*    WHEN 'CHANGES'.
*
*      SUBMIT /psyng/sw_108 VIA SELECTION-SCREEN
*             WITH s_vrsio = g_sod_vrsio
*             WITH p_crole  = 'X'
**             WITH s_cauth IN lr_swaudid
*             AND RETURN.
*
*    WHEN 'ENTER'.
**     Do nothing
*
**   Transport table entries
*    WHEN 'TRANSPORT'.
*      SUBMIT /psyng/sw_048 VIA SELECTION-SCREEN
*             WITH p_vrsio  = g_sod_vrsio
*             WITH p_tagrnm = gc_select
*             AND RETURN.
*
*** Critical role / upload download
*
*    WHEN 'UPDOWN'.
*
*      SUBMIT /psyng/sw_data_upload_download VIA SELECTION-SCREEN
*              WITH sodvrsio  = g_sod_vrsio
**             WITH p_ttcode = gc_select
*              WITH f_ct = ' '
*              WITH f_ctxt = ' '
*              WITH f_cr = 'X'
*              WITH f_crtxt = 'X'
*              WITH f_cp = ' '
*              WITH f_cptxt = ' '
*              WITH f_funh = ' '
*              WITH f_fund = ' '
*              WITH f_funt = ' '
*              WITH f_objd = ' '
*              WITH f_conh = ' '
*              WITH f_cond = ' '
*              WITH f_cont = ' '
*              WITH f_cono = ' '
*              WITH f_cah = ' '
*              WITH f_cad = ' '
*              WITH f_cat = ' '
*              AND RETURN.
*
*
**   Toggle between display and change modes
*    WHEN 'DISPCHG'.
*      IF gf_dispchg = gc_display.
*        sec_actvt = act_change.
*        AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
*                 ID 'ACTVT' FIELD sec_actvt
*                 ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
*        IF sy-subrc NE 0.
*          CLEAR : ok_code, sy-ucomm.
*          MESSAGE e108(/psyng/sw) WITH text-019.
*        ENDIF.
*
*        gf_dispchg = gc_change.
*        PERFORM check_version_editable.
*        CHECK gf_dispchg = gc_change.
*
*        CALL FUNCTION 'ENQUEUE_/PSYNG/TABLEVERS'
*          EXPORTING
**           mode_/psyng/tablevers = 'X'
*            tabname        = '/PSYNG/CRIROLES'
*            vrsio          = g_sod_vrsio
*          EXCEPTIONS
*            foreign_lock   = 1
*            system_failure = 2
*            OTHERS         = 3.
*        IF sy-subrc <> 0.
*          gf_dispchg = gc_display.
*          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*        ELSE.
*          gt_locked-type   = 'TABLEVERS'.
*          gt_locked-object = '/PSYNG/CRIROLES'.
*          APPEND gt_locked.
*        ENDIF.
*      ELSE.
*        sec_actvt = act_display.
*        AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
*                 ID 'ACTVT' FIELD sec_actvt
*                 ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
*        IF sy-subrc NE 0.
*          CLEAR : ok_code, sy-ucomm.
*          MESSAGE e108(/psyng/sw) WITH text-016.
*        ENDIF.
*
*        PERFORM exit_without_save.
*        CHECK gf_answer = 1.
*        CLEAR: first_time, gf_data_change.
*
*        CALL FUNCTION 'DEQUEUE_/PSYNG/TABLEVERS'
*          EXPORTING
**           mode_/psyng/tablevers = 'X'
*            tabname = '/PSYNG/CRIROLES'
*            vrsio   = g_sod_vrsio.
*
*        DELETE gt_locked WHERE type = 'TABLEVERS'.
*        COMMIT WORK.
*        gf_dispchg = gc_display.
*      ENDIF.
*
*    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
*         'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
*         'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8'.
**     If data was changed, ask if user wants to exit without saving
*      IF gf_dispchg = gc_change.
*        PERFORM exit_without_save.
*
*        IF gf_answer <> 1.
*          CLEAR ok_code.
*          EXIT.
*        ENDIF.
*      ENDIF.
*
*      CALL FUNCTION 'DEQUEUE_/PSYNG/TABLEVERS'
*        EXPORTING
*          tabname = '/PSYNG/CRIROLES'
*          vrsio   = g_sod_vrsio.
*
*      DELETE gt_locked WHERE type = 'TABLEVERS'.
*      CLEAR: gf_data_change, g_criroles_itab, g_criroles_itab[],
*      agr_texts, populated, first_role1.
*
*    WHEN 'FS'.
*      g_fullscreen = '0210'.
*      CLEAR: ok_code, sy-ucomm.
*      CALL SCREEN '9000'.
*
*    WHEN 'LTEXT'.
*      DATA  : l_index      TYPE i,
*              lt_texts_cr  TYPE TABLE OF /psyng/texts WITH HEADER LINE,
*              lt_texts_cr1 TYPE TABLE OF /psyng/texts WITH HEADER LINE,
*              l_line       TYPE /psyng/texts-line.
*
*      REFRESH: i_text.
*      DATA : l_idx LIKE sy-tabix.
*
*      READ TABLE g_criroles_itab WITH KEY flag = 'X'.
*      l_index = sy-tabix.
*      IF sy-subrc NE 0.
*        MESSAGE i161(/psyng/sw).
*        EXIT.
*      ENDIF.
*
*      LOOP AT gt_texts_cr WHERE textname = g_criroles_itab-agr_name.
*        i_text-text = gt_texts_cr-text.
*        APPEND i_text.
*      ENDLOOP.
*      IF sy-subrc = 0.
*        gt_editor_text[] = i_text[].
*      ELSE.
*
*        SELECT line text FROM /psyng/texts
*           INTO CORRESPONDING FIELDS OF TABLE i_text
*           WHERE textname = g_criroles_itab-agr_name
*           AND   object   = 'Q'
*           AND   vrsio    = g_sod_vrsio
*           AND   spras    = sy-langu
*           ORDER BY line.
*        IF sy-subrc = 0.
*          gt_editor_text[] = i_text[].
*        ELSE.
*          REFRESH gt_editor_text.
*          CLEAR gt_editor_text.
*        ENDIF.
*      ENDIF.
*
*
*      CONCATENATE 'Role' g_criroles_itab-agr_name '- SOD Version -'
*       g_sod_vrsio INTO gtitle SEPARATED BY space.
*
*      PERFORM popup_long_text.
*      CLEAR gtitle.
*      CLEAR g_criroles_itab-flag.
*      REFRESH : lt_texts_cr.
*      CLEAR i_text.
*      REFRESH i_text.
*      i_text[] = gt_editor_text[].
*
*      FREE : gt_editor_text.
*      CLEAR : gt_editor_text.
*
*      lt_texts_cr-vrsio    = g_sod_vrsio.
*      lt_texts_cr-textname = g_criroles_itab-agr_name.
*      lt_texts_cr-object = 'Q'.
*      IF i_text[] IS INITIAL.
*        SELECT SINGLE line FROM /psyng/texts
*        INTO l_line WHERE textname = g_criroles_itab-agr_name
*        AND vrsio = g_sod_vrsio
*        AND object = 'Q'.
*        IF sy-subrc = 0.
*          DELETE FROM /psyng/texts
*                    WHERE textname = g_criroles_itab-agr_name
*                                       AND vrsio = g_sod_vrsio
*                                       AND object = 'Q'.
*          MODIFY g_criroles_itab INDEX l_index TRANSPORTING flag.
*          CLEAR g_criroles_itab.
*          EXIT.
*        ELSE.
*          MODIFY g_criroles_itab INDEX l_index TRANSPORTING flag.
*          CLEAR g_criroles_itab.
*          EXIT.
*        ENDIF.
*
*      ELSE.
*
*        LOOP AT i_text.
*          lt_texts_cr-line =  lt_texts_cr-line + 1.
*          MOVE-CORRESPONDING i_text TO lt_texts_cr.
*          APPEND lt_texts_cr.
*        ENDLOOP.
*      ENDIF.
*
*      lt_texts_cr[] = lt_texts_cr[].
*      SORT lt_texts_cr1 BY textname.
*      DELETE ADJACENT DUPLICATES FROM lt_texts_cr1 COMPARING textname.
*
*      LOOP AT lt_texts_cr1.
*        DELETE gt_texts_cr WHERE textname = lt_texts_cr1-textname.
*      ENDLOOP.
*
*
*      APPEND LINES OF lt_texts_cr TO gt_texts_cr.
*      CLEAR lt_texts_cr.
*      REFRESH lt_texts_cr.
*      SORT gt_texts_cr.
*      DELETE ADJACENT DUPLICATES FROM gt_texts_cr COMPARING ALL FIELDS.
*      MODIFY g_criroles_itab INDEX l_index TRANSPORTING flag.
*      CLEAR g_criroles_itab.
*
*    WHEN 'CADET'.
*      sec_actvt = act_print.
*      AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
*               ID 'ACTVT' FIELD sec_actvt
*               ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
*      IF sy-subrc NE 0.
*        CLEAR : ok_code, sy-ucomm.
*        MESSAGE e108(/psyng/sw) WITH text-050.
*      ENDIF.
*
*      SUBMIT /psyng/sw_117 WITH sodvrsio = g_sod_vrsio AND RETURN.
*
*    WHEN 'SORT_A'.
*      sort_type = 'A'.
*      PERFORM sort_col_cr USING sort_type.
*
*    WHEN 'SORT_D'.
*      sort_type = 'D'.
*      PERFORM sort_col_cr USING sort_type.
*
***    WHEN 'SEARCH'.
*    WHEN 'FILTER'.
*
*      DATA: l_tabix    LIKE sy-tabix,
*            lt_crirole LIKE TABLE OF g_criroles_itab WITH HEADER LINE.
*
*      CLEAR: gl_critrole,
*             gl_critrole,
*             gl_critrans.
*      g_call_scrn = '0210'.
*      CALL SCREEN 907 STARTING AT 3 10.
*      CHECK sy-ucomm = 'CONTINUE'.
*
*
*
*      RANGES: r_rrole FOR /psyng/criroles-agr_name,
*                   r_rowner FOR /psyng/criroles-owner,
*                   r_rimp FOR /psyng/criroles-imp.
*
*      REFRESH: lt_crirole, r_rrole, r_rowner, r_rimp.
**--- Collect search input in ranges
*      IF NOT  gl_critrole-agr_name IS INITIAL.
*        IF gl_critrole-agr_name CS '*'.
*
*          r_rrole-sign = 'I'.
*          r_rrole-option = 'CP'.
*        ELSE.
*          r_rrole-sign = 'I'.
*          r_rrole-option = 'EQ'.
*        ENDIF.
*        r_rrole-low =  gl_critrole-agr_name.
*        COLLECT r_rrole.
*      ENDIF.
*
*      IF NOT gl_critrans-owner IS INITIAL.
*        IF gl_critrans-owner CS '*'.
*          r_rowner-sign = 'I'.
*          r_rowner-option = 'CP'.
*        ELSE.
*          r_rowner-sign = 'I'.
*          r_rowner-option = 'EQ'.
*        ENDIF.
*        r_rowner-low = gl_critrans-owner.
*        COLLECT r_rowner.
*      ENDIF.
*
*      IF NOT gl_critrans-imp IS INITIAL.
*        IF gl_critrans-imp CS '*'.
*          r_rimp-sign = 'I'.
*          r_rimp-option = 'CP'.
*        ELSE.
*          r_rimp-sign = 'I'.
*          r_rimp-option = 'EQ'.
*        ENDIF.
*        r_rimp-low = gl_critrans-imp.
*        COLLECT r_rimp.
*      ENDIF.
*
*
**   Filter data from tc table acc. to intput
*      LOOP AT g_criroles_itab WHERE agr_name IN r_rrole
*                                 AND owner   IN r_rowner
*                                 AND imp     IN r_rimp.
*
*        MOVE-CORRESPONDING  g_criroles_itab TO lt_crirole.
*        APPEND lt_crirole.
*      ENDLOOP.
*
*      REFRESH g_criroles_itab.
*      LOOP AT lt_crirole.
*        MOVE-CORRESPONDING lt_crirole TO g_criroles_itab.
*        APPEND g_criroles_itab.
*        CLEAR lt_crirole.
*      ENDLOOP.
*
*      IF g_criroles_itab[] IS INITIAL.
*        CLEAR g_filtertext.
**      ELSE.
*      ENDIF.
*      g_filtertext = 'Filter applied'(248).
*
**---->when no input in search screen
*      IF gl_critrole-agr_name IS INITIAL
*               AND gl_critrans-owner IS INITIAL
*               AND gl_critrans-imp IS INITIAL.
*        REFRESH g_criroles_itab.
*        SELECT * FROM /psyng/criroles WHERE vrsio = g_sod_vrsio.
*          g_criroles_itab-agr_name =  /psyng/criroles-agr_name.
*          g_criroles_itab-imp     =   /psyng/criroles-imp.
*          g_criroles_itab-owner = /psyng/criroles-owner.
*          g_criroles_itab-flag = space.
*          SELECT SINGLE text INTO g_criroles_itab-text FROM agr_texts
*          WHERE agr_name =  g_criroles_itab-agr_name
*          AND   spras    = sy-langu
*          AND   line     = 0.
*          IF sy-subrc = 0.
*            APPEND g_criroles_itab.
*          ELSE.
*           g_criroles_itab-text = 'Role for cross system analysis'(299).
*            APPEND g_criroles_itab.
*          ENDIF.
*          ADD 1 TO critrole-current_line.
*        ENDSELECT.
*        CLEAR g_filtertext.
*      ENDIF.
*
*    WHEN 'UNFILTER'.
*      CLEAR: g_filtertext, g_criroles_itab[].
*      SELECT * FROM /psyng/criroles WHERE vrsio = g_sod_vrsio.
*        g_criroles_itab-agr_name =  /psyng/criroles-agr_name.
*        g_criroles_itab-imp     =   /psyng/criroles-imp.
*        g_criroles_itab-owner = /psyng/criroles-owner.
*        g_criroles_itab-flag = space.
*        SELECT SINGLE text INTO g_criroles_itab-text FROM agr_texts
*        WHERE agr_name =  g_criroles_itab-agr_name
*        AND   spras    = sy-langu
*        AND   line     = 0.
*        IF sy-subrc = 0.
*          APPEND g_criroles_itab.
*        ELSE.
*          g_criroles_itab-text = 'Role for cross system analysis'(299).
*          APPEND g_criroles_itab.
*        ENDIF.
**        ADD 1 TO critrole-current_line. "HBHALLA
*      ENDSELECT.
*      DESCRIBE TABLE g_criroles_itab LINES critrole-current_line."HBHALLA
*      SORT g_criroles_itab BY agr_name.
*
*    WHEN OTHERS.
*
*      CLEAR populated.
*
*  ENDCASE.
*
** Clear OK_CODE unless other tabs are selected
*  IF ok_code NS '_FC'.
*    CLEAR ok_code.
*  ENDIF.


ENDMODULE.                 " USER_COMMAND_0210  INPUT

*---------------------------------------------------------------------*
*       MODULE USER_COMMAND_0213 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0213 INPUT.
  DATA l_cp_flag TYPE flag VALUE 'X'.           "HBHALLA
  PERFORM user_command_0213 CHANGING l_cp_flag. "HBHALLA

** DATA: l_filename LIKE rlgrap-filename,
*  DATA: lt_file1        LIKE g_criprofs_itab OCCURS 0 WITH HEADER LINE,
*        l_file_criprofs TYPE string,
*        ls_filename1    TYPE string.
**  RANGES : lr_vrsio FOR /psyng/criprof-vrsio.
*  crt_dte = sy-datum.
*  crt_tme = sy-uzeit.
*  populated = 'X'.
*
*
*  CASE ok_code.
*    WHEN 'INSR'.
*
*      AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
*                  ID 'ACTVT' FIELD '01'
*                  ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
*      IF sy-subrc NE 0.
*        CLEAR : ok_code, sy-ucomm.
*        MESSAGE e108(/psyng/sw) WITH text-118.
*      ENDIF.
*
**      ADD 20 TO critprof-lines.
*      DESCRIBE TABLE g_criprofs_itab LINES critprof-lines.
*      PERFORM insert_row_into_tc USING  'CRITPROF' 'G_CRIPROFS_ITAB'.
*
*
*    WHEN 'DELL'.
*
*      AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
*              ID 'ACTVT' FIELD '06'
*              ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
*      IF sy-subrc NE 0.
*        CLEAR : ok_code, sy-ucomm.
*        MESSAGE e108(/psyng/sw) WITH text-119.
*      ENDIF.
*
*      READ TABLE g_criprofs_itab WITH KEY flag = 'X'.
*      IF sy-subrc <> 0.
*        MESSAGE i161(/psyng/sw).
*        EXIT.
*      ENDIF.
*
*      CALL FUNCTION 'POPUP_TO_CONFIRM'
*        EXPORTING
*          titlebar              = text-027
*          text_question         = text-q01
*          text_button_1         = text-123
*          icon_button_1         = 'ICON_DELETE'
*          text_button_2         = text-124
*          icon_button_2         = 'ICON_SYSTEM_CANCEL'
*          default_button        = '2'
*          display_cancel_button = ' '
*        IMPORTING
*          answer                = popup_answer.
*      CHECK popup_answer = '1'.
*
*      DELETE g_criprofs_itab WHERE flag = 'X'.
*      DESCRIBE TABLE g_criprofs_itab LINES critprof-lines.
*      MESSAGE s121(/psyng/sw) WITH 'Profile(s)'. "deleted
*
*    WHEN 'SAVE'.
*
**      DELETE FROM /psyng/criprof WHERE profile > space
**                                   AND vrsio   = g_sod_vrsio.
*
*      LOOP AT g_criprofs_itab.
*        gt_crit_profs-profile = g_criprofs_itab-profn.
*        gt_crit_profs-vrsio = g_sod_vrsio.
*        gt_crit_profs-owner = g_criprofs_itab-owner.
**        gt_crit_trans-description = g_trans_itab-description.
*        gt_crit_profs-imp = g_criprofs_itab-imp.
*        APPEND gt_crit_profs.
*      ENDLOOP.
*
*      CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_PROFILES'
*        EXPORTING
*          i_vrsio             = g_sod_vrsio
*          APPEND_FLAG         = 'X'          "HBHALLA
**     IMPORTING
**         CRIPROF_ADDED       =
**         CRIPROF_MODIF       =
**         CRIPROF_DEL         =
*        TABLES
*          criprof             = gt_crit_profs
*          texts               = gt_texts_cp
*        EXCEPTIONS
*          empty_list_provided = 1
*          OTHERS              = 2.
*      IF sy-subrc = 0.
*        MESSAGE s120(/psyng/sw).  " Data Saved
*      ENDIF.
*
*
****   SE 3.1 DEVELOPEMNT ITEM C43 Code by Shekhar 17/10/2013
****   ITEM C48 Start fix
*
*      DELETE g_criprofs_itab WHERE profn = space.
*      DESCRIBE TABLE g_criprofs_itab LINES critprof-lines.
****   ENDFIX.
*
*
**      success = 'Y'.
**      LOOP AT g_criprofs_itab.
**        /psyng/criprof-profile = g_criprofs_itab-profn.
**        /psyng/criprof-vrsio   = g_sod_vrsio.
**        /psyng/criprof-imp = g_criprofs_itab-imp.
**        /psyng/criprof-owner = g_criprofs_itab-owner.
**        /psyng/criprof-description = g_criprofs_itab-description.
**        INSERT /psyng/criprof.
**        IF sy-subrc NE 0.
**          success = 'N'.
**        ENDIF.
**      ENDLOOP.
**      IF success = 'Y'.
**        MESSAGE s120(/psyng/sw).  " Data Saved
**      ELSE.
**        MESSAGE s122(/psyng/sw).  " Data Not Saved
**      ENDIF.
*
*
*    WHEN 'CHANGES'.
*
**      Clear: lr_vrsio.
**      lr_vrsio-sign   = 'I'.
**      lr_vrsio-option = 'EQ'.
**      lr_vrsio-low    = g_sod_vrsio.
**      APPEND lr_vrsio.
*
**      IF NOT /psyng/swaudc2-swaudid IS INITIAL.
**        lr_swaudid-sign = 'I'.
**        lr_swaudid-option = 'EQ'.
**        lr_swaudid-low = /psyng/swaudc2-swaudid.
**        APPEND lr_swaudid.
*
**    ENDIF.
*
*      SUBMIT /psyng/sw_108 VIA SELECTION-SCREEN
*             WITH s_vrsio = g_sod_vrsio
*             WITH p_cprof  = 'X'
**             WITH s_cauth IN lr_swaudid
*             AND RETURN.
*
*
*    WHEN 'ENTER'.
**     Do nothing
*
**   Transport table entries
*    WHEN 'TRANSPORT'.
*      SUBMIT /psyng/sw_048 VIA SELECTION-SCREEN
*             WITH p_vrsio = g_sod_vrsio
*             WITH p_tprof = gc_select
*             AND RETURN.
*
*
***  Critical profile Upload / Download
*
*    WHEN 'UPDOWN'.
*
*      SUBMIT /psyng/sw_data_upload_download VIA SELECTION-SCREEN
*              WITH sodvrsio  = g_sod_vrsio
**             WITH p_ttcode = gc_select
*              WITH f_ct = ' '
*              WITH f_ctxt = ' '
*              WITH f_cr = ' '
*              WITH f_crtxt = ' '
*              WITH f_cp = 'X'
*              WITH f_cptxt = 'X'
*              WITH f_funh = ' '
*              WITH f_fund = ' '
*              WITH f_funt = ' '
*              WITH f_objd = ' '
*              WITH f_conh = ' '
*              WITH f_cond = ' '
*              WITH f_cont = ' '
*              WITH f_cono = ' '
*              WITH f_cah = ' '
*              WITH f_cad = ' '
*              WITH f_cat = ' '
*              AND RETURN.
*
*
**   Toggle between display and change modes
*    WHEN 'DISPCHG'.
*      IF gf_dispchg = gc_display.
*        sec_actvt = act_change.
*        AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
*                 ID 'ACTVT' FIELD sec_actvt
*                 ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
*        IF sy-subrc NE 0.
*          CLEAR : ok_code, sy-ucomm.
*          MESSAGE e108(/psyng/sw) WITH text-025.
*        ENDIF.
*
*        gf_dispchg = gc_change.
*        PERFORM check_version_editable.
*        CHECK gf_dispchg = gc_change.
*
*        CALL FUNCTION 'ENQUEUE_/PSYNG/TABLEVERS'
*          EXPORTING
*            tabname        = '/PSYNG/CRIPROF'
*            vrsio          = g_sod_vrsio
*          EXCEPTIONS
*            foreign_lock   = 1
*            system_failure = 2
*            OTHERS         = 3.
*        IF sy-subrc <> 0.
*          gf_dispchg = gc_display.
*          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*        ELSE.
*          gt_locked-type   = 'TABLEVERS'.
*          gt_locked-object = '/PSYNG/CRIPROF'.
*          APPEND gt_locked.
*        ENDIF.
*      ELSE.
*        sec_actvt = act_display.
*        AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
*                 ID 'ACTVT' FIELD sec_actvt
*                 ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
*        IF sy-subrc NE 0.
*          CLEAR : ok_code, sy-ucomm.
*          MESSAGE e108(/psyng/sw) WITH text-210.
*        ENDIF.
*
*        PERFORM exit_without_save.
*        CHECK gf_answer = '1'.
*        CLEAR: first_time, gf_data_change.
*
*        CALL FUNCTION 'DEQUEUE_/PSYNG/TABLEVERS'
*          EXPORTING
*            tabname = '/PSYNG/CRIPROF'
*            vrsio   = g_sod_vrsio.
*
*        DELETE gt_locked WHERE type = 'TABLEVERS'.
*        gf_dispchg = gc_display.
*      ENDIF.
*
*    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
*         'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
*         'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8'.
**     If data was changed, ask if user wants to exit without saving
*      IF gf_dispchg = gc_change.
*        PERFORM exit_without_save.
*
*        IF gf_answer <> '1'.
*          CLEAR ok_code.
*          EXIT.
*        ENDIF.
*      ENDIF.
*
*      CALL FUNCTION 'DEQUEUE_/PSYNG/TABLEVERS'
*        EXPORTING
*          tabname = '/PSYNG/CRIPROF'
*          vrsio   = g_sod_vrsio.
*
*      DELETE gt_locked WHERE type = 'TABLEVERS'.
*      CLEAR: gf_data_change, g_criprofs_itab, g_criprofs_itab[],
*      agr_texts, populated, first_prof1.
*
*    WHEN 'FS'.
*      g_fullscreen = '0213'.
*      CLEAR: ok_code, sy-ucomm.
*      CALL SCREEN '9000'.
*
*    WHEN 'LTEXT'.
*      CLEAR l_index.
*      DATA : lt_texts_cp  TYPE TABLE OF /psyng/texts WITH HEADER LINE,
*             lt_texts_cp1 TYPE TABLE OF /psyng/texts WITH HEADER LINE.
*
*      REFRESH: i_text.
*      READ TABLE g_criprofs_itab WITH KEY flag = 'X'.
*      l_index = sy-tabix.
*      IF sy-subrc NE 0.
*        MESSAGE i161(/psyng/sw).
*        EXIT.
*      ENDIF.
*
*      LOOP AT gt_texts_cp WHERE textname = g_criprofs_itab-profn.
*        i_text-text = gt_texts_cp-text.
*        APPEND i_text.
*      ENDLOOP.
*      IF sy-subrc = 0.
*        gt_editor_text[] = i_text[].
*      ELSE.
*        SELECT line text FROM /psyng/texts
*           INTO CORRESPONDING FIELDS OF TABLE i_text
*           WHERE textname = g_criprofs_itab-profn
*           AND   object   = 'P'
*           AND   vrsio    = g_sod_vrsio
*           AND   spras    = sy-langu
*           ORDER BY line.
*        IF sy-subrc = 0.
*          gt_editor_text[] = i_text[].
*        ELSE.
*          REFRESH gt_editor_text.
*          CLEAR gt_editor_text.
*        ENDIF.
*      ENDIF.
*
*      CONCATENATE 'Profile' g_criprofs_itab-profn  '- SOD Version -'
*      g_sod_vrsio INTO gtitle SEPARATED BY space.
*      PERFORM popup_long_text.
*      CLEAR gtitle.
*      CLEAR g_criprofs_itab-flag.
*      CLEAR i_text.
*      REFRESH i_text.
*      REFRESH lt_texts_cp.
*
*      i_text[] = gt_editor_text[].
*
*
*      FREE : gt_editor_text.
*      CLEAR : gt_editor_text.
*
*      lt_texts_cp-vrsio    = g_sod_vrsio.
*      lt_texts_cp-textname = g_criprofs_itab-profn.
*      lt_texts_cp-object = 'P'.
*      IF i_text[] IS INITIAL.
*        SELECT SINGLE line FROM /psyng/texts
*        INTO l_line WHERE textname = g_criprofs_itab-profn
*        AND vrsio = g_sod_vrsio
*        AND object = 'P'.
*        IF sy-subrc = 0.
*          DELETE FROM /psyng/texts
*                       WHERE textname = g_criprofs_itab-profn
*                          AND vrsio = g_sod_vrsio
*                          AND object = 'P'.
*          MODIFY g_criprofs_itab INDEX l_index TRANSPORTING flag.
*          CLEAR g_criprofs_itab.
*          EXIT.
*        ELSE.
*          MODIFY g_criprofs_itab INDEX l_index TRANSPORTING flag.
*          CLEAR g_criprofs_itab.
*          EXIT.
*        ENDIF.
*      ELSE.
*        LOOP AT i_text.
*          lt_texts_cp-line = lt_texts_cp-line + 1.
*          MOVE-CORRESPONDING i_text TO lt_texts_cp.
*          APPEND lt_texts_cp.
*        ENDLOOP.
*      ENDIF.
*
*      lt_texts_cp1[] = lt_texts_cp[].
*      SORT lt_texts_cp1 BY textname.
*      DELETE ADJACENT DUPLICATES FROM lt_texts_cp1 COMPARING textname.
*
*      LOOP AT lt_texts_cp1.
*        DELETE gt_texts_cp WHERE textname = lt_texts_cp1-textname.
*      ENDLOOP.
*
*
*
*      APPEND LINES OF lt_texts_cp TO gt_texts_cp.
*      CLEAR lt_texts_cp.
*      REFRESH lt_texts_cp.
*
*      SORT gt_texts_cp.
*      DELETE ADJACENT DUPLICATES FROM gt_texts_cp COMPARING ALL FIELDS.
*
*
*      MODIFY g_criprofs_itab INDEX l_index TRANSPORTING flag.
*      CLEAR g_criprofs_itab.
*
*    WHEN 'CADET'.
*      sec_actvt = act_print.
*      AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
*               ID 'ACTVT' FIELD sec_actvt
*               ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
*      IF sy-subrc NE 0.
*        CLEAR : ok_code, sy-ucomm.
*        MESSAGE e108(/psyng/sw) WITH text-108.
*      ENDIF.
*
*      SUBMIT /psyng/sw_118 WITH sodvrsio = g_sod_vrsio AND RETURN.
*
*    WHEN 'SORT_A'.
*      sort_type = 'A'.
*      PERFORM sort_col_cf USING sort_type.
*      first_prof1 = 'X'.
*
*    WHEN 'SORT_D'.
*      sort_type = 'D'.
*      PERFORM sort_col_cf USING sort_type.
*      first_prof1 = 'X'.
*
**    WHEN 'SEARCH'.
*    WHEN 'FILTER'.
*      DATA: lt_critprof LIKE TABLE OF g_criprofs_itab WITH HEADER LINE.
*
*      CLEAR: gl_criprofs,
*             gl_critrans,
*             gl_critrole.
*      g_call_scrn = '0213'.
*      CALL SCREEN 907 STARTING AT 3 10.
*      CHECK sy-ucomm = 'CONTINUE'.
*
*
*
*      RANGES: r_prof FOR /psyng/criprof-profile,
*              r_owner FOR /psyng/criprof-owner,
*              r_imp FOR /psyng/criprof-imp.
** --- Collect search input in Ranges
*      REFRESH: lt_critprof, r_prof, r_owner, r_imp.
*      IF NOT  gl_criprofs-profn IS INITIAL.
*        IF gl_criprofs-profn CS '*'.
*
*          r_prof-sign = 'I'.
*          r_prof-option = 'CP'.
*        ELSE.
*          r_prof-sign = 'I'.
*          r_prof-option = 'EQ'.
*        ENDIF.
*        r_prof-low =  gl_criprofs-profn.
*        COLLECT r_prof.
*      ENDIF.
*
*      IF NOT gl_critrans-owner IS INITIAL.
*        IF gl_critrans-owner CS '*'.
*          r_owner-sign = 'I'.
*          r_owner-option = 'CP'.
*        ELSE.
*          r_owner-sign = 'I'.
*          r_owner-option = 'EQ'.
*        ENDIF.
*        r_owner-low = gl_critrans-owner.
*        COLLECT r_owner.
*      ENDIF.
*
*      IF NOT gl_critrans-imp IS INITIAL.
*        IF gl_critrans-imp CS '*'.
*          r_imp-sign = 'I'.
*          r_imp-option = 'CP'.
*        ELSE.
*          r_imp-sign = 'I'.
*          r_imp-option = 'EQ'.
*        ENDIF.
*        r_imp-low = gl_critrans-imp.
*        COLLECT r_imp.
*      ENDIF.
*
***** Filter data from tc table acc. to Search input
*      LOOP AT g_criprofs_itab WHERE   profn    IN r_prof
*                                 AND  owner   IN r_owner
*                                 AND imp    IN r_imp.
*
*        MOVE-CORRESPONDING  g_criprofs_itab TO lt_critprof.
*        APPEND lt_critprof.
*      ENDLOOP.
*
*      REFRESH g_criprofs_itab.
*      LOOP AT lt_critprof.
*        MOVE-CORRESPONDING lt_critprof TO g_criprofs_itab.
*        APPEND g_criprofs_itab.
*        CLEAR: lt_critprof.
*      ENDLOOP.
*
*      IF g_criprofs_itab[] IS INITIAL.
*        CLEAR g_filtertext_p.
**      ELSE.
*      ENDIF.
*      g_filtertext_p = 'Filter applied'(248).
*
**---->when no input in search screen
*      IF gl_criprofs-profn IS INITIAL
*               AND gl_critrans-owner IS INITIAL
*               AND gl_critrans-imp IS INITIAL.
*        REFRESH g_criprofs_itab.
*
*        SELECT * FROM /psyng/criprof WHERE vrsio = g_sod_vrsio.
*          g_criprofs_itab-profn =  /psyng/criprof-profile.
*          g_criprofs_itab-imp     =   /psyng/criprof-imp.
*          g_criprofs_itab-flag = space.
*          g_criprofs_itab-owner = /psyng/criprof-owner.
*
*          SELECT SINGLE ptext INTO  g_criprofs_itab-ptext FROM usr11
*          WHERE profn =  g_criprofs_itab-profn
*          AND   langu    = sy-langu
*          AND   aktps    = 'A'.
*          IF sy-subrc = 0.
*            APPEND g_criprofs_itab.
*          ELSE.
*       g_criprofs_itab-ptext = 'Profile for cross system analysis'(300).
*            APPEND g_criprofs_itab.
*          ENDIF.
*          ADD 1 TO critprof-current_line.
*        ENDSELECT.
*
*        CLEAR g_filtertext_p.
*      ENDIF.
*
*    WHEN 'PUNFILTER'.
*      CLEAR: g_filtertext_p, g_criprofs_itab[].
*
*      SELECT * FROM /psyng/criprof WHERE vrsio = g_sod_vrsio.
*        g_criprofs_itab-profn =  /psyng/criprof-profile.
*        g_criprofs_itab-imp     =   /psyng/criprof-imp.
*        g_criprofs_itab-flag = space.
*        g_criprofs_itab-owner = /psyng/criprof-owner.
*
*        SELECT SINGLE ptext INTO  g_criprofs_itab-ptext FROM usr11
*        WHERE profn =  g_criprofs_itab-profn
*        AND   langu    = sy-langu
*        AND   aktps    = 'A'.
*        IF sy-subrc = 0.
*          APPEND g_criprofs_itab.
*        ELSE.
*       g_criprofs_itab-ptext = 'Profile for cross system analysis'(300).
*          APPEND g_criprofs_itab.
*        ENDIF.
**        ADD 1 TO critprof-current_line. "HBHALLA
*      ENDSELECT.
*      DESCRIBE TABLE g_criprofs_itab LINES critprof-current_line. "HBHALLA
*      SORT g_criprofs_itab BY profn.
*
*    WHEN OTHERS.
*      CLEAR populated.
*  ENDCASE.
*
** Clear OK_CODE unless other tabs are selected
*  IF ok_code NS '_FC'.
*    CLEAR ok_code.
*  ENDIF.


ENDMODULE.                 " USER_COMMAND_0213  INPUT
*&---------------------------------------------------------------------*
*&      Module  mccriauth_mark  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE mccriauth_mark INPUT.
  IF gt_mccauser-sel = 'X'.
    IF ok_code = 'REPLACE'. "#EC SAST_CI_GEN_CHECK
      READ TABLE gt_mccauser INDEX tc_mccriauth-current_line.
      IF gt_mccauser-sel <> 'X'.
        MESSAGE e398(00) WITH text-e10.
      ENDIF.
    ENDIF.

    MODIFY gt_mccauser INDEX tc_mccriauth-current_line.
  ENDIF.

ENDMODULE.                 " mccriauth_mark  INPUT
*&---------------------------------------------------------------------*
*&      Module  mccauser_modify  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE mccauser_modify INPUT.
  MODIFY gt_mccauser INDEX tc_mccriauth-current_line.
ENDMODULE.                 " mccauser_modify  INPUT

*&---------------------------------------------------------------------*
*&      Module  mccarole_mark  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE mccarole_mark INPUT.
  IF gt_mccarole-sel = 'X'.
    IF ok_code = 'REPLACE'. "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (06/12/24)
      READ TABLE gt_mccarole INDEX tc_mccarole-current_line.
      IF gt_mccarole-sel <> 'X'.
        MESSAGE e398(00) WITH text-e10.
      ENDIF.
    ENDIF.

    MODIFY gt_mccarole INDEX tc_mccarole-current_line.
  ENDIF.
ENDMODULE.                 " mccarole_mark  INPUT

*&---------------------------------------------------------------------*
*&      Module  mccarole_modify  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE mccarole_modify INPUT.
  MODIFY gt_mccarole INDEX tc_mccarole-current_line.
ENDMODULE.                 " mccarole_modify  INPUT

*&---------------------------------------------------------------------*
*&      Module  EXPORT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE export INPUT.
*EXPORT itab TO MEMORY ID c_e378.
  EXPORT itab1 TO MEMORY ID c_e377.
ENDMODULE.                 " EXPORT  INPUT
*&---------------------------------------------------------------------*
*&      Form  call_area_menu
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM call_area_menu.

  DATA: l_menu LIKE ttree-id.

  se_config_param 'AREA_MENU' l_menu.
  IF l_menu IS INITIAL.
    MESSAGE e398(00) WITH  text-e19.
  ENDIF.

  CALL FUNCTION 'BMENU_START_BROWSER'
    EXPORTING
      mode                = 'D'
      tree_id             = l_menu
    EXCEPTIONS
      tree_does_not_exist = 1
      no_authority        = 2
      OTHERS              = 3.

  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE e398(00) WITH  text-e18.
      WHEN 2.
        MESSAGE e398(00) WITH  text-066.
      WHEN OTHERS.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDCASE.
  ENDIF.

ENDFORM.                    " call_area_menu

*&---------------------------------------------------------------------*
*&      Module  set_version  INPUT
*&---------------------------------------------------------------------*
*       Set version for foreign key check
*----------------------------------------------------------------------*
MODULE set_version INPUT.
  /psyng/functtran-vrsio = g_sod_vrsio.
ENDMODULE.                 " set_version  INPUT

*&---------------------------------------------------------------------*
*&      Module  validate_sod_vrsio  INPUT
*&---------------------------------------------------------------------*
*       Validate SOD version
*----------------------------------------------------------------------*
MODULE validate_sod_vrsio INPUT.
  PERFORM validate_sod_vrsio USING g_get_vrsio.
ENDMODULE.                 " validate_sod_vrsio  INPUT


*---------------------------------------------------------------------*
*       FORM validate_sod_vrsio                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_VRSIO                                                       *
*---------------------------------------------------------------------*
FORM validate_sod_vrsio USING i_vrsio.
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/swsodvers
                WHERE vrsio = i_vrsio.
  IF sy-subrc <> 0.
    MESSAGE e100(/psyng/sw).
  ENDIF.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM get_desc_sod_vrsio                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_VRSIO                                                       *
*  -->  E_DESC                                                        *
*---------------------------------------------------------------------*
FORM get_desc_sod_vrsio
  USING
    i_vrsio
  CHANGING
    e_desc TYPE /psyng/desc132.
  IF g_sod_vrsio <> i_vrsio OR e_desc IS INITIAL.
    SELECT SINGLE vdesc INTO e_desc FROM /psyng/swsodvers
                  WHERE vrsio = i_vrsio.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0902  INPUT
*&---------------------------------------------------------------------*
*       Handle user commands for screen 902
*----------------------------------------------------------------------*
MODULE user_command_0902 INPUT.
  CASE sy-ucomm.
    WHEN 'ENTER'.
      PERFORM validate_sod_vrsio USING g_get_vrsio.
      PERFORM release_locked.
*--Get Description
      PERFORM get_desc_sod_vrsio
                  USING
                     g_get_vrsio
                  CHANGING
                     g_sod_vrsio_desc.

      g_sod_vrsio = g_get_vrsio.

      SET PARAMETER ID '/PSYNG/VRSIO' FIELD g_sod_vrsio.

      IF g_set_default = 'X'.
        PERFORM set_default_user_param.
      ENDIF.
  ENDCASE.

  SET SCREEN 0.
  LEAVE SCREEN.
ENDMODULE.                 " USER_COMMAND_0902  INPUT

*&---------------------------------------------------------------------*
*&      Module  pai_0903  INPUT
*&---------------------------------------------------------------------*
*       Handle user commands for screen 903
*       Screen 905 uses this module also
*----------------------------------------------------------------------*
MODULE pai_0903 INPUT.
  SET SCREEN 0.
  LEAVE SCREEN.
ENDMODULE.                 " pai_0903  INPUT
*&---------------------------------------------------------------------*
*&      Module  F4_COMPANY_AUD  INPUT
*&---------------------------------------------------------------------*
*       F4 help for mitigating control auditor's company
*----------------------------------------------------------------------*
MODULE f4_company_aud INPUT.
  DATA : ls_fmname    TYPE rs38l_fnam.
*--Check what FM is configured for search help for Company
  se_config_param 'SW_COMPANY_SHLP_FM' ls_fmname.

  IF NOT ls_fmname IS INITIAL.
    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = ls_fmname
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
*--Configured Fm does not exist, use default
      MESSAGE s113(/psyng/sw) WITH
      'Cannot determine SW_COMPANY_SHLP_FM with FM '(c05)
      ls_fmname '. FM doesn''t exist'(c06).
    ENDIF.
  ELSE.
    ls_fmname = '/PSYNG/SW_074'.
  ENDIF.
  CALL FUNCTION ls_fmname "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Function name is variable so it can’t be fixed.(11/12/24)
    CHANGING
      e_company = gt_mcauditor-company.
ENDMODULE.                 " F4_COMPANY_AUD  INPUT
*&---------------------------------------------------------------------*
*&      Module  F4_COMPANY_CON  INPUT
*&---------------------------------------------------------------------*
*       F4 help for conflict owner's company
*----------------------------------------------------------------------*
MODULE f4_company_con INPUT.
*--Check what FM is configured for search help for Company
  se_config_param 'SW_COMPANY_SHLP_FM' ls_fmname.
  IF NOT ls_fmname IS INITIAL.
    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = ls_fmname
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
*--Configured Fm does not exist, use default
      MESSAGE s113(/psyng/sw) WITH
      'Cannot determine SW_COMPANY_SHLP_FM with FM '
      ls_fmname '. FM doesn''t exist'.
    ENDIF.
  ELSE.
    ls_fmname = '/PSYNG/SW_074'.
  ENDIF.


  CALL FUNCTION ls_fmname "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Function name is variable so it can’t be fixed.(11/12/24)
    CHANGING
      e_company = gt_conowner-company.

  PERFORM get_comp_name CHANGING gt_conowner-company
                                 gt_conowner-comp_name.
ENDMODULE.                 " F4_COMPANY_CON  INPUT

*&---------------------------------------------------------------------*
*&      Module  conowner_modify  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE conowner_modify INPUT.
* If sending emails, validate owner user ID
  IF gt_conowner-ma_email = 'X'.
    SELECT SINGLE mandt INTO sy-mandt FROM usr02
                  WHERE bname = gt_conowner-owner.
    IF sy-subrc <> 0.
      MESSAGE e124(01) WITH gt_conowner-owner.
    ENDIF.
  ENDIF.

  PERFORM get_comp_name CHANGING gt_conowner-company
                                 gt_conowner-comp_name.

  READ TABLE gt_conowner INDEX tc_conowner-current_line
             TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    MODIFY gt_conowner INDEX tc_conowner-current_line.
  ELSE.
    READ TABLE gt_conowner WITH KEY owner   = gt_conowner-owner
                                  company = gt_conowner-company.
    IF sy-subrc = 0.
      MESSAGE e101(/psyng/sw).
    ENDIF.

    IF g_dflt_con_ma_email IS INITIAL.
      se_config_param 'DFLT_CON_MA_EMAIL' g_dflt_con_ma_email.
    ENDIF.

    IF g_dflt_con_ma_email = 'Y'.
      gt_conowner-ma_email = 'X'.
    ENDIF.

    APPEND gt_conowner.
  ENDIF.


ENDMODULE.                 " conowner_modify  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0904  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0904 INPUT.
  CASE sy-ucomm.
    WHEN 'CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'OWNERINSRT'.
      ADD 5 TO tc_conowner-lines.
    WHEN 'OWNERDEL'.
      DELETE gt_conowner WHERE sel = 'X'.
      IF sy-subrc <> 0.
        CLEAR : ok_code, sy-ucomm.
        MESSAGE e161(/psyng/sw).
      ENDIF.
    WHEN 'SAVE'.
      CHECK gf_dispchg = gc_change.
      LOOP AT gt_conowner.
        IF gt_conowner-owner IS INITIAL.
          CLEAR sy-ucomm.
          MESSAGE e106(/psyng/sw) WITH 'Conflict Owner'(c07).
        ENDIF.

        gt_conowner-conid = /psyng/conflict-conid.
        gt_conowner-vrsio = g_sod_vrsio.
        MODIFY gt_conowner TRANSPORTING conid vrsio.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
        EXPORTING
          wa_conflict           = /psyng/conflict
          i_vrsio               = g_sod_vrsio
        TABLES
          conowner              = gt_conowner
        EXCEPTIONS
          target_not_specified  = 1
          target_already_exists = 2
          not_authorized        = 3
          locked                = 4
          OTHERS                = 5.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'SORT_A'.
      sort_type = 'A'.
      PERFORM sort_col USING sort_type.

    WHEN 'SORT_D'.
      sort_type = 'D'.
      PERFORM sort_col USING sort_type.

  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0904  INPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_9000 INPUT.

*BOC HBHALLA 29/01/2025 ATC checks PN 11269
  CONSTANTS: lc_back(4) VALUE 'BACK',
             lc_others(6) VALUE 'OTHERS'.

  CASE sy-ucomm.
*    WHEN 'BACK' OR 'FS'.
    WHEN lc_back OR lc_fs.
      SET SCREEN 0.
      LEAVE SCREEN.
*   WHEN 'OTHERS'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
    WHEN lc_others. "#EC SAST_CI_GEN_CHECK (HBHALLA)
*      case g_fullscreen.
*        when '0222'.
*          perform user_command_0222.
*        when others.
**         not implemented for other screens.
*      endcase.
  ENDCASE.
*EOC HBHALLA 29/01/2025 ATC checks PN 11269
ENDMODULE.                 " USER_COMMAND_9000  INPUT

*&---------------------------------------------------------------------*
*&      Module  pai_0905  INPUT
*&---------------------------------------------------------------------*
*       Handle user commands for screen 905
*----------------------------------------------------------------------*
MODULE pai_0905 INPUT.
  CASE sy-ucomm.
    WHEN 'CONTINUE' OR 'NOCONTINUE'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.                 " pai_0905  INPUT
*&---------------------------------------------------------------------*
*&      Module  f4_version  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_version INPUT.
  PERFORM f4_help_version CHANGING gt_mcusrgrp-vrsio.
  gt_mccarole-vrsio = gt_mcusrgrp-vrsio.
ENDMODULE.                 " f4_version  INPUT
*&---------------------------------------------------------------------*
*&      Module  F4_AUDITIOR  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_auditior INPUT.
  PERFORM f4_help_auditor CHANGING gt_mccauser-auditor.
  gt_mccarole-auditor =  gt_mccauser-auditor.
ENDMODULE.                 " F4_AUDITIOR  INPUT
*&---------------------------------------------------------------------*
*&      Module  Owner_MODIFY  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE owner_modify INPUT.
  MODIFY g_trans_itab FROM g_trans_wa INDEX critran-current_line
         TRANSPORTING owner.
ENDMODULE.                 " Owner_MODIFY  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_owner  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_owner INPUT.

 IF g_trans_wa-owner IS NOT INITIAL. "HBHALLA
  CALL FUNCTION 'SUSR_USER_CHECK_EXISTENCE'
    EXPORTING
      user_name            = g_trans_wa-owner
    EXCEPTIONS
      user_name_not_exists = 1
      OTHERS               = 2.

  IF sy-subrc NE 0.
    MESSAGE e020(/psyng/sw) WITH g_trans_wa-owner.
    LEAVE LIST-PROCESSING.        "HBHALLA
  ENDIF.
ENDIF. "HBHALLA



ENDMODULE.                 " validate_owner  INPUT
*&---------------------------------------------------------------------*
*&      Module  valid_owner  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE valid_owner INPUT.

  CHECK NOT /psyng/swaudhdr-owner IS INITIAL.
  CALL FUNCTION 'SUSR_USER_CHECK_EXISTENCE'
    EXPORTING
      user_name            = /psyng/swaudhdr-owner
    EXCEPTIONS
      user_name_not_exists = 1
      OTHERS               = 2.

  IF sy-subrc NE 0.
    MESSAGE e020(/psyng/sw) WITH /psyng/swaudhdr-owner.
  ENDIF.

ENDMODULE.                 " valid_owner  INPUT
*&---------------------------------------------------------------------*
*&      Module  critrole_imp_modify  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE critrole_imp_modify INPUT.
  g_critrole_wa-imp = g_criroles_itab-imp.
  MODIFY g_criroles_itab FROM g_critrole_wa INDEX
 critrole-current_line
         TRANSPORTING imp.
ENDMODULE.                 " critrole_imp_modify  INPUT
*&---------------------------------------------------------------------*
*&      Module  critrole_owner_modify  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE critrole_owner_modify INPUT.
  g_critrole_wa-owner = g_criroles_itab-owner.
  MODIFY g_criroles_itab FROM g_critrole_wa
  INDEX critrole-current_line TRANSPORTING owner.
ENDMODULE.                 " critrole_owner_modify  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_role_owner  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_role_owner INPUT.

 IF g_criroles_itab-owner IS NOT INITIAL. "HBHALLA
  CALL FUNCTION 'SUSR_USER_CHECK_EXISTENCE'
    EXPORTING
      user_name            = g_criroles_itab-owner
    EXCEPTIONS
      user_name_not_exists = 1
      OTHERS               = 2.

  IF sy-subrc NE 0.
    MESSAGE e020(/psyng/sw) WITH g_criroles_itab-owner.
    LEAVE LIST-PROCESSING.    "HBHALLA
  ENDIF.
 ENDIF. "HBHALLA

ENDMODULE.                 " validate_role_owner  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0300 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK'.
      CALL METHOD go_text_edit->get_text_as_r3table
        EXPORTING
          only_when_modified     = cl_gui_textedit=>false
        IMPORTING
          table                  = gt_editor_text
          is_modified            = gf_is_modified
        EXCEPTIONS
          error_dp               = 1
          error_cntl_call_method = 2
          error_dp_create        = 3
          potential_data_loss    = 4
          OTHERS                 = 5.

      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      IF gf_is_modified = 1.
        gf_data_change = 'X'.
      ENDIF.

      CLEAR ok_code.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'CANCEL'.
      CLEAR ok_code.
      SET SCREEN 0.
      LEAVE SCREEN.

  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
*&      Module  imp_modify_p  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE imp_modify_p INPUT.
  MODIFY g_criprofs_itab INDEX critprof-current_line
TRANSPORTING imp.
ENDMODULE.                 " imp_modify_p  INPUT
*&---------------------------------------------------------------------*
*&      Module  validate_owner_p  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_owner_p INPUT.

 IF g_criprofs_itab-owner IS NOT INITIAL. "HBHALLA
  CALL FUNCTION 'SUSR_USER_CHECK_EXISTENCE'
    EXPORTING
      user_name            = g_criprofs_itab-owner
    EXCEPTIONS
      user_name_not_exists = 1
      OTHERS               = 2.

  IF sy-subrc NE 0.
    MESSAGE e020(/psyng/sw) WITH g_criprofs_itab-owner.
    LEAVE LIST-PROCESSING.        "HBHALLA
  ENDIF.
 ENDIF. "HBHALLA

ENDMODULE.                 " validate_owner_p  INPUT
*&---------------------------------------------------------------------*
*&      Module  owner_modify_p  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE owner_modify_p INPUT.
  MODIFY g_criprofs_itab INDEX critprof-current_line
         TRANSPORTING owner.
ENDMODULE.                 " owner_modify_p  INPUT
*&---------------------------------------------------------------------*
*&      Module  exit_300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_300 INPUT.
  SET SCREEN 0.
  LEAVE SCREEN.
ENDMODULE.                 " exit_300  INPUT
*&---------------------------------------------------------------------*
*&      Module  desc_modify  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE desc_modify INPUT.
*  MODIFY g_trans_itab FROM g_trans_wa INDEX critrans-current_line
*         TRANSPORTING description.
ENDMODULE.                 " desc_modify  INPUT
*&---------------------------------------------------------------------*
*&      Module  update_func  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*** For future or later use
*MODULE update_func INPUT.
*  PERFORM update_function.
*ENDMODULE.                 " update_func  INPUT
**&---------------------------------------------------------------------
**
**&      Module  update_conf  INPUT
**&---------------------------------------------------------------------
**
**       text
**----------------------------------------------------------------------
**
*MODULE update_conf INPUT.
*  PERFORM update_conflict.
*ENDMODULE.                 " update_conf  INPUT
**&---------------------------------------------------------------------
**
**&      Module  update_mith  INPUT
**&---------------------------------------------------------------------
**
**       text
**----------------------------------------------------------------------
**
*MODULE update_mith INPUT.
*  PERFORM update_mitigation.
*ENDMODULE.                 " update_mith  INPUT
**&---------------------------------------------------------------------
**
**&      Module  update_cauth  INPUT
**&---------------------------------------------------------------------
**
**       text
**----------------------------------------------------------------------
**
*MODULE update_cauth INPUT.
*  PERFORM update_critical_auth.
*ENDMODULE.                 " update_cauth  INPUT
*&---------------------------------------------------------------------*
*&      Module  busarea_modify  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE busarea_modify INPUT.
  MODIFY g_trans_itab FROM g_trans_wa INDEX critran-current_line
         TRANSPORTING busarea.
ENDMODULE.                 " busarea_modify  INPUT
*&---------------------------------------------------------------------*
*&      Module  conpmit_mark  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE conpmit_mark INPUT.
  IF gt_conpmit-sel = 'X'.
    MODIFY gt_conpmit INDEX tc_conpmit-current_line.
  ENDIF.
ENDMODULE.                 " conpmit_mark  INPUT
*&---------------------------------------------------------------------*
*&      Module  conpmit_modify  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE conpmit_modify INPUT.

*-- Validate Mitigation ID
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/mchdr
  WHERE contid = gt_conpmit-contid.
  IF sy-subrc NE 0.
    MESSAGE e002(/psyng/sw) WITH
     'Invalid Mitigation id - ' gt_conpmit-contid.
  ENDIF.



  PERFORM get_comp_name CHANGING gt_conpmit-company
                                  gt_conpmit-comp_name.
*-- Check for Duplicates
  READ TABLE gt_conpmit INDEX tc_conpmit-current_line
             TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    MODIFY gt_conpmit INDEX tc_conpmit-current_line.
  ELSE.
    READ TABLE gt_conpmit WITH KEY contid   = gt_conpmit-contid
                                   company = gt_conpmit-company.
    IF sy-subrc = 0.
      MESSAGE e101(/psyng/sw).
    ENDIF.


    APPEND gt_conpmit.
  ENDIF.

ENDMODULE.                 " conpmit_modify  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0906  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0906 INPUT.
  CASE sy-ucomm.
    WHEN 'CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'MITINSRT'.
      ADD 5 TO tc_conpmit-lines.
    WHEN 'MITDEL'.
      DELETE gt_conpmit WHERE sel = 'X'.
      IF sy-subrc <> 0.
        CLEAR : ok_code, sy-ucomm.
        MESSAGE e161(/psyng/sw).
      ENDIF.
    WHEN 'SAVE'.
      CHECK gf_dispchg = gc_change.
      LOOP AT gt_conpmit.
        IF gt_conpmit-contid IS INITIAL.
          CLEAR sy-ucomm.
          MESSAGE e106(/psyng/sw) WITH 'Conflict Mitigation'(c08).
        ELSE.
        ENDIF.

        gt_conpmit-conid = /psyng/conflict-conid.
        gt_conpmit-vrsio = g_sod_vrsio.
        MODIFY gt_conpmit TRANSPORTING conid vrsio.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
        EXPORTING
          wa_conflict           = /psyng/conflict
          i_vrsio               = g_sod_vrsio
        TABLES
          conpmit               = gt_conpmit
        EXCEPTIONS
          target_not_specified  = 1
          target_already_exists = 2
          not_authorized        = 3
          locked                = 4
          OTHERS                = 5.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'SORT_A'.
      sort_type = 'A'.
      PERFORM sort_col_mit USING sort_type.

    WHEN 'SORT_D'.
      sort_type = 'D'.
      PERFORM sort_col_mit USING sort_type.

  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0906  INPUT
*&---------------------------------------------------------------------*
*&      Module  f4_company_con_mit  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_company_con_mit INPUT.
*--Check what FM is configured for search help for Company
  se_config_param 'SW_COMPANY_SHLP_FM' ls_fmname.
  IF NOT ls_fmname IS INITIAL.
    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = ls_fmname
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
*--Configured Fm does not exist, use default
      MESSAGE s113(/psyng/sw) WITH
      'Cannot determine SW_COMPANY_SHLP_FM with FM '
      ls_fmname '. FM doesn''t exist'.
    ENDIF.
  ELSE.
    ls_fmname = '/PSYNG/SW_074'.
  ENDIF.


  CALL FUNCTION ls_fmname "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Function name is variable so it can’t be fixed.(11/12/24)
    CHANGING
      e_company = gt_conpmit-company.

  PERFORM get_comp_name CHANGING gt_conpmit-company
                                 gt_conpmit-comp_name.

ENDMODULE.                 " f4_company_con_mit  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0907  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0907 INPUT.
  CASE sy-ucomm.
    WHEN 'CONTINUE' OR 'NOCONTINUE'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0907  INPUT
*&---------------------------------------------------------------------*
*&      Module  f4_tcode  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_tcode INPUT.
  PERFORM f4_help_tcode CHANGING g_trans_itab-tcode.
ENDMODULE.                 " f4_tcode  INPUT
*&---------------------------------------------------------------------*
*&      Module  f4_owner  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_owner INPUT.
  PERFORM f4_help_owner CHANGING g_trans_itab-owner.
ENDMODULE.                 " f4_owner  INPUT
*&---------------------------------------------------------------------*
*&      Module  f4_imp  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_imp INPUT.
  PERFORM f4_help_imp CHANGING g_trans_itab-imp.
ENDMODULE.                 " f4_imp  INPUT
*&---------------------------------------------------------------------*
*&      Module  f4_busarea  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_busarea INPUT.
  PERFORM f4_help_busarea CHANGING g_trans_itab-busarea.
ENDMODULE.                 " f4_busarea  INPUT
*&---------------------------------------------------------------------*
*&      Module  f4_agr_name  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_agr_name INPUT.
  PERFORM f4_help_agr_name CHANGING g_criroles_itab-agr_name.
ENDMODULE.                 " f4_agr_name  INPUT
*&---------------------------------------------------------------------*
*&      Module  f4_profn  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_profn INPUT.
  PERFORM f4_help_profn CHANGING g_criprofs_itab-profn.
ENDMODULE.                 " f4_profn  INPUT

*---------------------------------------------------------------------*
*       MODULE user_command_0908 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0908 INPUT.

*BOC HBHALLA 14/01/2025 ATC checks PN 11269
CONSTANTS: lc_exit(4) VALUE 'EXIT',
           lc_save(4) VALUE 'SAVE',
           lc_disp(10) VALUE 'DISPCHANGE'.

  CASE sy-ucomm.
*    WHEN 'EXIT'.
    WHEN lc_exit.
      SET SCREEN 0.
      LEAVE SCREEN.
*    WHEN 'SAVE'. "#EC SAST_CI_GEN_CHECK
    WHEN lc_save. "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (06/12/24)
      PERFORM save_syscon_data.
*    WHEN 'DISPCHANGE'.
    WHEN lc_disp.
      IF gf_dispchg1 = gc_display.      "Change mode to CHANGE
        gf_dispchg1 = gc_change.
      ELSE.                            "Change mode to DISPLAY
        gf_dispchg1 = gc_display.
        PERFORM get_syscon_existing_data.
      ENDIF.
      PERFORM display_confltr_alv.
  ENDCASE.
*EOC HBHALLA 14/01/2025 ATC checks PN 11269
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE user_command_0909 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0909 INPUT.

  CASE sy-ucomm.
*    WHEN 'EXIT'.
    WHEN lc_exit.
      SET SCREEN 0.
      LEAVE SCREEN.
*    WHEN 'SAVE'.
    WHEN lc_save.
      PERFORM save_sysfun_data.

*    WHEN 'DISPCHANGE'. "#EC SAST_CI_GEN_CHECK
    WHEN lc_disp. "#EC SAST_CI_GEN_CHECK
      IF gf_dispchg1 = gc_display.      "Change mode to CHANGE
        gf_dispchg1 = gc_change.
      ELSE.                            "Change mode to DISPLAY
        gf_dispchg1 = gc_display.
        PERFORM get_sysfun_existing_data.
      ENDIF.
      PERFORM display_funfltr_alv.
  ENDCASE.
*EOC HBHALLA 14/01/2025 ATC checks PN 11269
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE user_command_0910 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0910 INPUT.
  CASE sy-ucomm.
*    WHEN 'EXIT'.
    WHEN lc_exit.
      SET SCREEN 0.
      LEAVE SCREEN.
*    WHEN 'SAVE'.
    WHEN lc_save.
      PERFORM save_sysca_data.
*    WHEN 'DISPCHANGE'. "#EC SAST_CI_GEN_CHECK
    WHEN lc_disp. "#EC SAST_CI_GEN_CHECK
      IF gf_dispchg1 = gc_display.      "Change mode to CHANGE
        gf_dispchg1 = gc_change.
      ELSE.                            "Change mode to DISPLAY
        gf_dispchg1 = gc_display.
        PERFORM get_sysca_existing_data.
      ENDIF.
      PERFORM display_cafltr_alv.
  ENDCASE.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE user_command_0911 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0911 INPUT.

  CASE sy-ucomm.
*    WHEN 'EXIT'.
    WHEN lc_exit.
      SET SCREEN 0.
      LEAVE SCREEN.
*    WHEN 'SAVE'.
    WHEN lc_save.
      PERFORM save_systcd_data.
*    WHEN 'DISPCHANGE'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
    WHEN lc_disp. "#EC SAST_CI_GEN_CHECK (HBHALLA)
      IF gf_dispchg1 = gc_display.      "Change mode to CHANGE
        gf_dispchg1 = gc_change.
      ELSE.                            "Change mode to DISPLAY
        gf_dispchg1 = gc_display.
        PERFORM get_systcd_existing_data.
      ENDIF.
      PERFORM display_tcdfltr_alv.
  ENDCASE.
*EOC HBHALLA 14/01/2025 ATC checks PN 11269
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE mc_active_tab_set INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE mc_active_tab_set INPUT.
  CASE sy-ucomm.
    WHEN c_tc_md-tab1.
      g_tc_md-pressed_tab = c_tc_md-tab1.
    WHEN c_tc_md-tab2.
      g_tc_md-pressed_tab = c_tc_md-tab2.
  ENDCASE.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE USER_COMMAND_0226 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0226 INPUT.
  CASE sy-ucomm.
    WHEN 'EDIT_MIT_TXT'.
      REFRESH gt_tline.
      gt_tline-tdline = 'Mitigation Review Text'(m13).
      APPEND gt_tline.
      PERFORM edit_text USING /psyng/mcrvwhdr-dflt_review lang.
  ENDCASE.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE user_command_0227 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0227 INPUT.
*  CASE sy-ucomm.
*  ENDCASE.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE user_command_0228 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0228 INPUT.
  CASE sy-ucomm.
    WHEN 'EXIT' OR 'BACK' OR 'CANCEL'.
      LEAVE TO SCREEN 228.
    WHEN 'MIT_REPORT'.
      SUBMIT /psyng/sw_132
      WITH s_sod = g_sod_vrsio
      VIA SELECTION-SCREEN AND RETURN.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  CHECK_TRANS_208  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_trans_208 INPUT.
  IF mark_col = 'X'.
    g_trans_itab-flag = 'X'.
    MODIFY g_trans_itab INDEX critran-current_line TRANSPORTING flag.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  TRANS_MODIFY_208  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE trans_modify_208 INPUT.

  IF tstct-tcode IS INITIAL   AND ok_code NE 'DELL'.
    DELETE g_trans_itab INDEX critran-current_line.
    DESCRIBE TABLE g_trans_itab LINES critran-lines.
    EXIT.
  ENDIF.

* Mark entry for deletion without validations
  IF ok_code = 'DELL'.
    g_trans_itab-tcode = tstct-tcode.
    g_trans_itab-flag = 'X'.
    MODIFY g_trans_itab
    INDEX critran-current_line
    TRANSPORTING tcode flag.
*TRANSPORTING flag WHERE tcode = tstct-tcode.
    IF sy-subrc <> 0.
      APPEND g_trans_itab.
      IF gf_dispchg = gc_change.
        gf_data_change = gc_select.
      ENDIF.
    ENDIF.
    EXIT.
  ENDIF.

  CLEAR g_trans_itab.
  MOVE-CORRESPONDING tstct TO g_trans_wa.

  g_trans_itab-tcode = tstct-tcode.
*  g_trans_itab-imp   = g_trans_itab-imp.
*  g_trans_itab-owner = g_trans_itab-owner.
*  g_trans_itab-description = g_trans_itab-description.

  CLEAR g_trans_itab-ttext.
  SELECT SINGLE ttext INTO g_trans_itab-ttext FROM tstct
  WHERE tcode = tstct-tcode
  AND sprsl = sy-langu.
  IF sy-subrc <> 0.
*--TCOde does not exist in this system
    IF tstct-tcode  CP
        /psyng/sw_cl_constants=>placeholder_tcode_prefix.
      g_trans_itab-ttext =
      'Placeholder for object level analysis'(191).
    ELSE.
      g_trans_itab-ttext =
      'Tcode for cross system analysis'(192).
    ENDIF.
  ENDIF.

* Check for existing entry
*BOC: HBHALLA
IF gt_trans_bckup[] IS INITIAL.
  LOOP AT g_trans_itab WHERE tcode = g_trans_itab-tcode.
    IF sy-tabix <> critran-current_line.
      CLEAR : ok_code, sy-ucomm.
      MESSAGE e101(/psyng/sw).
    ENDIF.
  ENDLOOP.
ELSE.
  READ TABLE gt_trans_bckup WITH KEY tcode = g_trans_itab-tcode.
    IF sy-subrc = 0.
      CLEAR : ok_code, sy-ucomm,g_trans_wa.
      LOOP AT SCREEN.
        IF SCREEN-NAME EQ 'TSTCT-TCODE'.
          CLEAR: TSTCT-TCODE.
        ENDIF.
      ENDLOOP.
      MESSAGE e099(/psyng/sw) WITH g_trans_itab-tcode.
    ENDIF.
ENDIF.
*End Of Change: HBHALLA

  MODIFY g_trans_itab INDEX critran-current_line.
  IF sy-subrc <> 0.
    APPEND g_trans_itab.
  ENDIF.

*BOC: HBHALLA
 IF gt_trans_bckup[] IS NOT INITIAL.
    APPEND g_trans_itab TO gt_trans_bckup[].
 ENDIF.
*END OF CHANGE: HBHALLA
*===========================================================
* Add new function module here
  IF ok_code = 'ENTER'.
    PERFORM get_parameter.
  ENDIF.
*===========================================================
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  VALIDATE_BUS_AREA  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_bus_area INPUT.
DATA  lv_busarea TYPE   /PSYNG/BUS_AREA.

IF g_trans_wa-busarea IS NOT INITIAL.
CLEAR  lv_busarea.
SELECT SINGLE  busarea FROM /PSYNG/BUSAREA INTO lv_busarea
  WHERE busarea = g_trans_wa-busarea.
IF sy-subrc NE 0.
  MESSAGE e020(/psyng/sw) WITH
*BOC UMITTAL PN-17849 05/03/2026
  'App Area:'(249)
*EOC UMITTAL PN-17849 05/03/2026
  g_trans_wa-busarea.
  LEAVE LIST-PROCESSING.
ENDIF.
ENDIF.

ENDMODULE.
