*----------------------------------------------------------------------*
* Report  /PSYNG/SW_LOCCFG                                             *
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
REPORT /psyng/sw_loccfg MESSAGE-ID /psyng/sw.

CONSTANTS: gc_delimit(1) TYPE c VALUE ';'.


CONTROLS: tc_orgnr_ug  TYPE TABLEVIEW USING SCREEN 0100,
          tc_orgnr_adr TYPE TABLEVIEW USING SCREEN 0200,
          tc_loccfg    TYPE TABLEVIEW USING SCREEN 0300,
          tc_orgnr_usr TYPE TABLEVIEW USING SCREEN 0400.

DATA: g_mode(1)            TYPE c,
      g_tabname            TYPE tabname,
      ok_code              LIKE sy-ucomm,
      g_tc_orgnr_ug_lines  LIKE sy-loopc,
      g_tc_orgnr_adr_lines LIKE sy-loopc,
      g_tc_loccfg_lines    LIKE sy-loopc,
      g_tc_orgnr_usr_lines LIKE sy-loopc,
      g_filename           TYPE string,
      gf_data_change       TYPE /psyng/bapiflagx,
      gf_serverfile        TYPE /psyng/bapiflagx,
      gf_localfile         TYPE /psyng/bapiflagx.

DATA: BEGIN OF gt_orgnr_ug OCCURS 0.
        INCLUDE STRUCTURE /psyng/orgnr_ug.
DATA:   sel(1) TYPE c,
      END OF gt_orgnr_ug.

DATA: BEGIN OF gt_orgnr_adr OCCURS 0.
        INCLUDE STRUCTURE /psyng/orgnr_adr.
DATA:   sel(1) TYPE c,
      END OF gt_orgnr_adr.

DATA: BEGIN OF gt_loccfg OCCURS 0.
        INCLUDE STRUCTURE /psyng/sw_loccfg.
DATA:   sel(1) TYPE c,
      END OF gt_loccfg.

DATA: BEGIN OF gt_orgnr_usr OCCURS 0.
        INCLUDE STRUCTURE /psyng/orgnr_usr.
DATA:   sel(1) TYPE c,
      END OF gt_orgnr_usr.

DATA: BEGIN OF gt_excfunc OCCURS 0,
        func TYPE rsmpe-func,
      END OF gt_excfunc.

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
PARAMETERS: p_userg RADIOBUTTON GROUP gr1,
            p_comp  RADIOBUTTON GROUP gr1,
            p_user  RADIOBUTTON GROUP gr1,
            p_confg RADIOBUTTON GROUP gr1.
SELECTION-SCREEN END OF BLOCK blk1.

*------------------------- START-OF-SELECTION ------------------------*
START-OF-SELECTION.

*BOC AKUMAR SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-25/11/2024
  CASE 'X'.
    WHEN p_userg.
      g_tabname = '/PSYNG/ORGNR_UG'.
      PERFORM get_data_100.
      CALL SCREEN 100.
    WHEN p_comp.
      g_tabname = '/PSYNG/ORGNR_ADR'.
      PERFORM get_data_200.
      CALL SCREEN 200.
    WHEN p_confg.
      g_tabname = '/PSYNG/SW_LOCCFG'.
***********************************
**Authorization check for Display table /PSYNG/SW_LOCCFG
**SF 1665
      AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
                 ID 'ACTVT' FIELD '03'
                 ID 'DICBERCLS' FIELD 'Y&S2'.
      IF sy-subrc EQ 0.
**SF 1665
***********************************
        PERFORM get_data_300.
        CALL SCREEN 300.
******************************************
**SF 1665
      ELSE.
        MESSAGE e113(/psyng/sw) WITH text-e02  '/PSYNG/SW_LOCCFG'.
        STOP.
      ENDIF.
**SF 1665
*********************************************
    WHEN p_user.
      g_tabname = '/PSYNG/ORGNR_USR'.
      PERFORM get_data_400.
      CALL SCREEN 400.
  ENDCASE.

  INCLUDE /psyng/sw_loccfgf01.
  INCLUDE /psyng/sw_loccfgo01.
  INCLUDE /psyng/sw_loccfgi01.
