FUNCTION /psyng/sw_026 .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      I_TCODES STRUCTURE  TSTC
*"      O_TCODES STRUCTURE  /PSYNG/SW_PAR_TCODE_OUTPUT
*"      IT_TCODE_FILTERS STRUCTURE  /PSYNG/RANGE_TCODE OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_026'.
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
*Constants
  CONSTANTS:
        hex_tra TYPE x VALUE '00',               " Transaction
        hex_men TYPE x VALUE '01',               " Area Menu
        hex_par TYPE x VALUE '02',               " Parametertransaction
        hex_rep TYPE x VALUE '80',               " Report
        hex_chk TYPE x VALUE '04',               " With auth object
        hex_enq TYPE x VALUE '20'.               " Locked in SM01

* Data declerations
  DATA: BEGIN OF lt_tstcp OCCURS 0.  "to manipulate para tcodes
          INCLUDE STRUCTURE tstcp.
  DATA:   first(60),
          atcode LIKE sy-tcode,
          third(250),
        END OF lt_tstcp.
  DATA : lt_split TYPE TABLE OF string.

  DATA: BEGIN OF lt_progs OCCURS 0,  "to get progs of para tcodes
          tcode LIKE tstc-tcode,
          pgmna LIKE tstc-pgmna,
          dypno LIKE tstc-dypno,
        END OF lt_progs.
  TYPES:BEGIN OF typ_tprog,
          pgmna LIKE tstc-pgmna,
          tcode LIKE tstc-tcode,
          dypno LIKE tstc-dypno,
          cinfo LIKE tstc-cinfo,
        END OF typ_tprog.

  DATA: lt_tprog TYPE SORTED TABLE OF typ_tprog  "to get tcodes of progs
          WITH UNIQUE KEY pgmna tcode dypno           "of para tcodes
          WITH HEADER LINE.
  DATA:    tprog_idx       TYPE             i,
           lt_excl TYPE TABLE OF /psyng/sw_excdtx,
           ls_excl LIKE LINE OF lt_excl,
           ls_config      TYPE /psyng/swconfig,
           l_userexit_fm  LIKE rs38l-name,
           l_tcode        TYPE tcode.
  FIELD-SYMBOLS : <tstcp> LIKE LINE OF lt_tstcp,
                  <tstc>  TYPE tstc,
                  <prog>  TYPE typ_tprog,
                  <string> TYPE string,
                  <progs>  LIKE lt_progs.
  DATA : l_tstcp_idx TYPE i,
         lt_called_tcodes_param_h type hashed table of tstc
         with unique key tcode,
         lt_called_tcodes_param type table of tstc
         with header line.
* Initial preparations
  REFRESH: o_tcodes.
  CLEAR: o_tcodes.
  SORT i_tcodes BY tcode.

  SELECT * FROM tstcp INTO CORRESPONDING FIELDS OF TABLE lt_tstcp.
* Get programs of called tcodes

  IF NOT i_tcodes[] IS INITIAL.
    SELECT tcode pgmna dypno FROM tstc
             INTO CORRESPONDING FIELDS OF TABLE lt_progs
             FOR ALL ENTRIES IN i_tcodes
             WHERE tcode = i_tcodes-tcode AND
                   pgmna GT space
              AND  pgmna <> 'SAPLS_CUS_IMG_ACTIVITY'.
   "(++)HBHALLA(PN-18406)(03/05/26)
  ENDIF.

*----------------------------------------------------------------------
* Load exclusion  table /psyng/sw_excdtx
* for called transactions
*----------------------------------------------------------------------
  SELECT * FROM /psyng/sw_excdtx INTO TABLE lt_excl. "#EC CI_NOWHERE
*----------------------------------------------------------------------
* Execute user exit for exclusion filters
*----------------------------------------------------------------------
  se_config_param 'SW_ENH_CALLED_EXIT' ls_config-value.
  IF not ls_config-value is initial.
    l_userexit_fm = ls_config-value.
    CALL FUNCTION 'FUNCTION_EXISTS'
         EXPORTING
              funcname           = l_userexit_fm
         EXCEPTIONS
              function_not_exist = 1
              OTHERS             = 2.
    IF sy-subrc = 0.
      CALL FUNCTION ls_config-value
           TABLES
                i_exclude_called = lt_excl.
      MESSAGE s144(/psyng/sw) WITH ls_config-value.
    ELSE.
      MESSAGE w143(/psyng/sw) WITH ls_config-value.
    ENDIF.
  ENDIF.

  SORT lt_excl BY called_tcode.
* Manipulation
  LOOP AT lt_tstcp ASSIGNING <tstcp>.
    l_tstcp_idx = sy-tabix. "used for deleting
    CASE <tstcp>-param(2).

      WHEN '/*'.   "PARAMETER transaction with skip first screen
        SPLIT <tstcp>-param AT space INTO <tstcp>-first <tstcp>-third.
        SPLIT <tstcp>-first AT '/*' INTO <tstcp>-first <tstcp>-atcode.
