*----------------------------------------------------------------------*
* Report  /PSYNG/SW_SOD_BY_ORG                                         *
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
REPORT /psyng/sw_sod_by_org MESSAGE-ID /psyng/sw.
TYPE-POOLS : abap. "<NSINGH>++
TABLES : sscrfields,/psyng/sw_varel,/psyng/sw_varvr.
DATA : g_svrsio      TYPE /psyng/sodvrsio,
       g_tvrsio      TYPE /psyng/sodvrsio,
       gs_ssodvers   TYPE /psyng/swsodvers,
       gs_tsodvers   TYPE /psyng/swsodvers.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(20)  text-t02.
PARAMETERS: p_svrsio(3) TYPE c MEMORY ID /psyng/vrsio.
SELECTION-SCREEN COMMENT 35(20) text-t03.
PARAMETERS: p_tvrsio(3) TYPE c .
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN SKIP.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-t04.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN: PUSHBUTTON 1(60) text-t15 USER-COMMAND uc1.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_bukrs  AS CHECKBOX DEFAULT 'X' MODIF ID ro.
SELECTION-SCREEN COMMENT 3(30) text-t05.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_ekorg  AS CHECKBOX MODIF ID fld.
SELECTION-SCREEN COMMENT 3(30) text-t06.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_werks  AS CHECKBOX MODIF ID fld.
SELECTION-SCREEN COMMENT 3(30) text-t07.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_vkorg  AS CHECKBOX MODIF ID fld.
SELECTION-SCREEN COMMENT 3(30) text-t08.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
* Parameters: p_werks  as checkbox.
PARAMETERS: p_gsber  AS CHECKBOX MODIF ID fld.
SELECTION-SCREEN COMMENT 3(30) text-t09.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_spart  AS CHECKBOX MODIF ID fld.
SELECTION-SCREEN COMMENT 3(30) text-t10.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_vtweg  AS CHECKBOX MODIF ID fld.
SELECTION-SCREEN COMMENT 3(30) text-t11.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_kkber  AS CHECKBOX MODIF ID fld.
SELECTION-SCREEN COMMENT 3(30) text-t12.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_kokrs  AS CHECKBOX MODIF ID fld.
SELECTION-SCREEN COMMENT 3(30) text-t13.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN SKIP.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(30) text-t16.
PARAMETER : p_varelv  TYPE /psyng/ve_vrsio.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(30) text-t17.
PARAMETER : p_varelp  TYPE /psyng/se_varel
            DEFAULT '/PSYNG/$' MODIF ID ro.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(27) text-t18.
SELECT-OPTIONS : s_varelg  FOR /psyng/sw_varel-var_element
                 NO INTERVALS.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b1.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_svrsio.
  PERFORM f4_vrsio CHANGING p_svrsio.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_tvrsio.
  PERFORM f4_vrsio CHANGING p_tvrsio.

*--------------------------------------------------------------*
*At Selection-Screen Output
*--------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.
    IF screen-group1 = 'RO'.
      screen-input = ''.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

*--------------------------------------------------------------*
*At Selection-Screen
*--------------------------------------------------------------*
AT SELECTION-SCREEN.
  CLEAR : gs_ssodvers,gs_tsodvers.
  g_svrsio = p_svrsio.
  g_tvrsio = p_tvrsio.
  IF sscrfields-ucomm = 'UC1'.
    CLEAR :  p_ekorg,p_vkorg,p_werks,p_gsber,
             p_spart,p_vtweg,p_kkber,p_kokrs.

*****"Parse SOD Matrix

    PERFORM validate_version USING p_svrsio gs_ssodvers 'S'.

    IF NOT gs_ssodvers IS INITIAL.
      PERFORM parse_sod_matrix.
    ENDIF.
  ENDIF.

*--------------------------------------------------------------*
*Start-of-Selection
*--------------------------------------------------------------*
START-OF-SELECTION.

*BOC AKUMAR SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-25/11/2024

  PERFORM validations.

  PERFORM execute_conversion.

*---------------------------------------------------------------------*
*       FORM parse_sod_matrix                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM parse_sod_matrix.
  DATA : lt_tobj LIKE STANDARD TABLE OF tobj WITH HEADER LINE
  .
** Check if Target / Source SOD Matrix Versions are not empty/ not equal
  CALL FUNCTION '/PSYNG/SW_AO_002'
       EXPORTING
            i_sodvrsio       = g_svrsio
       TABLES
            et_tobj          = lt_tobj
       EXCEPTIONS
            version_no_exist = 1
            OTHERS           = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  IF lt_tobj[] IS INITIAL.
    MESSAGE s113 WITH
          'No valid Org Components found'(w01).
  ELSE.

    LOOP AT lt_tobj.
      CASE lt_tobj-fiel1.
        WHEN 'EKORG'.
          p_ekorg = 'X'.
        WHEN 'VKORG'.
          p_vkorg = 'X'.
        WHEN 'WERKS'.
          p_werks = 'X'.
        WHEN 'GSBER'.
          p_gsber = 'X'.
        WHEN 'SPART'.
          p_spart = 'X'.
        WHEN 'VTWEG'.
          p_vtweg = 'X'.
        WHEN 'KKBER'.
          p_kkber = 'X'.
        WHEN 'KOKRS'.
          p_kokrs = 'X'.
      ENDCASE.
    ENDLOOP.

  ENDIF.
