FUNCTION /psyng/sw_cr_add_cri_auths.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(WA_SWAUDID) TYPE  /PSYNG/SWAUDHDR
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SWAUDHDR-VRSIO OPTIONAL
*"     VALUE(F_CAT) TYPE  CHAR1 OPTIONAL
*"     VALUE(FLAG) TYPE  CHAR1 OPTIONAL
*"  EXPORTING
*"     VALUE(CRIAUTH_ADDED) TYPE  CHAR1
*"     VALUE(CRIAUTH_HDR_ADDED) TYPE  CHAR1
*"     VALUE(CRIAUTH_TXT_ADDED) TYPE  CHAR1
*"     VALUE(CRIAUTH_OBJS_ADDED) TYPE  CHAR1
*"  TABLES
*"      TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"      SWAUDC2 STRUCTURE  /PSYNG/SWAUDC2 OPTIONAL
*"      HISTORY STRUCTURE  /PSYNG/HISTORY OPTIONAL
*"  EXCEPTIONS
*"      TARGET_NOT_SPECIFIED
*"      NOT_AUTHORIZED
*"      AUTHID_ALREADY_EXISTS
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_ADD_CRI_AUTHS'.
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
*  DATA: lt_functtran LIKE TABLE OF /psyng/functtran WITH HEADER LINE.
  DATA: lt_tcode TYPE SORTED TABLE OF /psyng/functtran WITH UNIQUE KEY
        tcode WITH HEADER LINE,
        lt_swaudc2 TYPE SORTED TABLE OF /psyng/swaudc2
        WITH UNIQUE KEY
        tcode object valueset field val_from val_to
        WITH HEADER LINE,
         ls_swaudhdr_n TYPE /psyng/swaudhdr,
         ls_swaudhdr_o TYPE /psyng/swaudhdr,
         ls_swaudc2_n  TYPE /psyng/swaudc2,
         ls_swaudc2_o  TYPE /psyng/swaudc2,
         l_objid       TYPE cdhdr-objectid.

  DATA: BEGIN OF lt_cdtxt OCCURS 0.
          INCLUDE STRUCTURE cdtxt.
  DATA: END OF lt_cdtxt.
  .
  DATA: updatetype(1).
* BOC by RGUPTA on 07.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700
  criauth_added      = 'N'.
  criauth_hdr_added  = 'N'.
  criauth_txt_added  = 'N'.
  criauth_objs_added = 'N'.



  IF wa_swaudid IS INITIAL.
    RAISE target_not_specified.
    "EXIT.
  ENDIF.
*Sort data tables
  SORT : swaudc2.

  CONCATENATE wa_swaudid-vrsio wa_swaudid-swaudid INTO l_objid.


*Check if CA Exists
  wa_swaudid-change_usr = l_current_user. "sy-uname. C0700
  wa_swaudid-change_dat = sy-datum.
  wa_swaudid-change_tim = sy-uzeit.
  SELECT SINGLE * FROM /psyng/swaudhdr               "#EC CI_SEL_NESTED
                  WHERE swaudid  = wa_swaudid-swaudid
                  AND vrsio      = i_vrsio.



  IF sy-subrc <> 0.
    wa_swaudid-create_usr = l_current_user. "sy-uname. C0700
    wa_swaudid-create_dat = sy-datum.
    wa_swaudid-create_tim = sy-uzeit.
    INSERT /psyng/swaudhdr FROM wa_swaudid.         "#EC CI_IMUD_NESTED
    IF sy-subrc = 0.
*      COMMIT WORK.
      criauth_added = 'Y'.      "if new record inserted
*     Record Insert in change document
*      updatetype = 'I'.
      ls_swaudhdr_n = wa_swaudid.
      CALL FUNCTION '/PSYNG/SWAUD_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user"sy-uname C0700
                object_change_indicator = 'I'
                planned_or_real_changes = 'R'
                n_psyng_swaudc2         = ls_swaudc2_n
                o_psyng_swaudc2         = ls_swaudc2_o
                n_psyng_swaudhdr        = ls_swaudhdr_n
                o_psyng_swaudhdr        = ls_swaudhdr_o
                upd_psyng_swaudhdr      = 'I'
           TABLES
                icdtxt_swaud            = lt_cdtxt.
         COMMIT WORK. "(++)HBHALLA(PN-5886)(Issue1)(18/02/26)
      CLEAR : ls_swaudhdr_n.
    ENDIF.
  ELSE.
    CHECK flag IS INITIAL."append only is initial
    wa_swaudid-create_usr = /psyng/swaudhdr-create_usr.
    wa_swaudid-create_dat = /psyng/swaudhdr-create_dat.
    wa_swaudid-create_tim = /psyng/swaudhdr-create_tim.
    MODIFY /psyng/swaudhdr FROM wa_swaudid.         "#EC CI_IMUD_NESTED
    IF sy-subrc = 0.
