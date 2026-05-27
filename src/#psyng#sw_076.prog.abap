*----------------------------------------------------------------------*
* Report  /PSYNG/SW_076                                                *
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
REPORT /psyng/sw_076  .
TYPE-POOLS: slis.
************************************************************************
* DECLARATION OF DATA TYPE
************************************************************************
*  CDHDR
TYPES: BEGIN OF ty_cdhdr,
       objectclas TYPE cdhdr-objectclas,
       objectid TYPE cdhdr-objectid,
       changenr TYPE cdhdr-changenr,
       username TYPE cdhdr-username,
       udate TYPE cdhdr-udate,
       utime TYPE cdhdr-utime,
       END OF ty_cdhdr,

* CDPOS
       BEGIN OF ty_cdpos,
       objectclas TYPE cdpos-objectclas,
       objectid TYPE cdpos-objectid,
       changenr TYPE cdpos-changenr,
       tabname TYPE cdpos-tabname,
       tabkey(200) TYPE c,
       fname TYPE cdpos-fname,
       chngind TYPE cdpos-chngind,
       value_new TYPE cdpos-value_old,
       value_old TYPE cdpos-value_new,
       END OF ty_cdpos,



* FOR FINAL OUTPUT
       BEGIN OF ty_output,
       username TYPE cdhdr-username,
       userfull TYPE adrp-name_text,
       udate TYPE cdhdr-udate,
       utime TYPE cdhdr-utime,
       tabname TYPE cdpos-tabname,
       tab_desc TYPE dd02t-ddtext,
       tab_key(200) TYPE c,
       fd_name TYPE cdpos-fname,
       field_desc TYPE dd04t-ddtext,
       cng_id TYPE cdpos-chngind,
       old_val TYPE cdpos-value_old,
       new_val TYPE cdpos-value_new,
       END OF ty_output.

*GET TABLE DESCRIPTION
TYPES : BEGIN OF ty_dd02t,
        tabname TYPE dd02t-tabname,
        ddlanguage TYPE dd02t-ddlanguage,
        ddtext TYPE dd02t-ddtext,
        END OF ty_dd02t.

*GET FIELD DESCRITION
TYPES : BEGIN OF ty_dd03t,
        tabname TYPE dd03t-tabname,
        ddlanguage TYPE dd03t-ddlanguage,
        fieldname TYPE dd03t-fieldname,
        ddtext TYPE dd03t-ddtext,
        END OF ty_dd03t.


************************************************************************
*   DECLARATION OF INTERNAL TABLE AND WORK AREA
************************************************************************

DATA:    it_cdhdr TYPE STANDARD TABLE OF ty_cdhdr INITIAL SIZE 100,
         it_cdpos TYPE STANDARD TABLE OF ty_cdpos INITIAL SIZE 100,
         it_output TYPE STANDARD TABLE OF ty_output INITIAL SIZE 100,
        w_cdhdr TYPE ty_cdhdr,
        w_cdpos TYPE ty_cdpos,
        w_output TYPE ty_output.


DATA: gs_fcat1 TYPE slis_fieldcat_alv,
      it_fcat1 TYPE slis_t_fieldcat_alv.

DATA: w_lout1 TYPE slis_layout_alv.

DATA: l_sort TYPE slis_sortinfo_alv,
      isort  TYPE STANDARD TABLE OF slis_sortinfo_alv.

DATA: ls_variant TYPE disvariant.
ls_variant-report = sy-repid.



DATA: g_str1 TYPE string,
      g_str2 TYPE i,
      g_var TYPE /psyng/faobj2-vrsio.

************************************************************************
*   DECLARATION OF ranges
************************************************************************
RANGES : r_objid FOR cdhdr-objectid,
         r_funid FOR /psyng/faobj2-funid.

************************************************************************
*   DECLARATION OF GLOBAL DATA TYPES
************************************************************************
DATA: g_funid TYPE /psyng/faobj2-funid,
      g_cdate TYPE /psyng/faobj2-change_dat,
      g_ctime TYPE /psyng/faobj2-change_tim,
      g_cby TYPE /psyng/faobj2-change_usr.
