*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_UTLS_3BF01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  get_users_from_selection
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_EXLCKUSR  text
*      -->P_I_VALIDUSR  text
*      -->P_IT_BNAME  text
*----------------------------------------------------------------------*
FORM get_users_from_selection
  TABLES  it_bname     STRUCTURE /psyng/range_bname
          it_class     STRUCTURE /psyng/range_class
          it_usertype  STRUCTURE /psyng/sw_sel_opts_usrtyp
          it_actgroups STRUCTURE /psyng/sw_sel_opts_agr_name
          it_profiles  STRUCTURE /psyng/sw_sel_opts_profile
          et_users     STRUCTURE usr02
 USING    i_exlckusr   TYPE flag
          i_validusr   TYPE flag
          i_outvdate   TYPE flag.
  DATA :    l_include_locked TYPE flag,
            l_include_expire TYPE flag.
  IF i_validusr IS INITIAL.
    IF i_exlckusr = 'X'.
      CLEAR l_include_locked.
    ELSE.
      l_include_locked = 'X'.
    ENDIF.

    IF i_outvdate = 'X'.
      CLEAR l_include_expire.
    ELSE.
      l_include_expire = 'X'.
    ENDIF.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_041'
    EXPORTING
      i_validuser       = i_validusr
      i_include_locked  = l_include_locked
      i_include_expired = l_include_expire
    TABLES
      et_users          = et_users
      it_userlist       = it_bname
      it_grouplist      = it_class
      it_usertype       = it_usertype
      it_actgroups      = it_actgroups
      it_profile        = it_profiles.


ENDFORM.                    " get_users_from_selection
*&---------------------------------------------------------------------*
*&      Form  load_user_auths
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_FUNCTTRAN  text
*      -->P_IT_FAOBJ  text
*      -->P_LT_USERS  text
*      -->P_LT_USERTCODE  text
*      -->P_LT_USERPROF  text
*      -->P_LT_USERAUTH  text
*----------------------------------------------------------------------*
FORM load_user_auths

TABLES it_functtran STRUCTURE /psyng/functtran
       it_faobj     STRUCTURE /psyng/faobj2
       it_users     STRUCTURE usr02
       et_usertcode STRUCTURE /psyng/usertcode
       et_userprof  STRUCTURE /psyng/userprof
       et_userauth  STRUCTURE /psyng/userauth
   USING i_excl_er_roles TYPE flag. "(++)UMITTAL PN17376 18/02/2026

  DATA : l_local TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_local.
  LOOP AT it_users.
    CALL FUNCTION '/PSYNG/SW_GET_USER_AUTH_DATA'
      EXPORTING
        userid    = it_users-bname
        i_exclude_er_roles = i_excl_er_roles "(++)UMITTAL PN17376 18/02/2026
      TABLES
        functtran = it_functtran
        faobj     = it_faobj
        usertcode = et_usertcode
        userprof  = et_userprof
        userauth  = et_userauth
      EXCEPTIONS
        OTHERS    = 1. "#EC SAST_CI_GEN_CHECK
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
*--Handle placeholder tcodes
    LOOP AT it_functtran WHERE tcode CP
      /psyng/sw_cl_constants=>placeholder_tcode_prefix.
      et_usertcode-bname     = it_users-bname.
      et_usertcode-tcode     = it_functtran-tcode.
      et_usertcode-rfcdest   = l_local.
      INSERT TABLE et_usertcode .
    ENDLOOP.

  ENDLOOP.

ENDFORM.                    " load_user_auths
*&---------------------------------------------------------------------*
*&      Form  load_system_auths
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_FAOBJ  text
*      -->P_IT_FUNCTTRAN  text
*      -->P_LT_USERAUTH  text
*      -->P_LT_SYSTEMAUTHS  text
*----------------------------------------------------------------------*
FORM load_system_auths
TABLES   it_faobj       STRUCTURE /psyng/faobj2
         it_functtran   STRUCTURE /psyng/functtran
         it_userauth    STRUCTURE /psyng/userauth
         it_usertcode   STRUCTURE /psyng/usertcode
         it_swsodorgm   STRUCTURE /psyng/swsodorgm
         et_systemauths STRUCTURE /psyng/psswtcdaut
         et_orgauths    STRUCTURE /psyng/swsodorgauth.
  DATA : lt_uniqueauths TYPE TABLE OF /psyng/uniqueauths
                        WITH HEADER LINE,
         lt_tcodes      TYPE TABLE OF /psyng/psswtcd
                        WITH HEADER LINE.
  LOOP AT it_userauth.
    lt_uniqueauths-rfcdest = it_userauth-rfcdest.
    lt_uniqueauths-objct   = it_userauth-objct.
    lt_uniqueauths-auth    = it_userauth-auth.
    COLLECT lt_uniqueauths.
  ENDLOOP.
  LOOP AT it_usertcode.
    lt_tcodes-rfcdest = it_usertcode-rfcdest.
    lt_tcodes-tcode   = it_usertcode-tcode.
    COLLECT lt_tcodes.
  ENDLOOP.
  CALL FUNCTION '/PSYNG/SW_GET_TCODE_AUTH_DATA'
    TABLES
      tcd         = lt_tcodes
      faobj       = it_faobj
      functtran   = it_functtran
      tcdaut      = et_systemauths
      uniqueauths = lt_uniqueauths.
