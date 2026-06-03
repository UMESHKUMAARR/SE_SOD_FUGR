*&---------------------------------------------------------------------*
*& Report  /PSYNG/SW_RUN_RESDET_BATCH_JB
*& Wrapper: runs /PSYNG/SW_ANALY_RES_DET_BATCH as background job
*& Schedule via SM36. Produces both spool and job log entries.
*&
*& Spool  : WRITE statements — visible in SM37 → Spool → Display
*&           and on screen when run from SE38 in foreground
*& Job log: MESSAGE statements — visible in SM37 → Job log tab
*&           persists independently of spool, first thing ops checks
*&
*& Message class /PSYNG/SW msg 002: & & & & (4 free-text placeholders)
*&---------------------------------------------------------------------*
REPORT /psyng/sw_run_resdet_batch_jb.

*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

PARAMETERS:
  p_aid    TYPE /psyng/seresid OBLIGATORY,    " Analysis Run ID
  p_clear  TYPE flag           DEFAULT 'X'. " Clear previous data(X=Yes)

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.

PARAMETERS:
  p_exmit  TYPE flag DEFAULT space,     " Exclude mitigated conflicts
*  p_direct TYPE flag DEFAULT space,           " Direct assignments only
  p_local  TYPE flag DEFAULT space,            " Local system only
  p_def    TYPE flag DEFAULT space.            " Use default run

SELECTION-SCREEN END OF BLOCK b2.

*----------------------------------------------------------------------*
* Text symbols (SE38 → Goto → Text Elements → Text Symbols):
*   001 = Analysis Run Settings
*   002 = Filter Options
*----------------------------------------------------------------------*

*----------------------------------------------------------------------*
* Main
*----------------------------------------------------------------------*
START-OF-SELECTION.

  DATA: ls_return    TYPE bapireturn,
        lt_return    TYPE TABLE OF bapireturn,
        ls_ret       TYPE bapireturn,
        lv_run       TYPE /psyng/seresid,
        lv_batches   TYPE int4,
        lv_rows      TYPE int4,
        lv_users     TYPE int4,
        lv_bat_c     TYPE char10,
        lv_row_c     TYPE char20,
        lv_usr_c     TYPE char10,
        lv_aid_c     TYPE char20,
        lv_flags     TYPE string,
        lv_line1     TYPE char50,
        lv_line2     TYPE char50,
        lt_active    TYPE TABLE OF string,
        lv_joined    TYPE string,
        lv_has_error TYPE flag.

*----------------------------------------------------------------------*
* Build compact flag string — only active flags shown
*----------------------------------------------------------------------*
*  IF p_exmit  = 'X'. APPEND `EXCL_MITIGATED` TO lt_active. ENDIF.
*  IF p_direct = 'X'. APPEND `DIRECT_ASSN`    TO lt_active. ENDIF.
*  IF p_clear  = 'X'. APPEND `CLEAR_PREV`     TO lt_active. ENDIF.
*  IF p_local  = 'X'. APPEND `LOCAL`          TO lt_active. ENDIF.
*  IF p_def    = 'X'. APPEND `DEF_RUN`        TO lt_active. ENDIF.
*
*  IF lt_active IS INITIAL.
*    lv_flags = 'Flags: none'.
*  ELSE.
*    CONCATENATE LINES OF lt_active INTO lv_joined SEPARATED BY ' '.
*    CONCATENATE 'Flags:' lv_joined INTO lv_flags SEPARATED BY ' '.
*  ENDIF.

  WRITE p_aid TO lv_aid_c LEFT-JUSTIFIED.
  CONDENSE lv_aid_c.

*----------------------------------------------------------------------*
* START — write to both spool and job log
*----------------------------------------------------------------------*
* Spool (screen in SE38, spool in SM36)
  WRITE: / 'START  AID:' , lv_aid_c , lv_flags ,
           '  Time:' , sy-uzeit.

* Job log (SM37 → Job log tab) — MESSAGE s = success type, no popup
  CONCATENATE 'AID:' lv_aid_c INTO lv_line1 SEPARATED BY ' '.
  MESSAGE s002(/psyng/sw)
    WITH 'START:' lv_line1 lv_flags sy-uzeit.

*----------------------------------------------------------------------*
* Call FM2
*----------------------------------------------------------------------*
  CALL FUNCTION '/PSYNG/SW_ANALY_RES_DET_BATCH'
    EXPORTING
      analysis_run         = p_aid
      if_local             = p_local
      if_def_run           = p_def
      if_clear_prev        = p_clear
      if_exclude_mitigated = p_exmit
*      if_direct_assn_only  = p_direct
    IMPORTING
      e_analysis_run       = lv_run
      return               = ls_return
      e_batches_created    = lv_batches
      e_rows_written       = lv_rows
      e_users_processed    = lv_users
    TABLES
      et_return            = lt_return.

*----------------------------------------------------------------------*
* Build result display strings
*----------------------------------------------------------------------*
  WRITE lv_batches TO lv_bat_c LEFT-JUSTIFIED.
  WRITE lv_rows    TO lv_row_c LEFT-JUSTIFIED.
  WRITE lv_users   TO lv_usr_c LEFT-JUSTIFIED.
  CONDENSE: lv_bat_c, lv_row_c, lv_usr_c.

  LOOP AT lt_return INTO ls_ret
    WHERE type = 'E' OR type = 'A'.
    lv_has_error = 'X'.
    EXIT.
  ENDLOOP.

*----------------------------------------------------------------------*
* DONE / ERROR / WARN — spool + job log
*----------------------------------------------------------------------*
  IF lv_has_error = 'X' OR ls_return-type = 'E' OR ls_return-type = 'A'.

*   Spool: list all errors and warnings
    WRITE: / 'ERROR  AID:' , lv_aid_c , '  Time:' , sy-uzeit.
    LOOP AT lt_return INTO ls_ret
      WHERE type = 'E' OR type = 'A' OR type = 'W'.
      WRITE: / '  [' , ls_ret-type , ']' , ls_ret-message.
    ENDLOOP.

*   Job log: one error entry — marks job step as failed in SM37
    CONCATENATE 'ERROR  AID:' lv_aid_c INTO lv_line1 SEPARATED BY ' '.
    MESSAGE e002(/psyng/sw)                               "#EC NOTEXT
      WITH lv_line1 ls_return-message ' ' ' '.

  ELSEIF lv_rows > 0.

*   Spool
    WRITE: / 'DONE   AID:' , lv_aid_c.
    WRITE: / '       Batches:' , lv_bat_c ,
             '  Rows:'    , lv_row_c ,
             '  Users:'   , lv_usr_c ,
             '  Time:'    , sy-uzeit.

*   Job log: two entries — AID line then counts line
    CONCATENATE 'DONE   AID:' lv_aid_c INTO lv_line1 SEPARATED BY ' '.
    CONCATENATE 'Batches:' lv_bat_c 'Rows:' lv_row_c 'Users:' lv_usr_c
      INTO lv_line2 SEPARATED BY ' '.
    MESSAGE s002(/psyng/sw)
      WITH lv_line1 lv_line2 sy-uzeit ' '.

  ELSE.

*   Spool
    WRITE: / 'WARN   AID:' , lv_aid_c ,
             '— 0 rows written. Check user/conflict selection.'.
    WRITE: / '       Time:' , sy-uzeit.

*   Job log: warning entry
    CONCATENATE 'WARN   AID:' lv_aid_c '0 rows written'
      INTO lv_line1 SEPARATED BY ' '.
    MESSAGE w002(/psyng/sw)
      WITH lv_line1 'Check selection.' ' ' ' '.

  ENDIF.
