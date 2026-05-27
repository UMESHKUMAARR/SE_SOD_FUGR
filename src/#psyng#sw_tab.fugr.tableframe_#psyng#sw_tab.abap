*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_/PSYNG/SW_TAB
*   generation date: 19.11.2019 at 00:51:09 by user DDHIMAN
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_/PSYNG/SW_TAB      .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
