FUNCTION-POOL /psyng/sw_adm MESSAGE-ID /psyng/sw.

INCLUDE /psyng/sw_config.
TYPES : BEGIN OF gs_count,
         vrsio TYPE /psyng/sodvrsio,
         count TYPE /psyng/nr_users,
         END OF gs_count.

DEFINE log.
  &1-type    = &2.
  &1-id      = &3.
  concatenate &4 &5 &6 &7 into &1-message separated by space.
  append &1.
END-OF-DEFINITION.

*--Global data for Copy Matrix Version
  DATA: gt_function  TYPE TABLE OF /psyng/function WITH HEADER LINE,
        gt_functtran TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
        gt_faobj     TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
        gt_conflict  TYPE TABLE OF /psyng/conflict WITH HEADER LINE,
        gt_confdet   TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
        gt_critcodes TYPE TABLE OF /psyng/critcodes WITH HEADER LINE,
        gt_swaudhdr  TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE,
        gt_swaudc    TYPE TABLE OF /psyng/swaudc2 WITH HEADER LINE,
        gt_criroles  TYPE TABLE OF /psyng/criroles WITH HEADER LINE,
        gt_criprof   TYPE TABLE OF /psyng/criprof WITH HEADER LINE,
        gt_texts     TYPE TABLE OF /psyng/texts WITH HEADER LINE,
        gt_cuscon    TYPE TABLE OF /psyng/sw_cuscon WITH HEADER LINE,
        gt_conowner  TYPE TABLE OF /psyng/conowner WITH HEADER LINE,
        gt_confil    TYPE TABLE OF /psyng/sw_syscon WITH HEADER LINE,
        gt_funfil    TYPE TABLE OF /psyng/sw_sysfun WITH HEADER LINE,
        gt_tcodefil  TYPE TABLE OF /psyng/sw_systcd WITH HEADER LINE,
        gt_authfil   TYPE TABLE OF /psyng/sw_sysca WITH HEADER LINE,
        gt_swsodorgo TYPE TABLE OF /psyng/swsodorgo WITH HEADER LINE,
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
        gt_mchdr     TYPE TABLE OF /psyng/mchdr     WITH HEADER LINE,
        gt_mcrvwhdr  TYPE TABLE OF /psyng/mcrvwhdr  WITH HEADER LINE,
        gt_mcuser    TYPE TABLE OF /psyng/mcuser    WITH HEADER LINE,
        gt_mcusrgrp  TYPE TABLE OF /psyng/mcusrgrp  WITH HEADER LINE,
        gt_mcrole    TYPE TABLE OF /psyng/mcrole    WITH HEADER LINE,
        gt_mccarole  TYPE TABLE OF /psyng/mccarole  WITH HEADER LINE,
        gt_mccauser  TYPE TABLE OF /psyng/mccauser  WITH HEADER LINE,
        gt_mctran    TYPE TABLE OF /psyng/mctran    WITH HEADER LINE,
        gt_mcrepid   TYPE TABLE OF /psyng/mcrepid   WITH HEADER LINE,
        gt_mcauditor TYPE TABLE OF /psyng/mcauditor WITH HEADER LINE,
        gt_mctext    TYPE TABLE OF /psyng/mcrvwtxt  WITH HEADER LINE,
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
        gs_swsodvers TYPE /psyng/swsodvers,
        g_set_id     TYPE /psyng/seconfid.

*^^^ ============================================================ ^^^^^^
*    Test Mode: Delete Target
*^^^ ============================================================^^^^^^
DATA: BEGIN OF gt_test_function OCCURS 0,
        funid TYPE /psyng/function-function,
      END OF gt_test_function.
DATA: BEGIN OF gt_test_conflict OCCURS 0,
        conid TYPE /psyng/conflict-conid,
      END OF gt_test_conflict.
DATA:gt_test_swaudhdr TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE,
     gt_test_sw_cuscon  TYPE TABLE OF /psyng/sw_cuscon WITH HEADER LINE,
     gt_test_critcodes TYPE TABLE OF /psyng/critcodes WITH HEADER LINE,
     gt_test_criroles TYPE TABLE OF /psyng/criroles WITH HEADER LINE,
     gt_test_criprof TYPE TABLE OF /psyng/criprof WITH HEADER LINE.
*^^^ ============================================================ ^^^^^^

  DATA: g_svrsio         TYPE /psyng/swsodvers-vrsio,
        g_tvrsio         TYPE /psyng/swsodvers-vrsio,
        g_append_flag    TYPE c,
        g_overwrite_flag TYPE c.
