*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_128
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
REPORT /psyng/sw_128 MESSAGE-ID /psyng/sw.

START-OF-SELECTION.
*BOC AKUMAR SE VF scan changes-12/04/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-12/04/2024
*--Functionality is Obsolete
MESSAGE s002 WITH 'Functionality is Obsolete'.
