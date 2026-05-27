FUNCTION /psyng/sw_cr_add_functionid.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(WA_FUNCTION) TYPE  /PSYNG/FUNCTION
*"     VALUE(I_VRSIO) TYPE  /PSYNG/FUNCTION-VRSIO OPTIONAL
*"     VALUE(I_LANGU) TYPE  SPRAS DEFAULT SY-LANGU
*"     VALUE(FLAG) TYPE  CHAR1 OPTIONAL
*"     VALUE(F_FUNT) TYPE  CHAR1 OPTIONAL
*"  EXPORTING
*"     VALUE(FUNID_ADDED) TYPE  CHAR1
*"     VALUE(FUNID_HDR_ADDED) TYPE  CHAR1
*"     VALUE(FUNID_TC_ADDED) TYPE  CHAR1
*"     VALUE(FUNID_TXT_ADDED) TYPE  CHAR1
*"     VALUE(FUNCT_OBJS_ADDED) TYPE  CHAR1
*"  TABLES
*"      TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"      FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      FAOBJ STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"  EXCEPTIONS
*"      TARGET_NOT_SPECIFIED
*"      NOT_AUTHORIZED
*"      FUNCTION_ALREADY_EXISTS
*"      LOCKED
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_ADD_FUNCTIONID'.
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
  DATA: lt_functtran LIKE TABLE OF /psyng/functtran WITH HEADER LINE.
  DATA: lt_faobj2 LIKE TABLE OF /psyng/faobj2 WITH HEADER LINE,
        lt_tcode TYPE SORTED TABLE OF /psyng/functtran WITH UNIQUE KEY
        tcode WITH HEADER LINE,
        lt_faobj TYPE SORTED TABLE OF /psyng/faobj2
        WITH UNIQUE KEY
        tcode object valueset field val_from val_to
        WITH HEADER LINE,
        ls_function_n  TYPE /psyng/function,
        ls_function_o  TYPE /psyng/function,
        ls_functtran_n TYPE /psyng/functtran,
        ls_functtran_o TYPE /psyng/functtran,
        ls_faobj2_n    TYPE /psyng/faobj2,
        ls_faobj2_o    TYPE /psyng/faobj2,
        ls_faobj_empty TYPE /psyng/faobj,
        l_objid        TYPE cdhdr-objectid,
        lt_cdtxt       TYPE TABLE OF cdtxt.
* BOC by RGUPTA on 07.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700

  funid_added      = 'N'.
  funid_hdr_added  = 'N'.
  funid_tc_added   = 'N'.
  funid_txt_added  = 'N'.
  funct_objs_added = 'N'.

  IF wa_function IS INITIAL.
    RAISE target_not_specified.
    "EXIT.
  ENDIF.

*Sort data tables
  SORT : faobj. "functtran,
*  Om for SE4.4
  sort functtran by tcode.

  CONCATENATE wa_function-vrsio wa_function-function INTO l_objid.

* Lock function ID
  CALL FUNCTION 'ENQUEUE_/PSYNG/FUNCTION'
       EXPORTING
            function       = wa_function-function
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

*Check if Function Exists
  wa_function-change_usr = l_current_user. "sy-uname. C0700
  wa_function-change_dat = sy-datum.
  wa_function-change_tim = sy-uzeit.
  SELECT SINGLE * FROM /psyng/function       "#EC CI_SEL_NESTED
                  WHERE function = wa_function-function
                  AND vrsio      = i_vrsio.



  IF sy-subrc <> 0.
    IF flag NE 'X'.
      wa_function-create_usr = l_current_user. "sy-uname. C0700
      wa_function-create_dat = sy-datum.
      wa_function-create_tim = sy-uzeit.
    ENDIF.
    INSERT /psyng/function FROM wa_function.   "#EC CI_IMUD_NESTED
    IF sy-subrc = 0.
      funid_added = 'Y'.      "if new record inserted

