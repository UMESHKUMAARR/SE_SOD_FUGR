*----------------------------------------------------------------------*
* Report  /PSYNG/SW_107F01                                             *
* AUTHOR: Security Weaver, LLC                                         *
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  get_from_database
*&---------------------------------------------------------------------*
*       Get configuration from database
*----------------------------------------------------------------------*
FORM get_from_database.
 DATA : lt_config TYPE TABLE OF /psyng/se_config_param WITH HEADER LINE.
  REFRESH : gt_config.
  CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
       EXPORTING
            IF_INFO   = 'X'
       TABLES
            et_config = lt_config.
  LOOP AT lt_config.
    MOVE-CORRESPONDING lt_config TO gt_config.
    gt_config-sw = lt_config-maintained.
    APPEND gt_config.
  ENDLOOP.


ENDFORM.                    " get_from_database

*&---------------------------------------------------------------------*
*&      Form  toggle_display_change
*&---------------------------------------------------------------------*
*       Toggle screen fields between display and change modes
*----------------------------------------------------------------------*
FORM toggle_display_change.
  IF gf_dispchg = gc_display.                    "Display
    LOOP AT SCREEN.
      CHECK screen-group1 = '001' AND screen-input = 1.
      screen-input = 0.
      MODIFY SCREEN.
    ENDLOOP.
  ELSE.                                          "Change
    LOOP AT SCREEN.
      IF screen-group1 = '001' AND screen-input = 0.
        screen-input = 1.
        MODIFY SCREEN.
*changes vk 4/10/18 SE 3.5
*make custom parameters editable only for insert
      ELSEIF screen-group1 = '002' AND gt_config-sw IS INITIAL AND
                    gf_insert = 'X' AND gt_config-param IS INITIAL.
        screen-input = 1.
        MODIFY SCREEN.
*End of changes
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " toggle_display_change

*----------------------------------------------------------------------*
*   INCLUDE TABLECONTROL_FORMS                                         *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  FCODE_INSERT_ROW                                         *
*&---------------------------------------------------------------------*
FORM fcode_insert_row
              USING    p_tc_name           TYPE dynfnam
                       p_table_name             .

*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA l_lines_name       LIKE feld-name.
  DATA l_selline          LIKE sy-stepl.
  DATA l_line             TYPE i.
  DATA l_table_name       LIKE feld-name.
  FIELD-SYMBOLS <tc>                 TYPE cxtab_control.
  FIELD-SYMBOLS <table>              TYPE STANDARD TABLE.
  FIELD-SYMBOLS <lines>              TYPE i.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

* get the table, which belongs to the tc                               *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

"not headerline

* get looplines of TableControl
  CONCATENATE 'G_' p_tc_name '_LINES' INTO l_lines_name.
  ASSIGN (l_lines_name) TO <lines>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

* get current line
  GET CURSOR LINE l_selline.
  IF sy-subrc <> 0.                   " append line to table
    l_selline = <tc>-lines + 1.
*&SPWIZARD: set top line and new cursor line                           *
    IF l_selline > <lines>.
      <tc>-top_line = l_selline - <lines> + 1 .
    ELSE.
      <tc>-top_line = 1.
    ENDIF.
  ELSE.                               " insert line into table
    l_selline = <tc>-top_line + l_selline - 1.
  ENDIF.
*&SPWIZARD: set new cursor line                                        *
  l_line = l_selline - <tc>-top_line + 1.
* insert initial line
  INSERT INITIAL LINE INTO <table> INDEX l_selline.
  <tc>-lines = <tc>-lines + 1.
* set cursor
  g_curs_line = l_line.
ENDFORM.                              " FCODE_INSERT_ROW

*&---------------------------------------------------------------------*
*&      Form  FCODE_DELETE_ROW                                         *
*&---------------------------------------------------------------------*
FORM fcode_delete_row
              USING    p_tc_name           TYPE dynfnam
                       p_table_name.

*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA: l_table_name       LIKE feld-name,
        l_index            TYPE i.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <cfg>        LIKE LINE OF gt_config.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

* get the table, which belongs to the tc                               *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

"not headerline

* delete marked lines                                                  *
  DESCRIBE TABLE <table> LINES <tc>-lines.

  LOOP AT <table> ASSIGNING <cfg>.
    IF <cfg>-sel = 'X'.
*     Only clear values if it is an SW defined parameter
      IF <cfg>-sw = 'X'.
*vk 4/10/18 add message on deletion on SW parameters
        MESSAGE i002 WITH 'Only Custom Parameters Can be Deleted'(014).
