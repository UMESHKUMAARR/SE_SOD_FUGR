FUNCTION /psyng/sw_cr_add_mit_controls.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IS_MCHDR) LIKE  /PSYNG/MCHDR STRUCTURE  /PSYNG/MCHDR
*"     VALUE(IF_NO_EMAIL) TYPE  FLAG DEFAULT ' '
*"     VALUE(IF_DEL_ASSGN_ONLY) TYPE  FLAG DEFAULT ' '
*"     VALUE(IF_ADD_ASSGN_ONLY) TYPE  FLAG DEFAULT ''
*"     VALUE(FLAG) TYPE  CHAR1 OPTIONAL
*"     VALUE(IS_MCRVWHDR) LIKE  /PSYNG/MCRVWHDR STRUCTURE
*"        /PSYNG/MCRVWHDR OPTIONAL
*"     VALUE(IF_GET_UPDATE) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(EF_MCHDR_ADDED) TYPE  CHAR1
*"     VALUE(EF_MCAUDITOR_ADDED) TYPE  CHAR1
*"     VALUE(EF_MCTRAN_ADDED) TYPE  CHAR1
*"     VALUE(EF_MCREPID_ADDED) TYPE  CHAR1
*"     VALUE(EF_MCUSER_ADDED) TYPE  CHAR1
*"     VALUE(EF_MCUSRGRP_ADDED) TYPE  CHAR1
*"     VALUE(EF_MCCAUSER_ADDED) TYPE  CHAR1
*"     VALUE(EF_MCROLE_ADDED) TYPE  CHAR1
*"     VALUE(EF_MCCAROLE_ADDED) TYPE  CHAR1
*"     VALUE(EF_TEXT_ADDED) TYPE  CHAR1
*"     VALUE(EF_MCRVWHDR_ADDED) TYPE  CHAR1
*"  TABLES
*"      IT_MCAUDITOR STRUCTURE  /PSYNG/MCAUDITOR OPTIONAL
*"      IT_MCTRAN STRUCTURE  /PSYNG/MCTRAN OPTIONAL
*"      IT_MCREPID STRUCTURE  /PSYNG/MCREPID OPTIONAL
*"      IT_MCUSER STRUCTURE  /PSYNG/MCUSER OPTIONAL
*"      IT_MCUSRGRP STRUCTURE  /PSYNG/MCUSRGRP OPTIONAL
*"      IT_MCCAUSER STRUCTURE  /PSYNG/MCCAUSER OPTIONAL
*"      IT_MCCAROLE STRUCTURE  /PSYNG/MCCAROLE OPTIONAL
*"      IT_MCROLE STRUCTURE  /PSYNG/MCROLE OPTIONAL
*"      IT_TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"  EXCEPTIONS
*"      TARGET_NOT_SPECIFIED
*"      NOT_AUTHORIZED
*"      LOCKED
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_ADD_MIT_CONTROLS'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  DATA: l_objid        TYPE cdhdr-objectid,
        l_idx          TYPE sy-tabix,
        ls_mchdr       TYPE /psyng/mchdr,
        ls_mchdr_n     TYPE /psyng/mchdr,
        ls_mchdr_o     TYPE /psyng/mchdr,
        ls_mcauditor_n TYPE /psyng/mcauditor,
        ls_mcauditor_o TYPE /psyng/mcauditor,
        ls_mctran_n    TYPE /psyng/mctran,
        ls_mctran_o    TYPE /psyng/mctran,
        ls_mcrepid_n   TYPE /psyng/mcrepid,
        ls_mcrepid_o   TYPE /psyng/mcrepid,
        ls_mcuser_n    TYPE /psyng/mcuser,
        ls_mcuser_o    TYPE /psyng/mcuser,
        ls_mcusrgrp_n  TYPE /psyng/mcusrgrp,
        ls_mcusrgrp_o  TYPE /psyng/mcusrgrp,
        ls_mccarole_n  TYPE /psyng/mccarole,
        ls_mccarole_o  TYPE /psyng/mccarole,
        ls_mccauser_n  TYPE /psyng/mccauser,
        ls_mccauser_o  TYPE /psyng/mccauser,
        ls_mccauser_temp TYPE /psyng/mccauser,
        ls_mcrole_n    TYPE /psyng/mcrole,
        ls_mcrole_o    TYPE /psyng/mcrole,
        ls_mit_assgn   TYPE /psyng/mitigation_assignment,
        lt_mcauditor   TYPE TABLE OF /psyng/mcauditor WITH HEADER LINE,
        lt_mctran      TYPE TABLE OF /psyng/mctran    WITH HEADER LINE,
        lt_mcrepid     TYPE TABLE OF /psyng/mcrepid   WITH HEADER LINE,
        lt_mcuser      TYPE TABLE OF /psyng/mcuser    WITH HEADER LINE,
        lt_mcusrgrp    TYPE TABLE OF /psyng/mcusrgrp  WITH HEADER LINE,
        lt_mccarole    TYPE TABLE OF /psyng/mccarole  WITH HEADER LINE,
        lt_mccauser    TYPE TABLE OF /psyng/mccauser  WITH HEADER LINE,
   lt_mccauser_temp    TYPE TABLE OF /psyng/mccauser  WITH HEADER LINE,
        lt_mcrole      TYPE TABLE OF /psyng/mcrole    WITH HEADER LINE,
        lt_spras       TYPE TABLE OF spras            WITH HEADER LINE,
        ls_mcrvwhdr    TYPE /psyng/mcrvwhdr,
        ls_mcrvwhdr_o TYPE /psyng/mcrvwhdr,
        ls_mcrvwhdr_n TYPE /psyng/mcrvwhdr.

  DATA: BEGIN OF lt_cdtxt OCCURS 0.
          INCLUDE STRUCTURE cdtxt.
  DATA: END OF lt_cdtxt.

  FIELD-SYMBOLS: <text> TYPE /psyng/texts.
* BOC by RGUPTA on 07.04.22 for C0700
  DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700

  ef_mchdr_added     = 'N'.
  ef_mcauditor_added = 'N'.
  ef_mctran_added    = 'N'.
  ef_mcrepid_added   = 'N'.
  ef_mcuser_added    = 'N'.
  ef_mcusrgrp_added  = 'N'.
  ef_mccauser_added  = 'N'.
  ef_mccarole_added  = 'N'.
  ef_mcrole_added    = 'N'.
  ef_mcrvwhdr_added  = 'N'.

  IF is_mchdr IS INITIAL.
    RAISE target_not_specified.
    "EXIT.
  ENDIF.

*--SF Case 2601 - Change authorization for headers
*only needs to be performed when headers will be changed
  IF if_del_assgn_only IS INITIAL AND
     if_add_assgn_only IS INITIAL.
    AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
             ID 'ACTVT' FIELD '02'
             ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_CNTID' FIELD is_mchdr-contid.
    IF sy-subrc <> 0.
      RAISE not_authorized.
    ENDIF.
  ENDIF.
  l_objid = is_mchdr-contid.


  IF if_del_assgn_only = space.        "Not just deleting assignments
    SELECT SINGLE * INTO ls_mchdr FROM /psyng/mchdr  "#EC CI_SEL_NESTED
                  WHERE contid = is_mchdr-contid.
    IF sy-subrc <> 0.
      INSERT /psyng/mchdr FROM is_mchdr.            "#EC CI_IMUD_NESTED

      IF sy-subrc = 0.
        ef_mchdr_added = 'Y'.

        ls_mchdr_n = is_mchdr.
        CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
             EXPORTING
                  objectid                = l_objid
                  tcode                   = sy-tcode
                  utime                   = sy-uzeit
                  udate                   = sy-datum
                  username                = l_current_user"sy-unameC0700
                  object_change_indicator = 'I'
                  planned_or_real_changes = 'R'
                  n_psyng_mcauditor       = ls_mcauditor_n
                  o_psyng_mcauditor       = ls_mcauditor_o
                  n_psyng_mccarole        = ls_mccarole_n
                  o_psyng_mccarole        = ls_mccarole_o
                  n_psyng_mccauser        = ls_mccauser_n
                  o_psyng_mccauser        = ls_mccauser_o
                  n_psyng_mchdr           = ls_mchdr_n
                  o_psyng_mchdr           = ls_mchdr_o
                  upd_psyng_mchdr         = 'I'
                  n_psyng_mcrepid         = ls_mcrepid_n
                  o_psyng_mcrepid         = ls_mcrepid_o
                  n_psyng_mcrole          = ls_mcrole_n
                  o_psyng_mcrole          = ls_mcrole_o
                  n_psyng_mctran          = ls_mctran_n
                  o_psyng_mctran          = ls_mctran_o
                  n_psyng_mcuser          = ls_mcuser_n
                  o_psyng_mcuser          = ls_mcuser_o
                  n_psyng_mcusrgrp        = ls_mcusrgrp_n
                  o_psyng_mcusrgrp        = ls_mcusrgrp_o
                  n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                  o_psyng_mcrvwhdr        = ls_mcrvwhdr_o
             TABLES
                  icdtxt_mit              = lt_cdtxt.

        CLEAR ls_mchdr_n.
      ENDIF.
    ELSEIF is_mchdr <> ls_mchdr.
      CHECK flag IS INITIAL. "Avoid modify
      MODIFY /psyng/mchdr FROM is_mchdr.            "#EC CI_IMUD_NESTED
      ef_mchdr_added = 'Y'.

      ls_mchdr_n = is_mchdr.
      ls_mchdr_o = ls_mchdr.
      CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user"sy-uname C0700
                object_change_indicator = 'U'
                planned_or_real_changes = 'R'
                n_psyng_mcauditor       = ls_mcauditor_n
                o_psyng_mcauditor       = ls_mcauditor_o
                n_psyng_mccarole        = ls_mccarole_n
                o_psyng_mccarole        = ls_mccarole_o
                n_psyng_mccauser        = ls_mccauser_n
                o_psyng_mccauser        = ls_mccauser_o
                n_psyng_mchdr           = ls_mchdr_n
                o_psyng_mchdr           = ls_mchdr_o
                upd_psyng_mchdr         = 'U'
                n_psyng_mcrepid         = ls_mcrepid_n
                o_psyng_mcrepid         = ls_mcrepid_o
                n_psyng_mcrole          = ls_mcrole_n
                o_psyng_mcrole          = ls_mcrole_o
                n_psyng_mctran          = ls_mctran_n
                o_psyng_mctran          = ls_mctran_o
                n_psyng_mcuser          = ls_mcuser_n
                o_psyng_mcuser          = ls_mcuser_o
                n_psyng_mcusrgrp        = ls_mcusrgrp_n
                o_psyng_mcusrgrp        = ls_mcusrgrp_o
                n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                o_psyng_mcrvwhdr        = ls_mcrvwhdr_o
           TABLES
                icdtxt_mit              = lt_cdtxt.

      CLEAR: ls_mchdr_n, ls_mchdr_o.
    ENDIF.

    CHECK flag IS INITIAL. "Avoid modify

