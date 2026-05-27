FUNCTION /psyng/sw_remote_search_helps.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/VRSIO OPTIONAL
*"     VALUE(IF_VRSIO) TYPE  FLAG OPTIONAL
*"     VALUE(IF_FUNCTION) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CONFLICT) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CRIT_AUTH) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CUS_CON) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CRIT_TCODE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CRIT_ROLE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CRIT_PROF) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CONFIG) TYPE  FLAG OPTIONAL
*"     VALUE(IF_RULE_VERSIONS) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ELEMENTS) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CALLED_TCODES) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CALLING_TCODES) TYPE  FLAG OPTIONAL
*"     VALUE(IF_SETID) TYPE  FLAG OPTIONAL
*"     VALUE(IF_BUSAREA) TYPE  FLAG OPTIONAL
*"     VALUE(IF_RISK) TYPE  FLAG OPTIONAL
*"     VALUE(IF_MCHDR) TYPE  FLAG OPTIONAL
*"     VALUE(IF_SUBAREA) TYPE  FLAG OPTIONAL
*"     VALUE(IF_SYS_TYPE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_SYS_CAT) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(E_AUTH_CHECK) TYPE  FLAG
*"  TABLES
*"      IT_VEVRS STRUCTURE  /PSYNG/RANGE_SE_VE_VRSIO OPTIONAL
*"      ET_VRSIO STRUCTURE  /PSYNG/SWSODVERS OPTIONAL
*"      ET_FUNCTION STRUCTURE  /PSYNG/FUNCTION OPTIONAL
*"      ET_CONFLICT STRUCTURE  /PSYNG/CONFLICT OPTIONAL
*"      ET_CRIT_AUTH STRUCTURE  /PSYNG/SWAUDHDR OPTIONAL
*"      ET_CUS_CON STRUCTURE  /PSYNG/SW_CUSCON OPTIONAL
*"      ET_CRIT_TCODE STRUCTURE  /PSYNG/CRI_TCODES_F4 OPTIONAL
*"      ET_CRIT_ROLE STRUCTURE  /PSYNG/CRI_ROLES_F4 OPTIONAL
*"      ET_CRIT_PROF STRUCTURE  /PSYNG/CRI_PROF_F4 OPTIONAL
*"      ET_CONFIG STRUCTURE  /PSYNG/SWCONFIG OPTIONAL
*"      ET_RULE_VERSIONS STRUCTURE  /PSYNG/SW_VARVR OPTIONAL
*"      ET_ELEMENTS STRUCTURE  /PSYNG/SW_VAREL OPTIONAL
*"      ET_CALLED_TCODES STRUCTURE  /PSYNG/SW_EXCDTX OPTIONAL
*"      ET_CALLING_TCODES STRUCTURE  /PSYNG/SW_EXCLTX OPTIONAL
*"      ET_SETID STRUCTURE  /PSYNG/SETID_F4 OPTIONAL
*"      ET_BUSAREA STRUCTURE  /PSYNG/BUSAREA OPTIONAL
*"      ET_RISK STRUCTURE  /PSYNG/SW_RISK OPTIONAL
*"      ET_MCHDR STRUCTURE  /PSYNG/MCHDR OPTIONAL
*"      ET_SUBAREA STRUCTURE  /PSYNG/BUS_PROCE OPTIONAL
*"      ET_SYS_TYPE STRUCTURE  /PSYNG/SW_SYSTYP OPTIONAL
*"      ET_SYS_CAT STRUCTURE  /PSYNG/SW_SYSCAT OPTIONAL
*"----------------------------------------------------------------------
**--> BOC PN 11269 - ATC fixes - UMITTAL - 13/01/25
   CONSTANTS: lc_fname TYPE rs38l_fnam
   VALUE '/PSYNG/SW_REMOTE_SEARCH_HELPS'.
*  S_RFC AUTHORITY CHECK
   AUTHORITY-CHECK OBJECT 'S_RFC'
         ID 'RFC_TYPE' FIELD 'FUNC'
         ID 'RFC_NAME' FIELD lc_fname
         ID 'ACTVT' FIELD '16'.
   IF sy-subrc <> 0.
*--> BOC UMITTAL 06/01/2026 PN17034
*     MESSAGE s089(/psyng/sw) WITH lc_fname.
     MESSAGE 'You are Not Authorized'(e32)  TYPE 'S'
     DISPLAY LIKE 'E'.
     e_auth_check = 'X'.
     RETURN.
*<-- EOC UMITTAL 06/01/2026 PN17034
   ENDIF.

*--> EOC PN 11269 - ATC fixes - UMITTAL - 13/01/25
  DATA: ls_setid    TYPE /psyng/setid_f4,
        lt_swcfgset TYPE TABLE OF /psyng/swcfgset WITH HEADER LINE,
        lt_swcfgsys TYPE TABLE OF /psyng/swcfgsys WITH HEADER LINE.

*--Export all SOD matrix versions
  IF NOT  if_vrsio IS INITIAL.
    SELECT vrsio vdesc FROM /psyng/swsodvers
    INTO CORRESPONDING FIELDS OF TABLE et_vrsio.
  ENDIF.
*--Export all functions for SOD version
  IF NOT if_function IS INITIAL.
    SELECT * INTO TABLE et_function
      FROM /psyng/function.
    SORT et_function BY function vrsio.
  ENDIF.
