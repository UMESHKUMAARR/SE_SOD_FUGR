FUNCTION /psyng/sw_sod_by_org.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_SOURCE_VRSIO) TYPE  /PSYNG/FUNCTION-VRSIO DEFAULT
*"       000
*"     REFERENCE(I_TARGET_VRSIO) TYPE  /PSYNG/FUNCTION-VRSIO
*"     REFERENCE(I_VAR_ELEMENT_PREFIX) TYPE  /PSYNG/SE_VAREL DEFAULT
*"       '/PSYNG/$'
*"     REFERENCE(I_VAR_ELEMENT_VERSION) TYPE  /PSYNG/VE_VRSIO
*"  EXPORTING
*"     REFERENCE(E_ERROR) TYPE  BAPIFLAGX
*"     REFERENCE(E_MSG1) TYPE  SYMSGV
*"     REFERENCE(E_MSG2) TYPE  SYMSGV
*"     REFERENCE(E_MSG3) TYPE  SYMSGV
*"     REFERENCE(E_MSG4) TYPE  SYMSGV
*"  TABLES
*"      IT_VAR_ELEMENT_GROUP STRUCTURE  /PSYNG/ORGFIELD
*"      IT_FIELDS STRUCTURE  /PSYNG/ORGFIELD
*"----------------------------------------------------------------------
  TYPE-POOLS abap. "<NSINGH>++
  TYPES : BEGIN OF ty_functions,
            funid   TYPE /psyng/function_id,
          END   OF ty_functions.

  TYPES : BEGIN OF ty_conflicts,
            conid   TYPE /psyng/conflict_id,
          END   OF ty_conflicts.

*- Begin of Comment <NSINGH> 04/29/2020
*  TYPES : BEGIN OF ty_auth_fields,
*            field   TYPE authx-fieldname,
*            table   TYPE authx-checktable,
*            domname  TYPE dd01l-domname,
*          END OF ty_auth_fields.
*- End of Comment <NSINGH>

  DATA : lt_org_elements LIKE STANDARD TABLE OF /psyng/sw_ao_list,
*       lt_faobj2       TYPE STANDARD TABLE OF /psyng/faobj2,"<NSINGH>--
         lt_objects_temp LIKE STANDARD TABLE OF tobj,
         lt_objects      LIKE STANDARD TABLE OF tobj
                                               WITH HEADER LINE,
*       lt_faobj2_out   LIKE STANDARD TABLE OF /psyng/faobj2,"<NSINGH>--
         lt_functions    TYPE STANDARD TABLE OF ty_functions
                                               WITH HEADER LINE,
         lt_conflicts    TYPE STANDARD TABLE OF ty_conflicts
                                               WITH HEADER LINE.
*       lt_varel       LIKE STANDARD TABLE OF /psyng/sw_varel"<NSINGH>--
*                                               WITH HEADER LINE.
*       lt_auth_fields  TYPE STANDARD TABLE OF ty_auth_fields"<NSINGH>--
*                                               WITH HEADER LINE.

  DATA: lt_function  TYPE TABLE OF /psyng/function WITH HEADER LINE,
        lt_functtran TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
        lt_faobj     TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
        lt_conflict  TYPE TABLE OF /psyng/conflict WITH HEADER LINE,
        lt_confdet   TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
        lt_mchdr     TYPE TABLE OF /psyng/mchdr WITH HEADER LINE,
        lt_mctran    TYPE TABLE OF /psyng/mctran WITH HEADER LINE,
        lt_mcrepid   TYPE TABLE OF /psyng/mcrepid WITH HEADER LINE,
        lt_mcauditor TYPE TABLE OF /psyng/mcauditor WITH HEADER LINE,
        lt_critcodes TYPE TABLE OF /psyng/critcodes WITH HEADER LINE,
        lt_swaudhdr  TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE,
        lt_swaudc    TYPE TABLE OF /psyng/swaudc2 WITH HEADER LINE,
        lt_criroles  TYPE TABLE OF /psyng/criroles WITH HEADER LINE,
        lt_criprof   TYPE TABLE OF /psyng/criprof WITH HEADER LINE,
        lt_texts     TYPE TABLE OF /psyng/texts WITH HEADER LINE,
        lt_cuscon    TYPE TABLE OF /psyng/sw_cuscon WITH HEADER LINE,
        lt_conowner  TYPE TABLE OF /psyng/conowner WITH HEADER LINE,
