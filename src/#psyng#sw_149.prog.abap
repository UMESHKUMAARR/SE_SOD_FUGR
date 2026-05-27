REPORT /psyng/sw_149 .

TABLES: /psyng/swrrshdr.
INCLUDE :
   /psyng/sw_config,
   /psyng/sw_149_top,
   /psyng/sw_149_cl1,
   /psyng/sw_149_o01,
   /psyng/sw_149_i01,
   /psyng/sw_149_f01,
   /psyng/basis_exelog.

parameters : p_vrsio type /psyng/sodvrsio.

START-OF-SELECTION.

*BOC AKUMAR SE VF scan changes-12/04/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-12/04/2024

  g_vrsio = p_vrsio.
  exelog sy-repid ''.
  CREATE OBJECT gr_event_handler.
  CALL SCREEN '0100'.

INITIALIZATION.
*--Register report for Most Used Reports
  CALL FUNCTION '/PSYNG/SW_128'
  EXPORTING
  i_repid       = '/PSYNG/SW_149'.
