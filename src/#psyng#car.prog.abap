*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/CAR
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.

REPORT /psyng/car .
INCLUDE /psyng/car_top.
TABLES: usr02, /psyng/exelog, uscompany, /psyng/sw_sod_st.

DATA: ls_rfcdes       TYPE /psyng/sw_rfcdes,
        ls_audit_info TYPE /psyng/sw_sys_audit_info,
        lt_sod_st     TYPE TABLE OF /psyng/sw_sod_st WITH HEADER LINE,
        lt_user       type table of /PSYNG/BC_USERID_NAME
                      WITH HEADER LINE,
        g_current_user TYPE sy-uname. "RGUPTA C0700
RANGES: gt_bname FOR /psyng/bc_uidn-bname.

*---Selection screen
SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.
PARAMETERS: p_system TYPE /psyng/swcfgsys-sysid.
SELECTION-SCREEN: END OF BLOCK b1.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_system.
  PERFORM f4_system USING 'P_SYSTEM' CHANGING p_system.
* BOC by RGUPTA on 28.03.22 for C0700
INITIALIZATION.
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA On 28.03.22 for C0700
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
  AUTHORITY-CHECK OBJECT 'S_TCODE'
           ID 'TCD' FIELD '/PSYNG/SE'.

  IF sy-subrc NE 0.
    MESSAGE e398(00) WITH 'You are not Authorized.'(023).
  ENDIF.


*-- if input blank then should execute for local.
  IF p_system IS INITIAL.
    CONCATENATE sy-sysid sy-mandt INTO p_system.
  ENDIF.
*-- read rfc destination defined in SE
  SELECT SINGLE * FROM /psyng/sw_rfcdes INTO ls_rfcdes WHERE
  systid = p_system.

*--Get remote system info
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
  CALL FUNCTION '/PSYNG/SW_CUSTMER_AUDIT_INFO'
  DESTINATION ls_rfcdes-rfcdest
   IMPORTING
     e_audit_info       =  ls_audit_info
     TABLES
     et_sod_st          = lt_sod_st
     EXCEPTIONS
      RESOURCE_FAILURE      = 1
      communication_failure = 2
      system_failure        = 3
      OTHERS                = 4. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


  IF sy-subrc <> 0.
*todo --error handlinng.
  ENDIF.
*--Get the user's full name
lt_user-bname = g_current_user. "sy-uname. C0700
append lt_user.
CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
 EXPORTING
   NO_EMAIL       = 'X'
  TABLES
    username       = lt_user.
read table lt_user index 1.
usname = lt_user-NAME_FULL.


  WRITE:
      / text-000, ls_audit_info-company,
      / text-001, sy-datum, text-002, sy-uzeit,
*      / text-003, sy-uname, text-004, usname,  "C0700
      / text-003, g_current_user, text-004, usname, "C0700
      / text-005, ls_audit_info-sys_id, text-006,
ls_audit_info-sys_client.
  SKIP 3.
  WRITE:
      / ls_audit_info-tuser, text-007,
      / ls_audit_info-dusers, text-008,
      / ls_audit_info-susers, text-009,
      / ls_audit_info-cusers, text-010,
      / ls_audit_info-rusers, text-011,
      / ls_audit_info-srusers, text-012.
  SKIP 2.
  WRITE:
      / ls_audit_info-vusers, text-013,
      / ls_audit_info-vdusers, text-014,
      / ls_audit_info-vndusers, text-015.
  SKIP 2.
  WRITE:
      / ls_audit_info-lusers, text-016,
      / ls_audit_info-ldusers, text-017,
      / ls_audit_info-lndusers, text-018.
  SKIP 2.
  WRITE:
      / ls_audit_info-ueusers, text-019,
      / ls_audit_info-uedusers, text-020,
      / ls_audit_info-uendusers, text-021.

  SKIP 2.
  WRITE:/ text-022.
  LOOP AT lt_sod_st.
    MOVE lt_sod_st-sodcount TO sodcount .
    SHIFT sodcount LEFT DELETING LEADING '0' .
    WRITE:/5 lt_sod_st-byobject, sodcount.
  ENDLOOP.

************************************************
FORM f4_system USING    fieldname
                 CHANGING e_value.

  DATA: BEGIN OF lt_values OCCURS 0,
            line(255) TYPE c,
          END OF lt_values.
  DATA: lt_fields    TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return    TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_sw_rfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE.

  SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_sw_rfcdes.
  LOOP AT lt_sw_rfcdes.
    lt_values-line = lt_sw_rfcdes-rfcdest.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-rfcname.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-description.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-systid.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-sys_type.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-sys_category.
    APPEND lt_values.
  ENDLOOP.

  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'RFCDEST'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'RFCNAME'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'DESCRIPTION'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYSTID'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYS_TYPE'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYS_CATEGORY'.
  APPEND lt_fields.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield        = 'SYSTID'
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

  READ TABLE lt_return INDEX 1.
  e_value = lt_return-fieldval.
ENDFORM.

END-OF-SELECTION.
