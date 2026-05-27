*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_UTLS5F01.
*----------------------------------------------------------------------*
FORM set_default_sodversion
  USING l_sod TYPE /psyng/swsodvers-vrsio
        l_uname TYPE sy-uname
        i_delete TYPE sy-subrc  .
  DATA: lt_param  TYPE TABLE OF bapiparam WITH HEADER LINE,
        lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE,
        ls_paramx TYPE bapiparamx.


  SELECT parid parva INTO TABLE lt_param FROM usr05  "#EC CI_SEL_NESTED
          WHERE bname = l_uname.

  READ TABLE lt_param WITH KEY parid = '/PSYNG/VRSIO'.
  lt_param-parva = l_sod.

  IF sy-subrc = 0.
    MODIFY lt_param INDEX sy-tabix.
  ELSE.
    lt_param-parid = '/PSYNG/VRSIO'.
    APPEND lt_param.
  ENDIF.
  IF i_delete <> 0.
    DELETE lt_param WHERE parid = '/PSYNG/VRSIO'.
  ENDIF.

  ls_paramx-parid = 'X'.
  ls_paramx-parva = 'X'.
  CALL FUNCTION 'BAPI_USER_CHANGE' "#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
      username   = l_uname
      parameterx = ls_paramx
    TABLES
      parameter  = lt_param
      return     = lt_return.

ENDFORM.                    " set_default_sodversion

*---------------------------------------------------------------------*
*       FORM get_default_sodversion                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  L_UNAME                                                       *
*  -->  E_SOD                                                         *
*---------------------------------------------------------------------*
FORM get_default_sodversion
  USING    l_uname TYPE sy-uname
  CHANGING e_sod TYPE  /psyng/swsodvers-vrsio
           e_exists TYPE sy-subrc.
  DATA : l_parva        TYPE usr05-parva.
  CLEAR e_exists.

*-- Get user's default version
  SELECT SINGLE parva INTO l_parva FROM usr05
             WHERE bname = l_uname
               AND parid = '/PSYNG/VRSIO'.
  e_exists = sy-subrc.
  IF e_exists = 0 AND l_parva <> space.
    e_sod = l_parva.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_RISK_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_ID  text
*      <--P_E_TITLE  text
*      <--P_E_MESSAGE  text
*----------------------------------------------------------------------*
FORM get_risk_info  USING    i_id
                    CHANGING e_title
                             e_message.
  e_title  = 'Risk Scenario'(001).
  DATA : l_risktext     LIKE /psyng/sw_risk-text.
  SELECT SINGLE text INTO l_risktext FROM /psyng/sw_risk
                      WHERE risk = i_id.
  IF sy-subrc = 0.
    e_message = l_risktext.
  ENDIF.

ENDFORM.
FORM execute_tcode_popup
    USING
      i_tcode     TYPE tstct-tcode
      i_screen_id TYPE /psyng/user_right
      if_non_abap TYPE flag
      i_appl      TYPE /psyng/application
      i_system    TYPE /psyng/system
    CHANGING
        tcode_not_found TYPE flag.
  DATA: line(80),
        l_nonabap_tcode_desc TYPE /psyng/longtextfield,
        answer,
        l_tcode         TYPE xutcode,
        l_screen_id     TYPE /psyng/user_right,
        lf_en_installed TYPE flag,
        lt_string TYPE TABLE OF swastrtab WITH HEADER LINE,
        l_msg1 TYPE c LENGTH 50,
        l_msg2 TYPE c LENGTH 50,
        l_message TYPE string.
  CONSTANTS :
        l_table_en(20)  TYPE c VALUE '/PSYNG/EX_URHDR'.
  l_tcode = i_tcode.
  IF if_non_abap IS INITIAL OR i_appl = 'SAP'.
*BOC UMITTAL ATC check SIEMENS 11/02/25
*    SELECT ttext FROM tstct INTO line
*         WHERE sprsl = sy-langu AND tcode = i_tcode.
*      EXIT.
*    ENDSELECT.

    SELECT ttext FROM tstct INTO line
         WHERE sprsl = sy-langu AND tcode = l_tcode.
      EXIT.
    ENDSELECT.
*EOC UMITTAL ATC check SIEMENS 11/02/25
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = l_tcode
        text_question         = line
*       text_button_1         = text-121
        text_button_1         = 'Execute'(121)
        icon_button_1         = 'ICON_EXECUTE_OBJECT'
        text_button_2         = 'Cancel'(122)
        icon_button_2         = 'ICON_SYSTEM_CANCEL'
        default_button        = '2'
        display_cancel_button = ' '
      IMPORTING
        answer                = answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND       = 1
             OTHERS               = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

    CHECK answer = '1'.
    AUTHORITY-CHECK OBJECT 'S_TCODE'
             ID 'TCD' FIELD l_tcode.
    IF sy-subrc = 0.
      SELECT SINGLE tcode FROM tstc INTO l_tcode
        WHERE tcode = l_tcode .
      IF sy-subrc = 0.
*BOC UMITTAL CVA FIXES 11/03/2026
    CALL METHOD /psyng/sw_dynamic_select=>dynamic_call_txn
      EXPORTING
        i_tcode =  l_tcode .
*        CALL TRANSACTION l_tcode."#EC PATHLOCK_CI_DYN_ACCES
*EOC UMITTAL CVA FIXES 11/03/2026
      ELSE.
        MESSAGE s398(00) WITH
          'Transaction does not exist.'(086).
        tcode_not_found = 'X'.
      ENDIF.
    ELSE.
      MESSAGE s398(00) WITH
      'Not authorized to run transaction'(085).
    ENDIF.
  ELSE.
        l_screen_id = i_screen_id.
    CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
      EXPORTING
        i_module    = 'EN'
      IMPORTING
        e_installed = lf_en_installed.
    IF lf_en_installed = 'X'.
      SELECT SINGLE udesc FROM (l_table_en) "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
      INTO l_nonabap_tcode_desc
      WHERE usrrt = l_screen_id"l_tcode
            AND appl = i_appl
            AND
            (
              ( sysid = i_system AND sysdep = 'X' )
              OR
              ( sysid = 'ALL' AND sysdep <> 'X' )
            )
            .
*      CONCATENATE ':' l_nonabap_tcode_desc INTO l_nonabap_tcode_desc
*      SEPARATED BY space.
*      l_message = l_nonabap_tcode_desc.
*      CALL FUNCTION 'SWA_STRING_SPLIT'
*        EXPORTING
*          input_string                      = l_message
*         max_component_length               = 40
*         terminating_separators             = ' '
*        TABLES
*          string_components                 = lt_string.
*
*      READ TABLE lt_string INDEX 1.
*      IF sy-subrc IS INITIAL.
*        l_msg1 = lt_string-str.
*      ENDIF.
*      READ TABLE lt_string INDEX 2.
*      IF sy-subrc IS INITIAL.
*        l_msg2 = lt_string-str.
*      ENDIF.
*      MESSAGE i113(/psyng/sw)
*      WITH l_tcode l_msg1 l_msg2.
       CALL FUNCTION 'POPUP_TO_INFORM'
         EXPORTING
           titel         = 'Screen ID and Description'
           txt1          = l_screen_id
           txt2          = l_nonabap_tcode_desc(80)
           txt3          = l_nonabap_tcode_desc+80(80)
           txt4          = l_nonabap_tcode_desc+160(80).
    ENDIF.
  ENDIF.
ENDFORM.
