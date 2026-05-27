  FUNCTION /psyng/sw_cr_add_cri_profiles.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(APPEND_FLAG) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(CRIPROF_ADDED) TYPE  FLAG
*"     VALUE(CRIPROF_MODIF) TYPE  FLAG
*"     VALUE(CRIPROF_DEL) TYPE  FLAG
*"     VALUE(CRITXT_ADDED) TYPE  FLAG
*"  TABLES
*"      CRIPROF STRUCTURE  /PSYNG/CRIPROF OPTIONAL
*"      TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"  EXCEPTIONS
*"      EMPTY_LIST_PROVIDED
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_ADD_CRI_PROFILES'.
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
  DATA: criprof1 TYPE STANDARD TABLE OF /psyng/criprof
        WITH HEADER LINE,
        l_objid       TYPE cdhdr-objectid,
        ls_criprof_n TYPE /psyng/criprof,
        ls_criprof_o TYPE /psyng/criprof,
        ls_crirole   type /PSYNG/CRIROLES,
        ls_critcode  type /PSYNG/CRITCODES,
        l_modif TYPE flag.

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
  criprof_added = 'N'.
  criprof_modif = 'N'.
  criprof_del = 'N'.
  critxt_added = 'N'.


*  IF criprof[] IS INITIAL.
*    RAISE empty_list_provided.
*  ENDIF.

*  AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
*           ID 'ACTVT' FIELD 'UL'
*           ID 'Y&SW_VRSIO' FIELD i_vrsio.
*  IF sy-subrc NE 0.
*    RAISE not_authorized_to_import.
*  ENDIF.
  IF criprof IS REQUESTED.
**** Delete Blank Entries from table
    DELETE criprof WHERE profile = space.

*  *   get existing profiles

    SELECT * FROM /psyng/criprof INTO TABLE criprof1
    WHERE vrsio = i_vrsio.
    SORT criprof1 BY profile.

    IF append_flag NE 'X'.
*--Delete Old Profiles that no longer exist
      LOOP AT criprof1.
        READ TABLE criprof WITH KEY profile = criprof1-profile
                                    vrsio = criprof1-vrsio.
        CHECK sy-subrc <> 0.
        CONCATENATE criprof1-vrsio criprof1-profile INTO l_objid.
        DELETE FROM /psyng/criprof                  "#EC CI_IMUD_NESTED
                      WHERE vrsio = i_vrsio AND
                            profile = criprof1-profile.
        IF sy-subrc = 0.
          DELETE FROM /psyng/texts                  "#EC CI_IMUD_NESTED
                      WHERE textname = criprof1-profile
                      AND   object   = 'P'
                      AND   vrsio    = i_vrsio
                      AND   spras    = sy-langu.

          criprof_del = 'Y'.
          ls_criprof_o = criprof1.
          CALL FUNCTION '/PSYNG/CRIT_OBJ_WRITE_DOCUMENT' IN UPDATE TASK
            EXPORTING
              objectid                      = l_objid
              tcode                         = sy-tcode
              utime                         = sy-uzeit
              udate                         = sy-datum
              username                      = l_current_user "C0700
*       PLANNED_CHANGE_NUMBER         = ' '
             object_change_indicator       = 'D'
             planned_or_real_changes       = 'R'
*       NO_CHANGE_POINTERS            = ' '
            n_psyng_criprof               = ls_criprof_n
            o_psyng_criprof               = ls_criprof_o
           upd_psyng_criprof             = 'D'
            N_PSYNG_CRIROLES        = ls_crirole
            O_PSYNG_CRIROLES        = ls_crirole
            UPD_PSYNG_CRIROLES    = ' '
            N_PSYNG_CRITCODES       = ls_critcode
            O_PSYNG_CRITCODES       = ls_critcode
            UPD_PSYNG_CRITCODES     = ' '


            TABLES
              icdtxt_crit_obj               = lt_cdtxt
                    .
          COMMIT WORK.
          CLEAR : ls_criprof_o.

        ENDIF.

      ENDLOOP.
    ENDIF.

    LOOP AT criprof.
      READ TABLE criprof1 WITH KEY profile = criprof-profile
                                   vrsio = criprof-vrsio.
      IF sy-subrc = 0.
        criprof_modif = 'Y'.
        IF NOT criprof-imp EQ criprof1-imp.
          l_modif = 'X'.
        ELSE.
          IF NOT criprof-owner EQ criprof1-owner.
            l_modif = 'X'.
          ENDIF.
        ENDIF.
        IF l_modif = 'X'.
          CONCATENATE criprof-vrsio criprof-profile INTO l_objid.
*        criroles-change_usr = sy-uname.
*        criroles-change_dat = sy-datum.
*        criroles-change_tim = sy-uzeit.
          MODIFY /psyng/criprof FROM criprof.       "#EC CI_IMUD_NESTED
          IF sy-subrc = 0.
            criprof_modif = 'Y'.
