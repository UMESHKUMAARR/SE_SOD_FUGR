FUNCTION /psyng/sw_cr_add_conflictid.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(WA_CONFLICT) TYPE  /PSYNG/CONFLICT
*"     VALUE(I_VRSIO) TYPE  /PSYNG/CONFLICT-VRSIO OPTIONAL
*"     VALUE(FLAG) TYPE  CHAR1 OPTIONAL
*"     VALUE(F_CONT) TYPE  CHAR1 OPTIONAL
*"  EXPORTING
*"     VALUE(CONID_ADDED) TYPE  CHAR1
*"     VALUE(CONID_HDR_ADDED) TYPE  CHAR1
*"     VALUE(CONID_FUN_ADDED) TYPE  CHAR1
*"     VALUE(CONID_TXT_ADDED) TYPE  CHAR1
*"     VALUE(CONOWNER_ADDED) TYPE  CHAR1
*"     VALUE(CONPMIT_ADDED) TYPE  FLAG
*"  TABLES
*"      TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"      CONFDET STRUCTURE  /PSYNG/CONFDET OPTIONAL
*"      CONOWNER STRUCTURE  /PSYNG/CONOWNER OPTIONAL
*"      CONPMIT STRUCTURE  /PSYNG/CONPMIT OPTIONAL
*"  EXCEPTIONS
*"      TARGET_NOT_SPECIFIED
*"      TARGET_ALREADY_EXISTS
*"      NOT_AUTHORIZED
*"      LOCKED
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_ADD_CONFLICTID'.
*  S_RFC AUTHORITY CHECK
* BOC BNAYAK CVA scan fix DT:05-05-2026
*  AUTHORITY-CHECK OBJECT 'S_RFC'
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
* EOC BNAYAK CVA scan fix DT:05-05-2026
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026

  DATA : lt_confdet TYPE SORTED TABLE OF /psyng/confdet
          WITH HEADER LINE WITH UNIQUE KEY conid functionid,
         lt_conowner TYPE SORTED TABLE OF /psyng/conowner
         WITH HEADER LINE WITH UNIQUE KEY conid owner company ma_email,
         lt_conpmit TYPE SORTED TABLE OF /psyng/conpmit
         WITH HEADER LINE WITH UNIQUE KEY conid contid company,
         ls_conflict_n TYPE /psyng/conflict,
         ls_conflict_o TYPE /psyng/conflict,
         ls_confdet_n  TYPE /psyng/confdet,
         ls_confdet_o  TYPE /psyng/confdet,
         ls_conowner_n TYPE /psyng/conowner,
         ls_conowner_o TYPE /psyng/conowner,
         ls_conpmit_n TYPE /psyng/conpmit,
         ls_conpmit_o TYPE /psyng/conpmit,
         l_objid       TYPE cdhdr-objectid.

  DATA: BEGIN OF lt_cdtxt OCCURS 0.
          INCLUDE STRUCTURE cdtxt.
  DATA: END OF lt_cdtxt.
* BOC by RGUPTA on 07.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700

  conid_added       = 'N'.
  conid_hdr_added   = 'N'.
  conid_fun_added   = 'N'.
  conid_txt_added   = 'N'.
  conowner_added    = 'N'.
  conpmit_added     = 'N'.


  IF wa_conflict IS INITIAL.
    RAISE target_not_specified.
    "EXIT.
  ENDIF.

* Sort data tables
  SORT : confdet, conowner,conpmit.



  CONCATENATE wa_conflict-vrsio wa_conflict-conid INTO l_objid.

* Lock conflict ID
  CALL FUNCTION 'ENQUEUE_/PSYNG/CONFLICT'
       EXPORTING
            conid          = wa_conflict-conid
            vrsio          = i_vrsio
       EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
            RAISING locked.
    EXIT.
  ENDIF.

  wa_conflict-change_usr = l_current_user."sy-uname. C0700
  wa_conflict-change_dat = sy-datum.
  wa_conflict-change_tim = sy-uzeit.
  SELECT SINGLE * FROM /psyng/conflict               "#EC CI_SEL_NESTED
                  WHERE conid = wa_conflict-conid
                  AND vrsio      = i_vrsio.



  IF sy-subrc <> 0.
    IF flag NE 'X'.
      wa_conflict-create_usr = l_current_user. "sy-uname. C0700
      wa_conflict-create_dat = sy-datum.
      wa_conflict-create_tim = sy-uzeit.
    ENDIF.
    INSERT /psyng/conflict FROM wa_conflict.        "#EC CI_IMUD_NESTED
    IF sy-subrc = 0.
      conid_added = 'Y'.      "if new record inserted