*--Get the org level authorizations
  CALL FUNCTION '/PSYNG/SW_024'
    EXPORTING
      i_fielddetails = 'X'
    TABLES
      swsodorgm      = it_swsodorgm
      uniqueauths    = lt_uniqueauths
      systemauths    = et_orgauths.


ENDFORM.                    " load_system_auths
*&---------------------------------------------------------------------*
*&      Form  analyze_user_functions
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_FAOBJ  text
*      -->P_IT_FUNCTTRAN  text
*      -->P_LT_USERAUTH  text
*      -->P_LT_USERTCODE  text
*      -->P_LT_SYSTEMAUTHS  text
*      -->P_IT_SWSODORGM  text
*      -->P_LT_ORGAUTHS  text
*      -->P_ET_OUTPUTDET  text
*      -->P_LT_USERS_BNAME  text
*----------------------------------------------------------------------*
FORM analyze_user_functions
  TABLES   it_faobj        STRUCTURE /psyng/faobj2
           it_functtran    STRUCTURE /psyng/functtran
           it_userauth     STRUCTURE /psyng/userauth
           it_usertcode    STRUCTURE /psyng/usertcode
           it_systemauths  STRUCTURE /psyng/psswtcdaut
           it_swsodorgm    STRUCTURE /psyng/swsodorgm
           it_orgauths     STRUCTURE /psyng/swsodorgauth
           it_unique_org_abb STRUCTURE /psyng/swsodorgm
           it_tcode_obj    STRUCTURE /psyng/faobj2
           it_org_objects  STRUCTURE /psyng/faobj2
           et_outputdet    STRUCTURE /psyng/sw_func_scan_det
           it_faobj_org    structure /psyng/faobj2          "OPL645
  USING    i_bname         TYPE xubname
        i_org_field     type flag.                       "OPL645

  DATA : l_obj_count_found        TYPE i,
         l_obj_count_total        TYPE i,
         l_obj_count_and          TYPE i,
         l_obj_count_or           TYPE i,
         l_obj_count_found_and    TYPE i,
         l_obj_count_found_or     TYPE i,
         l_obj_count_org          TYPE i,
         l_obj_count_org_optional TYPE i,

         lt_det_tmp               TYPE SORTED TABLE OF /psyng/sw_func_scan_det
                                  WITH UNIQUE KEY
                                    objct
                                    AUTH
                                    BNAME
                                    ORG_ABB
                                    FUNID
                                    PROFILE
                                    COMP_PROF
                                    TCODE
                                    FIELD
                                    VON
                                    BIS
                                    SIMU
                                    ENHANCED
                                    ER
                                  WITH HEADER LINE,
         lf_userhas               TYPE flag,
         lf_hasobject             TYPE flag,

         l_and(3)                 TYPE c,
         lf_obj_org               TYPE flag,
         lt_org_objects           TYPE HASHED TABLE OF xuobject
                                  WITH UNIQUE KEY table_line
                                  WITH HEADER LINE,
         lt_unique_org_abb        TYPE SORTED TABLE OF /psyng/dorg_abb
                                  WITH UNIQUE KEY table_line
                                  WITH HEADER LINE,
         lf_org_relevant          TYPE flag,
         lt_tcode_obj             TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
         l_cnt                    TYPE i,
         l_cnt_o                  TYPE i,
         l_systemauth_idx         TYPE sy-tabix,
         l_userauth_idx           TYPE sy-tabix,
         l_orgauth_idx            TYPE sy-tabix.
  DATA : BEGIN OF lt_org_obj_cnt OCCURS 0,
           abb        TYPE /psyng/dorg_abb,
           object_or  TYPE HASHED TABLE OF xuobject WITH UNIQUE KEY table_line,
           object_and TYPE HASHED TABLE OF xuobject WITH UNIQUE KEY table_line,
         END OF lt_org_obj_cnt,
         BEGIN OF ls_orgauths OCCURS 0,
           profn TYPE xuprofile.
          INCLUDE STRUCTURE /psyng/swsodorgauth.
  DATA : END OF ls_orgauths,
   BEGIN OF ls_orgauths_idx OCCURS 0,
           auth type xuauth,
           object type xuobject,
   END OF ls_orgauths_idx,
  lt_orgauths LIKE SORTED TABLE OF ls_orgauths
              WITH NON-UNIQUE KEY abb
              WITH HEADER LINE,
  lt_orgauths_idx LIKE HASHED TABLE OF ls_orgauths_idx
              WITH UNIQUE KEY auth object
              WITH HEADER LINE.

  FIELD-SYMBOLS <org_obj_cnt> LIKE lt_org_obj_cnt.

