REPORT /psyng/sw_154.
TYPE-POOLS: SSCR.

*--Type for F4 help
TYPES: BEGIN OF ty_values,
         line(255) TYPE c,
       END OF   ty_values.
DATA : ls_return  TYPE bapireturn,
       lt_hidden  TYPE TABLE OF /psyng/swinvisbl WITH HEADER LINE,
       gt_swbuttabs TYPE TABLE OF /psyng/swbuttabs,
       gs_swbuttabs TYPE /psyng/swbuttabs,
       lt_return  TYPE TABLE OF bapireturn,
       l_rfcdest  TYPE RFCDEST,
       gt_e071    TYPE e071 OCCURS 0 WITH HEADER LINE,
       gt_e071k   TYPE e071k OCCURS 0 WITH HEADER LINE,
       g_trkorr   TYPE trkorr,
       l_programm TYPE /psyng/sw_button_tab_name,
       lf_log_heading TYPE flag,
       gs_opt_list TYPE sscr_opt_list,
       gs_restrict TYPE sscr_restrict,
       gs_ass      TYPE sscr_ass.
PARAMETERS :
  p_local  TYPE flag USER-COMMAND local DEFAULT 'X',
  p_system TYPE /psyng/sw_rfcdes-rfcdest
           MATCHCODE OBJECT /psyng/sw_rfcsh_coll.
PARAMETERS: list   TYPE flag RADIOBUTTON GROUP g1 USER-COMMAND usr,
            downld TYPE flag RADIOBUTTON GROUP g1,
            p_path TYPE rlgrap-filename
            LOWER CASE DEFAULT 'c:\temp' OBLIGATORY MODIF ID fil,
            p_file TYPE rlgrap-filename LOWER CASE
DEFAULT 'HiddenElements.txt' OBLIGATORY MODIF ID fil.
PARAMETERS  transp TYPE flag RADIOBUTTON GROUP g1.
SELECTION-SCREEN : SKIP 4.
SELECT-OPTIONS :
            s_progr FOR l_programm  NO intervals MODIF ID prg.
PARAMETERS : "PROGRAMM type PROGRAMM,
  hide   TYPE flag RADIOBUTTON GROUP g1,
  unhide TYPE flag RADIOBUTTON GROUP g1,
  unh_all TYPE flag RADIOBUTTON GROUP g1.
INITIALIZATION.
*Create an option list where only EQUALS is enabled
  gs_opt_list-name       = 'S_PROGR'.
  gs_opt_list-options-eq = 'X'.         " Equals is enabled
  APPEND gs_opt_list TO gs_restrict-opt_list_tab.

*Apply the option list that has only Equals enabled to Select-option S_MATNR
  gs_ass-kind    = 'S'.       " Applicable to specific Select-option
  gs_ass-name    = 'S_PROGR'.
  gs_ass-sg_main = 'I'.       " Both Include and Exclude options
  gs_ass-op_main = 'S_PROGR'.
  APPEND gs_ass TO gs_restrict-ass_tab.

  CALL FUNCTION 'SELECT_OPTIONS_RESTRICT'
    EXPORTING
      restriction            = gs_restrict
    EXCEPTIONS
      too_late               = 1
      repeated               = 2
      selopt_without_options = 3
      selopt_without_signs   = 4
      invalid_sign           = 5
      empty_option_list      = 6
      invalid_kind           = 7
      repeated_kind_a        = 8
      OTHERS                 = 9.
