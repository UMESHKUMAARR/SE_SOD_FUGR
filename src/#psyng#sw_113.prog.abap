***INCLUDE /PSYNG/SW_113 .
DATA : l_yesterday TYPE dats,
       gf_invalid_rfc TYPE C.

l_yesterday = sy-datum - 1.
************************************************************************
*--Selection Subscreen for SOD Live
************************************************************************
SELECTION-SCREEN BEGIN OF SCREEN 1200 AS SUBSCREEN.
SELECTION-SCREEN: BEGIN OF BLOCK b_live WITH FRAME .
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: lvl1 RADIOBUTTON GROUP g7 DEFAULT 'X'
                                          MODIF ID liv
                                          USER-COMMAND liv.
SELECTION-SCREEN COMMENT 3(72) text-l01 MODIF ID liv.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: lvl2 RADIOBUTTON GROUP g7   MODIF ID liv.
SELECTION-SCREEN COMMENT 3(72) text-l02 MODIF ID liv.
SELECTION-SCREEN: END OF LINE.



SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: lvl3 RADIOBUTTON GROUP g7   MODIF ID liv.
SELECTION-SCREEN COMMENT 3(77) text-l05 MODIF ID liv.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: lvl4 RADIOBUTTON GROUP g7   MODIF ID liv.
SELECTION-SCREEN COMMENT 3(77)
                         text-l12
                         for field lvl4 MODIF ID liv.
SELECTION-SCREEN: END OF LINE.


PARAMETERS : lvl3st TYPE dats              MODIF ID liv NO-DISPLAY.
PARAMETERS : lvl3ed TYPE dats              MODIF ID liv
DEFAULT l_yesterday NO-DISPLAY
.



SELECTION-SCREEN: BEGIN OF BLOCK b_liv2.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) text-l03
  MODIF ID liv
  FOR FIELD lvl3st.
SELECTION-SCREEN : POSITION 34.
PARAMETERS : lvl2st TYPE dats
  MODIF ID liv .
SELECTION-SCREEN COMMENT 46(3) text-l04
  MODIF ID liv
  FOR FIELD lvl3ed.
SELECTION-SCREEN : POSITION 57.
PARAMETERS : lvl2ed TYPE dats
  MODIF ID liv DEFAULT l_yesterday.
SELECTION-SCREEN: END OF LINE.
PARAMETERS: hidestd AS CHECKBOX           MODIF ID liv.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: lvl3_cd AS CHECKBOX
  MODIF ID liv DEFAULT 'X' .
SELECTION-SCREEN COMMENT 3(72) text-l06
  MODIF ID liv FOR FIELD lvl3_cd.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: lvl3_tl AS CHECKBOX
  MODIF ID liv DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(72) text-l07
  MODIF ID liv FOR FIELD lvl3_tl.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK b_liv2.

SELECTION-SCREEN: END OF BLOCK b_live.



SELECTION-SCREEN END OF SCREEN 1200.

************************************************************************
*--Selection Subscreen for simulation
************************************************************************
SELECTION-SCREEN BEGIN OF SCREEN 1100 AS SUBSCREEN.
SELECTION-SCREEN: BEGIN OF BLOCK b_sim .
SELECT-OPTIONS: simurols FOR agr_define-agr_name
                                           MODIF ID sim
                                           NO-DISPLAY.
PARAMETERS: rolerfc LIKE rfcdes-rfcdest MATCHCODE OBJECT
 /psyng/sw_rfcsh_coll
    MODIF ID sim NO-DISPLAY.
*--Remote Simulation with source and destination RFC's
SELECTION-SCREEN: BEGIN OF BLOCK b_sim_add2 WITH FRAME TITLE text-bsa.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: bysimu AS CHECKBOX DEFAULT ' ' MODIF ID sim
USER-COMMAND sim.
SELECTION-SCREEN: COMMENT 3(27) text-h14 FOR FIELD bysimu
                                           MODIF ID sim.

SELECTION-SCREEN: END OF LINE.
*--Column labels
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(13)   text-c01 FOR FIELD bysimu
                                           MODIF ID sim.