*  Review header
    IF is_mcrvwhdr IS NOT INITIAL. "RGUPTA on 28.06.22
      SELECT SINGLE * INTO ls_mcrvwhdr FROM
                   /psyng/mcrvwhdr                   "#EC CI_SEL_NESTED
                      WHERE contid = is_mchdr-contid.
      IF sy-subrc <> 0.
*--This is a new record, set the default review text
        IF is_mcrvwhdr-dflt_review IS INITIAL.
*--Set the default review text if it wasn't set
          se_config_param 'MIT_DFLT_REV_TEXT' is_mcrvwhdr-dflt_review.
        ENDIF.

        INSERT /psyng/mcrvwhdr FROM is_mcrvwhdr.    "#EC CI_IMUD_NESTED

        IF sy-subrc = 0.
          ef_mcrvwhdr_added = 'Y'.

          ls_mcrvwhdr_n = is_mcrvwhdr.
          CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
               EXPORTING
                    objectid                = l_objid
                    tcode                   = sy-tcode
                    utime                   = sy-uzeit
                    udate                   = sy-datum
                  username                = l_current_user"sy-unameC0700
                  object_change_indicator = 'I'
                  planned_or_real_changes = 'R'
                  n_psyng_mcauditor       = ls_mcauditor_n
                  o_psyng_mcauditor       = ls_mcauditor_o
                  n_psyng_mccarole        = ls_mccarole_n
                  o_psyng_mccarole        = ls_mccarole_o
                  n_psyng_mccauser        = ls_mccauser_n
                  o_psyng_mccauser        = ls_mccauser_o
                  n_psyng_mchdr           = ls_mchdr_n
                  o_psyng_mchdr           = ls_mchdr_o
                  n_psyng_mcrepid         = ls_mcrepid_n
                  o_psyng_mcrepid         = ls_mcrepid_o
                  n_psyng_mcrole          = ls_mcrole_n
                  o_psyng_mcrole          = ls_mcrole_o
                  n_psyng_mctran          = ls_mctran_n
                  o_psyng_mctran          = ls_mctran_o
                  n_psyng_mcuser          = ls_mcuser_n
                  o_psyng_mcuser          = ls_mcuser_o
                  n_psyng_mcusrgrp        = ls_mcusrgrp_n
                  o_psyng_mcusrgrp        = ls_mcusrgrp_o
                  n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                  o_psyng_mcrvwhdr        = ls_mcrvwhdr_o
                  upd_psyng_mcrvwhdr      = 'I'
             TABLES
                  icdtxt_mit              = lt_cdtxt.

          CLEAR ls_mcrvwhdr_n.
        ENDIF.
      ELSEIF is_mcrvwhdr <> ls_mcrvwhdr.
        CHECK flag IS INITIAL. "Avoid modify
     MODIFY /psyng/mcrvwhdr FROM is_mcrvwhdr.       "#EC CI_IMUD_NESTED
        ef_mcrvwhdr_added = 'Y'.

        ls_mcrvwhdr_n = is_mcrvwhdr.
        ls_mcrvwhdr_o = ls_mcrvwhdr.

        CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
             EXPORTING
                  objectid                = l_objid
                  tcode                   = sy-tcode
                  utime                   = sy-uzeit
                  udate                   = sy-datum
                 username                = l_current_user"sy-uname C0700
                 object_change_indicator = 'U'
                 planned_or_real_changes = 'R'
                 n_psyng_mcauditor       = ls_mcauditor_n
                 o_psyng_mcauditor       = ls_mcauditor_o
                 n_psyng_mccarole        = ls_mccarole_n
                 o_psyng_mccarole        = ls_mccarole_o
                 n_psyng_mccauser        = ls_mccauser_n
                 o_psyng_mccauser        = ls_mccauser_o
                 n_psyng_mchdr           = ls_mchdr_n
                 o_psyng_mchdr           = ls_mchdr_o
                 n_psyng_mcrepid         = ls_mcrepid_n
                 o_psyng_mcrepid         = ls_mcrepid_o
                 n_psyng_mcrole          = ls_mcrole_n
                 o_psyng_mcrole          = ls_mcrole_o
                 n_psyng_mctran          = ls_mctran_n
                 o_psyng_mctran          = ls_mctran_o
                 n_psyng_mcuser          = ls_mcuser_n
                 o_psyng_mcuser          = ls_mcuser_o
                 n_psyng_mcusrgrp        = ls_mcusrgrp_n
                 o_psyng_mcusrgrp        = ls_mcusrgrp_o
                 n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                 o_psyng_mcrvwhdr        = ls_mcrvwhdr_o
                 upd_psyng_mcrvwhdr      = 'U'
            TABLES
                 icdtxt_mit              = lt_cdtxt.

        CLEAR: ls_mcrvwhdr_n, ls_mcrvwhdr_o.
      ENDIF.
    ENDIF.
*   Auditors
    IF it_mcauditor IS REQUESTED.
      SELECT * INTO TABLE lt_mcauditor               "#EC CI_SEL_NESTED
             FROM /psyng/mcauditor
                WHERE contid = is_mchdr-contid.

      LOOP AT lt_mcauditor INTO ls_mcauditor_o.
        READ TABLE it_mcauditor WITH KEY contid = ls_mcauditor_o-contid
                                       auditor = ls_mcauditor_o-auditor
                                       company = ls_mcauditor_o-company.
        IF sy-subrc <> 0.
*         Delete auditors that no longer exist
          DELETE FROM /psyng/mcauditor              "#EC CI_IMUD_NESTED
                          WHERE contid  = ls_mcauditor_o-contid
                            AND auditor = ls_mcauditor_o-auditor
                            AND company = ls_mcauditor_o-company.
          IF sy-subrc = 0.
            CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
                 EXPORTING
                      objectid                = l_objid
                      tcode                   = sy-tcode
                      utime                   = sy-uzeit
                      udate                   = sy-datum
                      username                = l_current_user " C0700
                      object_change_indicator = 'D'
                      planned_or_real_changes = 'R'
                      n_psyng_mcauditor       = ls_mcauditor_n
                      o_psyng_mcauditor       = ls_mcauditor_o
                      upd_psyng_mcauditor     = 'D'
                      n_psyng_mccarole        = ls_mccarole_n
                      o_psyng_mccarole        = ls_mccarole_o
                      n_psyng_mccauser        = ls_mccauser_n
                      o_psyng_mccauser        = ls_mccauser_o
                      n_psyng_mchdr           = ls_mchdr_n
                      o_psyng_mchdr           = ls_mchdr_o
                      n_psyng_mcrepid         = ls_mcrepid_n
                      o_psyng_mcrepid         = ls_mcrepid_o
                      n_psyng_mcrole          = ls_mcrole_n
                      o_psyng_mcrole          = ls_mcrole_o
                      n_psyng_mctran          = ls_mctran_n
                      o_psyng_mctran          = ls_mctran_o
                      n_psyng_mcuser          = ls_mcuser_n
                      o_psyng_mcuser          = ls_mcuser_o
                      n_psyng_mcusrgrp        = ls_mcusrgrp_n
                      o_psyng_mcusrgrp        = ls_mcusrgrp_o
                      n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                      o_psyng_mcrvwhdr        = ls_mcrvwhdr_o
                 TABLES
                      icdtxt_mit              = lt_cdtxt.

            CLEAR ls_mcauditor_o.
          ENDIF.

*       Edit existing auditor
        ELSEIF ls_mcauditor_o <> it_mcauditor.
          MODIFY /psyng/mcauditor FROM it_mcauditor. "#EC CI_IMUD_NESTED


          IF sy-subrc = 0.
            ef_mcauditor_added = 'Y'.
            ls_mcauditor_n = it_mcauditor.

            CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
                 EXPORTING
                      objectid                = l_objid
                      tcode                   = sy-tcode
                      utime                   = sy-uzeit
                      udate                   = sy-datum
                      username                = l_current_user " C0700
                      object_change_indicator = 'U'
                      planned_or_real_changes = 'R'
                      n_psyng_mcauditor       = ls_mcauditor_n
                      o_psyng_mcauditor       = ls_mcauditor_o
                      upd_psyng_mcauditor     = 'U'
                      n_psyng_mccarole        = ls_mccarole_n
                      o_psyng_mccarole        = ls_mccarole_o
                      n_psyng_mccauser        = ls_mccauser_n
                      o_psyng_mccauser        = ls_mccauser_o
                      n_psyng_mchdr           = ls_mchdr_n
                      o_psyng_mchdr           = ls_mchdr_o
                      n_psyng_mcrepid         = ls_mcrepid_n
                      o_psyng_mcrepid         = ls_mcrepid_o
                      n_psyng_mcrole          = ls_mcrole_n
                      o_psyng_mcrole          = ls_mcrole_o
                      n_psyng_mctran          = ls_mctran_n
                      o_psyng_mctran          = ls_mctran_o
                      n_psyng_mcuser          = ls_mcuser_n
                      o_psyng_mcuser          = ls_mcuser_o
                      n_psyng_mcusrgrp        = ls_mcusrgrp_n
                      o_psyng_mcusrgrp        = ls_mcusrgrp_o
                      n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                      o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

                 TABLES
                      icdtxt_mit              = lt_cdtxt.

            CLEAR: ls_mcauditor_n, ls_mcauditor_o.
          ENDIF.
        ENDIF.
      ENDLOOP.

