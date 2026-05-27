FUNCTION /psyng/sw_cfg_get_new_setid.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  EXPORTING
*"     REFERENCE(SETID) TYPE  /PSYNG/SECONFID
*"----------------------------------------------------------------------
  DATA: wa_icc           TYPE /psyng/swcfgid.
  DATA : lf_table_locked TYPE flag,
         l_enq_start     TYPE /psyng/se16n_id,
         l_enq_current   TYPE /psyng/se16n_id,
         l_enq_duration  TYPE i.

*Wait for table to become unlocked
  lf_table_locked = 'X'.
  GET TIME STAMP FIELD l_enq_start.
  WHILE lf_table_locked = 'X'.
    CALL FUNCTION 'ENQUEUE_/PSYNG/SWCFGID'
         EXPORTING
     mode_/psyng/swcfgid = 'E'
     mandt               = sy-mandt "#EC SAST_CI_GEN_CHECK (HBHALLA)
     _scope              = '2'
     _wait               = 'X'
     _collect            = ' '
         EXCEPTIONS
              foreign_lock        = 1
              system_failure      = 2
              OTHERS              = 3.
    IF sy-subrc = 0.
      CLEAR lf_table_locked.
    ELSE.
      GET TIME STAMP FIELD l_enq_current.
      l_enq_duration = l_enq_current - l_enq_start.
      IF l_enq_duration > 30.
*      Lock can not be released.
*      Create new transid without using sap lock object
        PERFORM new_transid_ignore_lock CHANGING setid.
        EXIT.
      ENDIF.
    ENDIF.
  ENDWHILE.
  CHECK lf_table_locked IS INITIAL.
  SELECT SINGLE * FROM /psyng/swcfgid INTO wa_icc.

  IF wa_icc-setid IS INITIAL.
    wa_icc-setid = 1.
    INSERT INTO /psyng/swcfgid VALUES wa_icc.
  ELSE.
    ADD 1 TO wa_icc-setid.
    UPDATE /psyng/swcfgid SET setid = wa_icc-setid.
  ENDIF.

  setid = wa_icc-setid.
  COMMIT WORK.
*unlock table
  CALL FUNCTION 'DEQUEUE_/PSYNG/SWCFGID'
       EXPORTING
    mode_/psyng/swcfgid = 'E'
    mandt               = sy-mandt "#EC SAST_CI_GEN_CHECK (HBHALLA)
    _scope              = '3'
    _synchron           = ' '
    _collect            = ' '.


ENDFUNCTION.

*---------------------------------------------------------------------*
*       FORM new_transid_ignore_lock                                  *
*---------------------------------------------------------------------*
*       If the lock can't be achieved, get a new ID safely            *
*---------------------------------------------------------------------*
*  -->  SETID                                                         *
*---------------------------------------------------------------------*
FORM new_transid_ignore_lock CHANGING setid TYPE /psyng/seconfid.
  DATA: wa_icc       TYPE /psyng/swcfgid,
        wa_icc_check TYPE /psyng/swcfgid.

  SELECT SINGLE * FROM /psyng/swcfgid INTO wa_icc.
  IF wa_icc-setid IS INITIAL.
    wa_icc-setid = 1.
    INSERT INTO /psyng/swcfgid VALUES wa_icc.
  ELSE.
    ADD 1 TO wa_icc-setid.
    UPDATE /psyng/swcfgid SET setid = wa_icc-setid.
    COMMIT WORK.
  ENDIF.
*   try until transid in db is the one we have as output
  WHILE wa_icc-setid <> wa_icc_check-setid.
    SELECT SINGLE * FROM /psyng/swcfgid INTO wa_icc_check.
    IF wa_icc-setid <> wa_icc_check-setid.
      ADD 1 TO wa_icc-setid.
      UPDATE /psyng/swcfgid SET setid = wa_icc-setid.
      COMMIT WORK.
    ENDIF.
  ENDWHILE.
  setid = wa_icc-setid.
ENDFORM.                    " new_transid_ignore_lock
