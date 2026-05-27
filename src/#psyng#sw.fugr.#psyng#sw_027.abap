FUNCTION /psyng/sw_027.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      I_TCODES STRUCTURE  TSTC
*"      O_TCODES STRUCTURE  /PSYNG/SW_PAR_TCODE_OUTPUT
*"      IT_TCODE_FILTERS STRUCTURE  /PSYNG/RANGE_TCODE OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_027'.
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

*Constants
  CONSTANTS:
        hex_tra TYPE x VALUE '00',               " Transaction
        hex_men TYPE x VALUE '01',               " Area Menu
        hex_par TYPE x VALUE '02',               " Parametertransaction
        hex_rep TYPE x VALUE '80',               " Report
        hex_chk TYPE x VALUE '04',               " With auth object
        hex_enq TYPE x VALUE '20'.               " Locked in SM01

  DATA : lt_tstc           TYPE   SORTED TABLE OF tstc
                           WITH   NON-UNIQUE KEY pgmna,
         lt_tstc_fm        TYPE   SORTED TABLE OF tstc
                           WITH   NON-UNIQUE KEY pgmna
                           WITH HEADER LINE,

         ls_tcode          TYPE                   tstc,
         BEGIN OF lt_tcode_incl    OCCURS 0,
           tcode     TYPE tcode,
           pgmna     TYPE seu_name,
         END OF lt_tcode_incl,
         lt_tcode_incl_tmp     TYPE   TABLE OF        tstc,
         BEGIN OF lt_includes OCCURS 0,
          repname          LIKE                   sy-repid,
         END OF lt_includes,
         ls_progname       LIKE                   tstc-pgmna,
         ls_output         TYPE              /psyng/sw_par_tcode_output
,
         BEGIN OF lt_cross OCCURS 0,
          name             TYPE                   seu_name,
          include          LIKE                   ls_progname,
          type(1)          TYPE                   c,
         END OF lt_cross,
         BEGIN OF lt_cross_fm OCCURS 0,
          name             TYPE                   seu_name,
          include          LIKE                   ls_progname,
          type(1)          TYPE                   c,
         END OF lt_cross_fm,

         ls_cross          LIKE LINE OF           lt_cross,
         lt_excl           TYPE TABLE OF          /psyng/sw_excdtx,
         l_tstc_idx        TYPE                   i,
         l_cross_idx       TYPE                   i,
         ls_config      TYPE /psyng/swconfig,
         l_userexit_fm  LIKE rs38l-name.
  .
  FIELD-SYMBOLS : <tstc>   TYPE                   tstc,
                  <incl>   LIKE LINE OF           lt_includes,
                  <excl>   LIKE LINE OF           lt_excl,
                  <otcode> TYPE              /psyng/sw_par_tcode_output.

  DATA : lt_d010inc TYPE sorted TABLE OF d010inc WITH HEADER LINE
        with unique key master include.
  DATA : lt_cross_tcodes LIKE lt_cross OCCURS 0 WITH HEADER LINE,
         l_pp_auth_calltransaction(1) TYPE c,
         l_funcname TYPE rs38l-name,
         l_includename TYPE rs38l-include,
         lf_fm_ignore_sap TYPE flag,
         lt_sapnamespaces TYPE TABLE OF  trnspacet WITH HEADER LINE,
         l_comp TYPE string,
         lf_ignore_fm TYPE flag,
         lf_auth_check type flag.
  FREE : lt_cross_tcodes[].
*--SE3.1PS3T - If   SW_ENH_IGNORE_SAP_FM = Y,
*  Function modules in the SAP namespace
*  will not be considered during Ruleset Enhancement
  se_config_param 'SW_ENH_IGNORE_SAP_FM' ls_config-value.
   if
    ( ls_config-value = 'Y' OR   ls_config-value = 'X').
    lf_fm_ignore_sap = 'X'.
  ENDIF.
  DEFINE check_sap_namespace.
    if lt_sapnamespaces[] is initial.
      select * from trnspacet into table lt_sapnamespaces
      where sapflag = 'X'.
    endif.
