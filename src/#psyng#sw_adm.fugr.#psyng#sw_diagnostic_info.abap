FUNCTION /psyng/sw_diagnostic_info.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_SODVRSIO) TYPE  /PSYNG/SWSODVERS-VRSIO OPTIONAL
*"     VALUE(I_GENERAL_INFO) TYPE  FLAG OPTIONAL
*"     VALUE(I_CPU_PERFORMANCE) TYPE  FLAG OPTIONAL
*"     VALUE(I_MATRIX_OBJECT) TYPE  FLAG OPTIONAL
*"     VALUE(I_SECURITY_ENVIROMENT) TYPE  FLAG OPTIONAL
*"     VALUE(I_TABLES_SIZE) TYPE  FLAG OPTIONAL
*"     VALUE(I_SE_TABLES_SIZE) TYPE  FLAG OPTIONAL
*"     VALUE(I_TRANSPORT) TYPE  FLAG OPTIONAL
*"     VALUE(I_SOD_MATRIX_INFO) TYPE  FLAG OPTIONAL
*"     VALUE(I_MAXUSERS) TYPE  I OPTIONAL
*"  EXPORTING
*"     VALUE(E_SERVER) LIKE  MSXXLIST-NAME
*"     VALUE(E_CPU_CALCULATION) LIKE  /PSYNG/SW_CPU_CALCU_INFO
*"       STRUCTURE  /PSYNG/SW_CPU_CALCU_INFO
*"     VALUE(E_MATRIX_CAL) LIKE  /PSYNG/SW_CAL_SODMATRIX STRUCTURE
*"        /PSYNG/SW_CAL_SODMATRIX
*"     VALUE(E_SEC_INFO) LIKE  /PSYNG/SW_SECURITY_INFO STRUCTURE
*"        /PSYNG/SW_SECURITY_INFO
*"     VALUE(E_AGR_COUNT) TYPE  /PSYNG/LONGTEXTFIELD
*"     VALUE(E_USR_COUNT) TYPE  /PSYNG/LONGTEXTFIELD
*"     VALUE(E_PSYNG_COUNT) TYPE  /PSYNG/LONGTEXTFIELD
*"     VALUE(E_CONFIG_COUNT) TYPE  /PSYNG/LONGTEXTFIELD
*"     VALUE(E_MIT_COUNT) TYPE  /PSYNG/LONGTEXTFIELD
*"     VALUE(E_RES_COUNT) TYPE  /PSYNG/LONGTEXTFIELD
*"     VALUE(E_SOD_PERFORMANCE) TYPE  /PSYNG/SW_SOD_PERFORMANCE_CAL
*"     VALUE(EF_NOT_AUTH) TYPE  FLAG
*"     VALUE(EF_ORACLE) TYPE  FLAG
*"  TABLES
*"      ET_AGR_TAB STRUCTURE  /PSYNG/SW_TABLE_TEXT OPTIONAL
*"      ET_USR_TAB STRUCTURE  /PSYNG/SW_TABLE_TEXT OPTIONAL
*"      ET_PSYNG_TAB STRUCTURE  /PSYNG/SW_TABLE_TEXT OPTIONAL
*"      ET_CONFIG_TAB STRUCTURE  /PSYNG/SW_TABLE_TEXT OPTIONAL
*"      ET_MIT_TAB STRUCTURE  /PSYNG/SW_TABLE_TEXT OPTIONAL
*"      ET_RES_TAB STRUCTURE  /PSYNG/SW_TABLE_TEXT OPTIONAL
*"      ET_SW_TR STRUCTURE  E07T OPTIONAL
*"----------------------------------------------------------------------
*----------------------------------------------------------------------*
*  Change Date  Changed by  Change Tag  Transport                      *
*  20/02/2020   Gurpinder   C0025       P33K940509                     *
*----------------------------------------------------------------------*

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_DIAGNOSTIC_INFO'.
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

  IF i_general_info = 'X'.
    PERFORM general_info USING e_server.
  ENDIF.

  IF i_cpu_performance = 'X'.
    PERFORM cpu_cal USING i_sodvrsio
    CHANGING e_cpu_calculation.
  ENDIF.

  IF i_matrix_object = 'X'.
    PERFORM matrix_cal USING i_sodvrsio
      CHANGING e_matrix_cal.
  ENDIF.

  IF i_security_enviroment = 'X'.
    PERFORM security_environment
    CHANGING e_sec_info.
  ENDIF.

  IF i_tables_size = 'X'.
    PERFORM table_cal
        TABLES
           et_agr_tab
           et_usr_tab
           et_psyng_tab
           et_config_tab
           et_mit_tab
           et_res_tab
    USING ''
    CHANGING
          e_agr_count
          e_usr_count
          e_psyng_count
          e_config_count
          e_mit_count
          e_res_count
          ef_not_auth
          ef_oracle.
  ENDIF.

  IF i_se_tables_size = 'X'.
    PERFORM table_cal
        TABLES
           et_agr_tab
           et_usr_tab
           et_psyng_tab
           et_config_tab
           et_mit_tab
           et_res_tab
    USING i_se_tables_size
    CHANGING
          e_agr_count
          e_usr_count
          e_psyng_count
          e_config_count
          e_mit_count
          e_res_count
          ef_not_auth
          ef_oracle.
  ENDIF.

  IF i_transport = 'X'.
    PERFORM display_sw_tps
    TABLES et_sw_tr.
  ENDIF.

  IF i_sod_matrix_info = 'X'.
    PERFORM sod_matrix USING i_sodvrsio
                             i_maxusers
                       CHANGING
                          e_sod_performance.
  ENDIF.
ENDFUNCTION.
