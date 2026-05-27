FUNCTION /psyng/sw_cr_delete_conflict.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_VRSIO) LIKE  /PSYNG/CONFLICT-VRSIO
*"     REFERENCE(I_CONID) LIKE  /PSYNG/CONFLICT-CONID
*"  EXCEPTIONS
*"      NOT_AUTHORIZED
*"      NOT_EXIST
*"      LOCKED
*"----------------------------------------------------------------------
  DATA: ls_conflict_o  TYPE /psyng/conflict,
        ls_conflict_n  TYPE /psyng/conflict,
        ls_confdet_o   TYPE /psyng/confdet,
        ls_confdet_n   TYPE /psyng/confdet,
        ls_conowner_o  TYPE /psyng/conowner,
        ls_conowner_n  TYPE /psyng/conowner,
        l_objid        TYPE cdhdr-objectid,
        lt_cdtxt       TYPE TABLE OF cdtxt,
        lt_confdet     TYPE TABLE OF /psyng/confdet,
        lt_conowner    TYPE TABLE OF /psyng/conowner,
        ls_conpmit     type /PSYNG/CONPMIT.
* BOC by RGUPTA on 07.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700

  AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
           ID 'ACTVT'      FIELD '06'
           ID 'Y&SW_VRSIO' FIELD i_vrsio
           ID 'Y&SW_CONID' FIELD i_conid.
  IF sy-subrc <> 0.
    RAISE not_authorized.
  ENDIF.

  SELECT SINGLE * INTO ls_conflict_o        "#EC CI_SEL_NESTED
            FROM /psyng/conflict
                WHERE conid = i_conid
                  AND vrsio = i_vrsio.
  IF sy-subrc <> 0.
    RAISE not_exist.
  ENDIF.

  CONCATENATE i_vrsio i_conid INTO l_objid.

* Lock conflict ID
  CALL FUNCTION 'ENQUEUE_/PSYNG/CONFLICT'
       EXPORTING
            conid          = i_conid
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

* Delete conflict header
  DELETE FROM /psyng/conflict          "#EC CI_IMUD_NESTED
             WHERE conid = i_conid
               AND vrsio = i_vrsio.

  CALL FUNCTION '/PSYNG/CONFLICT_WRITE_DOCUMENT' IN UPDATE TASK
       EXPORTING
            objectid                = l_objid
            tcode                   = sy-tcode
            utime                   = sy-uzeit
            udate                   = sy-datum
            username                = l_current_user"sy-uname C0700
            object_change_indicator = 'D'
            planned_or_real_changes = 'R'
            n_psyng_conflict        = ls_conflict_n
            o_psyng_conflict        = ls_conflict_o
            upd_psyng_conflict      = 'D'
            n_psyng_confdet         = ls_confdet_n
            o_psyng_confdet         = ls_confdet_o
            N_PSYNG_CONOWNER        = ls_conowner_n
            O_PSYNG_CONOWNER        = ls_conowner_o
            UPD_PSYNG_CONOWNER      = ' '
            N_PSYNG_CONPMIT         = ls_conpmit
            O_PSYNG_CONPMIT         = ls_conpmit
            UPD_PSYNG_CONPMIT       = ' '

       TABLES
            icdtxt_conflict         = lt_cdtxt.

  CLEAR ls_conflict_o.

* Delete conflict details
  SELECT * INTO TABLE lt_confdet      "#EC CI_SEL_NESTED
     FROM /psyng/confdet
         WHERE conid = i_conid
           AND vrsio = i_vrsio.

  IF NOT lt_confdet[] IS INITIAL.
    DELETE /psyng/confdet FROM TABLE lt_confdet.    "#EC CI_IMUD_NESTED

    LOOP AT lt_confdet INTO ls_confdet_o.
      CALL FUNCTION '/PSYNG/CONFLICT_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user"sy-uname C0700
                object_change_indicator = 'D'
                planned_or_real_changes = 'R'
                n_psyng_conflict        = ls_conflict_n
                o_psyng_conflict        = ls_conflict_o
                n_psyng_confdet         = ls_confdet_n
                o_psyng_confdet         = ls_confdet_o
                upd_psyng_confdet       = 'D'
                N_PSYNG_CONOWNER        = ls_conowner_n
                O_PSYNG_CONOWNER        = ls_conowner_o
                UPD_PSYNG_CONOWNER      = ' '
                N_PSYNG_CONPMIT         = ls_conpmit
                O_PSYNG_CONPMIT         = ls_conpmit
                UPD_PSYNG_CONPMIT       = ' '
           TABLES
                icdtxt_conflict         = lt_cdtxt.
    ENDLOOP.
  ENDIF.

* Delete conflict owners
  SELECT * INTO TABLE lt_conowner         "#EC CI_SEL_NESTED
     FROM /psyng/conowner
         WHERE vrsio = i_vrsio
           AND conid = i_conid.

  IF NOT lt_conowner[] IS INITIAL.
    DELETE /psyng/conowner FROM TABLE lt_conowner. "#EC CI_IMUD_NESTED

    LOOP AT lt_conowner INTO ls_conowner_o.
      CALL FUNCTION '/PSYNG/CONFLICT_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user"sy-uname C0700
                object_change_indicator = 'D'
                planned_or_real_changes = 'R'
                n_psyng_conflict        = ls_conflict_n
                o_psyng_conflict        = ls_conflict_o
                n_psyng_confdet         = ls_confdet_n
                o_psyng_confdet         = ls_confdet_o
                upd_psyng_confdet       = 'D'
                N_PSYNG_CONOWNER        = ls_conowner_n
                O_PSYNG_CONOWNER        = ls_conowner_o
                UPD_PSYNG_CONOWNER      = ' '
                N_PSYNG_CONPMIT         = ls_conpmit
                O_PSYNG_CONPMIT         = ls_conpmit
                UPD_PSYNG_CONPMIT       = ' '

           TABLES
                icdtxt_conflict         = lt_cdtxt.
    ENDLOOP.
  ENDIF.

* Delete texts
  DELETE FROM /psyng/texts            "#EC CI_IMUD_NESTED
         WHERE textname = i_conid
           AND object   = 'C'
           AND vrsio    = i_vrsio.
  COMMIT WORK.

  CALL FUNCTION 'DEQUEUE_/PSYNG/CONFLICT'
       EXPORTING
            conid    = i_conid
            vrsio    = i_vrsio.
ENDFUNCTION.