*BOC:HBHALLA (04/12/24)
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN 1.
                MESSAGE s002(/psyng/sw)
             WITH 'Call is too late'.
             WHEN 2.
                MESSAGE s002(/psyng/sw)
             WITH 'Multiple call using LDB or report'.
             WHEN 3.
                MESSAGE s002(/psyng/sw)
             WITH 'One of the select-options contains no valid options'.
             WHEN 4.
                MESSAGE s002(/psyng/sw)
             WITH 'One of the select-options does not have a valid sign'.
             WHEN 5.
                MESSAGE s002(/psyng/sw)
             WITH 'Invalid sign'.
             WHEN 6.
                MESSAGE s002(/psyng/sw)
             WITH 'One of the options lists is empty'.
             WHEN 7.
                MESSAGE s002(/psyng/sw)
             WITH 'One line has a KIND value unequal to A, B, or S'.
             WHEN 8.
                MESSAGE s002(/psyng/sw)
             WITH 'More than one line has KIND = A'.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (04/12/24)

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_path.
  PERFORM dir_select.
*---------------- AT SELECTION-SCREEN ON VALUE-REQUEST ----------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_progr-low.
  PERFORM f4_progr CHANGING s_progr-low.

AT SELECTION-SCREEN OUTPUT.
  IF transp EQ 'X'.
     CLEAR p_system.
     p_local = 'X'.
  ENDIF.
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'PRG'.
        IF unh_all EQ 'X'.
           screen-input = 0.
        ELSE.
           screen-input = 1.
        ENDIF.
        MODIFY SCREEN.
      WHEN 'FIL'.
        IF downld IS INITIAL.
           screen-active = 0.
        ELSE.
           screen-active = 1.
        ENDIF.
        MODIFY SCREEN.
     ENDCASE.
     CASE screen-name.
      WHEN 'P_SYSTEM'.
        IF p_local = 'X'.
          CLEAR p_system.
          screen-input = '0'.
        ELSE.
          screen-input = '1'.
        ENDIF.
        MODIFY SCREEN.
    ENDCASE.
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
*--Check authorizations
  AUTHORITY-CHECK OBJECT 'S_TCODE'
           ID 'TCD' FIELD '/PSYNG/SW_154'.
  IF sy-subrc <> 0.
    MESSAGE e108(/psyng/sw) WITH 'Hide or Un-hide elements'(003).
  ENDIF.
  AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
           ID 'Y&SW_ADMF' FIELD 'HIDEELEM'.
  IF sy-subrc <> 0.
    MESSAGE e108(/psyng/sw) WITH 'Hide or Un-hide elements'(003).
  ENDIF.

  IF  p_local IS INITIAL
  AND p_system IS INITIAL.
    MESSAGE s002(/psyng/sw)
    WITH 'Please enter remote system Or Choose local system'(a01).
    LEAVE LIST-PROCESSING.
  ENDIF.
*-- Check RFC destinations
  IF NOT p_system IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.
  IF ( hide EQ 'X' OR unhide EQ 'X' ).
  IF NOT s_progr IS INITIAL.
    SELECT * FROM /psyng/swbuttabs
      INTO TABLE gt_swbuttabs
      WHERE element_name IN s_progr.
      IF sy-subrc EQ 0.
        SORT gt_swbuttabs BY element_type.
      ENDIF.
  ENDIF.
  IF gt_swbuttabs IS INITIAL.
    MESSAGE s002(/psyng/sw)
    WITH 'Please enter some valid element'(t12).
    LEAVE LIST-PROCESSING.
  ENDIF.
  ENDIF.
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
    CALL FUNCTION '/PSYNG/SW_062'
      DESTINATION p_system
      IMPORTING
        e_rfcdest             = l_rfcdest
      EXCEPTIONS
        communication_failure = 1
        system_failure        = 2
        OTHERS                = 3."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    IF sy-subrc EQ 0.
       CONCATENATE 'System :'(t11) l_rfcdest INTO l_rfcdest SEPARATED BY space.
  WRITE :/ l_rfcdest.
  ULINE.
    ENDIF.
  IF hide = 'X'.
    LOOP AT gt_swbuttabs INTO gs_swbuttabs.
      CALL FUNCTION '/PSYNG/SW_012'
      DESTINATION p_system
        EXPORTING
          swprogram = gs_swbuttabs-element_name
        IMPORTING
          return    = ls_return
 EXCEPTIONS
   system_failure        = 1
   communication_failure = 2
   OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up

  if sy-subrc EQ 0.
        IF ls_return-code = '108'.
        MESSAGE ID '/PSYNG/SW' TYPE 'S' NUMBER 108 WITH ls_return-message
        'in remote system'(t07) p_system.
        LEAVE LIST-PROCESSING.
        ELSE.
           APPEND ls_return TO lt_return.
        ENDIF.
  endif.
    ENDlOOP.
    PERFORM log_for_hide.
  ELSEIF unhide = 'X'.
    LOOP AT gt_swbuttabs INTO gs_swbuttabs.
          PERFORM unhide USING gs_swbuttabs-element_name.
    ENDLOOP.
    PERFORM log_for_unhide.
  ELSEIF unh_all EQ 'X'.
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
    CALL FUNCTION '/PSYNG/SW_012'
      DESTINATION p_system
      EXPORTING
       if_get_hidden_elements       = 'X'
     TABLES
       et_hidden                    = lt_hidden
 EXCEPTIONS
   system_failure        = 1
   communication_failure = 2
   OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up

  if sy-subrc NE 0.
