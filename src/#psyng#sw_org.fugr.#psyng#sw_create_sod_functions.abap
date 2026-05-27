FUNCTION /psyng/sw_create_sod_functions.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_COPY_EXISITING_FUN) TYPE  FLAG OPTIONAL
*"     REFERENCE(I_SOURCE_VRSIO) TYPE  /PSYNG/FUNCTION-VRSIO DEFAULT
*"       000
*"     REFERENCE(I_TARGET_VRSIO) TYPE  /PSYNG/FUNCTION-VRSIO
*"     REFERENCE(I_VAR_ELEMENT_PREFIX) TYPE  /PSYNG/SE_VAREL DEFAULT
*"       '/PSYNG/$'
*"     REFERENCE(I_VAR_ELEMENT_VERSION) TYPE  /PSYNG/VE_VRSIO
*"  TABLES
*"      IT_VAR_ELEMENT_GROUP STRUCTURE  /PSYNG/ORGFIELD OPTIONAL
*"      IT_FUNCTION STRUCTURE  /PSYNG/FUNCTION OPTIONAL
*"      IT_FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      IT_FAOBJ STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"      IT_OBJECTS STRUCTURE  TOBJ OPTIONAL
*"      IT_TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"      IT_FIELDS STRUCTURE  /PSYNG/ORGFIELD OPTIONAL
*"----------------------------------------------------------------------
************************************************************************
*                     T Y P E - P O O L S                              *
************************************************************************
  TYPE-POOLS abap.

************************************************************************
*                    T A B L E - T Y P E S                             *
************************************************************************

  TYPES : BEGIN OF ty_dd04l,
           rollname   TYPE dd04l-rollname,
           domname TYPE dd04l-domname,
          END OF ty_dd04l,

          BEGIN OF ty_dd01l,
            domname  TYPE dd01l-domname,
           entitytab TYPE dd01l-entitytab,
          END OF ty_dd01l,

          BEGIN OF ty_functions,
            funid   TYPE /psyng/function_id,
          END   OF ty_functions,

          BEGIN OF ty_auth_fields,
            field   TYPE authx-fieldname,
            table   TYPE authx-checktable,
            domname  TYPE dd01l-domname,
          END OF ty_auth_fields.

************************************************************************
*                    D A T A  D E C L A R A T I O N                    *
************************************************************************
  DATA: lt_functions       TYPE  TABLE OF ty_functions,
        ls_functions       TYPE ty_functions,

        lt_auth_fields     TYPE TABLE OF ty_auth_fields,
        ls_auth_fields     TYPE ty_auth_fields,

        lt_varel           TYPE TABLE OF /psyng/sw_varel,
        ls_varel           TYPE /psyng/sw_varel,

        lt_functtran_final TYPE TABLE OF /psyng/functtran,
        ls_functtran_final TYPE /psyng/functtran,

        lt_faobj_final     TYPE TABLE OF /psyng/faobj2,
        ls_faobj_final     TYPE /psyng/faobj2,

        lt_texts_final     TYPE TABLE OF /psyng/texts,
        ls_texts_final     TYPE /psyng/texts,

        lt_dd04l           TYPE TABLE OF ty_dd04l,
        ls_dd04l           TYPE  ty_dd04l,

        lt_dd01l           TYPE TABLE OF ty_dd01l,
        ls_dd01l           TYPE  ty_dd01l.

  DATA: ls_function        TYPE /psyng/function,
        ls_objects         TYPE tobj,
        lv_index           TYPE sy-tabix,
        lv_function        TYPE /psyng/function_id,
        ls_faobj2          TYPE /psyng/faobj2,
        lv_functtran_index TYPE sy-tabix,
        lv_faobj_index     TYPE sy-tabix.

************************************************************************
*                    F I E L D - S Y M B O L S                         *
************************************************************************
  FIELD-SYMBOLS <fs_auth_fields> TYPE ty_auth_fields.

************************************************************************
*                    C O N S T A N T S                                 *
************************************************************************
  CONSTANTS: lc_psyng       TYPE c VALUE '/PSYNG/-' LENGTH 8,
             lc_underscore  TYPE c VALUE '_',
             lc_actvt       TYPE /psyng/faobj2-field      VALUE 'ACTVT',
             lc_or          TYPE /psyng/faobj2-obj_or     VALUE 'OR',
             lc_i           TYPE /psyng/sw_varel-v_sign   VALUE 'I',
             lc_eq          TYPE /psyng/sw_varel-v_option VALUE 'EQ',
             lc_f           TYPE /psyng/texts-object      VALUE 'F'.

* BOC by RGUPTA on 08.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 08.04.22 for C0700
  LOOP AT it_fields.
*- Type Compatible
    ls_auth_fields-field = it_fields-field.
    APPEND ls_auth_fields TO lt_auth_fields.
    CLEAR ls_auth_fields.
  ENDLOOP.

  IF NOT lt_auth_fields[] IS INITIAL.
