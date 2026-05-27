FUNCTION /psyng/sw_cgf_set_default.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  FLAG OPTIONAL
*"     VALUE(I_CFGVRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(IF_LOCAL_SYSTEM) TYPE  FLAG DEFAULT 'X'
*"  EXPORTING
*"     VALUE(EF_SUCCESS) TYPE  FLAG
*"     VALUE(E_CONFIG_SET) TYPE  /PSYNG/SECONFID
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      IT_RFCDEST STRUCTURE  /PSYNG/SW_SEL_OPTS_RFCDEST OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CGF_SET_DEFAULT'.
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

  DATA : l_cnt         TYPE i,
         l_exact_match TYPE /psyng/param_value,
         l_local_sys   TYPE rfcdest,
         lt_setsys     TYPE TABLE OF /psyng/swcfgsys WITH HEADER LINE,
         lt_set        TYPE TABLE OF /psyng/swcfgsys WITH HEADER LINE,
         lt_systems    type table of /PSYNG/SWCFGSYS with header line,
         lf_missing_sys type flag.

  RANGES:
         r_vrsio       FOR i_cfgvrsio,
         r_sys         FOR l_local_sys,
         r_sys_set     FOR l_local_sys.
*--Determine if an exact match on systems should be considered
  se_config_param  'CFG_SET_EXACT_MATCH' l_exact_match.

  CLEAR ef_success.
*--Found the highest published configuration set
  r_vrsio-sign   = 'I'.
  r_vrsio-option = 'EQ'.
  r_sys-sign     = 'I'.
  r_sys-option   = 'EQ'.

*--fill systems table
  perform load_analyzed_systems
   tables lt_systems
           it_rfcdest
    using if_local_system.
  loop at lt_systems.
    r_sys-low =  lt_systems-sysid.
    APPEND r_sys.
  endloop.
  if not r_sys[] is initial.
    IF i_vrsio IS NOT INITIAL.
      r_vrsio-low = i_cfgvrsio.
      APPEND r_vrsio.
    ENDIF.
*  --Find latest published set containing any of the analyzed systems
    SELECT  sys~setid sys~sysid INTO CORRESPONDING FIELDS OF TABLE lt_setsys
    FROM /psyng/swcfgset AS set
      INNER JOIN /psyng/swcfgsys AS sys ON
        set~setid = sys~setid

      WHERE sys~sysid      IN r_sys      AND
            set~published  = 'X'         AND
            set~sodvrsio   IN r_vrsio.

    SORT lt_setsys BY setid sysid .
    lt_set[] = lt_setsys[].
    DELETE ADJACENT DUPLICATES FROM lt_set COMPARING setid.
*  --now for these sets, get all systems
    if not lt_set[] is initial.
      SELECT  sys~setid sys~sysid INTO CORRESPONDING FIELDS OF TABLE lt_setsys
        from /psyng/swcfgsys AS sys for all entries in lt_set where
          sys~setid = lt_set-setid.
    endif.

    SORT lt_set BY setid DESCENDING."latest set has priority
    LOOP AT lt_set.
      IF ef_success = 'X'.
        EXIT.
      ENDIF.
      REFRESH : r_sys_set.
      r_sys_set-sign     = 'I'.
      r_sys_set-option   = 'EQ'.
      READ TABLE lt_setsys WITH KEY setid = lt_set-setid.
      LOOP AT lt_setsys FROM sy-tabix.
        IF lt_setsys-setid <> lt_set-setid.
          EXIT.
        ENDIF.
        r_sys_set-low = lt_setsys-sysid.
        APPEND r_sys_set.
      ENDLOOP.
      SORT r_sys_set.
      IF r_sys[] = r_sys_set[].
        e_config_set = lt_set-setid.
        ef_success =  'X'.
        EXIT.
      ELSE.
        IF l_exact_match <> 'Y'.
*  --If there isn't an exact match, that may also be fine if all analyzed systems are in the set
*  if there are more, that's also okj
          clear lf_missing_sys.
          LOOP AT r_sys.
            IF r_sys-low NOT IN r_sys_set[].
              lf_missing_sys = 'X'.
              exit."this is not the correct set, go to the next one
            ENDIF.
          ENDLOOP.
          if lf_missing_sys is initial.
*    --       if we get here, that means all systems were found
            e_config_set = lt_set-setid.
            ef_success =  'X'.
            EXIT.
          endif.
        ENDIF.
      ENDIF.
    ENDLOOP.
  endif.
  IF ef_success IS INITIAL.
    log et_return 'E' 'NOGLOBALCONFSET'
      'No latest published Configuration Set available' '' '' ''.
    CLEAR ef_success.
  ENDIF.
ENDFUNCTION.