DATA: w_objid LIKE LINE OF r_objid,
      w_funid LIKE LINE OF r_funid.

************************************************************************
*   DECLARATION SELECTION SCREEN
************************************************************************
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
PARAMETERS:       p_vrsio TYPE /psyng/faobj2-vrsio.
SELECT-OPTIONS:  s_funid FOR g_funid.
SELECT-OPTIONS:  s_cby FOR g_cby,
                 s_cdate FOR g_cdate,
                 s_ctime FOR g_ctime.

SELECTION-SCREEN END OF BLOCK b1.

************************************************************************
*   DECLARATION F1 HELP FOR SELECTION SCREEN FIELDS
************************************************************************
* For field Function ID
AT SELECTION-SCREEN ON HELP-REQUEST FOR s_funid.

  PERFORM show_help USING '/PSYNG/SW_076_FUNID'.

* For field Change User
AT SELECTION-SCREEN ON HELP-REQUEST FOR s_cby.

  PERFORM show_help USING '/PSYNG/SW_076_CHANGE_USR'.

* For field Change Date
AT SELECTION-SCREEN ON HELP-REQUEST FOR s_cdate.

  PERFORM show_help USING '/PSYNG/SW_076_CHANGE_DAT'.

* For field Change Time
AT SELECTION-SCREEN ON HELP-REQUEST FOR s_ctime.

  PERFORM show_help USING '/PSYNG/SW_076_CHANGE_TIM'.

************************************************************************
*  START OF SELECTION EVENT
************************************************************************
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
  LOOP AT s_funid INTO w_funid.
    MOVE-CORRESPONDING w_funid  TO w_objid.
    CONCATENATE w_funid-low '|*' INTO w_objid-low.
    IF NOT w_funid-high IS  INITIAL.
      CONCATENATE w_funid-high '|*' INTO w_objid-high.
    ENDIF.
    IF w_objid-option = 'EQ'.
      w_objid-option = 'CP'.
    ENDIF.
    IF w_objid-option = 'NE'.
      w_objid-option = 'NP'.
    ENDIF.
    APPEND w_objid TO r_objid.
  ENDLOOP.


* GET DATA FROM CDHDR AND CDPOS
  PERFORM sub_get_cdhdr.

* FILL FINAL OUTOUT INTERNAL TABLE
  PERFORM sub_fill_final_output.

* POPULATE FIELDCATLOG
  PERFORM sub_build_fcat.

* POPULATE SORTINFO
  PERFORM sub_fill_sort.

* DISPLAY OUTPUT USING ALV
  PERFORM sub_disp_output.

*&---------------------------------------------------------------------*
*&      Form  show_help
*&---------------------------------------------------------------------*
*       Show f1 help for fields
*----------------------------------------------------------------------*
*      -->I_DOKNAME  Document name
*----------------------------------------------------------------------*
FORM show_help USING    i_dokname.

  CALL FUNCTION '/PSYNG/BASIS_F1_HELP'
       EXPORTING
            dokname = i_dokname.

ENDFORM.                    " show_help

*&---------------------------------------------------------------------*
*&      Form  SUB_GET_CDHDR
*&---------------------------------------------------------------------*
* GET DATA FROM CDHDR AND CDPOS
*----------------------------------------------------------------------*
FORM sub_get_cdhdr.
  DATA : lt_pos TYPE TABLE OF cdshw WITH HEADER LINE,
         lt_cdhdr_func TYPE TABLE OF cdhdr,
         l_value_to TYPE string,
         l_value_from TYPE string,
         l_from_offset TYPE i,
         l_to_offset   TYPE i,
         l_from_len LIKE sy-tabix,
         l_to_len TYPE sy-tabix,
         l_pos TYPE sy-tabix.