*     Add new auditors
      LOOP AT it_mcauditor INTO ls_mcauditor_n.
        READ TABLE lt_mcauditor WITH KEY contid = ls_mcauditor_n-contid
                                       auditor = ls_mcauditor_n-auditor
                                       company = ls_mcauditor_n-company.
        CHECK sy-subrc <> 0.

        INSERT /psyng/mcauditor FROM ls_mcauditor_n. "#EC CI_IMUD_NESTED

        IF sy-subrc = 0.
          ef_mcauditor_added = 'Y'.

          CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
               EXPORTING
                    objectid                = l_objid
                    tcode                   = sy-tcode
                    utime                   = sy-uzeit
                    udate                   = sy-datum
                    username                = l_current_user " C0700
                    object_change_indicator = 'I'
                    planned_or_real_changes = 'R'
                    n_psyng_mcauditor       = ls_mcauditor_n
                    o_psyng_mcauditor       = ls_mcauditor_o
                    upd_psyng_mcauditor     = 'I'
                    n_psyng_mccarole        = ls_mccarole_n
                    o_psyng_mccarole        = ls_mccarole_o
                    n_psyng_mccauser        = ls_mccauser_n
                    o_psyng_mccauser        = ls_mccauser_o
                    n_psyng_mchdr           = ls_mchdr_n
                    o_psyng_mchdr           = ls_mchdr_o
                    n_psyng_mcrepid         = ls_mcrepid_n
                    o_psyng_mcrepid         = ls_mcrepid_o
                    n_psyng_mcrole          = ls_mcrole_n
                    o_psyng_mcrole          = ls_mcrole_o
                    n_psyng_mctran          = ls_mctran_n
                    o_psyng_mctran          = ls_mctran_o
                    n_psyng_mcuser          = ls_mcuser_n
                    o_psyng_mcuser          = ls_mcuser_o
                    n_psyng_mcusrgrp        = ls_mcusrgrp_n
                    o_psyng_mcusrgrp        = ls_mcusrgrp_o
                    n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                    o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

               TABLES
                    icdtxt_mit              = lt_cdtxt.

          CLEAR ls_mcauditor_n.
        ENDIF.
      ENDLOOP.
    ENDIF.

*   Transactions
    IF it_mctran IS REQUESTED.
      SELECT * INTO TABLE lt_mctran                  "#EC CI_SEL_NESTED
             FROM /psyng/mctran
                WHERE contid = is_mchdr-contid.

      LOOP AT lt_mctran INTO ls_mctran_o.
        READ TABLE it_mctran WITH KEY contid = ls_mctran_o-contid
                                      tcode  = ls_mctran_o-tcode.
        IF sy-subrc <> 0.
*         Delete TCodes that no longer exist
          DELETE FROM /psyng/mctran                 "#EC CI_IMUD_NESTED
                     WHERE contid = ls_mctran_o-contid
                       AND tcode  = ls_mctran_o-tcode.
          IF sy-subrc = 0.
            CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
                 EXPORTING
                      objectid                = l_objid
                      tcode                   = sy-tcode
                      utime                   = sy-uzeit
                      udate                   = sy-datum
                      username                = l_current_user " C0700
                      object_change_indicator = 'D'
                      planned_or_real_changes = 'R'
                      n_psyng_mcauditor       = ls_mcauditor_n
                      o_psyng_mcauditor       = ls_mcauditor_o
                      n_psyng_mccarole        = ls_mccarole_n
                      o_psyng_mccarole        = ls_mccarole_o
                      n_psyng_mccauser        = ls_mccauser_n
                      o_psyng_mccauser        = ls_mccauser_o
                      n_psyng_mchdr           = ls_mchdr_n
                      o_psyng_mchdr           = ls_mchdr_o
                      n_psyng_mcrepid         = ls_mcrepid_n
                      o_psyng_mcrepid         = ls_mcrepid_o
                      n_psyng_mcrole          = ls_mcrole_n
                      o_psyng_mcrole          = ls_mcrole_o
                      n_psyng_mctran          = ls_mctran_n
                      o_psyng_mctran          = ls_mctran_o
                      upd_psyng_mctran        = 'D'
                      n_psyng_mcuser          = ls_mcuser_n
                      o_psyng_mcuser          = ls_mcuser_o
                      n_psyng_mcusrgrp        = ls_mcusrgrp_n
                      o_psyng_mcusrgrp        = ls_mcusrgrp_o
                      n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                      o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

                 TABLES
                      icdtxt_mit              = lt_cdtxt.

            CLEAR ls_mctran_o.
          ENDIF.

*       Edit existing TCode
        ELSEIF ls_mctran_o <> it_mctran.
          MODIFY /psyng/mctran FROM it_mctran.      "#EC CI_IMUD_NESTED

          IF sy-subrc = 0.
            ef_mctran_added = 'Y'.
            ls_mctran_n = it_mctran.

            CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
                 EXPORTING
                      objectid                = l_objid
                      tcode                   = sy-tcode
                      utime                   = sy-uzeit
                      udate                   = sy-datum
                      username                = l_current_user " C0700
                      object_change_indicator = 'U'
                      planned_or_real_changes = 'R'
                      n_psyng_mcauditor       = ls_mcauditor_n
                      o_psyng_mcauditor       = ls_mcauditor_o
                      n_psyng_mccarole        = ls_mccarole_n
                      o_psyng_mccarole        = ls_mccarole_o
                      n_psyng_mccauser        = ls_mccauser_n
                      o_psyng_mccauser        = ls_mccauser_o
                      n_psyng_mchdr           = ls_mchdr_n
                      o_psyng_mchdr           = ls_mchdr_o
                      n_psyng_mcrepid         = ls_mcrepid_n
                      o_psyng_mcrepid         = ls_mcrepid_o
                      n_psyng_mcrole          = ls_mcrole_n
                      o_psyng_mcrole          = ls_mcrole_o
                      n_psyng_mctran          = ls_mctran_n
                      o_psyng_mctran          = ls_mctran_o
                      upd_psyng_mctran        = 'U'
                      n_psyng_mcuser          = ls_mcuser_n
                      o_psyng_mcuser          = ls_mcuser_o
                      n_psyng_mcusrgrp        = ls_mcusrgrp_n
                      o_psyng_mcusrgrp        = ls_mcusrgrp_o
                      n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                      o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

                 TABLES
                      icdtxt_mit              = lt_cdtxt.

            CLEAR: ls_mctran_n, ls_mctran_o.
          ENDIF.
        ENDIF.
      ENDLOOP.

*     Add new TCodes
      LOOP AT it_mctran INTO ls_mctran_n.
        READ TABLE lt_mctran WITH KEY contid = ls_mctran_n-contid
                                      tcode  = ls_mctran_n-tcode.
        CHECK sy-subrc <> 0.

        INSERT /psyng/mctran FROM ls_mctran_n.      "#EC CI_IMUD_NESTED
        IF sy-subrc = 0.
          ef_mctran_added = 'Y'.

          CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
               EXPORTING
                    objectid                = l_objid
                    tcode                   = sy-tcode
                    utime                   = sy-uzeit
                    udate                   = sy-datum
                    username                = l_current_user " C0700
                    object_change_indicator = 'I'
                    planned_or_real_changes = 'R'
                    n_psyng_mcauditor       = ls_mcauditor_n
                    o_psyng_mcauditor       = ls_mcauditor_o
                    n_psyng_mccarole        = ls_mccarole_n
                    o_psyng_mccarole        = ls_mccarole_o
                    n_psyng_mccauser        = ls_mccauser_n
                    o_psyng_mccauser        = ls_mccauser_o
                    n_psyng_mchdr           = ls_mchdr_n
                    o_psyng_mchdr           = ls_mchdr_o
                    n_psyng_mcrepid         = ls_mcrepid_n
                    o_psyng_mcrepid         = ls_mcrepid_o
                    n_psyng_mcrole          = ls_mcrole_n
                    o_psyng_mcrole          = ls_mcrole_o
                    n_psyng_mctran          = ls_mctran_n
                    o_psyng_mctran          = ls_mctran_o
                    upd_psyng_mctran        = 'I'
                    n_psyng_mcuser          = ls_mcuser_n
                    o_psyng_mcuser          = ls_mcuser_o
                    n_psyng_mcusrgrp        = ls_mcusrgrp_n
                    o_psyng_mcusrgrp        = ls_mcusrgrp_o
                    n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                    o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

               TABLES
                    icdtxt_mit              = lt_cdtxt.

          CLEAR ls_mctran_n.
        ENDIF.
      ENDLOOP.
    ENDIF.

*   Reports
    IF it_mcrepid IS REQUESTED.
      SELECT * INTO TABLE lt_mcrepid                 "#EC CI_SEL_NESTED
           FROM /psyng/mcrepid
                WHERE contid = is_mchdr-contid.

      LOOP AT lt_mcrepid INTO ls_mcrepid_o.
        READ TABLE it_mcrepid WITH KEY contid = ls_mcrepid_o-contid
                                       repid  = ls_mcrepid_o-repid.
        IF sy-subrc <> 0.
