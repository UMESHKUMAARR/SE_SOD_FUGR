FUNCTION /psyng/sw_api_resdet_read_all.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_AID) TYPE  /PSYNG/SERESID
*"     VALUE(I_NR_BATCHES) TYPE  INT4 OPTIONAL
*"     VALUE(IF_RESET) TYPE  FLAG OPTIONAL
*"     VALUE(I_BATCH_FROM) TYPE  INT4 OPTIONAL
*"     VALUE(I_BATCH_TO) TYPE  INT4 OPTIONAL
*"  EXPORTING
*"     VALUE(E_TOTAL_ROWS) TYPE  INT4
*"     VALUE(E_TOTAL_BATCH) TYPE  INT4
*"     VALUE(E_PROCESSED_ROWS) TYPE  INT4
*"     VALUE(E_BATCHES_READ) TYPE  INT4
*"     VALUE(RETURN) TYPE  BAPIRETURN
*"  TABLES
*"      IT_BNAME STRUCTURE  /PSYNG/SW_SEL_OPTS_XUBNAME
*"      IT_CONID STRUCTURE  /PSYNG/RANGE_CONID
*"      ET_OUTPUTDET_N STRUCTURE  /PSYNG/SW_OUTPUTDET OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"----------------------------------------------------------------------
*----------------------------------------------------------------------*
* Data declarations
*----------------------------------------------------------------------*
  DATA: lf_range_mode  TYPE flag,
        lf_bname       TYPE flag,
        lf_conid       TYPE flag,
        l_nr_batches   TYPE i,
        l_from_seq     TYPE i,
        l_to_seq       TYPE i,
        lv_msg         TYPE string,
        lv_total_c     TYPE char10,
        lv_to_c        TYPE char10,
        lv_from_c      TYPE char10,
        lv_seq_from_c  TYPE char10,
        lv_seq_to_c    TYPE char10,
        ls_out         TYPE /psyng/sw_outputdet,
        lt_data        TYPE TABLE OF /psyng/sw_resdet,
        ls_return      TYPE bapireturn,
        ls_track       TYPE /psyng/sw_det_t.

  FIELD-SYMBOLS: <ls_resdet> TYPE /psyng/sw_resdet.

  RANGES: lr_seq   FOR /psyng/sw_resdet-batch_seq,
          lr_bname FOR /psyng/sw_resdet-bname,
          lr_conid FOR /psyng/sw_resdet-conid.

*----------------------------------------------------------------------*
* SECTION 1: Authority check
*----------------------------------------------------------------------*
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_API_RESDET_READ_ALL'.
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
  AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
            ID 'ACTVT' FIELD '03'.

  IF sy-subrc <> 0.
    ls_return-type    = 'E'.
    ls_return-message = 'Not authorized to read SE result data'.
    return = ls_return.
    APPEND ls_return TO et_return.
    EXIT.
  ENDIF.

*----------------------------------------------------------------------*
* SECTION 2: Validate mandatory AID
*----------------------------------------------------------------------*
  IF i_aid IS INITIAL.
    ls_return-type    = 'E'.
    ls_return-message = 'I_AID is mandatory and cannot be empty'.
    return = ls_return.
    APPEND ls_return TO et_return.
    EXIT.
  ENDIF.

*----------------------------------------------------------------------*
* SECTION 3: Read tracking table
* Both modes need TOTAL_BATCH, TOTAL_ROWS, BATCHES_READ.
* FM2 must have run for this AID. Single PK SELECT — negligible cost.
*----------------------------------------------------------------------*
  SELECT SINGLE *
    INTO ls_track
    FROM /psyng/sw_det_t
    WHERE aid = i_aid.                                  "#EC CI_GENBUFF

  IF sy-subrc <> 0.
    ls_return-type    = 'E'.
    ls_return-message =
    'No batch data found for this AID. Run Background job first.'.
    return = ls_return.
    APPEND ls_return TO et_return.
    EXIT.
  ENDIF.

* Populate totals — returned regardless of mode, zero extra DB cost
  e_total_rows  = ls_track-total_rows.
  e_total_batch = ls_track-total_batch.

*----------------------------------------------------------------------*
* SECTION 4: Mode detection and filter flag population
*
* lf_range_mode — set if I_BATCH_FROM supplied
* lf_bname      — set if IT_BNAME has entries
* lf_conid      — set if IT_CONID has entries
*
* IT_BNAME and IT_CONID are TABLES params with header line.
* Copied into local RANGES (lr_bname, lr_conid) for SELECT IN clause.
*----------------------------------------------------------------------*
  IF i_batch_from IS NOT INITIAL.
    lf_range_mode = 'X'.
  ENDIF.

  IF it_bname[] IS NOT INITIAL.
    lf_bname = 'X'.
    LOOP AT it_bname.
      lr_bname-sign   = it_bname-sign.
      lr_bname-option = it_bname-option.
      lr_bname-low    = it_bname-low.
      lr_bname-high   = it_bname-high.
      APPEND lr_bname.
    ENDLOOP.
  ENDIF.

  IF it_conid[] IS NOT INITIAL.
    lf_conid = 'X'.
    LOOP AT it_conid.
      lr_conid-sign   = it_conid-sign.
      lr_conid-option = it_conid-option.
      lr_conid-low    = it_conid-low.
      lr_conid-high   = it_conid-high.
      APPEND lr_conid.
    ENDLOOP.
  ENDIF.

