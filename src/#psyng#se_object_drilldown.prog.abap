REPORT /psyng/se_object_drilldown.


PARAMETERS :
  name     TYPE char100 LOWER CASE,
  r_object TYPE flag RADIOBUTTON GROUP g1,
  r_field  TYPE flag RADIOBUTTON GROUP g1,
  r_role   TYPE flag RADIOBUTTON GROUP g1,
  r_user   TYPE flag RADIOBUTTON GROUP g1,
  r_profi  TYPE flag RADIOBUTTON GROUP g1,
  r_value  TYPE flag RADIOBUTTON GROUP g1,
  r_tcode  TYPE flag RADIOBUTTON GROUP g1,
  p_startd TYPE dats,
  p_endd   TYPE dats,
  p_appl   TYPE /psyng/application DEFAULT 'SAP',
  p_sys    TYPE /psyng/system,
  p_rfc    TYPE rfcdest,
  p_object TYPE xuobject,
  p_field  TYPE xufield,
  p_funid  TYPE /psyng/function_id,
  p_vrsio  TYPE /psyng/sodvrsio,
  cfgset   type  /psyng/seconfid.
CONSTANTS: gc_service  TYPE xuobject VALUE 'S_SERVICE',
           gc_srv_name TYPE xufield  VALUE 'SRV_NAME',
           c_fname_get_key_val TYPE rs38l_fnam VALUE '/PSYNG/EN_GET_REF_VAL'.


TYPES:
  BEGIN OF typ_ref01,
    ref_key   TYPE /psyng/ref_key,
    key_val   TYPE /psyng/key_val,
    key_index TYPE i,
  END OF typ_ref01.

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
  CASE 'X'.
    WHEN r_object.
      PERFORM show_object USING name.
    WHEN r_field.
      PERFORM show_field USING name.
    WHEN r_role.
      PERFORM show_role USING name.
    WHEN r_user.
      PERFORM show_user USING name.
    WHEN r_profi.
      PERFORM show_profi USING name.
    WHEN r_value.
      PERFORM show_value USING name.
    WHEN r_tcode.
      PERFORM show_tcode USING name.
  ENDCASE.


FORM show_object  USING    p_name.
  DATA : l_object LIKE tobj-objct,
          lt_elements_value TYPE TABLE OF typ_ref01 with HEADER LINE,
          ls_element_value TYPe typ_ref01,
          l_ref_key   TYPE /psyng/ref_key,
          l_key_value TYPE /psyng/key_val.
  if p_APPL = 'SAP'.
    CONDENSE p_name.
    l_object = p_name.
    AUTHORITY-CHECK OBJECT 'S_USER_AUT'
         ID 'OBJECT' FIELD l_object
*         ID 'AUTH' FIELD '__________'
         ID 'AUTH' FIELD '' "(++)BOC UMITTAL SE VF scan-25/11/2024
         ID 'ACTVT' FIELD '03'.


IF sy-subrc <> 0.
  MESSAGE e108(/psyng/sw) WITH 'Display Authorization Object Documentation'(e01).
else.
    CALL FUNCTION 'SUSR_SHOW_OBJECT'
        EXPORTING
          object  = l_object
          eu_mode = ' '.

endif.
else.
" start of changes by kamalpreet for C1279.
     SPLIT p_name AT space INTO l_ref_key l_key_value.
*--get key values for field
    CALL FUNCTION '/PSYNG/BC_FUNCTION_EXISTS'
      EXPORTING
        funcname           = c_fname_get_key_val
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc EQ 0.
       lt_elements_value-ref_key = l_ref_key.
       APPEND lt_elements_value.
       CALL FUNCTION '/PSYNG/EN_GET_REF_VAL' "HBHALLA
         EXPORTING
           i_tabname              =  '/PSYNG/EX_REF03'
         TABLES
           it_key                 =  lt_elements_value.
       READ TABLE lt_elements_value.
       CALL FUNCTION 'POPUP_TO_INFORM'
         EXPORTING
           titel         = 'Field Key & Value'
           txt1          = lt_elements_value-ref_key
           txt2          = lt_elements_value-key_val(80)
           txt3          = lt_elements_value-key_val+80(80)
           txt4          = lt_elements_value-key_val+160(80).
    ENDIF.
   ENDIF.
  " end of changes by kamalpreet for C1279.


