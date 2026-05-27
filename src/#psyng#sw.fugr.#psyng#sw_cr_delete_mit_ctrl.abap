FUNCTION /psyng/sw_cr_delete_mit_ctrl.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_CONTID) LIKE  /PSYNG/MCHDR-CONTID
*"  EXCEPTIONS
*"      NOT_AUTHORIZED
*"      NOT_EXIST
*"      LOCKED
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_DELETE_MIT_CTRL'.
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
        ls_mcrole_n    TYPE /psyng/mcrole,
        ls_mcrole_o    TYPE /psyng/mcrole,
        lt_mcauditor   TYPE TABLE OF /psyng/mcauditor WITH HEADER LINE,
        lt_mctran      TYPE TABLE OF /psyng/mctran    WITH HEADER LINE,
        lt_mcrepid     TYPE TABLE OF /psyng/mcrepid   WITH HEADER LINE,
        lt_conflict    TYPE TABLE OF /psyng/conflict  WITH HEADER LINE,
        lt_cdtxt       TYPE TABLE OF cdtxt,
        lt_conpmit     TYPE TABLE OF /psyng/conpmit WITH HEADER LINE,
        lt_conpmit_t   TYPE TABLE OF /psyng/conpmit WITH HEADER LINE,
        ls_mcrvwhdr_o  TYPE /psyng/mcrvwhdr,
        ls_mcrvwhdr_n  TYPE /psyng/mcrvwhdr.

* BOC by RGUPTA on 07.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700
  AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
           ID 'ACTVT' FIELD '06'
           ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_CNTID' FIELD i_contid.
  IF sy-subrc <> 0.
    RAISE not_authorized.
  ENDIF.

  SELECT SINGLE * INTO ls_mchdr_o FROM /psyng/mchdr  "#EC CI_SEL_NESTED
                WHERE contid = i_contid.
  IF sy-subrc <> 0.
    RAISE not_exist.
  ENDIF.

  l_objid = i_contid.

* Lock mitigation control
  CALL FUNCTION 'ENQUEUE_/PSYNG/MCHDR'
       EXPORTING
            contid         = i_contid
       EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
            RAISING locked.
  ENDIF.

  SELECT SINGLE * INTO ls_mchdr_o FROM /psyng/mchdr  "#EC CI_SEL_NESTED
                WHERE contid = i_contid.
  IF sy-subrc <> 0.
    RAISE not_exist.
  ENDIF.

* Delete mitigation control header
  DELETE FROM /psyng/mchdr WHERE contid = i_contid. "#EC CI_IMUD_NESTED

  CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
       EXPORTING
            objectid                = l_objid
            tcode                   = sy-tcode
            utime                   = sy-uzeit
            udate                   = sy-datum
            username                = l_current_user" C0700
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
            upd_psyng_mchdr         = 'D'
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
            N_PSYNG_MCRVWHDR        = ls_mcrvwhdr_n
            O_PSYNG_MCRVWHDR        = ls_mcrvwhdr_o
       TABLES
            icdtxt_mit              = lt_cdtxt.

  CLEAR ls_mchdr_o.

* Delete mitigation auditors
  SELECT * INTO TABLE lt_mcauditor                   "#EC CI_SEL_NESTED
      FROM /psyng/mcauditor
         WHERE contid = i_contid.

  IF NOT lt_mcauditor[] IS INITIAL.
    DELETE /psyng/mcauditor FROM TABLE lt_mcauditor."#EC CI_IMUD_NESTED

    LOOP AT lt_mcauditor INTO ls_mcauditor_o.
      CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user "C0700
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
                N_PSYNG_MCRVWHDR        = ls_mcrvwhdr_n
                O_PSYNG_MCRVWHDR        = ls_mcrvwhdr_o

           TABLES
                icdtxt_mit              = lt_cdtxt.
    ENDLOOP.

    CLEAR ls_mcauditor_o.
  ENDIF.

* Delete mitigation transactions
  SELECT * INTO TABLE lt_mctran FROM /psyng/mctran   "#EC CI_SEL_NESTED
         WHERE contid = i_contid.

  IF NOT lt_mctran[] IS INITIAL.
    DELETE /psyng/mctran FROM TABLE lt_mctran.      "#EC CI_IMUD_NESTED

    LOOP AT lt_mctran INTO ls_mctran_o.
      CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user "C0700
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
                N_PSYNG_MCRVWHDR        = ls_mcrvwhdr_n
                O_PSYNG_MCRVWHDR        = ls_mcrvwhdr_o

           TABLES
                icdtxt_mit              = lt_cdtxt.
    ENDLOOP.

    CLEAR ls_mctran_o.
  ENDIF.

