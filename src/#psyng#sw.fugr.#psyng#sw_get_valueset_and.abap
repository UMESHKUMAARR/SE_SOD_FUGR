FUNCTION /psyng/sw_get_valueset_and.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IT_MATCH_AUTH_IN) TYPE  /PSYNG/MATCH_VALUESET_FOR_AND
*"       OPTIONAL
*"     VALUE(IT_FAOBJ) TYPE  /PSYNG/SW_TAB_FAOBJ OPTIONAL
*"  EXPORTING
*"     VALUE(ET_MATCH_AUTH_OUT) TYPE  /PSYNG/MATCH_VALUESET_FOR_AND
*"     VALUE(ET_MATCH_USER_OUT) TYPE  /PSYNG/MATCH_VALUESET_USER_AND
*"----------------------------------------------------------------------
  TYPES : BEGIN OF ty_valuesets,
            vrsio TYPE /psyng/sw_faobj2-vrsio,
            funid TYPE /psyng/sw_faobj2-funid,
            tcode TYPE /psyng/sw_faobj2-tcode,
            object TYPE /psyng/object,
          count TYPE i,
          END OF ty_valuesets .


  DATA : lt_faobj TYPE STANDARD TABLE OF /psyng/sw_faobj2,
        ls_faobj TYPE /psyng/sw_faobj2,
        lt_faobj_u TYPE STANDARD TABLE OF /psyng/sw_faobj2,
        lt_faobj_valueset TYPE STANDARD TABLE OF /psyng/sw_faobj2,
        ls_faobj_valueset TYPE  /psyng/sw_faobj2,
        lt_faobj_t TYPE STANDARD TABLE OF ty_valuesets,
        ls_faobj_u TYPE /psyng/sw_faobj2,
        ls_faobj_t TYPE ty_valuesets,
        ls_faobj_bad  TYPE /psyng/sw_faobj2,
        ls_faobj_good  TYPE /psyng/sw_faobj2,
        lt_faobj_bad  TYPE STANDARD TABLE OF /psyng/sw_faobj2,
        lt_faobj_good  TYPE STANDARD TABLE OF /psyng/sw_faobj2,
        lt_match_in TYPE STANDARD TABLE OF /psyng/match_obj,
        lt_match_in_t TYPE STANDARD TABLE OF /psyng/match_obj,
        lt_match_in_auth TYPE STANDARD TABLE OF /psyng/match_obj,
        ls_match_in_auth TYPE  /psyng/match_obj,
        ls_match_in TYPE  /psyng/match_obj ,
        ls_match_in_t TYPE  /psyng/match_obj ,
        lv_cfg_value TYPE /psyng/param_value,

        lt_usr_auth TYPE STANDARD TABLE OF /psyng/match_usr,
        lt_usr_auth_t TYPE STANDARD TABLE OF /psyng/match_usr,
        lt_usr_auth_final TYPE STANDARD TABLE OF /psyng/match_usr,
        ls_usr_auth TYPE  /psyng/match_usr.


  DATA : lt_vrs_and TYPE STANDARD TABLE OF /psyng/vrs_and,
         ls_vrs_and TYPE /psyng/vrs_and,
         lv_valueset_and_flag TYPE flag,
         l_field_val_access TYPE flag.
  FIELD-SYMBOLS : <fs_faobj_t> TYPE ty_valuesets.
  IF NOT it_match_auth_in IS INITIAL.
    CLEAR lt_match_in[].
    lt_match_in[] = it_match_auth_in[].
  ENDIF.
  IF NOT it_faobj IS INITIAL.
    CLEAR lt_faobj[].
    lt_faobj[] = it_faobj[].

    SORT lt_faobj BY vrsio funid tcode object valueset
                     field  val_from val_to.
    CLEAR lt_faobj_u[].
    lt_faobj_u[] = lt_faobj[].
    SORT lt_faobj_u BY vrsio funid tcode object valueset.
    DELETE ADJACENT DUPLICATES FROM lt_faobj_u COMPARING vrsio funid
              tcode object valueset ."get data with unique valusets
  ENDIF.


  CLEAR lv_valueset_and_flag.