*    concatenate &1 '*' into l_comp.
    &2 = 'X'.
    if &1 cp 'Y*' or &1 cp 'Z*'.
      clear &2.
    elseif &1 cp '/*/*'.
      clear &2.
      loop at lt_sapnamespaces.
        concatenate  lt_sapnamespaces-namespace '*' into l_comp.
        if &1 cs l_comp.
*--FM is in SAP namespace.
          &2 = 'X'.
          exit.
        endif.
      endloop.
    endif.
  END-OF-DEFINITION.


  .
  FREE : lt_cross_tcodes[].

*Get system profile parameter auth/check/calltransaction
* See OSS notes 515130 and 410622.
  PERFORM get_spp_value CHANGING l_pp_auth_calltransaction.

* Delete called transactions based on table /psyng/sw_excdtx
  SELECT * FROM /psyng/sw_excdtx INTO TABLE lt_excl. "#EC CI_NOWHERE
*----------------------------------------------------------------------
* Execute user exit for exclusion filters
*----------------------------------------------------------------------
  se_config_param 'SW_ENH_CALLED_EXIT' l_userexit_fm.
  if not l_userexit_fm is initial.
*    l_userexit_fm = ls_config-value.
    CALL FUNCTION 'FUNCTION_EXISTS'
         EXPORTING
              funcname           = l_userexit_fm
         EXCEPTIONS
              function_not_exist = 1
              OTHERS             = 2.
    IF sy-subrc = 0.
      CALL FUNCTION l_userexit_fm
           TABLES
                i_exclude_called = lt_excl.
      MESSAGE s144(/psyng/sw) WITH l_userexit_fm.
    ELSE.
      MESSAGE s143(/psyng/sw) WITH l_userexit_fm.
    ENDIF.
  ENDIF.


  LOOP AT lt_excl ASSIGNING <excl>.
    DELETE i_tcodes WHERE  tcode = <excl>-called_tcode.
  ENDLOOP.

  LOOP AT i_tcodes ASSIGNING <tstc> WHERE pgmna = ''.
    lt_cross_tcodes-name = <tstc>-tcode.
    APPEND lt_cross_tcodes.
  ENDLOOP.


*Buffer table TSTC
  SELECT * FROM tstc INTO TABLE lt_tstc ORDER BY pgmna.
*Customizing Transaction codes are not taken into account
*exclude report SAPLS_CUS_IMG_ACTIVITY
  DELETE lt_tstc WHERE pgmna = 'SAPLS_CUS_IMG_ACTIVITY'.

*1. Get programs calling the transactions
  IF NOT lt_cross_tcodes[] IS INITIAL.
    SELECT name include type FROM cross INTO TABLE lt_cross
    FOR ALL ENTRIES IN lt_cross_tcodes
    WHERE  name = lt_cross_tcodes-name
    AND ( type = 'T' OR type = 'Y' OR type = 'X' ).
  ENDIF.
  SORT lt_cross BY name.
*Get include info for the calling programs
  LOOP AT i_tcodes ASSIGNING <tstc>.
*check if program corresponds with a transaction
    READ TABLE lt_cross WITH KEY name = <tstc>-tcode
    INTO ls_cross BINARY SEARCH.
    IF sy-subrc = 0.
      l_cross_idx = sy-tabix.
      LOOP AT lt_cross INTO ls_cross
           FROM l_cross_idx WHERE name = <tstc>-tcode.
        SELECT distinct * FROM d010inc INTO TABLE lt_d010inc  "#EC CI_SEL_NESTED
        WHERE include = ls_cross-include.
        clear lt_d010inc.
        lt_d010inc-master = ls_cross-include.
*        APPEND lt_d010inc.
*        SORT lt_d010inc.
*        DELETE ADJACENT DUPLICATES FROM lt_d010inc.
        read table lt_d010inc with table key  master  = lt_d010inc-master
                                              include = lt_d010inc-include.
        if sy-subrc <> 0.
          insert table lt_d010inc.
        endif.
        LOOP AT lt_d010inc.
          READ TABLE lt_tstc WITH KEY pgmna = lt_d010inc-master
          TRANSPORTING NO FIELDS BINARY SEARCH.
          IF sy-subrc = 0.
            l_tstc_idx = sy-tabix.
            LOOP AT lt_tstc INTO ls_tcode FROM l_tstc_idx WHERE
              pgmna = lt_d010inc-master.
