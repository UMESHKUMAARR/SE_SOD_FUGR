*----------------------------------------------------------------------*
***INCLUDE /PSYNG/Z_AUTO_ORG_PBO .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  display_alv  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module display_alv output.
  SET TITLEBAR  'TITLE_0001'.
  PERFORM display_alv.

endmodule.                 " display_alv  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0001  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module STATUS_0001 output.
DATA: BEGIN OF lt_hidet OCCURS 1,
        FCODE type gui_code,
      END OF lt_hidet.
clear lt_hidet.
refresh : lt_hidet.
if p_upd is initial.
  lt_hidet-fcode = 'PROCESS'.
  append lt_hidet.
endif.
if p_rdupd is initial.
  lt_hidet-fcode = 'RDPROC'.
  append lt_hidet.
endif.
if gf_rd_installed is initial.
  lt_hidet-fcode = 'RDCURRENT'.
  append lt_hidet.
endif.

SET PF-STATUS 'STATUS_0001' excluding lt_hidet.
SET TITLEBAR  'TITLE_0001'.

endmodule.                 " STATUS_0001  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0002  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module STATUS_0002 output.
clear lt_hidet.
refresh : lt_hidet.
if p_upd is initial.
  lt_hidet-fcode = 'PROCESS'.
  append lt_hidet.
  lt_hidet-fcode = 'REFRESH'.
  append lt_hidet.
endif.
if gf_rd_installed is initial.
  lt_hidet-fcode = 'RDCURRENT'.
  append lt_hidet.
endif.
SET PF-STATUS 'STATUS_0001' excluding lt_hidet.
SET TITLEBAR  'TITLE_0001'.

endmodule.                 " STATUS_0002  OUTPUT
