REPORT ztablemain_excdtx_01 MESSAGE-ID /psyng/sw.
*---------------------------------------------------------------------*
*     DECLARATION OF DATA TYPES                                 *
*---------------------------------------------------------------------*
TYPES: BEGIN OF ty_excdtx ,
       sel,
       mandt TYPE /psyng/sw_excdtx-mandt,
       called_tcode TYPE /psyng/sw_excdtx-called_tcode,
       END OF ty_excdtx.

DATA: gt_excdtx TYPE STANDARD TABLE OF ty_excdtx INITIAL SIZE 1000,
       w_excdtx TYPE ty_excdtx,
       gf_data_change TYPE flag,
       g_mode(1)            TYPE c,
       g_filename     TYPE string.

DATA:     g_tabcon_lines  LIKE sy-loopc.
DATA:     ok_code LIKE sy-ucomm.

DATA: BEGIN OF gt_excfunc OCCURS 0,
        func TYPE rsmpe-func,
      END OF gt_excfunc.


CONTROLS: tabcon TYPE TABLEVIEW USING SCREEN 0100.


START-OF-SELECTION.
*********************************
*BOC UMITTAL SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
**Authorization check for Display table /psyng/sw_excdtx
**SF 1665
AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
           ID 'ACTVT' FIELD '03'
           ID 'DICBERCLS' FIELD 'Y&S5'.
  if sy-subrc ne 0.
     MESSAGE e113(/psyng/sw) WITH TEXT-e04 '/psyng/sw_excdtx'.
    stop.
  endif.
**SF 1665
**********************************

  PERFORM enqueue.
  SELECT * FROM /psyng/sw_excdtx INTO CORRESPONDING FIELDS OF
  TABLE gt_excdtx.
  CALL SCREEN 100.


*&---------------------------------------------------------------------*
*&      Form  enqueue
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM enqueue.
  CALL FUNCTION 'ENQUEUE_/PSYNG/TABLE'
       EXPORTING
            tabname        = '/PSYNG/SW_EXCDTX'
       EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
  IF sy-subrc = 0.
    g_mode = 'C'.                      "Change mode
  ELSE.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

    g_mode = 'D'.                      "Display mode
  ENDIF.

ENDFORM.                    " enqueue
*&---------------------------------------------------------------------*
*&      Module  TABCON_CHANGE_TC_ATTR  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tabcon_change_tc_attr OUTPUT.
  DESCRIBE TABLE gt_excdtx LINES tabcon-lines.
ENDMODULE.                 " TABCON_CHANGE_TC_ATTR  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  TABCON_GET_LINES  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tabcon_get_lines OUTPUT.
  g_tabcon_lines = sy-loopc.

ENDMODULE.                 " TABCON_GET_LINES  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS '100'.
  PERFORM toggle_display_change.

ENDMODULE.                 " STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  toggle_display_change
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM toggle_display_change.
  IF g_mode = 'D'.                     "Display
    LOOP AT SCREEN.
      CHECK screen-group1 = '100' AND screen-input = 1.
      screen-input = 0.
      MODIFY SCREEN.
    ENDLOOP.
  ELSE.                                "Change
    LOOP AT SCREEN.
      CHECK screen-group1 = '100' AND screen-input = 0.
      screen-input = 1.
      MODIFY SCREEN.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " toggle_display_change
*&---------------------------------------------------------------------*
*&      Module  TABCON_modify  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tabcon_modify INPUT.
  MODIFY gt_excdtx FROM w_excdtx
      INDEX tabcon-current_line.

  IF sy-subrc NE 0.
    APPEND w_excdtx TO gt_excdtx.
  ENDIF.

  gf_data_change = 'X'.

ENDMODULE.                 " TABCON_modify  INPUT
*&---------------------------------------------------------------------*
*&      Module  TABCON_mark  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tabcon_mark INPUT.
  DATA: w2_excdtx TYPE ty_excdtx.
  IF tabcon-line_sel_mode = 1.

    LOOP AT gt_excdtx INTO w2_excdtx WHERE sel = 'X'.
      w2_excdtx-sel = ''.
      MODIFY gt_excdtx FROM w2_excdtx TRANSPORTING sel.
    ENDLOOP.
  ENDIF.
  w2_excdtx-sel ='X'.
  MODIFY gt_excdtx FROM w2_excdtx INDEX tabcon-current_line
      TRANSPORTING sel.


