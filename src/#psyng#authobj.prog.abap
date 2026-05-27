*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/AUTHOBJ
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
INCLUDE /psyng/authobjtop.
INCLUDE /psyng/authobjcl1.
INCLUDE /psyng/authobjo01.
INCLUDE /psyng/authobji01.
INCLUDE /psyng/authobjf01.

*------------------------- AT SELECTION-SCREEN ------------------------*
AT SELECTION-SCREEN.
* Validate version
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/swsodvers
                WHERE vrsio = p_vrsio.
  IF sy-subrc <> 0.
    MESSAGE e128(/psyng/sw) WITH text-017.
  ENDIF.

*------------------------- START-OF-SELECTION -------------------------*
START-OF-SELECTION.
*  DATA: licn TYPE sy-datum VALUE '20071210'.
*  IF sy-datum > licn.
*    MESSAGE e208(00) WITH
*       'License expired. Contact Security Weaver, LLC'.
*  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.
*EOC UMITTAL SE VF scan changes-25/11/2024

DATA : l_valuset_and TYPE flag. "(++)UMITTAL IBS Valueset AND rel

  IF p_nodsp = 'X'.
    gf_dispchg = gc_change.
*--> BOC UMITTAL 11.03.2025 IBS Valueset AND relation

    CLEAR l_valuset_and.
        SELECT SINGLE valueset_and INTO l_valuset_and
            FROM /psyng/vrs_and
                      WHERE vrsio = p_vrsio.
        IF sy-subrc EQ 0 AND
          l_valuset_and = 'X'.
          MESSAGE i353(/psyng/sw) WITH p_vrsio.
        ENDIF.
*--> EOC UMITTAL 11.03.2025 IBS Valueset AND relation
  ENDIF.

* Create application object to handle ABAP Objects Events of controls
  CREATE OBJECT g_application.
  PERFORM get_from_database.
  SET SCREEN 100.