*         Delete Reports that no longer exist
          DELETE FROM /psyng/mcrepid                "#EC CI_IMUD_NESTED
                        WHERE contid = ls_mcrepid_o-contid
                          AND repid  = ls_mcrepid_o-repid.
          IF sy-subrc = 0.
            CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
                 EXPORTING
                      objectid                = l_objid
                      tcode                   = sy-tcode
                      utime                   = sy-uzeit
                      udate                   = sy-datum
                      username                = l_current_user " C0700
                      object_change_indicator = 'D'
                      planned_or_real_changes = 'R'
                      n_psyng_mcauditor       = ls_mcauditor_n
                      o_psyng_mcauditor       = ls_mcauditor_o
                      n_psyng_mccarole        = ls_mccarole_n
                      o_psyng_mccarole        = ls_mccarole_o
                      n_psyng_mccauser        = ls_mccauser_n
                      o_psyng_mccauser        = ls_mccauser_o
                      n_psyng_mchdr           = ls_mchdr_n
                      o_psyng_mchdr           = ls_mchdr_o
                      n_psyng_mcrepid         = ls_mcrepid_n
                      o_psyng_mcrepid         = ls_mcrepid_o
                      upd_psyng_mcrepid       = 'D'
                      n_psyng_mcrole          = ls_mcrole_n
                      o_psyng_mcrole          = ls_mcrole_o
                      n_psyng_mctran          = ls_mctran_n
                      o_psyng_mctran          = ls_mctran_o
                      n_psyng_mcuser          = ls_mcuser_n
                      o_psyng_mcuser          = ls_mcuser_o
                      n_psyng_mcusrgrp        = ls_mcusrgrp_n
                      o_psyng_mcusrgrp        = ls_mcusrgrp_o
                      n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                      o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

                 TABLES
                      icdtxt_mit              = lt_cdtxt.

            CLEAR ls_mcrepid_o.
          ENDIF.

*       Edit existing report
        ELSEIF ls_mcrepid_o <> it_mcrepid.
          MODIFY /psyng/mcrepid FROM it_mcrepid.    "#EC CI_IMUD_NESTED

          IF sy-subrc = 0.
            ef_mcrepid_added = 'Y'.
            ls_mcrepid_n = it_mcrepid.

            CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
                 EXPORTING
                      objectid                = l_objid
                      tcode                   = sy-tcode
                      utime                   = sy-uzeit
                      udate                   = sy-datum
                      username                = l_current_user " C0700
                      object_change_indicator = 'U'
                      planned_or_real_changes = 'R'
                      n_psyng_mcauditor       = ls_mcauditor_n
                      o_psyng_mcauditor       = ls_mcauditor_o
                      n_psyng_mccarole        = ls_mccarole_n
                      o_psyng_mccarole        = ls_mccarole_o
                      n_psyng_mccauser        = ls_mccauser_n
                      o_psyng_mccauser        = ls_mccauser_o
                      n_psyng_mchdr           = ls_mchdr_n
                      o_psyng_mchdr           = ls_mchdr_o
                      n_psyng_mcrepid         = ls_mcrepid_n
                      o_psyng_mcrepid         = ls_mcrepid_o
                      upd_psyng_mcrepid       = 'U'
                      n_psyng_mcrole          = ls_mcrole_n
                      o_psyng_mcrole          = ls_mcrole_o
                      n_psyng_mctran          = ls_mctran_n
                      o_psyng_mctran          = ls_mctran_o
                      n_psyng_mcuser          = ls_mcuser_n
                      o_psyng_mcuser          = ls_mcuser_o
                      n_psyng_mcusrgrp        = ls_mcusrgrp_n
                      o_psyng_mcusrgrp        = ls_mcusrgrp_o
                      n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                      o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

                 TABLES
                      icdtxt_mit              = lt_cdtxt.

            CLEAR: ls_mcrepid_n, ls_mcrepid_o.
          ENDIF.
        ENDIF.
      ENDLOOP.

*     Add new reports
      LOOP AT it_mcrepid INTO ls_mcrepid_n.
        READ TABLE lt_mcrepid WITH KEY contid = ls_mcrepid_n-contid
                                       repid  = ls_mcrepid_n-repid.
        CHECK sy-subrc <> 0.

        INSERT /psyng/mcrepid FROM ls_mcrepid_n.    "#EC CI_IMUD_NESTED
        IF sy-subrc = 0.
          ef_mcrepid_added = 'Y'.

          CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
               EXPORTING
                    objectid                = l_objid
                    tcode                   = sy-tcode
                    utime                   = sy-uzeit
                    udate                   = sy-datum
                    username                = l_current_user " C0700
                    object_change_indicator = 'I'
                    planned_or_real_changes = 'R'
                    n_psyng_mcauditor       = ls_mcauditor_n
                    o_psyng_mcauditor       = ls_mcauditor_o
                    n_psyng_mccarole        = ls_mccarole_n
                    o_psyng_mccarole        = ls_mccarole_o
                    n_psyng_mccauser        = ls_mccauser_n
                    o_psyng_mccauser        = ls_mccauser_o
                    n_psyng_mchdr           = ls_mchdr_n
                    o_psyng_mchdr           = ls_mchdr_o
                    n_psyng_mcrepid         = ls_mcrepid_n
                    o_psyng_mcrepid         = ls_mcrepid_o
                    upd_psyng_mcrepid       = 'I'
                    n_psyng_mcrole          = ls_mcrole_n
                    o_psyng_mcrole          = ls_mcrole_o
                    n_psyng_mctran          = ls_mctran_n
                    o_psyng_mctran          = ls_mctran_o
                    n_psyng_mcuser          = ls_mcuser_n
                    o_psyng_mcuser          = ls_mcuser_o
                    n_psyng_mcusrgrp        = ls_mcusrgrp_n
                    o_psyng_mcusrgrp        = ls_mcusrgrp_o
                    n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                    o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

               TABLES
                    icdtxt_mit              = lt_cdtxt.

          CLEAR ls_mcrepid_n.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.                               "Not just deleting assignments

* User assignments
  IF it_mcuser IS REQUESTED.
    IF if_del_assgn_only = space.
*BOC BNAYAK 04/09/2025 PN-15236
* Show Expired Mititgation ID's in Process Auditor(PA)
      IF  if_get_update EQ 'X'.
        SELECT *
          INTO TABLE lt_mcuser                       "#EC CI_SEL_NESTED
          FROM /psyng/mcuser
          WHERE contid = is_mchdr-contid AND
                to_date GT sy-datum.
      ELSE.
        SELECT *
           INTO TABLE lt_mcuser                      "#EC CI_SEL_NESTED
           FROM /psyng/mcuser
           WHERE contid = is_mchdr-contid.
      ENDIF.
*EOC BNAYAK  04/09/2025 PN-15236
    ELSE.
      lt_mcuser[] = it_mcuser[].
      REFRESH it_mcuser.
    ENDIF.

    LOOP AT lt_mcuser INTO ls_mcuser_o.
      READ TABLE it_mcuser WITH KEY contid  = ls_mcuser_o-contid
                                    conid   = ls_mcuser_o-conid
                                    userid  = ls_mcuser_o-userid
                                    vrsio   = ls_mcuser_o-vrsio
                                    org_abb = ls_mcuser_o-org_abb.
      IF sy-subrc <> 0.
        IF if_add_assgn_only = space.
*       Delete user assignments that no longer exist
          DELETE FROM /psyng/mcuser                 "#EC CI_IMUD_NESTED
                    WHERE contid  = ls_mcuser_o-contid
                      AND conid   = ls_mcuser_o-conid
                      AND userid  = ls_mcuser_o-userid
                      AND vrsio   = ls_mcuser_o-vrsio
                      AND org_abb = ls_mcuser_o-org_abb.
          IF sy-subrc = 0.
            CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
                 EXPORTING
                      objectid                = l_objid
                      tcode                   = sy-tcode
                      utime                   = sy-uzeit
                      udate                   = sy-datum
                      username                = l_current_user " C0700
                      object_change_indicator = 'D'
                      planned_or_real_changes = 'R'
                      n_psyng_mcauditor       = ls_mcauditor_n
                      o_psyng_mcauditor       = ls_mcauditor_o
                      n_psyng_mccarole        = ls_mccarole_n
                      o_psyng_mccarole        = ls_mccarole_o
                      n_psyng_mccauser        = ls_mccauser_n
                      o_psyng_mccauser        = ls_mccauser_o
                      n_psyng_mchdr           = ls_mchdr_n
                      o_psyng_mchdr           = ls_mchdr_o
                      n_psyng_mcrepid         = ls_mcrepid_n
                      o_psyng_mcrepid         = ls_mcrepid_o
                      n_psyng_mcrole          = ls_mcrole_n
                      o_psyng_mcrole          = ls_mcrole_o
                      n_psyng_mctran          = ls_mctran_n
                      o_psyng_mctran          = ls_mctran_o
                      n_psyng_mcuser          = ls_mcuser_n
                      o_psyng_mcuser          = ls_mcuser_o
                      upd_psyng_mcuser        = 'D'
                      n_psyng_mcusrgrp        = ls_mcusrgrp_n
                      o_psyng_mcusrgrp        = ls_mcusrgrp_o
                      n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                      o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

                 TABLES
                      icdtxt_mit              = lt_cdtxt.

            CLEAR ls_mcuser_o.
          ENDIF.
        ENDIF.
*     Edit existing user assignment
      ELSEIF ls_mcuser_o <> it_mcuser
      AND NOT it_mcuser IS INITIAL .

*BOC BNAYAK 04/09/2025 PN-15236
        IF if_get_update EQ 'X'.
         DELETE /psyng/mcuser FROM ls_mcuser_o.  "#EC CI_IMUD_NESTED
        ELSE.
         DELETE FROM /psyng/mcuser                  "#EC CI_IMUD_NESTED
               WHERE contid = is_mchdr-contid
*       DHORIONS : auditor is a field that can
*                  change, so shouldn't be taken into account here
*                               AND   auditor = it_mcuser-auditor
                                   AND userid  = it_mcuser-userid
                                   AND conid   = it_mcuser-conid
                                   AND vrsio   = it_mcuser-vrsio
                                   AND org_abb = it_mcuser-org_abb.
        ENDIF.