*       special case : transaction = START_REPORT
        IF <tstcp>-atcode = 'START_REPORT'.
          SPLIT <tstcp>-third AT ';' INTO TABLE lt_split.
          DELETE lt_split WHERE NOT table_line
          CP 'D_SREPOVARI-REPORT=*'.
          READ TABLE lt_split INTO <tstcp>-third INDEX 1.
          IF sy-subrc = 0.
            SPLIT <tstcp>-third AT '=' INTO <tstcp>-first <tstcp>-third.
            IF NOT <tstcp>-third IS INITIAL.
              READ TABLE lt_progs WITH KEY pgmna = <tstcp>-third
              ASSIGNING <progs>.
              IF sy-subrc = 0.
                <tstcp>-atcode = <progs>-tcode.
              ELSE.
                CLEAR <tstcp>-atcode.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
        CLEAR: <tstcp>-first, <tstcp>-third, <tstcp>-param.


        READ TABLE i_tcodes WITH KEY tcode = <tstcp>-atcode
             BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc NE 0 .
          DELETE lt_tstcp INDEX l_tstcp_idx.
        ELSE.
*         Delete called transactions based on table /psyng/sw_excdtx
          READ TABLE lt_excl WITH KEY called_tcode = <tstcp>-atcode
             BINARY SEARCH TRANSPORTING NO FIELDS.
          IF sy-subrc = 0 .
            DELETE lt_tstcp INDEX l_tstcp_idx.
          ENDIF.
        ENDIF.

      WHEN '/N'.   "PARAMETER transaction without skip first screen
        SPLIT <tstcp>-param AT space INTO <tstcp>-first <tstcp>-third.
        SPLIT <tstcp>-first AT '/N' INTO <tstcp>-first <tstcp>-atcode.
*       special case : transaction = START_REPORT
        IF <tstcp>-atcode = 'START_REPORT'.
          SPLIT <tstcp>-third AT ';' INTO TABLE lt_split.
          DELETE lt_split WHERE NOT table_line
          CP 'D_SREPOVARI-REPORT=*'.
          READ TABLE lt_split INTO <tstcp>-third INDEX 1.
          IF sy-subrc = 0.
            SPLIT <tstcp>-third AT '=' INTO <tstcp>-first <tstcp>-third.
            IF NOT <tstcp>-third IS INITIAL.
              READ TABLE lt_progs WITH KEY pgmna = <tstcp>-third
              ASSIGNING <progs>.
              IF sy-subrc = 0.
                <tstcp>-atcode = <progs>-tcode.
              ELSE.
                CLEAR <tstcp>-atcode.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.

        CLEAR: <tstcp>-first, <tstcp>-third, <tstcp>-param.
        READ TABLE i_tcodes WITH KEY tcode = <tstcp>-atcode
             BINARY SEARCH TRANSPORTING NO FIELDS.
        CHECK sy-subrc NE 0.
        DELETE lt_tstcp INDEX l_tstcp_idx.
*       If skip first screen is not active, exclusion table is ignored



      WHEN 'SA'.   "REPORT TCODE called with variant
        SPLIT <tstcp>-param AT '&' INTO <tstcp>-first <tstcp>-atcode.
        CLEAR: <tstcp>-first, <tstcp>-third, <tstcp>-param.
        READ TABLE i_tcodes WITH KEY tcode = <tstcp>-atcode
             BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc NE 0 .
          DELETE lt_tstcp INDEX l_tstcp_idx.
        ELSE.
*         Delete called transactions based on table /psyng/sw_excdtx
          READ TABLE lt_excl WITH KEY called_tcode = <tstcp>-atcode
             BINARY SEARCH TRANSPORTING NO FIELDS.
          IF sy-subrc = 0 .
            DELETE lt_tstcp INDEX l_tstcp_idx.
          ENDIF.
        ENDIF.


      WHEN '@@'.   "VARIANT transaction
        SPLIT <tstcp>-param AT space INTO <tstcp>-first <tstcp>-third.
        SPLIT <tstcp>-first AT '@@' INTO <tstcp>-first <tstcp>-atcode.
        CLEAR: <tstcp>-first, <tstcp>-third, <tstcp>-param.
        READ TABLE i_tcodes WITH KEY tcode = <tstcp>-atcode
             BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc NE 0 .
          DELETE lt_tstcp INDEX l_tstcp_idx.
        ELSE.