*determining the relation between Valuesets
  IF NOT lt_faobj_u[] IS INITIAL.
    READ TABLE lt_faobj_u INTO ls_faobj_u INDEX 1.
    SELECT SINGLE *
      FROM /psyng/vrs_and
      INTO  ls_vrs_and
       WHERE vrsio EQ ls_faobj_u-vrsio AND
             valueset_and EQ 'X'.
    IF sy-subrc EQ 0.
      lv_valueset_and_flag = 'X' .
    ELSE.
      CLEAR lv_valueset_and_flag.
    ENDIF.
  ENDIF.


  CLEAR :ls_faobj_u,
         ls_vrs_and.

  SORT it_match_auth_in BY funid tcode objct field von bis.
  SORT lt_match_in BY funid tcode objct field von bis.
  CLEAR : ls_match_in,
          ls_faobj_u,
          ls_faobj,
          ls_faobj_bad,
          ls_faobj_good,
          lt_faobj_bad[],
          lt_faobj_good[],
          ls_usr_auth,
          lt_usr_auth[].
  REFRESH : lt_faobj_t[].
  LOOP AT lt_faobj_u INTO ls_faobj_u.

    ls_faobj_t-vrsio = ls_faobj_u-vrsio.
    ls_faobj_t-funid = ls_faobj_u-funid .
    ls_faobj_t-tcode = ls_faobj_u-tcode .
    ls_faobj_t-object = ls_faobj_u-object .
    ls_faobj_t-count = 1.

    COLLECT ls_faobj_t INTO lt_faobj_t.

  ENDLOOP.

  IF lv_valueset_and_flag EQ 'X'.
    LOOP AT lt_faobj_u INTO ls_faobj_u."this contain unique valuset
      READ TABLE lt_faobj_t INTO ls_faobj_t WITH KEY
                  vrsio = ls_faobj_u-vrsio
                  funid = ls_faobj_u-funid
                  tcode = ls_faobj_u-tcode
                  object  = ls_faobj_u-object.
      IF sy-subrc EQ 0.
        LOOP AT lt_faobj INTO ls_faobj WHERE
                                      object  = ls_faobj_u-object AND
                                      valueset = ls_faobj_u-valueset .
     "Check these entries as they are associated with AND logic from IBS
          CLEAR ls_match_in.

          READ TABLE lt_match_in INTO ls_match_in
            WITH KEY funid = ls_faobj-funid
                     tcode = ls_faobj-tcode
                     objct = ls_faobj-object
                     field = ls_faobj-field
                     von   = ls_faobj-val_from
                     bis   = ls_faobj-val_to BINARY SEARCH.
          IF sy-subrc NE 0.
            ls_faobj_bad-mandt       =      ls_faobj-mandt.
            ls_faobj_bad-vrsio       =      ls_faobj-vrsio.
            ls_faobj_bad-funid       =      ls_faobj-funid.
            ls_faobj_bad-tcode       =      ls_faobj-tcode.
            ls_faobj_bad-object      =      ls_faobj-object.
            ls_faobj_bad-valueset    =      ls_faobj-valueset.
            ls_faobj_bad-field       =      ls_faobj-field.
            ls_faobj_bad-val_from    =      ls_faobj-val_from.
            ls_faobj_bad-val_to      =      ls_faobj-val_to.
            ls_faobj_bad-create_usr  =      ls_faobj-create_usr.
            ls_faobj_bad-create_dat  =      ls_faobj-create_dat.
            ls_faobj_bad-create_tim  =      ls_faobj-create_tim.
            ls_faobj_bad-change_usr  =      ls_faobj-change_usr.
            ls_faobj_bad-change_dat  =      ls_faobj-change_dat.
            ls_faobj_bad-change_tim  =      ls_faobj-change_tim.
            ls_faobj_bad-obj_or      =      ls_faobj-obj_or.
            ls_faobj_bad-fld_and     =      ls_faobj-fld_and.
            APPEND ls_faobj_bad TO lt_faobj_bad.
          ELSE.
            ls_faobj_good-mandt       =      ls_faobj-mandt.
            ls_faobj_good-vrsio       =      ls_faobj-vrsio.
            ls_faobj_good-funid       =      ls_faobj-funid.
            ls_faobj_good-tcode       =      ls_faobj-tcode.
            ls_faobj_good-object      =      ls_faobj-object.
            ls_faobj_good-valueset    =      ls_faobj-valueset.
            ls_faobj_good-field       =      ls_faobj-field.
            ls_faobj_good-val_from    =      ls_faobj-val_from.
            ls_faobj_good-val_to      =      ls_faobj-val_to.
            ls_faobj_good-create_usr  =      ls_faobj-create_usr.
            ls_faobj_good-create_dat  =      ls_faobj-create_dat.
            ls_faobj_good-create_tim  =      ls_faobj-create_tim.
            ls_faobj_good-change_usr  =      ls_faobj-change_usr.
            ls_faobj_good-change_dat  =      ls_faobj-change_dat.
            ls_faobj_good-change_tim  =      ls_faobj-change_tim.
            ls_faobj_good-obj_or      =      ls_faobj-obj_or.
            ls_faobj_good-fld_and     =      ls_faobj-fld_and.
            APPEND ls_faobj_good TO lt_faobj_good.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDLOOP.

    SORT lt_faobj_bad  BY funid tcode object field val_from val_to.
    SORT lt_faobj_good BY funid tcode object field val_from val_to.
    CLEAR ls_match_in.
    LOOP AT it_match_auth_in INTO ls_match_in.
      CLEAR ls_faobj_bad.
      "check if any object found in bad table
      READ TABLE lt_faobj_bad INTO ls_faobj_bad WITH KEY
                                  funid = ls_match_in-funid
                                  tcode = ls_match_in-tcode
                                  object = ls_match_in-objct
                                  field  = ls_match_in-field