SELECTION-SCREEN: COMMENT 15(13)  text-c02 FOR FIELD bysimu
                                           MODIF ID sim.

SELECTION-SCREEN: COMMENT 32(20) text-h23 FOR FIELD bysimu
                                           MODIF ID sim.
SELECTION-SCREEN: COMMENT 57(20) text-h24 FOR FIELD bysimu
                                           MODIF ID sim.
SELECTION-SCREEN: END OF LINE.
*--Simulation additions
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS:     ar_rfcs1 LIKE rfcdes-rfcdest MATCHCODE OBJECT
                         /psyng/sw_rfcsh_coll     MODIF ID sim
                VISIBLE LENGTH 13.
PARAMETERS:     ar_rfcd1 LIKE rfcdes-rfcdest MATCHCODE OBJECT
                        /psyng/sw_rfcsh_coll      MODIF ID sim
                VISIBLE LENGTH 13.

SELECT-OPTIONS: ar_rol_1 FOR  agr_define-agr_name MODIF ID sim.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS:     ar_rfcs2 LIKE rfcdes-rfcdest MATCHCODE OBJECT
                         /psyng/sw_rfcsh_coll     MODIF ID sim
                VISIBLE LENGTH 13.
PARAMETERS:     ar_rfcd2 LIKE rfcdes-rfcdest MATCHCODE OBJECT
                          /psyng/sw_rfcsh_coll    MODIF ID sim
                VISIBLE LENGTH 13.

SELECT-OPTIONS: ar_rol_2 FOR  agr_define-agr_name MODIF ID sim.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS:     ar_rfcs3 LIKE rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll      MODIF ID sim
                VISIBLE LENGTH 13.
PARAMETERS:     ar_rfcd3 LIKE rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll     MODIF ID sim
                VISIBLE LENGTH 13.

SELECT-OPTIONS: ar_rol_3 FOR  agr_define-agr_name MODIF ID sim.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS:     ar_rfcs4 LIKE rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll      MODIF ID sim
                VISIBLE LENGTH 13.
PARAMETERS:     ar_rfcd4 LIKE rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll     MODIF ID sim
                VISIBLE LENGTH 13.

SELECT-OPTIONS: ar_rol_4 FOR  agr_define-agr_name MODIF ID sim.
SELECTION-SCREEN: END OF LINE.



SELECTION-SCREEN: END OF BLOCK b_sim_add2 .



SELECTION-SCREEN: BEGIN OF BLOCK b_sim_del WITH FRAME TITLE text-bsd.
PARAMETERS: byrsimu AS CHECKBOX DEFAULT ' ' MODIF ID sim
USER-COMMAND sim.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(25) text-h15 FOR FIELD bysimu
                                           MODIF ID sim.
SELECTION-SCREEN: COMMENT 30(20) text-h23 FOR FIELD bysimu
                                           MODIF ID sim.
SELECTION-SCREEN: COMMENT 55(20) text-h24 FOR FIELD bysimu
                                           MODIF ID sim.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS:     rr_rfc_1 LIKE rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll     MODIF ID sim
                VISIBLE LENGTH 25.
SELECT-OPTIONS: rr_rol_1 FOR  agr_define-agr_name MODIF ID sim.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS:     rr_rfc_2 LIKE rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll     MODIF ID sim
                VISIBLE LENGTH 25.
SELECT-OPTIONS: rr_rol_2 FOR  agr_define-agr_name MODIF ID sim.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS:     rr_rfc_3 LIKE rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll     MODIF ID sim
                VISIBLE LENGTH 25.
SELECT-OPTIONS: rr_rol_3 FOR  agr_define-agr_name MODIF ID sim.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS:     rr_rfc_4 LIKE rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll     MODIF ID sim
                VISIBLE LENGTH 25.
SELECT-OPTIONS: rr_rol_4 FOR  agr_define-agr_name MODIF ID sim.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK b_sim_del .

SELECTION-SCREEN: END OF BLOCK b_sim .

SELECTION-SCREEN END OF SCREEN 1100.