*         Delete called transactions based on table /psyng/sw_excdtx
          READ TABLE lt_excl WITH KEY called_tcode = <tstcp>-atcode
             BINARY SEARCH TRANSPORTING NO FIELDS.
          IF sy-subrc = 0 .
            DELETE lt_tstcp INDEX l_tstcp_idx.
          ENDIF.
        ENDIF.

      WHEN OTHERS.
        IF <tstcp>-param(1) EQ '@'    "VARIANT transaction
            AND NOT ( <tstcp>-param(2) EQ '@@' ) .
          SPLIT <tstcp>-param AT space INTO <tstcp>-first <tstcp>-third.
          SPLIT <tstcp>-first AT '@' INTO <tstcp>-first <tstcp>-atcode.
          CLEAR: <tstcp>-first, <tstcp>-third, <tstcp>-param.
          READ TABLE i_tcodes WITH KEY tcode = <tstcp>-atcode
               BINARY SEARCH TRANSPORTING NO FIELDS.
          CHECK sy-subrc NE 0.
          IF sy-subrc NE 0 .
            DELETE lt_tstcp INDEX l_tstcp_idx.
          ELSE.
*           Delete called transactions based on table /psyng/sw_excdtx
            READ TABLE lt_excl WITH KEY called_tcode = <tstcp>-atcode
               BINARY SEARCH TRANSPORTING NO FIELDS.
            IF sy-subrc = 0 .
              DELETE lt_tstcp INDEX l_tstcp_idx.
            ENDIF.
          ENDIF.
        ELSE.
          DELETE lt_tstcp INDEX l_tstcp_idx.
        ENDIF.

    ENDCASE.

  ENDLOOP.

* Move simple data to output table
  LOOP AT lt_tstcp ASSIGNING <tstcp>.
    MOVE <tstcp>-tcode TO o_tcodes-calling_tcode .
    MOVE <tstcp>-atcode TO o_tcodes-called_tcode .
    check o_tcodes-calling_tcode in IT_TCODE_FILTERS[].
    APPEND o_tcodes.
  ENDLOOP.

  SORT lt_progs.
  DELETE ADJACENT DUPLICATES FROM lt_progs.

* Get tcodes that are also calling programs of the called tcodes
  SELECT  pgmna tcode dypno cinfo FROM tstc
           INTO CORRESPONDING FIELDS OF TABLE lt_tprog
    WHERE  pgmna <> 'SAPLS_CUS_IMG_ACTIVITY'.
   "(++)HBHALLA(PN-18406)(03/05/26).
*delete parameter transactions from this table
  DELETE lt_tprog WHERE cinfo O hex_par. "#EC CI_SORTSEQ


*--Get info on parameter transactions for called tcodes
if not i_tcodes[] is initial.
  select tcode cinfo from tstc
  into corresponding fields of table lt_called_tcodes_param
  for all entries in i_tcodes where tcode = i_tcodes-tcode
    AND  pgmna <> 'SAPLS_CUS_IMG_ACTIVITY'.
   "(++)HBHALLA(PN-18406)(03/05/26)
  DELETE lt_called_tcodes_param WHERE cinfo O hex_par.
  insert lines of lt_called_tcodes_param
  into table lt_called_tcodes_param_h.
  free : lt_called_tcodes_param.
endif.

  LOOP AT i_tcodes ASSIGNING <tstc>.
    READ TABLE lt_progs WITH KEY tcode = <tstc>-tcode BINARY SEARCH.
    CHECK sy-subrc EQ 0.
    READ TABLE lt_tprog
         WITH KEY pgmna = lt_progs-pgmna BINARY SEARCH
         TRANSPORTING NO FIELDS.
    CHECK sy-subrc EQ 0.
    tprog_idx = sy-tabix.
    LOOP AT lt_tprog FROM tprog_idx
      ASSIGNING <prog>
      WHERE pgmna = lt_progs-pgmna
      AND   dypno = lt_progs-dypno.
      CHECK <prog>-tcode NE <tstc>-tcode.
      MOVE <prog>-tcode TO o_tcodes-calling_tcode .
      MOVE <tstc>-tcode TO o_tcodes-called_tcode .
      check o_tcodes-calling_tcode in IT_TCODE_FILTERS[].
*     Do not include called transactions based on table /psyng/sw_excdtx
      READ TABLE lt_excl WITH KEY called_tcode = o_tcodes-called_tcode
         BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
*is the called transaction a parameter transaction?
*        lt_called_tcodes_param_h only contains tcodes that are
*        NOT parameter transactions
        read table lt_called_tcodes_param_h
        with table key tcode = o_tcodes-called_tcode
        transporting no fields.
        check sy-subrc = 0.
        check o_tcodes-calling_tcode in IT_TCODE_FILTERS[].
        APPEND o_tcodes.
      ENDIF.
    ENDLOOP.
  ENDLOOP.

* Cleaning up
  FREE: lt_tstcp, lt_tprog, lt_progs.
  SORT: o_tcodes.
  DELETE ADJACENT DUPLICATES FROM o_tcodes.

ENDFUNCTION.
