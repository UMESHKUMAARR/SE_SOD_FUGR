*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_/PSYNG/SW
*   generation date: 02/25/2006 at 23:46:28 by user SSANGHA
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_/PSYNG/SW          .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
