FUNCTION /PSYNG/SW_RFC_CHECK.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_RFCDEST) TYPE  RFCDEST
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"  EXCEPTIONS
*"      FAILURE
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_RFC_CHECK'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026

DATA: l_message(100) TYPE c.
*--Check connections

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
  CALL FUNCTION 'RFC_PING' DESTINATION i_rfcdest
    EXCEPTIONS
      system_failure        = 1  MESSAGE l_message
      communication_failure = 2  MESSAGE l_message. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  IF sy-subrc NE 0.
   et_return-type = 'E'.
   et_return-id = '/PSYNG/BASIS'.
   et_return-number = '113'.
   et_return-message = l_message.
   append et_return.
    MESSAGE e113(/psyng/basis) WITH i_rfcdest l_message
     RAISING failure.
  ENDIF.

*-- User validations
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
  CALL FUNCTION 'RFCPING' DESTINATION i_rfcdest
    EXCEPTIONS
      system_failure        = 1  MESSAGE l_message
      communication_failure = 2  MESSAGE l_message."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  IF sy-subrc NE 0.
    et_return-type = 'E'.
   et_return-id = '/PSYNG/BASIS'.
   et_return-number = '113'.
   et_return-message = l_message.
   append et_return.
    MESSAGE e113(/psyng/basis) WITH i_rfcdest l_message
    RAISING failure.
  ENDIF.





ENDFUNCTION.
