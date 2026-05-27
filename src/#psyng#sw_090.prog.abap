*****           Implementation of object type /PSYNG/MC            *****
INCLUDE <OBJECT>.
BEGIN_DATA OBJECT. " Do not change.. DATA is generated
* only private members may be inserted into structure private
DATA:
" begin of private,
"   to declare private attributes remove comments and
"   insert private attributes here ...
" end of private,
  BEGIN OF KEY,
      MITCONTID LIKE /PSYNG/MCHDR-CONTID,
      TCODE_REP_INDICATOR LIKE /PSYNG/MCHDR-INACTIVE,
      PROGRAMNAME LIKE /PSYNG/MCREPID-REPID,
      AUDITOR LIKE /PSYNG/MCAUDITOR-AUDITOR,
  END OF KEY.
END_DATA OBJECT. " Do not change.. DATA is generated

BEGIN_METHOD MONITOR CHANGING CONTAINER.
DATA: ICONTID LIKE /PSYNG/MCHDR-CONTID,
      ITYPE   LIKE /PSYNG/MCTRAN-FREQUENCY,
      IREPID  LIKE /PSYNG/MCREPID-REPID.

  SWC_GET_ELEMENT CONTAINER 'IContid' ICONTID.
  SWC_GET_ELEMENT CONTAINER 'ITcode_Rep_Ind' ITYPE.
  SWC_GET_ELEMENT CONTAINER 'IRepid' IREPID.
  CALL FUNCTION '/PSYNG/SW_054'
    EXPORTING
      I_CONTID = ICONTID
      I_TYPE   = ITYPE
      I_REPID  = IREPID
    EXCEPTIONS
      OTHERS = 01.
  CASE SY-SUBRC.
    WHEN 0.            " OK
    WHEN OTHERS.       " to be implemented
  ENDCASE.
END_METHOD.





