*End of changes
        CLEAR: <cfg>-value, <cfg>-newval.
      ELSE.
        l_index = sy-tabix.
        APPEND <cfg> TO gt_delete.
        DELETE <table> INDEX l_index.
        IF sy-subrc = 0.
          <tc>-lines = <tc>-lines - 1.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                              " FCODE_DELETE_ROW

*&---------------------------------------------------------------------*
*&      Form  COMPUTE_SCROLLING_IN_TC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*      -->P_OK       ok code
*----------------------------------------------------------------------*
FORM compute_scrolling_in_tc USING    p_tc_name
                                      p_ok.
*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA l_tc_new_top_line     TYPE i.
  DATA l_tc_name             LIKE feld-name.
  DATA l_tc_lines_name       LIKE feld-name.
  DATA l_tc_field_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <lines>      TYPE i.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
* get looplines of TableControl
  CONCATENATE 'G_' p_tc_name '_LINES' INTO l_tc_lines_name.
  ASSIGN (l_tc_lines_name) TO <lines>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

* is no line filled?                                                   *
  IF <tc>-lines = 0.
*   yes, ...                                                           *
    l_tc_new_top_line = 1.
  ELSE.
*   no, ...                                                            *
    CALL FUNCTION 'SCROLLING_IN_TABLE'
         EXPORTING
              entry_act             = <tc>-top_line
              entry_from            = 1
              entry_to              = <tc>-lines
              last_page_full        = 'X'
              loops                 = <lines>
              ok_code               = p_ok
              overlapping           = 'X'
         IMPORTING
              entry_new             = l_tc_new_top_line
         EXCEPTIONS
             NO_ENTRY_OR_PAGE_ACT  = 1
             NO_ENTRY_TO           = 2
             NO_OK_CODE_OR_PAGE_GO = 3
              OTHERS               = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  ENDIF.

* get actual tc and column                                             *
  GET CURSOR FIELD l_tc_field_name
             AREA  l_tc_name.

  IF syst-subrc = 0.
    IF l_tc_name = p_tc_name.
*     set actual column                                                *
      SET CURSOR FIELD l_tc_field_name LINE 1.
    ENDIF.
  ENDIF.

* set the new top line                                                 *
  <tc>-top_line = l_tc_new_top_line.
ENDFORM.                              " COMPUTE_SCROLLING_IN_TC

*&---------------------------------------------------------------------*
*&      Form  revert_single
*&---------------------------------------------------------------------*
*       Revert a single record to SW default
*----------------------------------------------------------------------*
FORM revert_single.
  DATA: l_line      LIKE sy-linno,
        l_answer(1) TYPE c,
        l_objid        type cdhdr-objectid,
        ls_config      TYPE /psyng/swconfig,
        ls_config_orig TYPE /psyng/swconfig,
        ls_config_dum  TYPE /psyng/swconfig,
        ls_SWINVISBL   TYPE /PSYNG/SWINVISBL,
        lt_ICDTXT_SECONFIG
                       type table of CDTXT.


  CALL FUNCTION 'POPUP_TO_CONFIRM'
       EXPORTING
            titlebar              = 'Confirm'(001)
            text_question         =
  'Do you want to replace the current value with SW default value?'(q01)
            text_button_1         = 'Yes'(002)
            icon_button_1         = 'ICON_OKAY'
            text_button_2         = 'No'(003)
            icon_button_2         = 'ICON_CANCEL'
            default_button        = '2'
            display_cancel_button = 'X'
       IMPORTING
            answer                = l_answer
       EXCEPTIONS
            text_not_found        = 1
            OTHERS                = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CHECK l_answer EQ '1'.

  GET CURSOR LINE l_line.

  l_line = l_line + tc_config-top_line - 1.
  CLEAR gt_config.
  READ TABLE gt_config INDEX l_line.

  CHECK gt_config-value <> gt_config-default.
  move-corresponding gt_config to ls_config_orig.
  gt_config-value = gt_config-default.
  MODIFY gt_config INDEX l_line TRANSPORTING value.

  UPDATE /psyng/swconfig SET value = gt_config-value
                         WHERE param = gt_config-param.

*--Create Change Document
      move-corresponding gt_config to ls_config.
      l_objid = gt_config-param.

    CALL FUNCTION '/PSYNG/SECONFIG_WRITE_DOCUMENT'
    EXPORTING
         objectid                      = l_objid
         tcode                         = '/PSYNG/SW'
         utime                         = sy-uzeit
         udate                         = sy-datum
         username                      = g_current_user"sy-uname C0700
         PLANNED_CHANGE_NUMBER         = ' '
         OBJECT_CHANGE_INDICATOR       = 'U'
         PLANNED_OR_REAL_CHANGES       = 'R'
         NO_CHANGE_POINTERS            = ' '
         O_PSYNG_SWCONFIG              = ls_config_orig
         N_PSYNG_SWCONFIG              = ls_config
         UPD_PSYNG_SWCONFIG            = 'U'
         UPD_PSYNG_SWINVISBL           = ''
         N_PSYNG_SWINVISBL             = ls_SWINVISBL
         O_PSYNG_SWINVISBL             = ls_SWINVISBL
      TABLES
         ICDTXT_SECONFIG                = lt_ICDTXT_SECONFIG.


  COMMIT WORK.
  MESSAGE s120.