*      COMMIT WORK.
      criauth_hdr_added = 'Y'.   "if existing record modified
*     Record Change in change document
      ls_swaudhdr_o = /psyng/swaudhdr.
      ls_swaudhdr_n = wa_swaudid.
      CALL FUNCTION '/PSYNG/SWAUD_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user"sy-uname C0700
                object_change_indicator = 'U'
                planned_or_real_changes = 'R'
                n_psyng_swaudc2         = ls_swaudc2_n
                o_psyng_swaudc2         = ls_swaudc2_o
                n_psyng_swaudhdr        = ls_swaudhdr_n
                o_psyng_swaudhdr        = ls_swaudhdr_o
                upd_psyng_swaudhdr      = 'U'
           TABLES
                icdtxt_swaud            = lt_cdtxt.
      COMMIT WORK.
      CLEAR: ls_swaudhdr_o, ls_swaudhdr_n.
    ENDIF.
  ENDIF.
  CHECK sy-subrc = 0.
*--Critical Auth Description
  IF texts IS REQUESTED.
    FIELD-SYMBOLS : <text> TYPE /psyng/texts.
    DATA : lt_spras TYPE TABLE OF spras WITH HEADER LINE.
    DATA : l_idx LIKE sy-tabix.
*--Init language
   texts-spras = sy-langu.
   modify texts transporting spras where spras is initial.

*--Collect all languages
    LOOP AT texts ASSIGNING <text>.
      lt_spras = <text>-spras.
      COLLECT lt_spras.
    endloop.
    IF lt_spras[] IS INITIAL.
      lt_spras = sy-langu.
      COLLECT lt_spras.
    ENDIF.

*--assign line nr's per language
    loop at lt_spras.
      l_idx = 1.
      LOOP AT texts ASSIGNING <text> where spras = lt_spras.
        <text>-line = l_idx.
        <text>-object = 'T'.
        add 1 to l_idx.
      endloop.
    endloop.
*    LOOP AT texts ASSIGNING <text>.
*      ADD 1 TO l_idx.
*
**---- Om Changes SE3.2 14/01/2016
*      AT NEW spras.
*        l_idx = 0.
*      ENDAT.
**        End
*
*      <text>-line = l_idx.
*      <text>-object = 'T'.
*      IF <text>-spras IS INITIAL.
**     If language is not specified, use logon language
*        <text>-spras = sy-langu.
*      ENDIF.
*      lt_spras = <text>-spras.
*      COLLECT lt_spras.
*    ENDLOOP.
*    IF lt_spras[] IS INITIAL.
*      lt_spras = sy-langu.
*      COLLECT lt_spras.
*    ENDIF.

*Delete old text for all languages that where encountered in the text
*table
*    IF f_cat EQ 'X'.
    LOOP AT lt_spras.
      DELETE FROM /psyng/texts                      "#EC CI_IMUD_NESTED
                WHERE textname = wa_swaudid-swaudid
                AND   object   = 'T'
                AND   vrsio    = i_vrsio
                AND   spras    = lt_spras.
    ENDLOOP.
*    ENDIF.
    IF NOT texts[] IS INITIAL.
      INSERT /psyng/texts FROM TABLE texts.         "#EC CI_IMUD_NESTED
      IF sy-subrc = 0.
        criauth_txt_added = 'Y'.
*     There are No Change documents for texts.
      ENDIF.
    ENDIF.
  ENDIF.



*--Function Objects
  IF swaudc2 IS REQUESTED.
    IF criauth_added = 'Y'.
*DHORIONS 20130527 - Checking for existing objects should happen when a
*                    ca is being changed, not when it's being created
      FREE : lt_swaudc2[].
    ELSE.
*   get existing objects
      SELECT DISTINCT tcode object                   "#EC CI_SEL_NESTED
            valueset field val_from val_to
      INTO CORRESPONDING FIELDS OF TABLE lt_swaudc2 FROM /psyng/swaudc2
                        WHERE vrsio  = i_vrsio
                        AND swaudid    = wa_swaudid-swaudid.
    ENDIF.
