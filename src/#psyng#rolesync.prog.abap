*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/ROLESYNC
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/rolesync NO STANDARD PAGE HEADING.
TABLES: /psyng/roletrans, /psyng/rolehdr, agr_1251, agr_tcodes.

DATA gv_i TYPE i.

DATA: BEGIN OF itab OCCURS 0,
      tcode LIKE /psyng/roletrans-tcode,
END OF itab.

DATA: BEGIN OF jtab OCCURS 0,
      tcode LIKE /psyng/roletrans-tcode,
END OF jtab.

PARAMETERS : roleid LIKE /psyng/roletrans-roleid.

DATA: iagr_tcodes TYPE STANDARD TABLE OF agr_tcodes WITH HEADER LINE,
      gv_saptechname TYPE /psyng/rolehdr-saptechname.



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
  IF NOT roleid IS INITIAL.
    AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
             ID 'ACTVT' FIELD '01'
             ID 'Y&SW_ROLID' FIELD roleid.
*BOC:UMITTAL CVA scan fix 27/02/2026
       IF sy-subrc <> 0.
         MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
         LEAVE LIST-PROCESSING.
       ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ELSE.
    AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
            ID 'ACTVT' FIELD '01'
            ID 'Y&SW_ROLID' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
         IF sy-subrc <> 0.
           MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
           LEAVE LIST-PROCESSING.
         ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ENDIF.
  IF sy-subrc NE 0.
   MESSAGE e398(00) WITH 'You are not Authorized to Sync.'(010).
  ENDIF.

  WRITE:/
'**********************************************************************'
.
  WRITE:/.
  WRITE:/ text-001, roleid.
  WRITE:/
'**********************************************************************'
.
  WRITE:/.

  SELECT SINGLE saptechname INTO gv_saptechname
   FROM /psyng/rolehdr
    WHERE roleid = roleid.

*  IF /PSYNG/ROLEHDR-SAPTECHNAME = SPACE.
  IF gv_saptechname = space.
    WRITE:/ text-002.
  ELSE.
    SELECT * FROM /psyng/roletrans
    WHERE roleid = roleid.
      itab-tcode = /psyng/roletrans-tcode.
      APPEND itab.
    ENDSELECT.

    CALL FUNCTION '/PSYNG/SW_POPULATE_S_TCODE'
         EXPORTING
              p_agrname   = gv_saptechname  "/PSYNG/ROLEHDR-SAPTECHNAME
         TABLES
              iagr_tcodes = iagr_tcodes.

    LOOP AT iagr_tcodes.
      jtab-tcode = iagr_tcodes-tcode.
      APPEND jtab.
    ENDLOOP.

*    SELECT * FROM AGR_1251
*    WHERE AGR_NAME  = /PSYNG/ROLEHDR-SAPTECHNAME
*    AND OBJECT = 'S_TCODE'
*    AND FIELD = 'TCD'.
*       perform
*      JTAB-TCODE = AGR_1251-LOW.
*      APPEND JTAB.
*    ENDSELECT.
    gv_i = 0.
    WRITE:/ text-003.
    LOOP AT itab.
      READ TABLE jtab WITH KEY tcode = itab-tcode.
      IF sy-subrc <> 0.
        WRITE:/ itab-tcode.
        gv_i = gv_i + 1.
      ENDIF.
    ENDLOOP.

    WRITE:/ text-004, gv_i.
    WRITE:/.
    WRITE:/.
    gv_i = 0.
    WRITE:/ text-005.
    LOOP AT jtab.
      READ TABLE itab WITH KEY tcode = jtab-tcode.
      IF sy-subrc <> 0.
        WRITE:/ jtab-tcode.
        gv_i = gv_i + 1.
      ENDIF.
    ENDLOOP.
    WRITE:/ text-004, gv_i.


  ENDIF.