*        ls_swsodvers TYPE /psyng/swsodvers,
        lt_swsodorgo TYPE TABLE OF /psyng/swsodorgo WITH HEADER LINE.

  DATA:
*- Begin of Comment <NSINGH> 04/29/2020
*        lt_function_final  TYPE TABLE OF /psyng/function
*        WITH HEADER LINE,
*        lt_functtran_final TYPE TABLE OF /psyng/functtran
*        WITH HEADER LINE,
*        lt_faobj_final     TYPE TABLE OF /psyng/faobj2
*        WITH HEADER LINE,
*        lt_conflict_final  TYPE TABLE OF /psyng/conflict
*        WITH HEADER LINE,
*- End of Comment <NSINGH>
        lt_confdet_final   TYPE TABLE OF /psyng/confdet
        WITH HEADER LINE,
        lt_conowner_final  TYPE TABLE OF /psyng/conowner
        WITH HEADER LINE,
        lt_texts_final     TYPE TABLE OF /psyng/texts
        WITH HEADER LINE.


  DATA: ls_function  TYPE /psyng/function,
        ls_functtran TYPE /psyng/functtran,
        ls_faobj     TYPE /psyng/faobj2,
        ls_conflict  TYPE /psyng/conflict,
        ls_confdet   TYPE /psyng/confdet,
*- Begin of Comment <NSINGH> 04/29/2020
*        ls_critcodes TYPE /psyng/critcodes,
*        ls_swaudhdr  TYPE /psyng/swaudhdr,
*        ls_swaudc    TYPE /psyng/swaudc2,
*        ls_criroles  TYPE /psyng/criroles,
*        ls_criprof   TYPE /psyng/criprof,
*        ls_mchdr     TYPE /psyng/mchdr,
*        ls_cuscon    TYPE /psyng/sw_cuscon,
*- End of Comment <NSINGH>
        ls_texts     TYPE /psyng/texts,
        ls_conowner  TYPE /psyng/conowner.



  DATA : ls_faobj2        LIKE /psyng/faobj2,
         ls_objects       LIKE tobj,
*- Begin of Comment <NSINGH> 04/29/2020
*         lv_index         TYPE i,
*         lf_no_auth       TYPE /psyng/bapiflagx,
*         lv_function      TYPE /psyng/function_id,
*- End of Comment <NSINGH>
         lv_conflict      TYPE /psyng/conflict_id,
         ls_dd03l         TYPE dd03l.

  DATA : lv_conflict_len   TYPE i,
         lv_function_len   TYPE i,
         lv_group_len      TYPE i,
         lv_conflict_len1  TYPE i,
         lv_function_len1  TYPE i,
         lv_group_len1     TYPE i,
         lv_total_len      TYPE numc3.

*  FIELD-SYMBOLS : <fs> TYPE ANY. "<NSINGH>--
* BOC by RGUPTA on 08.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 08.04.22 for C0700
  CALL FUNCTION '/PSYNG/SW_AO_002'
   EXPORTING
     i_sodvrsio             = i_source_vrsio
   TABLES
     et_tobj                = lt_objects_temp
     et_list                = lt_org_elements
 EXCEPTIONS
   version_no_exist       = 1
   OTHERS                 = 2
            .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  SORT lt_objects_temp BY fiel1.
  SORT it_fields       BY field.

  LOOP AT lt_objects_temp INTO ls_objects.
    READ TABLE it_fields TRANSPORTING NO FIELDS
            WITH KEY field = ls_objects-fiel1.
    IF sy-subrc = 0.
      COLLECT ls_objects INTO lt_objects.
    ENDIF.
  ENDLOOP.
  SORT lt_objects BY objct fiel1.

******* Fields Check Tables
*- Begin of Comment <NSINGH> 04/29/2020
*  LOOP AT it_fields.
*    lt_auth_fields-field = it_fields-field.
*    APPEND lt_auth_fields .
*  ENDLOOP.
*  IF NOT lt_auth_fields[] IS INITIAL.
*    LOOP AT lt_auth_fields.
*
*      SELECT domname
*        INTO lt_auth_fields-domname
*        UP TO 1 ROWS
*        FROM dd04l
*        WHERE rollname = lt_auth_fields-field.
*        EXIT.
*      ENDSELECT.
*
*      IF lt_auth_fields-domname IS INITIAL.
*        lt_auth_fields-domname = lt_auth_fields-field.
*      ENDIF.
*
*      SELECT entitytab
*        INTO lt_auth_fields-table
*        UP TO 1 ROWS
*        FROM dd01l
*        WHERE domname = lt_auth_fields-domname.
*        EXIT.
*      ENDSELECT.
*
*      MODIFY lt_auth_fields.
*    ENDLOOP.
*  ENDIF.
*- End of Comment <NSINGH>

