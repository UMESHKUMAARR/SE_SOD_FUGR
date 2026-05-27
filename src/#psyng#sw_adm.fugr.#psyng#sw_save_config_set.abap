FUNCTION /psyng/sw_save_config_set.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(IF_DELETE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_TEST) TYPE  FLAG DEFAULT 'X'
*"  TABLES
*"      IT_VAREL STRUCTURE  /PSYNG/SWCFGVE OPTIONAL
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"      IT_ORG STRUCTURE  /PSYNG/SWCFGOE OPTIONAL
*"      IT_ELEMENTS STRUCTURE  /PSYNG/SWCFSEL OPTIONAL
*"      IT_CONFIG_HEADER STRUCTURE  /PSYNG/SWCFGSET OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_SAVE_CONFIG_SET'.
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

  DATA: l_message_v1     TYPE symsgv,
        l_message_v2     TYPE symsgv,
        lf_sys_no_exist  TYPE flag,
        lt_varel         TYPE TABLE OF /psyng/swcfgve,
        lt_systems       TYPE TABLE OF /psyng/swcfgsys,
        lt_org           TYPE TABLE OF /psyng/swcfgoe,
        lt_elements      TYPE TABLE OF /psyng/swcfsel,
        lt_sw_rfcdes     TYPE TABLE OF /psyng/sw_rfcdes.

  SORT it_config_header BY setid.
  SORT it_systems       BY setid sysid.
  SORT it_org           BY setid abb varbl sysid value.
  SORT it_varel         BY setid var_element sysid value.
  SORT it_elements      BY setid type varbl.

*-- Get RFC systems defined in local system
  SELECT * FROM /psyng/sw_rfcdes "#EC CI_NOWHERE
    INTO TABLE lt_sw_rfcdes.
*--Check authorization for all configuration set IDs
  LOOP AT it_config_header.
    AUTHORITY-CHECK OBJECT   'Y&SW_CFGST'
             ID 'ACTVT'      FIELD '02'
             ID 'Y&SW_SETID' FIELD it_config_header-setid.
    IF sy-subrc <> 0.
      MESSAGE s108 WITH text-e21 INTO et_return-message.
      l_message_v1 = it_config_header-setid.
      PERFORM fill_log
       TABLES et_return
        USING 'E' et_return-message
              text-o10 l_message_v1 '' ''.
      DELETE it_config_header WHERE setid = it_config_header-setid.
      DELETE it_varel         WHERE setid = it_config_header-setid.
      DELETE it_systems       WHERE setid = it_config_header-setid.
      DELETE it_org           WHERE setid = it_config_header-setid.
      DELETE it_elements      WHERE setid = it_config_header-setid.
    ENDIF.
  ENDLOOP.

  LOOP AT it_config_header.
    REFRESH: lt_varel, lt_systems, lt_org, lt_elements.
    CLEAR lf_sys_no_exist.
    LOOP AT it_varel WHERE setid = it_config_header-setid.
      APPEND it_varel TO lt_varel.
    ENDLOOP.
    LOOP AT it_systems WHERE setid = it_config_header-setid.
*--Check if configuration set system is one of the RFC's defined
      READ TABLE lt_sw_rfcdes
      TRANSPORTING NO FIELDS
        WITH KEY systid = it_systems-sysid.
      IF sy-subrc NE 0.
        MOVE
     'System do not exist in RFC Destinations'(e24)
        TO et_return-message.
        l_message_v1 = it_config_header-setid.
        l_message_v2 = it_systems-sysid.
        PERFORM fill_log
         TABLES et_return
          USING 'E' et_return-message
                text-o10 l_message_v1 text-o12 l_message_v2.
        DELETE it_config_header WHERE setid = it_config_header-setid.
        DELETE it_varel         WHERE setid = it_config_header-setid.
        DELETE it_systems       WHERE setid = it_config_header-setid.
        DELETE it_org           WHERE setid = it_config_header-setid.
        DELETE it_elements      WHERE setid = it_config_header-setid.
        lf_sys_no_exist = 'X'.
        EXIT.
      ENDIF.
      APPEND it_systems TO lt_systems.
    ENDLOOP.

    IF lf_sys_no_exist EQ 'X'.
      CONTINUE.
    ENDIF.

    LOOP AT it_org WHERE setid = it_config_header-setid.
      APPEND it_org TO lt_org.
    ENDLOOP.
    LOOP AT it_elements WHERE setid = it_config_header-setid.
      APPEND it_elements TO lt_elements.
    ENDLOOP.
    PERFORM db_changes_config_set
     TABLES lt_varel
            lt_systems
            lt_org
            lt_elements
            et_return
      USING it_config_header
            if_delete
            if_test.
  ENDLOOP.

ENDFUNCTION.
