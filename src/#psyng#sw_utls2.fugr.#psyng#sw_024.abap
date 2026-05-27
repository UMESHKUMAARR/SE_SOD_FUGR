FUNCTION /psyng/sw_024.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_FIELDDETAILS) TYPE  FLAG DEFAULT ''
*"  TABLES
*"      SWSODORGM STRUCTURE  /PSYNG/SWSODORGM
*"      UNIQUEAUTHS STRUCTURE  /PSYNG/UNIQUEAUTHS
*"      SYSTEMAUTHS STRUCTURE  /PSYNG/SWSODORGAUTH
*"      IT_SIMU_AUTHS STRUCTURE  AGR_1251 OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_024'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026

  DATA : BEGIN OF lt_auth_range OCCURS 0,
           sign   TYPE tvarv_sign,
           option TYPE tvarv_opti,
           low    TYPE xuauth,
           high   TYPE xuauth,
         END OF lt_auth_range,
         BEGIN OF lt_obj_range OCCURS 0,
           sign   TYPE tvarv_sign,
           option TYPE tvarv_opti,
           low    TYPE xuobject,
           high   TYPE xuobject,
         END OF lt_obj_range,
         BEGIN OF lt_fld_range OCCURS 0,
           sign   TYPE tvarv_sign,
           option TYPE tvarv_opti,
           low    TYPE xufield,
           high   TYPE xufield,
         END OF lt_fld_range,
         ls_obj_range        LIKE LINE OF lt_obj_range,
         ls_fld_range        LIKE LINE OF lt_fld_range,

         lt_auth_range_slice LIKE TABLE OF lt_auth_range,
         ls_auth_range       LIKE LINE OF lt_auth_range,
         lt_ust12            TYPE TABLE OF ust12, " WITH HEADER LINE,
         lt_ust12_sorted     TYPE SORTED TABLE OF ust12 WITH NON-UNIQUE KEY
                         objct field, "auth von bis,
         wa_systemauth       TYPE   /psyng/swsodorgauth,
         nrauths             TYPE i,
         slice_start         TYPE i VALUE 1,
         slice_stop          TYPE i,
         slice_size          TYPE i VALUE 1000,
         l_rfcdest           TYPE rfcdest,
         l_counter           LIKE sy-tabix,
         l_mod               TYPE i,
         l_detindex          type i.
  TYPES :
    BEGIN OF typ_sysauth_sort,
      rfcdest TYPE rfcdest,
      abb     TYPE /psyng/dorg_abb,
      object  TYPE xuobject,
      auth    TYPE xuauth,
      varbl   TYPE tprorgvar,
    END OF typ_sysauth_sort.
*--Dhorions 20110713 : Use sorted table, sorting uses too much memory
  DATA : lt_systemauths     TYPE SORTED TABLE OF typ_sysauth_sort
         WITH NON-UNIQUE KEY
         rfcdest abb object auth varbl WITH HEADER LINE," low high,
*--Sorted table for quick deletion of records
         lt_systemauths_del TYPE SORTED TABLE OF typ_sysauth_sort
         WITH non-UNIQUE KEY
         rfcdest abb object auth
         WITH HEADER LINE,
         lt_systemauths_out TYPE SORTED TABLE OF typ_sysauth_sort
         WITH UNIQUE KEY
         rfcdest abb object auth
         WITH HEADER LINE,
         lt_systemauths_det TYPE SORTED TABLE OF /PSYNG/SWSODORGAUTH
         WITH UNIQUE KEY
         rfcdest varbl abb object auth low
         WITH HEADER LINE
         .

  DATA: lt_ust12_temp  TYPE TABLE OF ust12 WITH HEADER LINE,
        wa_ust12       TYPE ust12,
        lt_auths_scope TYPE HASHED TABLE OF xuauth
        WITH UNIQUE KEY TABLE LINE
        WITH HEADER LINE.

  DATA : BEGIN OF lt_obj_fields OCCURS 0,
           object TYPE xuobject,
           varbl  TYPE xufield,
         END OF lt_obj_fields,
         BEGIN OF lt_obj_fieldcount OCCURS 0,
           object     TYPE xuobject,
           fieldcount TYPE i,
         END OF lt_obj_fieldcount,
         lt_obj_multi_field LIKE TABLE OF lt_obj_fields
         WITH HEADER LINE,
         BEGIN OF lt_obj_multi_match OCCURS 0,
           object TYPE xuobject,
           auth   TYPE xuauth,
           abb    TYPE /psyng/dorg_abb,
         END OF lt_obj_multi_match.
  FIELD-SYMBOLS :
    <sodorgm> TYPE   /psyng/swsodorgm,
    <auth>    LIKE LINE OF uniqueauths,
    <ust12>   TYPE ust12.
  FIELD-SYMBOLS: <pair> TYPE /psyng/auth_compare.
  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest.


