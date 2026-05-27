REPORT /psyng/sw_134 .
tables: /psyng/swaudc2.

SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.
PARAMETERS: p_bname TYPE usr02-bname,
            p_frdate TYPE dats,
            p_todate TYPE dats,
            p_vrsio  TYPE /psyng/conflict-vrsio,
            p_conid  TYPE /psyng/conflict-conid,
            p_audid TYPE /psyng/swaudc2-swaudid.
selection-screen: end of block b1.

SELECTION-SCREEN: BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-t02.
PARAMETERS : p_shexe RADIOBUTTON GROUP rd1 DEFAULT 'X',
             p_shchg RADIOBUTTON GROUP rd1,
             p_sham RADIOBUTTON GROUP rd1.
SELECTION-SCREEN: END OF BLOCK b2.

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
*show execution history
  IF p_shexe = 'X'.
   CALL FUNCTION '/PSYNG/SW_MC_SHOW_EXECUTION'
         EXPORTING
              i_bname      = p_bname
              i_start_date = p_frdate
              i_end_date   = p_todate
              i_vrsio      = p_vrsio
              i_conid      = p_conid
              i_swaudid    = p_audid.

  ENDIF.

*show changes
  IF p_shchg = 'X'.
   CALL FUNCTION '/PSYNG/SW_MC_SHOW_CHANGES'
         EXPORTING
              i_bname      = p_bname
              i_start_date = p_frdate
              i_end_date   = p_todate
              i_vrsio      = p_vrsio
              i_conid      = p_conid
              i_swaudid    = p_audid.

  ENDIF.

*show am open alerts
  IF p_sham = 'X'.
    CALL FUNCTION '/PSYNG/SW_MC_SHOW_AMALERTS'
         EXPORTING
              i_bname      = p_bname
              i_start_date = p_frdate
              i_end_date   = p_todate
              i_vrsio      = p_vrsio
              i_conid      = p_conid
              i_swaudid    = p_audid.

  ENDIF.
