FUNCTION /psyng/sw_save_dyncfg.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(IF_DELETE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_TEST) TYPE  FLAG DEFAULT 'X'
*"  TABLES
*"      IT_CALLING_TCODES STRUCTURE  /PSYNG/SW_EXCLTX OPTIONAL
*"      IT_CALLED_TCODES STRUCTURE  /PSYNG/SW_EXCDTX OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_SAVE_DYNCFG'.
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
  RANGES: lr_tcodes FOR /psyng/sw_excltx-low.
  DATA: lt_calling_tcodes TYPE TABLE OF /psyng/sw_excltx,
        ls_calling_tcodes TYPE /psyng/sw_excltx,
        lt_called_tcodes  TYPE TABLE OF /psyng/sw_excdtx,
        ls_called_tcodes  TYPE /psyng/sw_excdtx,
        l_message_v1      TYPE symsgv.

*--Delete the existing dynamic configuration
  IF if_delete EQ 'X'.
*--Get existing calling tcodes
    SELECT * "#EC CI_NOWHERE
      FROM /psyng/sw_excltx
      INTO TABLE lt_calling_tcodes.
*--Get existing called tcodes
    SELECT * "#EC CI_NOWHERE
      FROM /psyng/sw_excdtx
      INTO TABLE lt_called_tcodes.
    IF if_test IS INITIAL.
*--Delete all calling transaction configuration
      DELETE FROM /psyng/sw_excltx WHERE low IN lr_tcodes.
    ENDIF.
    IF sy-dbcnt GT 0
    OR if_test  EQ 'X'.
      MOVE 'Calling Tcodes deleted successfully'(s23)
      TO et_return-message.
      LOOP AT lt_calling_tcodes INTO ls_calling_tcodes.
        CLEAR l_message_v1.
        CONCATENATE ls_calling_tcodes-sign
                    ls_calling_tcodes-type
                    ls_calling_tcodes-low INTO l_message_v1
                    SEPARATED BY ' / '.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o08 l_message_v1 '' ''.
      ENDLOOP.
    ENDIF.
    IF if_test IS INITIAL.
*--Delete all called transaction configuration
      DELETE FROM /psyng/sw_excdtx WHERE called_tcode IN lr_tcodes.
    ENDIF.
    IF sy-dbcnt GT 0
    OR if_test  EQ 'X'.
      MOVE 'Called Tcodes deleted successfully'(s24)
      TO et_return-message.
      LOOP AT lt_called_tcodes INTO ls_called_tcodes.
        l_message_v1 = ls_called_tcodes-called_tcode.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o09 l_message_v1 '' ''.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT it_calling_tcodes[] IS INITIAL.
    IF if_test IS INITIAL.
      MODIFY /psyng/sw_excltx FROM TABLE it_calling_tcodes.
    ENDIF.
    IF sy-dbcnt GT 0
    OR if_test EQ 'X'.
      IF if_delete EQ 'X'.
        MOVE 'Calling Tcodes added successfully'(s25)
        TO et_return-message.
      ELSE.
        MOVE 'Calling Tcodes modified successfully'(s26)
        TO et_return-message.
      ENDIF.
      LOOP AT it_calling_tcodes.
        CLEAR l_message_v1.
        CONCATENATE it_calling_tcodes-sign
                    it_calling_tcodes-type
                    it_calling_tcodes-low INTO l_message_v1
                    SEPARATED BY ' / '.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o08 l_message_v1 '' ''.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT it_called_tcodes[] IS INITIAL.
    IF if_test IS INITIAL.
      MODIFY /psyng/sw_excdtx FROM TABLE it_called_tcodes.
    ENDIF.
    IF sy-dbcnt GT 0
    OR if_test EQ 'X'.
      IF if_delete EQ 'X'.
        MOVE 'Called Tcodes added successfully'(s27)
        TO et_return-message.
      ELSE.
        MOVE 'Called Tcodes modified successfully'(s28)
        TO et_return-message.
      ENDIF.
      LOOP AT it_called_tcodes.
        l_message_v1 = it_called_tcodes-called_tcode.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o09 l_message_v1 '' ''.
      ENDLOOP.
    ENDIF.
  ENDIF.

ENDFUNCTION.