*Use ranges for auths.
 IF it_simu_auths[] IS INITIAL. "HBHALLA

  ls_auth_range-sign = 'I'.
  ls_auth_range-option = 'EQ'.
  LOOP AT uniqueauths ASSIGNING <auth> WHERE rfcdest = l_rfcdest.
    ls_auth_range-low = <auth>-auth.
    APPEND ls_auth_range TO lt_auth_range.
    lt_auths_scope = <auth>-auth.
    INSERT TABLE lt_auths_scope.
  ENDLOOP.
  SORT lt_auth_range.
  DELETE ADJACENT DUPLICATES FROM lt_auth_range.
  DESCRIBE TABLE lt_auth_range LINES nrauths.

 ENDIF. "HBHALLA

  ls_obj_range-sign = 'I'.
  ls_obj_range-option = 'EQ'.
  ls_fld_range-sign = 'I'.
  ls_fld_range-option = 'EQ'.
  LOOP AT swsodorgm ASSIGNING <sodorgm>.
    ls_obj_range-low = <sodorgm>-object.
    ls_fld_range-low = <sodorgm>-varbl.
    APPEND ls_fld_range TO lt_fld_range.
    APPEND ls_obj_range TO lt_obj_range.
*--Collect fields per object
    lt_obj_fields-object = <sodorgm>-object.
    lt_obj_fields-varbl  = <sodorgm>-varbl.
    COLLECT lt_obj_fields.
  ENDLOOP.
  SORT lt_obj_range.
  DELETE ADJACENT DUPLICATES FROM lt_obj_range.
  SORT lt_fld_range.
  DELETE ADJACENT DUPLICATES FROM lt_fld_range.

*--identify objects with more than 1 VARBL
  LOOP AT lt_obj_fields.
    lt_obj_fieldcount-object      = lt_obj_fields-object.
    lt_obj_fieldcount-fieldcount  = 1.
    COLLECT lt_obj_fieldcount.
  ENDLOOP.
  DELETE  lt_obj_fieldcount WHERE fieldcount  = 1.
  SORT lt_obj_fieldcount BY object.
  SORT lt_obj_fields BY object.
  LOOP AT lt_obj_fieldcount.
    READ TABLE lt_obj_fields WITH KEY object =  lt_obj_fieldcount-object
     BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      LOOP AT lt_obj_fields FROM sy-tabix.
        IF  lt_obj_fields-object <>  lt_obj_fieldcount-object.
          EXIT.
        ENDIF.
        APPEND lt_obj_fields TO lt_obj_multi_field.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
  FREE lt_obj_fields.
  SORT lt_obj_multi_field BY object varbl.


*--If no objects were defined in the Org Level Maintenance, or no auths are in scope, exit now.
  CHECK NOT lt_obj_range[] IS INITIAL and ( NOT lt_auths_scope[] is initial OR NOT it_simu_auths[] IS INITIAL ). "HBHALLA

IF it_simu_auths[] IS INITIAL. "HBHALLA
 if lines( lt_auth_range ) > 1000.
*-- When a large nr of auths is in scope :
*   Select entries based on object and field range, then ignore auths out of scope
*   To prevent limitations of SQL Statement Length being longer than the database supports
    SELECT * FROM ust12 INTO TABLE lt_ust12_temp       "#EC CI_SEL_NESTED
       WHERE objct IN lt_obj_range
       AND   aktps = 'A'
       AND   field IN lt_fld_range.
    LOOP AT lt_ust12_temp.
      READ TABLE lt_auths_scope
      WITH TABLE KEY table_line = lt_ust12_temp-auth
      TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        MOVE-CORRESPONDING lt_ust12_temp TO wa_ust12.
        APPEND wa_ust12 TO lt_ust12.
      ENDIF.
    ENDLOOP.
    free : lt_ust12_temp.
  else.
