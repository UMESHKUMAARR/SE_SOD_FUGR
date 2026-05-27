FUNCTION /psyng/sw_display_tcode.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_TYPE) TYPE  /PSYNG/TCODETYPE OPTIONAL
*"     REFERENCE(I_TCODE) TYPE  XUTCODE OPTIONAL
*"     REFERENCE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     REFERENCE(I_FUNID) TYPE  /PSYNG/FUNCTION_ID OPTIONAL
*"     REFERENCE(IF_NON_ABAP) TYPE  FLAG OPTIONAL
*"     REFERENCE(I_APPL) TYPE  /PSYNG/APPLICATION OPTIONAL
*"     REFERENCE(I_SYSTEM) TYPE  /PSYNG/SYSTEM OPTIONAL
*"     REFERENCE(I_SCREEN_ID) TYPE  /PSYNG/USER_RIGHT OPTIONAL
*"----------------------------------------------------------------------
  DATA: l_fioriid    TYPE /psyng/sw_fioriid,
        l_type       TYPE  /psyng/tcodetype,
        lf_not_found TYPE flag.
  l_type = i_type.
  IF l_type IS INITIAL.
    IF i_tcode CP '/PSYNG/-*'.
      l_type = 'P'.
*--If version and function provided, look up type in SOD Matrix
      IF NOT i_vrsio IS INITIAL OR NOT  i_funid IS INITIAL.
        SELECT SINGLE type FROM /psyng/functtran INTO l_type
           WHERE functionid = i_funid AND
                 tcode      = i_tcode AND
                 vrsio      = i_vrsio.
        IF l_type IS INITIAL.
          l_type = 'P'.
        ENDIF.
      ENDIF.
    ELSE.
      l_type = 'T'.
    ENDIF.
  ENDIF.
  CASE  l_type.
    WHEN 'F'.

      SELECT SINGLE fioriid FROM /psyng/functtran INTO l_fioriid
          WHERE functionid = i_funid AND
                tcode      = i_tcode AND
                vrsio      = i_vrsio.
      IF sy-subrc <> 0.
*--Check if the passed tcode is a fiori app id
       SELECT single FIORIID into  l_fioriid
        FROM /psyng/sw_fioria
       WHERE fioriid = i_tcode.
      endif.
      IF sy-subrc = 0.
        CALL FUNCTION '/PSYNG/SW_FIORIAPP_SHOW'
          EXPORTING
            i_fioriid = l_fioriid
          EXCEPTIONS
            not_found = 1
            OTHERS    = 2.
        IF sy-subrc <> 0.
          MESSAGE i113(/psyng/sw) WITH
          'Fiori App not Found'(088).
        ENDIF.
      ELSE.
        MESSAGE i113(/psyng/sw) WITH
        'Fiori App not Found'(088).

      ENDIF.
    WHEN 'T'.
      PERFORM execute_tcode_popup
           USING i_tcode
                 i_screen_id
                 if_non_abap
                 i_appl
                 i_system
           CHANGING lf_not_found.

    WHEN 'P'.
      MESSAGE i113(/psyng/sw) WITH
      'No info for Placeholder Transactions'(087).
  ENDCASE.
ENDFUNCTION.
