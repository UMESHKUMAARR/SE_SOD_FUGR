FUNCTION /psyng/sw_adm_cockpit_overview.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  EXPORTING
*"     VALUE(E_HEADER) TYPE  /PSYNG/SWADMOVW
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_ADM_COCKPIT_OVERVIEW'.
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

  DATA :   l_dflt_vrsio  TYPE /psyng/param.
*--sysid
  CONCATENATE sy-sysid sy-mandt INTO e_header-systid.

*--Get Program version of Separations Enforcer
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
       EXPORTING
            i_module         = 'SE'
       IMPORTING
            e_module_version = e_header-version.

*---vrsio count
  SELECT COUNT(*) FROM /psyng/swsodvers "#EC CI_NOWHERE
         INTO e_header-sodvrsio_nr.

*---cfgset count
  SELECT COUNT(*) FROM /psyng/swcfgset  "#EC CI_NOWHERE
         INTO e_header-cfgset_nr.

*--Get default version
  se_config_param 'DFLT_GLOBAL_VERSION' l_dflt_vrsio.
  e_header-dflt_vrsio = l_dflt_vrsio.

*---latest stored results
  SELECT MAX( aid ) FROM /psyng/swreshdr INTO "#EC CI_NOFIELD
  e_header-lsr_aid                            "#EC CI_NOFIRST
  WHERE end_date NE '00000000'
    AND end_time NE '000000'
    AND no_restrictions EQ 'X'.

  IF NOT e_header-lsr_aid IS INITIAL.
    SELECT SINGLE bname start_date sodvrsio setid
        users_analyzed conflicted_users
    FROM /psyng/swreshdr INTO
    (e_header-lsr_user, e_header-lsr_date,  e_header-lsr_vrsio,
    e_header-setid, e_header-users_analyzed,
e_header-conflicted_users)
        WHERE aid = e_header-lsr_aid.
  ENDIF.

ENDFUNCTION.
