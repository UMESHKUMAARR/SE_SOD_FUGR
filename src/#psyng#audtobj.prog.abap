*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/AUDTOBJ
* AUTHOR                : Security Weaver, LLC
* RELEASE               : 1.0.1.0
* DATE OF RELEASE       :
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNaudtORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
INCLUDE /psyng/audtobjtop.
INCLUDE /psyng/audtobjcl1.
INCLUDE /psyng/audtobjo01.
INCLUDE /psyng/audtobji01.
INCLUDE /psyng/audtobjf01.

*------------------------- AT SELECTION-SCREEN ------------------------*
AT SELECTION-SCREEN.
* Validate version
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/swsodvers
                WHERE vrsio = p_vrsio .
  IF sy-subrc <> 0.
    MESSAGE e128(/psyng/sw) WITH text-016.
  ENDIF.

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
  IF p_nodsp = 'X'.
    gf_dispchg = gc_change.
  ENDIF.

* Create application object to handle ABAP Objects Events of controls
  CREATE OBJECT g_application.
  PERFORM get_from_database.
  SET SCREEN 100.
