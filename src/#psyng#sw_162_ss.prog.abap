*&---------------------------------------------------------------------*
*&  Include           /PSYNG/SW_162_SS
*&---------------------------------------------------------------------*

* A field to enter SOD version
* A check box to run report in test mode

SELECTION-SCREEN: BEGIN OF BLOCK b1 with FRAME TITLE text-001.
*PARAMETERS : p_vrsion TYPE /PSYNG/SODVRSIO.
PARAMETERS : p_vrsion TYPE char3.
SELECT-OPTIONS: so_fun for /psyng/functtran-functionid.

PARAMETERS        p_test AS CHECKBOX.
SELECTION-SCREEN: END OF BLOCK b1.
