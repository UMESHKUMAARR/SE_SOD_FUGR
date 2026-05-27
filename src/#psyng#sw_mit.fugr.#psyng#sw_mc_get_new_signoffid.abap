FUNCTION /PSYNG/SW_MC_GET_NEW_SIGNOFFID .
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_NR_KEYS) TYPE  I DEFAULT 1
*"  EXPORTING
*"     REFERENCE(E_FIRST_ID) TYPE  /PSYNG/SE_MC_SIGNOFFID
*"     REFERENCE(E_LAST_ID) TYPE  /PSYNG/SE_MC_SIGNOFFID
*"----------------------------------------------------------------------
  DATA: wa_icc TYPE /psyng/sw_sgnid.
  DATA : lf_table_locked TYPE flag,
         l_enq_start TYPE /psyng/se16n_id,
         l_enq_current TYPE /psyng/se16n_id,
         l_enq_duration TYPE i.

*Wait for table to become unlocked
  lf_table_locked = 'X'.
  GET TIME STAMP FIELD l_enq_start.
  WHILE lf_table_locked = 'X'.
    CALL FUNCTION 'ENQUEUE_/PSYNG/SE_SIGNOF'
         EXPORTING
     mode_/psyng/sw_sgnid = 'E'
     mandt                = sy-mandt "#EC SAST_CI_GEN_CHECK (HBHALLA)
     _scope               = '2'
     _wait                = 'X'
     _collect             = ' '
         EXCEPTIONS
              foreign_lock         = 1
              system_failure       = 2
              OTHERS               = 3.
    IF sy-subrc = 0.
      CLEAR lf_table_locked.
    ELSE.
      GET TIME STAMP FIELD l_enq_current.
      l_enq_duration = l_enq_current - l_enq_start.
      IF l_enq_duration > 30.
*      Lock can not be released.
*      Create new SIGNOFFID without using sap lock object
        PERFORM new_transid_ignore_lock using i_nr_keys
                                        CHANGING e_first_id e_last_id
                                        .
        EXIT.
      ENDIF.
    ENDIF.
  ENDWHILE.
  CHECK lf_table_locked IS INITIAL.
  SELECT SINGLE * FROM /psyng/sw_sgnid INTO wa_icc.

  IF sy-subrc <> 0.
    wa_icc-signoffid = 1.
    e_first_id = wa_icc-signoffid.
    wa_icc-signoffid = wa_icc-signoffid + i_nr_keys - 1.
    e_last_id = wa_icc-signoffid.
    INSERT INTO /psyng/sw_sgnid VALUES wa_icc.
  ELSE.
    add 1 to wa_icc-signoffid.
    e_first_id = wa_icc-signoffid.
    wa_icc-signoffid = wa_icc-signoffid + i_nr_keys - 1.
    e_last_id = wa_icc-signoffid.
    UPDATE /psyng/sw_sgnid SET signoffid = wa_icc-signoffid.
  ENDIF.
  COMMIT WORK.
*unlock table
  CALL FUNCTION 'DEQUEUE_/PSYNG/SE_SIGNOF'
       EXPORTING
   mode_/psyng/sw_sgnid = 'E'
   mandt                = sy-mandt "#EC SAST_CI_GEN_CHECK (HBHALLA)
   _scope               = '3'
   _synchron            = ' '
   _collect             = ' '.


ENDFUNCTION.
