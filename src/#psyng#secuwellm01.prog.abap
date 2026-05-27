*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SECUWELLM01                                         *
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
*   LOG_EXC_VERS_100                                                   *
*----------------------------------------------------------------------*
*   For screen 100, check if SOD versions are to be excluded.  If so,  *
*   hide the menu path for setting versions and default version to 000.*
*----------------------------------------------------------------------*
DEFINE log_exc_vers_100.
* Check if maintenance of SOD versions is to be excluded
  IF gf_excl_sodvers <> 'Y'.
    CALL FUNCTION '/PSYNG/BC_001'
      EXPORTING
        i_product         = 'SE'
        i_func_name       = 'SODVERSION'
     IMPORTING
        ef_func_exc       = gf_excl_sodvers.
  ENDIF.

  IF gf_excl_sodvers = 'Y'.
*   Hide menu
    gt_func-fcode = 'SETVRSIO'.
    APPEND gt_func.

    g_sod_vrsio = '000'.
  ENDIF.
END-OF-DEFINITION.          "log_exc_vers_100

*----------------------------------------------------------------------*
*   LOG_EXC_VERS_107                                                   *
*----------------------------------------------------------------------*
*   For screen 107, check if SOD versions are to be excluded.  If so,  *
*   hide the buttons that maintain versions.                           *
*   Removed in SE4.5PS1 2021/02/22
*----------------------------------------------------------------------*
*DEFINE log_exc_vers_107.
*  IF gf_excl_sodvers <> 'Y'.
*    CALL FUNCTION '/PSYNG/BC_001'
*      EXPORTING
*        i_product         = 'SE'
*        i_func_name       = 'SODVERSION'
*     IMPORTING
*        ef_func_exc       = gf_excl_sodvers.
*  ENDIF.
*
*  IF gf_excl_sodvers = 'Y'.
**   Hide buttons
*    LOOP AT screen.
*      CHECK screen-name = 'SODVERSIONS' OR screen-name = 'SODVERS'
*      OR screen-name = 'SW_080' OR screen-name = 'SW_081'.
*
*      screen-invisible = '1'.
*      MODIFY screen.
*    ENDLOOP.
*  ENDIF.
*END-OF-DEFINITION.          "log_exc_vers_107

*----------------------------------------------------------------------*
*   LOG_EXC_ORG_107                                                    *
*----------------------------------------------------------------------*
*   For screen 107, check if Org level maintenance is to be excluded.  *
*   If so, hide the button that maintains this.                        *
*   Removed in SE4.5PS1 2021/02/22
*----------------------------------------------------------------------*
*DEFINE log_exc_org_107.
*  IF gf_excl_orgcheck IS INITIAL.
*    CALL FUNCTION '/PSYNG/BC_001'
*      EXPORTING
*        i_product         = 'SE'
*        i_func_name       = 'ORGCHECK'
*     IMPORTING
*        ef_func_exc       = gf_excl_orgcheck.
*  ENDIF.
*
*  IF gf_excl_orgcheck = 'Y'.
**   Hide button
*    LOOP AT screen.
*      CHECK screen-name = 'MAINTAIN_ORG_LEVEL'.
*      screen-invisible = '1'.
*      MODIFY screen.
*      EXIT.
*    ENDLOOP.
*  ENDIF.
*END-OF-DEFINITION.          "log_exc_org_107