ENDMODULE.                 " TABCON_mark  INPUT
*&---------------------------------------------------------------------*
*&      Module  TABCON_user_command  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tabcon_user_command INPUT.
  DATA: l_ok              TYPE sy-ucomm,
          l_offset          TYPE i,
          lf_answer(1)      TYPE c.

  ok_code = sy-ucomm.
  CASE ok_code.
    WHEN 'INSR'.
      PERFORM fcode_insert_row USING 'TABCON'
                                     'GT_EXCDTX'.

    WHEN 'DELE'.                      "delete row

      PERFORM fcode_delete_row USING   'TABCON'
                                       'GT_EXCDTX'
                                       'SEL'.


    WHEN 'P--' OR                     "top of list
             'P-'  OR                     "previous page
             'P+'  OR                     "next page
             'P++'.                       "bottom of list
      PERFORM compute_scrolling_in_tc USING 'TABCON'
                                            sy-ucomm.


*WHEN 'MARK'.                      "mark all filled lines
*      PERFORM FCODE_TC_MARK_LINES USING 'TABCON'
*                                         'GT_EXCDTX'
*                                        'SEL'   .
*      CLEAR P_OK.

*WHEN 'DMRK'.                      "demark all filled lines
*      PERFORM FCODE_TC_DEMARK_LINES USING 'TABCON'
*                                          'GT_EXCDTX'
*                                          'SEL' .
*

    WHEN 'UPLD' OR 'DWNLD'.           "upload or download
      CALL SCREEN 200 STARTING AT 3 3 ENDING AT 105 8.


    WHEN 'SAVE'.
      PERFORM save_data.


    WHEN 'EXIT'.
      PERFORM confirm_exit CHANGING lf_answer.
      LEAVE PROGRAM.
      CHECK lf_answer = '1'.
      PERFORM dequeue.
      LEAVE TO SCREEN 0.


  ENDCASE.

ENDMODULE.                 " TABCON_user_command  INPUT



*&---------------------------------------------------------------------*
*&      Form  FCODE_INSERT_ROW
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0265   text
*      -->P_0266   text
*----------------------------------------------------------------------*
FORM fcode_insert_row USING    p_tc_name TYPE  dynfnam
                               p_table_name .
*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA l_lines_name       LIKE feld-name.
  DATA l_selline          LIKE sy-stepl.
  DATA l_lastline         TYPE i.
  DATA l_line             TYPE i.
  DATA l_table_name       LIKE feld-name.
  FIELD-SYMBOLS <tc>                 TYPE cxtab_control.
  FIELD-SYMBOLS <table>              TYPE STANDARD TABLE.
  FIELD-SYMBOLS <lines>              TYPE i.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

* get the table, which belongs to the tc                               *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

"not headerline

* get looplines of TableControl
  CONCATENATE 'G_' p_tc_name '_LINES' INTO l_lines_name.
  ASSIGN (l_lines_name) TO <lines>. "#EC PATHLOCK_CI_DYN_ACCES
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
    l_lastline = <tc>-top_line + <lines> - 1.
  ENDIF.
*&SPWIZARD: set new cursor line                                        *
  l_line = l_selline - <tc>-top_line + 1.
* insert initial line
  INSERT INITIAL LINE INTO <table> INDEX l_selline.
  <tc>-lines = <tc>-lines + 1.
* set cursor
  SET CURSOR LINE l_line.


ENDFORM.                    " FCODE_INSERT_ROW



*&---------------------------------------------------------------------*
*&      Form  FCODE_DELETE_ROW                                         *
*&---------------------------------------------------------------------*
FORM fcode_delete_row
              USING    p_tc_name           TYPE dynfnam
                       p_table_name
                       p_mark_name .

*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA l_table_name       LIKE feld-name.
  DATA: w2_excdtx TYPE ty_excdtx.
  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <wa>.
  FIELD-SYMBOLS <mark_field>.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

