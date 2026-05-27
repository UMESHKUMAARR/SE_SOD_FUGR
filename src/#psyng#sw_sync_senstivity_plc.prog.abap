*&---------------------------------------------------------------------*
*& Report  /PSYNG/SW_SYNC_SENSTIVITY_PLC
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT /psyng/sw_sync_senstivity_plc.

*Import type definitions used for ALV grid
*TYPE-POOLS: lvc.

*Module Pool: Screen related objects
DATA: go_cc      TYPE REF TO cl_gui_custom_container, "UI area
      go_grid    TYPE REF TO cl_gui_alv_grid.

*ALV related objects
DATA: gt_fcat TYPE lvc_t_fcat,
      gs_fcat TYPE lvc_s_fcat,
      gs_layout TYPE lvc_s_layo,
      gt_sens TYPE TABLE OF /psyng/swimpsync,
      gs_sens TYPE /psyng/swimpsync,
      gf_dispchg(1) TYPE c,
      gt_rows TYPE lvc_t_row,
      gs_row  TYPE lvc_s_row.

*Constant objects
CONSTANTS: gc_display(1) TYPE c VALUE 'D',
           gc_change(1)  TYPE c VALUE 'C'.

START-OF-SELECTION.

  AUTHORITY-CHECK OBJECT 'S_PROGRAM'
         ID 'P_GROUP' FIELD 'SW_SE'
         ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) WITH 'execute ' sy-repid.
    EXIT.
  ENDIF.

*--Set change mode to display while opening maintainance screen for the
*--first time
  gf_dispchg = gc_display.
  CALL SCREEN 0001.

  INCLUDE /psyng/sw_sync_senstivity_po01.
