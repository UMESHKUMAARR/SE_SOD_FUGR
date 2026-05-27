FUNCTION /psyng/sw_cr_add_cri_roles.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(APPEND_FLAG) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(CRIROLE_ADDED) TYPE  FLAG
*"     VALUE(CRIROLE_MODIF) TYPE  FLAG
*"     VALUE(CRIROLE_DEL) TYPE  FLAG
*"     VALUE(CRITXT_ADDED) TYPE  FLAG
*"  TABLES
*"      CRIROLES STRUCTURE  /PSYNG/CRIROLES OPTIONAL
*"      TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"  EXCEPTIONS
*"      EMPTY_LIST_PROVIDED
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_ADD_CRI_ROLES'.
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
  DATA: criroles1 TYPE STANDARD TABLE OF /psyng/criroles
        WITH HEADER LINE,
        l_objid       TYPE cdhdr-objectid,
        ls_criroles_n TYPE /psyng/criroles,
        ls_criroles_o TYPE /psyng/criroles,
        l_modif TYPE flag,
        ls_criprof   type /PSYNG/CRIPROF,
        ls_critcode  type /PSYNG/CRITCODES.

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
  crirole_added = 'N'.
  crirole_modif = 'N'.
  crirole_del = 'N'.
  critxt_added = 'N'.



*  IF criroles[] IS INITIAL.
*    RAISE empty_list_provided.
*  ENDIF.

*  AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
*           ID 'ACTVT' FIELD 'UL'
*           ID 'Y&SW_VRSIO' FIELD i_vrsio.
*  IF sy-subrc NE 0.
*    RAISE not_authorized_to_import.
*  ENDIF.

  IF criroles IS REQUESTED.
**Delete Blank Entries from Table
    DELETE criroles WHERE agr_name = space.

    SORT criroles BY agr_name.

*  *   get existing tcodes

    SELECT * FROM /psyng/criroles INTO TABLE criroles1
    WHERE vrsio = i_vrsio.
    SORT criroles1 BY agr_name.

    IF append_flag NE 'X'.
*--Delete Old Tcodes that no longer exist
      LOOP AT criroles1.
        READ TABLE criroles WITH KEY agr_name = criroles1-agr_name
                                     vrsio = criroles1-vrsio.
        CHECK sy-subrc <> 0.
        CONCATENATE criroles1-vrsio criroles1-agr_name INTO l_objid.
        DELETE FROM /psyng/criroles                 "#EC CI_IMUD_NESTED
                       WHERE vrsio = i_vrsio AND
                             agr_name = criroles1-agr_name.
        IF sy-subrc = 0.
          DELETE FROM /psyng/texts                  "#EC CI_IMUD_NESTED
                      WHERE textname = criroles1-agr_name
                      AND   object   = 'Q'
                      AND   vrsio    = i_vrsio
                      AND   spras    = sy-langu.


          crirole_del = 'Y'.
          ls_criroles_o = criroles1.
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
*       UPD_ICDTXT_CRIT_OBJ           = ' '
            n_psyng_criroles              = ls_criroles_n
            o_psyng_criroles              = ls_criroles_o
           upd_psyng_criroles            = 'D'

            n_psyng_criprof        = ls_criprof
            o_psyng_criprof        = ls_criprof
            UPD_PSYNG_CRIPROF      = ' '
            N_PSYNG_CRITCODES      = ls_critcode
            O_PSYNG_CRITCODES      = ls_critcode
            UPD_PSYNG_CRITCODES    = ' '
            TABLES
              icdtxt_crit_obj               = lt_cdtxt
                    .
          COMMIT WORK.
          CLEAR : ls_criroles_o.

        ENDIF.

      ENDLOOP.
    ENDIF.

    LOOP AT criroles.
      READ TABLE criroles1 WITH KEY agr_name = criroles-agr_name
                                    vrsio = criroles-vrsio.
      IF sy-subrc = 0.
        crirole_modif = 'Y'.
        IF NOT criroles-imp EQ criroles1-imp.
          l_modif = 'X'.
        ELSE.
          IF NOT criroles-owner EQ criroles1-owner.
            l_modif = 'X'.
          ENDIF.
        ENDIF.
        IF l_modif = 'X'.
          CONCATENATE criroles-vrsio criroles-agr_name INTO l_objid.
*        criroles-change_usr = sy-uname.
*        criroles-change_dat = sy-datum.
*        criroles-change_tim = sy-uzeit.
          MODIFY /psyng/criroles FROM criroles.     "#EC CI_IMUD_NESTED
          IF sy-subrc = 0.
            crirole_modif = 'Y'.
