*&---------------------------------------------------------------------*
*& Report  /PSYNG/SW_162
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT /psyng/sw_162 MESSAGE-ID /psyng/sw.

INCLUDE /psyng/sw_162_top. "include for data declaration
INCLUDE /psyng/sw_162_ss.  "include for selection Screen
INCLUDE /psyng/sw_162_f01.

AT SELECTION-SCREEN.

  "SOD version verification
  "HBHALLA BOC (19-12-23)
  IF p_vrsion EQ ' '.
    MESSAGE e215. "Fill in all the required fields.
    LEAVE LIST-PROCESSING.
  "END OF CHANGE.
  ELSE.
    IF p_vrsion = '000' OR p_vrsion = '999'.
      MESSAGE e214 WITH p_vrsion.
      LEAVE LIST-PROCESSING.
    ELSE.
      SELECT SINGLE mandt INTO g_mandt FROM /psyng/swsodvers
      WHERE vrsio = p_vrsion.
      IF sy-subrc <> 0.
        MESSAGE e156(/psyng/sw) WITH p_vrsion.
        LEAVE LIST-PROCESSING.
      ENDIF.
    ENDIF.
  ENDIF.

"SOD verison must be a numeric value.
  IF p_vrsion CN '0123456789 '.
    MESSAGE e217. "SOD verison must be a numeric value.
  ENDIF.

"Check if function ID is blank or not
  IF so_fun IS INITIAL.
    MESSAGE e216. "Fill in all the required fields.
    LEAVE LIST-PROCESSING.
    "HBHALLA BOC (19-12-23)
  ELSE.
      SELECT SINGLE mandt INTO g_mandt FROM /psyng/function
      WHERE vrsio = p_vrsion
      AND   function IN so_fun.

      IF sy-subrc <> 0.
        MESSAGE e045(/psyng/sw) WITH p_vrsion.
        LEAVE LIST-PROCESSING.
      ENDIF.
    "END OF CHANGE.
  ENDIF.

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
  PERFORM fetch_data CHANGING gt_functtran
                              gt_faobj2.
  PERFORM data_processing USING    gt_functtran
                                   gt_faobj2
                          CHANGING gt_logs
                                   g_total_count
                                   g_count
                                   g_functtran_count
                                   g_faobj2_count.

END-OF-SELECTION.
  IF NOT p_test IS INITIAL.
    CALL SCREEN 100.
  ELSE.
    PERFORM update_table USING gt_functtran
                               gt_faobj2
                               g_total_count
                               g_count
                               g_functtran_count
                               g_faobj2_count.

  ENDIF.