* get the table, which belongs to the tc                               *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body

  ASSIGN (l_table_name) TO <table>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

"not headerline

* delete marked lines                                                  *
  DESCRIBE TABLE <table> LINES <tc>-lines.

  LOOP AT <table> ASSIGNING <wa>.

*   access to the component 'FLAG' of the table header                 *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    IF <mark_field> = 'X'.
      DELETE <table> INDEX syst-tabix.
      IF sy-subrc = 0.
        <tc>-lines = <tc>-lines - 1.
      ENDIF.
    ENDIF.
  ENDLOOP.
  gf_data_change = 'X'.
ENDFORM.                              " FCODE_DELETE_ROW
*&---------------------------------------------------------------------*
*&      Module  STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  gt_excfunc-func = 'INSR'.
  APPEND gt_excfunc.
  gt_excfunc-func = 'DELE'.
  APPEND gt_excfunc.
  gt_excfunc-func = 'DWNLD'.
  APPEND gt_excfunc.
  gt_excfunc-func = 'UPLD'.
  APPEND gt_excfunc.
  SET PF-STATUS '100' EXCLUDING gt_excfunc.

ENDMODULE.                 " STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  IF sy-ucomm = 'CONTINUE'.
    IF ok_code = 'UPLD'.          "Upload
      PERFORM upload_file.
    ELSE.
      PERFORM download_file.
    ENDIF.
  ENDIF.

  SET SCREEN 0.
  LEAVE SCREEN.



ENDMODULE.                 " USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*&      Form  upload_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM upload_file.
  DATA: lt_import    TYPE TABLE OF string,
          l_import     TYPE string,
          lt_exclude   TYPE TABLE OF /psyng/sw_excdtx,
          ls_exclude   TYPE /psyng/sw_excdtx.

*BOC:HBHALLA (097)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '60'.
  IF sy-subrc = 0.
  CALL FUNCTION 'GUI_UPLOAD' "#EC SAST_CI_GEN_CHECK
       EXPORTING
            filename            = g_filename
*            HAS_FIELD_SEPARATOR = G_DELIM
       TABLES
            data_tab            = lt_import
       EXCEPTIONS
            OTHERS              = 1.
  IF sy-subrc <> 0.
    MESSAGE e133 WITH g_filename.
  ENDIF.
  IF sy-subrc = 0.
    MESSAGE s140 WITH 'Uploaded Successfully'(007).
  ENDIF.
  ENDIF.
*EOC:HBHALLA (097)
  LOOP AT lt_import INTO l_import.
    w_excdtx-called_tcode = l_import.


    APPEND w_excdtx TO  gt_excdtx.
*        ENDIF.
*      ELSE.
*        MESSAGE E113 WITH TEXT-E01 TEXT-E03 LS_EXCLUDE-SIGN.
*      ENDIF.
*    ELSE.
*      MESSAGE E113 WITH TEXT-E01 TEXT-E02 LS_EXCLUDE-TYPE.
*    ENDIF.
  ENDLOOP.

ENDFORM.                    " upload_file
*&---------------------------------------------------------------------*
*&      Module  f4_FILE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_file INPUT.
  PERFORM f4_file CHANGING g_filename.

ENDMODULE.                 " f4_FILE  INPUT


*&---------------------------------------------------------------------*
*&      Form  f4_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_FILENAME  text
*----------------------------------------------------------------------*
FORM f4_file CHANGING p_g_filename.
  DATA : uaction TYPE i,
         title TYPE string,
         fn TYPE string,
         path TYPE string,
         filetable TYPE  filetable.
  IF ok_code = 'UPLD'.
    MOVE text-003 TO title.
    CALL METHOD cl_gui_frontend_services=>file_open_dialog
"#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
      window_title      = title
      default_extension = 'csv'
      default_filename  = 'test'
      initial_directory = 'c:\temp'
      file_filter       = '*.csv'
      multiselection          = ''
    CHANGING
      file_table              = filetable
      rc                      = uaction
  EXCEPTIONS
    file_open_dialog_failed = 1
    cntl_error              = 2
    error_no_gui            = 3
    OTHERS                  = 4
                      .
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
      READ TABLE filetable INDEX 1 INTO p_g_filename.
    ENDIF.
  ELSE.
    MOVE text-002 TO title.
    CALL METHOD cl_gui_frontend_services=>file_save_dialog