*--2017/06/28
           check ls_tcode-tcode in IT_TCODE_FILTERS[].
*          Check if TCODE is called with auth check, if so, ignore it
            PERFORM tcode_has_auth_check
            USING
               lt_d010inc-master
               <tstc>-tcode
            CHANGING
               lf_auth_check.
            check lf_auth_check is initial.

              ls_output-calling_tcode = ls_tcode-tcode.
              ls_output-called_tcode = <tstc>-tcode.
              APPEND ls_output TO o_tcodes.
            ENDLOOP.
          ELSE.
            CLEAR : l_funcname,l_includename.
*-- Check if the include  Program Found has FM associated with it or
            if not lt_d010inc-include is initial.
            l_includename = lt_d010inc-include.
            CALL FUNCTION 'FUNCTION_INCLUDE_INFO'
                 CHANGING
                      funcname            = l_funcname
                      include             = l_includename
                 EXCEPTIONS
                      function_not_exists = 1
                      include_not_exists  = 2
                      group_not_exists    = 3
                      no_selections       = 4
                      no_function_include = 5
                      OTHERS              = 6.
            IF sy-subrc = 0 AND NOT l_funcname IS INITIAL.

*--SE3.1PS3T - If   SW_ENH_IGNORE_SAP_FM = Y,
*  Function modules in the SAP namespace
*  will not be considered during Ruleset Enhancement

              IF lf_fm_ignore_sap = 'X'.
                check_sap_namespace l_funcname lf_ignore_fm.
              ELSE.
                CLEAR lf_ignore_fm.
              ENDIF.
              IF NOT lf_ignore_fm = 'X'.

*--check Program in which FM called (CALL_FUNCTION)
             SELECT name include type FROM cross INTO TABLE lt_cross_fm
                     WHERE  name = l_funcname
                     AND ( type = 'F' ).

*-- Check tcode Which is assocauted with Program
                CHECK NOT lt_cross_fm[] IS INITIAL.
                SELECT * FROM tstc INTO TABLE lt_tstc_fm
                FOR ALL ENTRIES IN lt_cross_fm WHERE
                pgmna = lt_cross_fm-include.

                CHECK sy-subrc = 0.

                LOOP AT lt_tstc_fm.
                  check lt_tstc_fm-tcode in IT_TCODE_FILTERS[].
*        Check if TCODE is called with auth check, if so, ignore it
                  PERFORM tcode_has_auth_check
                  USING
                     l_includename
                     <tstc>-tcode
                  CHANGING
                     lf_auth_check.
                  check lf_auth_check is initial.

                  ls_output-calling_tcode = lt_tstc_fm-tcode.
                  ls_output-called_tcode = <tstc>-tcode.
                  APPEND ls_output TO o_tcodes.
                ENDLOOP.
              ENDIF.
            ENDIF.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
*----------------------------------------------------------------------
*Remove called-calling pairs for which authorizations are defined
*in transaction SE97
*----------------------------------------------------------------------
  SORT o_tcodes.
  DELETE ADJACENT DUPLICATES FROM o_tcodes.
  IF NOT o_tcodes[] IS INITIAL.
    DATA : lt_couples TYPE TABLE OF tcdcouples.
    FIELD-SYMBOLS : <couple>  TYPE tcdcouples.
    SELECT * FROM tcdcouples INTO TABLE lt_couples
      FOR ALL ENTRIES IN o_tcodes
      WHERE
            tcode  = o_tcodes-calling_tcode
      AND   called = o_tcodes-called_tcode.
*      AND   okflag = 'X'.
    LOOP AT lt_couples ASSIGNING <couple>.

* Check system profile parameter auth/check/calltransaction
* See OSS notes 515130 and 410622.
      CASE l_pp_auth_calltransaction.
        WHEN 0 OR 2 OR 3.
          CHECK <couple>-okflag = 'X'.
          DELETE TABLE  o_tcodes WITH TABLE KEY
            calling_tcode = <couple>-tcode
            called_tcode = <couple>-called.
        WHEN 1.
          DELETE TABLE  o_tcodes WITH TABLE KEY
            calling_tcode = <couple>-tcode
            called_tcode = <couple>-called.
      ENDCASE.
    ENDLOOP.