ENDFORM.                    " revert_single

*&---------------------------------------------------------------------*
*&      Form  revert_all
*&---------------------------------------------------------------------*
*       Revert all records to SW defaults
*----------------------------------------------------------------------*
FORM revert_all.
  DATA: l_answer(1) TYPE c,
        l_objid        type cdhdr-objectid,
        ls_config      TYPE /psyng/swconfig,
        ls_config_orig TYPE /psyng/swconfig,
        ls_config_dum  TYPE /psyng/swconfig,
        ls_SWINVISBL   TYPE /PSYNG/SWINVISBL,
        lt_ICDTXT_SECONFIG
                       type table of CDTXT.


  CALL FUNCTION 'POPUP_TO_CONFIRM'
       EXPORTING
            titlebar              = 'Confirm'(001)
            text_question         = text-q02
            text_button_1         = 'Yes'(002)
            icon_button_1         = 'ICON_OKAY'
            text_button_2         = 'No'(003)
            icon_button_2         = 'ICON_CANCEL'
            default_button        = '2'
            display_cancel_button = 'X'
       IMPORTING
            answer                = l_answer
       EXCEPTIONS
            text_not_found        = 1
            OTHERS                = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CHECK l_answer EQ '1'.

  LOOP AT gt_config.
    CHECK gt_config-value <> gt_config-default.
    move-corresponding gt_config to ls_config_orig.
    gt_config-value = gt_config-default.
    MODIFY gt_config TRANSPORTING value.

    UPDATE /psyng/swconfig                          "#EC CI_IMUD_NESTED
         SET value = gt_config-value
                           WHERE param = gt_config-param.

      move-corresponding gt_config to ls_config.
      l_objid = gt_config-param.
      CALL FUNCTION '/PSYNG/SECONFIG_WRITE_DOCUMENT'
      EXPORTING
           objectid                      = l_objid
           tcode                         = '/PSYNG/SW'
           utime                         = sy-uzeit
           udate                         = sy-datum
           username                      = g_current_user"sy-uname C0700
           PLANNED_CHANGE_NUMBER         = ' '
           OBJECT_CHANGE_INDICATOR       = 'U'
           PLANNED_OR_REAL_CHANGES       = 'R'
           NO_CHANGE_POINTERS            = ' '
           O_PSYNG_SWCONFIG              = ls_config_orig
           N_PSYNG_SWCONFIG              = ls_config
           UPD_PSYNG_SWCONFIG            = 'U'
           UPD_PSYNG_SWINVISBL           = ''
           N_PSYNG_SWINVISBL             = ls_SWINVISBL
           O_PSYNG_SWINVISBL             = ls_SWINVISBL
        TABLES
           ICDTXT_SECONFIG                = lt_ICDTXT_SECONFIG.

  COMMIT WORK.
  ENDLOOP.
  MESSAGE s120.
ENDFORM.                    " revert_all

*&---------------------------------------------------------------------*
*&      Form  save_cfg
*&---------------------------------------------------------------------*
*       Save configuration
*----------------------------------------------------------------------*
FORM save_cfg.
  DATA: ls_config      TYPE /psyng/swconfig,
        ls_config_orig TYPE /psyng/swconfig,
        ls_config_dum  TYPE /psyng/swconfig,
        l_mandt        type sy-mandt,
        l_objid        type cdhdr-objectid,
        lt_ICDTXT_SECONFIG         type table of CDTXT ,
        lf_change      type flag,
        ls_SWINVISBL   TYPE /PSYNG/SWINVISBL.


  LOOP AT gt_delete INTO gs_config.
    READ TABLE gt_config WITH KEY param = gs_config-param.
    CHECK sy-subrc <> 0.

    DELETE FROM /psyng/swconfig                     "#EC CI_IMUD_NESTED
         WHERE param = gs_config-param.
