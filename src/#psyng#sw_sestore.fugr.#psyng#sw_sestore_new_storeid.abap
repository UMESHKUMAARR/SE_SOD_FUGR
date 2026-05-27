FUNCTION /psyng/sw_sestore_new_storeid.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IF_ROLE_ID) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     REFERENCE(RESID) TYPE  /PSYNG/SERESID
*"     REFERENCE(RRSID) TYPE  /PSYNG/SERRSID
*"----------------------------------------------------------------------
  DATA: wa_icc           TYPE /psyng/swresid,
        wa_icc_role      TYPE /psyng/swrrsid,
        lf_table_locked TYPE flag,
        l_enq_start     TYPE /psyng/se16n_id,
        l_enq_current   TYPE /psyng/se16n_id,
        l_enq_duration  TYPE i.
  IF if_role_id IS INITIAL.
*Get user SOD analysis ID
*Wait for table to become unlocked
    lf_table_locked = 'X'.
    GET TIME STAMP FIELD l_enq_start.
    WHILE lf_table_locked = 'X'.
      CALL FUNCTION 'ENQUEUE_/PSYNG/SWRESID'
           EXPORTING
        mode_/psyng/swresid = 'E'
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
          PERFORM new_transid_ignore_lock CHANGING resid.
          EXIT.
        ENDIF.
      ENDIF.
    ENDWHILE.
    CHECK lf_table_locked IS INITIAL.
    SELECT SINGLE * FROM /psyng/swresid INTO wa_icc.

    IF wa_icc-resid IS INITIAL.
      wa_icc-resid = 1.
      INSERT INTO /psyng/swresid VALUES wa_icc.
    ELSE.
      ADD 1 TO wa_icc-resid.
      UPDATE /psyng/swresid SET resid = wa_icc-resid.
    ENDIF.

    resid = wa_icc-resid.
    COMMIT WORK.
*unlock table
    CALL FUNCTION 'DEQUEUE_/PSYNG/SWRESID'
         EXPORTING
      mode_/psyng/swresid = 'E'
      mandt               = sy-mandt "#EC SAST_CI_GEN_CHECK (HBHALLA)
      _scope              = '3'
      _synchron           = ' '
      _collect            = ' '.
  ELSE.
*Get role SOD analysis ID
*Wait for table to become unlocked
    lf_table_locked = 'X'.
    GET TIME STAMP FIELD l_enq_start.
    WHILE lf_table_locked = 'X'.
      CALL FUNCTION 'ENQUEUE_/PSYNG/SWRRSID'
           EXPORTING
        mode_/psyng/swrrsid = 'E'
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
          PERFORM new_transid_role_ignore_lock CHANGING rrsid.
          EXIT.
        ENDIF.
      ENDIF.
    ENDWHILE.
    CHECK lf_table_locked IS INITIAL.
    SELECT SINGLE * FROM /psyng/swrrsid INTO wa_icc_role.

    IF wa_icc_role-resid IS INITIAL.
      wa_icc_role-resid = 1.
      INSERT INTO /psyng/swrrsid VALUES wa_icc_role.
    ELSE.
      ADD 1 TO wa_icc_role-resid.
      UPDATE /psyng/swrrsid SET resid = wa_icc_role-resid.
    ENDIF.

    rrsid = wa_icc_role-resid.
    COMMIT WORK.
*unlock table
    CALL FUNCTION 'DEQUEUE_/PSYNG/SWRRSID'
         EXPORTING
      mode_/psyng/swrrsid = 'E'
      mandt               = sy-mandt "#EC SAST_CI_GEN_CHECK (HBHALLA)
      _scope              = '3'
      _synchron           = ' '
      _collect            = ' '.
  ENDIF.

ENDFUNCTION.

*---------------------------------------------------------------------*
*       FORM new_transid_ignore_lock                                  *
*---------------------------------------------------------------------*
*       If the lock can't be achieved, get a new ID safely            *
*---------------------------------------------------------------------*
*  -->  SETID                                                         *
*---------------------------------------------------------------------*
FORM new_transid_ignore_lock CHANGING resid TYPE /psyng/seresid.
  DATA: wa_icc       TYPE /psyng/swresid,
        wa_icc_check TYPE /psyng/swresid.

  SELECT SINGLE * FROM /psyng/swresid INTO wa_icc.
  IF wa_icc-resid IS INITIAL.
    wa_icc-resid = 1.
    INSERT INTO /psyng/swresid VALUES wa_icc.
  ELSE.
    ADD 1 TO wa_icc-resid.
    UPDATE /psyng/swresid SET resid = wa_icc-resid.
    COMMIT WORK.
  ENDIF.
*   try until transid in db is the one we have as output
  WHILE wa_icc-resid <> wa_icc_check-resid.
    SELECT SINGLE * FROM /psyng/swresid INTO wa_icc_check.
    IF wa_icc-resid <> wa_icc_check-resid.
      ADD 1 TO wa_icc-resid.
      UPDATE /psyng/swresid SET resid = wa_icc-resid.
      COMMIT WORK.
    ENDIF.
  ENDWHILE.
  resid = wa_icc-resid.
ENDFORM.                    " new_transid_ignore_lock

*---------------------------------------------------------------------*
*       FORM new_transid_role_ignore_lock                             *
*---------------------------------------------------------------------*
*       If the lock can't be achieved, get a new ID safely            *
*---------------------------------------------------------------------*
*  -->  SETID                                                         *
*---------------------------------------------------------------------*
FORM new_transid_role_ignore_lock CHANGING resid TYPE /psyng/seresid.
  DATA: wa_icc       TYPE /psyng/swrrsid,
        wa_icc_check TYPE /psyng/swrrsid.

  SELECT SINGLE * FROM /psyng/swrrsid INTO wa_icc.
  IF wa_icc-resid IS INITIAL.
    wa_icc-resid = 1.
    INSERT INTO /psyng/swrrsid VALUES wa_icc.
  ELSE.
    ADD 1 TO wa_icc-resid.
    UPDATE /psyng/swrrsid SET resid = wa_icc-resid.
    COMMIT WORK.
  ENDIF.
*   try until transid in db is the one we have as output
  WHILE wa_icc-resid <> wa_icc_check-resid.
    SELECT SINGLE * FROM /psyng/swrrsid INTO wa_icc_check.
    IF wa_icc-resid <> wa_icc_check-resid.
      ADD 1 TO wa_icc-resid.
      UPDATE /psyng/swrrsid SET resid = wa_icc-resid.
      COMMIT WORK.
    ENDIF.
  ENDWHILE.
  resid = wa_icc-resid.
ENDFORM.                    " new_transid_ignore_lock
