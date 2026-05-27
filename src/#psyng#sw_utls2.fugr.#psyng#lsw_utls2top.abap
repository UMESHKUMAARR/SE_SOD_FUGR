FUNCTION-POOL /PSYNG/SW_UTLS2.              "MESSAGE-ID ..
INCLUDE /PSYNG/SW_CONFIG.
TYPE-POOLS SHLP.
**Global decl for miigation tcodes
DATA: BEGIN OF gt_mctran OCCURS 0,
      TCODE TYPE /psyng/mctran-TCODE,
      frequency TYPE /psyng/mctran-frequency,
      END OF gt_mctran.

**Global decl for miigation reports
DATA: BEGIN OF gt_mcrepid OCCURS 0,
      REPID TYPE /psyng/mcrepid-REPID,
      frequency TYPE /psyng/mcrepid-frequency,
      END OF gt_mcrepid.

**Global decl for miigation Auditors
DATA: BEGIN OF gt_mcauditor OCCURS 0,
      AUDITOR TYPE /PSYNG/MCAUDITOR-AUDITOR,
      END OF gt_mcauditor.

**Global decl for miigation User
DATA: BEGIN OF gt_mcuser OCCURS 0.
        INCLUDE STRUCTURE /psyng/mcuser.
DATA: END OF gt_mcuser.

**Global decl for miigation usergroup
DATA: BEGIN OF gt_mcusrgrp OCCURS 0.
        INCLUDE STRUCTURE /psyng/mcusrgrp.
DATA: END OF gt_mcusrgrp.

**Global decl for miigation texts
DATA: BEGIN OF gt_text OCCURS 0,
        text TYPE /psyng/texts-text,
      END OF gt_text.

**Global decl for miigation usergroup assign flag
DATA: g_assign_flag TYPE /PSYNG/FLAGX.

**Global decl for Workareas for mitigation
DATA: WA_gt_mcauditor LIKE LINE OF  gt_mcauditor,
      WA_gt_mcrepid   LIKE LINE OF  gt_mcrepid,
      WA_gt_mctran    LIKE LINE OF  gt_mctran,
      WA_gt_text      LIKE LINE OF  gt_text.

* Global Declaration for Mitigating table controls

CONTROLS: tc_mctran  TYPE TABLEVIEW USING SCREEN 1001,
          tc_mcrepid TYPE TABLEVIEW USING SCREEN 1001,
          tc_mcauditor TYPE TABLEVIEW USING SCREEN 1001.

* Global declarations for comparing Derived roles with Parent roles
DATA :  lt_ust12_table TYPE TABLE OF        ust12.
TYPES : BEGIN OF type_parent_role ,
          agr_name    TYPE   agr_name,
          ust12       LIKE   lt_ust12_table,
        END OF type_parent_role.

DATA : gt_parent_role TYPE SORTED TABLE OF type_parent_role
                      WITH UNIQUE KEY      agr_name,
       lt_orgfield    TYPE TABLE OF        xufield,
       gt_ust12       TYPE SORTED TABLE OF ust12
                      WITH NON-UNIQUE KEY  auth.
