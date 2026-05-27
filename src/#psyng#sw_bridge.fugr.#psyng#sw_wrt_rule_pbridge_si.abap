FUNCTION /psyng/sw_wrt_rule_pbridge_si.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IF_SCHEMA) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ACT_GRP) TYPE  FLAG OPTIONAL
*"     VALUE(IF_RULES) TYPE  FLAG OPTIONAL
*"     VALUE(IF_RULES_OVRWRT) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ACTVT_MOD_VALUES) TYPE  FLAG OPTIONAL
*"     VALUE(IF_MIT_CONT_HEADER) TYPE  FLAG OPTIONAL
*"     VALUE(IF_MIT_ASSIGN) TYPE  FLAG OPTIONAL
*"     VALUE(I_SCHEMA_B64) TYPE  STRING OPTIONAL
*"     VALUE(I_GROUP_B64) TYPE  STRING OPTIONAL
*"     VALUE(I_ACTMODVAL_B64) TYPE  STRING OPTIONAL
*"     VALUE(I_RULE_B64) TYPE  STRING OPTIONAL
*"     VALUE(I_MCDEF_B64) TYPE  STRING OPTIONAL
*"     VALUE(I_MCASSIGN_B64) TYPE  STRING OPTIONAL
*"     VALUE(L_SCHEMA_COUNT) TYPE  INT4 OPTIONAL
*"     VALUE(L_RULES_COUNT) TYPE  INT4 OPTIONAL
*"     VALUE(L_GROUP_COUNT) TYPE  INT4 OPTIONAL
*"     VALUE(L_MODE_COUNT) TYPE  INT4 OPTIONAL
*"  TABLES
*"      ET_MESSAGES STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------

  PERFORM get_connector_param CHANGING g_host g_port g_scheme
                                       g_username g_password.

  IF if_schema = 'X'.
    PERFORM upload_schema USING i_schema_b64 l_schema_count.
  ENDIF.

  IF if_act_grp = 'X'.
    PERFORM upload_actvt_grp USING i_group_b64 l_group_count.
  ENDIF.

  IF if_rules = 'X'.
    PERFORM upload_rules USING i_rule_b64
                               if_rules_ovrwrt l_rules_count.
  ENDIF.

  IF if_actvt_mod_values = 'X'.
    PERFORM upload_actvt_mod_values USING i_actmodval_b64 l_mode_count.
  ENDIF .

  IF if_mit_cont_header = 'X'.
    PERFORM upload_mit_def USING i_mcdef_b64.
  ENDIF .

  IF if_mit_assign = 'X'.
    PERFORM upload_mit_assign USING i_mcassign_b64.
  ENDIF .

  et_messages[] = gt_messages[].

ENDFUNCTION.