*--Export all conflicts for SOD version
  IF NOT if_conflict IS INITIAL.
    SELECT * INTO TABLE et_conflict
      FROM /psyng/conflict.
    SORT et_conflict BY conid vrsio.
  ENDIF.
*--Export critical authorizations for SOD version
  IF NOT if_crit_auth IS INITIAL.
    SELECT * INTO TABLE et_crit_auth
      FROM /psyng/swaudhdr.
  ENDIF.
*--Export custom conflicts for SOD version
  IF NOT if_cus_con IS INITIAL.
    SELECT * INTO TABLE et_cus_con
      FROM /psyng/sw_cuscon
      WHERE vrsio = i_vrsio.
  ENDIF.
*--Export critical transactions for SOD version
  IF NOT if_crit_tcode IS INITIAL.
    SELECT a~tcode
           a~vrsio
           a~owner
           a~imp
           b~ttext INTO TABLE et_crit_tcode
           FROM /psyng/critcodes AS a INNER JOIN tstct AS b
           ON a~tcode EQ b~tcode
           WHERE vrsio = i_vrsio.
  ENDIF.
*--Export critical roles for SOD version
  IF NOT if_crit_role IS INITIAL.
    SELECT a~agr_name
           a~vrsio
           a~owner
           a~imp
           b~text INTO TABLE et_crit_role
           FROM /psyng/criroles AS a INNER JOIN agr_texts AS b
           ON a~agr_name EQ b~agr_name
           WHERE vrsio = i_vrsio
             AND line EQ space.
  ENDIF.
*--Export critical profiles for SOD version
  IF NOT if_crit_prof IS INITIAL.
    SELECT a~profile
           a~vrsio
           a~owner
           a~imp
           b~ptext INTO TABLE et_crit_prof
           FROM /psyng/criprof AS a INNER JOIN usr11 AS b
           ON a~profile EQ b~profn
           WHERE vrsio = i_vrsio.
  ENDIF.
*--Export configuration parameters
  IF NOT if_config IS INITIAL.
    SELECT * INTO TABLE et_config
      FROM /psyng/swconfig.
    SORT et_config BY param.
  ENDIF.
*--Export variable element rule versions
  IF NOT if_rule_versions IS INITIAL.
    SELECT * INTO TABLE et_rule_versions
      FROM /psyng/sw_varvr.
  ENDIF.
*--Export variable elements rules
  IF NOT if_elements IS INITIAL.
    SELECT DISTINCT var_element  FROM /psyng/sw_varel
    INTO CORRESPONDING FIELDS OF TABLE
    et_elements
    WHERE varel_vrsio IN it_vevrs.
  ENDIF.
*--Export called tcodes
  IF NOT if_called_tcodes IS INITIAL.
    SELECT * INTO TABLE et_called_tcodes FROM /psyng/sw_excdtx.
  ENDIF.
*--Export calling tcodes
  IF NOT if_calling_tcodes IS INITIAL.
    SELECT * INTO TABLE et_calling_tcodes FROM /psyng/sw_excltx.
  ENDIF.
*--Export configuration Set ID
  IF NOT if_setid IS INITIAL.
    SELECT setid varel_vrsio published description sodvrsio
    INTO CORRESPONDING FIELDS OF TABLE lt_swcfgset
    FROM /psyng/swcfgset.
    IF NOT lt_swcfgset[] IS INITIAL.
      SELECT * FROM /psyng/swcfgsys INTO TABLE lt_swcfgsys
      FOR ALL ENTRIES IN lt_swcfgset
      WHERE setid = lt_swcfgset-setid.
    ENDIF.
*---Process them
    LOOP AT lt_swcfgset.
      MOVE-CORRESPONDING lt_swcfgset TO ls_setid.
      LOOP AT lt_swcfgsys WHERE setid = lt_swcfgset-setid.
        CONCATENATE ls_setid-system   ',' lt_swcfgsys-sysid
        INTO ls_setid-system SEPARATED BY space.
      ENDLOOP.
      ls_setid-system = ls_setid-system+2.
      APPEND ls_setid TO et_setid.
      CLEAR ls_setid.
    ENDLOOP.
  ENDIF.
*--Export Application Areas
  IF NOT if_busarea IS INITIAL.
    SELECT * INTO TABLE et_busarea FROM /psyng/busarea.
    SORT et_busarea BY busarea.
  ENDIF.
*--Export Risk Scenario
  IF NOT if_risk IS INITIAL.
    SELECT * INTO TABLE et_risk FROM /psyng/sw_risk.
    SORT et_risk BY risk.
  ENDIF.
*--Export Mitigating Controls Header
  IF NOT if_mchdr IS INITIAL.
    SELECT * INTO TABLE et_mchdr FROM /psyng/mchdr.
    SORT et_mchdr BY contid.
  ENDIF.
*--Export Process Areas
  IF NOT if_subarea IS INITIAL.
    SELECT * INTO TABLE et_subarea FROM /psyng/bus_proce.
    SORT et_subarea BY subarea.
  ENDIF.
*--Export System Types
  IF NOT if_sys_type IS INITIAL.
    SELECT * INTO TABLE et_sys_type FROM /psyng/sw_systyp.
    SORT et_sys_type BY sys_type.
  ENDIF.
*--Export System Category
  IF NOT if_sys_cat IS INITIAL.
    SELECT * INTO TABLE et_sys_cat FROM /psyng/sw_syscat.
    SORT et_sys_cat BY sys_category.
  ENDIF.

ENDFUNCTION.