*--Delete Old records that no longer exist
    LOOP AT lt_swaudc2 INTO ls_swaudc2_o.
      READ TABLE swaudc2 WITH KEY
        tcode    = ls_swaudc2_o-tcode
        object   = ls_swaudc2_o-object
        valueset = ls_swaudc2_o-valueset
        field    = ls_swaudc2_o-field
        val_from = ls_swaudc2_o-val_from
        val_to   = ls_swaudc2_o-val_to.
      CHECK sy-subrc <> 0.
      DELETE FROM /psyng/swaudc2 WHERE              "#EC CI_IMUD_NESTED
      vrsio    = i_vrsio AND
      swaudid  = wa_swaudid-swaudid AND
      tcode    = ls_swaudc2_o-tcode AND
      object   = ls_swaudc2_o-object AND
      valueset = ls_swaudc2_o-valueset AND
      field    = ls_swaudc2_o-field AND
      val_from = ls_swaudc2_o-val_from AND
      val_to   = ls_swaudc2_o-val_to.
      IF sy-subrc = 0.
*       Record Delete in change document
        CALL FUNCTION '/PSYNG/SWAUD_WRITE_DOCUMENT' IN UPDATE TASK
             EXPORTING
                  objectid                = l_objid
                  tcode                   = sy-tcode
                  utime                   = sy-uzeit
                  udate                   = sy-datum
                  username                = l_current_user"sy-unameC0700
                  object_change_indicator = 'D'
                  planned_or_real_changes = 'R'
                  n_psyng_swaudc2         = ls_swaudc2_n
                  o_psyng_swaudc2         = ls_swaudc2_o
                  upd_psyng_swaudc2       = 'D'
                  n_psyng_swaudhdr        = ls_swaudhdr_n
                  o_psyng_swaudhdr        = ls_swaudhdr_o
             TABLES
                  icdtxt_swaud            = lt_cdtxt.
        CLEAR ls_swaudc2_o.

      ENDIF.
    ENDLOOP.
  ENDIF.
  LOOP AT swaudc2.
    READ TABLE lt_swaudc2 WITH KEY
      tcode    = swaudc2-tcode
      object   = swaudc2-object
      valueset = swaudc2-valueset
      field    = swaudc2-field
      val_from = swaudc2-val_from
      val_to   = swaudc2-val_to.
    IF sy-subrc = 0.
*when comparing the fields, ignore the change dates
*     Did the record really change
      IF lt_swaudc2 <> swaudc2.
        swaudc2-create_usr = lt_swaudc2-create_usr.
        swaudc2-create_dat = lt_swaudc2-create_dat.
        swaudc2-create_tim = lt_swaudc2-create_tim.
        MODIFY /psyng/swaudc2 FROM swaudc2.         "#EC CI_IMUD_NESTED
        criauth_objs_added = 'Y'.
*         Record Change in change document
        ls_swaudc2_n = swaudc2.
        ls_swaudc2_o = lt_swaudc2.
        CALL FUNCTION '/PSYNG/SWAUD_WRITE_DOCUMENT' IN UPDATE TASK
             EXPORTING
                  objectid                = l_objid
                  tcode                   = sy-tcode
                  utime                   = sy-uzeit
                  udate                   = sy-datum
                  username                = l_current_user"sy-unameC0700
                  object_change_indicator = 'U'
                  planned_or_real_changes = 'R'
                  n_psyng_swaudc2         = ls_swaudc2_n
                  o_psyng_swaudc2         = ls_swaudc2_o
                  upd_psyng_swaudc2       = 'U'
                  n_psyng_swaudhdr        = ls_swaudhdr_n
                  o_psyng_swaudhdr        = ls_swaudhdr_o
             TABLES
                  icdtxt_swaud            = lt_cdtxt.
        CLEAR : ls_swaudc2_o , ls_swaudc2_n.

      ENDIF.
    ELSE.
      INSERT /psyng/swaudc2 FROM swaudc2.           "#EC CI_IMUD_NESTED
      criauth_objs_added = 'Y'.

*         Record Insert in change document
      ls_swaudc2_n = swaudc2.
      CALL FUNCTION '/PSYNG/SWAUD_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user"sy-uname C0700
                object_change_indicator = 'I'
                planned_or_real_changes = 'R'
                n_psyng_swaudc2         = ls_swaudc2_n
                o_psyng_swaudc2         = ls_swaudc2_o
                upd_psyng_swaudc2       = 'I'
                n_psyng_swaudhdr        = ls_swaudhdr_n
                o_psyng_swaudhdr        = ls_swaudhdr_o
           TABLES
                icdtxt_swaud            = lt_cdtxt.
      CLEAR ls_swaudc2_n.


    ENDIF.
  ENDLOOP.
ENDFUNCTION.