********Retrieve entire conflict repository (version specific)
  CALL FUNCTION '/PSYNG/SW_051'
   EXPORTING
     i_vrsio            = i_source_vrsio
   TABLES
     et_function        = lt_function
     et_functtran       = lt_functtran
     et_faobj           = lt_faobj
     et_conflict        = lt_conflict
     et_confdet         = lt_confdet
     et_mchdr           = lt_mchdr
     et_mctran          = lt_mctran
     et_mcrepid         = lt_mcrepid
     et_critcodes       = lt_critcodes
     et_swaudhdr        = lt_swaudhdr
     et_swaudc          = lt_swaudc
     et_criroles        = lt_criroles
     et_criprof         = lt_criprof
     et_texts           = lt_texts
     et_cuscon          = lt_cuscon
     et_conowner        = lt_conowner
     et_mcauditor       = lt_mcauditor
     et_swsodorgo       = lt_swsodorgo
   EXCEPTIONS
     version_not_exist  = 1
  OTHERS                = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
********Checking length of Conflicts and
  LOOP AT it_var_element_group.
    lv_group_len1 = strlen( it_var_element_group-field ).
    IF lv_group_len1 > lv_group_len.
      lv_group_len = lv_group_len1.
    ENDIF.
  ENDLOOP.

  SELECT SINGLE * INTO ls_dd03l FROM dd03l
          WHERE tabname   = '/PSYNG/FUNCTION'
            AND fieldname = 'FUNCTION'."#EC SAST_CI_GEN_CHECK

  LOOP AT lt_function.
    lv_function_len1 = strlen( lt_function-function ).
    IF lv_function_len1 > lv_function_len.
      lv_function_len = lv_function_len1.
    ENDIF.
  ENDLOOP.

  lv_total_len = lv_function_len + lv_group_len + 1.
  IF lv_total_len > ls_dd03l-leng.
    SHIFT lv_total_len LEFT DELETING LEADING '0'.
    SHIFT ls_dd03l-leng LEFT DELETING LEADING '0'.
    e_error = 'X'.
    e_msg1 = 'Max Function(s) length with combination'.
    e_msg2 = 'of Element Group is '.
    CONCATENATE lv_total_len '. Maximum allowed is '
                                INTO e_msg3.
    e_msg4 = ls_dd03l-leng.
   DELETE FROM /psyng/swsodvers WHERE vrsio = i_target_vrsio."<NSINGH>++
    EXIT.
  ENDIF.

  SELECT SINGLE * INTO ls_dd03l FROM dd03l
        WHERE tabname   = '/PSYNG/CONFLICT'
          AND fieldname = 'CONID'."#EC SAST_CI_GEN_CHECK

  LOOP AT lt_conflict.
    lv_conflict_len1 = strlen( lt_conflict-conid ).
    IF lv_conflict_len1 > lv_conflict_len.
      lv_function_len = lv_conflict_len1 .
    ENDIF.
  ENDLOOP.

  lv_total_len = lv_function_len + lv_group_len + 1.
  IF lv_total_len > ls_dd03l-leng.
    SHIFT lv_total_len LEFT DELETING LEADING '0'.
    SHIFT ls_dd03l-leng LEFT DELETING LEADING '0'.
    e_error = 'X'.
    e_msg1 = 'Max Conflict(s) length with combination'.
    e_msg2 = 'of Element Group is '.
    CONCATENATE lv_total_len '. Maximum allowed is '
                            INTO e_msg3.
    e_msg4 = ls_dd03l-leng.
   DELETE FROM /psyng/swsodvers WHERE vrsio = i_target_vrsio."<NSINGH>++
    EXIT.
  ENDIF.