*- Fetching Data elements.
    SELECT rollname        "Data element (semantic domain)
           domname         "Domain name
           INTO TABLE lt_dd04l
           FROM dd04l
           FOR ALL ENTRIES IN lt_auth_fields
    WHERE rollname = lt_auth_fields-field."#EC SAST_CI_GEN_CHECK

    IF NOT lt_dd04l[] IS INITIAL.
      SORT lt_dd04l[] BY rollname domname.
      DELETE ADJACENT DUPLICATES FROM lt_dd04l[]
                                      COMPARING rollname domname.
*- Fetching Domains.
      SELECT domname     "Domain name
             entitytab   "Value table
             INTO TABLE lt_dd01l
             FROM dd01l
             FOR ALL ENTRIES IN lt_dd04l
     WHERE domname = lt_dd04l-domname."#EC SAST_CI_GEN_CHECK

      SELECT domname     "Domain name
             entitytab   "Value table
             APPENDING TABLE lt_dd01l
             FROM dd01l
             FOR ALL ENTRIES IN lt_auth_fields
          WHERE domname = lt_auth_fields-field."#EC SAST_CI_GEN_CHECK
    ENDIF.

    IF NOT lt_dd01l[] IS INITIAL.
      SORT lt_dd01l[] BY domname entitytab.
      DELETE ADJACENT DUPLICATES FROM lt_dd01l[]
                                 COMPARING  domname entitytab.
    ENDIF.

    LOOP AT lt_auth_fields ASSIGNING <fs_auth_fields>.
      READ TABLE lt_dd04l INTO ls_dd04l WITH KEY
                                       rollname = <fs_auth_fields>-field
                                       BINARY SEARCH.
      IF sy-subrc = 0.
        <fs_auth_fields>-domname = ls_dd04l-domname.
      ELSE.
        <fs_auth_fields>-domname = <fs_auth_fields>-field.
      ENDIF.

      READ TABLE lt_dd01l INTO ls_dd01l WITH KEY
                                     domname = <fs_auth_fields>-domname
                                     BINARY SEARCH.
      IF sy-subrc = 0.
        <fs_auth_fields>-table = ls_dd01l-entitytab.
      ENDIF.
      CLEAR: ls_dd04l, ls_dd01l.
    ENDLOOP.

    IF NOT lt_auth_fields[] IS INITIAL.
      SORT lt_auth_fields[] BY field.
    ENDIF.

*- Unassiging Field-Symbol.
    IF  <fs_auth_fields> IS ASSIGNED.
      UNASSIGN  <fs_auth_fields>.
    ENDIF.
  ENDIF.


*- Iterating to fetch the Functions relevant for ORG Level fields
  SORT it_faobj[] BY funid.
  SORT it_objects[] BY objct fiel1.

  LOOP AT it_faobj INTO ls_faobj2.
    READ TABLE it_objects WITH KEY objct = ls_faobj2-object
                                   BINARY SEARCH.
    IF sy-subrc = 0.
      ls_functions-funid = ls_faobj2-funid.
      APPEND ls_functions TO lt_functions.
      CLEAR ls_functions.
    ENDIF.
    CLEAR ls_faobj2.
  ENDLOOP.

  IF NOT lt_functions[] IS INITIAL.
    SORT lt_functions[] BY funid.
    DELETE ADJACENT DUPLICATES FROM lt_functions[] COMPARING funid.
  ENDIF.

*- Function header
  ls_function-vrsio = i_target_vrsio.
  ls_function-create_dat = sy-datum.
  ls_function-create_tim = sy-uzeit.
  ls_function-create_usr = l_current_user. "sy-uname. C0700

  CLEAR: ls_function-change_dat, ls_function-change_tim,
         ls_function-change_usr.
  MODIFY it_function FROM ls_function TRANSPORTING
         vrsio create_dat create_tim create_usr change_dat change_tim
         change_usr  WHERE vrsio = i_source_vrsio.
  CLEAR ls_function.

  IF NOT it_functtran[] IS INITIAL.
    SORT it_functtran[] BY functionid tcode.
    DELETE ADJACENT DUPLICATES FROM it_functtran[] COMPARING
                                                   functionid tcode.
  ENDIF.


  LOOP AT it_var_element_group.
*- This Nested loop is unavoidable.
    LOOP AT it_function INTO ls_function.
      lv_index    = sy-tabix.
      lv_function = ls_function-function.
*- Checking if function is ORG relevant
      IF  i_copy_exisiting_fun IS INITIAL.
        READ TABLE lt_functions INTO ls_functions WITH KEY
                                                  funid = lv_function
                                                  BINARY SEARCH.

        IF sy-subrc = 0.
          CONCATENATE ls_functions-funid it_var_element_group-field
                 INTO ls_function-function SEPARATED BY lc_underscore.
        ELSE.
          CONTINUE.
        ENDIF.
      ENDIF.

