FUNCTION /psyng/sw_transport_check.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_REQUEST) TYPE  TRKORR
*"     REFERENCE(I_OWNER) TYPE  TR_AS4USER
*"     REFERENCE(I_TYPE) TYPE  TRFUNCTION
*"  TABLES
*"      IT_ATTRIBUTES TYPE  TRATTRIBUTES
*"      IT_OBJECTS TYPE  TR_OBJECTS
*"  CHANGING
*"     REFERENCE(TEXT) TYPE  AS4TEXT
*"  EXCEPTIONS
*"      CANCEL
*"----------------------------------------------------------------------
  STATICS : lf_config_checked TYPE flag,
            lf_check_active   TYPE flag,
            l_sod_version     TYPE /psyng/sodvrsio VALUE '000',
            lf_allow_conflicts TYPE flag.
  DATA: ls_swconfig  TYPE /psyng/swconfig,
        lt_roles     TYPE TABLE OF /psyng/sw_sel_opts_agr_name
                     WITH HEADER LINE,
       lt_agrs type table of agr_define with header line,
       lf_stop type flag.
  IF lf_config_checked IS INITIAL.
    lf_allow_conflicts = 'X'.
    se_config_param 'SW_TRP_REL_CHECK' ls_swconfig-value.

    lf_config_checked = 'X'.
    IF ls_swconfig-value = 'Y' OR ls_swconfig-value = 'X'.
      lf_check_active = 'X'.
      SELECT SINGLE * FROM /psyng/swconfig
             INTO ls_swconfig
             WHERE param = 'SW_INTEGRATION_VRSIO'.
      IF sy-subrc = 0.
        l_sod_version = ls_swconfig-value.
      ENDIF.
     se_config_param 'SW_TRP_REL_ENFORCE' ls_swconfig-value.

      IF ( ls_swconfig-value = 'Y' OR ls_swconfig-value = 'X').
        clear lf_allow_conflicts.
      ENDIF.

    ENDIF.
  ENDIF.
  CHECK lf_check_active = 'X'.
*--Check if the transport contains roles
  READ TABLE it_objects WITH KEY pgmid  = 'R3TR'
                              object    = 'ACGR'
                              TRANSPORTING NO FIELDS.
  CHECK sy-subrc = 0.
*--Transport contains a role
  lt_roles-sign   = 'I'.
  lt_roles-option = 'EQ'.
  LOOP AT it_objects WHERE pgmid  = 'R3TR' AND object    = 'ACGR'.
    lt_agrs-agr_name = it_objects-obj_name.
    COLLECT lt_agrs.
  ENDLOOP.

  perform analyze_role in program /PSYNG/SAPLSW_PRGN
          tables lt_agrs
          using '' 'SE10' l_sod_version lf_allow_conflicts
          changing lf_stop
          .
  if lf_stop = 'X'.
  MESSAGE i002(/psyng/sw) WITH
  'Security Weaver Separations Enforcer'(001)
  'Doesn''t allow releasing roles that'(002)
  ' contain conflicts'(003).
*   & & & &

   RAISE cancel.
  endif.



ENDFUNCTION.