*     Record Insert in change document
      ls_conflict_n = wa_conflict.
      CALL FUNCTION '/PSYNG/CONFLICT_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user"sy-uname C0700
                object_change_indicator = 'I'
                planned_or_real_changes = 'R'
                n_psyng_confdet         = ls_confdet_n
                o_psyng_confdet         = ls_confdet_o
                n_psyng_conflict        = ls_conflict_n
                o_psyng_conflict        = ls_conflict_o
                upd_psyng_conflict      = 'I'
                n_psyng_conowner        = ls_conowner_n
                o_psyng_conowner        = ls_conowner_o
*--DHORIONS 2017/01/06 - Added because of Certification Syntax checks
                n_psyng_conpmit         = ls_conpmit_n
                o_psyng_conpmit         = ls_conpmit_o
                upd_psyng_conpmit       = ' '
           TABLES
                icdtxt_conflict         = lt_cdtxt.

      CLEAR ls_conflict_n.
    ENDIF.
  ELSE.
    CHECK flag IS INITIAL.
    wa_conflict-create_usr = /psyng/conflict-create_usr.
    wa_conflict-create_dat = /psyng/conflict-create_dat.
    wa_conflict-create_tim = /psyng/conflict-create_tim.
    MODIFY /psyng/conflict FROM wa_conflict.        "#EC CI_IMUD_NESTED
    IF sy-subrc = 0.
      conid_hdr_added = 'Y'.   "if existing record modified
*     Record Change in change document
      ls_conflict_o = /psyng/conflict.
      ls_conflict_n = wa_conflict.
      CALL FUNCTION '/PSYNG/CONFLICT_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user"sy-uname C0700
                object_change_indicator = 'U'
                planned_or_real_changes = 'R'
                n_psyng_confdet         = ls_confdet_n
                o_psyng_confdet         = ls_confdet_o
                n_psyng_conflict        = ls_conflict_n
                o_psyng_conflict        = ls_conflict_o
                upd_psyng_conflict      = 'U'
                n_psyng_conowner        = ls_conowner_n
                o_psyng_conowner        = ls_conowner_o
*--DHORIONS 2017/01/06 - Added because of Certification Syntax checks
                n_psyng_conpmit         = ls_conpmit_n
                o_psyng_conpmit         = ls_conpmit_o
                upd_psyng_conpmit       = ' '

           TABLES
                icdtxt_conflict         = lt_cdtxt.

      CLEAR: ls_conflict_o, ls_conflict_n.
    ENDIF.
  ENDIF.
*  CHECK sy-subrc = 0.
*--Functions
  IF confdet IS REQUESTED.
    IF conid_added = 'Y'.
      FREE : lt_confdet.
    ELSE.
*   get existing functions
      SELECT * INTO TABLE lt_confdet                 "#EC CI_SEL_NESTED
             FROM /psyng/confdet
                        WHERE vrsio    = i_vrsio
                        AND conid      = wa_conflict-conid.
    ENDIF.
    SORT confdet by conid functionid.
*--Delete Old Functions that no longer exist
    LOOP AT lt_confdet INTO ls_confdet_o.
      READ TABLE confdet
                 WITH KEY functionid = ls_confdet_o-functionid
      BINARY SEARCH TRANSPORTING NO FIELDS.
      CHECK sy-subrc <> 0.
*--DHORIONS :delete statement was commented out for case 2671,
*             uncommented by Dries to make it possible to remove
*             functions from conflicts
      DELETE FROM /psyng/confdet                    "#EC CI_IMUD_NESTED
                    WHERE vrsio = i_vrsio AND
                          conid      =  wa_conflict-conid AND
                          functionid =  ls_confdet_o-functionid
.
      IF sy-subrc = 0.
