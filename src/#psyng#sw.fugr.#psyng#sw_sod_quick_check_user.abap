FUNCTION /psyng/sw_sod_quick_check_user .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_SOD_QUICK_CHECK_USER'.
*  S_RFC AUTHORITY CHECK
* BOC BNAYAK CVA scan fix DT:05-05-2026
*  AUTHORITY-CHECK OBJECT 'S_RFC'
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
* EOC BNAYAK CVA scan fix DT:05-05-2026
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026

  DATA: ifields TYPE STANDARD TABLE OF sval WITH HEADER LINE,
        answer, userresponse.

  clear: ifields.
  refresh: ifields.

  IF ifields[] IS INITIAL.
    ifields-tabname = 'USR02'.
    ifields-fieldname = 'BNAME'.
    ifields-fieldtext = 'User ID'.
    APPEND ifields.
  ENDIF.

  CLEAR userresponse.
  CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
    EXPORTING
      formname                = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
      programname             = '/PSYNG/SODREPORT_ORG'
      popup_title             = text-003
      ok_pushbuttontext       = text-029
    IMPORTING
      returncode              = userresponse
    TABLES
      fields                  = ifields
   EXCEPTIONS
     error_in_fields          = 1
     OTHERS                   = 2.

  IF sy-subrc <> 0.
    MESSAGE e208(00) WITH text-004.
  ENDIF.
  CHECK userresponse NE 'A'.  "check to see user doesn't abort

  READ TABLE ifields WITH KEY tabname = 'USR02'
                              fieldname = 'BNAME'.

  IF ifields-value IS INITIAL.
    MESSAGE i208(00) WITH text-005.
  ELSE.
*--Validate user exists
    select single bname into ifields-value from usr02
    where bname = ifields-value.
    if sy-subrc = 0.
      SUBMIT /psyng/sodreport_sys_wide_org
             WITH sodvrsio = vrsio
             WITH validusr = ' '
             WITH xmc = 'X'
             WITH shonosod = 'X'
             WITH pcolor = 'X'
             WITH odt = 'X'
             WITH userlist = ifields-value
             AND RETURN.
    else.
      MESSAGE i208(00) WITH 'User Does not exist'(037).
    endif.
  ENDIF.
ENDFUNCTION.
