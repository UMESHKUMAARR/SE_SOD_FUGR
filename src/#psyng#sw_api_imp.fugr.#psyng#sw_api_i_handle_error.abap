*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_API_I_HANDLE_ERROR
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_api_i_handle_error.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  EXPORTING
*"     REFERENCE(ES_RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      IT_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"----------------------------------------------------------------------


  FIELD-SYMBOLS : <ret> TYPE  bapiret2.
  DATA: l_count TYPE balmnr.
  SORT it_return BY type.
  LOOP AT it_return ASSIGNING <ret>.
*--Assign a Unique nr to each type of error
    CASE <ret>-id.
      WHEN 'NOCONFLICTS'.
        <ret>-log_no = '1'.
      WHEN 'NOUSERS'.
        <ret>-log_no = '2'.
      WHEN 'NOVERSION'.
        <ret>-log_no = '3'.
      WHEN 'NOCONFIGSET'.
        <ret>-log_no = '4'.
      WHEN 'NOSIMUROLES'.
        <ret>-log_no = '5'.
      WHEN 'INVALIDVERSION'.
        <ret>-log_no = '6'.
      WHEN 'INVALIDCONFSET'.
        <ret>-log_no = '7'.
      WHEN 'NOGLOBALCONFSET'.
        <ret>-log_no = '8'.
      WHEN 'INVALIDROLE'.
        <ret>-log_no = '9'.
      WHEN 'ROLERFCFAIL'.
        <ret>-log_no = '10'.
      WHEN 'DEFAULT_VERSION'.
        <ret>-log_no = '11'.
      WHEN 'NO_DEFAULT_VERSION'.
        <ret>-log_no = '12'.
      WHEN 'CFG_SET_ENABLED'.
        <ret>-log_no = '13'.
      WHEN 'CFG_SET_DISABLED'.
        <ret>-log_no = '14'.
      WHEN 'NO_RUN'.
        <ret>-log_no = '15'.
      WHEN 'INVALIDUSER'.
        <ret>-log_no = '16'.
      WHEN 'NO_COMPLETE_CHECK'.
        <ret>-log_no = '17'.
      WHEN OTHERS.
*--Fall back to the first characters of the id of the message.
        MOVE <ret>-id TO es_return-code.
    ENDCASE.
    ADD 1 TO l_count.
    IF <ret>-type CO 'EW'.
      IF es_return-type <> 'E'.
*--Fill return structure if not already filled with error
        MOVE-CORRESPONDING <ret> TO es_return.
        es_return-log_no = <ret>-id.
        es_return-code   = <ret>-log_no .
        es_return-log_msg_no = l_count.
      ENDIF.
    ENDIF.
*--Convert to BAPIRETURN structure
    MOVE-CORRESPONDING <ret> TO et_return.
    et_return-log_no = <ret>-id.
    et_return-code   = <ret>-log_no .
    et_return-log_msg_no = l_count.
    APPEND et_return.
  ENDLOOP.

  IF es_return IS INITIAL.
    es_return-type    = 'S'.
    es_return-message = 'Success'.
    es_return-code    = '0'.
    es_return-log_no  = 'SUCCESS'.
    es_return-log_msg_no = l_count + 1.
    APPEND es_return TO et_return.
  ENDIF.

ENDFUNCTION.