*-- When a smaller nr of auths is in scope :
*   Select entries based on object, field and auth range
    SELECT * FROM ust12 INTO TABLE lt_ust12       "#EC CI_SEL_NESTED
       WHERE objct IN lt_obj_range
       AND   auth  IN lt_auth_range
       AND   aktps = 'A'
       AND   field IN lt_fld_range .
  endif.
  FREE : lt_auth_range[].



  SORT lt_ust12.
  DELETE ADJACENT DUPLICATES FROM lt_ust12.
  lt_ust12_sorted[] = lt_ust12[].
  FREE : lt_ust12.

  ENDIF. "HBHALLA

  DATA : lt_compare TYPE TABLE OF /psyng/auth_compare,
         pair       TYPE /psyng/auth_compare.

  DATA: lt_simu_auth  TYPE SORTED TABLE OF agr_1251 WITH NON-UNIQUE KEY object field,  "BOC: HBHALL
        ls_simu_auth  TYPE  agr_1251.

  field-symbols: <simu_auth> TYPE agr_1251.
  SORT it_simu_auths BY agr_name object auth field low high.
  DELETE ADJACENT DUPLICATES FROM it_simu_auths
  COMPARING agr_name object auth field low high.
  SORT it_simu_auths BY object field.                                  "HBHALLA Bug Fix
  INSERT LINES OF it_simu_auths INTO table lt_simu_auth.                     "HBHALLA Bug Prevent

*    END OF CHANGE: HBHALLA


  LOOP AT swsodorgm ASSIGNING <sodorgm>.

  IF it_simu_auths[] IS INITIAL. "HBHALLA

    READ TABLE lt_ust12_sorted WITH TABLE KEY objct = <sodorgm>-object
*                               aktps = 'A'
                               field = <sodorgm>-varbl
*                               BINARY SEARCH
                               TRANSPORTING NO FIELDS.
    if sy-subrc = 0.
      LOOP AT lt_ust12_sorted FROM sy-tabix
              ASSIGNING <ust12>.
        IF NOT <ust12>-objct = <sodorgm>-object OR NOT
               <ust12>-field = <sodorgm>-varbl.
          EXIT.
        ENDIF.
        pair-auth_from  = <ust12>-von.
        pair-auth_to    = <ust12>-bis.
        pair-sod_from   = <sodorgm>-low.
        pair-sod_to     = <sodorgm>-high.
        pair-auth       = <ust12>-auth.
        TRANSLATE pair-auth_from   TO UPPER CASE.
        TRANSLATE pair-auth_to     TO UPPER CASE.
        TRANSLATE pair-sod_from    TO UPPER CASE.
        TRANSLATE pair-sod_to      TO UPPER CASE.

        APPEND pair TO lt_compare.
        ADD 1 TO l_counter.
        l_mod = l_counter MOD 250000.
        IF l_mod = 0 AND l_counter GE 250000.
*    --Prevent Process from timing out.
          CALL FUNCTION '/PSYNG/BASIS_GET_WPINFO'
            EXPORTING
              i_commit_pct = 20.
        ENDIF.
      ENDLOOP.
    endif.

  ELSE.  "BOC: HBHALLA

      READ TABLE lt_simu_auth WITH TABLE KEY object = <sodorgm>-object
*                               aktps = 'A'
                               field = <sodorgm>-varbl
*                               BINARY SEARCH
                               TRANSPORTING NO FIELDS.
    if sy-subrc = 0.

   LOOP AT lt_simu_auth FROM sy-tabix
              ASSIGNING <simu_auth>.
        IF NOT <simu_auth>-object = <sodorgm>-object OR NOT
               <simu_auth>-field = <sodorgm>-varbl.
          EXIT.
        ENDIF.
        pair-auth_from  = <simu_auth>-low.
        pair-auth_to    = <simu_auth>-high.
        pair-sod_from   = <sodorgm>-low.
        pair-sod_to     = <sodorgm>-high.
        pair-auth       = <simu_auth>-auth.
        TRANSLATE pair-auth_from   TO UPPER CASE.
        TRANSLATE pair-auth_to     TO UPPER CASE.
        TRANSLATE pair-sod_from    TO UPPER CASE.
        TRANSLATE pair-sod_to      TO UPPER CASE.

        APPEND pair TO lt_compare.
        ADD 1 TO l_counter.
        l_mod = l_counter MOD 250000.
        IF l_mod = 0 AND l_counter GE 250000.