*       Record Delete in change document
        CALL FUNCTION '/PSYNG/CONFLICT_WRITE_DOCUMENT' IN UPDATE TASK
             EXPORTING
                  objectid                = l_objid
                  tcode                   = sy-tcode
                  utime                   = sy-uzeit
                  udate                   = sy-datum
                  username                = l_current_user"sy-unameC0700
                  object_change_indicator = 'D'
                  planned_or_real_changes = 'R'
                  n_psyng_confdet         = ls_confdet_n
                  o_psyng_confdet         = ls_confdet_o
                  upd_psyng_confdet       = 'D'
                  n_psyng_conflict        = ls_conflict_n
                  o_psyng_conflict        = ls_conflict_o
                  n_psyng_conowner        = ls_conowner_n
                  o_psyng_conowner        = ls_conowner_o
*--DHORIONS 2017/01/06 - Added because of Certification Syntax checks
                n_psyng_conpmit         = ls_conpmit_n
                o_psyng_conpmit         = ls_conpmit_o
                upd_psyng_conpmit       = ' '

             TABLES
                  icdtxt_conflict         = lt_cdtxt.

        CLEAR ls_confdet_o.
      ENDIF.
    ENDLOOP.
*--Add new functions

    LOOP AT confdet WHERE conid = wa_conflict-conid.
      READ TABLE lt_confdet WITH TABLE KEY
        conid      = wa_conflict-conid
        functionid = confdet-functionid
        TRANSPORTING NO FIELDS.
      CHECK sy-subrc <> 0.
      INSERT /psyng/confdet FROM confdet.           "#EC CI_IMUD_NESTED
      IF sy-subrc = 0.
        conid_fun_added   = 'Y'.

*       Record Insert in change document
        ls_confdet_n = confdet.
        CALL FUNCTION '/PSYNG/CONFLICT_WRITE_DOCUMENT' IN UPDATE TASK
             EXPORTING
                  objectid                = l_objid
                  tcode                   = sy-tcode
                  utime                   = sy-uzeit
                  udate                   = sy-datum
                  username                = l_current_user"sy-unameC0700
                  object_change_indicator = 'I'
                  planned_or_real_changes = 'R'
                  n_psyng_confdet         = ls_confdet_n
                  o_psyng_confdet         = ls_confdet_o
                  upd_psyng_confdet       = 'I'
                  n_psyng_conflict        = ls_conflict_n
                  o_psyng_conflict        = ls_conflict_o
                  n_psyng_conowner        = ls_conowner_n
                  o_psyng_conowner        = ls_conowner_o
*--DHORIONS 2017/01/06 - Added because of Certification Syntax checks
                n_psyng_conpmit         = ls_conpmit_n
                o_psyng_conpmit         = ls_conpmit_o
                upd_psyng_conpmit       = ' '

             TABLES
                  icdtxt_conflict         = lt_cdtxt.

        CLEAR ls_confdet_n.
      ENDIF.
    ENDLOOP.
  ENDIF.
  IF conowner IS REQUESTED.
    IF conid_added = 'Y'.
      FREE : lt_conowner.
    ELSE.
*   get existing owners
      SELECT * INTO TABLE lt_conowner                "#EC CI_SEL_NESTED
               FROM /psyng/conowner
                        WHERE vrsio    = i_vrsio
                        AND   conid      = wa_conflict-conid.
    ENDIF.
*--Delete Old owners that no longer exist
    SORT conowner.
    LOOP AT lt_conowner.
      READ TABLE conowner WITH KEY owner   = lt_conowner-owner
                                   company = lt_conowner-company
                                   ma_email = lt_conowner-ma_email
      BINARY SEARCH TRANSPORTING NO FIELDS.
      CHECK sy-subrc <> 0.
      DELETE FROM /psyng/conowner                   "#EC CI_IMUD_NESTED
             WHERE vrsio = i_vrsio AND
                   conid       = wa_conflict-conid AND
                   owner       = lt_conowner-owner  AND
                   company     = lt_conowner-company.
      IF sy-subrc = 0.
*       Record Delete in change document
        ls_conowner_o = lt_conowner.
        CALL FUNCTION '/PSYNG/CONFLICT_WRITE_DOCUMENT' IN UPDATE TASK
             EXPORTING
                  objectid                = l_objid
                  tcode                   = sy-tcode
                  utime                   = sy-uzeit
                  udate                   = sy-datum
                  username                = l_current_user"sy-unameC0700
                  object_change_indicator = 'D'
                  planned_or_real_changes = 'R'
                  n_psyng_confdet         = ls_confdet_n
                  o_psyng_confdet         = ls_confdet_o
                  n_psyng_conflict        = ls_conflict_n
                  o_psyng_conflict        = ls_conflict_o
                  n_psyng_conowner        = ls_conowner_n
                  o_psyng_conowner        = ls_conowner_o
                  upd_psyng_conowner      = 'D'
