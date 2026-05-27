*&---------------------------------------------------------------------*
*& Report  ZARPAN_EXPORT_TO_SERVER
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT /psyng/sw_159.

TABLES : agr_define, /psyng/conflict, /psyng/swrrsrol.

DATA : ls_ba_role TYPE /psyng/bc_ba_00.

PARAMETERS : p_aid TYPE /psyng/swrrshdr-aid,
             p_comp TYPE flag,
             p_sing TYPE flag,
             p_assr TYPE flag,
             p_mitcon TYPE flag,
             p_fun    TYPE flag,
             p_orgvar TYPE flag,
             p_all   TYPE flag,
             p_rswc  TYPE flag,
             p_rswoc TYPE flag,
             p_spath  TYPE  char200,
             p_rcount TYPE  i.

SELECT-OPTIONS :
   s_role  FOR agr_define-agr_name,
   rba     FOR ls_ba_role-busarea,
   s_conid FOR /psyng/conflict-conid,
   s_rnum  FOR /psyng/swrrsrol-nr_conflicts,
   s_rmnum FOR /psyng/swrrsrol-nr_mitigated.

*BOC AKUMAR SE VF scan changes-25/11/2024
START-OF-SELECTION.

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-25/11/2024

CALL FUNCTION '/PSYNG/SW_STORED_ROL_SRVR_EXPT'
  EXPORTING
    i_all          = p_all
    i_rswc         = p_rswc
    i_aid          = p_aid
    i_comp         = p_comp
    i_sing         = p_sing
    i_assr         = p_assr
    i_mitcon       = p_mitcon
    i_fun          = space
    i_orgvar       = 'X'
    i_rswoc        = p_rswoc
    i_roles_count  = p_rcount
    i_server_path  = p_spath
*        I_EXPORT       = 'X'
  TABLES
    i_role         = s_role
    i_rba          = rba
    i_conid        = s_conid
    i_rnum         = s_rnum
    i_rmnum        = s_rmnum.
