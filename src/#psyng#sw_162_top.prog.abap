*&---------------------------------------------------------------------*
*&  Include           /PSYNG/SW_162_TOP
*&---------------------------------------------------------------------*

TABLES : /psyng/functtran.
TYPES: BEGIN OF ty_logs,
         sodvers TYPE string,
         table   TYPE string,
         funid   TYPE string,
         tcode   TYPE string,
         field   TYPE string,
         old_val TYPE string,
         new_val TYPE string,
       END OF ty_logs,

       "HBHALLA BOC (12-12-23)
       BEGIN OF ty_faobj2,
         mandt   TYPE /psyng/faobj2-mandt,
         vrsio   TYPE /psyng/faobj2-vrsio,
         funid   TYPE /psyng/faobj2-funid,
         tcode   TYPE /psyng/faobj2-tcode,
       END OF ty_faobj2,
       "END OF CHANGE

       tt_functtran TYPE STANDARD TABLE OF /psyng/functtran,
       tt_logs      TYPE STANDARD TABLE OF ty_logs,  "HBHALLA
       tt_faobj2    TYPE TABLE OF ty_faobj2.

DATA: g_cust_cont         TYPE REF TO cl_gui_custom_container,
      g_alv_grid          TYPE REF TO cl_gui_alv_grid,
      gt_fieldcat         TYPE lvc_t_fcat,
      gt_logs             TYPE TABLE OF ty_logs,     "HBHALLA
      "umittal
      gt_functtran        TYPE STANDARD TABLE OF /psyng/functtran,
      gt_faobj2           TYPE TABLE OF ty_faobj2,   "HBHALLA
      g_total_count       TYPE n LENGTH 6,
      g_count             TYPE n LENGTH 6,
      g_functtran_count   TYPE n LENGTH 6,
      g_faobj2_count      TYPE n LENGTH 6,
      g_mandt             TYPE sy-mandt.
      "umittal
"END OF CHANGE