*--Create Change Document
      move-corresponding gs_config to ls_config.
      l_objid = gs_config-param.
    CALL FUNCTION '/PSYNG/SECONFIG_WRITE_DOCUMENT'
      EXPORTING
            objectid                      = l_objid
            tcode                         = '/PSYNG/SW'
            utime                         = sy-uzeit
            udate                         = sy-datum
            username                      = g_current_user"sy-unameC0700
            PLANNED_CHANGE_NUMBER         = ' '
            OBJECT_CHANGE_INDICATOR       = 'D'
            PLANNED_OR_REAL_CHANGES       = 'R'
            NO_CHANGE_POINTERS            = ' '
            O_PSYNG_SWCONFIG              = ls_config
            N_PSYNG_SWCONFIG              = ls_config_dum
            UPD_PSYNG_SWCONFIG            = 'D'
            UPD_PSYNG_SWINVISBL           = ''
            N_PSYNG_SWINVISBL             = ls_SWINVISBL
            O_PSYNG_SWINVISBL             = ls_SWINVISBL
      TABLES
            ICDTXT_SECONFIG               = lt_ICDTXT_SECONFIG.
  ENDLOOP.

  REFRESH gt_delete.

  LOOP AT gt_config.
    clear lf_change.
    l_objid = gt_config-param.
*   Check if non-SW parameters already exist
    IF gt_config-sw IS INITIAL.
      SELECT SINGLE mandt INTO l_mandt              "#EC CI_SEL_NESTED
        FROM /psyng/swconfig
                    WHERE param = gt_config-param.
      IF sy-subrc <> 0.
        move-corresponding gt_config to ls_config_orig.
        gt_config-value = gt_config-newval.
        CLEAR gt_config-newval.
        MODIFY gt_config TRANSPORTING value newval.
        MOVE-CORRESPONDING gt_config TO ls_config.
        INSERT INTO /psyng/swconfig                 "#EC CI_IMUD_NESTED
          VALUES ls_config.
*--Change Document for Insert
        CALL FUNCTION '/PSYNG/SECONFIG_WRITE_DOCUMENT'
        EXPORTING
             objectid                      = l_objid
             tcode                         = '/PSYNG/SW'
             utime                         = sy-uzeit
             udate                         = sy-datum
             username                      = g_current_user"sy-unameC700
             PLANNED_CHANGE_NUMBER         = ' '
             OBJECT_CHANGE_INDICATOR       = 'I'
             PLANNED_OR_REAL_CHANGES       = 'R'
             NO_CHANGE_POINTERS            = ' '
             O_PSYNG_SWCONFIG              = ls_config_orig
             N_PSYNG_SWCONFIG              = ls_config
             UPD_PSYNG_SWCONFIG            = 'I'
             UPD_PSYNG_SWINVISBL           = ''
             N_PSYNG_SWINVISBL             = ls_SWINVISBL
             O_PSYNG_SWINVISBL             = ls_SWINVISBL

      TABLES
            ICDTXT_SECONFIG                = lt_ICDTXT_SECONFIG.

      ENDIF.
    ENDIF.
    IF NOT gt_config-newval IS INITIAL.
      lf_change = 'X'.
      move-corresponding gt_config to ls_config_orig.
      gt_config-value = gt_config-newval.
      CLEAR gt_config-newval.
      MODIFY gt_config TRANSPORTING value newval.
    ENDIF.
    MOVE-CORRESPONDING gt_config TO ls_config.
    MODIFY /psyng/swconfig FROM ls_config.
*--Change Document for Update
    if lf_change = 'X' and ls_config_orig <> ls_config.
    CALL FUNCTION '/PSYNG/SECONFIG_WRITE_DOCUMENT'
    EXPORTING
         objectid                      = l_objid
         tcode                         = '/PSYNG/SW'
         utime                         = sy-uzeit
         udate                         = sy-datum
         username                      = g_current_user"sy-uname C0700
         PLANNED_CHANGE_NUMBER         = ' '
         OBJECT_CHANGE_INDICATOR       = 'U'
         PLANNED_OR_REAL_CHANGES       = 'R'
         NO_CHANGE_POINTERS            = ' '
         O_PSYNG_SWCONFIG              = ls_config_orig
         N_PSYNG_SWCONFIG              = ls_config
         UPD_PSYNG_SWCONFIG            = 'U'
         UPD_PSYNG_SWINVISBL           = ''
         N_PSYNG_SWINVISBL             = ls_SWINVISBL
         O_PSYNG_SWINVISBL             = ls_SWINVISBL
      TABLES
            ICDTXT_SECONFIG                = lt_ICDTXT_SECONFIG.
    endif.

  ENDLOOP.
  COMMIT WORK.
  PERFORM get_from_database.
  MESSAGE s120.
ENDFORM.                    " save_cfg

