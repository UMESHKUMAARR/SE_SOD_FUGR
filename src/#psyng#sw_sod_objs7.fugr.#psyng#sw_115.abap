FUNCTION /psyng/sw_115.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(VRSIO) TYPE  /PSYNG/SODVRSIO
*"  TABLES
*"      IT_ROLES STRUCTURE  /PSYNG/SW_SEL_OPTS_AGR_NAME OPTIONAL
*"      ET_OUTPUT STRUCTURE  /PSYNG/SW_OUT_ROUTDET OPTIONAL
*"      IT_RFCDEST STRUCTURE  /PSYNG/SW_SEL_OPTS_RFCDEST OPTIONAL
*"----------------------------------------------------------------------


  DATA : it_critcodes TYPE TABLE OF /psyng/critcodes WITH HEADER LINE,
         lt_roles TYPE TABLE OF agr_1251 WITH HEADER LINE,
         roletcode TYPE TABLE OF /psyng/role_tcode WITH HEADER LINE,
         l_rfcdest TYPE rfcdes-rfcdest,
         wa_output TYPE /psyng/sw_out_routdet,
         wa_rfcdest TYPE rfcdes,
         lt_rfcdest TYPE TABLE OF rfcdes WITH HEADER LINE.

  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest.

  PERFORM load_rfc
           TABLES it_rfcdest
                  lt_rfcdest.

    wa_rfcdest-rfcdest = 'LOCAL'.
    wa_rfcdest-rfcoptions = l_rfcdest.
    APPEND wa_rfcdest TO lt_rfcdest.



  CALL FUNCTION '/PSYNG/SW_CR_READ_CRI_TCODES'
       EXPORTING
            i_vrsio   = vrsio
       TABLES
            critcodes = it_critcodes
"(++)BOC UMITTAL SE VF scan-25/11/2024.
       EXCEPTIONS
          NOT_AUTHORIZED_TO_DISPLAY   = 1
          OTHERS = 2.
IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

"(++)EOC UMITTAL SE VF scan-25/11/2024.
  LOOP AT lt_rfcdest INTO wa_rfcdest.

    IF wa_rfcdest-rfcdest = 'LOCAL'.

      CALL FUNCTION '/PSYNG/BC_012'
           TABLES
                it_agr_name   = it_roles
                et_role_tcode = roletcode.

    ELSE.
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
      CALL FUNCTION '/PSYNG/BC_012'
      DESTINATION wa_rfcdest-rfcdest
     TABLES
      it_agr_name         = it_roles
       et_role_tcode       = roletcode. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


    ENDIF.

    LOOP AT it_critcodes.
      READ TABLE roletcode WITH KEY screen = it_critcodes-tcode.
      IF sy-subrc = 0.
        wa_output-agr_name = roletcode-rolename.
        wa_output-tcode = it_critcodes-tcode.
        wa_output-rfcdest = wa_rfcdest-rfcoptions.
        APPEND wa_output TO et_output.
        CLEAR wa_output.
      ENDIF.
    ENDLOOP.
  ENDLOOP.




  .






ENDFUNCTION.
