FUNCTION /PSYNG/SW_ORG_LVL_RES_MOD.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IF_ORG_CHECK) TYPE  FLAG
*"     REFERENCE(IF_SUMMARY) TYPE  FLAG
*"  TABLES
*"      IT_ORGLVL STRUCTURE  /PSYNG/RANGE_DORG_ABB OPTIONAL
*"      IT_MAPPED_USERS STRUCTURE  /PSYNG/SW_USER_MAPPING OPTIONAL
*"      IT_FUNCTIONS STRUCTURE  /PSYNG/SW_OUTPUT_ORG OPTIONAL
*"      IT_DETAILS STRUCTURE  /PSYNG/SW_OUTPUTDET3 OPTIONAL
*"--------------------------------------------------------------------

if if_summary = 'X'.
*--The function module was called from the USER SOD Summary Report
*--Determine Org Area Abbreviations based on tables:
*  IT_ORGLVL
*  IT_MAPPED_USERS
*  IT_FUNCTIONS
else.
*--The function module was called from the USER SOD Detailed Report
*--Determine Org Area Abbreviations based on tables:
*  IT_ORGLVL
*  IT_DETAILS
endif.
ENDFUNCTION.