*&---------------------------------------------------------------------*
*&      Form  show_info
*&---------------------------------------------------------------------*
*       Show informational message to describe parameter
*----------------------------------------------------------------------*
FORM show_info.
  DATA: l_line LIKE sy-linno.

  GET CURSOR LINE l_line.
  l_line = l_line + tc_config-top_line - 1.
  READ TABLE gt_config INDEX l_line.
  IF NOT gt_config-info_msg IS INITIAL AND gt_config-info_msg > ''.
    MESSAGE ID '/PSYNG/SW_INF' TYPE 'I' NUMBER gt_config-info_msg.
  ELSE.
    MESSAGE i020 WITH 'Information about this parameter'(000).
  ENDIF.
ENDFORM.                    " show_info

*&---------------------------------------------------------------------*
*&      Form  display_change
*&---------------------------------------------------------------------*
*       Toggle display / change mode
*----------------------------------------------------------------------*
FORM display_change.
  IF gf_dispchg = gc_display.
    AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
             ID 'DICBERCLS' FIELD 'Y&S2'
             ID 'ACTVT' FIELD '02'.
    IF sy-subrc <> 0.
      MESSAGE e108 WITH 'Change'(005) 'Configuration'(006).
    ENDIF.

      gf_dispchg = gc_change.
  ELSE.
    AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
             ID 'DICBERCLS' FIELD 'Y&S2'
             ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      MESSAGE e108 WITH 'Display'(004) 'Configuration'(006).
    ENDIF.
    gf_dispchg = gc_display.
  ENDIF.

  PERFORM get_from_database.
  PERFORM get_texts.
ENDFORM.                    " display_change

*&---------------------------------------------------------------------*
*&      Form  get_texts
*&---------------------------------------------------------------------*
*       Get information for texts
*----------------------------------------------------------------------*
FORM get_texts.
* Mitigation assignment email
  READ TABLE gt_config WITH KEY param = 'SW_MIT_ASG_NOTIF_OID'.

  IF sy-subrc = 0.
    IF NOT gt_config-value IS INITIAL.
    g_txt_mit_assgn = gt_config-value.
    ELSE.
    g_txt_mit_assgn = gt_config-default.
    ENDIF.
    PERFORM get_txt_lang USING g_txt_mit_assgn
                         CHANGING g_lang_mit_assgn
                                  g_msg_mit_assgn.
  ENDIF.

* Mitigation reminder email
  READ TABLE gt_config WITH KEY param = 'SW_MIT_REMIND_EMAIL'.

  IF sy-subrc = 0.
    IF NOT gt_config-value IS INITIAL.
    g_txt_mit_remind = gt_config-value.
    ELSE.
    g_txt_mit_remind = gt_config-default.
    ENDIF.

    PERFORM get_txt_lang USING g_txt_mit_remind
                         CHANGING g_lang_mit_remind
                                  g_msg_mit_remind.
  ENDIF.

*BOC C1159 CGUPTA 20/09/2023

* Mitigation expiration email
  READ TABLE gt_config WITH KEY param = 'SW_MIT_EXPIRE_EMAIL'.

  IF sy-subrc = 0.
    IF NOT gt_config-value IS INITIAL.
    g_txt_mit_notify = gt_config-value.
    ELSE.
    g_txt_mit_notify = gt_config-default.
    ENDIF.

    PERFORM get_txt_lang USING g_txt_mit_notify
                         CHANGING g_lang_mit_notify
                                  g_msg_mit_notify.
  ENDIF.
*EOC C1159 CGUPTA 20/09/2023



* Mitigation URL
  READ TABLE gt_config WITH KEY param = 'MIT_ATTACH_URL'.

  IF sy-subrc = 0.
    IF NOT gt_config-value IS INITIAL.
    g_txt_mit_url = gt_config-value.
    ELSE.
    g_txt_mit_url = gt_config-default.
    ENDIF.

    PERFORM get_txt_lang USING g_txt_mit_url
                         CHANGING g_lang_mit_url
                                  g_msg_mit_url.

  ENDIF.

* User Inactivity Email

  READ TABLE gt_config WITH KEY param = 'SW_USR_INACTIV_EMAIL'.

  IF sy-subrc = 0.
    IF NOT gt_config-value IS INITIAL.
    g_txt_usr_inact = gt_config-value.
    ELSE.
    g_txt_usr_inact = gt_config-default.
    ENDIF.
    PERFORM get_txt_lang USING g_txt_usr_inact
                         CHANGING g_lang_usr_inact
                                  g_msg_usr_inact.


  ENDIF.
* Mitigation Signoff Email
  READ TABLE gt_config WITH KEY param = 'SW_MIT_SIGNOFF_EMAIL'.

  IF sy-subrc = 0.
    IF NOT gt_config-value IS INITIAL.
    g_txt_mit_soff = gt_config-value.
    ELSE.
    g_txt_mit_soff = gt_config-default.
    ENDIF.

    PERFORM get_txt_lang USING g_txt_mit_soff
                         CHANGING g_lang_mit_soff
                                  g_msg_mit_soff.
  ENDIF.


