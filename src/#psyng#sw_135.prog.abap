REPORT /psyng/sw_135.
TABLES: /psyng/swcfgset,
        /psyng/swsodvers,
        /psyng/swcfgsys,
        /psyng/swcfgve.
include :
  /PSYNG/BASIS_EXELOG,
  /PSYNG/SW_CONFIG.
INCLUDE /psyng/sw_135_top.

INCLUDE /psyng/sw_135_cl1.
INCLUDE /psyng/sw_135_o01.
INCLUDE /psyng/sw_135_i01.
INCLUDE /psyng/sw_135_f01.

parameters : p_vrsio type /psyng/sodvrsio.
INITIALIZATION.
* BOC by RGUPTA for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.

* EOC by RGUPTA for C0700
  gf_dispchg = gc_display.
  exelog sy-repid ''.
  se_config_param 'CFG_SET_ORG_SHOW_TOT' gf_CFG_SET_ORG_SHOW_TOT.
  if gf_CFG_SET_ORG_SHOW_TOT = 'Y' or gf_CFG_SET_ORG_SHOW_TOT = 'X'.
    gf_CFG_SET_ORG_SHOW_TOT = 'X'.
  endif.
  se_config_param 'CFG_SET_AUTOPARSE' gf_CFG_SET_AUTO_PARSE.
  if gf_CFG_SET_AUTO_PARSE = 'Y' or gf_CFG_SET_AUTO_PARSE = 'X'.
    gf_CFG_SET_AUTO_PARSE = 'X'.
  endif.

START-OF-SELECTION.
*BOC UMITTAL SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
g_VRSIO = p_vrsio.
  CREATE OBJECT gr_event_handler_sys.
  CREATE OBJECT gr_event_handler_ele1.
  CREATE OBJECT gr_event_handler_ele2.
  CREATE OBJECT gr_event_handler_org.
  CREATE OBJECT gr_event_handler_org1.
  CREATE OBJECT gr_event_handler_org2.
  CREATE OBJECT gr_event_handler_var.

  CLEAR g_sod_parse.

  CALL SCREEN '0100'.