*======================================================================*
* SECTION 5: Input contract validation
*======================================================================*

*----------------------------------------------------------------------*
* CV-1: Cross-mode contamination
*----------------------------------------------------------------------*
  IF lf_range_mode = 'X'.

    IF i_nr_batches IS NOT INITIAL.
      ls_return-type    = 'E'.
      ls_return-message =
 'I_NR_BATCHES is cursor mode only. Remove it or remove I_BATCH_FROM.'.
      return = ls_return.
      APPEND ls_return TO et_return.
      EXIT.
    ENDIF.

    IF if_reset = 'X'.
      ls_return-type    = 'E'.
      ls_return-message =
 'IF_RESET is cursor mode only. Range mode never modifies the cursor.'.
      return = ls_return.
      APPEND ls_return TO et_return.
      EXIT.
    ENDIF.

  ELSE.

    IF i_batch_to IS NOT INITIAL.
      ls_return-type    = 'E'.
      ls_return-message =
'I_BATCH_TO requir I_BATCH_FROM.Add I_BATCH_FROM or remove I_BATCH_TO.'.
      return = ls_return.
      APPEND ls_return TO et_return.
      EXIT.
    ENDIF.

    IF lf_bname = 'X'.
      ls_return-type    = 'E'.
      ls_return-message =
'IT_BNAME is range mode only.Give I_BATCH_FROM to activate range mode.'.
      return = ls_return.
      APPEND ls_return TO et_return.
      EXIT.
    ENDIF.

    IF lf_conid = 'X'.
      ls_return-type    = 'E'.
      ls_return-message =
'IT_CONID is range mode only.Give I_BATCH_FROM to activate range mode.'.
      return = ls_return.
      APPEND ls_return TO et_return.
      EXIT.
    ENDIF.

  ENDIF.

*----------------------------------------------------------------------*
* CV-2: Value validation within each mode
*----------------------------------------------------------------------*
  IF lf_range_mode = 'X'.

    IF i_batch_from < 1.
      ls_return-type    = 'E'.
      ls_return-message =
'I_BATCH_FROM must be >= 1. BATCH_SEQ numbering starts at 1.'.
      return = ls_return.
      APPEND ls_return TO et_return.
      EXIT.
    ENDIF.

    IF i_batch_from > ls_track-total_batch.
      WRITE ls_track-total_batch TO lv_total_c LEFT-JUSTIFIED.
      CONDENSE lv_total_c.
      CONCATENATE 'I_BATCH_FROM exceeds total batches. Available:'
                  lv_total_c
        INTO lv_msg SEPARATED BY ' '.
      ls_return-type    = 'E'.
      ls_return-message = lv_msg.
      return = ls_return.
      APPEND ls_return TO et_return.
      EXIT.
    ENDIF.

    IF i_batch_to IS NOT INITIAL AND
       i_batch_to < i_batch_from.
      WRITE i_batch_to   TO lv_to_c   LEFT-JUSTIFIED.
      WRITE i_batch_from TO lv_from_c LEFT-JUSTIFIED.
      CONDENSE lv_to_c.
      CONDENSE lv_from_c.
      CONCATENATE 'I_BATCH_TO (' lv_to_c
                  ') must be >= I_BATCH_FROM (' lv_from_c
                  '). Inverted range not allowed.'
        INTO lv_msg.
      ls_return-type    = 'E'.
      ls_return-message = lv_msg.
      return = ls_return.
      APPEND ls_return TO et_return.
      EXIT.
    ENDIF.

  ELSE.

    IF i_nr_batches < 0.
      ls_return-type    = 'E'.
      ls_return-message =
        'I_NR_BATCHES cannot be negative. Omit for default of 1.'.
      return = ls_return.
      APPEND ls_return TO et_return.
      EXIT.
    ENDIF.

    IF i_nr_batches = 0.
      ls_return-type    = 'W'.
      ls_return-message =
        'I_NR_BATCHES = 0 is invalid. Defaulting to 1 batch.'.
      return = ls_return.
      APPEND ls_return TO et_return.
      CLEAR ls_return.
    ENDIF.

    IF if_reset = 'X' AND ls_track-batches_read = 0.
      ls_return-type    = 'I'.
      ls_return-message =
        'IF_RESET = X has no effect. BATCHES_READ is already 0.'.
      return = ls_return.
      APPEND ls_return TO et_return.
      CLEAR ls_return.
    ENDIF.

  ENDIF.

