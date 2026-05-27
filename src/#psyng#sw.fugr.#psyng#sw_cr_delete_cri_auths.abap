FUNCTION /psyng/sw_cr_delete_cri_auths.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_VRSIO) TYPE  /PSYNG/SODVRSIO
*"     REFERENCE(I_SWAUDID) TYPE  /PSYNG/SWAUDID
*"  EXCEPTIONS
*"      NOT_AUTHORIZED
*"      NOT_EXIST
*"      LOCKED
*"----------------------------------------------------------------------
  DATA: ls_swaudhdr_o  TYPE /psyng/swaudhdr,
        ls_swaudhdr_n  TYPE /psyng/swaudhdr,
        ls_swaudc2_o   TYPE /psyng/swaudc2,
        ls_swaudc2_n   TYPE /psyng/swaudc2,
        l_objid        TYPE cdhdr-objectid,
        lt_cdtxt       TYPE TABLE OF cdtxt,
        lt_swaudc2     TYPE TABLE OF /psyng/swaudc2.

*Begin of Addition:HBHALLA(PN-5886)(Issue2&3)(19/02/26)
  DATA:planned_change_number LIKE cdhdr-planchngnr,
       cdoc_no_change_pointers LIKE cdhdr-change_ind.
  DATA: upd_icdtxt_swaudc           TYPE c.
  DATA: BEGIN OF icdtxt_swaudc           OCCURS 20.
          INCLUDE STRUCTURE cdtxt.
  DATA: END OF icdtxt_swaudc.
*End of Addition:HBHALLA(PN-5886)(Issue2&3)(19/02/26)

* BOC by RGUPTA on 07.04.22 for C0700
  DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700

  AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
           ID 'ACTVT'      FIELD '06'
           ID 'Y&SW_VRSIO' FIELD i_vrsio
           ID 'Y&SW_AUTID' FIELD i_swaudid.
  IF sy-subrc <> 0.
    RAISE not_authorized.
  ENDIF.

  SELECT SINGLE * INTO ls_swaudhdr_o FROM /psyng/swaudhdr
                WHERE swaudid = i_swaudid
                  AND vrsio = i_vrsio.
  IF sy-subrc <> 0.
    RAISE not_exist.
  ENDIF.

  CONCATENATE i_vrsio i_swaudid INTO l_objid.

* Lock crit auth ID
  CALL FUNCTION 'ENQUEUE_/PSYNG/SWAUDHDR'
       EXPORTING
            swaudid        = i_swaudid
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

* Delete CA header
  DELETE FROM /psyng/swaudhdr                       "#EC CI_IMUD_NESTED
            WHERE swaudid = i_swaudid
              AND vrsio = i_vrsio.

  CALL FUNCTION '/PSYNG/SWAUD_WRITE_DOCUMENT' IN UPDATE TASK
        EXPORTING
          objectid                      = l_objid
          tcode                         = sy-tcode
          utime                         = sy-uzeit
          udate                         = sy-datum
          username                      = l_current_user"sy-uname C0700
         object_change_indicator       = 'D'
         planned_or_real_changes       = 'R'
          n_psyng_swaudc2               = ls_swaudc2_n
          o_psyng_swaudc2               = ls_swaudc2_o
          n_psyng_swaudhdr              = ls_swaudhdr_n
          o_psyng_swaudhdr              = ls_swaudhdr_o
         upd_psyng_swaudhdr            = 'D'
        TABLES
          icdtxt_swaud                  = lt_cdtxt
                .
  COMMIT WORK."(++)HBHALLA(PN-5886)(Issue3)(19/02/26)

* * Delete crit auth details
  SELECT * INTO TABLE lt_swaudc2 FROM /psyng/swaudc2 "#EC CI_SEL_NESTED
         WHERE swaudid = i_swaudid
           AND vrsio = i_vrsio.

  IF NOT lt_swaudc2[] IS INITIAL.
    DELETE /psyng/swaudc2 FROM TABLE lt_swaudc2.    "#EC CI_IMUD_NESTED
    CLEAR ls_swaudhdr_o.

    LOOP AT lt_swaudc2 INTO ls_swaudc2_o.
*Begin of Addition:HBHALLA(PN-5886)(Issue2&3)(19/02/26)
      CONCATENATE ls_swaudc2_o-swaudid ls_swaudc2_o-tcode
                      ls_swaudc2_o-object ls_swaudc2_o-valueset
                      ls_swaudc2_o-field ls_swaudc2_o-val_from
                      ls_swaudc2_o-val_to i_vrsio
                      INTO l_objid SEPARATED BY '|'.
*      CALL FUNCTION '/PSYNG/SWAUD_WRITE_DOCUMENT' IN UPDATE TASK
*        EXPORTING
*          objectid                      = l_objid
*          tcode                         = sy-tcode
*          utime                         = sy-uzeit
*          udate                         = sy-datum
*          username                      = l_current_user"sy-uname C0700
*         object_change_indicator       = 'D'
*         planned_or_real_changes       = 'R'
*          n_psyng_swaudc2               = ls_swaudc2_n
*          o_psyng_swaudc2               = ls_swaudc2_o
*         UPD_PSYNG_SWAUDC2             = 'D'
*          n_psyng_swaudhdr              = ls_swaudhdr_n
*          o_psyng_swaudhdr              = ls_swaudhdr_o
*        TABLES
*          icdtxt_swaud                  = lt_cdtxt .

      CALL FUNCTION '/PSYNG/SWAUDC_WRITE_DOCUMENT' IN UPDATE TASK
         EXPORTING objectid              = l_objid
                   tcode                 = '/PSYNG/AUDTOBJ'
                   utime                 = sy-uzeit
                   udate                 = sy-datum
                   username              = l_current_user
                   planned_change_number = planned_change_number
                   object_change_indicator = 'D'
                   planned_or_real_changes = 'R'
                   no_change_pointers = cdoc_no_change_pointers
                   o_psyng_swaudc
                       = ls_swaudc2_o
                   n_psyng_swaudc
                       = ls_swaudc2_n
                   upd_psyng_swaudc
                       = 'D'
                   upd_icdtxt_swaudc
                       = upd_icdtxt_swaudc
           TABLES  icdtxt_swaudc
                       = icdtxt_swaudc.
      COMMIT WORK.
      CLEAR planned_change_number.
      CLEAR : ls_swaudc2_o.
*End of Addition:HBHALLA(PN-5886)(Issue2&3)(19/02/26)
    ENDLOOP.
  ENDIF.

* Delete texts
  DELETE FROM /psyng/texts                          "#EC CI_IMUD_NESTED
           WHERE textname = i_swaudid
             AND object   = 'T'
             AND vrsio    = i_vrsio.
  COMMIT WORK.

  CALL FUNCTION 'DEQUEUE_/PSYNG/SWAUDHDR'
       EXPORTING
            swaudid = i_swaudid
            vrsio   = i_vrsio.
ENDFUNCTION.