*     Record Insert in change document
      ls_function_n = wa_function.
      CALL FUNCTION '/PSYNG/FUNCTS_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user "C0700
                object_change_indicator = 'I'
                planned_or_real_changes = 'R'
                n_psyng_function        = ls_function_n
                o_psyng_function        = ls_function_o
                upd_psyng_function      = 'I'
                n_psyng_functtran       = ls_functtran_n
                o_psyng_functtran       = ls_functtran_o
           TABLES
                icdtxt_functs           = lt_cdtxt.

      CLEAR ls_function_n.
    ENDIF.
  ELSE.
    CHECK flag IS INITIAL."append only is initial
    wa_function-create_usr = /psyng/function-create_usr.
    wa_function-create_dat = /psyng/function-create_dat.
    wa_function-create_tim = /psyng/function-create_tim.
    MODIFY /psyng/function FROM wa_function.         "#EC CI_IMUD_NESTED
    IF sy-subrc = 0.
      funid_hdr_added = 'Y'.   "if existing record modified

*     Record Change in change document
      ls_function_n = wa_function.
      ls_function_o = /psyng/function.
      CALL FUNCTION '/PSYNG/FUNCTS_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user "C0700
                object_change_indicator = 'U'
                planned_or_real_changes = 'R'
                n_psyng_function        = ls_function_n
                o_psyng_function        = ls_function_o
                upd_psyng_function      = 'U'
                n_psyng_functtran       = ls_functtran_n
                o_psyng_functtran       = ls_functtran_o
           TABLES
                icdtxt_functs           = lt_cdtxt.

      CLEAR: ls_function_n, ls_function_o.
    ENDIF.
  ENDIF.
*  CHECK sy-subrc = 0.
*--Transaction Codes
  IF functtran IS REQUESTED.
    IF funid_added = 'Y'.
      FREE : lt_tcode.
    ELSE.
*   get existing tcodes
      SELECT * INTO TABLE lt_tcode              "#EC CI_SEL_NESTED
             FROM /psyng/functtran
                        WHERE vrsio    = i_vrsio
                        AND functionid = wa_function-function.


    ENDIF.
*--Delete Old Tcodes that no longer exist
    LOOP AT lt_tcode.
      READ TABLE functtran WITH KEY tcode = lt_tcode-tcode
      BINARY SEARCH TRANSPORTING NO FIELDS.
      CHECK sy-subrc <> 0.
      DELETE FROM /psyng/functtran            "#EC CI_IMUD_NESTED
              WHERE vrsio = i_vrsio AND
                    functionid = wa_function-function AND
                    tcode      = lt_tcode-tcode.
      IF sy-subrc = 0.
*       Record Delete in change document
        ls_functtran_o = lt_tcode.
        CALL FUNCTION '/PSYNG/FUNCTS_WRITE_DOCUMENT' IN UPDATE TASK
             EXPORTING
                  objectid                = l_objid
                  tcode                   = sy-tcode
                  utime                   = sy-uzeit
                  udate                   = sy-datum
                  username                = l_current_user "C0700
                  object_change_indicator = 'D'
                  planned_or_real_changes = 'R'
                  n_psyng_function        = ls_function_n
                  o_psyng_function        = ls_function_o
                  n_psyng_functtran       = ls_functtran_n
                  o_psyng_functtran       = ls_functtran_o
                  upd_psyng_functtran     = 'D'
             TABLES
                  icdtxt_functs           = lt_cdtxt.

        CLEAR ls_functtran_o.
      ENDIF.
    ENDLOOP.
*--Add new tcodes
    LOOP AT functtran.
      READ TABLE lt_tcode WITH TABLE KEY tcode = functtran-tcode
                                         TRANSPORTING NO FIELDS.
      CHECK sy-subrc <> 0.
      INSERT /psyng/functtran FROM functtran.    "#EC CI_IMUD_NESTED
      IF sy-subrc = 0.
        funid_tc_added   = 'Y'.

*       Record Insert in change document
        ls_functtran_n = functtran.
        CALL FUNCTION '/PSYNG/FUNCTS_WRITE_DOCUMENT' IN UPDATE TASK
             EXPORTING
                  objectid                = l_objid
                  tcode                   = sy-tcode
                  utime                   = sy-uzeit
                  udate                   = sy-datum
                  username                = l_current_user "C0700
                  object_change_indicator = 'I'
                  planned_or_real_changes = 'R'
                  n_psyng_function        = ls_function_n
                  o_psyng_function        = ls_function_o
                  n_psyng_functtran       = ls_functtran_n
                  o_psyng_functtran       = ls_functtran_o
                  upd_psyng_functtran     = 'I'
             TABLES
                  icdtxt_functs           = lt_cdtxt.

        CLEAR ls_functtran_n.
      ENDIF.
    ENDLOOP.
  ENDIF.