* GET DATA FROM CDHDR
  SELECT objectclas
         objectid
         changenr
         username
         udate
         utime FROM cdhdr INTO TABLE it_cdhdr
         WHERE objectclas = '/PSYNG/FAOBJ'
         AND objectid IN r_objid
         AND username IN s_cby
         AND udate IN s_cdate
         AND utime IN s_ctime.

*Poulate Internal table it_cdhrd on vrsio field
  CLEAR w_cdhdr.
  LOOP AT it_cdhdr INTO w_cdhdr.
    g_str1  =  w_cdhdr-objectid.
    g_str2 = strlen( g_str1 ).
    g_str2 = g_str2 - 3.
    CLEAR g_var.
    g_var = g_str1+g_str2(3).

*   If the version isn't the same or more than the length of the field
*   is used then the version may not be in there.
    IF g_var <> p_vrsio AND g_str2 <> 87.
      DELETE it_cdhdr INDEX sy-tabix.
    ENDIF.
    CLEAR w_cdhdr.
  ENDLOOP.

* GET DATA FROM CDPOS
  LOOP AT it_cdhdr INTO w_cdhdr.
*   Call this function to populate SAP data to speed up next function
    CALL FUNCTION 'CHANGEDOCUMENT_READ_HEADERS'
         EXPORTING
              date_of_change             = w_cdhdr-udate
              time_of_change             = w_cdhdr-utime
              objectclass                = '/PSYNG/FAOBJ'
              objectid                   = w_cdhdr-objectid
              username                   = w_cdhdr-username
              date_until                 = w_cdhdr-udate
              time_until                 = w_cdhdr-utime
         TABLES
              i_cdhdr                    = lt_cdhdr_func
         EXCEPTIONS
              no_position_found          = 1
              wrong_access_to_archive    = 2
              time_zone_conversion_error = 3
              OTHERS                     = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

    CALL FUNCTION 'CHANGEDOCUMENT_READ_POSITIONS'
         EXPORTING
              changenumber            = w_cdhdr-changenr
         TABLES
              editpos                 = lt_pos
         EXCEPTIONS
              no_position_found       = 1
              wrong_access_to_archive = 2
              OTHERS                  = 3.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
    LOOP AT lt_pos.
      MOVE-CORRESPONDING lt_pos TO w_cdpos.
      w_cdpos-value_old = lt_pos-f_old.
      w_cdpos-value_new = lt_pos-f_new.
      w_cdpos-changenr = w_cdhdr-changenr.
      CHECK NOT w_cdpos-tabkey IS INITIAL AND NOT
       w_cdpos-tabkey(1) = ' '.
*     get value_to field from w_cdhdr.
      PERFORM get_value_to USING w_cdhdr CHANGING
      l_value_to
      l_value_from.

      l_from_len = strlen( l_value_from ).
      l_to_len = strlen( l_value_to ).
      l_from_offset = l_from_len + 54 + 1.
      l_pos = l_from_offset + l_to_len.
      IF  l_pos  LE 90.
        w_cdpos-tabkey+l_from_offset = l_value_to.
      ELSE.
        l_pos = 90 - ( l_from_offset + l_to_len ).
        IF l_pos > 0.
          w_cdpos-tabkey+l_from_offset = l_value_to(l_pos).
        ELSE.
          CHECK w_cdpos-tabkey+3(3) = p_vrsio.
          l_to_offset = 53 + l_from_len.
          w_cdpos-tabkey+53 = l_value_from.
          w_cdpos-tabkey+l_to_offset = l_value_to.
        ENDIF.
      ENDIF.
      APPEND w_cdpos TO it_cdpos.
    ENDLOOP.
    REFRESH : lt_pos[].
  ENDLOOP.
ENDFORM.                    " SUB_GET_CDHDR

