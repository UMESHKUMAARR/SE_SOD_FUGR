FUNCTION /psyng/sw_adm_refresh_ovrview.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  EXPORTING
*"     VALUE(EF_SUCCESS) TYPE  FLAG
*"  TABLES
*"      IT_SYSTEM STRUCTURE  /PSYNG/RANGE_SYSID OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------
  DATA: lt_detail TYPE TABLE OF /psyng/swadmovw WITH HEADER LINE,
        l_count TYPE string.

*--get configured system detail
  CALL FUNCTION '/PSYNG/SW_VRSIO_COUNT'
       EXPORTING
            i_detail_info = 'X'
       TABLES
            et_detail     = lt_detail
            it_system     = it_system.
  LOOP AT it_system.
    READ TABLE lt_detail WITH KEY systid = it_system-low.
    IF sy-subrc <> 0.
      CLEAR lt_detail.
      lt_detail-last_check = sy-datum.
      lt_detail-systid     = it_system-low.
      log et_return 'E' 'FAILED' 'Failed' 'System:' it_system-low ''.
    ENDIF.
*--delete old and insert the new values
    DELETE FROM /psyng/swadmovw WHERE  systid = it_system-low.
    IF sy-subrc = 0.
      log et_return 'S' 'DELETED' 'Deleted' 'System' it_system-low ''.
      COMMIT WORK.
      CLEAR l_count.
    ENDIF.
    MODIFY /psyng/swadmovw FROM TABLE lt_detail.
    IF sy-subrc = 0.
      log et_return 'S'
        'INSERTED' 'Inserted'    'System:'    it_system-low ''.
      COMMIT WORK.
      ef_success = 'X'.
      CLEAR l_count.
    ENDIF.
  ENDLOOP.
ENDFUNCTION.