*======================================================================*
* END OF VALIDATION
*======================================================================*

  IF lf_range_mode = 'X'.

*======================================================================*
* SECTION 6A: RANGE MODE — stateless, cursor never touched
*======================================================================*

*-- RM-1: Resolve read window -----------------------------------------
    l_from_seq = i_batch_from.

    IF i_batch_to IS INITIAL.
      l_to_seq = i_batch_from.
    ELSE.
      l_to_seq = i_batch_to.
    ENDIF.

    IF l_to_seq > ls_track-total_batch.
      l_to_seq = ls_track-total_batch.
    ENDIF.

*-- RM-2: Build BATCH_SEQ range (inline) ------------------------------
    CLEAR lr_seq.
    lr_seq-sign   = 'I'.
    lr_seq-option = 'BT'.
    lr_seq-low    = l_from_seq.
    lr_seq-high   = l_to_seq.
    APPEND lr_seq.

*-- RM-3: Single SELECT using PK (MANDT+AID+BATCH_SEQ+ROW_SEQ) -------
*   PK range scan on AID+BATCH_SEQ fetches only the requested window.
*   BNAME and CONID filtered in ABAP memory on the small result set.
*   No secondary index needed — PK covers AID+BATCH_SEQ directly.
*   No ORDER BY — range mode is ad-hoc, not streaming pagination.

    SELECT *
      FROM /psyng/sw_resdet
      INTO TABLE lt_data
      WHERE aid       = i_aid
        AND batch_seq IN lr_seq.                        "#EC CI_GENBUFF

*-- RM-4: BNAME filter (ABAP in-memory) with message ------------------
    IF lf_bname = 'X'.
      DELETE lt_data WHERE bname NOT IN lr_bname.

      IF lt_data IS INITIAL.
*       FIX MISS-1: users filter eliminated all rows — warn explicitly
        WRITE l_from_seq TO lv_seq_from_c LEFT-JUSTIFIED.
        WRITE l_to_seq   TO lv_seq_to_c   LEFT-JUSTIFIED.
        CONDENSE lv_seq_from_c.
        CONDENSE lv_seq_to_c.
        CONCATENATE 'No data found for the given users'
                    'in BATCH_SEQ' lv_seq_from_c '-' lv_seq_to_c
                    '. Users may exist in other batch ranges.'
          INTO lv_msg SEPARATED BY ' '.
        ls_return-type    = 'W'.
        ls_return-message = lv_msg.
        return = ls_return.
        APPEND ls_return TO et_return.
        e_batches_read    = ls_track-batches_read.
        e_processed_rows  = 0.
        EXIT.
      ENDIF.
    ENDIF.

*-- RM-5: CONID filter (ABAP in-memory) with message ------------------
    IF lf_conid = 'X'.
      DELETE lt_data WHERE conid NOT IN lr_conid.

      IF lt_data IS INITIAL.
*       FIX MISS-2/3: conid filter (after optional bname filter)
*       eliminated all rows — distinguish which filter caused it
        WRITE l_from_seq TO lv_seq_from_c LEFT-JUSTIFIED.
        WRITE l_to_seq   TO lv_seq_to_c   LEFT-JUSTIFIED.
        CONDENSE lv_seq_from_c.
        CONDENSE lv_seq_to_c.
        IF lf_bname = 'X'.
*         MISS-3: both filters supplied — users valid but CONID mismatch
          CONCATENATE 'No data found- Given users do not have'
                      'the specified conflicts in BATCH_SEQ'
                      lv_seq_from_c '-' lv_seq_to_c
                      '. Try a wider batch range.'
            INTO lv_msg SEPARATED BY ' '.
        ELSE.
*         MISS-2: only CONID filter — conflict not in this batch range
          CONCATENATE 'No data found for the given conflicts'
                      'in BATCH_SEQ' lv_seq_from_c '-' lv_seq_to_c
                      '. Conflicts may exist in other batch ranges.'
            INTO lv_msg SEPARATED BY ' '.
        ENDIF.
        ls_return-type    = 'W'.
        ls_return-message = lv_msg.
        return = ls_return.
        APPEND ls_return TO et_return.
        e_batches_read    = ls_track-batches_read.
        e_processed_rows  = 0.
        EXIT.
      ENDIF.
    ENDIF.
*-- RM-6: Sort for consistent output order ----------------------------
*   FIX: Range Mode had no sort — Cursor Mode already had this sort.
*   Both modes must return rows in the same deterministic order.
*    SORT lt_data BY bname conid sysid funid.
    SORT lt_data BY bname conid sysid funid agr_name comp_agr
                         profname tcode object field von.
    DESCRIBE TABLE lt_data LINES e_processed_rows.