*    --Prevent Process from timing out.
          CALL FUNCTION '/PSYNG/BASIS_GET_WPINFO'
            EXPORTING
              i_commit_pct = 20.
        ENDIF.
      ENDLOOP.
    ENDIF.

ENDIF.  "END OF CHANGE: HBHALLA

*BOC:HBHALLA PN-11675 Case5 (OPL647)
  DELETE lt_compare[] WHERE auth_from IS INITIAL.
*EOC:HBHALLA PN-11675 Case5 (OPL647)

    IF NOT lt_compare[] IS INITIAL.
       CALL FUNCTION '/PSYNG/SW_COMPARE_RANGES'
*      CALL FUNCTION '/PSYNG/SW_021'
        EXPORTING
          I_BUFFER_SIZE    = 50000
        TABLES
          it_compare = lt_compare.
      LOOP AT lt_compare ASSIGNING <pair>.
        IF <pair>-match = 'X'.
          wa_systemauth-abb     = <sodorgm>-abb.
          wa_systemauth-object  = <sodorgm>-object.
          wa_systemauth-auth    = <pair>-auth.
          wa_systemauth-rfcdest = l_rfcdest.
          IF i_fielddetails = 'X'.
            wa_systemauth-varbl = <sodorgm>-varbl.
            wa_systemauth-low  = <sodorgm>-low.
            wa_systemauth-high = <sodorgm>-high.
            insert wa_systemauth into table lt_systemauths_det.
          ENDIF.
*--If this is an object with multiple VARBLS, keep track of the VARBLS
*  so we can ensure the user has a match for the same org for all VARBLS
          READ TABLE lt_obj_fieldcount WITH KEY
              object = <sodorgm>-object
              BINARY SEARCH TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            wa_systemauth-varbl = <sodorgm>-varbl.
            lt_obj_multi_match-object = <sodorgm>-object.
            lt_obj_multi_match-abb    = <sodorgm>-abb.
            lt_obj_multi_match-auth   = wa_systemauth-auth.
            COLLECT lt_obj_multi_match.
*--           further checks required for multiple fields
            lt_systemauths-varbl   = <sodorgm>-varbl.
            lt_systemauths-rfcdest = wa_systemauth-rfcdest.
            lt_systemauths-abb     = wa_systemauth-abb.
            lt_systemauths-object  = wa_systemauth-object.
            lt_systemauths-auth    = wa_systemauth-auth.
            INSERT TABLE lt_systemauths.
*            INSERT wa_systemauth INTO TABLE lt_systemauths.
          ELSE.
*--           no further checks required for multiple fields
            lt_systemauths_out-varbl   = <sodorgm>-varbl.
            lt_systemauths_out-rfcdest = wa_systemauth-rfcdest.
            lt_systemauths_out-abb     = wa_systemauth-abb.
            lt_systemauths_out-object  = wa_systemauth-object.
            lt_systemauths_out-auth    = wa_systemauth-auth.
            INSERT TABLE  lt_systemauths_out.
          ENDIF.
        ENDIF.
      ENDLOOP.
      FREE : lt_compare[].
    ENDIF.
  ENDLOOP."swsodorgm


  FREE : lt_ust12_sorted.
  IF NOT lt_obj_multi_match[] IS INITIAL.
    LOOP AT lt_systemauths.
      INSERT lt_systemauths INTO TABLE lt_systemauths_del.
    ENDLOOP.
*--for object that have multiple Org fields (VARBLS), make sure all of
*  them match for each VARBL
    LOOP AT lt_obj_multi_match.
      READ TABLE lt_obj_multi_field WITH KEY
        object = lt_obj_multi_match-object
        BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        LOOP AT lt_obj_multi_field FROM sy-tabix.
          IF lt_obj_multi_field-object <> lt_obj_multi_match-object.
            EXIT.
          ENDIF.
          READ TABLE lt_systemauths WITH TABLE KEY
            rfcdest  = l_rfcdest
            abb      = lt_obj_multi_match-abb
            object   = lt_obj_multi_match-object
            auth     = lt_obj_multi_match-auth
