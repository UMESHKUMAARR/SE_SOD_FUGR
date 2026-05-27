FUNCTION /psyng/sw_cr_add_cri_tcodes.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(APPEND_FLAG) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(CRITRAN_ADDED) TYPE  FLAG
*"     VALUE(CRITRAN_MODIF) TYPE  FLAG
*"     VALUE(CRITRAN_DEL) TYPE  FLAG
*"     VALUE(CRITXT_ADDED) TYPE  FLAG
*"  TABLES
*"      CRITCODES STRUCTURE  /PSYNG/CRITCODES OPTIONAL
*"      TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"  EXCEPTIONS
*"      NOT_AUTHORIZED_TO_IMPORT
*"      EMPTY_LIST_PROVIDED
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_ADD_CRI_TCODES'.
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
  DATA: critcodes1 TYPE STANDARD TABLE OF /psyng/critcodes
        WITH HEADER LINE,
        l_objid       TYPE cdhdr-objectid,
        ls_critcodes_n TYPE /psyng/critcodes,
        ls_critcodes_o TYPE /psyng/critcodes,
        l_modif TYPE flag.
  data :
        ls_criprof type /PSYNG/CRIPROF,
        ls_crirole type /PSYNG/CRIROLES.

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
  critran_added = 'N'.
  critran_modif = 'N'.
  critran_del = 'N'.
  critxt_added = 'N'.


*  IF critcodes[] IS INITIAL.
*    RAISE empty_list_provided.
*  ENDIF.

*  AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
*           ID 'ACTVT' FIELD 'UL'
*           ID 'Y&SW_VRSIO' FIELD i_vrsio.
*  IF sy-subrc NE 0.
*    RAISE not_authorized_to_import.
*  ENDIF.

  IF critcodes IS REQUESTED.

**** Delete Blank Entries from table
    DELETE critcodes WHERE tcode = space.

***  *   get existing tcodes


    SELECT * FROM /psyng/critcodes INTO TABLE critcodes1
    WHERE vrsio = i_vrsio.
    SORT critcodes1 BY tcode.

    IF append_flag NE 'X'. "overwrite
*--Delete Old Tcodes that no longer exist
      LOOP AT critcodes1.
        READ TABLE critcodes WITH KEY tcode = critcodes1-tcode
                                      vrsio = critcodes1-vrsio.
        CHECK sy-subrc <> 0.
        CONCATENATE critcodes1-vrsio critcodes1-tcode INTO l_objid.
        DELETE FROM /psyng/critcodes                "#EC CI_IMUD_NESTED
           WHERE vrsio = i_vrsio AND
                 tcode = critcodes1-tcode.
        IF sy-subrc = 0.
          DELETE FROM /psyng/texts                  "#EC CI_IMUD_NESTED
                      WHERE textname = critcodes1-tcode
                      AND   object   = 'X'
                      AND   vrsio    = i_vrsio
                      AND   spras    = sy-langu.
          critran_del = 'Y'.
          ls_critcodes_o = critcodes1.
          CALL FUNCTION '/PSYNG/CRIT_OBJ_WRITE_DOCUMENT' IN UPDATE TASK
            EXPORTING
              objectid                      = l_objid
              tcode                         = sy-tcode
              utime                         = sy-uzeit
              udate                         = sy-datum
              username                      = l_current_user" C0700
*       PLANNED_CHANGE_NUMBER         = ' '
             object_change_indicator       = 'D'
             planned_or_real_changes       = 'R'