ENDFORM.


*---------------------------------------------------------------------*
*       FORM f4_vrsio                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  E_VRSIO                                                       *
*---------------------------------------------------------------------*
FORM f4_vrsio CHANGING e_vrsio TYPE char3 .

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF help_value  WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_vrsio TYPE TABLE OF /psyng/swsodvers WITH HEADER LINE.


  SELECT vrsio vdesc FROM /psyng/swsodvers
  INTO CORRESPONDING FIELDS OF TABLE lt_vrsio.

  SORT lt_vrsio BY vrsio ASCENDING.

  REFRESH: lt_fields, lt_values.
  lt_fields-tabname   = '/PSYNG/SWSODVERS'.
  lt_fields-fieldname = 'VRSIO'.
  lt_fields-selectflag = 'X'.
  APPEND lt_fields.

  lt_fields-fieldname = 'VDESC'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  LOOP AT lt_vrsio.
    lt_values-line = lt_vrsio-vrsio.
    APPEND lt_values.
    lt_values-line = lt_vrsio-vdesc.
    APPEND lt_values.
  ENDLOOP.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
       EXPORTING
            titel                     = text-t15
       IMPORTING
            select_value              = e_vrsio
       TABLES
            fields                    = lt_fields
            valuetab                  = lt_values
       EXCEPTIONS
            field_not_in_ddic         = 1
            more_then_one_selectfield = 2
            no_selectfield            = 3
            OTHERS                    = 4.
  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  .

ENDFORM.                                                    " f4_vrsio

*---------------------------------------------------------------------*
*       FORM Validate_version                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM validate_version USING i_sodvrsio es_sodvers i_type.
  DATA : ls_sodvers TYPE /psyng/swsodvers.
  IF i_sodvrsio = space.
    SET CURSOR FIELD p_svrsio.
    CASE i_type.
      WHEN 'S'. "Source
        MESSAGE s002 WITH
        'Please Enter Source SOD version'(e01).
      WHEN 'T'. "Target
        MESSAGE s002 WITH
        'Please Enter Target SOD version'(e02).
    ENDCASE.
    LEAVE LIST-PROCESSING.
  ELSEIF NOT i_sodvrsio CO '1234567890 '.
    CASE i_type.
      WHEN 'S'. "Source
        SET CURSOR FIELD p_svrsio.
        MESSAGE s002 WITH
        'Please Enter Valid Source SOD version'(e03).
      WHEN 'T'. "Target
        SET CURSOR FIELD p_tvrsio.
        MESSAGE s002 WITH
        'Please Enter Valid Target SOD version'(e04).
    ENDCASE.
    LEAVE LIST-PROCESSING.
  ELSE.
    CASE i_type.
      WHEN 'S'. "Source
        SELECT SINGLE * FROM /psyng/swsodvers INTO es_sodvers
                WHERE vrsio = g_svrsio.
        IF sy-subrc NE 0.
          MESSAGE s106 WITH text-e07 i_sodvrsio.
          LEAVE LIST-PROCESSING.
          EXIT.
        ENDIF.
      WHEN 'T'. "Target
        SELECT SINGLE * FROM /psyng/swsodvers INTO es_sodvers
                WHERE vrsio = g_tvrsio.
        IF sy-subrc NE 0.
          SELECT SINGLE * FROM /psyng/swsodvers INTO ls_sodvers
                         WHERE vrsio = g_svrsio.
          ls_sodvers-vrsio = g_tvrsio.
          ls_sodvers-noedit = abap_false. "<NSINGH>++
          MODIFY /psyng/swsodvers FROM ls_sodvers.
          CLEAR ls_sodvers. "<NSINGH>++
        ENDIF.
    ENDCASE.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  validations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM validations.

  PERFORM validate_version USING p_svrsio gs_ssodvers 'S'.

  PERFORM validate_version USING p_tvrsio gs_tsodvers 'T'.
  IF gs_tsodvers-noedit = 'X'.
    MESSAGE s013 WITH p_tvrsio.
    LEAVE LIST-PROCESSING.
  ENDIF.

****** Validate Variable Element Version
  IF p_varelv IS INITIAL.
    MESSAGE s002 WITH
         'Please Enter Variable Element Version'(e12).
    SET CURSOR FIELD p_varelv.
    LEAVE LIST-PROCESSING.
  ELSEIF p_varelp IS INITIAL.
    MESSAGE s002 WITH
           'Please Enter Variable Element Prefix'(e13).
    LEAVE LIST-PROCESSING.
  ELSEIF s_varelg IS INITIAL.
    MESSAGE s002 WITH
           'Please Enter Variable Element Group'(e14).
    SET CURSOR FIELD s_varelg.
    LEAVE LIST-PROCESSING.
  ELSEIF NOT p_varelv IS INITIAL.
    SELECT SINGLE * FROM /psyng/sw_varvr
            WHERE varel_vrsio = p_varelv.
    IF sy-subrc NE 0.
      MESSAGE s002 WITH
          'Invalid Variable Element Version'(e15).
      SET CURSOR FIELD p_varelv.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.


