*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_158
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
REPORT /psyng/sw_158.
TABLES: usr02,
        /psyng/swresusr,
        /psyng/conflict.
PARAMETERS : p_aid    TYPE /psyng/swreshdr-aid,
             p_local  TYPE flag,
             p_remote TYPE flag,
             p_cross  TYPE flag,
             p_mitcon TYPE flag,
             p_fun    TYPE flag,
             p_rolpro TYPE flag,
             p_orgvar TYPE flag,
             p_all    TYPE  flag,
             p_uswc   TYPE  flag,
             p_spath  TYPE  char200,
             p_ucount TYPE  i.
SELECT-OPTIONS: s_bname FOR usr02-bname,
                s_kostl FOR /psyng/swresusr-kostl
                        MATCHCODE OBJECT /psyng/kostl,
                s_class FOR usr02-class,
                s_comp  FOR /psyng/swresusr-company,
                s_dep   FOR /psyng/swresusr-department,
                usrtype FOR /psyng/swresusr-ustyp,
                s_conid FOR /psyng/conflict-conid,
                s_unum  FOR /psyng/swresusr-nr_conflicts,
                s_umnum FOR /psyng/swresusr-nr_mitigated.

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

CALL FUNCTION '/PSYNG/SW_STORED_SRVR_EXPORT'
  EXPORTING
    i_aid         = p_aid
    i_local       = p_local
    i_remote      = p_remote
    i_cross       = p_cross
    i_mitcon      = p_mitcon
    i_fun         = space
    i_rolpro      = space
    i_orgvar      = 'X'
    i_all         = p_all
    i_uswc        = p_uswc
    i_server_path = p_spath
    i_users_count = p_ucount
  TABLES
    i_bname       = s_bname
    i_class       = s_class
    i_kostl       = s_kostl
    i_comp        = s_comp
    i_dep         = s_dep
    i_unum        = s_unum
    i_umnum       = s_umnum
    i_usrtyp      = usrtype
    i_conid       = s_conid.