"#EC SAST_CI_GEN_CHECK (HBHALLA)
      EXPORTING
        window_title      = title
        default_extension = 'csv'
        default_file_name = 'SW_excdtx.csv'
        file_filter       = '*.csv'
      CHANGING
        filename          = fn
        path              = path
        fullpath          = p_g_filename
        user_action       = uaction
      EXCEPTIONS
        cntl_error        = 1
        error_no_gui      = 2
        OTHERS            = 3
            .
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.
ENDFORM.                                                    " f4_file
*&---------------------------------------------------------------------*
*&      Form  download_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM download_file.
  DATA: w_tcode TYPE string,
        lt_tcode TYPE TABLE OF string .


  LOOP AT gt_excdtx INTO w_excdtx.
    w_tcode = w_excdtx-called_tcode.
    APPEND w_tcode TO lt_tcode.
  ENDLOOP.
*BOC:HBHALLA (096)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '61'.
  IF sy-subrc = 0.
  CALL FUNCTION 'GUI_DOWNLOAD' "#EC SAST_CI_GEN_CHECK
    EXPORTING
*   BIN_FILESIZE                  =
      filename                      = g_filename
*   FILETYPE                      = 'ASC'
*   APPEND                        = ' '
*   WRITE_FIELD_SEPARATOR         = ' '
*   HEADER                        = '00'
*   TRUNC_TRAILING_BLANKS         = ' '
*   WRITE_LF                      = 'X'
*   COL_SELECT                    = ' '
*   COL_SELECT_MASK               = ' '
*   DAT_MODE                      = ' '
* IMPORTING
*   FILELENGTH                    =
    TABLES
      data_tab                      = lt_tcode
* EXCEPTIONS
*   FILE_WRITE_ERROR              = 1
*   NO_BATCH                      = 2
*   GUI_REFUSE_FILETRANSFER       = 3
*   INVALID_TYPE                  = 4
*   NO_AUTHORITY                  = 5
*   UNKNOWN_ERROR                 = 6
*   HEADER_NOT_ALLOWED            = 7
*   SEPARATOR_NOT_ALLOWED         = 8
*   FILESIZE_NOT_ALLOWED          = 9
*   HEADER_TOO_LONG               = 10
*   DP_ERROR_CREATE               = 11
*   DP_ERROR_SEND                 = 12
*   DP_ERROR_WRITE                = 13
*   UNKNOWN_DP_ERROR              = 14
*   ACCESS_DENIED                 = 15
*   DP_OUT_OF_MEMORY              = 16
*   DISK_FULL                     = 17
*   DP_TIMEOUT                    = 18
*   FILE_NOT_FOUND                = 19
*   DATAPROVIDER_EXCEPTION        = 20
*   CONTROL_FLUSH_ERROR           = 21
*   OTHERS                        = 22
            .
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
* IF SY-SUBRC <> 0.
    MESSAGE e133 WITH g_filename.
* ENDIF.
  ENDIF.

  IF sy-subrc = 0.
    MESSAGE s140 WITH  'Downloaded successfully'(008) .
  ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
ENDFORM.                    " download_file
*&---------------------------------------------------------------------*
*&      Form  SAVE_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_data.
**SF 1665
    AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
               ID 'ACTVT' FIELD '02'
               ID 'DICBERCLS' FIELD 'Y&S5'.
      if sy-subrc ne 0.
     clear sy-ucomm.

         MESSAGE e113(/psyng/sw) WITH TEXT-e05 '/psyng/sw_excdtx'.
        stop.
      endif.

  DATA: ls_excl TYPE /psyng/sw_excdtx,
           lt_exclude TYPE TABLE OF /psyng/sw_excdtx.
* Since there's not much data, delete everything and re-add
*BOC:HBHALLA (17/12/24)
  DELETE FROM /psyng/sw_excdtx  WHERE CALLED_TCODE NE SPACE.
