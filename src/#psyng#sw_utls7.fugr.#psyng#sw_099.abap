FUNCTION /psyng/sw_099.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_HIST_START) TYPE  DATS OPTIONAL
*"     VALUE(I_HIST_END) TYPE  DATS OPTIONAL
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_DETAILS) TYPE  FLAG OPTIONAL
*"     VALUE(I_CHANGEDOCS) TYPE  FLAG OPTIONAL
*"     VALUE(I_TABLOG) TYPE  FLAG OPTIONAL
*"     VALUE(I_BY_FUNCTION) TYPE  FLAG OPTIONAL
*"     VALUE(I_BY_CONFLICT) TYPE  FLAG OPTIONAL
*"     VALUE(IF_USE_TA) TYPE  FLAG DEFAULT ' '
*"  TABLES
*"      IT_RESULTS STRUCTURE  /PSYNG/SW_SOD_OUTPUT_ORG OPTIONAL
*"      IT_USERS STRUCTURE  /PSYNG/SW_SEL_OPTS_XUBNAME OPTIONAL
*"      ET_DETAILS STRUCTURE  /PSYNG/SW_LEVEL3_DETAILS OPTIONAL
*"      IT_CONFS STRUCTURE  /PSYNG/SW_SEL_OPTS_CONID OPTIONAL
*"      ET_FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      ET_CONFDET STRUCTURE  /PSYNG/CONFDET OPTIONAL
*"      IT_FUNCRESULTS STRUCTURE  /PSYNG/SW_OUTPUT_ORG OPTIONAL
*"      IT_FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      IT_CONFDET STRUCTURE  /PSYNG/CONFDET OPTIONAL
*"      IT_CONFLICTS STRUCTURE  /PSYNG/CONFLICT OPTIONAL
*"      IT_RFC STRUCTURE  /PSYNG/SW_SEL_OPTS_RFCDEST OPTIONAL
*"      IT_FAOBJ STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"----------------------------------------------------------------------

  DATA :
           lt_confdet   TYPE TABLE OF /psyng/confdet   WITH HEADER LINE,
           lt_functtran TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
           lt_conflict  TYPE TABLE OF /psyng/conflict  WITH HEADER LINE,
           lt_tcodes    TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
           lt_tcodes_a  TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
           lt_tcodes_p  TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
           lt_users   TYPE TABLE OF /PSYNG/SW_SEL_OPTS_XUBNAME
                                                       WITH HEADER LINE,
           lt_users_p   TYPE TABLE OF /PSYNG/SW_SEL_OPTS_XUBNAME
                                                       WITH HEADER LINE,
           lt_cdhdr_sum TYPE TABLE OF cdhdr            WITH HEADER LINE,
           lt_usr       TYPE TABLE OF usr02            WITH HEADER LINE,
           lt_dblog_summary
                        TYPE TABLE OF /psyng/dblog_summary
                                                       WITH HEADER LINE,
           lt_range_tcode
                        TYPE TABLE OF /psyng/range_tcode
                                                       WITH HEADER LINE,
           lf_conflictfound   TYPE flag,
           lf_functionfound   TYPE flag,
           lf_tcodefound      TYPE flag,
           lf_check_conflict  TYPE flag,
           lf_level2_conflict TYPE flag,
           lf_level2_results_included
                              TYPE flag,
           lt_rfcdes          TYPE TABLE OF rfcdes         WITH HEADER LINE,
           lt_funcscan_all    TYPE TABLE OF /psyng/sw_output_org,
           lt_funcscan        TYPE TABLE OF /psyng/sw_output_org,
           l_local_sys        TYPE rfcdes-rfcoptions,
           lf_TA_installed    type flag,
           lf_ta_v21          type flag,
           l_index_mode       type /PSYNG/PARAM_VALUE,
           begin of lt_class_tcode  occurs 0,
             tcode            type tcode,
             objectclas       type CDOBJECTCL,
           end of lt_class_tcode,
           l_ta_vrsio         type /PSYNG/PROG_VRSIO
         .


*--Check if TA is installed
  perform check_ta_installed changing lf_ta_installed lf_ta_v21 l_ta_vrsio.
  if not lf_ta_installed = 'X'.
    clear if_use_ta.
  endif.