*&---------------------------------------------------------------------*
*&      Form  SUB_FILL_FINAL_OUTPUT
*&---------------------------------------------------------------------*
*  SENDING DATA TO FINAL OUTPUT INTERNAL TABLE
*----------------------------------------------------------------------*
FORM sub_fill_final_output.



  CLEAR:w_cdpos.

  LOOP AT it_cdpos INTO w_cdpos .
    w_output-tabname = w_cdpos-tabname.



    w_output-tab_key = w_cdpos-tabkey.
    w_output-fd_name = w_cdpos-fname.
    w_output-cng_id =  w_cdpos-chngind.
    w_output-old_val = w_cdpos-value_old.
    w_output-new_val = w_cdpos-value_new.


* get table description
    PERFORM get_table_desc USING w_cdpos-tabname
                                 CHANGING w_output-tab_desc.
*get field description
    PERFORM get_field_desc USING w_cdpos-tabname
                                      w_cdpos-fname
                                CHANGING w_output-field_desc.

    CLEAR w_cdhdr.
 READ TABLE it_cdhdr INTO w_cdhdr WITH KEY changenr = w_cdpos-changenr .

* GET USERS FULL NAME
    PERFORM get_username USING w_cdhdr-username
                               CHANGING w_output-userfull.


    w_output-username = w_cdhdr-username.
    w_output-udate = w_cdhdr-udate.
    w_output-utime = w_cdhdr-utime.


    APPEND w_output TO it_output.
    CLEAR w_output.
  ENDLOOP.
ENDFORM.                    " SUB_FILL_FINAL_OUTPUT
*&---------------------------------------------------------------------*
*&      Form  SUB_BUILD_FCAT
*&---------------------------------------------------------------------*
*POPULATE  FIELDCATLOG
*----------------------------------------------------------------------*
FORM sub_build_fcat.
  PERFORM sub_fil_fcat1 USING: '1' 'USERNAME' 'User'(002) '' '',
                 '2' 'USERFULL' ' Complete Name'(003) '' '' ,
                 '3' 'UDATE' 'Date'(004) '' '',
                 '4' 'UTIME' 'Time'(005) '' '',
                  '5' 'TABNAME' 'Table Name'(006) 'X' '',
                  '6' 'TAB_DESC' 'Short Text'(007) '' '',
                  '7' 'TAB_KEY' 'Table Key'(008) 'X' '',
                  '8' 'FD_NAME' 'Field Name'(009) 'X' '',
                  '9' 'FIELD_DESC' 'Short Text'(010) '' '',
                  '10' 'CNG_ID' 'Change ID'(011) 'X' '',
                  '11' 'OLD_VAL' 'Old Value'(012) '' 'X',
                  '12' 'NEW_VAL' 'New Value'(013) '' 'X'.

ENDFORM.                    " SUB_BUILD_FCAT
*&---------------------------------------------------------------------*
*&      Form  SUB_FIL_FCAT1
*&---------------------------------------------------------------------*
* FILL FIELDCATLOG TABLE
*----------------------------------------------------------------------*
FORM sub_fil_fcat1 USING:  i_col_pos TYPE char2
                          i_fnam TYPE char30
                          i_seltext TYPE char30
                          i_key TYPE c
                          i_no_out TYPE c.

  gs_fcat1-col_pos = i_col_pos.
  gs_fcat1-fieldname = i_fnam.
  gs_fcat1-seltext_m = i_seltext.
  gs_fcat1-key = i_key.
 gs_fcat1-no_out = i_no_out.
  APPEND gs_fcat1 TO it_fcat1.
  CLEAR gs_fcat1.



ENDFORM.                    " SUB_FIL_FCAT1
*&---------------------------------------------------------------------*
*&      Form  SUB_DISP_OUTPUT
*&---------------------------------------------------------------------*
*  DISPALY THE OUTPUT IN ALV
*----------------------------------------------------------------------*
FORM sub_disp_output.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   EXPORTING
     i_callback_program                = sy-cprog
     is_layout                         = w_lout1
     it_fieldcat                       = it_fcat1
   it_sort                           = isort
   i_save                            = 'A'
   is_variant                        = ls_variant
    TABLES
      t_outtab                          = it_output
 EXCEPTIONS
   PROGRAM_ERROR                     = 1
   OTHERS                            = 2
            .
  IF sy-subrc <> 0.
 MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " SUB_DISP_OUTPUT