****** Iterating to fetch the Functions relevant for ORG Level fields
  SORT lt_faobj BY funid.
  LOOP AT lt_faobj INTO ls_faobj2.
    READ TABLE lt_objects BINARY SEARCH
              WITH KEY objct = ls_faobj2-object.
    IF sy-subrc = 0.
      lt_functions-funid = ls_faobj2-funid .
      COLLECT lt_functions.
    ENDIF.
  ENDLOOP.
  SORT lt_functions BY funid.
  CLEAR: ls_faobj2.


****** Iterating to fetch the Conflicts relevant for ORG Level fields
  SORT lt_confdet BY conid.
  LOOP AT lt_confdet INTO ls_confdet.
    READ TABLE lt_functions BINARY SEARCH
                       WITH KEY funid = ls_confdet-functionid.
    IF sy-subrc = 0.
      lt_conflicts-conid = ls_confdet-conid.
      COLLECT lt_conflicts.
    ENDIF.
  ENDLOOP.
  SORT lt_conflicts BY conid.
  CLEAR : ls_confdet.

* Function header
  ls_function-vrsio = i_target_vrsio.
  ls_function-create_dat = sy-datum.
  ls_function-create_tim = sy-uzeit.
  ls_function-create_usr = l_current_user. "sy-uname. C0700

  CLEAR: ls_function-change_dat, ls_function-change_tim,
         ls_function-change_usr.
  MODIFY lt_function FROM ls_function
   TRANSPORTING vrsio create_dat create_tim create_usr change_dat
                      change_tim change_usr
         WHERE vrsio = i_source_vrsio.

* Function details
  ls_functtran-vrsio = i_target_vrsio.
  MODIFY lt_functtran FROM ls_functtran TRANSPORTING vrsio
         WHERE vrsio = i_source_vrsio.

* Function objects
  ls_faobj-vrsio = i_target_vrsio.
  ls_faobj-create_dat = sy-datum.
  ls_faobj-create_tim = sy-uzeit.
  ls_faobj-create_usr = l_current_user. "sy-uname. C0700

  CLEAR: ls_faobj-change_dat, ls_faobj-change_tim, ls_faobj-change_usr.
  MODIFY lt_faobj FROM ls_faobj
   TRANSPORTING vrsio create_dat create_tim create_usr change_dat
                      change_tim change_usr
         WHERE vrsio = i_source_vrsio.

  ls_conflict-vrsio = i_target_vrsio.
  ls_conflict-create_dat = sy-datum.
  ls_conflict-create_tim = sy-uzeit.
  ls_conflict-create_usr = l_current_user. "sy-uname. C0700
  CLEAR: ls_conflict-change_dat, ls_conflict-change_tim,
         ls_conflict-change_usr.
  MODIFY lt_conflict FROM ls_conflict TRANSPORTING vrsio
         WHERE vrsio = i_source_vrsio.

* Conflict owner.
  ls_conowner-vrsio = i_target_vrsio.
  MODIFY lt_conowner FROM ls_conowner TRANSPORTING vrsio
         WHERE vrsio = i_source_vrsio.

* Conflict details
  ls_confdet-vrsio = i_target_vrsio.
  MODIFY lt_confdet FROM ls_confdet TRANSPORTING vrsio
         WHERE vrsio = i_source_vrsio.

* All Texts
  ls_texts-vrsio = i_target_vrsio.
  MODIFY lt_texts FROM ls_texts TRANSPORTING vrsio
         WHERE vrsio = i_source_vrsio.
  SORT lt_texts BY textname object spras vrsio line.

*-- Delete the previous versions of the records that are currently
*   being uploaded
  IF NOT lt_function[] IS INITIAL.
    DELETE FROM /psyng/function
    WHERE vrsio = i_target_vrsio.
    DELETE FROM /psyng/functtran
    WHERE vrsio = i_target_vrsio .
    DELETE FROM /psyng/faobj2
    WHERE vrsio = i_target_vrsio .
    DELETE FROM /psyng/texts
    WHERE vrsio  = i_target_vrsio AND
          object = 'O' .
    DELETE FROM /psyng/sw_varel
    WHERE varel_vrsio = i_target_vrsio.
    COMMIT WORK.
  ENDIF.