*Raise error
  endif.
      IF lt_hidden[] IS INITIAL.
        WRITE : 'No hidden buttons or tabs in transaction /PSYNG/SE'(001).
      ELSE.
        REFRESH gt_swbuttabs.
        SELECT * FROM /psyng/swbuttabs
          INTO TABLE gt_swbuttabs
          FOR ALL ENTRIES IN lt_hidden
          WHERE element_name = lt_hidden-swprogram.
        LOOP AT lt_hidden.
          PERFORM unhide USING lt_hidden-swprogram.
        ENDLOOP.
          PERFORM log_for_unhide.
      ENDIF.
  ELSEIF list = 'X'.
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
    CALL FUNCTION '/PSYNG/SW_012'
      DESTINATION p_system
      EXPORTING
       if_get_hidden_elements       = 'X'
     TABLES
       et_hidden                    = lt_hidden
 EXCEPTIONS
   system_failure        = 1
   communication_failure = 2
   OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  if sy-subrc NE 0.
*Raise error
  endif.
      IF NOT lt_hidden[] IS INITIAL.
        REFRESH gt_swbuttabs.
        SELECT * FROM /psyng/swbuttabs
          INTO TABLE gt_swbuttabs
          FOR ALL ENTRIES IN lt_hidden
          WHERE element_name = lt_hidden-swprogram.
        SORT gt_swbuttabs BY element_type.
        WRITE :/  'Hidden elements in transaction /PSYNG/SE'(002).
        SKIP.
        ULINE (180).
        WRITE :/ '|', 'Element Name', 41 '|', 'Element Type', 58 '|', 'Description',180 '|'.
        LOOP AT gt_swbuttabs INTO gs_swbuttabs.
          ULINE (180).
          WRITE : / '|', gs_swbuttabs-element_name, 41 '|', gs_swbuttabs-element_type, 58 '|', gs_swbuttabs-description(120), 180 '|'.
        ENDLOOP.
        ULINE (180).
      ELSE.
        WRITE : 'No hidden elements in transaction /PSYNG/SE'(001).
      ENDIF.
    ELSEIF transp = 'X'.
      SELECT * FROM /psyng/swinvisbl INTO TABLE lt_hidden.
        IF NOT lt_hidden[] IS INITIAL.
          PERFORM create_transport.
          gt_e071-trkorr   = g_trkorr.
          gt_e071-pgmid    = 'R3TR'.
          gt_e071-object   = 'TABU'.
          gt_e071-obj_name = '/PSYNG/SWINVISBL'.
          gt_e071-objfunc  = ''.
          gt_e071k-mastertype = 'TABU'.
          gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SWINVISBL'.
          gt_e071k-tabkey  = '*'. CONDENSE gt_e071k-tabkey.
          MOVE-CORRESPONDING gt_e071 TO gt_e071k.
          APPEND gt_e071k.
          APPEND gt_e071.
          PERFORM add_to_transport.

        ELSE.
          WRITE : 'No hidden buttons or tabs in transaction /PSYNG/SE'(001).
        ENDIF.
     ELSEIF downld = 'X'.
        PERFORM download.
     ENDIF.