*--DHORIONS 2017/01/06 - Added because of Certification Syntax checks
                n_psyng_conpmit         = ls_conpmit_n
                o_psyng_conpmit         = ls_conpmit_o
                upd_psyng_conpmit       = ' '

             TABLES
                  icdtxt_conflict         = lt_cdtxt.

        CLEAR ls_conowner_o.
      ENDIF.
    ENDLOOP.
*--Add new owners

    LOOP AT conowner WHERE conid = wa_conflict-conid.
      READ TABLE lt_conowner WITH TABLE KEY
        conid   = wa_conflict-conid
        owner   = conowner-owner
        company = conowner-company
        ma_email = conowner-ma_email
        TRANSPORTING NO FIELDS.
      CHECK sy-subrc <> 0.
      INSERT /psyng/conowner FROM conowner.         "#EC CI_IMUD_NESTED
      IF sy-subrc = 0.
        conowner_added   = 'Y'.

*       Record Insert in change document
        ls_conowner_n = conowner.
        CALL FUNCTION '/PSYNG/CONFLICT_WRITE_DOCUMENT' IN UPDATE TASK
             EXPORTING
                  objectid                = l_objid
                  tcode                   = sy-tcode
                  utime                   = sy-uzeit
                  udate                   = sy-datum
                  username                = l_current_user"sy-unameC0700
                  object_change_indicator = 'I'
                  planned_or_real_changes = 'R'
                  n_psyng_confdet         = ls_confdet_n
                  o_psyng_confdet         = ls_confdet_o
                  n_psyng_conflict        = ls_conflict_n
                  o_psyng_conflict        = ls_conflict_o
                  n_psyng_conowner        = ls_conowner_n
                  o_psyng_conowner        = ls_conowner_o
                  upd_psyng_conowner      = 'I'
*--DHORIONS 2017/01/06 - Added because of Certification Syntax checks
                n_psyng_conpmit         = ls_conpmit_n
                o_psyng_conpmit         = ls_conpmit_o
                upd_psyng_conpmit       = ' '

             TABLES
                  icdtxt_conflict         = lt_cdtxt.

        CLEAR ls_conowner_n.
      ENDIF.
    ENDLOOP.

  ENDIF.


  IF conpmit IS REQUESTED.
    IF conid_added = 'Y'.
      FREE : lt_conpmit.
    ELSE.
*   get existing Proposed Mits
      SELECT * INTO TABLE lt_conpmit                 "#EC CI_SEL_NESTED
               FROM /psyng/conpmit
                        WHERE vrsio    = i_vrsio
                        AND   conid      = wa_conflict-conid.
    ENDIF.
*--Delete Old Proposed Mits that no longer exist
    SORT conpmit.
    LOOP AT lt_conpmit.
      READ TABLE conpmit WITH KEY contid   = lt_conpmit-contid
                                   company = lt_conpmit-company
      BINARY SEARCH TRANSPORTING NO FIELDS.
      CHECK sy-subrc <> 0.
      DELETE FROM /psyng/conpmit                    "#EC CI_IMUD_NESTED
             WHERE vrsio = i_vrsio AND
                   conid       = wa_conflict-conid AND
                   contid       = lt_conpmit-contid  AND
                   company     = lt_conpmit-company.
      IF sy-subrc = 0.
*       Record Delete in change document
        ls_conpmit_o = lt_conpmit.
        CALL FUNCTION '/PSYNG/CONFLICT_WRITE_DOCUMENT' IN UPDATE TASK
             EXPORTING
                  objectid                = l_objid
                  tcode                   = sy-tcode
                  utime                   = sy-uzeit
                  udate                   = sy-datum
                  username                = l_current_user"sy-unameC0700
                  object_change_indicator = 'D'
                  planned_or_real_changes = 'R'
                  n_psyng_confdet         = ls_confdet_n
                  o_psyng_confdet         = ls_confdet_o
                  n_psyng_conflict        = ls_conflict_n
                  o_psyng_conflict        = ls_conflict_o
                  n_psyng_conpowner       = ls_conowner_n
                  o_psyng_conpowner       = ls_conowner_o
                  n_psyng_conpmit         = ls_conpmit_n
                  o_psyng_conpmit         = ls_conpmit_o
                  upd_psyng_conpmit       = 'D'
                  n_psyng_conowner        = ls_conowner_n
                  o_psyng_conowner        = ls_conowner_o
                  upd_psyng_conowner      = ' '
             TABLES
                  icdtxt_conflict         = lt_cdtxt.

        CLEAR ls_conpmit_o.
      ENDIF.
    ENDLOOP.
