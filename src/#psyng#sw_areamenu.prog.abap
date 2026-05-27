REPORT /psyng/sw_areamenu .

DATA: l_menu LIKE ttree-id.

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

  MOVE sy-tcode TO l_menu.

  CALL FUNCTION 'BMENU_START_BROWSER'
    EXPORTING
      mode                             = 'D'
      tree_id                          = l_menu
*   NODE_ID                          = ' '
*   STANDARD_VIEW                    = ' '
*   HIDE_INCONSISTENT_NODES          = 'X'
*   GUI_STATUS_DISPLAY               = ' '
*   GUI_STATUS_EDIT                  = ' '
*   GUI_STATUS_PROG                  = ' '
*   GUI_TITLE_DISPLAY                = ' '
*   GUI_TITLE_EDIT                   = ' '
*   GUI_TITLE_TEXT                   = ' '
*   HIDE_TOGGLE_BUTTON               = ' '
*   STATUS_EXCL_TABLE                =
*   NEW_STRUCTURE                    = ' '
*   APPL_MENU_FUNCTION               = ' '
* IMPORTING
*   STRUCTURE_MODIFIED               =
* TABLES
*   ADDITIONAL_USER_PARAMETERS       =
    EXCEPTIONS
     tree_does_not_exist              = 1
     no_authority                     = 2
     OTHERS                           = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
           WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