*--Check the index mode for reading CDHDR determined
*  by parameter LEVEL3_CHDR_INDEX
CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
 EXPORTING
   I_PARAMETER       = 'LEVEL3_CHDR_INDEX'
 IMPORTING
   E_VALUE           = l_index_mode.




*2019/08/05 - DHORIONS - This FM doesn't look at stats data
* so don't make any changes unless dates are initial.
  if i_hist_start is initial or i_hist_end is initial.
    PERFORM get_default_dates USING    if_use_ta
                              CHANGING i_hist_start
                                       i_hist_end.
  endif.

  IF it_users IS INITIAL.
    it_users-sign = 'I'.
    it_users-option  = 'EQ'.
    LOOP AT et_details.
      it_users-low = et_details-bname.
      COLLECT it_users.
    ENDLOOP.
    LOOP AT it_results.
      it_users-low = it_results-bname.
      COLLECT it_users.
    ENDLOOP.
    LOOP AT it_funcresults.
      it_users-low = it_funcresults-bname.
      COLLECT it_users.
    ENDLOOP.
  ENDIF.


*--Level 2 results were passed to this function module
  IF NOT it_results[] IS INITIAL OR NOT it_funcresults[] IS INITIAL.
    lf_level2_results_included = 'X'.
  ENDIF.

*--Load conflicts, details and tcodes
  IF i_by_conflict = 'X'.
    IF it_conflicts[] IS INITIAL.
      SELECT conid FROM /psyng/conflict    "#EC CI_SEL_NESTED
      INTO CORRESPONDING FIELDS OF TABLE lt_conflict
      WHERE
        vrsio = i_vrsio AND
        conid IN it_confs.
    ELSE.
      lt_conflict[] = it_conflicts[].
    ENDIF.
  ENDIF.
  IF it_confdet[] IS INITIAL.
    SELECT conid functionid  FROM /psyng/confdet   "#EC CI_SEL_NESTED
      INTO CORRESPONDING FIELDS OF  TABLE lt_confdet
      WHERE vrsio = i_vrsio AND
            conid IN it_confs.
  ELSE.
    lt_confdet[] = it_confdet[].
  ENDIF.
  IF it_functtran[] IS INITIAL.
    IF NOT lt_confdet[] IS INITIAL.
      SELECT functionid tcode FROM /psyng/functtran  "#EC CI_SEL_NESTED
        INTO CORRESPONDING FIELDS OF  TABLE lt_functtran
        FOR ALL ENTRIES IN lt_confdet
        WHERE vrsio = i_vrsio AND
              functionid = lt_confdet-functionid.
    ENDIF.
  ELSE.
    lt_functtran[] = it_functtran[].
  ENDIF.


*--Get the tcodes from the object details
  perform get_tcodes_from_objects
    tables
      IT_FAOBJ
      lt_functtran.


*--Collect Tcodes
  lt_range_tcode-sign = 'I'.
  lt_range_tcode-option = 'EQ'.
  LOOP AT lt_functtran.
    lt_tcodes-tcode = lt_functtran-tcode.
    if not lt_tcodes-tcode CP '/PSYNG/-*'. "ignore placeholder tcodes
      COLLECT lt_tcodes.
    endif.
    lt_range_tcode-low = lt_functtran-tcode.
    COLLECT lt_range_tcode.
  ENDLOOP.
*--Load change document summary
*  One record per user tcode combination
  CHECK NOT lt_tcodes IS INITIAL.
  IF i_changedocs = 'X'.
    if l_index_mode = '573864_OBJECTCLAS'.
*--When this parameter is set, there is no index on the CDHDR
*  on the username and we'll try to take advantage of the index on the
*  objectclass
    MESSAGE s002(/psyng/sw) WITH
    'Parameter LEVEL3_CHDR_INDEX set to 573864_OBJECTCLAS'
    'Not using recommended index on CDHDR'.

*--Get Object Class tcode combinations
    MESSAGE s002(/psyng/sw) WITH
    'Reading CDHDR OBJECTCLASS TCODE Relation'.
    commit work.

    SELECT DISTINCT objectclas tcode            "#EC CI_NOFIELD
        FROM cdhdr                              "#EC CI_NOFIRST
        INTO TABLE lt_class_tcode
        for all entries in lt_tcodes
    WHERE
                tcode      =  lt_tcodes-tcode
       and      udate      >= i_hist_start
       AND      udate      <= i_hist_end
       and      tcode      =  lt_class_tcode-tcode
