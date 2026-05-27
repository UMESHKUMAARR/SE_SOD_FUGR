*----------------------------------------------------------------------*
* Report  /PSYNG/SW_084                                                *
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
REPORT /psyng/sw_084 MESSAGE-ID /psyng/sw.
CONSTANTS: gc_change(1)  TYPE c VALUE 'C',
           gc_display(1) TYPE c VALUE 'D'.

CONTROLS: tc_sodvers TYPE TABLEVIEW USING SCREEN 0100.

DATA: BEGIN OF gt_sodvers OCCURS 0.
        INCLUDE STRUCTURE /psyng/swsodvers.
DATA:   sel(1) TYPE c,
      END OF gt_sodvers.
data: gt_change like table of gt_sodvers with header line.
DATA: BEGIN OF gt_del OCCURS 0,
        vrsio TYPE /psyng/swsodvers-vrsio,
      END OF gt_del.

DATA: BEGIN OF gt_excfunc OCCURS 0,
        func TYPE rsmpe-func,
      END OF gt_excfunc.

DATA: g_lines         LIKE sy-loopc,
      ok_code         LIKE sy-ucomm,
      gs_tc_sodvers   LIKE LINE OF gt_sodvers,
      gf_dispchg(1)   TYPE c,
      gf_auth_mode(1) TYPE c,
      gf_del_auth(1)  TYPE c,
      gf_data_change  TYPE /psyng/bapiflagx,
      gf_answer(1)    TYPE c.

*--------------------------- INITIALIZATION ---------------------------*
INITIALIZATION.
* Check for change authority
  AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
           ID 'ACTVT' FIELD '02'
           ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  IF sy-subrc = 0.
    gf_auth_mode = gc_change.

*   Check for delete authority
    AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
             ID 'ACTVT' FIELD '06'
             ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
    IF sy-subrc = 0.
      gf_del_auth = 'X'.
    ENDIF.
  ELSE.
*   Check for display authority
    AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
             ID 'ACTVT' FIELD '03'
             ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
    IF sy-subrc = 0.
      gf_auth_mode = gc_display.
      MESSAGE s108 WITH text-003.
    ELSE.
      MESSAGE e108 WITH text-002.
    ENDIF.
  ENDIF.

  gf_dispchg = gc_display.

*------------------------- START-OF-SELECTION -------------------------*
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
  PERFORM enqueue.

  CALL SCREEN 100.

  INCLUDE /psyng/sw_084o01.
  INCLUDE /psyng/sw_084i01.
  INCLUDE /psyng/sw_084f01.