ENDFORM.

FORM show_field  USING    p_name.
  DATA : l_field   LIKE authx-fieldname,
         ls_dfies  TYPE dfies,
         l_tabname TYPE tabname,
         lt_fields_value TYPE TABLE OF typ_ref01
           WITH HEADER LINE,
         lines     type table of TLINE,
         l_ref_key   TYPE /psyng/ref_key,
         l_key_value TYPE /psyng/key_val.
  CONDENSE p_name.
  IF p_appl EQ 'SAP'.
  l_field = p_name.

  SELECT SINGLE * FROM authx INTO CORRESPONDING FIELDS OF ls_dfies
           WHERE fieldname = l_field.
  l_tabname = ls_dfies-checktable.
CALL FUNCTION 'HELP_OBJECT_SHOW'
  EXPORTING
    dokclass                            = 'DE'
    dokname                             = ls_dfies-rollname
   CLASSIC_SAPSCRIPT                   = 'X'
  TABLES
    links                               = lines
 EXCEPTIONS
   OBJECT_NOT_FOUND                    = 1
   SAPSCRIPT_ERROR                     = 2
   OTHERS                              = 3
          .
IF sy-subrc <> 0.
* Implement suitable error handling here
ENDIF.
  ELSE.
    SPLIT p_name AT space INTO l_ref_key l_key_value.
*--get key values for field
    CALL FUNCTION '/PSYNG/BC_FUNCTION_EXISTS'
      EXPORTING
        funcname           = c_fname_get_key_val
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc EQ 0.
       lt_fields_value-ref_key = l_ref_key.
       APPEND lt_fields_value.
       CALL FUNCTION '/PSYNG/EN_GET_REF_VAL' "HBHALLA
         EXPORTING
           i_tabname              =  '/PSYNG/EX_REF02'
         TABLES
           it_key                 =  lt_fields_value.
       READ TABLE lt_fields_value.
       CALL FUNCTION 'POPUP_TO_INFORM'
         EXPORTING
           titel         = 'Field Key & Value'
           txt1          = lt_fields_value-ref_key
           txt2          = lt_fields_value-key_val(80)
           txt3          = lt_fields_value-key_val+80(80)
           txt4          = lt_fields_value-key_val+160(80).
    ENDIF.
  ENDIF.

ENDFORM.

FORM show_role  USING    p_name.
  DATA : l_agr_name TYPE agr_name,
         answer     TYPE c,
         lf_onlyrem TYPE FLAG,
         l_rfcdest  type rfcdest,
         l_rolid type /pSYNG/EX_ROLHDR_ST-ROLID,
         ls_role_value type /PSYNG/EX_ROLID_VALUE.
  l_agr_name = p_name.
  CHECK p_name <> space.

  l_agr_name = p_name.
  IF p_appl <> 'SAP'.

* -- 2022/01/06 Odubey SE-EN
    l_rolid = p_name.
      CALL FUNCTION '/PSYNG/SW_CR_READ_ROLES_EN'
        EXPORTING
          i_rolid                         = l_rolid
          i_appl                          = P_appl
          i_sysid                         = p_sys
       IMPORTING
         ES_ROLID_VALUE                  = ls_role_value
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             SOURCE_ROLID_DOESNT_EXIST = 1
             NOT_AUTHORIZED_TO_DISPLAY = 2
             OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
*    CONCATENATE ls_role_value-ROLID ':' ls_role_value-KEY_VAL into
*     l_rolid SEPARATED BY space.

    CLEAR answer.
    CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
      EXPORTING
        defaultoption     = '1'
        diagnosetext1     = l_rolid
        diagnosetext2     = ls_role_value-KEY_VAL
       diagnosetext3      = ls_role_value-RDESC
        textline1         = 'You can perform SOD analysis on this role.'(m07)