.

*--Get records based on objectclass
    MESSAGE s002(/psyng/sw) WITH
    'Reading CDHDR Changes for users'.
    commit work.
      if not lt_class_tcode[] is initial.
        SELECT DISTINCT username tcode
           FROM cdhdr
           INTO CORRESPONDING FIELDS OF TABLE   lt_cdhdr_sum
           FOR ALL ENTRIES IN lt_class_tcode
           WHERE    objectclas =  lt_class_tcode-objectclas
           and      udate      >= i_hist_start
           AND      udate      <= i_hist_end
           and      tcode      =  lt_class_tcode-tcode
           and      username   in it_users.
      endif.
    else.
*--Read CDHDR table by User and Date assuming the index from
*  Do a select on the CDHDR table per 1000 uses and 1000 tcodes maximum
*  to avoid errors with SQL statements that are too long
      sort : it_users, lt_tcodes.
      lt_users[]    = it_users[].

      while not lt_users[] is initial.
       refresh : lt_users_p.
       append lines of lt_users from 1 to 1000 to lt_users_p .
       delete lt_users from 1 to 1000.
       lt_tcodes_a[] = lt_tcodes[].
       while not lt_tcodes_a[] is initial.
        refresh : lt_tcodes_p.
        append lines of lt_tcodes_a from 1 to 1000 to lt_tcodes_p .
        delete lt_tcodes_a from 1 to 1000.
        SELECT DISTINCT username tcode FROM cdhdr   "#EC CI_SEL_NESTED
                                                    "#EC CI_NOFIELD
        APPENDING CORRESPONDING FIELDS OF TABLE lt_cdhdr_sum
        FOR ALL ENTRIES IN lt_tcodes_p
        WHERE username IN lt_users_p AND
        udate >= i_hist_start AND
        udate <= i_hist_end   AND
        tcode = lt_tcodes_p-tcode.
       endwhile.
      endwhile.
    endif.
*--Mark change type in objectclass field
    lt_cdhdr_sum-objectclas = 'CHANGEDOC'.
    MODIFY lt_cdhdr_sum
    TRANSPORTING objectclas
    WHERE objectclas = ''.
  ENDIF.
*--Load table logging summary
  IF i_tablog = 'X'.
    CALL FUNCTION '/PSYNG/BASIS_GET_DBLOG'
     EXPORTING
       i_begda          = i_hist_start
       i_begtm          = '000000'
       i_endda          = i_hist_end
       i_endtm          = '235959'
       i_limit          = 1
     TABLES
       it_bname         = it_users
       it_tcode         = lt_range_tcode
       et_summary       = lt_dblog_summary.
    LOOP AT lt_dblog_summary.
      MOVE-CORRESPONDING lt_dblog_summary TO lt_cdhdr_sum.
      lt_cdhdr_sum-objectclas = 'TABLOG'.
      APPEND lt_cdhdr_sum.
    ENDLOOP.
  ENDIF.

  SORT lt_cdhdr_sum BY username tcode.
*--Get unique users
  LOOP AT lt_cdhdr_sum.
    lt_usr-bname = lt_cdhdr_sum-username.
    COLLECT lt_usr.
  ENDLOOP.

  LOOP AT lt_usr.
    IF i_by_conflict = 'X'.
      LOOP AT lt_conflict.
        lf_check_conflict = 'X'.
        CLEAR lf_level2_conflict.
        IF lf_level2_results_included = 'X'.
*--level 2 results have been passed, only check for conflicts
*   that existed in level 2
          READ TABLE it_results WITH KEY bname    = lt_usr-bname
                                         conid    = lt_conflict-conid
                                         TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
            CLEAR lf_check_conflict.
          ELSE.
            lf_level2_conflict = 'X'.
          ENDIF.
        ENDIF.
        CHECK lf_check_conflict = 'X'.
        lf_conflictfound = 'X'.
        LOOP AT lt_confdet                         "#EC CI_NOORDER
          WHERE conid = lt_conflict-conid.
          CLEAR lf_tcodefound.
          LOOP AT lt_functtran WHERE               "#EC CI_NOORDER
          functionid = lt_confdet-functionid.