*EOC BNAYAK 04/09/2025 PN-15236
        IF sy-subrc = 0.
          MODIFY /psyng/mcuser FROM it_mcuser.      "#EC CI_IMUD_NESTED
        ENDIF.

      IF sy-subrc = 0.
        ef_mcuser_added = 'Y'.
        ls_mcuser_n = it_mcuser.

        CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
             EXPORTING
                  objectid                = l_objid
                  tcode                   = sy-tcode
                  utime                   = sy-uzeit
                  udate                   = sy-datum
                  username                = l_current_user  " C0700
                  object_change_indicator = 'U'
                  planned_or_real_changes = 'R'
                  n_psyng_mcauditor       = ls_mcauditor_n
                  o_psyng_mcauditor       = ls_mcauditor_o
                  n_psyng_mccarole        = ls_mccarole_n
                  o_psyng_mccarole        = ls_mccarole_o
                  n_psyng_mccauser        = ls_mccauser_n
                  o_psyng_mccauser        = ls_mccauser_o
                  n_psyng_mchdr           = ls_mchdr_n
                  o_psyng_mchdr           = ls_mchdr_o
                  n_psyng_mcrepid         = ls_mcrepid_n
                  o_psyng_mcrepid         = ls_mcrepid_o
                  n_psyng_mcrole          = ls_mcrole_n
                  o_psyng_mcrole          = ls_mcrole_o
                  n_psyng_mctran          = ls_mctran_n
                  o_psyng_mctran          = ls_mctran_o
                  n_psyng_mcuser          = ls_mcuser_n
                  o_psyng_mcuser          = ls_mcuser_o
                  upd_psyng_mcuser        = 'U'
                  n_psyng_mcusrgrp        = ls_mcusrgrp_n
                  o_psyng_mcusrgrp        = ls_mcusrgrp_o
                  n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                  o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

             TABLES
                  icdtxt_mit              = lt_cdtxt.

*         Send email to appropriate auditor(s)
        IF NOT if_no_email = 'X'.
          MOVE-CORRESPONDING ls_mcuser_n TO ls_mit_assgn.
          ls_mit_assgn-type = '1'.             "User
          CALL FUNCTION '/PSYNG/SW_078'
               EXPORTING
                    is_mit_assgn = ls_mit_assgn.
*                      i_single_recip = ls_mcuser_n-auditor.
        ENDIF.

        CLEAR: ls_mcuser_n, ls_mcuser_o.
      ENDIF.
    ENDIF.
  ENDLOOP.

*   Add new user assignments
  LOOP AT it_mcuser INTO ls_mcuser_n.
    READ TABLE lt_mcuser WITH KEY contid  = ls_mcuser_n-contid
                                  conid   = ls_mcuser_n-conid
                                  userid  = ls_mcuser_n-userid
                                  vrsio   = ls_mcuser_n-vrsio
                                  org_abb = ls_mcuser_n-org_abb .
    CHECK sy-subrc <> 0.

    INSERT /psyng/mcuser FROM ls_mcuser_n.          "#EC CI_IMUD_NESTED
    IF sy-subrc = 0.
      ef_mcuser_added = 'Y'.

      CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user    " C0700
                object_change_indicator = 'I'
                planned_or_real_changes = 'R'
                n_psyng_mcauditor       = ls_mcauditor_n
                o_psyng_mcauditor       = ls_mcauditor_o
                n_psyng_mccarole        = ls_mccarole_n
                o_psyng_mccarole        = ls_mccarole_o
                n_psyng_mccauser        = ls_mccauser_n
                o_psyng_mccauser        = ls_mccauser_o
                n_psyng_mchdr           = ls_mchdr_n
                o_psyng_mchdr           = ls_mchdr_o
                n_psyng_mcrepid         = ls_mcrepid_n
                o_psyng_mcrepid         = ls_mcrepid_o
                n_psyng_mcrole          = ls_mcrole_n
                o_psyng_mcrole          = ls_mcrole_o
                n_psyng_mctran          = ls_mctran_n
                o_psyng_mctran          = ls_mctran_o
                n_psyng_mcuser          = ls_mcuser_n
                o_psyng_mcuser          = ls_mcuser_o
                upd_psyng_mcuser        = 'I'
                n_psyng_mcusrgrp        = ls_mcusrgrp_n
                o_psyng_mcusrgrp        = ls_mcusrgrp_o
                n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

           TABLES
                icdtxt_mit              = lt_cdtxt.

*       Send email to appropriate auditor(s)
      IF NOT if_no_email = 'X'.
        MOVE-CORRESPONDING ls_mcuser_n TO ls_mit_assgn.
        ls_mit_assgn-type = '1'.               "User
        CALL FUNCTION '/PSYNG/SW_078'
             EXPORTING
                  is_mit_assgn = ls_mit_assgn.
      ENDIF.

      CLEAR ls_mcuser_n.
    ENDIF.
  ENDLOOP.

  IF if_del_assgn_only = 'X'.
    it_mcuser[] = lt_mcuser[].
  ENDIF.
ENDIF.

* User group assignments
IF it_mcusrgrp IS REQUESTED.
  IF if_del_assgn_only = space.
    SELECT * INTO TABLE lt_mcusrgrp                  "#EC CI_SEL_NESTED
           FROM /psyng/mcusrgrp
              WHERE contid = is_mchdr-contid.
    ELSE.
      lt_mcusrgrp[] = it_mcusrgrp[].
      REFRESH it_mcusrgrp.
    ENDIF.

    LOOP AT lt_mcusrgrp INTO ls_mcusrgrp_o.
      READ TABLE it_mcusrgrp WITH KEY contid = ls_mcusrgrp_o-contid
                                      conid  = ls_mcusrgrp_o-conid
                                      class  = ls_mcusrgrp_o-class
                                      vrsio  = ls_mcusrgrp_o-vrsio.
      IF sy-subrc <> 0 AND if_add_assgn_only = space.
*       Delete user group assignments that no longer exist
        DELETE FROM /psyng/mcusrgrp                 "#EC CI_IMUD_NESTED
                       WHERE contid = ls_mcusrgrp_o-contid
                         AND conid  = ls_mcusrgrp_o-conid
                         AND class  = ls_mcusrgrp_o-class
                         AND vrsio  = ls_mcusrgrp_o-vrsio.
        IF sy-subrc = 0.
          CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
               EXPORTING
                    objectid                = l_objid
                    tcode                   = sy-tcode
                    utime                   = sy-uzeit
                    udate                   = sy-datum
                    username                = l_current_user " C0700
                    object_change_indicator = 'D'
                    planned_or_real_changes = 'R'
                    n_psyng_mcauditor       = ls_mcauditor_n
                    o_psyng_mcauditor       = ls_mcauditor_o
                    n_psyng_mccarole        = ls_mccarole_n
                    o_psyng_mccarole        = ls_mccarole_o
                    n_psyng_mccauser        = ls_mccauser_n
                    o_psyng_mccauser        = ls_mccauser_o
                    n_psyng_mchdr           = ls_mchdr_n
                    o_psyng_mchdr           = ls_mchdr_o
                    n_psyng_mcrepid         = ls_mcrepid_n
                    o_psyng_mcrepid         = ls_mcrepid_o
                    n_psyng_mcrole          = ls_mcrole_n
                    o_psyng_mcrole          = ls_mcrole_o
                    n_psyng_mctran          = ls_mctran_n
                    o_psyng_mctran          = ls_mctran_o
                    n_psyng_mcuser          = ls_mcuser_n
                    o_psyng_mcuser          = ls_mcuser_o
                    n_psyng_mcusrgrp        = ls_mcusrgrp_n
                    o_psyng_mcusrgrp        = ls_mcusrgrp_o
                    upd_psyng_mcusrgrp      = 'D'
                    n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                    o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

               TABLES
                    icdtxt_mit              = lt_cdtxt.

          CLEAR ls_mcusrgrp_o.
        ENDIF.

*     Edit existing user group assignment if found
      ELSEIF ls_mcusrgrp_o <> it_mcusrgrp
      AND NOT it_mcusrgrp IS INITIAL.
        MODIFY /psyng/mcusrgrp FROM it_mcusrgrp.    "#EC CI_IMUD_NESTED

        IF sy-subrc = 0.
          ef_mcusrgrp_added = 'Y'.
          ls_mcusrgrp_n = it_mcusrgrp.

          CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
               EXPORTING
                    objectid                = l_objid
                    tcode                   = sy-tcode
                    utime                   = sy-uzeit
                    udate                   = sy-datum
                    username                = l_current_user "C0700
                    object_change_indicator = 'U'
                    planned_or_real_changes = 'R'
                    n_psyng_mcauditor       = ls_mcauditor_n
                    o_psyng_mcauditor       = ls_mcauditor_o
                    n_psyng_mccarole        = ls_mccarole_n
                    o_psyng_mccarole        = ls_mccarole_o
                    n_psyng_mccauser        = ls_mccauser_n
                    o_psyng_mccauser        = ls_mccauser_o
                    n_psyng_mchdr           = ls_mchdr_n
                    o_psyng_mchdr           = ls_mchdr_o
                    n_psyng_mcrepid         = ls_mcrepid_n
                    o_psyng_mcrepid         = ls_mcrepid_o
                    n_psyng_mcrole          = ls_mcrole_n
                    o_psyng_mcrole          = ls_mcrole_o
                    n_psyng_mctran          = ls_mctran_n
                    o_psyng_mctran          = ls_mctran_o
                    n_psyng_mcuser          = ls_mcuser_n
                    o_psyng_mcuser          = ls_mcuser_o
                    n_psyng_mcusrgrp        = ls_mcusrgrp_n
                    o_psyng_mcusrgrp        = ls_mcusrgrp_o
                    upd_psyng_mcusrgrp      = 'U'
                    n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                    o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

               TABLES
                    icdtxt_mit              = lt_cdtxt.