**      Record update in database/change document
            ls_criroles_n = criroles.
            ls_criroles_o = criroles1.
          CALL FUNCTION '/PSYNG/CRIT_OBJ_WRITE_DOCUMENT' IN UPDATE TASK
                          EXPORTING
                            objectid                   = l_objid
                            tcode                      = sy-tcode
                            utime                      = sy-uzeit
                            udate                      = sy-datum
                            username                   = l_current_user
*       PLANNED_CHANGE_NUMBER         = ' '
                           object_change_indicator       = 'U'
                           planned_or_real_changes       = 'R'
*       NO_CHANGE_POINTERS            = ' '
                      n_psyng_criroles              = ls_criroles_n
                      o_psyng_criroles              = ls_criroles_o
                     upd_psyng_criroles            = 'U'
            n_psyng_criprof        = ls_criprof
            o_psyng_criprof        = ls_criprof
            UPD_PSYNG_CRIPROF      = ' '
            N_PSYNG_CRITCODES      = ls_critcode
            O_PSYNG_CRITCODES      = ls_critcode
            UPD_PSYNG_CRITCODES    = ' '


                          TABLES
                            icdtxt_crit_obj               = lt_cdtxt
                                  .

            CLEAR : ls_criroles_n, ls_criroles_o ,l_modif.
            COMMIT WORK.
*          DELETE criroles.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.

    IF NOT criroles[] IS INITIAL.
*    return-type = 'W'.
*    return-message = text-019.
*  ELSE.
      SORT criroles.
      LOOP AT criroles.
        criroles-vrsio      = i_vrsio.
*      criroles-create_usr = sy-uname.
*      criroles-create_dat = sy-datum.
*      criroles-create_tim = sy-uzeit.
*      CLEAR: criroles-change_usr, criroles-change_dat,
*             criroles-change_tim.
        MODIFY criroles.
        CONCATENATE criroles-vrsio criroles-agr_name INTO l_objid.
        INSERT /psyng/criroles FROM criroles.       "#EC CI_IMUD_NESTED
        IF sy-subrc = 0.
          crirole_added = 'Y'.
***   Record insert in Database / change doc
          ls_criroles_n = criroles.
*       ls_criroles_o = criroles1.
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
          n_psyng_criroles              = ls_criroles_n
          o_psyng_criroles              = ls_criroles_o
         upd_psyng_criroles            = 'I'
            n_psyng_criprof        = ls_criprof
            o_psyng_criprof        = ls_criprof
            UPD_PSYNG_CRIPROF      = ' '
            N_PSYNG_CRITCODES      = ls_critcode
            O_PSYNG_CRITCODES      = ls_critcode
            UPD_PSYNG_CRITCODES    = ' '


            TABLES
              icdtxt_crit_obj               = lt_cdtxt
                    .

          CLEAR : ls_criroles_n.
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
    DATA: lv_spras LIKE /psyng/texts-spras.
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
          <text>-object = 'Q'.
          add 1 to l_idx.
        endloop.
      endloop.
    endloop.

*    LOOP AT texts.
**-- Handle single role text at a time for multi lang support
*      AT NEW textname.
*        LOOP AT texts ASSIGNING <text> WHERE textname = texts-textname.
*          AT NEW spras.
*            l_idx = 0.
*          ENDAT.
*          ADD 1 TO l_idx.
*          <text>-line = l_idx.
*          <text>-object = 'Q'.
*          IF <text>-spras IS INITIAL.
**     If language is not specified, use logon language
*            <text>-spras = sy-langu.
*          ENDIF.
*          lt_spras = <text>-spras.
*          COLLECT lt_spras.
**      ENDAT.
*          lv_spras = <text>-spras.
*        ENDLOOP.
*      ENDAT.
*    ENDLOOP.

*    IF lt_spras[] IS INITIAL.
*      lt_spras = sy-langu.
*      COLLECT lt_spras.
*    ENDIF.
*Delete old text for all languages that where encountered in the text
*table
    LOOP AT criroles.
      LOOP AT lt_spras.
        READ TABLE texts WITH KEY textname = criroles-agr_name.
        IF sy-subrc = 0.
          DELETE FROM /psyng/texts                  "#EC CI_IMUD_NESTED
                      WHERE textname = criroles-agr_name
                    AND   object   = 'Q'
                    AND   vrsio    = i_vrsio
                    AND   spras    = lt_spras.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
    IF sy-subrc NE 0.
      LOOP AT lt_spras.
        DELETE FROM /psyng/texts
              WHERE   object   = 'Q'
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
  REFRESH criroles.
  CLEAR criroles.

  COMMIT WORK.

ENDFUNCTION.
