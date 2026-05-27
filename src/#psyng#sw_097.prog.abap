*----------------------------------------------------------------------*
* Report  /PSYNG/SW_097                                                *
* AUTHOR: Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
REPORT /psyng/sw_097 MESSAGE-ID /psyng/sw.

CONSTANTS: gc_change(1)  TYPE c VALUE 'C',
           gc_display(1) TYPE c VALUE 'D'.

CONTROLS: tc_remcon TYPE TABLEVIEW USING SCREEN 0100.

DATA: BEGIN OF gt_remcon OCCURS 0.
        INCLUDE STRUCTURE /psyng/sw_remcon.
DATA:   sel(1) TYPE c,
      END OF gt_remcon,

      BEGIN OF gt_excfunc OCCURS 0,
        func TYPE rsmpe-func,
      END OF gt_excfunc,

      g_tc_lines      LIKE sy-loopc,
      gs_remcon       LIKE LINE OF gt_remcon,
      ok_code         LIKE sy-ucomm,
      gt_e071         LIKE e071 OCCURS 0 WITH HEADER LINE,
      gt_e071k        LIKE e071k OCCURS 0 WITH HEADER LINE,
      g_trkorr        LIKE e071-trkorr,
*     Flags
      gf_auth_mode(1) TYPE c,
      gf_dispchg(1)   TYPE c,
      gf_data_change  TYPE /psyng/bapiflagx,
      gf_answer(1)    TYPE c.

*--------------------------- INITIALIZATION ---------------------------*
INITIALIZATION.
  AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
           ID 'ACTVT'      FIELD '02'
           ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  IF sy-subrc = 0.
    gf_auth_mode = gc_change.
    gf_dispchg   = gc_change.
  ELSE.
    AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
             ID 'ACTVT'      FIELD '03'
             ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
    IF sy-subrc = 0.
      gf_auth_mode = gc_display.
      gf_dispchg   = gc_display.
      MESSAGE s108 WITH text-002.
    ELSE.
      MESSAGE e108 WITH text-001.
    ENDIF.
  ENDIF.

*------------------------ START-OF-SELECTION --------------------------*
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

  INCLUDE /psyng/sw_097o01.
  INCLUDE /psyng/sw_097i01.
  INCLUDE /psyng/sw_097f01.
