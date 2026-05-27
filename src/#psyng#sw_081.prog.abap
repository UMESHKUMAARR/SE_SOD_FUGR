*----------------------------------------------------------------------*
* Report  /PSYNG/SW_081                                                *
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
REPORT /psyng/sw_081 NO STANDARD PAGE HEADING
                     LINE-COUNT 65
                     LINE-SIZE 500
                     MESSAGE-ID /psyng/sw.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /PSYNG/BASIS_EXELOG.
INCLUDE /psyng/sw_081top.      "TOP include
INCLUDE /psyng/sw_081cl1.      "Classes
INCLUDE /psyng/sw_081o01.      "PBO modules
INCLUDE /psyng/sw_081i01.      "PAI modules
INCLUDE /psyng/sw_081f01.      "Forms
INCLUDE /psyng/sw_081f02.      "Tree forms

*------------------------- AT SELECTION-SCREEN ------------------------*
AT SELECTION-SCREEN.

  IF p_cfunc <> 'X' AND
    p_cconf  <> 'X' AND
    p_ctran  <> 'X' AND
    p_cauth  <> 'X' AND
    p_crole  <> 'X' AND
    p_cprof  <> 'X'.
    MESSAGE e002 WITH 'Please select at least one checkbox'(s00)
    'to compare'(s04).
    LEAVE LIST-PROCESSING.
  ENDIF.


  IF p_rvrsio = p_lvrsio.
    MESSAGE e113 WITH text-002.
  ENDIF.

* Check that both versions exist
  SELECT SINGLE vdesc INTO g_lvdesc FROM /psyng/swsodvers
                WHERE vrsio = p_lvrsio.
  IF sy-subrc <> 0.
    MESSAGE e113 WITH text-c01 text-001.
  ENDIF.

  SELECT SINGLE vdesc INTO g_rvdesc FROM /psyng/swsodvers
                WHERE vrsio = p_rvrsio.
  IF sy-subrc <> 0.
    MESSAGE e113 WITH text-c02 text-001.
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
EXELOG sy-repid ''.

* Check if user wants the output details in ALV format or standard list
* G_FORMAT = 'LIST' for list format
  se_config_param 'SW_SOD_REPO_DETAIL' g_format.

  PERFORM compare_functions.
  PERFORM compare_conflicts.
  PERFORM compare_crit_tcodes.
  PERFORM compare_crit_auths.
  PERFORM compare_crit_roles.
  PERFORM compare_crit_profs.

  CHECK g_format <> 'LIST'.
  CREATE OBJECT go_application.
  CALL SCREEN 100.

*----------------------------- TOP-OF-PAGE ----------------------------*
TOP-OF-PAGE.
  FORMAT COLOR COL_HEADING.
  WRITE: /   p_lvrsio, g_lvdesc,
         135 sy-vline,
         136 p_rvrsio, g_rvdesc.
  FORMAT COLOR COL_BACKGROUND.
  ULINE.