*         Send email to appropriate auditor(s)
          IF NOT if_no_email = 'X'.
            MOVE-CORRESPONDING ls_mcusrgrp_n TO ls_mit_assgn.
            ls_mit_assgn-type = '2'.             "User group
            CALL FUNCTION '/PSYNG/SW_078'
                 EXPORTING
                      is_mit_assgn = ls_mit_assgn.
*                      i_single_recip = ls_mcusrgrp_n-auditor.
          ENDIF.

          CLEAR: ls_mcusrgrp_n, ls_mcusrgrp_o.
        ENDIF.
      ENDIF.
    ENDLOOP.

*   Add new user group assignments
    LOOP AT it_mcusrgrp INTO ls_mcusrgrp_n.
      READ TABLE lt_mcusrgrp WITH KEY contid = ls_mcusrgrp_n-contid
                                      conid  = ls_mcusrgrp_n-conid
                                      class  = ls_mcusrgrp_n-class
                                      vrsio  = ls_mcusrgrp_n-vrsio.
      CHECK sy-subrc <> 0.

      INSERT /psyng/mcusrgrp FROM ls_mcusrgrp_n.    "#EC CI_IMUD_NESTED
      IF sy-subrc = 0.
        ef_mcusrgrp_added = 'Y'.

        CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
             EXPORTING
                  objectid                = l_objid
                  tcode                   = sy-tcode
                  utime                   = sy-uzeit
                  udate                   = sy-datum
                  username                = l_current_user  " C0700
                  object_change_indicator = 'I'
                  planned_or_real_changes = 'R'
                  n_psyng_mcauditor       = ls_mcauditor_n
                  o_psyng_mcauditor       = ls_mcauditor_o
                  n_psyng_mccarole        = ls_mccarole_n
                  o_psyng_mccarole        = ls_mccarole_o
                  n_psyng_mccauser        = ls_mccauser_n
                  o_psyng_mccauser        = ls_mccauser_o
                  n_psyng_mchdr           = ls_mchdr_n
                  o_psyng_mchdr           = ls_mchdr_o
                  n_psyng_mcrepid         = ls_mcrepid_n
                  o_psyng_mcrepid         = ls_mcrepid_o
                  n_psyng_mcrole          = ls_mcrole_n
                  o_psyng_mcrole          = ls_mcrole_o
                  n_psyng_mctran          = ls_mctran_n
                  o_psyng_mctran          = ls_mctran_o
                  n_psyng_mcuser          = ls_mcuser_n
                  o_psyng_mcuser          = ls_mcuser_o
                  n_psyng_mcusrgrp        = ls_mcusrgrp_n
                  o_psyng_mcusrgrp        = ls_mcusrgrp_o
                  upd_psyng_mcusrgrp      = 'I'
                  n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                  o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

             TABLES
                  icdtxt_mit              = lt_cdtxt.

*       Send email to appropriate auditor(s)
        IF NOT if_no_email = 'X'.
          MOVE-CORRESPONDING ls_mcusrgrp_n TO ls_mit_assgn.
          ls_mit_assgn-type = '2'.               "User group
          CALL FUNCTION '/PSYNG/SW_078'
               EXPORTING
                    is_mit_assgn = ls_mit_assgn.
*                    i_single_recip = ls_mcusrgrp_n-auditor.
        ENDIF.

        CLEAR ls_mcusrgrp_n.
      ENDIF.
    ENDLOOP.

    IF if_del_assgn_only = 'X'.
      it_mcusrgrp[] = lt_mcusrgrp[].
    ENDIF.
  ENDIF.

* Critical auth user assignments
  IF it_mccauser IS REQUESTED.
    IF if_del_assgn_only = space.
      SELECT * INTO TABLE lt_mccauser                "#EC CI_SEL_NESTED
              FROM /psyng/mccauser
                WHERE contid = is_mchdr-contid.
      ELSE.
        lt_mccauser[] = it_mccauser[].
        REFRESH it_mccauser.
      ENDIF.

      LOOP AT lt_mccauser INTO ls_mccauser_o.
        READ TABLE it_mccauser WITH KEY contid  = ls_mccauser_o-contid
                                       swaudid = ls_mccauser_o-swaudid
                                        userid  = ls_mccauser_o-userid
                                         vrsio   = ls_mccauser_o-vrsio.

        IF sy-subrc <> 0 AND if_add_assgn_only = ' '.
*       Delete critical auth user assignments that no longer exist
         DELETE FROM /psyng/mccauser                 "#EC CI_SEL_NESTED
                        WHERE contid  = ls_mccauser_o-contid
                          AND swaudid = ls_mccauser_o-swaudid
                          AND userid  = ls_mccauser_o-userid
                          AND vrsio   = ls_mccauser_o-vrsio.
          IF sy-subrc = 0.
            CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
                 EXPORTING
                      objectid                = l_objid
                      tcode                   = sy-tcode
                      utime                   = sy-uzeit
                      udate                   = sy-datum
                      username                = l_current_user " C0700
                      object_change_indicator = 'D'
                      planned_or_real_changes = 'R'
                      n_psyng_mcauditor       = ls_mcauditor_n
                      o_psyng_mcauditor       = ls_mcauditor_o
                      n_psyng_mccarole        = ls_mccarole_n
                      o_psyng_mccarole        = ls_mccarole_o
                      n_psyng_mccauser        = ls_mccauser_n
                      o_psyng_mccauser        = ls_mccauser_o
                      upd_psyng_mccauser      = 'D'
                      n_psyng_mchdr           = ls_mchdr_n
                      o_psyng_mchdr           = ls_mchdr_o
                      n_psyng_mcrepid         = ls_mcrepid_n
                      o_psyng_mcrepid         = ls_mcrepid_o
                      n_psyng_mcrole          = ls_mcrole_n
                      o_psyng_mcrole          = ls_mcrole_o
                      n_psyng_mctran          = ls_mctran_n
                      o_psyng_mctran          = ls_mctran_o
                      n_psyng_mcuser          = ls_mcuser_n
                      o_psyng_mcuser          = ls_mcuser_o
                      n_psyng_mcusrgrp        = ls_mcusrgrp_n
                      o_psyng_mcusrgrp        = ls_mcusrgrp_o
                      n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                      o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

                 TABLES
                      icdtxt_mit              = lt_cdtxt.

            CLEAR ls_mccauser_o.
          ENDIF.

*     Edit existing critical auth user assignment

        ELSEIF ls_mccauser_o <> it_mccauser.
         DELETE FROM /psyng/mccauser                "#EC CI_IMUD_NESTED
                 WHERE contid = is_mchdr-contid
*                                 AND   auditor = it_mccauser-auditor
                   AND userid = it_mccauser-userid
                   AND swaudid = it_mccauser-swaudid
                   AND vrsio = it_mccauser-vrsio.
          IF sy-subrc = 0.
           MODIFY /psyng/mccauser                   "#EC CI_IMUD_NESTED
                  FROM TABLE it_mccauser.
          ENDIF.

          IF sy-subrc = 0.
            ef_mccauser_added = 'Y'.
            ls_mccauser_n = it_mccauser.

            CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
                 EXPORTING
                      objectid                = l_objid
                      tcode                   = sy-tcode
                      utime                   = sy-uzeit
                      udate                   = sy-datum
                      username                = l_current_user " C0700
                      object_change_indicator = 'U'
                      planned_or_real_changes = 'R'
                      n_psyng_mcauditor       = ls_mcauditor_n
                      o_psyng_mcauditor       = ls_mcauditor_o
                      n_psyng_mccarole        = ls_mccarole_n
                      o_psyng_mccarole        = ls_mccarole_o
                      n_psyng_mccauser        = ls_mccauser_n
                      o_psyng_mccauser        = ls_mccauser_o
                      upd_psyng_mccauser      = 'U'
                      n_psyng_mchdr           = ls_mchdr_n
                      o_psyng_mchdr           = ls_mchdr_o
                      n_psyng_mcrepid         = ls_mcrepid_n
                      o_psyng_mcrepid         = ls_mcrepid_o
                      n_psyng_mcrole          = ls_mcrole_n
                      o_psyng_mcrole          = ls_mcrole_o
                      n_psyng_mctran          = ls_mctran_n
                      o_psyng_mctran          = ls_mctran_o
                      n_psyng_mcuser          = ls_mcuser_n
                      o_psyng_mcuser          = ls_mcuser_o
                      n_psyng_mcusrgrp        = ls_mcusrgrp_n
                      o_psyng_mcusrgrp        = ls_mcusrgrp_o
                      n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                      o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

                 TABLES
                      icdtxt_mit              = lt_cdtxt.

*         Send email to appropriate auditor(s)
            IF NOT if_no_email = 'X'.
              MOVE-CORRESPONDING ls_mccauser_n TO ls_mit_assgn.
              ls_mit_assgn-type = '3'.             "Critical auth
              CALL FUNCTION '/PSYNG/SW_078'
                   EXPORTING
                        is_mit_assgn = ls_mit_assgn.
*                      i_single_recip = ls_mccauser_n-auditor.
            ENDIF.

            CLEAR: ls_mccauser_n, ls_mccauser_o.
          ENDIF.
        ENDIF.
      ENDLOOP.

