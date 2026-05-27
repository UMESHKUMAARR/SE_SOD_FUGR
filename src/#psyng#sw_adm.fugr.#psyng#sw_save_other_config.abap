FUNCTION /psyng/sw_save_other_config.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IF_DELETE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_TEST) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_BUSAREA) TYPE  FLAG OPTIONAL
*"     VALUE(IF_SUBAREA) TYPE  FLAG OPTIONAL
*"     VALUE(IF_RISK) TYPE  FLAG OPTIONAL
*"     VALUE(IF_SYS_TYPE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_SYS_CAT) TYPE  FLAG OPTIONAL
*"  TABLES
*"      IT_BUSAREA STRUCTURE  /PSYNG/BUSAREA OPTIONAL
*"      IT_SUBAREA STRUCTURE  /PSYNG/BUS_PROCE OPTIONAL
*"      IT_RISK STRUCTURE  /PSYNG/SW_RISK OPTIONAL
*"      IT_SYS_TYPE STRUCTURE  /PSYNG/SW_SYSTYP OPTIONAL
*"      IT_SYS_CAT STRUCTURE  /PSYNG/SW_SYSCAT OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_SAVE_OTHER_CONFIG'.
*  S_RFC AUTHORITY CHECK
* BOC BNAYAK CVA scan fix DT:05-05-2026
*  AUTHORITY-CHECK OBJECT 'S_RFC'
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
* EOC BNAYAK CVA scan fix DT:05-05-2026
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  RANGES: lr_busarea  FOR /psyng/busarea-busarea,
          lr_subarea  FOR /psyng/bus_proce-subarea,
          lr_risk     FOR /psyng/sw_risk-risk,
          lr_sys_type FOR /psyng/sw_systyp-sys_type,
          lr_sys_cat  FOR /psyng/sw_syscat-sys_category.
  DATA: lt_busarea        TYPE TABLE OF /psyng/busarea,
        ls_busarea        TYPE /psyng/busarea,
        lt_subarea        TYPE TABLE OF /psyng/bus_proce,
        ls_subarea        TYPE /psyng/bus_proce,
        lt_risk           TYPE TABLE OF /psyng/sw_risk,
        ls_risk           TYPE /psyng/sw_risk,
        lt_sys_type       TYPE TABLE OF /psyng/sw_systyp,
        ls_sys_type       TYPE /psyng/sw_systyp,
        lt_sys_cat        TYPE TABLE OF /psyng/sw_syscat,
        ls_sys_cat        TYPE /psyng/sw_syscat,
        l_message_v1      TYPE symsgv,
        l_message_v2      TYPE symsgv.

*--Delete the existing configuration
  IF if_delete EQ 'X'.
    IF NOT if_busarea IS INITIAL.
*--Get existing application areas
      SELECT *
        FROM /psyng/busarea
        INTO TABLE lt_busarea.
      IF if_test IS INITIAL.
*--Delete all application areas
        DELETE FROM /psyng/busarea WHERE busarea IN lr_busarea.
      ENDIF.
      IF sy-dbcnt GT 0
      OR if_test  EQ 'X'.
        MOVE 'Application Area deleted successfully'(s59)
        TO et_return-message.
        LOOP AT lt_busarea INTO ls_busarea.
          CLEAR: l_message_v1, l_message_v2.
          l_message_v1 = ls_busarea-busarea.
          l_message_v2 = ls_busarea-text.
          PERFORM fill_log
           TABLES et_return
            USING 'S' et_return-message
                  text-o23 l_message_v1 text-o28 l_message_v2.
        ENDLOOP.
      ENDIF.
    ENDIF.
    IF NOT if_subarea IS INITIAL.
*--Get existing process areas
      SELECT *
        FROM /psyng/bus_proce
        INTO TABLE lt_subarea.
      IF if_test IS INITIAL.
*--Delete all process areas
        DELETE FROM /psyng/bus_proce WHERE subarea IN lr_subarea.
      ENDIF.
      IF sy-dbcnt GT 0
      OR if_test  EQ 'X'.
        MOVE 'Process Area deleted successfully'(s60)
        TO et_return-message.
        LOOP AT lt_subarea INTO ls_subarea.
          CLEAR: l_message_v1, l_message_v2.
          l_message_v1 = ls_subarea-subarea.
          l_message_v2 = ls_subarea-text.
          PERFORM fill_log
           TABLES et_return
            USING 'S' et_return-message
                  text-o24 l_message_v1 text-o28 l_message_v2.
        ENDLOOP.
      ENDIF.
    ENDIF.
    IF NOT if_risk IS INITIAL.
*--Get existing risk scenarios
      SELECT *
        FROM /psyng/sw_risk
        INTO TABLE lt_risk.
      IF if_test IS INITIAL.
*--Delete all risk scenarios
        DELETE FROM /psyng/sw_risk WHERE risk IN lr_risk.
      ENDIF.
      IF sy-dbcnt GT 0
      OR if_test  EQ 'X'.
        MOVE 'Risk Scenario deleted successfully'(s61)
        TO et_return-message.
        LOOP AT lt_risk INTO ls_risk.
          CLEAR: l_message_v1, l_message_v2.
          l_message_v1 = ls_risk-risk.
          l_message_v2 = ls_risk-text.
          PERFORM fill_log
           TABLES et_return
            USING 'S' et_return-message
                  text-o25 l_message_v1 text-o28 l_message_v2.
        ENDLOOP.
      ENDIF.
    ENDIF.
    IF NOT if_sys_type IS INITIAL.
