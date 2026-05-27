REPORT /PSYNG/SW_138 .

tables: /PSYNG/SWRESHDR.
include :
   /PSYNG/SW_CONFIG,
   /PSYNG/SW_138_TOP,
   /PSYNG/SW_138_CL1,
   /PSYNG/SW_138_O01,
   /PSYNG/SW_138_I01,
   /PSYNG/SW_138_F01,
   /psyng/basis_exelog.
parameters :
  p_vrsio type /psyng/sodvrsio.
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
  CREATE OBJECT gr_event_handler.
  CALL SCREEN '0100'.

INITIALIZATION.
*--Register report for Most Used Reports
  CALL FUNCTION '/PSYNG/SW_128'
  EXPORTING
  i_repid       = '/PSYNG/SW_138'.
 exelog sy-repid ''.