*-- Delete the previous versions of the records that are currently
*   being uploaded
  IF NOT lt_conflict[] IS INITIAL.
    DELETE FROM /psyng/conflict
    WHERE vrsio = i_target_vrsio.
    DELETE FROM /psyng/confdet
    WHERE vrsio = i_target_vrsio.
    DELETE FROM /psyng/conowner
    WHERE vrsio = i_target_vrsio.
    DELETE FROM /psyng/texts
    WHERE vrsio  = i_target_vrsio AND
          object = 'C' .

    COMMIT WORK.
  ENDIF.

*- Begin of Addition <NSINGH> 04/29/2020
*- Copying Existing function into new SOD
  CALL FUNCTION '/PSYNG/SW_CREATE_SOD_FUNCTIONS'
    EXPORTING
      i_copy_exisiting_fun  = abap_true
      i_source_vrsio        = i_source_vrsio
      i_target_vrsio        = i_target_vrsio
      i_var_element_prefix  = i_var_element_prefix
      i_var_element_version = i_var_element_version
    TABLES
      it_var_element_group  = it_var_element_group
      it_function           = lt_function
      it_functtran          = lt_functtran
      it_faobj              = lt_faobj
      it_objects            = lt_objects
      it_texts              = lt_texts
      it_fields             = it_fields.

*- Create Organization specific function into new SOD
  CALL FUNCTION '/PSYNG/SW_CREATE_SOD_FUNCTIONS'
    EXPORTING
      i_copy_exisiting_fun  = space
      i_source_vrsio        = i_source_vrsio
      i_target_vrsio        = i_target_vrsio
      i_var_element_prefix  = i_var_element_prefix
      i_var_element_version = i_var_element_version
    TABLES
      it_var_element_group  = it_var_element_group
      it_function           = lt_function
      it_functtran          = lt_functtran
      it_faobj              = lt_faobj
      it_objects            = lt_objects
      it_texts              = lt_texts
      it_fields             = it_fields.
*- End of Addition <NSINGH>

  LOOP AT it_var_element_group.
*- Begin of Comment <NSINGH> 04/29/2020
*    LOOP AT lt_function INTO ls_function.
*      lv_index    = sy-tabix.
*      lv_function = ls_function-function.
***** Checking if function is ORG relevant
*      READ TABLE lt_functions BINARY SEARCH
*                  WITH KEY funid = lv_function.
*      IF sy-subrc = 0.
*        CONCATENATE lt_functions-funid it_var_element_group-field
*               INTO ls_function-function SEPARATED BY '_'.
*      ENDIF.
*
*      LOOP AT lt_functtran INTO lt_functtran_final
*              WHERE functionid = lv_function.
*        lt_functtran_final-functionid = ls_function-function.
*        APPEND lt_functtran_final.
*      ENDLOOP.
*
*      LOOP AT lt_faobj INTO lt_faobj_final WHERE funid = lv_function.
*        lt_faobj_final-funid = ls_function-function.
*        READ TABLE lt_objects BINARY SEARCH
*                             WITH KEY objct = lt_faobj_final-object
*                                      fiel1 = lt_faobj_final-field.
*        IF sy-subrc NE 0.
*          APPEND lt_faobj_final.
*        ENDIF.
*
*        READ TABLE lt_objects BINARY SEARCH
*                             WITH KEY objct = lt_faobj_final-object.
*        IF sy-subrc  = 0.
*******  Adding ORG Level Field
*          LOOP AT lt_objects WHERE objct = lt_faobj_final-object.
*            CLEAR : lt_faobj_final-val_to.
*            lt_faobj_final-field    = lt_objects-fiel1.
*            CONCATENATE i_var_element_prefix lt_objects-fiel1
*                        '_' it_var_element_group-field
*                        INTO lt_faobj_final-val_from.
*            APPEND lt_faobj_final.
*
****** Variable elements
*            READ TABLE lt_auth_fields WITH KEY field =
*lt_objects-fiel1.
*            lt_varel-tabname      =  lt_auth_fields-table.
*            lt_varel-field        =  lt_objects-fiel1.
*            lt_varel-varel_vrsio  =  i_var_element_version.
*            lt_varel-var_element  =  lt_faobj_final-val_from.
*            lt_varel-valueset     =  lt_faobj_final-valueset .
*            lt_varel-element      =  lt_objects-fiel1.
*            lt_varel-outputflag   = 'X'.
*            lt_varel-v_sign       = 'I'.
*            lt_varel-v_option     = 'EQ'.
*            lt_varel-val_from     = it_var_element_group-field.
*            APPEND lt_varel.
*          ENDLOOP.
*        ENDIF.
*      ENDLOOP.
*
*
*      LOOP AT lt_texts INTO lt_texts_final
*              WHERE textname = lv_function AND
*                    object   = 'F'.
*        lt_texts_final-textname = ls_function-function.
*        APPEND lt_texts_final.
*        DELETE lt_texts.
*      ENDLOOP.
*
*
*      CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
*           EXPORTING
*                wa_function             = ls_function
*                i_vrsio                 = i_target_vrsio
*           TABLES
*                texts                   = lt_texts_final
*                functtran               = lt_functtran_final
*                faobj                   = lt_faobj_final
*           EXCEPTIONS
*                target_not_specified    = 1
*                not_authorized          = 2
*                function_already_exists = 3
*                locked                  = 4
*                OTHERS                  = 5.
*
*      IF sy-subrc = 2.
*        lf_no_auth = 'X'.
*        DELETE lt_function INDEX lv_index.
*      ENDIF.
*
*      REFRESH: lt_functtran_final, lt_faobj_final, lt_texts_final.
*      CLEAR : lt_varel.
*    ENDLOOP.
*- End of Comment <NSINGH>
*--
    LOOP AT lt_conflict INTO ls_conflict.