*--look for tcode in execution history
*           search hitlist
            READ TABLE lt_cdhdr_sum WITH KEY username = lt_usr-bname
                                          tcode    = lt_functtran-tcode
            BINARY SEARCH TRANSPORTING NO FIELDS.
            IF sy-subrc = 0.
              lf_tcodefound = 'X'.
              EXIT.                               "#EC CI_NOORDER
            ENDIF.
          ENDLOOP.
          IF lf_tcodefound IS INITIAL.
            CLEAR lf_conflictfound.
            EXIT.                                 "#EC CI_NOORDER
          ENDIF.
        ENDLOOP.
        IF lf_conflictfound = 'X'.
          IF lf_level2_results_included <> 'X'.
*-- Add to results, even if there were no level 2 results
            it_results-bname = lt_usr-bname.
            it_results-conid = lt_conflict-conid.
            APPEND it_results.
          ENDIF.
          IF lf_level2_conflict = 'X'.
*  --Mark conflict as level 3
            it_results-level3 = 'X'.
            it_results-level2 = 'X'.

            MODIFY it_results TRANSPORTING level3
                                           level2
            WHERE
              bname = lt_usr-bname AND
              conid = lt_conflict-conid.
          ENDIF.
        ENDIF.
      ENDLOOP.

    ELSEIF i_by_function = 'X'.

      LOOP AT lt_confdet.
        CLEAR lf_tcodefound.
        lf_check_conflict = 'X'.
        IF lf_level2_results_included = 'X'.
*  --level 2 results have been passed, only check for conflicts
*     that existed in level 2
          READ TABLE it_funcresults
          WITH KEY bname    = lt_usr-bname
                   funid    = lt_confdet-functionid
          TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
            CLEAR lf_check_conflict.
          ELSE.
            lf_level2_conflict = 'X'.
          ENDIF.
        ENDIF.
        CHECK lf_check_conflict = 'X'.
        LOOP AT lt_functtran WHERE
        functionid = lt_confdet-functionid.
*--look for tcode in execution history
*           search hitlist
          READ TABLE lt_cdhdr_sum WITH KEY
            username = lt_usr-bname
            tcode       = lt_functtran-tcode
          BINARY SEARCH TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            lf_tcodefound = 'X'.
            EXIT.
          ENDIF.
        ENDLOOP.
        IF NOT lf_tcodefound IS INITIAL.
          it_funcresults-changed  = 'X'.
          it_funcresults-executed = 'X'.
          MODIFY it_funcresults TRANSPORTING changed
                                             executed
          WHERE
            bname = lt_usr-bname AND
            funid = lt_confdet-functionid.
        ENDIF.
      ENDLOOP.
    ENDIF.
    IF i_details = 'X'.
      LOOP AT lt_confdet ."WHERE conid = lt_conflict-conid.
        lf_check_conflict = 'X'.
        LOOP AT lt_functtran WHERE   functionid = lt_confdet-functionid.
*--Check if user has this function
          IF lf_level2_results_included = 'X'.
            IF i_by_function = 'X'.
              READ TABLE it_funcresults
                WITH KEY bname    = lt_usr-bname
                         funid    = lt_confdet-functionid.
              IF sy-subrc <> 0.
                CLEAR lf_check_conflict.
              ENDIF.
            ELSE.
              READ TABLE it_results WITH KEY bname    = lt_usr-bname
                                            conid    = lt_confdet-conid
                                             TRANSPORTING NO FIELDS.
              IF sy-subrc <> 0.
                CLEAR lf_check_conflict.
              ENDIF.
            ENDIF.
          ENDIF.
          CHECK lf_check_conflict = 'X'.
*--Check if not yet added to details
          READ TABLE et_details WITH KEY bname = lt_usr-bname
                                         tcode = lt_functtran-tcode
                                         funid = lt_confdet-functionid
                                         TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
            LOOP AT lt_cdhdr_sum WHERE username = lt_usr-bname AND
                                       tcode    = lt_functtran-tcode.
              PERFORM get_change_details
                TABLES et_details
                USING
                  lt_usr-bname
                  lt_functtran-tcode
                  lt_cdhdr_sum-objectclas
                  i_hist_start
                  i_hist_end
                  lt_confdet-functionid.
            ENDLOOP.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
  IF i_details = 'X'.
    et_functtran[] = lt_functtran[].
    et_confdet[]   = lt_confdet[].
  ENDIF.
ENDFUNCTION.