*       NO_CHANGE_POINTERS            = ' '
       UPD_ICDTXT_CRIT_OBJ           = ' '
        n_psyng_criprof              = ls_criprof
        o_psyng_criprof              = ls_criprof
       UPD_PSYNG_CRIPROF             = ' '
        n_psyng_criroles             = ls_crirole
        o_psyng_criroles             = ls_crirole
       UPD_PSYNG_CRIROLES            = ' '
              n_psyng_critcodes             = ls_critcodes_n
              o_psyng_critcodes             = ls_critcodes_o
             upd_psyng_critcodes           = 'D'
            TABLES
              icdtxt_crit_obj               = lt_cdtxt
                    .
          COMMIT WORK.
          CLEAR : ls_critcodes_o.

        ENDIF.

      ENDLOOP.
    ENDIF.

    LOOP AT critcodes.
      READ TABLE critcodes1 WITH KEY tcode = critcodes-tcode
                                     vrsio = critcodes-vrsio.
      IF sy-subrc = 0.
        critran_modif = 'Y'.
        IF NOT critcodes-imp EQ critcodes1-imp.
          l_modif = 'X'.
        ELSEIF NOT critcodes-owner EQ critcodes1-owner.
          l_modif = 'X'.
        ELSE.
          IF NOT critcodes-busarea EQ critcodes1-busarea.
            l_modif = 'X'.
          ENDIF.
        ENDIF.
        IF l_modif = 'X'.
          CONCATENATE critcodes-vrsio critcodes-tcode INTO l_objid.
          critcodes-change_usr = l_current_user. "sy-uname. C0700
          critcodes-change_dat = sy-datum.
          critcodes-change_tim = sy-uzeit.
          MODIFY /psyng/critcodes FROM critcodes.   "#EC CI_IMUD_NESTED
          IF sy-subrc = 0.
            critran_modif = 'Y'.
**      Record update in database/change document
            ls_critcodes_n = critcodes.
            ls_critcodes_o = critcodes1.
          CALL FUNCTION '/PSYNG/CRIT_OBJ_WRITE_DOCUMENT' IN UPDATE TASK
                        EXPORTING
                          objectid                      = l_objid
                          tcode                         = sy-tcode
                          utime                         = sy-uzeit
                          udate                         = sy-datum
                          username                      = l_current_user
*       PLANNED_CHANGE_NUMBER         = ' '
                         object_change_indicator       = 'U'
                         planned_or_real_changes       = 'R'
                         n_psyng_critcodes             = ls_critcodes_n
                         o_psyng_critcodes             = ls_critcodes_o
                         upd_psyng_critcodes           = 'U'
                          n_psyng_criprof              = ls_criprof
                          o_psyng_criprof              = ls_criprof
                         UPD_PSYNG_CRIPROF             = ' '
                          n_psyng_criroles             = ls_crirole
                          o_psyng_criroles             = ls_crirole
                         UPD_PSYNG_CRIROLES            = ' '

                        TABLES
                          icdtxt_crit_obj               = lt_cdtxt
                                .

            CLEAR : ls_critcodes_n, ls_critcodes_o ,l_modif.
            COMMIT WORK.
*          DELETE critcodes.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.

    IF NOT critcodes[] IS INITIAL.
*    return-type = 'W'.
*    return-message = text-019.
*  ELSE.
      SORT critcodes.
      LOOP AT critcodes.
        critcodes-vrsio      = i_vrsio.
        critcodes-create_usr = l_current_user. "sy-uname. C0700
        critcodes-create_dat = sy-datum.
        critcodes-create_tim = sy-uzeit.
        CLEAR: critcodes-change_usr, critcodes-change_dat,
               critcodes-change_tim.
        MODIFY critcodes.
        CONCATENATE critcodes-vrsio critcodes-tcode INTO l_objid.
        INSERT /psyng/critcodes FROM critcodes.     "#EC CI_IMUD_NESTED
        IF sy-subrc = 0.
          critran_added = 'Y'.
***   Record insert in Database / change doc
          ls_critcodes_n = critcodes.
*       ls_critcodes_o = critcodes1.
          CALL FUNCTION '/PSYNG/CRIT_OBJ_WRITE_DOCUMENT' IN UPDATE TASK
            EXPORTING
              objectid                      = l_objid
              tcode                         = sy-tcode
              utime                         = sy-uzeit
              udate                         = sy-datum
              username                      = l_current_user "C0700
*       PLANNED_CHANGE_NUMBER         = ' '
             object_change_indicator       = 'I'
             planned_or_real_changes       = 'R'
