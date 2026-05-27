FUNCTION /PSYNG/SW_INFO_MESSAGE_OBJECT.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_TYPE) TYPE  STRING
*"     REFERENCE(I_ID) TYPE  STRING
*"  EXPORTING
*"     REFERENCE(E_MESSAGE) TYPE  STRING
*"     REFERENCE(E_TITLE) TYPE  STRING
*"----------------------------------------------------------------------

case i_type.
  when 'RISK'.
    perform get_risk_info
      using
        i_id
      changing
        e_title
        e_message.

endcase.



ENDFUNCTION.