FORM create_transport.
  CHECK g_trkorr IS INITIAL.

  CALL FUNCTION 'TRINT_ORDER_CHOICE'
    EXPORTING
      wi_order_type          = 'W'
      wi_task_type           = 'F'
      wi_category            = 'SYST'
      wi_cli_dep             = ''
      wi_display_button      = 'X'
    IMPORTING
      we_task                = g_trkorr
    TABLES
      wt_e071                = gt_e071
      wt_e071k               = gt_e071k
    EXCEPTIONS
      no_correction_selected = 1
      display_mode           = 2
      object_append_error    = 3
      recursive_call         = 4
      wrong_order_type       = 5
      OTHERS                 = 6.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

* Get existing data
  SELECT * INTO TABLE gt_e071 FROM e071
         WHERE trkorr = g_trkorr.

    SELECT * INTO TABLE gt_e071k FROM e071k
           WHERE trkorr = g_trkorr.
ENDFORM.                    " create_transport
FORM add_to_transport.

  DATA: ls_e070 TYPE e070,
        ls_e07t TYPE e07t.
  DATA : l_trnsport TYPE e070-strkorr.

  SELECT SINGLE * INTO ls_e070 FROM e070
                WHERE trkorr = g_trkorr.

    SELECT SINGLE * INTO ls_e07t FROM e07t
                  WHERE trkorr = g_trkorr.

      SORT gt_e071 BY pgmid object obj_name.
      DELETE ADJACENT DUPLICATES FROM gt_e071
                                 COMPARING pgmid object obj_name.
      SORT gt_e071k BY pgmid object objname tabkey.
      DELETE ADJACENT DUPLICATES FROM gt_e071k
                                 COMPARING pgmid object objname tabkey.

      CALL FUNCTION 'TRINT_MODIFY_COMM'
        EXPORTING
          wi_called_by_editor            = 'X'
          wi_e070                        = ls_e070
          wi_e07t                        = ls_e07t
          wi_lock_sort_flag              = 'X'
          wi_save_user                   = 'X'
          wi_sel_e071                    = 'X'
          wi_sel_e071k                   = 'X'
          wi_sel_e07t                    = space
        TABLES
          wt_e071                        = gt_e071
          wt_e071k                       = gt_e071k
        EXCEPTIONS
          chosen_project_closed          = 1
          e070_insert_error              = 2
          e070_update_error              = 3
          e071k_insert_error             = 4
          e071k_update_error             = 5
          e071_insert_error              = 6
          e071_update_error              = 7
          e07t_insert_error              = 8
          e07t_update_error              = 9
          e070c_insert_error             = 10
          e070c_update_error             = 11
          locked_entries                 = 12
          locked_object_not_deleted      = 13
          ordername_forbidden            = 14
          order_change_but_locked_object = 15
          order_released                 = 16
          order_user_locked              = 17
          tr_check_keysyntax_error       = 18
          no_authorization               = 19
          wrong_client                   = 20 "#EC SAST_CI_GEN_CHECK
          unallowed_source_client        = 21
          unallowed_user                 = 22
          unallowed_trfunction           = 23
          unallowed_trstatus             = 24
          no_systemname                  = 25
          no_systemtype                  = 26
          OTHERS                         = 27.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ELSE.
        IF NOT ls_e070 IS INITIAL.
          l_trnsport = ls_e070-strkorr.
          MESSAGE s181(/psyng/sw) WITH l_trnsport 'Transport Created'(005).
        ENDIF.
      ENDIF.
ENDFORM.                    " add_to_transport
*&---------------------------------------------------------------------*
*&      Form  UNHIDE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_HIDDEN_SWPROGRAM  text
*----------------------------------------------------------------------*
FORM unhide  USING i_swprogram TYPE PROGRAMM.