*       NO_CHANGE_POINTERS            = ' '
              n_psyng_critcodes             = ls_critcodes_n
              o_psyng_critcodes             = ls_critcodes_o
             upd_psyng_critcodes           = 'I'
       UPD_ICDTXT_CRIT_OBJ           = ' '
        n_psyng_criprof              = ls_criprof
        o_psyng_criprof              = ls_criprof
       UPD_PSYNG_CRIPROF             = ' '
        n_psyng_criroles             = ls_crirole
        o_psyng_criroles             = ls_crirole
       UPD_PSYNG_CRIROLES            = ' '

            TABLES
              icdtxt_crit_obj               = lt_cdtxt
                    .

          CLEAR : ls_critcodes_n.
          COMMIT WORK.
        ENDIF.
      ENDLOOP.

*    INSERT /psyng/critcodes FROM critcodes.
*    IF sy-subrc = 0.
*      return-type = 'S'.
*      return-message = text-021.
*    ELSE.
*      return-type = 'E'.
*      return-message = text-023.
*    ENDIF.
    ENDIF.
  ENDIF.

  IF texts IS REQUESTED.
    FIELD-SYMBOLS : <text> TYPE /psyng/texts.
    DATA : lt_spras TYPE TABLE OF spras WITH HEADER LINE,
    lt_textnames TYPE TABLE OF /psyng/texts-textname
           WITH HEADER LINE.
    DATA : l_idx LIKE sy-tabix.
*--Init language
   texts-spras = sy-langu.
   modify texts transporting spras where spras is initial.

*--Collect all languages
    LOOP AT texts ASSIGNING <text>.
      lt_spras = <text>-spras.
      COLLECT lt_spras.
      lt_textnames = <text>-textname.
      collect lt_textnames.
    endloop.
    IF lt_spras[] IS INITIAL.
      lt_spras = sy-langu.
      COLLECT lt_spras.
    ENDIF.

*--assign line nr's per language
    loop at lt_textnames.
      loop at lt_spras.
        l_idx = 1.
        LOOP AT texts ASSIGNING <text> where spras    = lt_spras and
                                             textname = lt_textnames.
          <text>-line = l_idx.
          <text>-object = 'X'.
          add 1 to l_idx.
        endloop.
      endloop.
    endloop.

*    LOOP AT texts.
*      AT NEW textname.
*        LOOP AT texts ASSIGNING <text> WHERE textname = texts-textname.
*          AT NEW spras.
*            l_idx = 0.
*          ENDAT.
*          ADD 1 TO l_idx.
*          <text>-line = l_idx.
*          <text>-object = 'X'.
*          IF <text>-spras IS INITIAL.
**     If language is not specified, use logon language
*            <text>-spras = sy-langu.
*          ENDIF.
*          lt_spras = <text>-spras.
*          COLLECT lt_spras.
**      ENDAT.
*        ENDLOOP.
*      ENDAT.
*    ENDLOOP.
*
*    IF lt_spras[] IS INITIAL.
*      lt_spras = sy-langu.
*      COLLECT lt_spras.
*    ENDIF.
*Delete old text for all languages that where encountered in the text
*table
    LOOP AT critcodes.
      LOOP AT lt_spras.
        READ TABLE texts WITH KEY textname = critcodes-tcode.
        IF sy-subrc = 0.
          DELETE FROM /psyng/texts                  "#EC CI_IMUD_NESTED
                      WHERE textname = critcodes-tcode
                  AND  object   = 'X'
                    AND   vrsio    = i_vrsio
                    AND   spras    = lt_spras.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
    IF sy-subrc NE 0.
      LOOP AT lt_spras.
        DELETE FROM /psyng/texts
                     WHERE  object   = 'X'
                       AND   vrsio    = i_vrsio
                       AND   spras    = lt_spras.
      ENDLOOP.
    ENDIF.

    SORT texts.
    DELETE ADJACENT DUPLICATES FROM texts COMPARING ALL FIELDS.
    IF NOT texts[] IS INITIAL.
      MODIFY /psyng/texts FROM TABLE texts.
      IF sy-subrc = 0.
        REFRESH texts.
        CLEAR texts.
        critxt_added = 'Y'.
*     There are No Change documents for texts.
      ENDIF.
    ENDIF.


  ENDIF.

  REFRESH critcodes.
  CLEAR critcodes.

  COMMIT WORK.

ENDFUNCTION.