*BOC AKUMAR OPL645
  if i_org_field = 'X'.
    sort it_faobj_org by funid tcode object.
  endif.
*EOC AKUMAR OPL645

  SORT it_orgauths BY auth object.

  lt_det_tmp-bname = i_bname.

*--Create a list of objects that's org relevant
  lt_tcode_obj[] = it_tcode_obj[].
  LOOP AT it_unique_org_abb.
    lt_unique_org_abb = it_unique_org_abb-abb.
    INSERT TABLE lt_unique_org_abb.
  ENDLOOP.
  LOOP AT it_org_objects.
    lt_org_objects = it_org_objects-object.
    INSERT TABLE lt_org_objects.
  ENDLOOP.
  LOOP AT it_functtran.
    REFRESH : lt_det_tmp,lt_org_obj_cnt.
    CLEAR lt_org_obj_cnt.
    lt_det_tmp-bname = i_bname.
    CLEAR l_obj_count_org.
    LOOP AT it_usertcode WHERE bname = i_bname AND
                               tcode = it_functtran-tcode.
      CLEAR lf_userhas.
      lt_det_tmp-funid = it_functtran-functionid.
      lt_det_tmp-tcode = it_functtran-tcode.
*--Add tcode record
      IF NOT it_usertcode-tcode CP '/PSYNG/-*'.
        lt_det_tmp-objct    = 'S_TCODE'.
        lt_det_tmp-field    = 'TCD'.
        lt_det_tmp-von      = it_usertcode-tcode.
        lt_det_tmp-bis      = ''.
        lt_det_tmp-profile  = it_usertcode-profn.
        lt_det_tmp-auth     = it_usertcode-auth.
        lt_det_tmp-simu     = it_usertcode-simu.
        lt_det_tmp-er       = it_usertcode-er.
        INSERT TABLE lt_det_tmp.
      ENDIF.
      CLEAR : l_obj_count_total, l_obj_count_found,
              l_obj_count_and,l_obj_count_found_and,
              l_obj_count_or,l_obj_count_found_or.
      REFRESH : lt_org_obj_cnt.
      CLEAR : l_obj_count_org,l_obj_count_org_optional,lt_org_obj_cnt.
      .
    ENDLOOP.
    CHECK sy-subrc = 0. "user has tcode
    LOOP AT lt_tcode_obj WHERE funid = it_functtran-functionid AND
                               tcode = it_functtran-tcode.
      l_and = lt_tcode_obj-obj_or.
      AT NEW object.
        ADD 1 TO l_obj_count_total.
        IF l_and <> 'OR'.
          ADD 1 TO l_obj_count_and.
        ELSE.
          ADD 1 TO l_obj_count_or.
        ENDIF.
        lt_det_tmp-objct = lt_tcode_obj-object.
*          check if object is org relevant ( in swsodorgm and not OR )
*BOC AKUMAR OPL645
        if i_org_field = 'X'.

          read table it_faobj_org with key
                                     funid = lt_tcode_obj-funid
                                     tcode = lt_tcode_obj-tcode
                                     object = lt_tcode_obj-object
                                   binary search transporting no fields.

          if sy-subrc = 0.

            clear lf_org_relevant.
            read table lt_org_objects with table key
            table_line = lt_tcode_obj-object transporting no fields.

            if sy-subrc = 0 .
              lf_org_relevant = 'X'.
              if l_and <> 'OR'.
                add 1 to l_obj_count_org.
              else.
                add 1 to l_obj_count_org_optional.
              endif.
            endif.

          else.

            clear lf_org_relevant.

          endif.

        else.

          clear lf_org_relevant.
          read table lt_org_objects with table key
          table_line = lt_tcode_obj-object transporting no fields.
          if sy-subrc = 0 .
            lf_org_relevant = 'X'.
            if l_and <> 'OR'.
              add 1 to l_obj_count_org.
            else.
              add 1 to l_obj_count_org_optional.
            endif.
          endif.

        endif.