DATA: ls_return  TYPE bapireturn.
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
      CALL FUNCTION '/PSYNG/SW_013'
      DESTINATION p_system
        EXPORTING
          swprogram = i_swprogram
        IMPORTING
          return    = ls_return
 EXCEPTIONS
   system_failure        = 1
   communication_failure = 2
   OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  if sy-subrc EQ 0.
        IF ls_return-code = '108'.
        MESSAGE ID '/PSYNG/SW' TYPE 'S' NUMBER 108 WITH ls_return-message
        'in remote system'(t07) p_system.
        LEAVE LIST-PROCESSING.
        ELSE.
           APPEND ls_return TO lt_return.
        ENDIF.
  endif.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DIR_SELECT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM dir_select.

  DATA :   l_title TYPE string,
           l_folder TYPE string.

  l_title = 'Open'(t02).
  l_folder = p_path.
  CALL METHOD cl_gui_frontend_services=>directory_browse
"#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
      window_title    = l_title
      initial_folder  = l_folder
    CHANGING
      selected_folder = l_folder
    EXCEPTIONS
      cntl_error      = 1
      error_no_gui    = 2
      OTHERS          = 3
          .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      cntl_system_error = 1
      cntl_error        = 2
      OTHERS            = 3
          .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  p_path  = l_folder.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM download .
  DATA: l_filename TYPE string,
        l_err_mess TYPE bapiret2-message,
        l_msgv1    TYPE bapiret2-message_v1,
        l_msgv2    TYPE bapiret2-message_v2.

DATA: lt_hidden  TYPE TABLE OF /psyng/swinvisbl WITH HEADER LINE.
  CONCATENATE p_path '\' p_file INTO l_filename.

  IF  l_filename NP '*.txt'
  AND l_filename NP '*.xls'.
    MESSAGE s113(/psyng/sw) WITH 'Please put valid file format (.txt or .xls)'(t03).
    LEAVE LIST-PROCESSING.
  ENDIF.
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
      CALL FUNCTION '/PSYNG/SW_012'
      DESTINATION p_system
      EXPORTING
       if_get_hidden_elements       = 'X'
     TABLES
       et_hidden                    = lt_hidden
 EXCEPTIONS
   system_failure        = 1
   communication_failure = 2
   OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  if sy-subrc NE 0.
*Raise error
  endif.
  IF lt_hidden[] IS NOT INITIAL.
        REFRESH gt_swbuttabs.
        SELECT * FROM /psyng/swbuttabs
          INTO TABLE gt_swbuttabs
          FOR ALL ENTRIES IN lt_hidden
          WHERE element_name = lt_hidden-swprogram.
        SORT gt_swbuttabs BY element_type.
*BOC:HBHALLA (096)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '61'.
  IF sy-subrc = 0.
  CALL FUNCTION 'GUI_DOWNLOAD' "#EC SAST_CI_GEN_CHECK
       EXPORTING
            filename                = l_filename
            filetype                = 'ASC'
            write_field_separator   = 'X'
            dat_mode                = ' '
