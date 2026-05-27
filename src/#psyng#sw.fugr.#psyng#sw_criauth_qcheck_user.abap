FUNCTION /psyng/sw_criauth_qcheck_user.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CRIAUTH_QCHECK_USER'.
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
  DATA: lt_fields    TYPE STANDARD TABLE OF sval WITH HEADER LINE,
        l_retcode(1) TYPE c.


  CLEAR: lt_fields.
  REFRESH: lt_fields.

  IF lt_fields[] IS INITIAL.
    lt_fields-tabname   = 'USR02'.
    lt_fields-fieldname = 'BNAME'.
    lt_fields-fieldtext = 'User ID'(006).
    APPEND lt_fields.
  ENDIF.

  CLEAR l_retcode.
  CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
       EXPORTING
            formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
            programname       = '/PSYNG/SODREPORT_ORG'
            popup_title       = text-000
            ok_pushbuttontext = text-029
       IMPORTING
            returncode        = l_retcode
       TABLES
            fields            = lt_fields
       EXCEPTIONS
            error_in_fields   = 1
            OTHERS            = 2.
  IF sy-subrc <> 0.
    MESSAGE e208(00) WITH text-004.
  ENDIF.

  CHECK l_retcode NE 'A'.         "check to see user doesn't abort

  READ TABLE lt_fields WITH KEY tabname   = 'USR02'
                                fieldname = 'BNAME'.

  IF lt_fields-value IS INITIAL.
    MESSAGE i208(00) WITH text-005.
  ELSE.
    SUBMIT /psyng/sw_crit_auths
           WITH sodvrsio = vrsio
           WITH validusr = ' '
           WITH xmc      = 'X'
           WITH shonoca  = 'X'
           WITH pbname   = lt_fields-value
           AND RETURN.
  ENDIF.
ENDFUNCTION.