* Configuration Set Comparison E-Mail
  READ TABLE gt_config WITH KEY param = 'CFGGSET_COMP_EMAIL'.

  IF sy-subrc = 0.
    IF NOT gt_config-value IS INITIAL.
    g_txt_cnf_comp = gt_config-value.
    ELSE.
    g_txt_cnf_comp = gt_config-default.
    ENDIF.

    PERFORM get_txt_lang USING g_txt_cnf_comp
                         CHANGING g_lang_cnf_comp
                                  g_msg_cnf_comp.
  ENDIF.


ENDFORM.                    " get_texts

*&---------------------------------------------------------------------*
*&      Form  get_txt_lang
*&---------------------------------------------------------------------*
*       Get all languages for a text
*----------------------------------------------------------------------*
*      -->I_TXT_NAME  Text name
*      <--E_TXT_MSG   Message for text languages
*----------------------------------------------------------------------*
FORM get_txt_lang USING    i_txt_name LIKE /psyng/swconfig-value
                  CHANGING e_txt_lang
                           e_txt_msg.
  DATA: BEGIN OF lt_txt_lang OCCURS 0,
          spras LIKE stxh-tdspras,
        END OF lt_txt_lang.

  DATA: l_full_lang(2) TYPE c,
        l_cnt_txt(3)   TYPE c.


  CLEAR: e_txt_lang, e_txt_msg.

* Determine all languages for text name
  SELECT DISTINCT tdspras FROM stxh
         INTO TABLE lt_txt_lang
         WHERE tdname   = i_txt_name
           AND tdid     = 'ST'
           AND tdobject = 'TEXT'.
  IF sy-subrc <> 0.
    CLEAR e_txt_lang.
    MESSAGE i020 WITH '@8R@' i_txt_name INTO e_txt_msg.
    EXIT.
  ENDIF.

  READ TABLE lt_txt_lang WITH KEY spras = sy-langu.
  IF sy-subrc = 0.
    DELETE lt_txt_lang INDEX sy-tabix.
    INSERT lt_txt_lang INDEX 1.
  ENDIF.

*Start of BOC: HBHALLA.
*  SORT lt_txt_lang BY spras.
*End of Change.

  LOOP AT lt_txt_lang FROM 0 TO 3.
    CALL FUNCTION 'CONVERSION_EXIT_ISOLA_OUTPUT'
         EXPORTING
              input  = lt_txt_lang-spras
         IMPORTING
              output = l_full_lang.

    IF sy-tabix = 1.
      e_txt_lang = l_full_lang.

      CONCATENATE 'Text name exists for languages:'(007) l_full_lang
                  INTO e_txt_msg.
    ELSE.
      CONCATENATE e_txt_msg l_full_lang INTO e_txt_msg SEPARATED BY ','.
    ENDIF.
  ENDLOOP.

  DESCRIBE TABLE lt_txt_lang LINES sy-tfill.
  SUBTRACT 3 FROM sy-tfill.

  IF sy-tfill > 0.
    l_cnt_txt = sy-tfill.
    CONDENSE l_cnt_txt.
    CONCATENATE e_txt_msg 'and'(008) l_cnt_txt 'others'(009)
                INTO e_txt_msg SEPARATED BY space.
  ENDIF.
ENDFORM.                    " get_txt_lang

*&---------------------------------------------------------------------*
*&      Form  edit_text
*&---------------------------------------------------------------------*
*       Edit text in SO10
*----------------------------------------------------------------------*
*      -->I_TXT_NAME  Text name
*      -->I_LANG      Text language
*----------------------------------------------------------------------*
FORM edit_text USING    i_txt_name
                        i_lang.

  CONSTANTS: lc_funcname LIKE rs38l-name VALUE 'CREATE_TEXT'.

  DATA: l_langname TYPE spras,
        l_tdname   LIKE thead-tdname,
        ls_thead   TYPE thead.


* Check if a language can be used
  l_langname = i_lang.
  CATCH SYSTEM-EXCEPTIONS localization_errors = 1.
    SET LOCALE LANGUAGE l_langname.
  ENDCATCH.
  IF sy-subrc <> 0.
    MESSAGE i113 WITH l_langname
            'Language is not set - cannot be used'(010).
    EXIT.
  ENDIF.

  l_tdname = i_txt_name.

* Read text name and language
  SELECT SINGLE mandt INTO sy-mandt FROM stxh
               WHERE tdname   = i_txt_name
                 AND tdspras  = l_langname
                 AND tdid     = 'ST'
                 AND tdobject = 'TEXT'.

