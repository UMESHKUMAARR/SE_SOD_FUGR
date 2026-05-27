*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_109
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

REPORT /psyng/sw_109. "#EC SAST_CI_GEN_CHECK
data : gf_success type /PSYNG/UPGRADE.
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
  perform main changing gf_success.

*---------------------------------------------------------------------*
*       FORM upgrade_action                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  P_SUCCESS                                                     *
*---------------------------------------------------------------------*
FORM main CHANGING p_success type /PSYNG/UPGRADE.
  DATA : l_message TYPE bapireturn,
         lt_messages TYPE TABLE OF char72,
         ls_config   TYPE /psyng/er_config_param,
         l_subrc TYPE numc2.

  DATA : lt_tadir TYPE TABLE OF tadir WITH HEADER LINE,
         lt_params TYPE rsparams OCCURS 0 WITH HEADER LINE,
         l_cnt TYPE i,
         l_current_user TYPE sy-uname. "C0700
* BOC by RGUPTA on 05.04.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 05.04.22 for C0700

  MESSAGE s113(/psyng/sw) WITH
  'Upgrading Separations Enforcer Variants on client '
  sy-mandt.
  CONCATENATE 'Upgrading Separations Enforcer Variants on client'(001)
  sy-mandt INTO l_message.
  APPEND l_message TO lt_messages.

*--Get All SE reports
 SELECT obj_name FROM tadir INTO CORRESPONDING FIELDS OF TABLE lt_tadir
  WHERE
  devclass = '/PSYNG/SW' OR devclass = '/PSYNG/SW_UTLS'.

  LOOP AT lt_tadir.
*--Check if there are variants for this report :
    SELECT COUNT( DISTINCT variant ) INTO l_cnt     "#EC CI_SEL_NESTED
    FROM varid WHERE report = lt_tadir-obj_name.
    IF sy-subrc = 0 AND l_cnt > 0.
*    MESSAGE s113(/psyng/sw) WITH
*    'Upgrading Variants for report '
*    lt_tadir-obj_name.
      CONCATENATE
      'Upgrading Variants for report '(002)
      lt_tadir-obj_name
      INTO l_message.
      APPEND l_message TO lt_messages.


      lt_params-selname = 'S_REPORT'.
      lt_params-sign    = 'I'.
      lt_params-option  = 'EQ'.
      lt_params-kind    = 'S'.
      lt_params-low     = lt_tadir-obj_name.
      APPEND lt_params.
    ENDIF.
  ENDLOOP.
*--Upgrade the Variants
  IF lt_params[] IS INITIAL.
    p_success-processed = 'X'.
    p_success-pdate     = sy-datum.
    p_success-ptime     = sy-uzeit.
    p_success-pbname    = l_current_user. "sy-uname. C0700
    EXIT.
  ENDIF.

*--Check which version of the report to call (note 65343)
*  https://service.sap.com/sap/support/notes/65343
data l_repid like sy-repid.
  select single name into l_repid from trdir where
    name = 'RSVARDOC_610'."#EC SAST_CI_GEN_CHECK
  if sy-subrc <> 0.
  select single name into l_repid from trdir where
    name = 'RSVARDOC_46X'."#EC SAST_CI_GEN_CHECK
    if sy-subrc <> 0.
      l_repid = 'RSVARDOC'.
    endif.
  endif.
  SUBMIT (l_repid)"#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(12/12/24)
   WITH SELECTION-TABLE lt_params AND RETURN.
  p_success-processed = 'X'.
  p_success-pdate     = sy-datum.
  p_success-ptime     = sy-uzeit.
  p_success-pbname    = l_current_user. "sy-uname. C0700

*--> BOC PN 11269 - ATC fixes - HBHALLA - 24/01/25
*  EDITOR-CALL FOR lt_messages."#EC SAST_CI_GEN_CHECK(HBHALLA)(17/12/24)
  CALL FUNCTION 'POPUP_WITH_TABLE'
    EXPORTING
      ENDPOS_COL         = 80
      ENDPOS_ROW         = 6
      STARTPOS_COL       = 25
      STARTPOS_ROW       = 1
      TITLETEXT          = 'Information'
*   IMPORTING
*     CHOICE             =
    TABLES
      VALUETAB           =  lt_messages
   EXCEPTIONS
     BREAK_OFF          = 1
     OTHERS             = 2
            .
  IF SY-SUBRC <> 0.
 CASE sy-subrc.
   WHEN 1.
      MESSAGE e002(/psyng/sw) WITH 'Break Off'(t04).
   WHEN OTHERS.
      MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(t03).
 ENDCASE.
  ENDIF.
*--> EOC PN 11269 - ATC fixes - HBHALLA - 24/01/25

ENDFORM.
