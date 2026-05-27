*&---------------------------------------------------------------------*
*& Report  /PSYNG/SW_NAV_CON
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT /psyng/sw_nav_con.

INCLUDE /psyng/sw_nav_con_top.
INCLUDE /psyng/sw_nav_con_scr.
INCLUDE /psyng/sw_nav_con_f01.



AT SELECTION-SCREEN.
  PERFORM validate_field.


  "------------------------------------------------------------
  " F4 help for P_CONID based on P_VRSIO
  "------------------------------------------------------------

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_conid.
  PERFORM search_help.

START-OF-SELECTION.
  AUTHORITY-CHECK OBJECT 'S_PROGRAM'
         ID 'P_GROUP' FIELD 'SW_SE'
         ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) WITH 'execute '(004) sy-repid.
    EXIT.
  ENDIF.
  CLEAR l_uname.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name =  l_uname.

*-- Get user's default version
  SELECT SINGLE parva INTO l_parva FROM usr05
             WHERE bname = l_uname
               AND parid = '/PSYNG/VRSIO'.
  l_parva_exists = sy-subrc.
  IF l_parva_exists = 0 AND l_parva <> space.
    l_sod = l_parva.
  ENDIF.

  PERFORM set_default_sodversion USING p_vrsio l_uname 0.
  SET PARAMETER ID '/PSYNG/CON' FIELD p_conid.
  g_dynnr = '0202'.
  EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
  AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
  IF sy-subrc <> 0.
    MESSAGE e077(s#) WITH '/PSYNG/SE'.
  ELSE.
    CALL TRANSACTION '/PSYNG/SE'.
  ENDIF.
*-- Set back to Default
  PERFORM set_default_sodversion USING l_sod l_uname l_parva_exists.
  EXIT.