*---------------------------------------------------------------------*
*       FORM get_username                                             *
*---------------------------------------------------------------------*
* GET USERS FULL NAME
*---------------------------------------------------------------------*
FORM get_username USING    i_bname TYPE cdhdr-username
                  CHANGING e_name_text TYPE adrp-name_text.
  TYPES: BEGIN OF typ_user,
           bname     TYPE cdhdr-username,
           name_text TYPE adrp-name_text,
         END OF typ_user.

  STATICS: lt_user TYPE HASHED TABLE OF typ_user WITH UNIQUE KEY bname
                   WITH HEADER LINE.

  DATA: lt_uidn TYPE TABLE OF /psyng/bc_uidn WITH HEADER LINE.

  RANGES: lt_bname FOR /psyng/bc_uidn-bname.


  CLEAR e_name_text.
  READ TABLE lt_user WITH TABLE KEY bname = i_bname.
  IF sy-subrc = 0.
    e_name_text = lt_user-name_text.
    EXIT.
  ENDIF.

  lt_bname-sign   = 'I'.
  lt_bname-option = 'EQ'.
  lt_bname-low    = i_bname.
  APPEND lt_bname.
  CALL FUNCTION '/PSYNG/BC_011'
       TABLES
            it_bname = lt_bname
            et_uidn  = lt_uidn.

  SORT lt_uidn BY bname.
  READ TABLE lt_uidn INDEX 1 TRANSPORTING name_text.
  CHECK sy-subrc = 0.
  e_name_text       = lt_uidn-name_text.
  lt_user-bname     = i_bname.
  lt_user-name_text = e_name_text.
  INSERT TABLE lt_user.
ENDFORM.                    " get_username
*&---------------------------------------------------------------------*
*&      Form  SUB_FILL_SORT
*&---------------------------------------------------------------------*
* SORT FIELDS
*----------------------------------------------------------------------*
FORM sub_fill_sort.
  w_lout1-zebra =  'X'.
  w_lout1-colwidth_optimize = 'X'.

  l_sort-spos = '1'.
  l_sort-fieldname = 'USERNAME'.
  l_sort-tabname = 'IT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'USERFULL'.
  l_sort-tabname = 'IT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'UDATE'.
  l_sort-tabname = 'IT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '4'.
  l_sort-fieldname = 'UTIME'.
  l_sort-tabname = 'IT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.


  l_sort-spos = '5'.
  l_sort-fieldname = 'TABNAME'.
  l_sort-tabname = 'IT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '6'.
  l_sort-fieldname = 'TAB_DESC'.
  l_sort-tabname = 'IT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '7'.
  l_sort-fieldname = 'TAB_KEY'.
  l_sort-tabname = 'IT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

ENDFORM.                    " SUB_FILL_SORT

*&---------------------------------------------------------------------*
*&      Form  GET_TABLE_DESC
*&---------------------------------------------------------------------*
*     get table description
*----------------------------------------------------------------------*

FORM get_table_desc USING    i_tabname TYPE cdpos-tabname
                   CHANGING e_ddtext TYPE dd02t-ddtext.
  TYPES: BEGIN OF typ_tab,
             tabname TYPE cdpos-tabname,
             ddtext  TYPE dd02t-ddtext,
           END OF typ_tab.

  STATICS: lt_tab TYPE HASHED TABLE OF typ_tab WITH UNIQUE KEY tabname
                  WITH HEADER LINE.


  CLEAR e_ddtext.
  READ TABLE lt_tab WITH TABLE KEY tabname = i_tabname.
  IF sy-subrc = 0.
    e_ddtext = lt_tab-ddtext.
    EXIT.
  ENDIF.

  SELECT SINGLE ddtext              "#EC CI_SEL_NESTED
            INTO e_ddtext FROM dd02t
                WHERE tabname    = i_tabname
                  AND ddlanguage = sy-langu
                  AND as4local   = 'A'."#EC SAST_CI_GEN_CHECK

  CHECK sy-subrc = 0.

  lt_tab-tabname = i_tabname.
  lt_tab-ddtext  = e_ddtext.
  INSERT TABLE lt_tab.