*   Add new critical auth user assignments
      LOOP AT it_mccauser INTO ls_mccauser_n ."WHERE mandt EQ space.
        READ TABLE lt_mccauser WITH KEY contid  = ls_mccauser_n-contid
                                       swaudid = ls_mccauser_n-swaudid
                                        userid  = ls_mccauser_n-userid
                                         vrsio   = ls_mccauser_n-vrsio.
        CHECK sy-subrc <> 0.

        MODIFY LINE ls_mccauser_n-mandt FIELD VALUE sy-mandt FROM space.
       INSERT /psyng/mccauser FROM ls_mccauser_n.   "#EC CI_IMUD_NESTED
        IF sy-subrc = 0.
          ef_mccauser_added = 'Y'.

          CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
               EXPORTING
                    objectid                = l_objid
                    tcode                   = sy-tcode
                    utime                   = sy-uzeit
                    udate                   = sy-datum
                    username                = l_current_user " C0700
                    object_change_indicator = 'I'
                    planned_or_real_changes = 'R'
                    n_psyng_mcauditor       = ls_mcauditor_n
                    o_psyng_mcauditor       = ls_mcauditor_o
                    n_psyng_mccarole        = ls_mccarole_n
                    o_psyng_mccarole        = ls_mccarole_o
                    n_psyng_mccauser        = ls_mccauser_n
                    o_psyng_mccauser        = ls_mccauser_o
                    upd_psyng_mccauser      = 'I'
                    n_psyng_mchdr           = ls_mchdr_n
                    o_psyng_mchdr           = ls_mchdr_o
                    n_psyng_mcrepid         = ls_mcrepid_n
                    o_psyng_mcrepid         = ls_mcrepid_o
                    n_psyng_mcrole          = ls_mcrole_n
                    o_psyng_mcrole          = ls_mcrole_o
                    n_psyng_mctran          = ls_mctran_n
                    o_psyng_mctran          = ls_mctran_o
                    n_psyng_mcuser          = ls_mcuser_n
                    o_psyng_mcuser          = ls_mcuser_o
                    n_psyng_mcusrgrp        = ls_mcusrgrp_n
                    o_psyng_mcusrgrp        = ls_mcusrgrp_o
                    n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                    o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

               TABLES
                    icdtxt_mit              = lt_cdtxt.

*       Send email to appropriate auditor(s)
          IF NOT if_no_email = 'X'.
            MOVE-CORRESPONDING ls_mccauser_n TO ls_mit_assgn.
            ls_mit_assgn-type = '3'.               "Critical auth
            CALL FUNCTION '/PSYNG/SW_078'
                 EXPORTING
                      is_mit_assgn = ls_mit_assgn.
          ENDIF.

          CLEAR ls_mccauser_n.
        ENDIF.
      ENDLOOP.

      IF if_del_assgn_only = 'X'.
        it_mccauser[] = lt_mccauser[].
      ENDIF.
    ENDIF.

* Critical auth role assignments
    IF it_mccarole IS REQUESTED.
      IF if_del_assgn_only = space.
        SELECT * INTO TABLE lt_mccarole FROM /psyng/mccarole
               WHERE contid = is_mchdr-contid.
        ELSE.
          lt_mccarole[] = it_mccarole[].
          REFRESH it_mccarole.
        ENDIF.

        LOOP AT lt_mccarole INTO ls_mccarole_o.
         READ TABLE it_mccarole WITH KEY contid   = ls_mccarole_o-contid
                                        swaudid  = ls_mccarole_o-swaudid
                                       agr_name = ls_mccarole_o-agr_name
                                         vrsio    = ls_mccarole_o-vrsio.

          IF sy-subrc <> 0 AND if_add_assgn_only = ' '.
*       Delete critical auth role assignments that no longer exist
            DELETE FROM /psyng/mccarole
                        WHERE contid   = ls_mccarole_o-contid
                          AND swaudid  = ls_mccarole_o-swaudid
                          AND agr_name = ls_mccarole_o-agr_name
                          AND vrsio    = ls_mccarole_o-vrsio.
            IF sy-subrc = 0.
              CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
                   EXPORTING
                        objectid                = l_objid
                        tcode                   = sy-tcode
                        utime                   = sy-uzeit
                        udate                   = sy-datum
                        username                = l_current_user " C0700
                        object_change_indicator = 'D'
                        planned_or_real_changes = 'R'
                        n_psyng_mcauditor       = ls_mcauditor_n
                        o_psyng_mcauditor       = ls_mcauditor_o
                        n_psyng_mccarole        = ls_mccarole_n
                        o_psyng_mccarole        = ls_mccarole_o
                        n_psyng_mccauser        = ls_mccauser_n
                        o_psyng_mccauser        = ls_mccauser_o
                        upd_psyng_mccarole      = 'D'
                        n_psyng_mchdr           = ls_mchdr_n
                        o_psyng_mchdr           = ls_mchdr_o
                        n_psyng_mcrepid         = ls_mcrepid_n
                        o_psyng_mcrepid         = ls_mcrepid_o
                        n_psyng_mcrole          = ls_mcrole_n
                        o_psyng_mcrole          = ls_mcrole_o
                        n_psyng_mctran          = ls_mctran_n
                        o_psyng_mctran          = ls_mctran_o
                        n_psyng_mcuser          = ls_mcuser_n
                        o_psyng_mcuser          = ls_mcuser_o
                        n_psyng_mcusrgrp        = ls_mcusrgrp_n
                        o_psyng_mcusrgrp        = ls_mcusrgrp_o
                        n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                        o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

                   TABLES
                        icdtxt_mit              = lt_cdtxt.

              CLEAR ls_mccarole_o.
            ENDIF.

*     Edit existing critical auth role assignment
          ELSEIF ls_mccarole_o <> it_mccarole.
            DELETE FROM /psyng/mccarole WHERE contid = is_mchdr-contid
                                    AND agr_name = it_mccarole-agr_name
                                      AND swaudid = it_mccarole-swaudid
                                        AND vrsio = it_mccarole-vrsio.
            IF sy-subrc = 0.
              MODIFY /psyng/mccarole FROM TABLE it_mccarole.
            ENDIF.

            IF sy-subrc = 0.
              ef_mccarole_added = 'Y'.
              ls_mccarole_n = it_mccarole.

              CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
                   EXPORTING
                        objectid                = l_objid
                        tcode                   = sy-tcode
                        utime                   = sy-uzeit
                        udate                   = sy-datum
                        username                = l_current_user " C0700
                        object_change_indicator = 'U'
                        planned_or_real_changes = 'R'
                        n_psyng_mcauditor       = ls_mcauditor_n
                        o_psyng_mcauditor       = ls_mcauditor_o
                        n_psyng_mccarole        = ls_mccarole_n
                        o_psyng_mccarole        = ls_mccarole_o
                        n_psyng_mccauser        = ls_mccauser_n
                        o_psyng_mccauser        = ls_mccauser_o
                        upd_psyng_mccarole      = 'U'
                        n_psyng_mchdr           = ls_mchdr_n
                        o_psyng_mchdr           = ls_mchdr_o
                        n_psyng_mcrepid         = ls_mcrepid_n
                        o_psyng_mcrepid         = ls_mcrepid_o
                        n_psyng_mcrole          = ls_mcrole_n
                        o_psyng_mcrole          = ls_mcrole_o
                        n_psyng_mctran          = ls_mctran_n
                        o_psyng_mctran          = ls_mctran_o
                        n_psyng_mcuser          = ls_mcuser_n
                        o_psyng_mcuser          = ls_mcuser_o
                        n_psyng_mcusrgrp        = ls_mcusrgrp_n
                        o_psyng_mcusrgrp        = ls_mcusrgrp_o
                        n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                        o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

                   TABLES
                        icdtxt_mit              = lt_cdtxt.

*         Send email to appropriate auditor(s)
              IF NOT if_no_email = 'X'.
                MOVE-CORRESPONDING ls_mccarole_n TO ls_mit_assgn.
            ls_mit_assgn-type = '5'.             "Critical auth for role
                CALL FUNCTION '/PSYNG/SW_078'
                     EXPORTING
                          is_mit_assgn = ls_mit_assgn.
              ENDIF.

              CLEAR: ls_mccarole_n, ls_mccarole_o.
            ENDIF.
          ENDIF.
        ENDLOOP.

*   Add new critical auth role assignments
        LOOP AT it_mccarole INTO ls_mccarole_n.
         READ TABLE lt_mccarole WITH KEY contid   = ls_mccarole_n-contid
                                        swaudid  = ls_mccarole_n-swaudid
                                       agr_name = ls_mccarole_n-agr_name
                                         vrsio    = ls_mccarole_n-vrsio.
          CHECK sy-subrc <> 0.

        MODIFY LINE ls_mccarole_n-mandt FIELD VALUE sy-mandt FROM space.
          INSERT /psyng/mccarole FROM ls_mccarole_n.
          IF sy-subrc = 0.
            ef_mccarole_added = 'Y'.

            CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
                 EXPORTING
                      objectid                = l_objid
                      tcode                   = sy-tcode
                      utime                   = sy-uzeit
                      udate                   = sy-datum
                      username                = l_current_user " C0700
                      object_change_indicator = 'I'
                      planned_or_real_changes = 'R'
                      n_psyng_mcauditor       = ls_mcauditor_n
                      o_psyng_mcauditor       = ls_mcauditor_o
                      n_psyng_mccarole        = ls_mccarole_n
                      o_psyng_mccarole        = ls_mccarole_o
                      n_psyng_mccauser        = ls_mccauser_n
                      o_psyng_mccauser        = ls_mccauser_o
                      upd_psyng_mccarole      = 'I'
                      n_psyng_mchdr           = ls_mchdr_n
                      o_psyng_mchdr           = ls_mchdr_o
                      n_psyng_mcrepid         = ls_mcrepid_n
                      o_psyng_mcrepid         = ls_mcrepid_o
                      n_psyng_mcrole          = ls_mcrole_n
                      o_psyng_mcrole          = ls_mcrole_o
                      n_psyng_mctran          = ls_mctran_n
                      o_psyng_mctran          = ls_mctran_o
                      n_psyng_mcuser          = ls_mcuser_n
                      o_psyng_mcuser          = ls_mcuser_o
                      n_psyng_mcusrgrp        = ls_mcusrgrp_n
                      o_psyng_mcusrgrp        = ls_mcusrgrp_o
                      n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                      o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

                 TABLES
                      icdtxt_mit              = lt_cdtxt.

*       Send email to appropriate auditor(s)
            IF NOT if_no_email = 'X'.
              MOVE-CORRESPONDING ls_mccarole_n TO ls_mit_assgn.
          ls_mit_assgn-type = '5'.               "Critical auth for role
              CALL FUNCTION '/PSYNG/SW_078'
                   EXPORTING
                        is_mit_assgn = ls_mit_assgn.
            ENDIF.

            CLEAR ls_mccarole_n.
          ENDIF.
        ENDLOOP.

        IF if_del_assgn_only = 'X'.
          it_mccarole[] = lt_mccarole[].
        ENDIF.
      ENDIF.