*EOC AKUMAR OPL645
      ENDAT.

      CLEAR lf_hasobject.
      READ TABLE it_systemauths WITH KEY
          funid = it_functtran-functionid
          tcode = it_functtran-tcode
          objct = lt_tcode_obj-object
          BINARY SEARCH TRANSPORTING NO FIELDS.
      l_systemauth_idx = sy-tabix.

      LOOP AT it_systemauths FROM l_systemauth_idx.
        IF it_systemauths-funid <> it_functtran-functionid OR
           it_systemauths-tcode <> it_functtran-tcode OR
           it_systemauths-objct <> lt_tcode_obj-object.
          EXIT.
        ENDIF.
        lt_det_tmp-field = it_systemauths-field.
        lt_det_tmp-von   = it_systemauths-von.
        lt_det_tmp-bis   = it_systemauths-bis.
        READ TABLE it_userauth WITH KEY
             bname =  i_bname
             objct =  lt_tcode_obj-object
             auth  =  it_systemauths-auth
             BINARY SEARCH TRANSPORTING NO FIELDS.
        l_userauth_idx = sy-tabix.
        LOOP AT  it_userauth FROM l_userauth_idx .
          IF  it_userauth-bname <>  i_bname OR
              it_userauth-objct <>  lt_tcode_obj-object OR
              it_userauth-auth  <>  it_systemauths-auth.
            EXIT.
          ENDIF.
          lt_det_tmp-profile  = it_userauth-profn.
          lt_det_tmp-auth     = it_userauth-auth.
          lt_det_tmp-simu     = it_userauth-simu.
          lt_det_tmp-er       = it_userauth-er.

*Begin of Addition:HBHALLA(PN-15751)(24/12/25)
*Removes Extra blank abb entries coming for org elements
   IF lf_org_relevant = 'X'.
     READ TABLE it_orgauths WITH KEY
      auth   = lt_det_tmp-auth
      object = lt_det_tmp-objct
      varbl  = lt_det_tmp-field
      BINARY SEARCH TRANSPORTING NO FIELDS.
     IF sy-subrc <> 0.
       INSERT TABLE lt_det_tmp.
     ENDIF.
   ELSE.
          INSERT TABLE lt_det_tmp.
   ENDIF.
*End of Addition:HBHALLA(PN-15751)(24/12/25)

          lf_hasobject = 'X'.
*--Get the org abbs for this auth
          IF lf_org_relevant = 'X'.
            READ TABLE it_orgauths WITH KEY
             auth   = it_userauth-auth
             object = lt_tcode_obj-object
             BINARY SEARCH TRANSPORTING NO FIELDS.
            l_orgauth_idx = sy-tabix.
            LOOP AT it_orgauths FROM l_orgauth_idx.
              IF it_orgauths-auth   <> it_userauth-auth OR
                 it_orgauths-object <> lt_tcode_obj-object .
                EXIT.
              ENDIF.
              MOVE-CORRESPONDING it_orgauths TO lt_orgauths.
              lt_orgauths-profn = it_userauth-profn.
              INSERT TABLE lt_orgauths.
              lt_orgauths_idx-object = lt_orgauths-object.
              lt_orgauths_idx-auth   = lt_orgauths-auth.
              insert table lt_orgauths_idx.
              READ TABLE lt_org_obj_cnt
              WITH KEY abb = it_orgauths-abb
              ASSIGNING <org_obj_cnt>.
              IF sy-subrc = 0.
                IF  l_and <> 'OR'.
                  INSERT lt_tcode_obj-object
                  INTO TABLE <org_obj_cnt>-object_and.
                ELSE.
                  INSERT lt_tcode_obj-object
                  INTO TABLE <org_obj_cnt>-object_or.
                ENDIF.
              ELSE.
                lt_org_obj_cnt-abb = it_orgauths-abb.
                REFRESH : lt_org_obj_cnt-object_or,
                          lt_org_obj_cnt-object_and .
                IF  l_and <> 'OR'.
                  INSERT lt_tcode_obj-object
                  INTO TABLE lt_org_obj_cnt-object_and.
                ELSE.
                  INSERT lt_tcode_obj-object
                  INTO TABLE lt_org_obj_cnt-object_or.
                ENDIF.

                INSERT TABLE lt_org_obj_cnt.
              ENDIF.
            ENDLOOP.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
      IF lf_hasobject = 'X'.
        ADD 1 TO l_obj_count_found. "user has the object
        IF l_and <> 'OR'.
          ADD 1 TO l_obj_count_found_and.
        ELSE.
          ADD 1 TO l_obj_count_found_or.
        ENDIF.
      ENDIF.
    ENDLOOP.