* Check whether text ID exists or not
  IF sy-subrc NE 0.
*   Check if FM CREATE_TEXT exists or not
    CALL FUNCTION 'FUNCTION_EXISTS'
         EXPORTING
              funcname           = lc_funcname
         EXCEPTIONS
              function_not_exist = 1
              OTHERS             = 2.

    IF sy-subrc EQ 0.
      CALL FUNCTION lc_funcname "#EC PATHLOCK_CI_DYN_ACCES
           EXPORTING
                fid         = 'ST'
                flanguage   = l_langname
                fname       = l_tdname
                fobject     = 'TEXT'
                save_direct = 'X'
                fformat     = '*'
           TABLES
                flines      = gt_tline
           EXCEPTIONS
                no_init     = 1
                no_save     = 2
                OTHERS      = 3.

      IF sy-subrc EQ 0.
        CALL FUNCTION 'READ_TEXT'
             EXPORTING
         client   = sy-mandt "#EC SAST_CI_GEN_CHECK (HBHALLA)
         object   = 'TEXT'
         name     = l_tdname
         id       = 'ST'
         language = l_langname
             IMPORTING
                  header   = ls_thead
             TABLES
                  lines    = gt_tline
             EXCEPTIONS
                  OTHERS   = 1.

*       If it fails we will get script message for text
        IF sy-subrc NE 0.
          CALL FUNCTION 'SAPSCRIPT_MESSAGE'.
          EXIT.
        ENDIF.

*       Check authority to open in "edit mode"
        CALL FUNCTION 'CHECK_TEXT_AUTHORITY'
             EXPORTING
                  activity     = 'SHOW'
                  id           = 'ST'
                  language     = l_langname
                  name         = l_tdname
                  object       = 'TEXT'
             EXCEPTIONS
                  no_authority = 1
                  OTHERS       = 2.
        IF sy-subrc NE 0.
          MESSAGE s613(td) WITH l_langname
                                'ST'
                                l_tdname.
          EXIT.
        ENDIF.

        CALL FUNCTION 'EDIT_TEXT'
             EXPORTING
                  header        = ls_thead
             TABLES
                  lines         = gt_tline
             EXCEPTIONS
                  id            = 1
                  language      = 2
                  linesize      = 3
                  name          = 4
                  object        = 5
                  textformat    = 6
                  communication = 7
                  OTHERS        = 8.

*       If it is fails it will give script message for that text
        IF sy-subrc NE 0.
          CALL FUNCTION 'SAPSCRIPT_MESSAGE'.
        ENDIF.

        REFRESH: gt_tline.
        EXIT.
      ENDIF.

*************************************************************
*   FM CREATE_TEXT does not exist
    ELSE.