*       IMPORTING
*            FILELENGTH              = l_download_size
       TABLES
            data_tab                = gt_swbuttabs
       EXCEPTIONS
            file_write_error        = 1
            no_batch                = 2
            gui_refuse_filetransfer = 3
            invalid_type            = 4
            no_authority            = 5
            unknown_error           = 6
            header_not_allowed      = 7
            separator_not_allowed   = 8
            filesize_not_allowed    = 9
            header_too_long         = 10
            dp_error_create         = 11
            dp_error_send           = 12
            dp_error_write          = 13
            unknown_dp_error        = 14
            access_denied           = 15
            dp_out_of_memory        = 16
            disk_full               = 17
            dp_timeout              = 18
            file_not_found          = 19
            dataprovider_exception  = 20
            control_flush_error     = 21
            OTHERS                  = 22.

  IF sy-subrc <> 0.
    l_msgv1          = l_filename.
    l_msgv2          = 'Unable to download Hidden elements file'(t05).
    CALL FUNCTION '/PSYNG/BC_003'
         EXPORTING
              i_subrc     = sy-subrc
              i_msgty     = 'I'
              i_msgv1     = l_msgv1
              i_msgv2     = l_msgv2
              if_no_popup = 'X'
         IMPORTING
              e_message   = l_err_mess.

        MESSAGE l_err_mess TYPE 'S'.
  ELSE.
        MESSAGE ID '/PSYNG/SW' TYPE 'S' NUMBER 002
        WITH 'Hidden elements are downloaded sucessfully'(t04).
  ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
        ELSE.
          WRITE : 'No hidden buttons or tabs in transaction /PSYNG/SE'(001).
        ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  RFC_VALIDATIONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM rfc_validations .
  DATA: lt_rfcs    TYPE TABLE OF /psyng/sw_sel_opts_rfcdest,
        ls_rfcs    TYPE /psyng/sw_sel_opts_rfcdest.
  DATA: lt_ret TYPE TABLE OF bapiret2,
        ls_ret TYPE bapiret2.
  ls_rfcs-sign   = 'I'.
  ls_rfcs-option = 'EQ'.
  ls_rfcs-low    = p_system.

  APPEND ls_rfcs TO lt_rfcs.
*--Validate RFC Destinations
  CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
    EXPORTING
      i_popup   = 'N'
      i_module  = 'SE'
    TABLES
      it_rfcdes = lt_rfcs
      et_return = lt_ret.

  IF NOT lt_ret IS INITIAL.
    READ TABLE lt_ret INTO ls_ret INDEX 1.
    MESSAGE s002(/psyng/sw) WITH ls_ret-message.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  LOG_FOR_UNHIDE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM log_for_unhide .
    SORT gt_swbuttabs BY element_name.
    READ TABLE lt_return INTO ls_return WITH KEY type = 'S'.
    IF sy-subrc EQ 0.
        WRITE :/ 'Following elements in transaction /PSYNG/SE are un-hidden'(t09).
        SKIP.
        ULINE (180).
        WRITE :/ '|','Element Name', 41 '|','Element Type', 58 '|','Description', 180 '|'.
    LOOP AT lt_return INTO ls_return WHERE type EQ 'S'.
      READ TABLE gt_swbuttabs INTO gs_swbuttabs
      WITH KEY element_name = ls_return-message_v1 BINARY SEARCH.
      IF sy-subrc EQ 0.
          ULINE (180).
          WRITE : / '|',ls_return-message_v1, 41 '|',gs_swbuttabs-element_type, 58 '|',gs_swbuttabs-description(120), 180 '|'.
      ENDIF.
    ENDLOOP.
        ULINE (180).
        SKIP.
    ENDIF.
    READ TABLE lt_return INTO ls_return WITH KEY type = 'E'.
    IF sy-subrc EQ 0.
        WRITE :/ 'Following elements in transaction /PSYNG/SE are already visible'(t10).
        SKIP.
        ULINE (180).
        WRITE :/ '|','Element Name', 41 '|','Element Type', 58 '|','Description', 180 '|'.
    LOOP AT lt_return INTO ls_return WHERE type EQ 'E'.
      READ TABLE gt_swbuttabs INTO gs_swbuttabs
      WITH KEY element_name = ls_return-message_v1 BINARY SEARCH.
      IF sy-subrc EQ 0.
          ULINE (180).
          WRITE : / '|',ls_return-message_v1, 41 '|',gs_swbuttabs-element_type, 58 '|',gs_swbuttabs-description(120), 180 '|'.
      ENDIF.
    ENDLOOP.
        ULINE (180).
        SKIP.
    ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  LOG_FOR_HIDE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM log_for_hide .
    SORT gt_swbuttabs BY element_name.
    READ TABLE lt_return INTO ls_return WITH KEY type = 'S'.
    IF sy-subrc EQ 0.
        WRITE :/ 'Following elements in transaction /PSYNG/SE are hidden'(t06).
        SKIP.
        ULINE (180).
        WRITE :/ '|','Element Name', 41 '|','Element Type', 58 '|','Description', 180 '|'.
    LOOP AT lt_return INTO ls_return WHERE type EQ 'S'.
      READ TABLE gt_swbuttabs INTO gs_swbuttabs
      WITH KEY element_name = ls_return-message_v1 BINARY SEARCH.
      IF sy-subrc EQ 0.
          ULINE (180).
          WRITE : / '|',ls_return-message_v1, 41 '|',gs_swbuttabs-element_type, 58 '|',gs_swbuttabs-description(120), 180 '|'.
      ENDIF.
    ENDLOOP.
        ULINE (180).
        SKIP.
    ENDIF.
    READ TABLE lt_return INTO ls_return WITH KEY type = 'E'.
    IF sy-subrc EQ 0.
        WRITE :/ 'Following elements in transaction /PSYNG/SE are already invisible'(t08).
        SKIP.
        ULINE (180).
        WRITE :/ '|','Element Name', 41 '|','Element Type', 58 '|','Description', 180 '|'.
    LOOP AT lt_return INTO ls_return WHERE type EQ 'E'.
      READ TABLE gt_swbuttabs INTO gs_swbuttabs
      WITH KEY element_name = ls_return-message_v1 BINARY SEARCH.
      IF sy-subrc EQ 0.
          ULINE (180).
          WRITE : / '|',ls_return-message_v1, 41 '|',gs_swbuttabs-element_type, 58 '|',gs_swbuttabs-description(120), 180 '|'.
      ENDIF.
    ENDLOOP.
        ULINE (180).
        SKIP.
    ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_PROGR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_PROGR_LOW  text
