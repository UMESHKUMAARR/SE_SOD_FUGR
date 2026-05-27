*&---------------------------------------------------------------------*
*&  Include           /PSYNG/SW_IMPORT_SEL
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
PARAMETERS : p_upload TYPE rlgrap-filename. "Paramenter to get the file name
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-002.
PARAMETERS : p_meta AS CHECKBOX DEFAULT 'X' USER-COMMAND u1 MODIF ID dta . "Checkbox to enable/disable meta check
*PARAMETERS : p_meta AS CHECKBOX  USER-COMMAND u1  MODIF ID dta . "Checkbox to enable/disable meta check
PARAMETERS : p_null AS CHECKBOX  MODIF ID tda. "Checkbox to enable/disable meta check
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE text-003.
PARAMETERS : p_clr_db AS CHECKBOX DEFAULT 'X'. "Checkbox to enable/disable for data deletion from temporary DB
SELECTION-SCREEN END OF BLOCK b3.