ENDFORM.                    " validations
*&---------------------------------------------------------------------*
*&      Form  execute_conversion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM execute_conversion.
  DATA : lv_answer(1)       TYPE c.
  DATA : lv_error           TYPE bapiflagx,
         lv_msg1            TYPE symsgv,
         lv_msg2            TYPE symsgv,
         lv_msg3            TYPE symsgv,
         lv_msg4            TYPE symsgv.

  DATA : lt_var_element_group LIKE STANDARD TABLE OF /psyng/orgfield
                                                  WITH HEADER LINE,
         lt_fields            LIKE STANDARD TABLE OF /psyng/orgfield
                                                  WITH HEADER LINE,
         lt_functions         LIKE STANDARD TABLE OF /psyng/function
                                                  WITH HEADER LINE,
         lt_conflicts         LIKE STANDARD TABLE OF /psyng/conflict
                                                  WITH HEADER LINE.

****** Variable Element Groups
  LOOP AT s_varelg.
    lt_var_element_group-field = s_varelg-low.
    APPEND lt_var_element_group.
  ENDLOOP.

*****" Getting Selected Fields.
  IF p_bukrs = 'X'.
    lt_fields-field = 'BUKRS'.
    APPEND lt_fields.
  ENDIF.
  IF p_ekorg = 'X'.
    lt_fields-field = 'EKORG'.
    APPEND lt_fields.
  ENDIF.
  IF p_vkorg = 'X'.
    lt_fields-field = 'VKORG'.
    APPEND lt_fields.
  ENDIF.
  IF p_werks = 'X'.
    lt_fields-field = 'WERKS'.
    APPEND lt_fields.
  ENDIF.
  IF p_gsber = 'X'.
    lt_fields-field = 'GSBER'.
    APPEND lt_fields.
  ENDIF.
  IF p_spart = 'X'.
    lt_fields-field = 'SPART'.
    APPEND lt_fields.
  ENDIF.
  IF p_vtweg = 'X'.
    lt_fields-field = 'VTWEG'.
    APPEND lt_fields.
  ENDIF.
  IF p_kkber = 'X'.
    lt_fields-field = 'KKBER'.
    APPEND lt_fields.
  ENDIF.
  IF p_kokrs = 'X'.
    lt_fields-field = 'KOKRS'.
    APPEND lt_fields.
  ENDIF.

  CALL FUNCTION '/PSYNG/SW_051'
    EXPORTING
      i_vrsio                 = g_tvrsio
* IMPORTING
*   ES_SWSODVERS            =
   TABLES
     et_function             = lt_functions
     et_conflict             = lt_conflicts
 EXCEPTIONS
   VERSION_NOT_EXIST       = 1
   OTHERS                  = 2.
  IF sy-subrc <> 0.
 MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.


  IF NOT lt_functions[] IS INITIAL
  OR NOT lt_conflicts[] IS INITIAL.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
         EXPORTING
              titlebar              = 'Overwrite Confirmation'(t20)
              text_question         =
 'Target SOD Version already contains Functions or Conflicts.'(t21)
              text_button_1         = 'Overwrite'(t22)
              icon_button_1         = 'ICON_CHECKED'
              text_button_2         = 'Cancel'(t23)
              icon_button_2         = 'ICON_INCOMPLETE'
              default_button        = '1'
              display_cancel_button = space
         IMPORTING
              answer                = lv_answer
         EXCEPTIONS
              text_not_found        = 1
              OTHERS                = 2.
*BOC:HBHALLA (04/12/24)
        IF sy-subrc <> 0.
       CASE sy-subrc.
         WHEN 1.
            MESSAGE s002(/psyng/sw) WITH 'Diagnosis text not found'.
         WHEN OTHERS.
            MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
       ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)
  ELSE.
    lv_answer = '1'.
  ENDIF.

  IF lv_answer = '1'.
    CALL FUNCTION '/PSYNG/SW_SOD_BY_ORG'
         EXPORTING
              i_source_vrsio        = g_svrsio
              i_target_vrsio        = g_tvrsio
              i_var_element_prefix  = p_varelp
              i_var_element_version = p_varelv
         IMPORTING
              e_error               = lv_error
              e_msg1                = lv_msg1
              e_msg2                = lv_msg2
              e_msg3                = lv_msg3
              e_msg4                = lv_msg4
         TABLES
              it_var_element_group  = lt_var_element_group
              it_fields             = lt_fields.
    IF sy-subrc = 0.
      IF NOT lv_error IS INITIAL.
        MESSAGE e002 WITH lv_msg1 lv_msg2 lv_msg3 lv_msg4.
      ELSE.
        MESSAGE s002 WITH
               'SOD Conversion Successful'(s01).
      ENDIF.
    ELSE.
      MESSAGE e002 WITH
             'SOD Conversion failed'(e11).
    ENDIF.
  ENDIF.

ENDFORM.                    " execute_conversion
