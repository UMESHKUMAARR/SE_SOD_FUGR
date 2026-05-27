*----------------------------------------------------------------------*
* Report  /PSYNG/SW_063                                                *
* AUTHOR: Security Weaver, LLC                                         *
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
REPORT /psyng/sw_063 MESSAGE-ID /psyng/sw.
CONSTANTS: gc_change(1)  TYPE c VALUE 'C',
           gc_display(1) TYPE c VALUE 'D'.

CONTROLS: tc_cuscon TYPE TABLEVIEW USING SCREEN 0100.

DATA: BEGIN OF gt_cuscon OCCURS 0.
        INCLUDE STRUCTURE /psyng/sw_cuscon.
DATA:   sel(1) TYPE c,
      END OF gt_cuscon.

DATA: BEGIN OF gt_excfunc OCCURS 0,
        func TYPE rsmpe-func,
      END OF gt_excfunc.

DATA: g_tc_cuscon_wa2   LIKE LINE OF gt_cuscon,
      g_tc_cuscon_lines LIKE sy-loopc,
      ok_code           LIKE sy-ucomm,
      gf_auth_mode(1)   TYPE c,
      gf_dispchg(1)     TYPE c,
      gf_data_change    TYPE /psyng/bapiflagx,
      gf_answer(1)      TYPE c,
      g_current_user    TYPE sy-uname. "C0700

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
PARAMETERS: p_vrsio LIKE /psyng/sw_cuscon-vrsio.
SELECTION-SCREEN END OF BLOCK blk1.

*------------------------- AT SELECTION-SCREEN ------------------------*
AT SELECTION-SCREEN.
  AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
           ID 'ACTVT'      FIELD '02'
           ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO' FIELD p_vrsio.
  IF sy-subrc = 0.
    gf_auth_mode = gc_change.
    gf_dispchg   = gc_change.
  ELSE.
    AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
             ID 'ACTVT'      FIELD '03'
             ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_VRSIO' FIELD p_vrsio.
    IF sy-subrc = 0.
      gf_auth_mode = gc_display.
      gf_dispchg   = gc_display.
      MESSAGE s108 WITH text-002.
    ELSE.
      MESSAGE e108 WITH text-001.
    ENDIF.
  ENDIF.

* Validate version
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/swsodvers
                WHERE vrsio = p_vrsio.
  IF sy-subrc <> 0.
    MESSAGE e128 WITH text-t01.
  ENDIF.
* BOC by RGUPTA on 29.03.22 for C0700
  INITIALIZATION.
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 29.03.22 for C0700

*------------------------- START-OF-SELECTION ------------------------*
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
  PERFORM get_data.
  IF gf_auth_mode = gc_change.
    PERFORM enqueue.
  ENDIF.

  CALL SCREEN 100.

  INCLUDE /psyng/sw_063o01.
  INCLUDE /psyng/sw_063i01.
  INCLUDE /psyng/sw_063f01.