ENDFORM.                    " GET_TABLE_DESC

*&---------------------------------------------------------------------*
*&      Form  get_field_desc
*&---------------------------------------------------------------------*
*       Get field description
*----------------------------------------------------------------------*
FORM get_field_desc USING    i_tabname TYPE cdpos-tabname
                            i_fname TYPE cdpos-fname
                   CHANGING e_ftext TYPE dd04t-ddtext.
  TYPES: BEGIN OF typ_fld,
           tabname TYPE cdpos-tabname,
           fname   TYPE cdpos-fname,
           ftext   TYPE dd04t-ddtext,
         END OF typ_fld.

  STATICS: lt_fld TYPE HASHED TABLE OF typ_fld
                  WITH UNIQUE KEY tabname fname
                  WITH HEADER LINE.


  CLEAR e_ftext.
  READ TABLE lt_fld WITH TABLE KEY tabname = i_tabname
                                   fname   = i_fname.
  IF sy-subrc = 0.
    e_ftext = lt_fld-ftext.
    EXIT.
  ENDIF.

* First, check if text was defined locally on the table
  SELECT SINGLE ddtext INTO e_ftext FROM dd03t     "#EC CI_SEL_NESTED
                WHERE tabname    = i_tabname
                  AND ddlanguage = sy-langu
                  AND as4local   = 'A'
                  AND fieldname  = i_fname."#EC SAST_CI_GEN_CHECK

  IF sy-subrc <> 0.
*   Next, check the data element
    SELECT SINGLE dd04t~ddtext INTO e_ftext "#EC CI_SEL_NESTED
             FROM dd03l INNER JOIN dd04t
               ON dd03l~rollname = dd04t~rollname
              AND dd03l~as4local = dd04t~as4local
            WHERE dd03l~tabname    = i_tabname
              AND dd03l~fieldname  = i_fname
              AND dd03l~as4local   = 'A'
              AND dd04t~ddlanguage = sy-langu."#EC SAST_CI_GEN_CHECK
  ENDIF.

  CHECK sy-subrc = 0.

  lt_fld-tabname = i_tabname.
  lt_fld-fname   = i_fname.
  lt_fld-ftext  = e_ftext.
  INSERT TABLE lt_fld.
ENDFORM.                    " get_field_desc
*&---------------------------------------------------------------------*
*&      Form  get_value_to
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_W_CDHDR  text
*      <--P_L_VALUE_TO  text
*----------------------------------------------------------------------*
FORM get_value_to USING    p_cdhdr TYPE ty_cdhdr
                  CHANGING p_value_to TYPE string
                           p_value_from TYPE string.

  DATA : lt_fields TYPE TABLE OF string,
         l_lines LIKE sy-tabix,
         l_length LIKE sy-tabix,
         l_line TYPE string.

  SPLIT p_cdhdr-objectid  AT '|' INTO TABLE lt_fields.
* the 5th field is value_to
  DESCRIBE TABLE lt_fields LINES l_lines.
  IF l_lines > 6.
    READ TABLE lt_fields INTO l_line INDEX 6.
    l_length = strlen( l_line ).
    IF l_length < 40.
      p_value_from = l_line.
    ELSE.
      p_value_from = l_line(40).
    ENDIF.

    READ TABLE lt_fields INTO l_line INDEX 7.
    l_length = strlen( l_line ).
    IF l_length < 40.
      p_value_to = l_line.
    ELSE.
      p_value_to = l_line(40).
    ENDIF.
  ENDIF.
ENDFORM.                    " get_value_to
