FUNCTION /psyng/sw_info_bapiret.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IF_WARNING) TYPE  FLAG DEFAULT 'X'
*"     REFERENCE(IF_SUCCESS) TYPE  FLAG DEFAULT ' '
*"     REFERENCE(IF_ERROR) TYPE  FLAG DEFAULT 'X'
*"     REFERENCE(IF_INFO) TYPE  FLAG DEFAULT ' '
*"     REFERENCE(IF_BG_FAIL_ON_ERROR) TYPE  FLAG DEFAULT 'X'
*"  TABLES
*"      IT_BAPIRET2 STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------
  DATA :
    l_log_handle        TYPE balloghndl,
    l_s_log             TYPE bal_s_log,
    l_s_msg             TYPE bal_s_msg,
    l_s_display_profile TYPE bal_s_prof,
    lf_show             TYPE flag,
    lf_fail             TYPE flag,
    lt_string           TYPE TABLE OF swastrtab
    WITH HEADER LINE,
    l_message type string.

  CONSTANTS lc_50 TYPE i VALUE 50.

  IF sy-batch = 'X'.
*--Just add messages to log
    LOOP AT it_bapiret2.
      IF ( it_bapiret2-type = 'S' AND if_success = 'X' ) OR
         ( it_bapiret2-type = 'E' AND if_error = 'X' ) OR
         ( it_bapiret2-type = 'W' AND if_warning = 'X' ) OR
         ( it_bapiret2-type = 'S' AND if_info = 'X' ).
        IF strlen( it_bapiret2-message ) > 50.
          l_s_msg-msgv1 = it_bapiret2-message(50).
          IF strlen( it_bapiret2-message ) > 100.
            l_s_msg-msgv2 = it_bapiret2-message+50(50).
          ELSE.
            l_s_msg-msgv3 = it_bapiret2-message+50.
          ENDIF.
        ELSE.
          l_s_msg-msgv1 = it_bapiret2-message.
        ENDIF.
MESSAGE s002(/psyng/sw) WITH l_s_msg-msgv1 l_s_msg-msgv2 l_s_msg-msgv3 ''.
        IF if_bg_fail_on_error = 'X' AND if_error = 'X'.
          lf_fail = 'X'.
        ENDIF.
      ENDIF.
    ENDLOOP.
    IF sy-subrc = 0.
      COMMIT WORK.
    ENDIF.
    IF lf_fail = 'X'.
      MESSAGE e002(/psyng/sw) WITH 'Fatal Error'.
    ENDIF.
  ELSE.
*--Show popup with the messages
    CALL FUNCTION 'BAL_LOG_CREATE'
      EXPORTING
        i_s_log      = l_s_log
      IMPORTING
        e_log_handle = l_log_handle
      EXCEPTIONS
        OTHERS       = 1.
    IF sy-subrc = 0.
      LOOP AT it_bapiret2.
        IF ( it_bapiret2-type = 'S' AND if_success = 'X' ) OR
        ( it_bapiret2-type = 'E' AND if_error = 'X' ) OR
        ( it_bapiret2-type = 'W' AND if_warning = 'X' ) OR
        ( it_bapiret2-type = 'S' AND if_info = 'X' ).
          l_s_msg-msgty = it_bapiret2-type.
          l_s_msg-msgid = it_bapiret2-id.
*        l_s_msg-msgno = it_bapiret2-number.
          IF strlen( it_bapiret2-message ) > 50.

*----10.02.2022 odubey B16471
*----break message into 50 char, avoid space between words
          l_message = it_bapiret2-message.
            CALL FUNCTION 'SWA_STRING_SPLIT'
              EXPORTING
                input_string                       = l_message
               max_component_length                = lc_50
              TABLES
                string_components                  = lt_string
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             MAX_COMPONENT_LENGTH_INVALID = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

            READ TABLE lt_string INDEX 1.
            l_s_msg-msgv1 = lt_string-str.
            IF strlen( it_bapiret2-message ) > 100.
              READ TABLE lt_string INDEX 2.
              l_s_msg-msgv2 = lt_string-str.
            ELSE.
               READ TABLE lt_string INDEX 2.
              l_s_msg-msgv3 = lt_string-str.
            ENDIF.
          ELSE.
            l_s_msg-msgv1 = it_bapiret2-message.
          ENDIF.
          lf_show = 'X'.
          CALL FUNCTION 'BAL_LOG_MSG_ADD'
            EXPORTING
              i_log_handle = l_log_handle
              i_s_msg      = l_s_msg
            EXCEPTIONS
              OTHERS       = 1. "#EC SAST_CI_GEN_CHECK
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

        ENDIF.
      ENDLOOP.
      IF lf_show = 'X'.
*      get a display  profile
        CALL FUNCTION 'BAL_DSP_PROFILE_POPUP_GET'
          IMPORTING
            e_s_display_profile = l_s_display_profile
          EXCEPTIONS
            OTHERS              = 1.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
*     --Show thez popup
        CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
          EXPORTING
            i_s_display_profile = l_s_display_profile
          EXCEPTIONS
            OTHERS              = 1.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.




ENDFUNCTION.