*-- RM-7: Transfer to output ------------------------------------------
    LOOP AT lt_data ASSIGNING <ls_resdet>.
      MOVE-CORRESPONDING <ls_resdet> TO ls_out.
      APPEND ls_out TO et_outputdet_n.
      CLEAR ls_out.
    ENDLOOP.

*-- RM-8: Return cursor as informational — NOT updated ----------------
    e_batches_read = ls_track-batches_read.

*-- RM-9: Success message — W if zero rows, S if data returned --------
*   FIX MISS-4: [S] with Rows:0 was misleading — use [W] when empty
    PERFORM build_success_message
      USING    'R'
               l_from_seq
               l_to_seq
               e_processed_rows
               e_batches_read
      CHANGING lv_msg.

    IF e_processed_rows = 0.
      ls_return-type = 'W'.
    ELSE.
      ls_return-type = 'S'.
    ENDIF.
    ls_return-message = lv_msg.
    return = ls_return.
    APPEND ls_return TO et_return.

  ELSE.

*======================================================================*
* SECTION 6B: CURSOR MODE — stateful, advances cursor on each call
*
* IT_BNAME and IT_CONID intentionally blocked in cursor mode.
* A user's rows span ALL BATCH_SEQs. Filtering in cursor mode advances
* the cursor past batches with un-returned rows — permanent data loss.
*======================================================================*

*-- CM-1: Optional reset ----------------------------------------------
    IF if_reset = 'X'.
      ls_track-batches_read = 0.
      ls_track-updated_on   = sy-datum.
      UPDATE /psyng/sw_det_t FROM ls_track.               "#EC CI_SUBRC
      COMMIT WORK.
    ENDIF.

*-- CM-2: Check if all batches consumed -------------------------------
    IF ls_track-batches_read >= ls_track-total_batch.
      ls_return-type    = 'I'.
      ls_return-message =
'All batches already read for this AID.Reset batch cursor.'.
      return = ls_return.
      APPEND ls_return TO et_return.
      e_batches_read = ls_track-batches_read.
      EXIT.
    ENDIF.

*-- CM-3: Resolve NR_BATCHES ------------------------------------------
    IF i_nr_batches > 0.
      l_nr_batches = i_nr_batches.
    ELSE.
      l_nr_batches = 1.
    ENDIF.

*-- CM-4: Compute read window -----------------------------------------
    l_from_seq = ls_track-batches_read + 1.
    l_to_seq   = ls_track-batches_read + l_nr_batches.
    IF l_to_seq > ls_track-total_batch.
      l_to_seq = ls_track-total_batch.
    ENDIF.

*-- CM-5: Build BATCH_SEQ range (inline) ------------------------------
    CLEAR lr_seq.
    lr_seq-sign   = 'I'.
    lr_seq-option = 'BT'.
    lr_seq-low    = l_from_seq.
    lr_seq-high   = l_to_seq.
    APPEND lr_seq.

*-- CM-6: SELECT — no BNAME/CONID filter by design --------------------
    SELECT *
      FROM /psyng/sw_resdet
      INTO TABLE lt_data
      WHERE aid       = i_aid
        AND batch_seq IN lr_seq.                        "#EC CI_GENBUFF

*    SORT lt_data BY bname conid sysid funid.
    SORT lt_data BY bname conid sysid funid agr_name comp_agr
                             profname tcode object field von.
    e_processed_rows = sy-dbcnt.

*-- CM-7: Transfer to output (inline) ---------------------------------
    LOOP AT lt_data ASSIGNING <ls_resdet>.
      MOVE-CORRESPONDING <ls_resdet> TO ls_out.
      APPEND ls_out TO et_outputdet_n.
      CLEAR ls_out.
    ENDLOOP.

*-- CM-8: Advance cursor — ONLY state mutation in this FM -------------
    ls_track-batches_read = l_to_seq.
    ls_track-updated_on   = sy-datum.
    UPDATE /psyng/sw_det_t FROM ls_track.                 "#EC CI_SUBRC
    COMMIT WORK.

    e_batches_read = l_to_seq.

*-- CM-9: Success message ---------------------------------------------
    PERFORM build_success_message
      USING    'C'
               l_from_seq
               l_to_seq
               e_processed_rows
               e_batches_read
      CHANGING lv_msg.

    IF e_processed_rows = 0.
      ls_return-type = 'W'.
    ELSE.
      ls_return-type = 'S'.
    ENDIF.
    ls_return-message = lv_msg.
    return = ls_return.
    APPEND ls_return TO et_return.

  ENDIF.
ENDFUNCTION.