*                                  val_from = ls_match_in-von
*                                  val_to   = ls_match_in-bis
                                  BINARY SEARCH.
      IF sy-subrc EQ 0.
        "check if relation between fields in AND or OR
        IF ls_faobj_bad-fld_and EQ space.
          " if relation between field values is OR and entry found in
          " good table as well, that means access is available
          READ TABLE lt_faobj_good INTO ls_faobj_good WITH KEY
                                  funid = ls_match_in-funid
                                  tcode = ls_match_in-tcode
                                  object = ls_match_in-objct
                                  field  = ls_match_in-field
                                  BINARY SEARCH.
          IF sy-subrc NE 0.
            "if entry not found in Good table, delete that object
            " from matching auths
            DELETE lt_match_in WHERE funid = ls_faobj_bad-funid AND
                                     tcode = ls_faobj_bad-tcode AND
                                     objct = ls_faobj_bad-object.
          ENDIF.

        ELSE.
          " if relation between field values is AND and entry found in
          " bad table, delete object straight away.
          DELETE lt_match_in WHERE funid = ls_faobj_bad-funid AND
                                      tcode = ls_faobj_bad-tcode AND
                                      objct = ls_faobj_bad-object.
        ENDIF.

      ENDIF.
    ENDLOOP.

*--> After getting all the matchinbg auths, now check complete valusets
*--> for the matching auths
    lt_match_in_t[] = lt_match_in[].
    SORT lt_match_in_t BY funid tcode objct auth.
    SORT lt_faobj BY vrsio funid tcode object valueset.

    LOOP AT lt_match_in_t INTO ls_match_in.
      CLEAR ls_match_in_t.
      MOVE-CORRESPONDING ls_match_in TO ls_match_in_t.
      APPEND ls_match_in TO lt_match_in_auth.
      AT END OF auth. "Create groups of auths
        LOOP AT lt_faobj INTO ls_faobj WHERE
            funid     = ls_match_in_t-funid AND
            tcode     = ls_match_in_t-tcode AND
            object    = ls_match_in_t-objct .
          APPEND ls_faobj TO lt_faobj_valueset.
          AT END OF valueset. "Create groups of valuesets
            CLEAR ls_match_in_auth.
            LOOP AT lt_match_in_auth INTO ls_match_in_auth.
              CLEAR ls_faobj_valueset.
              READ TABLE lt_faobj_valueset INTO ls_faobj_valueset
               WITH KEY funid     = ls_match_in_auth-funid
                        tcode     = ls_match_in_auth-tcode
                        object    = ls_match_in_auth-objct
                        field     = ls_match_in_auth-field
                        val_from  = ls_match_in_auth-von
                        val_to    = ls_match_in_auth-bis .
              IF sy-subrc EQ 0.
                CLEAR ls_usr_auth.
                ls_usr_auth-funid = ls_match_in_auth-funid.
                ls_usr_auth-tcode = ls_match_in_auth-tcode.
                ls_usr_auth-objct = ls_match_in_auth-objct.
                ls_usr_auth-auth  = ls_match_in_auth-auth.
                ls_usr_auth-field = ls_match_in_auth-field.
                ls_usr_auth-von   = ls_match_in_auth-von.
                ls_usr_auth-bis   = ls_match_in_auth-bis .
                ls_usr_auth-valueset = ls_faobj_valueset-valueset.
                APPEND ls_usr_auth TO lt_usr_auth_t.
              ENDIF.
            ENDLOOP.

            SORT lt_usr_auth_t BY funid
                                  tcode
                                  objct
                                  field
                                  von
                                  bis
                                  valueset .
            "Check completeness of Valuesets.
            CLEAR : ls_faobj_valueset,ls_usr_auth.
            LOOP AT lt_faobj_valueset INTO ls_faobj_valueset.
              READ TABLE lt_usr_auth_t INTO ls_usr_auth
              WITH KEY funid       = ls_faobj_valueset-funid
                       tcode       = ls_faobj_valueset-tcode
                       objct       = ls_faobj_valueset-object
                       field       = ls_faobj_valueset-field
                       von         = ls_faobj_valueset-val_from
                       bis         = ls_faobj_valueset-val_to
                       valueset    = ls_faobj_valueset-valueset
                       BINARY SEARCH.
              IF sy-subrc EQ 0.
                l_field_val_access = 'X'.
              ELSE.
"Check relation between field values(Plug is ON or OFF) :

                IF ls_faobj_valueset-fld_and EQ 'X'.
                  REFRESH lt_usr_auth_t[].
                ENDIF.
              ENDIF.

              AT END OF field.
                IF l_field_val_access NE 'X'. "
                  REFRESH lt_usr_auth_t[].
                ENDIF.
                CLEAR : l_field_val_access.
              ENDAT.

            ENDLOOP.
            APPEND LINES OF lt_usr_auth_t TO lt_usr_auth_final.
            REFRESH lt_usr_auth_t[].
            REFRESH lt_faobj_valueset[].
          ENDAT.
        ENDLOOP.
        REFRESH lt_match_in_auth[].
      ENDAT.
    ENDLOOP.

    SORT lt_usr_auth_final BY funid tcode objct auth field
         von bis valueset.
    DELETE ADJACENT DUPLICATES FROM lt_usr_auth_final
    COMPARING  ALL FIELDS.
*    COMPARING  funid tcode objct field.
  ENDIF.

  et_match_auth_out[] = lt_match_in[].
  et_match_user_out[] = lt_usr_auth_final[].






ENDFUNCTION.
