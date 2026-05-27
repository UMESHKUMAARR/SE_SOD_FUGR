*&---------------------------------------------------------------------*
*&  Include           ZARP_RES_ACC_PUB_CONFIG_TOP
*&---------------------------------------------------------------------*

CLASS lcl_event_handler DEFINITION DEFERRED.

TYPES : BEGIN OF ty_res_access,
  username TYPE /psyng/sw_cnfacc-username,
  sign TYPE /psyng/sw_cnfacc-sign,
  opton TYPE /psyng/sw_cnfacc-opton,
  sysidlow TYPE /psyng/sw_cnfacc-sysidlow,
  sysidhigh TYPE /psyng/sw_cnfacc-sysidhigh,
  END OF ty_res_access,
  tt_res_access TYPE TABLE OF ty_res_access.

TYPES : BEGIN OF ty_values,
      line(255) TYPE c,
    END OF ty_values,
    tt_values TYPE TABLE OF ty_values,
    tt_dfies TYPE TABLE OF dfies.

DATA : gt_res_access TYPE TABLE OF ty_res_access,
       gs_res_access TYPE ty_res_access,
       ok_code TYPE sy-ucomm,
       g_cust_cont TYPE REF TO cl_gui_custom_container,
       g_alv_grid TYPE REF TO cl_gui_alv_grid,
       gt_fieldcat TYPE lvc_t_fcat,
       gf_dispchg(1) TYPE c,
       gf_sign TYPE flag,
       gr_event_handler TYPE REF TO lcl_event_handler,
       gf_opton TYPE flag,
       gf_sysidlow TYPE flag,
       gf_sysidhigh TYPE flag.

CONSTANTS: gc_display(1) TYPE c VALUE 'D',
           gc_change(1)  TYPE c VALUE 'C'.