* when  auth/check/calltransaction = 1 or 3, the auth check is always
* executed, even if these is no record in tcdcouples
    IF l_pp_auth_calltransaction = 1 OR
       l_pp_auth_calltransaction = 3.
      LOOP AT o_tcodes ASSIGNING <otcode>.
        READ TABLE lt_couples WITH KEY tcode  = <otcode>-calling_tcode
                                       called = <otcode>-called_tcode
                   TRANSPORTING NO FIELDS.
        IF sy-subrc = 4.
          DELETE TABLE  o_tcodes WITH TABLE KEY
            calling_tcode = <otcode>-calling_tcode
            called_tcode  = <otcode>-called_tcode.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
  REFRESH :  lt_cross.
*2.  Get programs calling the programs assigned to the transactions
* Get all included programs
  LOOP AT i_tcodes ASSIGNING <tstc> WHERE pgmna = ''.
    READ TABLE lt_tstc WITH KEY tcode = <tstc>-tcode "#EC CI_SORTSEQ
      INTO ls_tcode.
    MODIFY i_tcodes FROM ls_tcode.
    CALL FUNCTION 'GET_INCLUDES'
         EXPORTING
              progname = ls_tcode-pgmna
         TABLES
              incltab  = lt_includes.
    APPEND ls_tcode TO lt_tcode_incl.
    LOOP AT lt_includes ASSIGNING <incl>.
      ls_tcode-tcode = ls_tcode-tcode.
      ls_tcode-pgmna = <incl>-repname.
      APPEND ls_tcode TO lt_tcode_incl.
    ENDLOOP.
    REFRESH : lt_includes[].
  ENDLOOP.
*SF Case 2151 : Improve performance by sorting table
  SORT lt_tcode_incl BY pgmna.
  DATA : l_tabix LIKE sy-tabix.

*get programs calling these programs
  IF NOT lt_tcode_incl[] IS INITIAL.
    SELECT name include type FROM cross INTO TABLE lt_cross
      FOR ALL ENTRIES IN lt_tcode_incl
      WHERE  name = lt_tcode_incl-pgmna
      AND    type = 'R'.
  ENDIF.
  LOOP AT lt_cross INTO ls_cross.
    FREE : lt_d010inc.
*check if program corresponds with a transaction
*this transaction can not be a parameter transaction
    DELETE lt_tstc WHERE cinfo O hex_par. "#EC CI_SORTSEQ

    SELECT distinct * FROM d010inc INTO TABLE lt_d010inc      "#EC CI_SEL_NESTED
    WHERE include = ls_cross-include.
    lt_d010inc-master = ls_cross-include.
    read table lt_d010inc with table key  master  = lt_d010inc-master
                                          include = lt_d010inc-include.
    if sy-subrc <> 0.
      insert table lt_d010inc.
    endif.
    LOOP AT lt_d010inc.
      READ TABLE lt_tstc WITH KEY pgmna = lt_d010inc-master
      TRANSPORTING NO FIELDS BINARY SEARCH.
      l_tstc_idx = sy-tabix.
      LOOP AT lt_tstc INTO ls_tcode FROM l_tstc_idx WHERE
        pgmna = lt_d010inc-master.
        ls_output-calling_tcode = ls_tcode-tcode.
           check ls_output-calling_tcode in IT_TCODE_FILTERS[].

*SF Case 2151 : Improve performance by using binary search
        READ TABLE lt_tcode_incl WITH KEY pgmna = ls_cross-name
        TRANSPORTING NO FIELDS BINARY SEARCH.
        CHECK sy-subrc = 0.
        l_tabix = sy-tabix.
        LOOP AT lt_tcode_incl
        FROM l_tabix
        INTO ls_tcode
         WHERE pgmna = ls_cross-name.
*          Check if TCODE is called with auth check, if so, ignore it
            PERFORM tcode_has_auth_check
            USING
               lt_d010inc-master
               ls_tcode-tcode
            CHANGING
               lf_auth_check.
            check lf_auth_check is initial.

          ls_output-called_tcode = ls_tcode-tcode.
          APPEND ls_output TO o_tcodes.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
  ENDLOOP.
**Remove the duplicate entries
  SORT o_tcodes.
  DELETE ADJACENT DUPLICATES FROM o_tcodes.
ENDFUNCTION.