*        TEXTLINE2         =
        TEXTLINE3         = 'Do you want to do SOD Analysis on the Role?'(m08)
        text_option1      = 'SOD Analysis'(m09)
        text_option2      = 'Cancel'(m10)
        icon_text_option1 = 'ICON_CHECK'
        icon_text_option2 = 'ICON_SYSTEM_CANCEL'
        titel             = 'SOD Analysis'
        cancel_display    = ''
      IMPORTING
        answer            = answer.
    CASE answer.
      WHEN '1'.

        PERFORM role_sod_analysis_en_detail(/psyng/sodreport_org)
          USING l_agr_name
                p_rfc
                p_appl
                p_vrsio.
      WHEN '2'.
        EXIT.
    ENDCASE.
  ELSE.
    CLEAR answer.
    CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
      EXPORTING
        defaultoption     = '1'
        diagnosetext1     = l_agr_name
        diagnosetext2     = 'You can display this role in transaction PFCG or'(m11)
        diagnosetext3     = 'You can perform SOD analysis on this role.'(m07)
        textline1         = 'Display role or perform SOD analysis on this role?'(m12)
        text_option1      = 'Display Role'(m13)
        text_option2      = 'SOD Analysis'(m09)
        icon_text_option1 = 'ICON_DISPLAY'
        icon_text_option2 = 'ICON_CHECK'
        titel             = 'Display role or perform SOD check'(m14)
        cancel_display    = 'X'
      IMPORTING
        answer            = answer.

    CASE answer.
      WHEN '1'.
        PERFORM display_role_in_pfcg(/psyng/sodreport_org)
          USING l_agr_name.
      WHEN '2'.
*        PERFORM role_sod_analysis_from_details(/psyng/sodreport_org)
*          USING l_agr_name
*                p_rfc.
          concatenate sy-sysid sy-mandt into l_rfcdest.
          if not p_rfc is initial and p_rfc <> l_rfcdest.
            lf_onlyrem  = 'X'.
*--Lookup the rfc destination
            select single rfcdest into l_rfcdest from /psyng/sw_rfcdes where systid =  p_rfc.
          else.
             clear :  l_rfcdest, lf_onlyrem.
          endif.
          SUBMIT /psyng/sod_syswide_byrole
            WITH role      = l_agr_name
            WITH sodvrsio  = p_vrsio
            WITH cfgset    = cfgset
            WITH remrfc    = l_rfcdest
            WITH ronlyrem  = lf_onlyrem
            AND RETURN.

    ENDCASE.
  ENDIF.
ENDFORM.

FORM show_user  USING    p_name.
  DATA : answer  TYPE c,
         l_bname TYPE xubname.
  l_bname = p_name.
*  IF NOT p_startd IS INITIAL AND NOT p_endd IS INITIAL.
*--Allow user to choose between user history and SU01 display
    CLEAR answer.
    CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
      EXPORTING
        defaultoption     = '1'
        diagnosetext1     = 'You can view User Master Record (in transaction SU01) or'(m01)
        diagnosetext2     = 'view user''s transaction code execution history'(m02)
        textline1         = 'View user master or history?'(m03)
        text_option1      = 'User Master'(m04)
        text_option2      = 'User History'(m05)
        icon_text_option1 = 'ICON_TBH'
        icon_text_option2 = 'ICON_HISTORY'
        titel             = 'User Master or Transaction History'(m06)
        cancel_display    = 'X'
      IMPORTING
        answer            = answer.