*      lv_index     = sy-tabix. "<NSINGH>--
      lv_conflict  = ls_conflict-conid.
**** Checking if Conflict is ORG relevant
      READ TABLE lt_conflicts BINARY SEARCH
                  WITH KEY conid = lv_conflict.
      IF sy-subrc = 0.
        CONCATENATE lt_conflicts-conid it_var_element_group-field
               INTO ls_conflict-conid SEPARATED BY '_'.
      ENDIF.


      LOOP AT lt_confdet INTO lt_confdet_final
              WHERE conid = lv_conflict.
        lt_confdet_final-conid = ls_conflict-conid.
**** Checking if function is ORG relevant
        READ TABLE lt_functions BINARY SEARCH
                    WITH KEY funid = lt_confdet_final-functionid.
        IF sy-subrc = 0.
          APPEND lt_confdet_final. "<NSINGH>++
          CONCATENATE lt_functions-funid it_var_element_group-field
                 INTO lt_confdet_final-functionid SEPARATED BY '_'.
        ENDIF.
        APPEND lt_confdet_final.
      ENDLOOP.

*- Begin of Addition <NSINGH> 04/27/2020
      IF NOT lt_confdet_final[] IS INITIAL.
        SORT lt_confdet_final[] BY functionid.
        DELETE ADJACENT DUPLICATES FROM lt_confdet_final[]
                                                   COMPARING functionid.
      ENDIF.
*- End of Addition <NSINGH>

      LOOP AT lt_conowner INTO lt_conowner_final
              WHERE conid = lv_conflict.
        lt_conowner_final-conid = ls_conflict-conid.
        APPEND lt_conowner_final.
      ENDLOOP.

      LOOP AT lt_texts INTO lt_texts_final
                              WHERE textname = lv_conflict
                              AND   object   = 'C'.

        lt_texts_final-textname = ls_conflict-conid.
        APPEND lt_texts_final.
        DELETE lt_texts.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
           EXPORTING
                wa_conflict           = ls_conflict
                i_vrsio               = i_target_vrsio
           TABLES
                texts                 = lt_texts_final
                confdet               = lt_confdet_final
                conowner              = lt_conowner_final
           EXCEPTIONS
                target_not_specified  = 1
                target_already_exists = 2
                not_authorized        = 3
                locked                = 4
                OTHERS                = 5.

*- Begin of Change <NSINGH> 04/29/2020
*      IF sy-subrc = 3.
      IF sy-subrc <> 0.
*        lf_no_auth = 'X'.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*- End of Change <NSINGH>
      ENDIF.

      REFRESH: lt_confdet_final, lt_conowner_final, lt_texts_final.
    ENDLOOP.
  ENDLOOP. " Variable Element Group Loop


*- Create Variable Elements
*- Begin of Comment <NSINGH> 04/29/2020
*  SORT lt_varel BY var_element.
*  DELETE ADJACENT DUPLICATES FROM lt_varel COMPARING var_element.
*
*  MODIFY /psyng/sw_varel FROM TABLE lt_varel.
*- End of Comment <NSINGH>

ENDFUNCTION.
