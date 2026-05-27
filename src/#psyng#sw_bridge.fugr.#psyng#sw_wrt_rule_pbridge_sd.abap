FUNCTION /PSYNG/SW_WRT_RULE_PBRIDGE_SD.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IF_ACTVT_MOD) TYPE  FLAG
*"     VALUE(IF_ACTVTMOD_OVRWRT) TYPE  FLAG
*"     VALUE(IF_GRP_CMP) TYPE  FLAG
*"     VALUE(IF_GRPCMP_OVRWRT) TYPE  FLAG
*"     VALUE(I_ACTVTMOD_B64) TYPE  STRING
*"     VALUE(I_GRPCMP_B64) TYPE  STRING
*"     VALUE(I_SYSTEM) TYPE  /PSYNG/BRIDGE_SYSTEM
*"  TABLES
*"      ET_MESSAGES STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------

  PERFORM get_connector_param CHANGING g_host g_port g_scheme
                                       g_username g_password.

  IF if_actvt_mod = 'X'.
    PERFORM upload_actvt_mod USING i_actvtmod_b64
                                   if_actvtmod_ovrwrt
                                   i_system.
  ENDIF.

  IF if_grp_cmp = 'X'.
    PERFORM upload_grp_cmp USING i_grpcmp_b64
                                 if_grpcmp_ovrwrt
                                 i_system.
  ENDIF.

  et_messages[] = gt_messages[].
ENDFUNCTION.
