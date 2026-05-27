*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_SODF01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  refresh_tables
*&---------------------------------------------------------------------*
*       Clear global tables
*----------------------------------------------------------------------*
FORM refresh_tables.
  REFRESH: gt_confdet, gt_functtran, gt_faobj, gt_tcdaut, gt_iduser,
           gt_users, gt_usertcode,  gt_userauth, gt_tcd, gt_cf, gt_ft,
           gt_tobjs1, gt_tobjs3, gt_outputdet, gt_outputdet2,
           gt_outputdet3, gt_confs1, gt_confs2, gt_conflict.
ENDFORM.                    " refresh_tables