*--Get existing system types
      SELECT *
        FROM /psyng/sw_systyp
        INTO TABLE lt_sys_type.
      IF if_test IS INITIAL.
*--Delete all system types
        DELETE FROM /psyng/sw_systyp WHERE sys_type IN lr_sys_type.
      ENDIF.
      IF sy-dbcnt GT 0
      OR if_test  EQ 'X'.
        MOVE 'System Type deleted successfully'(s68)
        TO et_return-message.
        LOOP AT lt_sys_type INTO ls_sys_type.
          CLEAR: l_message_v1, l_message_v2.
          l_message_v1 = ls_sys_type-sys_type.
          l_message_v2 = ls_sys_type-sys_description.
          PERFORM fill_log
           TABLES et_return
            USING 'S' et_return-message
                  text-o26 l_message_v1 text-o28 l_message_v2.
        ENDLOOP.
      ENDIF.
    ENDIF.
    IF NOT if_sys_cat IS INITIAL.
*--Get existing system categories
      SELECT *
        FROM /psyng/sw_syscat
        INTO TABLE lt_sys_cat.
      IF if_test IS INITIAL.
*--Delete all system types
        DELETE FROM /psyng/sw_syscat WHERE sys_category IN lr_sys_cat.
      ENDIF.
      IF sy-dbcnt GT 0
      OR if_test  EQ 'X'.
        MOVE 'System Category deleted successfully'(s69)
        TO et_return-message.
        LOOP AT lt_sys_cat INTO ls_sys_cat.
          CLEAR: l_message_v1, l_message_v2.
          l_message_v1 = ls_sys_cat-sys_category.
          l_message_v2 = ls_sys_cat-cat_description.
          PERFORM fill_log
           TABLES et_return
            USING 'S' et_return-message
                  text-o27 l_message_v1 text-o28 l_message_v2.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.

  IF NOT it_busarea[] IS INITIAL.
    IF if_test IS INITIAL.
      MODIFY /psyng/busarea FROM TABLE it_busarea.
    ENDIF.
    IF sy-dbcnt GT 0
    OR if_test EQ 'X'.
      IF if_delete EQ 'X'.
        MOVE 'Application Area added successfully'(s62)
        TO et_return-message.
      ELSE.
        MOVE 'Application Area modified successfully'(s63)
        TO et_return-message.
      ENDIF.
      LOOP AT it_busarea.
        CLEAR: l_message_v1, l_message_v2.
        l_message_v1 = it_busarea-busarea.
        l_message_v2 = it_busarea-text.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o23 l_message_v1 text-o28 l_message_v2.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT it_subarea[] IS INITIAL.
    IF if_test IS INITIAL.
      MODIFY /psyng/bus_proce FROM TABLE it_subarea.
    ENDIF.
    IF sy-dbcnt GT 0
    OR if_test EQ 'X'.
      IF if_delete EQ 'X'.
        MOVE 'Process Area added successfully'(s64)
        TO et_return-message.
      ELSE.
        MOVE 'Process Area modified successfully'(s65)
        TO et_return-message.
      ENDIF.
      LOOP AT it_subarea.
        CLEAR: l_message_v1, l_message_v2.
        l_message_v1 = it_subarea-subarea.
        l_message_v2 = it_subarea-text.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o24 l_message_v1 text-o28 l_message_v2.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT it_risk[] IS INITIAL.
    IF if_test IS INITIAL.
      MODIFY /psyng/sw_risk FROM TABLE it_risk.
    ENDIF.
    IF sy-dbcnt GT 0
    OR if_test EQ 'X'.
      IF if_delete EQ 'X'.
        MOVE 'Risk Scenario added successfully'(s66)
        TO et_return-message.
      ELSE.
        MOVE 'Risk Scenario modified successfully'(s67)
        TO et_return-message.
      ENDIF.
      LOOP AT it_risk.
        CLEAR: l_message_v1, l_message_v2.
        l_message_v1 = it_risk-risk.
        l_message_v2 = it_risk-text.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o25 l_message_v1 text-o28 l_message_v2.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT it_sys_type[] IS INITIAL.
    IF if_test IS INITIAL.
      MODIFY /psyng/sw_systyp FROM TABLE it_sys_type.
    ENDIF.
    IF sy-dbcnt GT 0
    OR if_test EQ 'X'.
      IF if_delete EQ 'X'.
        MOVE 'System Type added successfully'(s70)
        TO et_return-message.
      ELSE.
        MOVE 'System Type modified successfully'(s71)
        TO et_return-message.
      ENDIF.
      LOOP AT it_sys_type.
        CLEAR: l_message_v1, l_message_v2.
        l_message_v1 = it_sys_type-sys_type.
        l_message_v2 = it_sys_type-sys_description.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o26 l_message_v1 text-o28 l_message_v2.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT it_sys_cat[] IS INITIAL.
    IF if_test IS INITIAL.
      MODIFY /psyng/sw_syscat FROM TABLE it_sys_cat.
    ENDIF.
    IF sy-dbcnt GT 0
    OR if_test EQ 'X'.
      IF if_delete EQ 'X'.
        MOVE 'System Category added successfully'(s72)
        TO et_return-message.
      ELSE.
        MOVE 'System Category modified successfully'(s73)
        TO et_return-message.
      ENDIF.
      LOOP AT it_sys_cat.
        CLEAR: l_message_v1, l_message_v2.
        l_message_v1 = it_sys_cat-sys_category.
        l_message_v2 = it_sys_cat-cat_description.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o27 l_message_v1 text-o28 l_message_v2.
      ENDLOOP.
    ENDIF.
  ENDIF.

ENDFUNCTION.
