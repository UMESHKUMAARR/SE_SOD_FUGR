*&----------------------------------------------------------------------*
*&  Include           /PSYNG/SW_IMPORT_TOP
*&---------------------------------------------------------------------*
DATA: gv_filename   TYPE string,
      gt_import_tab TYPE /psyng/sw_import_t,
      go_import_obj TYPE REF TO /psyng/sw_ruleset_import,
      go_logger_obj TYPE REF TO /psyng/sw_ruleset_logger.
DATA: gt_class_names    TYPE STANDARD TABLE OF seoclsname .
