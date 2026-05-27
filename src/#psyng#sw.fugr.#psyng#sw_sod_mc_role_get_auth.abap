FUNCTION /psyng/sw_sod_mc_role_get_auth.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(AGR_NAME) TYPE  AGR_NAME OPTIONAL
*"     VALUE(CONID) TYPE  /PSYNG/CONFLICT_ID OPTIONAL
*"  TABLES
*"      MCROLEAUTH_FM STRUCTURE  /PSYNG/SW_MC_ROLE_AUTHS
*"      ROLES_FM STRUCTURE  /PSYNG/MCROLE OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_SOD_MC_ROLE_GET_AUTH'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026

  PERFORM get_role_auth USING agr_name conid.

  LOOP AT roles_fm.
    PERFORM get_role_auth USING roles_fm-agr_name roles_fm-conid.
  ENDLOOP.

  mcroleauth_fm[] = mcroleauth[].
  FREE mcroleauth.

ENDFUNCTION.


*---------------------------------------------------------------------*
*       FORM get_single_role_auth                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IAGR_NAME                                                     *
*---------------------------------------------------------------------*
FORM get_role_auth USING iagr_name TYPE agr_define-agr_name
                         iconid type /psyng/conflict-conid.
  SELECT object auth INTO  (wa_mcroleauth-objct, wa_mcroleauth-auth )
                     FROM agr_1251
                     WHERE agr_name = iagr_name AND
                           deleted NE 'X'.
* profile name should be enough instead of entire auth name, also
* this way saves memory since multiple auths don't need to be stored
    wa_mcroleauth-auth+10(2) = '  '.
    CONCATENATE sy-sysid sy-mandt INTO wa_mcroleauth-rfcdest.
*    wa_mcroleauth-sagr_name = iagr_name.
    wa_mcroleauth-conid = iconid.
    INSERT wa_mcroleauth INTO TABLE mcroleauth.
  ENDSELECT.

  CHECK sy-subrc NE 0.   "if role is composite
  SELECT child_agr FROM agr_agrs
                   INTO role
                   WHERE agr_name = iagr_name
                   AND attributes <> 'X'.
    SELECT object auth INTO  (wa_mcroleauth-objct, wa_mcroleauth-auth )
                       FROM agr_1251
                       WHERE agr_name = role AND
                             deleted NE 'X'.
* profile name should be enough instead of entire auth name, also
* this way saves memory since multiple auths don't need to be stored
      wa_mcroleauth-auth+10(2) = '  '.
      CONCATENATE sy-sysid sy-mandt INTO wa_mcroleauth-rfcdest.
*      wa_mcroleauth-sagr_name = role.
*      wa_mcroleauth-cagr_name = iagr_name.
      wa_mcroleauth-conid = iconid.
      INSERT wa_mcroleauth INTO TABLE mcroleauth.
    ENDSELECT.
  ENDSELECT.
ENDFORM.
