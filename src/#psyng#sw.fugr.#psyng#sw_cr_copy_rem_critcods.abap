FUNCTION /psyng/sw_cr_copy_rem_critcods.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(RFCDEST) TYPE  RFCDES-RFCDEST
*"     VALUE(SOURCEVRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(TARGETVRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  EXPORTING
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      CRITCODES STRUCTURE  /PSYNG/CRITCODES OPTIONAL
*"  EXCEPTIONS
*"      NOT_AUTHORIZED_TO_IMPORT
*"      NO_AUTH_TO_READ_SOURCE
*"      INVALID_RFC
*"      SOURCE_LIST_EMPTY
*"      NOT_AUTHORIZED_TO_DISPLAY
*"----------------------------------------------------------------------
***Authorization check for Displaying SW Critical Tcodes
**SF 1665
************New Code******************************
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_COPY_REM_CRITCODS'.
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
  AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
           ID 'ACTVT' FIELD '01'
           ID 'Y&SW_VRSIO' FIELD targetvrsio.

  IF sy-subrc NE 0.
    RAISE not_authorized_to_display.
  ENDIF.
**SF 1665
***********Old Code*************
*  AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
*           ID 'ACTVT' FIELD 'UL'
*           ID 'Y&SW_VRSIO' FIELD targetvrsio.
*
*  IF sy-subrc NE 0.
*    RAISE not_authorized_to_import.
*  ENDIF.

******************************************
  SELECT SINGLE * FROM rfcdes WHERE rfcdest = rfcdest.
  IF sy-subrc NE 0.
    RAISE invalid_rfc.
  ENDIF.
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
  CALL FUNCTION '/PSYNG/SW_CR_READ_CRI_TCODES'
    DESTINATION rfcdest
    EXPORTING
      i_vrsio                         = sourcevrsio
    TABLES
      critcodes                       = critcodes
    EXCEPTIONS
     not_authorized_to_display       = 1
     OTHERS                          = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


  CASE sy-subrc.
    WHEN 1.
      RAISE no_auth_to_read_source.
    WHEN 2.
    WHEN OTHERS.
  ENDCASE.

  IF critcodes[] IS INITIAL.
    RAISE source_list_empty.
  ENDIF.
** SE 3.1 Change: Removed authority check from FM and add it before
*  calling FM as for appropriate Ativity
 AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
           ID 'ACTVT' FIELD 'UL'
           ID 'Y&SW_VRSIO' FIELD targetvrsio.
  IF sy-subrc NE 0.
    RAISE not_authorized_to_import.
  ENDIF.

  CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_TCODES'
       EXPORTING
            i_vrsio                  = targetvrsio
       IMPORTING
            return                   = return
       TABLES
            critcodes                = critcodes
       EXCEPTIONS
*            not_authorized_to_import = 1
            empty_list_provided      = 2
            OTHERS                   = 3.

  CASE sy-subrc.
*    WHEN 1.
*      RAISE not_authorized_to_import.
    WHEN 2.
      RAISE source_list_empty.
    WHEN 3.
    WHEN OTHERS.
  ENDCASE.


ENDFUNCTION.