*- Parallel Cursor used for better performance
      READ TABLE it_functtran WITH KEY functionid = lv_function
                                       BINARY SEARCH
                                       TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        lv_functtran_index = sy-tabix.
        LOOP AT it_functtran INTO ls_functtran_final FROM
                                                     lv_functtran_index.
          IF ls_functtran_final-functionid NE lv_function.
            EXIT.
          ENDIF.
          IF  i_copy_exisiting_fun IS INITIAL.
            CONCATENATE lc_psyng lv_function INTO
                                               ls_functtran_final-tcode.
            ls_functtran_final-functionid = ls_function-function.
          ENDIF.
          APPEND ls_functtran_final TO lt_functtran_final.
          CLEAR ls_functtran_final.
        ENDLOOP.
        CLEAR lv_functtran_index.
      ENDIF.

*- Parallel Cursor used for better performance
      READ TABLE it_faobj WITH KEY funid = lv_function BINARY SEARCH
                                   TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        lv_faobj_index = sy-tabix.

        LOOP AT it_faobj INTO ls_faobj_final FROM lv_faobj_index.

          IF  ls_faobj_final-funid NE lv_function.
            EXIT.
          ENDIF.
          ls_faobj_final-funid = ls_function-function.
          ls_faobj2 = ls_faobj_final.
          IF  i_copy_exisiting_fun IS INITIAL.
            CONCATENATE lc_psyng  lv_function INTO ls_faobj_final-tcode.
*- Adding ORG Level Field
            LOOP AT it_objects INTO ls_objects
                                    WHERE objct = ls_faobj_final-object.
              READ TABLE it_objects WITH KEY
                                      objct = ls_faobj_final-object
                                      fiel1 = ls_faobj_final-field
                                      TRANSPORTING NO FIELDS
                                      BINARY SEARCH.
              IF sy-subrc NE 0.
                CLEAR : ls_faobj_final-val_to.
                CONCATENATE i_var_element_prefix ls_objects-fiel1
                            lc_underscore it_var_element_group-field
                        INTO ls_faobj_final-val_from.
                ls_faobj_final-field = ls_objects-fiel1.
                ls_faobj_final-obj_or = lc_or.
*- Variable elements
                READ TABLE lt_auth_fields INTO ls_auth_fields
                                      WITH KEY field = ls_objects-fiel1
                                      BINARY SEARCH.
                IF sy-subrc = 0.
                  ls_varel-tabname      =  ls_auth_fields-table.
                ENDIF.
                ls_varel-field        =  ls_objects-fiel1.
                ls_varel-varel_vrsio  =  i_var_element_version.
                ls_varel-var_element  =  ls_faobj_final-val_from.
                ls_varel-valueset     =  ls_faobj_final-valueset .
                ls_varel-element      =  ls_objects-fiel1.
                ls_varel-outputflag   =  abap_true.
                ls_varel-v_sign       =  lc_i.
                ls_varel-v_option     =  lc_eq.
                ls_varel-val_from     =  it_var_element_group-field.
                APPEND ls_varel TO lt_varel.
                APPEND ls_faobj_final TO lt_faobj_final.
                CLEAR:  ls_varel.
              ENDIF.

              ls_faobj2-tcode = ls_faobj_final-tcode.
              IF ls_faobj2-field = lc_actvt.
                ls_faobj2-obj_or = lc_or.
                APPEND ls_faobj2 TO lt_faobj_final.
                CLEAR ls_faobj2.
              ENDIF.
              CLEAR ls_objects.
            ENDLOOP.
          ELSE.
            APPEND ls_faobj_final TO lt_faobj_final.
          ENDIF.
          CLEAR ls_faobj_final.
        ENDLOOP.
        CLEAR lv_faobj_index.
      ENDIF.

      LOOP AT it_texts INTO ls_texts_final
              WHERE textname = lv_function AND
                    object   = lc_f.
        ls_texts_final-textname = ls_function-function.
        APPEND ls_texts_final TO lt_texts_final.
        CLEAR ls_texts_final.
      ENDLOOP.


      CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
        EXPORTING
          wa_function             = ls_function
          i_vrsio                 = i_target_vrsio
        TABLES
          texts                   = lt_texts_final
          functtran               = lt_functtran_final
          faobj                   = lt_faobj_final
        EXCEPTIONS
          target_not_specified    = 1
          not_authorized          = 2
          function_already_exists = 3
          locked                  = 4
          OTHERS                  = 5.
      IF sy-subrc = 2.
        DELETE it_function[] INDEX lv_index.
      ENDIF.

      REFRESH: lt_functtran_final[], lt_faobj_final[], lt_texts_final[].
      CLEAR : ls_function.
    ENDLOOP.
  ENDLOOP.

*- Create Variable Elements
  IF NOT lt_varel[] IS INITIAL.
    SORT lt_varel BY var_element.
    DELETE ADJACENT DUPLICATES FROM lt_varel COMPARING var_element.
    MODIFY /psyng/sw_varel FROM TABLE lt_varel.
    REFRESH : lt_varel[].
  ENDIF.

  REFRESH : lt_functions[], lt_auth_fields[], lt_dd04l[], lt_dd01l[].

ENDFUNCTION.