*            tcode    = ''
            varbl    = lt_obj_multi_field-varbl
          TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
*  --     At least one VARBL doesn't match, delete all records for
*         ORG, OBJECT and AUTH
            READ TABLE lt_systemauths_del WITH TABLE KEY
              rfcdest  = l_rfcdest
              abb      = lt_obj_multi_match-abb
              object   = lt_obj_multi_match-object
              auth     = lt_obj_multi_match-auth
              TRANSPORTING NO FIELDS.
            DELETE lt_systemauths_del FROM sy-tabix WHERE
              rfcdest  = l_rfcdest AND
              abb      = lt_obj_multi_match-abb AND
              object   = lt_obj_multi_match-object AND
              auth     = lt_obj_multi_match-auth.
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
    FREE lt_systemauths.
  ENDIF.
*--Add the records for objects with 1 org field
  LOOP AT lt_systemauths_out.
    wa_systemauth-varbl   = lt_systemauths_out-varbl.
    wa_systemauth-rfcdest = lt_systemauths_out-rfcdest .
    wa_systemauth-abb     = lt_systemauths_out-abb.
    wa_systemauth-object  = lt_systemauths_out-object.
    wa_systemauth-auth    = lt_systemauths_out-auth .
    IF i_fielddetails = 'X'.
      read table lt_systemauths_det with key
        rfcdest = lt_systemauths_out-rfcdest
        varbl   = lt_systemauths_out-varbl
        abb     = lt_systemauths_out-abb
        object  = lt_systemauths_out-object
        auth    = lt_systemauths_out-auth
        binary search.
     if sy-subrc = 0.
       clear l_detindex.
       loop at lt_systemauths_det from sy-tabix.
         if lt_systemauths_det-rfcdest <> lt_systemauths_out-rfcdest or
            lt_systemauths_det-varbl   <> lt_systemauths_out-varbl   or
            lt_systemauths_det-abb     <> lt_systemauths_out-abb     or
            lt_systemauths_det-object  <> lt_systemauths_out-object  or
            lt_systemauths_det-auth    <> lt_systemauths_out-auth    or
            l_detindex > 10.
           exit.
         endif.
         add 1 to l_detindex.
         append lt_systemauths_det to systemauths.
       endloop.
     endif.
    else.
      APPEND wa_systemauth TO systemauths.
    endif.
  ENDLOOP.
  FREE : lt_systemauths_out.
*--Add the records for objects with multiple org fields
  delete adjacent duplicates from lt_systemauths_del
  comparing all fields.
  LOOP AT lt_systemauths_del.
    wa_systemauth-varbl   = lt_systemauths_del-varbl.
    wa_systemauth-rfcdest = lt_systemauths_del-rfcdest .
    wa_systemauth-abb     = lt_systemauths_del-abb.
    wa_systemauth-object  = lt_systemauths_del-object.
    wa_systemauth-auth    = lt_systemauths_del-auth .
    IF i_fielddetails = 'X'.
      read table lt_systemauths_det with key
        rfcdest = lt_systemauths_del-rfcdest
        varbl   = lt_systemauths_del-varbl
        abb     = lt_systemauths_del-abb
        object  = lt_systemauths_del-object
        auth    = lt_systemauths_del-auth
        binary search.
     if sy-subrc = 0.
       clear l_detindex.
       loop at lt_systemauths_det from sy-tabix.
         if lt_systemauths_det-rfcdest <> lt_systemauths_del-rfcdest or
            lt_systemauths_det-varbl   <> lt_systemauths_del-varbl   or
            lt_systemauths_det-abb     <> lt_systemauths_del-abb     or
            lt_systemauths_det-object  <> lt_systemauths_del-object  or
            lt_systemauths_det-auth    <> lt_systemauths_del-auth    or
            l_detindex > 5.
           exit.
         endif.
         add 1 to l_detindex.
         append lt_systemauths_det to systemauths.
       endloop.
     endif.
    else.
      APPEND wa_systemauth TO systemauths.
    endif.
  ENDLOOP.
  FREE : lt_systemauths_del, lt_systemauths_det,lt_systemauths_out.

ENDFUNCTION.