*  ELSE.
*    answer = '1'.
*  ENDIF.
  CASE answer.
    WHEN '1'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU01'.
      IF sy-subrc <> 0.
        AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU01D'.
        IF sy-subrc <> 0.
          MESSAGE e077(s#) WITH 'SU01D'.
        ELSE.
          SET PARAMETER ID 'XUS' FIELD l_bname.
          CALL TRANSACTION 'SU01D'  AND SKIP FIRST SCREEN.
        ENDIF.
      ELSE.
        SET PARAMETER ID 'XUS' FIELD l_bname.
        CALL TRANSACTION 'SU01'  AND SKIP FIRST SCREEN.
      ENDIF.
    WHEN '2'.
      PERFORM show_user_tcode_history(/psyng/sodreport_org)
        USING l_bname '' p_startd p_endd.
  ENDCASE.
ENDFORM.

FORM show_profi  USING    p_name.
  DATA : l_prof TYPE xuprofile.
  l_prof = p_name.
  AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU02'.
  IF sy-subrc <> 0.
    MESSAGE e077(s#) WITH 'SU02'.
  ELSE.
    SET PARAMETER ID 'XUP' FIELD l_prof.
    CALL TRANSACTION 'SU02'.
  ENDIF.
ENDFORM.

FORM show_value  USING    p_name.
  DATA : l_value     TYPE xupname,
         l_val       TYPE xuvalue,
         l_tabname   TYPE tabname,
         l_fieldname TYPE fieldname,
         ls_tactt    TYPE tactt,
         ls_dfies    TYPE dfies,
         l_textline1 TYPE string,
         l_textline2 TYPE string,
         lt_values   TYPE TABLE OF ddshretval WITH HEADER LINE,
          lt_action_value type table of typ_ref01,
         ls_action_value type typ_ref01,
         l_ref_key   TYPE /psyng/ref_key,
         l_key_value TYPE /psyng/key_val.
  l_value = p_name.
  l_val   = p_name.

  if p_appl <> 'SAP'.

    SPLIT p_name AT space INTO l_ref_key l_key_value.
*--get key values for VALUE_FROM
    CALL FUNCTION '/PSYNG/BC_FUNCTION_EXISTS'
      EXPORTING
        funcname           = c_fname_get_key_val
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc EQ 0.
       ls_action_value-ref_key = l_ref_key.
       APPEND ls_action_value to lt_action_value.
       CALL FUNCTION c_fname_get_key_val "#EC PATHLOCK_CI_DYN_ACCES
         EXPORTING
           i_tabname              =  '/PSYNG/EX_REF04'
         TABLES
           it_key                 =  lt_action_value.
       READ TABLE lt_action_value into ls_action_value index 1.
       CALL FUNCTION 'POPUP_TO_INFORM'
         EXPORTING
           titel         = 'Value From Key & Actual Value'
           txt1          = ls_action_value-ref_key
           txt2          = ls_action_value-key_val(80)
           txt3          = ls_action_value-key_val+80(80)
           txt4          = ls_action_value-key_val+160(80).
    ENDIF.


  ELSE.

  IF  p_object EQ  gc_service
        AND p_field  EQ gc_srv_name.
*        l_hashcode = outputdet4-bis.
*--Displays a popup with the name of the Odata Service
    CALL FUNCTION '/PSYNG/SW_ODATA_TEXT'
      EXPORTING
        i_hashcode      = l_value
        if_show_message = 'X'
      EXCEPTIONS
        not_found       = 1
        OTHERS          = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ELSE.
    CALL FUNCTION '/PSYNG/SW_AUTH_VALUE_TEXT'
      EXPORTING
        i_object        = p_object
        i_field         = p_field
        i_value         = l_val
        if_show_message = 'X'.

  ENDIF.
 endif.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SHOW_TCODE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_NAME  text
*----------------------------------------------------------------------*
FORM show_tcode  USING    p_name.
  DATA : lf_non_abap TYPE flag,
         l_screen_id TYPE /psyng/user_right,
         l_tcode     TYPE tcode.
  IF p_appl <> 'SAP' AND p_appl <> ''.
    lf_non_abap = 'X'.
  ENDIF.
  l_tcode = p_name.
  l_screen_id = p_name.
  CALL FUNCTION '/PSYNG/SW_DISPLAY_TCODE'
    EXPORTING
      i_tcode     = l_tcode
      i_vrsio     = p_vrsio
      i_funid     = p_funid
      if_non_abap = lf_non_abap
      i_appl      = p_appl
      i_system    = p_sys
      i_screen_id = l_screen_id.
ENDFORM.
