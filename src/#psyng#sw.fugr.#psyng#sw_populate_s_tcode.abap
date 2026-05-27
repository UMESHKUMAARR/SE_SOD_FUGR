FUNCTION /PSYNG/SW_POPULATE_S_TCODE.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(P_AGRNAME) LIKE  AGR_DEFINE-AGR_NAME OPTIONAL
*"  TABLES
*"      IAGR_TCODES STRUCTURE  AGR_TCODES
*"----------------------------------------------------------------------
DATA: FR_LOW LIKE AGR_1251-LOW, FR_HIGH LIKE AGR_1251-HIGH.
DATA: FIRST_CHAR.
DATA: dbtstc TYPE SORTED TABLE OF tstc WITH UNIQUE KEY
             tcode
             WITH HEADER LINE.

select * from tstc into table dbtstc. "#EC CI_SEL_NESTED

SELECT * FROM AGR_1251       "#EC CI_SEL_NESTED
WHERE AGR_NAME = P_AGRNAME
AND   OBJECT = 'S_TCODE'
AND   FIELD = 'TCD'
AND   DELETED NE 'X'.

fr_low                = AGR_1251-LOW.
to_high               = AGR_1251-HIGH.
iagr_tcodes-agr_name  = p_agrname.
*=======================================================================
  first_char = fr_low.

  IF first_char = '*'.                     "If auth has "*" get all
    LOOP AT dbtstc. "#EC CI_SORTSEQ
      iagr_tcodes-tcode = dbtstc-tcode.

    ENDLOOP.
  ELSE.
    IF fr_low > space AND to_high > space. "If auth has range
      LOOP AT dbtstc "#EC CI_SORTSEQ
           WHERE tcode >= fr_low AND tcode <= to_high.
        iagr_tcodes-tcode = dbtstc-tcode.
        append iagr_tcodes.
      ENDLOOP.
      IF to_high CS '*'.
        IF sy-subrc = 0.          "get all transactions begining
          LOOP AT dbtstc "#EC CI_SORTSEQ
              WHERE tcode CP to_high.
            iagr_tcodes-tcode = dbtstc-tcode.
            append iagr_tcodes.
          ENDLOOP.
        ENDIF.
      ENDIF.
      IF fr_low CS '*'.
        IF sy-subrc = 0.             "get all transactions begining
          LOOP AT dbtstc "#EC CI_SORTSEQ
             WHERE tcode CP fr_low.
            iagr_tcodes-tcode = dbtstc-tcode.
            append iagr_tcodes.
          ENDLOOP.
        ENDIF.
      ENDIF.
    ELSE.               "If auth has a starting char with * following it
      IF fr_low CS '*'.
        LOOP AT dbtstc WHERE tcode CP fr_low. "#EC CI_SORTSEQ
          iagr_tcodes-tcode = dbtstc-tcode.
          append iagr_tcodes.
        ENDLOOP.
      ELSE.                "If specific transaction is specified
        READ TABLE dbtstc WITH KEY tcode = fr_low BINARY SEARCH.
        CHECK sy-subrc = 0.
        iagr_tcodes-tcode = dbtstc-tcode.
        append iagr_tcodes.
      ENDIF.
    ENDIF.
  ENDIF.
*=======================================================================
ENDSELECT.

ENDFUNCTION.