"#EC SAST_CI_GEN_CHECK
*EOC:HBHALLA (17/12/24)
  LOOP AT gt_excdtx INTO w_excdtx.
    MOVE-CORRESPONDING w_excdtx TO ls_excl.
    APPEND  ls_excl TO lt_exclude.
  ENDLOOP.

*Save changes to database
  MODIFY /psyng/sw_excdtx FROM TABLE lt_exclude.
  COMMIT WORK.
  MESSAGE s140 WITH text-006.
  CLEAR gf_data_change.

ENDFORM.                    " SAVE_DATA

*&---------------------------------------------------------------------*
*&      Form  CONFIRM_EXIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LF_ANSWER  text
*----------------------------------------------------------------------*
FORM confirm_exit CHANGING e_answer TYPE char1.

  e_answer = '1'.
  CHECK gf_data_change = 'X'.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
       EXPORTING
            titlebar              = text-t02
            text_question         = text-q01
            text_button_1         = text-004
            icon_button_1         = 'ICON_OKAY'
            text_button_2         = text-005
            icon_button_2         = 'ICON_SYSTEM_CANCEL'
            default_button        = '2'
            display_cancel_button = space
       IMPORTING
            answer                = e_answer
       EXCEPTIONS
            text_not_found        = 1
            OTHERS                = 2.

"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.                    " CONFIRM_EXIT
*&---------------------------------------------------------------------*
*&      Form  DEQUEUE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM dequeue.
  CALL FUNCTION 'DEQUEUE_/PSYNG/TABLE'
       EXPORTING
            tabname = '/PSYNG/SW_EXCDTX'.


ENDFORM.                    " DEQUEUE
*&---------------------------------------------------------------------*
*&      Form  COMPUTE_SCROLLING_IN_TC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0314   text
*      -->P_SY_UCOMM  text
*----------------------------------------------------------------------*
FORM compute_scrolling_in_tc USING   p_tc_name
                                      p_ok.
*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA l_tc_new_top_line     TYPE i.
  DATA l_tc_name             LIKE feld-name.
  DATA l_tc_lines_name       LIKE feld-name.
  DATA l_tc_field_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <lines>      TYPE i.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

* get looplines of TableControl
  CONCATENATE 'G_' p_tc_name '_LINES' INTO l_tc_lines_name.

  ASSIGN (l_tc_lines_name) TO <lines>. "#EC PATHLOCK_CI_DYN_ACCES
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
"(++)BOC UMITTAL SE VF scan-25/11/2024.
         EXCEPTIONS
              NO_ENTRY_OR_PAGE_ACT  = 1
              NO_ENTRY_TO           = 2
              NO_OK_CODE_OR_PAGE_GO = 3
              OTHERS                = 4.
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


ENDFORM.                    " COMPUTE_SCROLLING_IN_TC
*&---------------------------------------------------------------------*
*&      Form  FCODE_TC_MARK_LINES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0321   text
*      -->P_0322   text
*      -->P_0323   text
*----------------------------------------------------------------------*
FORM fcode_tc_mark_lines USING p_tc_name
                                 p_table_name
                                 p_mark_name .
*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA l_table_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <wa>.
  FIELD-SYMBOLS <mark_field>.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

* get the table, which belongs to the tc                               *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body

  ASSIGN (l_table_name) TO <table>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

  "not headerline

* demark all filled lines                                              *
  LOOP AT <table> ASSIGNING <wa>.

*   access to the component 'FLAG' of the table header                 *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    <mark_field> = space.
  ENDLOOP.

ENDFORM.                    " FCODE_TC_MARK_LINES


*&---------------------------------------------------------------------*
*&      Form  FCODE_TC_DEMARK_LINES
*&---------------------------------------------------------------------*
*       demarks all TableControl lines
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*----------------------------------------------------------------------*
FORM fcode_tc_demark_lines USING p_tc_name
                                 p_table_name
                                 p_mark_name .
*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA l_table_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <wa>.
  FIELD-SYMBOLS <mark_field>.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

* get the table, which belongs to the tc                               *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

"not headerline

* demark all filled lines                                              *
  LOOP AT <table> ASSIGNING <wa>.

*   access to the component 'FLAG' of the table header                 *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    <mark_field> = space.
  ENDLOOP.
ENDFORM.                                          "fcode_tc_mark_lines