*--Add new Proposed Mits
    LOOP AT conpmit WHERE conid = wa_conflict-conid.
      READ TABLE lt_conpmit WITH TABLE KEY
        conid   = wa_conflict-conid
        contid   = conpmit-contid
        company = conpmit-company
        TRANSPORTING NO FIELDS.
      CHECK sy-subrc <> 0.
      INSERT /psyng/conpmit FROM conpmit.           "#EC CI_IMUD_NESTED
      IF sy-subrc = 0.
        conpmit_added   = 'Y'.

*       Record Insert in change document
        ls_conpmit_n = conpmit.
        CALL FUNCTION '/PSYNG/CONFLICT_WRITE_DOCUMENT' IN UPDATE TASK
             EXPORTING
                  objectid                = l_objid
                  tcode                   = sy-tcode
                  utime                   = sy-uzeit
                  udate                   = sy-datum
                  username                = l_current_user"sy-unameC0700
                  object_change_indicator = 'I'
                  planned_or_real_changes = 'R'
                  n_psyng_confdet         = ls_confdet_n
                  o_psyng_confdet         = ls_confdet_o
                  n_psyng_conflict        = ls_conflict_n
                  o_psyng_conflict        = ls_conflict_o
                  n_psyng_conpowner       = ls_conowner_n
                  o_psyng_conpowner       = ls_conowner_o
                  n_psyng_conpmit         = ls_conpmit_n
                  o_psyng_conpmit         = ls_conpmit_o
                  upd_psyng_conpmit       = 'I'
                  n_psyng_conowner        = ls_conowner_n
                  o_psyng_conowner        = ls_conowner_o
                  upd_psyng_conowner      = ' '

             TABLES
                  icdtxt_conflict         = lt_cdtxt.

        CLEAR ls_conpmit_n.
      ENDIF.
    ENDLOOP.
  ENDIF.

*--Conflict Description
  IF texts IS REQUESTED.
    FIELD-SYMBOLS : <text> TYPE /psyng/texts.
    DATA : lt_spras TYPE TABLE OF spras WITH HEADER LINE.
    DATA : l_idx LIKE sy-tabix.
*--Init language
    texts-spras = sy-langu.
    MODIFY texts TRANSPORTING spras WHERE spras IS INITIAL.
*--Collect all languages
    LOOP AT texts ASSIGNING <text>.
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
      LOOP AT texts ASSIGNING <text> WHERE spras = lt_spras.
        <text>-line = l_idx.
        <text>-object = 'C'.
        ADD 1 TO l_idx.
      ENDLOOP.
    ENDLOOP.

*Delete old text for all languages that where encountered in the text
*table
*    IF f_cont EQ 'X'.
    LOOP AT lt_spras.
      DELETE FROM /psyng/texts                      "#EC CI_IMUD_NESTED
                WHERE textname = wa_conflict-conid
                AND   object   = 'C'
                AND   vrsio    = i_vrsio
                AND   spras    = lt_spras.
    ENDLOOP.
    IF NOT texts[] IS INITIAL. "<NSINGH>++
      INSERT /psyng/texts FROM TABLE texts.         "#EC CI_IMUD_NESTED
      IF sy-subrc = 0.
        conid_txt_added = 'Y'.
*   There are No Change documents for texts.
      ENDIF.
    ENDIF. "<NSINGH>++

  ENDIF.

  COMMIT WORK AND WAIT.

  CALL FUNCTION 'DEQUEUE_/PSYNG/CONFLICT'
       EXPORTING
            conid     = wa_conflict-conid
            vrsio     = i_vrsio
            _synchron = 'X'.

  COMMIT WORK AND WAIT.
ENDFUNCTION.