*--Check if user has the tcode and it's objects
    IF l_obj_count_found_and = l_obj_count_and AND
       l_obj_count_found > 0.
      IF l_obj_count_or > 0 AND l_obj_count_found_or < 1.
        CLEAR lf_userhas."at least one of the OR objects must be found
      ELSE.
        lf_userhas = 'X'.
      ENDIF.
    ELSEIF l_obj_count_total = 0.
      lf_userhas = 'X'."only tcodes
    ENDIF.
*--Now check if there's an org abb for which
*  the user matches all AND objects
    IF lf_userhas = 'X'.
*--check lt_org_obj_cnt
      IF l_obj_count_org > 0 OR l_obj_count_org_optional > 0.
        IF l_obj_count_org > 0.
*--There is at least one mandatory org object
          CLEAR lf_userhas.
        ENDIF.
        LOOP AT lt_org_obj_cnt.
          DESCRIBE TABLE lt_org_obj_cnt-object_and LINES l_cnt.
          DESCRIBE TABLE lt_org_obj_cnt-object_or LINES l_cnt_o.
*--All org relevant AND objects should have an org match
*  and if there are any OR objects, at least 1 should match
          IF l_cnt >= l_obj_count_org
          AND
             ( l_obj_count_org_optional = 0 OR l_cnt_o > 0 ).
            lf_userhas = 'X'.
*--All org relevant objects match this org
            lt_det_tmp-org_abb = lt_org_obj_cnt-abb.
            read table lt_orgauths with table key abb = lt_org_obj_cnt-abb.
            LOOP AT lt_orgauths from sy-tabix.
              if lt_orgauths-abb <> lt_org_obj_cnt-abb.
                exit.
              endif.
*            LOOP AT lt_orgauths WHERE abb = lt_org_obj_cnt-abb.
              lt_det_tmp-objct = lt_orgauths-object.
              lt_det_tmp-field = lt_orgauths-varbl.
              lt_det_tmp-von   = lt_orgauths-low.
              lt_det_tmp-bis   = lt_orgauths-high.
              lt_det_tmp-auth  = lt_orgauths-auth.
              lt_det_tmp-profile = lt_orgauths-profn.

              lt_det_tmp-tcode = it_functtran-tcode.
*--Get the correct profile for this auth
              INSERT TABLE lt_det_tmp.
            ENDLOOP.
          ENDIF.
        ENDLOOP.
*--DHORIONS 20200504 - TARIS OPL242
*--This was an org relevant conflict, so for any object
* that is org relevant if we have found an auth, but no corresponding
* record in lt_orgauths, the auth should be removed from
* lt_det_tmp
        IF lf_userhas = 'X'.
          LOOP AT lt_org_objects .
*            READ TABLE lt_det_tmp WITH TABLE KEY
*              objct = lt_org_objects.
            READ TABLE lt_det_tmp WITH KEY
              objct = lt_org_objects binary search.
            IF sy-subrc = 0.
              LOOP AT lt_det_tmp FROM sy-tabix.
                IF lt_det_tmp-objct <> lt_org_objects.
                  EXIT.
                ENDIF.
                READ TABLE lt_orgauths_idx WITH TABLE KEY
                     object    = lt_det_tmp-objct
                     auth      = lt_det_tmp-auth
                     TRANSPORTING NO FIELDS.
                IF sy-subrc <> 0.
                  DELETE lt_det_tmp WHERE
                          objct     = lt_det_tmp-objct AND
                          auth      = lt_det_tmp-auth.

                ENDIF.
              ENDLOOP.
            ENDIF.
          ENDLOOP.
        ENDIF.

        FREE : lt_orgauths.
      ENDIF.

      CLEAR lt_det_tmp-org_abb.
    ENDIF.
    FREE :  lt_org_obj_cnt,
            lt_org_obj_cnt-object_and,
            lt_org_obj_cnt-object_or,
            lt_orgauths.
    CLEAR : lt_det_tmp-org_abb,
            lt_org_obj_cnt.
    IF lf_userhas = 'X'.
      APPEND LINES OF lt_det_tmp TO et_outputdet.
    ENDIF.
    FREE : lt_det_tmp.
  ENDLOOP.
*--2020/12/01 - lt_det_tmp table only has unique records, no need to remove dupes
*  SORT et_outputdet.
*  DELETE ADJACENT DUPLICATES FROM et_outputdet.
ENDFORM.                    " analyze_user_functions