*
* Role assignments
      IF it_mcrole IS REQUESTED.
        IF if_del_assgn_only = space.
          SELECT * INTO TABLE lt_mcrole FROM /psyng/mcrole
                 WHERE contid = is_mchdr-contid.
          ELSE.
            lt_mcrole[] = it_mcrole[].
            REFRESH it_mcrole.
          ENDIF.

          LOOP AT lt_mcrole INTO ls_mcrole_o.
            READ TABLE it_mcrole WITH KEY contid   = ls_mcrole_o-contid
                                          conid    = ls_mcrole_o-conid
                                         agr_name = ls_mcrole_o-agr_name
                                         vrsio    = ls_mcrole_o-vrsio.
            IF sy-subrc <> 0 AND if_add_assgn_only = space.
*       Delete roles assignments that no longer exist
         DELETE FROM /psyng/mcrole                  "#EC CI_IMUD_NESTED
                    WHERE contid   = ls_mcrole_o-contid
                      AND conid    = ls_mcrole_o-conid
                      AND agr_name = ls_mcrole_o-agr_name
                      AND vrsio    = ls_mcrole_o-vrsio.
              IF sy-subrc = 0.
                CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
                     EXPORTING
                          objectid                = l_objid
                          tcode                   = sy-tcode
                          utime                   = sy-uzeit
                          udate                   = sy-datum
                        username                = l_current_user " C0700
                        object_change_indicator = 'D'
                        planned_or_real_changes = 'R'
                        n_psyng_mcauditor       = ls_mcauditor_n
                        o_psyng_mcauditor       = ls_mcauditor_o
                        n_psyng_mccarole        = ls_mccarole_n
                        o_psyng_mccarole        = ls_mccarole_o
                        n_psyng_mccauser        = ls_mccauser_n
                        o_psyng_mccauser        = ls_mccauser_o
                        n_psyng_mchdr           = ls_mchdr_n
                        o_psyng_mchdr           = ls_mchdr_o
                        n_psyng_mcrepid         = ls_mcrepid_n
                        o_psyng_mcrepid         = ls_mcrepid_o
                        n_psyng_mcrole          = ls_mcrole_n
                        o_psyng_mcrole          = ls_mcrole_o
                        upd_psyng_mcrole        = 'D'
                        n_psyng_mctran          = ls_mctran_n
                        o_psyng_mctran          = ls_mctran_o
                        n_psyng_mcuser          = ls_mcuser_n
                        o_psyng_mcuser          = ls_mcuser_o
                        n_psyng_mcusrgrp        = ls_mcusrgrp_n
                        o_psyng_mcusrgrp        = ls_mcusrgrp_o
                        n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                        o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

                   TABLES
                        icdtxt_mit              = lt_cdtxt.

                CLEAR ls_mcrole_o.
              ENDIF.

*     Edit existing role assignment
            ELSEIF ls_mcrole_o <> it_mcrole.
         MODIFY /psyng/mcrole FROM it_mcrole.       "#EC CI_IMUD_NESTED

              IF sy-subrc = 0.
                ef_mcrole_added = 'Y'.
                ls_mcrole_n = it_mcrole.

                CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
                     EXPORTING
                          objectid                = l_objid
                          tcode                   = sy-tcode
                          utime                   = sy-uzeit
                          udate                   = sy-datum
                        username                = l_current_user " C0700
                        object_change_indicator = 'U'
                        planned_or_real_changes = 'R'
                        n_psyng_mcauditor       = ls_mcauditor_n
                        o_psyng_mcauditor       = ls_mcauditor_o
                        n_psyng_mccarole        = ls_mccarole_n
                        o_psyng_mccarole        = ls_mccarole_o
                        n_psyng_mccauser        = ls_mccauser_n
                        o_psyng_mccauser        = ls_mccauser_o
                        n_psyng_mchdr           = ls_mchdr_n
                        o_psyng_mchdr           = ls_mchdr_o
                        n_psyng_mcrepid         = ls_mcrepid_n
                        o_psyng_mcrepid         = ls_mcrepid_o
                        n_psyng_mcrole          = ls_mcrole_n
                        o_psyng_mcrole          = ls_mcrole_o
                        upd_psyng_mcrole        = 'U'
                        n_psyng_mctran          = ls_mctran_n
                        o_psyng_mctran          = ls_mctran_o
                        n_psyng_mcuser          = ls_mcuser_n
                        o_psyng_mcuser          = ls_mcuser_o
                        n_psyng_mcusrgrp        = ls_mcusrgrp_n
                        o_psyng_mcusrgrp        = ls_mcusrgrp_o
                        n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                        o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

                   TABLES
                        icdtxt_mit              = lt_cdtxt.

*         Send email to appropriate auditor(s)
                IF NOT if_no_email = 'X'.
                  MOVE-CORRESPONDING ls_mcrole_n TO ls_mit_assgn.
                  ls_mit_assgn-type = '4'.             "Role
                  CALL FUNCTION '/PSYNG/SW_078'
                       EXPORTING
                            is_mit_assgn = ls_mit_assgn.
*                      i_single_recip = ls_mcrole_n-auditor.
                ENDIF.

                CLEAR: ls_mcrole_n, ls_mcrole_o.
              ENDIF.
            ENDIF.
          ENDLOOP.

*   Add new role assignments
          LOOP AT it_mcrole INTO ls_mcrole_n.
            READ TABLE lt_mcrole WITH KEY contid   = ls_mcrole_n-contid
                                          conid    = ls_mcrole_n-conid
                                         agr_name = ls_mcrole_n-agr_name
                                         vrsio    = ls_mcrole_n-vrsio.
            CHECK sy-subrc <> 0.

            INSERT /psyng/mcrole FROM ls_mcrole_n.
            IF sy-subrc = 0.
              ef_mcrole_added = 'Y'.

              CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
                   EXPORTING
                        objectid                = l_objid
                        tcode                   = sy-tcode
                        utime                   = sy-uzeit
                        udate                   = sy-datum
                       username                = l_current_user " C0700
                       object_change_indicator = 'I'
                       planned_or_real_changes = 'R'
                       n_psyng_mcauditor       = ls_mcauditor_n
                       o_psyng_mcauditor       = ls_mcauditor_o
                       n_psyng_mccarole        = ls_mccarole_n
                       o_psyng_mccarole        = ls_mccarole_o
                       n_psyng_mccauser        = ls_mccauser_n
                       o_psyng_mccauser        = ls_mccauser_o
                       n_psyng_mchdr           = ls_mchdr_n
                       o_psyng_mchdr           = ls_mchdr_o
                       n_psyng_mcrepid         = ls_mcrepid_n
                       o_psyng_mcrepid         = ls_mcrepid_o
                       n_psyng_mcrole          = ls_mcrole_n
                       o_psyng_mcrole          = ls_mcrole_o
                       upd_psyng_mcrole        = 'I'
                       n_psyng_mctran          = ls_mctran_n
                       o_psyng_mctran          = ls_mctran_o
                       n_psyng_mcuser          = ls_mcuser_n
                       o_psyng_mcuser          = ls_mcuser_o
                       n_psyng_mcusrgrp        = ls_mcusrgrp_n
                       o_psyng_mcusrgrp        = ls_mcusrgrp_o
                       n_psyng_mcrvwhdr        = ls_mcrvwhdr_n
                       o_psyng_mcrvwhdr        = ls_mcrvwhdr_o

                  TABLES
                       icdtxt_mit              = lt_cdtxt.

*       Send email to appropriate auditor(s)
              IF NOT if_no_email = 'X'.
                MOVE-CORRESPONDING ls_mcrole_n TO ls_mit_assgn.
                ls_mit_assgn-type = '4'.               "Role
                CALL FUNCTION '/PSYNG/SW_078'
                     EXPORTING
                          is_mit_assgn = ls_mit_assgn.
              ENDIF.

              CLEAR ls_mcrole_n.
            ENDIF.
          ENDLOOP.

          IF if_del_assgn_only = 'X'.
            it_mcrole[] = lt_mcrole[].
          ENDIF.
        ENDIF.

* Mitigation Description
        IF it_texts IS REQUESTED.
*--Init language
          it_texts-spras = sy-langu.
          MODIFY it_texts TRANSPORTING spras WHERE spras IS INITIAL.

*--Collect all languages
          LOOP AT it_texts ASSIGNING <text>.
            lt_spras = <text>-spras.
            COLLECT lt_spras.
          ENDLOOP.
          IF lt_spras[] IS INITIAL.
            lt_spras = sy-langu.
            COLLECT lt_spras.
          ENDIF.

*--assign line nr's per language
          LOOP AT lt_spras.
            l_idx = 1.
            LOOP AT it_texts ASSIGNING <text> WHERE spras = lt_spras.
              <text>-line = l_idx.
              <text>-object = 'M'.
              ADD 1 TO l_idx.
            ENDLOOP.
          ENDLOOP.


*   Delete old text for all languages that where encountered in the text
*   table
          LOOP AT lt_spras.
       DELETE FROM /psyng/texts                     "#EC CI_IMUD_NESTED
                      WHERE textname = ls_mchdr-contid
                        AND object   = 'M'
                        AND spras    = lt_spras.
          ENDLOOP.

          IF NOT it_texts[] IS INITIAL.
       MODIFY /psyng/texts FROM TABLE it_texts.     "#EC CI_IMUD_NESTED
            IF sy-subrc = 0.
              ef_text_added = 'Y'.
*       There are No Change documents for texts.
            ENDIF.
          ENDIF.
        ENDIF.

        COMMIT WORK.

        CALL FUNCTION 'DEQUEUE_/PSYNG/MCHDR'
             EXPORTING
                  contid = is_mchdr-contid.
      ENDFUNCTION.
