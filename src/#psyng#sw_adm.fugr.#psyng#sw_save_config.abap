FUNCTION /psyng/sw_save_config.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IF_DELETE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_TEST) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_CONFIG_SCREEN_CALL) TYPE  FLAG OPTIONAL
*"  TABLES
*"      IT_CONFIG STRUCTURE  /PSYNG/SE_CONFIG_PARAM OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_SAVE_CONFIG'.
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

  TABLES: /psyng/swconfig.
  DATA: ls_config    TYPE /psyng/swconfig,
        l_message_v1 TYPE symsgv,
        l_message_v2 TYPE symsgv,
        lt_delete    type table of /psyng/swconfig with header line,
        l_objid      type cdhdr-objectid,
        lt_ICDTXT_SECONFIG type table of CDTXT,
        lf_change    type flag,
        ls_SWINVISBL TYPE /PSYNG/SWINVISBL,
        ls_config_orig TYPE /psyng/swconfig,
        ls_config_dum  TYPE /psyng/swconfig,
        lf_delete_ok   type flag,
        lf_change_ok   type flag.

  RANGES: lr_config  FOR /psyng/swconfig-param.
* BOC by RGUPTA on 07.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700
  AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
           ID 'DICBERCLS' FIELD 'Y&S2'
           ID 'ACTVT' FIELD '02'.
  IF sy-subrc <> 0.
    MESSAGE s108 WITH text-e19 INTO et_return-message.
    PERFORM fill_log
     TABLES et_return
      USING 'E' et_return-message
            '' '' '' ''.
*    IF if_test IS INITIAL.
      EXIT.
*    ENDIF.
  ENDIF.

*--delete custom parameters
if IF_CONFIG_SCREEN_CALL = 'X'.
  lr_config-sign = 'I'. lr_config-option = 'EQ'.
  loop at it_config where maintained <> 'X'.
    lr_config-low = it_config-param.
    append lr_config.
    endloop.
    refresh it_config.
  endif.

*--Delete all configuration parameters
  IF if_delete EQ 'X'.
    IF if_test IS INITIAL.
      select * from /psyng/swconfig into table lt_delete where param in lr_config.
      if not lt_delete[] is initial.
        lf_delete_ok = 'X'.
        loop at lt_delete.
            DELETE FROM /psyng/swconfig WHERE param = lt_delete-param.
            if sy-subrc <> 0.
              clear lf_delete_ok.
            else.
              l_objid = lt_delete-param.
              CALL FUNCTION '/PSYNG/SECONFIG_WRITE_DOCUMENT'
                EXPORTING
                      objectid                      = l_objid
                      tcode                         = '/PSYNG/SW'
                      utime                         = sy-uzeit
                      udate                         = sy-datum
                      username                      = l_current_user "C0700
                      PLANNED_CHANGE_NUMBER         = ' '
                      OBJECT_CHANGE_INDICATOR       = 'D'
                      PLANNED_OR_REAL_CHANGES       = 'R'
                      NO_CHANGE_POINTERS            = ' '
                      O_PSYNG_SWCONFIG              = lt_delete
                      N_PSYNG_SWCONFIG              = ls_config_dum
                      UPD_PSYNG_SWCONFIG            = 'D'
                      UPD_PSYNG_SWINVISBL           = ''
                      N_PSYNG_SWINVISBL             = ls_SWINVISBL
                      O_PSYNG_SWINVISBL             = ls_SWINVISBL
                TABLES
                      ICDTXT_SECONFIG               = lt_ICDTXT_SECONFIG.
             endif.
        endloop.
      endif.
    ENDIF.
    IF lf_delete_ok = 'X'
    OR if_test  EQ 'X'.
      MOVE 'All Configuration parameters deleted successfully'(s16)
      TO et_return-message.
      PERFORM fill_log
       TABLES et_return
        USING 'S' et_return-message
              '' '' '' ''.
    ENDIF.
  ENDIF.

*-- Modify configuration paramaters
  IF it_config[] IS INITIAL.
    MOVE 'No configuration parameter selected'(w01)
    TO et_return-message.
    PERFORM fill_log
     TABLES et_return
      USING 'W' et_return-message
            '' '' '' ''.
  ELSE.
    lf_change_ok = 'X'.
    LOOP AT it_config.

      MOVE-CORRESPONDING it_config TO ls_config.
      IF if_test IS INITIAL.
        clear ls_config_orig.
        select single * from /psyng/swconfig into ls_config_orig where param = ls_config-param.
        l_objid = ls_config-param.
        MODIFY /psyng/swconfig FROM ls_config.
        if sy-subrc <> 0.
          clear lf_change_ok.
        else.
          CALL FUNCTION '/PSYNG/SECONFIG_WRITE_DOCUMENT'
              EXPORTING
                   objectid                      = l_objid
                   tcode                         = '/PSYNG/SW'
                   utime                         = sy-uzeit
                   udate                         = sy-datum
                   username                      = l_current_user "C0700
                   PLANNED_CHANGE_NUMBER         = ' '
                   OBJECT_CHANGE_INDICATOR       = 'U'
                   PLANNED_OR_REAL_CHANGES       = 'R'
                   NO_CHANGE_POINTERS            = ' '
                   O_PSYNG_SWCONFIG              = ls_config_orig
                   N_PSYNG_SWCONFIG              = ls_config
                   UPD_PSYNG_SWCONFIG            = 'U'
                   UPD_PSYNG_SWINVISBL           = ''
                   N_PSYNG_SWINVISBL             = ls_SWINVISBL
                   O_PSYNG_SWINVISBL             = ls_SWINVISBL
                TABLES
                      ICDTXT_SECONFIG            = lt_ICDTXT_SECONFIG.
        endif.
      ENDIF.
      IF lf_change_ok = 'X'
      OR if_test  EQ 'X'.
        IF if_delete IS INITIAL.
          MOVE 'Configuration parameter modified successfully'(s55)
          TO et_return-message.
        ELSE.
          MOVE 'Configuration parameter added successfully'(s15)
          TO et_return-message.
        ENDIF.
        l_message_v1 = ls_config-param.
        l_message_v2 = ls_config-value.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                l_message_v1 l_message_v2 '' ''.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFUNCTION.