* Delete mitigation reports
  SELECT * INTO TABLE lt_mcrepid                     "#EC CI_SEL_NESTED
     FROM /psyng/mcrepid
         WHERE contid = i_contid.

  IF NOT lt_mcrepid[] IS INITIAL.
    DELETE /psyng/mcrepid FROM TABLE lt_mcrepid.    "#EC CI_IMUD_NESTED

    LOOP AT lt_mcrepid INTO ls_mcrepid_o.
      CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user "C0700
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
                N_PSYNG_MCRVWHDR        = ls_mcrvwhdr_n
                O_PSYNG_MCRVWHDR        = ls_mcrvwhdr_o

           TABLES
                icdtxt_mit              = lt_cdtxt.
    ENDLOOP.

    CLEAR ls_mcrepid_o.
  ENDIF.
  SELECT SINGLE * INTO ls_mcrvwhdr_o FROM /psyng/mcrvwhdr  "#EC CI_SEL_NESTED
                WHERE contid = i_contid.
  IF NOT ls_mcrvwhdr_o IS INITIAL.
* Delete mitigation control review header
  DELETE FROM /psyng/mcrvwhdr WHERE contid = i_contid. "#EC CI_IMUD_NESTED

  CALL FUNCTION '/PSYNG/MIT_WRITE_DOCUMENT' IN UPDATE TASK
       EXPORTING
            objectid                = l_objid
            tcode                   = sy-tcode
            utime                   = sy-uzeit
            udate                   = sy-datum
            username                = l_current_user "C0700
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
            upd_psyng_mchdr         = 'D'
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
            N_PSYNG_MCRVWHDR        = ls_mcrvwhdr_n
            O_PSYNG_MCRVWHDR        = ls_mcrvwhdr_o
       TABLES
            icdtxt_mit              = lt_cdtxt.

  CLEAR ls_mcrvwhdr_o.
  ENDIF.

*-- Remove contid from multiple proposed mitigation
*-- Load all the conflcits for which this is defined as prop mit
  SELECT DISTINCT conid vrsio
  FROM /psyng/conpmit
  INTO CORRESPONDING FIELDS OF TABLE lt_conpmit
  WHERE contid = i_contid.


*-- Remove controlid from conflicts
  SELECT * INTO TABLE lt_conflict FROM /psyng/conflict
    WHERE contid = i_contid.

  IF NOT lt_conpmit[] IS INITIAL.
* -- Load Conflict detail for conomit table entries
    SELECT * FROM /psyng/conflict APPENDING TABLE lt_conflict
    FOR ALL ENTRIES IN lt_conpmit
    WHERE conid = lt_conpmit-conid
      AND vrsio = lt_conpmit-vrsio.

  ENDIF.

  SORT lt_conflict BY conid vrsio.
  DELETE ADJACENT DUPLICATES FROM lt_conflict COMPARING conid vrsio.

*-- Load the Proposed mitigation that we do not want to delete
  if not lt_conpmit[] is initial.
   SELECT *
   FROM /psyng/conpmit
   INTO TABLE lt_conpmit_t
   FOR ALL ENTRIES IN lt_conpmit WHERE
   conid = lt_conpmit-conid
   AND contid <> i_contid.
  endif.
  LOOP AT lt_conflict.
    CLEAR lt_conflict-contid .
    CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
         EXPORTING
              wa_conflict           = lt_conflict
              i_vrsio               = lt_conflict-vrsio
         TABLES
              conpmit               = lt_conpmit_t
         EXCEPTIONS
              target_not_specified  = 1
              target_already_exists = 2
              not_authorized        = 3
              locked                = 4
              OTHERS                = 5.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                   RAISING not_exist.
      WHEN 3.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                   RAISING not_authorized.
      WHEN 4.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                   RAISING locked.
    ENDCASE.
  ENDLOOP.

* Delete texts
  DELETE FROM /psyng/texts WHERE textname = i_contid"#EC CI_IMUD_NESTED
                                     AND object   = 'M'.
  COMMIT WORK.

  CALL FUNCTION 'DEQUEUE_/PSYNG/MCHDR'
       EXPORTING
            contid = i_contid.
ENDFUNCTION.