**      Record update in database/change document
            ls_criprof_n = criprof.
            ls_criprof_o = criprof1.
          CALL FUNCTION '/PSYNG/CRIT_OBJ_WRITE_DOCUMENT' IN UPDATE TASK
                          EXPORTING
                            objectid                      = l_objid
                            tcode                      = sy-tcode
                            utime                      = sy-uzeit
                            udate                      = sy-datum
                            username                   = l_current_user
*       PLANNED_CHANGE_NUMBER         = ' '
                           object_change_indicator       = 'U'
                           planned_or_real_changes       = 'R'
*       NO_CHANGE_POINTERS            = ' '
*       UPD_ICDTXT_CRIT_OBJ           = ' '
                      n_psyng_criprof               = ls_criprof_n
                      o_psyng_criprof               = ls_criprof_o
                     upd_psyng_criprof             = 'U'
            N_PSYNG_CRIROLES        = ls_crirole
            O_PSYNG_CRIROLES        = ls_crirole
            UPD_PSYNG_CRIROLES    = ' '
            N_PSYNG_CRITCODES       = ls_critcode
            O_PSYNG_CRITCODES       = ls_critcode
            UPD_PSYNG_CRITCODES     = ' '
            TABLES
                            icdtxt_crit_obj               = lt_cdtxt
                                  .

            CLEAR : ls_criprof_n, ls_criprof_o ,l_modif.
            COMMIT WORK.
*          DELETE criprof.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.

    IF NOT criprof[] IS INITIAL.
*    return-type = 'W'.
*    return-message = text-019.
*  ELSE.
      SORT criprof.
      LOOP AT criprof.
        criprof-vrsio      = i_vrsio.
*      criroles-create_usr = sy-uname.
*      criroles-create_dat = sy-datum.
*      criroles-create_tim = sy-uzeit.
*      CLEAR: criroles-change_usr, criroles-change_dat,
*             criroles-change_tim.
        MODIFY criprof.
        CONCATENATE criprof-vrsio criprof-profile INTO l_objid.
        INSERT /psyng/criprof FROM criprof.         "#EC CI_IMUD_NESTED
        IF sy-subrc = 0.
          criprof_added = 'Y'.
***   Record insert in Database / change doc
          ls_criprof_n = criprof.
*       ls_criroles_o = criprof1.
          CALL FUNCTION '/PSYNG/CRIT_OBJ_WRITE_DOCUMENT' IN UPDATE TASK
            EXPORTING
              objectid                      = l_objid
              tcode                         = sy-tcode
              utime                         = sy-uzeit
              udate                         = sy-datum
              username                      = l_current_user " C0700
*       PLANNED_CHANGE_NUMBER         = ' '
             object_change_indicator       = 'I'
             planned_or_real_changes       = 'R'
*       NO_CHANGE_POINTERS            = ' '
*       UPD_ICDTXT_CRIT_OBJ           = ' '
          n_psyng_criprof               = ls_criprof_n
          o_psyng_criprof               = ls_criprof_o
         upd_psyng_criprof             = 'I'
            N_PSYNG_CRIROLES        = ls_crirole
            O_PSYNG_CRIROLES        = ls_crirole
            UPD_PSYNG_CRIROLES    = ' '
            N_PSYNG_CRITCODES       = ls_critcode
            O_PSYNG_CRITCODES       = ls_critcode
            UPD_PSYNG_CRITCODES     = ' '

            TABLES
              icdtxt_crit_obj               = lt_cdtxt
                    .

          CLEAR : ls_criprof_n.
          COMMIT WORK.
        ENDIF.
      ENDLOOP.

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
          <text>-object = 'P'.
          add 1 to l_idx.
        endloop.
      endloop.
    endloop.


*    SORT texts BY textname spras.
*    LOOP AT texts.
*      AT NEW textname.
**-- Handle one critical prof at time for multi lang support
*        LOOP AT texts ASSIGNING <text> WHERE textname = texts-textname.
*          AT NEW spras.
*            l_idx = 0.
*          ENDAT.
*          ADD 1 TO l_idx.
*          <text>-line = l_idx.
*          <text>-object = 'P'.
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
    LOOP AT criprof.
      LOOP AT lt_spras.
        READ TABLE texts WITH KEY textname = criprof-profile.
        IF sy-subrc = 0.
          DELETE FROM /psyng/texts                  "#EC CI_IMUD_NESTED
                      WHERE textname = criprof-profile
                    AND  object   = 'P'
                    AND   vrsio    = i_vrsio
                    AND   spras    = lt_spras.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
    IF sy-subrc NE 0.
      LOOP AT lt_spras.
        DELETE FROM /psyng/texts
                WHERE object   = 'P'
              AND   vrsio    = i_vrsio
              AND   spras  = lt_spras.
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

  REFRESH criprof.
  CLEAR criprof.

  COMMIT WORK.

ENDFUNCTION.
