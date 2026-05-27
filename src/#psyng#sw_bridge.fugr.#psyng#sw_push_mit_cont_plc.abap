FUNCTION /psyng/sw_push_mit_cont_plc.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_CONTROL_HEADERS) TYPE  FLAG OPTIONAL
*"     REFERENCE(I_CONTROL_ASSIGN) TYPE  FLAG OPTIONAL
*"     REFERENCE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  TABLES
*"      ET_MESSAGES STRUCTURE  BAPIRET2 OPTIONAL
*"      ET_MCHDR STRUCTURE  /PSYNG/MCHDR OPTIONAL
*"      ET_MCUSER STRUCTURE  /PSYNG/DA_SW_MCUSER OPTIONAL
*"----------------------------------------------------------------------

*--Push mitigation definitions
  IF i_control_headers EQ 'X'.
    PERFORM push_mitigation_definitions tables et_messages
                                               et_mchdr
                                        USING i_control_headers.

  ENDIF.

*--Push mitigation assignments
  IF i_control_assign EQ 'X'.
    PERFORM push_mit_assignments tables et_messages
                                        et_mcuser
                                 using i_control_assign
                                       i_vrsio.
  ENDIF.



ENDFUNCTION.
