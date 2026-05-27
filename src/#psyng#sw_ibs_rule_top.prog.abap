*&---------------------------------------------------------------------*
*&  Include           /PSYNG/SW_IBS_RULE_TOP
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&  Include           /PSYNG/SW_IBS_GLOBAL_CONSTANTS
*&---------------------------------------------------------------------*
TYPE-POOLS: slis.
*DATA: converter     TYPE REF TO /psyng/cl_sw_ibs_rules_conv, " Class Object
DATA: converter     TYPE REF TO /psyng/cl_sw_ruleset_convsn, " Class Object
      lv_mandt      LIKE sy-mandt,
      lv_vers_exst  TYPE c,
      ls_variant    TYPE disvariant,      " ALV variant
      alv_layout    TYPE slis_layout_alv, " ALV layout
      l_program     LIKE sy-repid.        " ALV callback prgrm

DATA: lv_vrs_desc TYPE /psyng/swsodvers-vdesc.
DATA: gt_log    TYPE STANDARD TABLE OF /psyng/sw_gt_log, " itab for log
      ls_gt_log TYPE /psyng/sw_gt_log.                " wa for log table

DATA: lv_count_error   TYPE /psyng/sw_gt_log-type,
      lv_count_warning TYPE /psyng/sw_gt_log-type.

DATA: lt_fieldcatalog TYPE TABLE OF slis_fieldcat_alv, " itab fieldcat
      ls_fieldcatalog TYPE slis_fieldcat_alv.                " wa fieldcat

DEFINE field_cat.   " fieldcat MACROS

  ls_fieldcatalog-col_pos     = &1.               " column position
  ls_fieldcatalog-fieldname   = &2.
  ls_fieldcatalog-seltext_m   = &3.
  ls_fieldcatalog-seltext_s   = &3.
  ls_fieldcatalog-seltext_l   = &3.
  ls_fieldcatalog-intlen      = &4.
  ls_fieldcatalog-outputlen   = &4.
  ls_fieldcatalog-fix_column  = 'X'.
  ls_fieldcatalog-lzero       = 'X'.

  APPEND ls_fieldcatalog TO lt_fieldcatalog.

  CLEAR ls_fieldcatalog.

END-OF-DEFINITION.