*----------------------------------------------------------------------*
FORM f4_progr  CHANGING e_progr TYPE /psyng/sw_button_tab_name.

  DATA: lt_values   TYPE TABLE OF ty_values,
        ls_values   TYPE ty_values,
        lt_fields   TYPE TABLE OF dfies,
        ls_fields   TYPE dfies,
        lt_return   TYPE TABLE OF ddshretval,
        ls_return   TYPE ddshretval,
        lt_swbuttabs TYPE TABLE OF /psyng/swbuttabs,
        l_type      TYPE dd01v-datatype.
FIELD-SYMBOLS: <fs_swbuttabs> TYPE /psyng/swbuttabs.
*
  ls_fields-tabname   = '/PSYNG/SWBUTTABS'.
  ls_fields-fieldname = 'ELEMENT_NAME'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'ELEMENT_TYPE'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'DESCRIPTION'.
  APPEND ls_fields TO lt_fields.

* Get values for popup
    SELECT * INTO TABLE lt_swbuttabs
      FROM /psyng/swbuttabs.

LOOP AT lt_swbuttabs ASSIGNING <fs_swbuttabs>
  WHERE element_name EQ '/PSYNG/SODREPORT'
     OR element_name EQ '/PSYNG/SODREPORT_BY_PROFILE'
     OR element_name EQ '/PSYNG/SW_018'
     OR element_name EQ '/PSYNG/SW_AUTH_COUNT'.
<fs_swbuttabs>-description = 'Obsolete Report'.
ENDLOOP.

  LOOP AT lt_swbuttabs ASSIGNING <fs_swbuttabs>.
    ls_values-line = <fs_swbuttabs>-element_name.
    APPEND ls_values TO lt_values.
    ls_values-line = <fs_swbuttabs>-element_type.
    APPEND ls_values TO lt_values.
    ls_values-line = <fs_swbuttabs>-description.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield         = 'ELEMENT_NAME'
       TABLES
            value_tab        = lt_values
            field_tab        = lt_fields
            return_tab       = lt_return
       EXCEPTIONS
            parameter_error  = 1
            no_values_found  = 2
            OTHERS           = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_progr = ls_return-fieldval.

ENDFORM.
