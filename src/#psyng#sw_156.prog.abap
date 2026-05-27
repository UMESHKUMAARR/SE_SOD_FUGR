
REPORT /psyng/sw_156.

INCLUDE /psyng/sw_156_top.
INCLUDE /psyng/sw_156_cls.

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
  CREATE OBJECT gr_event_handler.
  gf_dispchg = gc_display.
* BOC by GSINGH on 06.02.2023 for B17166 - Adding authorization check
  PERFORM check_authorization
              USING
                 gf_dispchg.
* EOC by GSINGH.
  PERFORM get_data CHANGING gt_res_access.
  CALL SCREEN 100.

  INCLUDE /psyng/sw_156_seto01.

  INCLUDE /psyng/sw_156_seti01.

  INCLUDE /psyng/sw_156_setf01.
