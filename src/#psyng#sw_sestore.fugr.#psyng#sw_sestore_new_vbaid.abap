FUNCTION /PSYNG/SW_SESTORE_NEW_VBAID.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  EXPORTING
*"     REFERENCE(RESID) TYPE  /PSYNG/SERES_VBAINDEX
*"----------------------------------------------------------------------
  DATA: wa_icc           TYPE /PSYNG/SWRESVBAI,
        lf_table_locked TYPE flag,
        l_enq_start     TYPE /psyng/se16n_id,
        l_enq_current   TYPE /psyng/se16n_id,
        l_enq_duration  TYPE i.
*Wait for table to become unlocked
  lf_table_locked = 'X'.
  GET TIME STAMP FIELD l_enq_start.
  WHILE lf_table_locked = 'X'.
    CALL FUNCTION 'ENQUEUE_/PSYNG/SWRESVBAI'
         EXPORTING
      MODE_/PSYNG/SWRESVBAI = 'E'
      mandt                 = sy-mandt "#EC SAST_CI_GEN_CHECK (HBHALLA)
      _scope                = '2'
      _wait                 = 'X'
      _collect              = ' '
         EXCEPTIONS
              foreign_lock          = 1
              system_failure        = 2
              OTHERS                = 3.
    IF sy-subrc = 0.
      CLEAR lf_table_locked.
    ELSE.
      GET TIME STAMP FIELD l_enq_current.
      l_enq_duration = l_enq_current - l_enq_start.
      IF l_enq_duration > 30.
*      Lock can not be released.
*      Create new transid without using sap lock object
        PERFORM new_vbaid_ignore_lock CHANGING resid.
        EXIT.
      ENDIF.
    ENDIF.
  ENDWHILE.
  CHECK lf_table_locked IS INITIAL.
  SELECT SINGLE * FROM /PSYNG/SWRESVBAI INTO wa_icc.

  IF wa_icc-resid IS INITIAL.
    wa_icc-resid = 1.
    INSERT INTO /PSYNG/SWRESVBAI VALUES wa_icc.
  ELSE.
    ADD 1 TO wa_icc-resid.
    UPDATE /PSYNG/SWRESVBAI SET resid = wa_icc-resid.
  ENDIF.

  resid = wa_icc-resid.
  COMMIT WORK.
*unlock table
  CALL FUNCTION 'DEQUEUE_/PSYNG/SWRESVBAI'
       EXPORTING
    MODE_/PSYNG/SWRESVBAI = 'E'
    mandt                 = sy-mandt "#EC SAST_CI_GEN_CHECK (HBHALLA)
    _scope                = '3'
    _synchron             = ' '
    _collect              = ' '.


ENDFUNCTION.

*---------------------------------------------------------------------*
*       FORM new_transid_ignore_lock                                  *
*---------------------------------------------------------------------*
*       If the lock can't be achieved, get a new ID safely            *
*---------------------------------------------------------------------*
*  -->  SETID                                                         *
*---------------------------------------------------------------------*
FORM new_vbaid_ignore_lock CHANGING resid TYPE /PSYNG/SERES_VBAINDEX.
  DATA: wa_icc       TYPE /PSYNG/SWRESVBAI,
        wa_icc_check TYPE /PSYNG/SWRESVBAI.

  SELECT SINGLE * FROM /PSYNG/SWRESVBAI INTO wa_icc.
  IF wa_icc-resid IS INITIAL.
    wa_icc-resid = 1.
    INSERT INTO /PSYNG/SWRESVBAI VALUES wa_icc.
  ELSE.
    ADD 1 TO wa_icc-resid.
    UPDATE /PSYNG/SWRESVBAI SET resid = wa_icc-resid.
    COMMIT WORK.
  ENDIF.
*   try until transid in db is the one we have as output
  WHILE wa_icc-resid <> wa_icc_check-resid.
    SELECT SINGLE * FROM /PSYNG/SWRESVBAI INTO wa_icc_check.
    IF wa_icc-resid <> wa_icc_check-resid.
      ADD 1 TO wa_icc-resid.
      UPDATE /PSYNG/SWRESVBAI SET resid = wa_icc-resid.
      COMMIT WORK.
    ENDIF.
  ENDWHILE.
  resid = wa_icc-resid.
ENDFORM.                    " new_transid_ignore_lock
