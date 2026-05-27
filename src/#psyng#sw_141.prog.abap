*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_141
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
*  Change Date  Changed by  Change Tag  Transport                      *
*  30/01/2020   Gurpinder   C0006       P33K940178                     *
*----------------------------------------------------------------------*

REPORT /PSYNG/SW_141 MESSAGE-ID /psyng/sw .
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /PSYNG/SW_141_TOP.
INCLUDE /PSYNG/SW_141_CL1.
INCLUDE /PSYNG/SW_141_I01.
INCLUDE /PSYNG/SW_141_O01.
INCLUDE /PSYNG/SW_141_F01.

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
  CREATE OBJECT gr_event_handler.
  CREATE OBJECT gr_event_handler_101.
   CALL SCREEN '0100'.