*      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SO10'.
*Begin of Addition:HBHALLA(CVA_PR2_Static txn call)(05/05/26)
        CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
          EXPORTING
            tcode         = 'SO10'
         EXCEPTIONS
           OK            = 1
           NOT_OK        = 2
           OTHERS        = 3.
      IF sy-subrc = 1.
        CALL TRANSACTION 'SO10'.
      ELSE.
        MESSAGE e077(s#) WITH 'SO10'.
      ENDIF.
*End of Addition:HBHALLA(CVA_PR2_Static txn call)(05/05/26)
    ENDIF.
  ENDIF.

  CALL FUNCTION 'READ_TEXT'
       EXPORTING
            client   = sy-mandt "#EC SAST_CI_GEN_CHECK (HBHALLA)
            object   = 'TEXT'
            name     = l_tdname
            id       = 'ST'
            language = l_langname
       IMPORTING
            header   = ls_thead
       TABLES
            lines    = gt_tline
       EXCEPTIONS
            OTHERS   = 1.

* If it fails we will get script message for text
  IF sy-subrc NE 0.
    CALL FUNCTION 'SAPSCRIPT_MESSAGE'.
    EXIT.                              " Exit Form
  ENDIF.

* Check authority to open in "edit mode"
  CALL FUNCTION 'CHECK_TEXT_AUTHORITY'
       EXPORTING
            activity     = 'SHOW'
            id           = 'ST'
            language     = l_langname
            name         = l_tdname
            object       = 'TEXT'
       EXCEPTIONS
            no_authority = 1
            OTHERS       = 2.
  IF sy-subrc NE 0.
    MESSAGE s613(td) WITH l_langname 'ST'
                          l_tdname.
    EXIT.
  ENDIF.

  CALL FUNCTION 'EDIT_TEXT'
       EXPORTING
            display       = space
            header        = ls_thead
       TABLES
            lines         = gt_tline
       EXCEPTIONS
            id            = 1
            language      = 2
            linesize      = 3
            name          = 4
            object        = 5
            textformat    = 6
            communication = 7
            OTHERS        = 8.

* If it is fails it will give script message for that text
  IF sy-subrc NE 0.
    CALL FUNCTION 'SAPSCRIPT_MESSAGE'.
  ENDIF.
ENDFORM.                    " edit_text

*&---------------------------------------------------------------------*
*&      Form  sort_col_cnf
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SORT_TYPE  text
*----------------------------------------------------------------------*
FORM sort_col_cnf USING    p_sort_type.

  REFRESH fld_list.
  LOOP AT tc_config-cols INTO col.
    IF col-selected = 'X'.
      APPEND col TO fld_list.
    ENDIF.
  ENDLOOP.
  SORT fld_list BY index.
  CLEAR:fldname.
  IF NOT fld_list[] IS INITIAL.
    READ TABLE fld_list INDEX 1 INTO col.

    IF col-screen-name CS 'GT_CONFIG'.
      fldname = col-screen-name+10.
    ENDIF.
    IF p_sort_type = 'A'.
      SORT gt_config BY (fldname) ASCENDING.
    ELSE.
      SORT gt_config BY (fldname) DESCENDING.
    ENDIF.
  ENDIF.
ENDFORM.                    " sort_col_cnf

*---------------------------------------------------------------------*
*       FORM f4_help_Category                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  P_CATEGORY                                                    *
*---------------------------------------------------------------------*
FORM f4_help_category CHANGING p_category TYPE
                         /psyng/se_config_param-category.
  DATA: BEGIN OF lt_category OCCURS 0,
        category  TYPE /psyng/se_config_param-category,
        END OF lt_category.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_return    TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_fields    TYPE TABLE OF dfies      WITH HEADER LINE.

  LOOP AT gt_config.
    MOVE-CORRESPONDING gt_config TO lt_category.
    COLLECT lt_category.
  ENDLOOP.
  DELETE lt_category WHERE category IS initial.

  LOOP AT lt_category.
    lt_values-line = lt_category-category.
    APPEND lt_values.
  ENDLOOP.

  lt_fields-tabname   = '/PSYNG/SE_CONFIG_PARAM'.
  lt_fields-fieldname = 'CATEGORY'.
  APPEND lt_fields.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield        = 'CATEGORY'
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

  IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL.
    READ TABLE lt_return INDEX 1.
    gl_config-category = lt_return-fieldval.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM f4_help_param                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  P_PARAM                                                       *
*---------------------------------------------------------------------*
FORM f4_help_param CHANGING p_param TYPE
                         /psyng/se_config_param-param.

  DATA: BEGIN OF lt_param OCCURS 0,
          param  TYPE /psyng/se_config_param-param,
          END OF lt_param.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_return    TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_fields    TYPE TABLE OF dfies      WITH HEADER LINE.

  LOOP AT gt_config.
    MOVE-CORRESPONDING gt_config TO lt_param.
    COLLECT lt_param.
  ENDLOOP.
  DELETE lt_param WHERE param IS initial.
  LOOP AT lt_param.
    lt_values-line = lt_param-param.
    APPEND lt_values.
  ENDLOOP.

  lt_fields-tabname   = '/PSYNG/SE_CONFIG_PARAM'.
  lt_fields-fieldname = 'PARAM'.
  APPEND lt_fields.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield        = 'PARAM'
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

  IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL.
    READ TABLE lt_return INDEX 1.
    gl_config-param = lt_return-fieldval.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM f4_help_value                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  P_VALUE                                                       *
*---------------------------------------------------------------------*
FORM f4_help_value CHANGING p_value TYPE
                         /psyng/se_config_param-value.

  DATA: BEGIN OF lt_value OCCURS 0,
          value  TYPE /psyng/se_config_param-value,
          END OF lt_value.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_return    TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_fields    TYPE TABLE OF dfies      WITH HEADER LINE.

  LOOP AT gt_config.
    MOVE-CORRESPONDING gt_config TO lt_value.
    COLLECT lt_value.
  ENDLOOP.
  DELETE lt_value WHERE value IS initial.

  LOOP AT lt_value.
    lt_values-line = lt_value-value.
    APPEND lt_values.
  ENDLOOP.

  lt_fields-tabname   = '/PSYNG/SE_CONFIG_PARAM'.
  lt_fields-fieldname = 'VALUE'.
  APPEND lt_fields.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield        = 'VALUE'
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

  IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL.
    READ TABLE lt_return INDEX 1.
    gl_config-value = lt_return-fieldval.
  ENDIF.

ENDFORM.