*--Function Description
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
        <text>-object = 'F'.
        add 1 to l_idx.
      endloop.
    endloop.

*    LOOP AT texts ASSIGNING <text>.
**------ Om Change SE3.2 14/01/2016
*      AT NEW spras.
*        l_idx = 0.
*      ENDAT.
**------ End
*      ADD 1 TO l_idx.
*      <text>-line = l_idx.
*      <text>-object = 'F'.
*      IF <text>-spras IS INITIAL.
**     If language is not specified, use logon language
*        <text>-spras = sy-langu.
*      ENDIF.
*      lt_spras = <text>-spras.
*      COLLECT lt_spras.
*    ENDLOOP.
*Delete old text for all languages that where encountered in the text
*table
*    IF f_funt EQ 'X'.
    LOOP AT lt_spras.
      DELETE FROM /psyng/texts          "#EC CI_IMUD_NESTED
                WHERE textname = wa_function-function
                AND   object   = 'F'
                AND   vrsio    = i_vrsio
                AND   spras    = lt_spras.
    ENDLOOP.
    IF NOT texts[] IS INITIAL.
*      INSERT /psyng/texts FROM TABLE texts. "#EC CI_IMUD_NESTED
      MODIFY /psyng/texts FROM TABLE texts. "#EC CI_IMUD_NESTED
      IF sy-subrc = 0.
        funid_txt_added = 'Y'.
*     There are No Change documents for texts.
      ENDIF.
    ENDIF.

*    ENDIF.
  ENDIF.



*--Function Objects
  IF faobj IS REQUESTED.
    IF funid_added = 'Y'.
      FREE lt_faobj.
    ELSE.
*   get existing objects
      SELECT DISTINCT tcode        "#EC CI_SEL_NESTED
                      object
                      valueset
                      field
                      val_from
                      val_to
      INTO CORRESPONDING FIELDS OF TABLE lt_faobj FROM /psyng/faobj2
                        WHERE vrsio  = i_vrsio
                        AND funid    = wa_function-function.
    ENDIF.
*--Delete Old records that no longer exist
    LOOP AT lt_faobj.
      READ TABLE faobj WITH KEY
        tcode    = lt_faobj-tcode
        object   = lt_faobj-object
        valueset = lt_faobj-valueset
        field    = lt_faobj-field
        val_from = lt_faobj-val_from
        val_to   = lt_faobj-val_to.
      CHECK sy-subrc <> 0.
      DELETE FROM /psyng/faobj2 WHERE    "#EC CI_IMUD_NESTED
      vrsio    = i_vrsio AND
      funid    = wa_function-function AND
      tcode    = lt_faobj-tcode AND
      object   = lt_faobj-object AND
      valueset = lt_faobj-valueset AND
      field    = lt_faobj-field AND
      val_from = lt_faobj-val_from AND
      val_to   = lt_faobj-val_to.
      IF sy-subrc = 0.
*       Record Delete in change document
        CONCATENATE lt_faobj-funid lt_faobj-tcode lt_faobj-object
                    lt_faobj-valueset lt_faobj-field lt_faobj-val_from
                    lt_faobj-val_to lt_faobj-vrsio
                    lt_faobj-obj_or lt_faobj-fld_and
                    INTO l_objid SEPARATED BY '|'.

        ls_faobj2_o = lt_faobj.
        CALL FUNCTION '/PSYNG/FAOBJ_WRITE_DOCUMENT' IN UPDATE TASK
             EXPORTING
                  objectid                = l_objid
                  tcode                   = sy-tcode
                  utime                   = sy-uzeit
                  udate                   = sy-datum
                  username                = l_current_user "C0700
                  object_change_indicator = 'D'
                  planned_or_real_changes = 'R'
                  n_psyng_faobj           = ls_faobj_empty
                  o_psyng_faobj           = ls_faobj_empty
                  o_psyng_faobj2          = ls_faobj2_o
                  n_psyng_faobj2          = ls_faobj2_n
                  upd_psyng_faobj2        = 'D'
             TABLES
                  icdtxt_faobj            = lt_cdtxt.

        CLEAR ls_faobj2_o.
      ENDIF.
    ENDLOOP.
  ENDIF.
  LOOP AT faobj.
