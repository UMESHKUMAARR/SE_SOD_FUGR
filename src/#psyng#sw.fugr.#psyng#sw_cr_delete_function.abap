FUNCTION /psyng/sw_cr_delete_function.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_VRSIO) LIKE  /PSYNG/FUNCTION-VRSIO
*"     REFERENCE(I_FUNID) LIKE  /PSYNG/FUNCTION-FUNCTION
*"  EXCEPTIONS
*"      NOT_AUTHORIZED
*"      NOT_EXIST
*"      LOCKED
*"----------------------------------------------------------------------
  DATA: ls_function_o  TYPE /psyng/function,
        ls_function_n  TYPE /psyng/function,
        ls_functtran_o TYPE /psyng/functtran,
        ls_functtran_n TYPE /psyng/functtran,
        ls_faobj2_o    TYPE /psyng/faobj2,
        ls_faobj2_n    TYPE /psyng/faobj2,
        ls_faobj       TYPE /psyng/faobj,
        l_objid        TYPE cdhdr-objectid,
        lt_cdtxt       TYPE TABLE OF cdtxt,
        lt_functtran   TYPE TABLE OF /psyng/functtran,
        lt_faobj       TYPE TABLE OF /psyng/faobj2.
* BOC by RGUPTA on 07.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700

  AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
           ID 'ACTVT'      FIELD '06'
           ID 'Y&SW_VRSIO' FIELD i_vrsio
           ID 'Y&SW_FUNCT' FIELD i_funid.
  IF sy-subrc <> 0.
    RAISE not_authorized.
  ENDIF.

  SELECT SINGLE * INTO ls_function_o          "#EC CI_SEL_NESTED
       FROM /psyng/function
                WHERE function = i_funid
                  AND vrsio    = i_vrsio.
  IF sy-subrc <> 0.
    RAISE not_exist.
  ENDIF.

  CONCATENATE i_vrsio i_funid INTO l_objid.

* Lock function ID
  CALL FUNCTION 'ENQUEUE_/PSYNG/FUNCTION'
       EXPORTING
            function       = i_funid
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

* Delete function header
  DELETE FROM /psyng/function                  "#EC CI_IMUD_NESTED
              WHERE function = i_funid
                AND vrsio    = i_vrsio.

  CALL FUNCTION '/PSYNG/FUNCTS_WRITE_DOCUMENT' IN UPDATE TASK
       EXPORTING
            objectid                = l_objid
            tcode                   = sy-tcode
            utime                   = sy-uzeit
            udate                   = sy-datum
            username                = l_current_user"sy-uname C0700
            object_change_indicator = 'D'
            planned_or_real_changes = 'R'
            n_psyng_function        = ls_function_n
            o_psyng_function        = ls_function_o
            upd_psyng_function      = 'D'
            n_psyng_functtran       = ls_functtran_n
            o_psyng_functtran       = ls_functtran_o
       TABLES
            icdtxt_functs           = lt_cdtxt.

  CLEAR ls_function_o.

* Delete function details
  SELECT * INTO TABLE lt_functtran              "#EC CI_SEL_NESTED
      FROM /psyng/functtran
         WHERE functionid = i_funid
           AND vrsio      = i_vrsio.

  IF NOT lt_functtran[] IS INITIAL.
    DELETE /psyng/functtran FROM TABLE lt_functtran. "#EC CI_IMUD_NESTED

    LOOP AT lt_functtran INTO ls_functtran_o.
      CALL FUNCTION '/PSYNG/FUNCTS_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user"sy-uname C0700
                object_change_indicator = 'D'
                planned_or_real_changes = 'R'
                n_psyng_function        = ls_function_n
                o_psyng_function        = ls_function_o
                n_psyng_functtran       = ls_functtran_n
                o_psyng_functtran       = ls_functtran_o
                upd_psyng_functtran     = 'D'
           TABLES
                icdtxt_functs           = lt_cdtxt.
    ENDLOOP.
  ENDIF.

* Delete function authorization objects
  SELECT * INTO TABLE lt_faobj FROM /psyng/faobj2   "#EC CI_SEL_NESTED
         WHERE vrsio = i_vrsio
           AND funid = i_funid.

  IF NOT lt_faobj[] IS INITIAL.
    DELETE /psyng/faobj2 FROM TABLE lt_faobj.   "#EC CI_IMUD_NESTED

    LOOP AT lt_faobj INTO ls_faobj2_o.
     CONCATENATE ls_faobj2_o-funid ls_faobj2_o-tcode ls_faobj2_o-object
                  ls_faobj2_o-valueset ls_faobj2_o-field
                  ls_faobj2_o-val_from ls_faobj2_o-val_to
                  ls_faobj2_o-vrsio
                  INTO l_objid SEPARATED BY '|'.

      CALL FUNCTION '/PSYNG/FAOBJ_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user"sy-uname C0700
                object_change_indicator = 'D'
                planned_or_real_changes = 'R'
                n_psyng_faobj           = ls_faobj
                o_psyng_faobj           = ls_faobj
                o_psyng_faobj2          = ls_faobj2_o
                n_psyng_faobj2          = ls_faobj2_n
                upd_psyng_faobj2        = 'D'
           TABLES
                icdtxt_faobj            = lt_cdtxt.
    ENDLOOP.
  ENDIF.

* Delete texts
  DELETE FROM /psyng/texts               "#EC CI_IMUD_NESTED
           WHERE textname = i_funid
             AND object   = 'F'
             AND vrsio    = i_vrsio.
  COMMIT WORK.

  CALL FUNCTION 'DEQUEUE_/PSYNG/FUNCTION'
       EXPORTING
            function = i_funid
            vrsio    = i_vrsio.
ENDFUNCTION.
