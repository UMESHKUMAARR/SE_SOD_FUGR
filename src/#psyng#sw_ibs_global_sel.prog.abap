*&---------------------------------------------------------------------*
*&  Include           /PSYNG/SW_IBS_GLOBAL_SEL
*&---------------------------------------------------------------------*
*================ SELECTION-SCREEN==================
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.

PARAMETERS: p_vrsn TYPE /psyng/conflict-vrsio   " SOD Version
MEMORY ID /psyng/vrsio.

PARAMETERS : p_ibstxt AS CHECKBOX DEFAULT '' USER-COMMAND hide.
*Checkbox for using existing version description

PARAMETERS : p_vdesc TYPE /psyng/swsodvers-vdesc.
"New version description
SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: p_ovrwrt AS CHECKBOX USER-COMMAND show.
"Overwrite tables for current version
SELECTION-SCREEN COMMENT 3(60) text-006 FOR FIELD p_ovrwrt.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
*PARAMETER: p_tstrun  AS CHECKBOX DEFAULT 'X' USER-COMMAND show.
PARAMETER: p_tstrun  AS CHECKBOX USER-COMMAND show.
" Test run
SELECTION-SCREEN COMMENT 3(60) text-007 FOR FIELD p_tstrun.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETER p_noval AS CHECKBOX USER-COMMAND show.    " Skip vaidations
SELECTION-SCREEN COMMENT 3(60) text-008 FOR FIELD p_noval.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-002.
PARAMETERS : p_dlt_db AS CHECKBOX DEFAULT ''.  " Clear Meta data
SELECTION-SCREEN END OF BLOCK b2.