*Beging Of Commenting:HBHALLA(PN-7014)
*    faobj-change_usr = l_current_user.
*    faobj-change_dat = sy-datum.
*    faobj-change_tim = sy-uzeit.
*End Of Commenting:HBHALLA(PN-7014)
    READ TABLE lt_faobj WITH KEY
      tcode    = faobj-tcode
      object   = faobj-object
      valueset = faobj-valueset
      field    = faobj-field
      val_from = faobj-val_from
      val_to   = faobj-val_to.
    IF sy-subrc = 0.
*when comparing the fields, ignore the change dates
      lt_faobj-change_usr  = faobj-change_usr.
      lt_faobj-change_dat  = faobj-change_dat.
      lt_faobj-change_tim  = faobj-change_tim.
*     Did the record really change
      IF lt_faobj <> faobj.
*BOC:HBHALLA(PN-7014)
        lt_faobj-create_usr = faobj-create_usr.
        lt_faobj-create_dat = faobj-create_dat.
        lt_faobj-create_tim = faobj-create_tim.
*EOC:HBHALLA(PN-7014)
        MODIFY /psyng/faobj2 FROM faobj.     "#EC CI_IMUD_NESTED
        funct_objs_added = 'Y'.

*         Record Change in change document
        ls_faobj2_n = faobj.
        ls_faobj2_o = lt_faobj.

        CONCATENATE lt_faobj-funid lt_faobj-tcode lt_faobj-object
                    lt_faobj-valueset lt_faobj-field
lt_faobj-val_from
                    lt_faobj-val_to lt_faobj-vrsio
                    lt_faobj-obj_or lt_faobj-fld_and
                    INTO l_objid SEPARATED BY '|'.

        CALL FUNCTION '/PSYNG/FAOBJ_WRITE_DOCUMENT' IN UPDATE TASK
             EXPORTING
                  objectid                = l_objid
                  tcode                   = sy-tcode
                  utime                   = sy-uzeit
                  udate                   = sy-datum
                  username                = l_current_user "C0700
                  object_change_indicator = 'U'
                  planned_or_real_changes = 'R'
                  n_psyng_faobj           = ls_faobj_empty
                  o_psyng_faobj           = ls_faobj_empty
                  o_psyng_faobj2          = ls_faobj2_o
                  n_psyng_faobj2          = ls_faobj2_n
                  upd_psyng_faobj2        = 'U'
             TABLES
                  icdtxt_faobj            = lt_cdtxt.

        CLEAR: ls_faobj2_n, ls_faobj2_o.
      ENDIF.
    ELSE.
      INSERT /psyng/faobj2 FROM faobj.   "#EC CI_IMUD_NESTED
      funct_objs_added = 'Y'.

*     Record Insert in change document
      ls_faobj2_n = faobj.
*BOC UMITTAL : PN17398 : 27/01/2026
"As lt_faobj is coming blank from above , so changing
*      LT_FAOBJ to FAOBJ in L_OBJID.
*      CONCATENATE lt_faobj-funid lt_faobj-tcode lt_faobj-object
*                  lt_faobj-valueset lt_faobj-field lt_faobj-val_from
*                  lt_faobj-val_to lt_faobj-vrsio
*                  INTO l_objid SEPARATED BY '|'.
      CLEAR l_objid.
      CONCATENATE faobj-funid faobj-tcode faobj-object
                  faobj-valueset faobj-field faobj-val_from
                  faobj-val_to faobj-vrsio
                  faobj-obj_or faobj-fld_and
                  INTO l_objid SEPARATED BY '|'.
*EOC UMITTAL : PN17398 : 27/01/2026
      CALL FUNCTION '/PSYNG/FAOBJ_WRITE_DOCUMENT' IN UPDATE TASK
           EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user "C0700
                object_change_indicator = 'I'
                planned_or_real_changes = 'R'
                n_psyng_faobj           = ls_faobj_empty
                o_psyng_faobj           = ls_faobj_empty
                o_psyng_faobj2          = ls_faobj2_o
                n_psyng_faobj2          = ls_faobj2_n
                upd_psyng_faobj2        = 'I'
           TABLES
                icdtxt_faobj            = lt_cdtxt.

      CLEAR ls_faobj2_n.
    ENDIF.
  ENDLOOP.

  COMMIT WORK AND WAIT.

  CALL FUNCTION 'DEQUEUE_/PSYNG/FUNCTION'
       EXPORTING
            function = wa_function-function
            vrsio    = i_vrsio
            _SYNCHRON = 'X'.
  COMMIT WORK AND WAIT.

ENDFUNCTION.
