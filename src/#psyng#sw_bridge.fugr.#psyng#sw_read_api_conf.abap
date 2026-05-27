FUNCTION /psyng/sw_read_api_conf.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IF_TESTMODE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_PBRIDGE_CON) TYPE  FLAG OPTIONAL
*"     VALUE(IF_PBRIDGE_CON_TXT) TYPE  FLAG OPTIONAL
*"     VALUE(IF_PBRIDGE_CON_DETAIL) TYPE  FLAG OPTIONAL
*"     VALUE(I_PLCVRS) TYPE  /PSYNG/SW_PLC_RULESET
*"  EXPORTING
*"     VALUE(EF_SUCCESS) TYPE  FLAG
*"  TABLES
*"      ET_MESSAGES STRUCTURE  BAPIRET2
*"      ET_PBRIDGE_CON STRUCTURE  /PSYNG/API_CONF
*"      ET_PBRIDGE_CON_TXT STRUCTURE  /PSYNG/API_CONF_TXT
*"      ET_PBRIDGE_CON_DETAIL STRUCTURE  /PSYNG/API_CONF_DETAILS
*"  EXCEPTIONS
*"      NO_DATA_FOUND
*"----------------------------------------------------------------------
  TYPES rng_imp_typ TYPE RANGE OF /psyng/importance.
  DATA: l_total_conflicts TYPE i,
        ls_pbridge_con TYPE /psyng/api_conf,
        l_busarea TYPE /psyng/busarea-busarea,
        lt_busarea TYPE TABLE OF /psyng/busarea,
        rng_imp TYPE rng_imp_typ,
        wa_imp  TYPE LINE OF rng_imp_typ.

  FIELD-SYMBOLS : <fs_pbridge_con> TYPE /psyng/api_conf.

*--> BOC SE VF Scan changes - UMITTAL - 02/12/24
  CONSTANTS: lc_fname TYPE rs38l_fnam VALUE '/PSYNG/SW_READ_API_CONF'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE e089(/psyng/sw) WITH lc_fname.
  ENDIF.
*--> EOC SO VF Scan changes - UMITTAL - 02/12/24

  REFRESH : gt_messages.

  ef_success = 'X'.

*--Storing global variable
  g_plcvrs = i_plcvrs.
  gf_testmode = if_testmode.

*--Adding types of senstivies
*  wa_imp-sign = 'I'.
*  wa_imp-option = 'EQ'.
*  wa_imp-low = 'Critical'.
*  APPEND wa_imp TO rng_imp.
*  wa_imp-low = 'Low'.
*  APPEND wa_imp TO rng_imp.
*  wa_imp-low = 'Medium'.
*  APPEND wa_imp TO rng_imp.
*  wa_imp-low = 'High'.
*  APPEND wa_imp TO rng_imp.

*--Get connection configuration between SAP system and PLC
  PERFORM get_connector_param CHANGING g_host g_port g_scheme
                                       g_username g_password.

*--Get conflict header form PLC
  IF if_pbridge_con = 'X'.
    PERFORM read_pcloud_con CHANGING et_pbridge_con[].
  ENDIF.

*--Get conflict long description from PLC
  IF if_pbridge_con_txt = 'X'.
    PERFORM read_pcloud_con_txt CHANGING et_pbridge_con_txt[].
  ENDIF.

*--Get conflict detail from PLC
  IF if_pbridge_con_detail = 'X'.
    PERFORM read_pcloud_con_detail CHANGING et_pbridge_con_detail[].
  ENDIF.

*--Filter conflicts that are incompatible with the SE design
  SELECT busarea
    FROM /psyng/busarea
    INTO CORRESPONDING FIELDS OF TABLE lt_busarea.

  LOOP AT et_pbridge_con ASSIGNING <fs_pbridge_con>.

    READ TABLE lt_busarea WITH KEY busarea = <fs_pbridge_con>-busarea
    TRANSPORTING NO FIELDS.

    IF sy-subrc NE 0.

*--Filter1: Delete the risks whose application area does not
*      DELETE et_pbridge_con WHERE conid = ls_pbridge_con-conid.
*      DELETE et_pbridge_con_txt WHERE conid = ls_pbridge_con-conid.
*      DELETE et_pbridge_con_detail WHERE conid = ls_pbridge_con-conid.

      CLEAR <fs_pbridge_con>-busarea.

    ENDIF.

*    IF ls_pbridge_con-imp NOT IN rng_imp.
*
**--Filter2: Delete the risks whose sensitivity does not exist
*      DELETE et_pbridge_con WHERE conid = ls_pbridge_con-conid.
*      DELETE et_pbridge_con_txt WHERE conid = ls_pbridge_con-conid.
*      DELETE et_pbridge_con_detail WHERE conid = ls_pbridge_con-conid.
*
*    ENDIF.

  ENDLOOP.
  UNASSIGN <fs_pbridge_con>.

*--Total number of PLC risks which are compatible with SE
  DESCRIBE TABLE et_pbridge_con LINES l_total_conflicts.

  IF et_pbridge_con[] IS INITIAL
  OR et_pbridge_con_txt[] IS INITIAL
  OR et_pbridge_con_detail[] IS INITIAL.
    DELETE gt_messages WHERE type = 'S'.
    CLEAR ef_success.
    RAISE no_data_found.
  ELSE.
    enmsg 'S' gt_messages 'Conflict data successfully ' 'pulled with'
                                l_total_conflicts 'conflicts'.
  ENDIF.

  APPEND LINES OF gt_messages TO et_messages.

  REFRESH gt_messages.

ENDFUNCTION.
