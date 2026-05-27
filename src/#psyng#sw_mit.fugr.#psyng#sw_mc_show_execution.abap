FUNCTION /psyng/sw_mc_show_execution.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_BNAME) TYPE  XUBNAME
*"     REFERENCE(I_START_DATE) TYPE  DATS
*"     REFERENCE(I_END_DATE) TYPE  DATS
*"     REFERENCE(I_VRSIO) TYPE  /PSYNG/SODVRSIO
*"     VALUE(I_CONID) TYPE  /PSYNG/CONFLICT_ID
*"     VALUE(I_SWAUDID) TYPE  /PSYNG/SWAUDID
*"----------------------------------------------------------------------
  DATA: lf_fmname TYPE rs38l_fnam,
       l_1stmon(7) TYPE c,
       l_lastmon(7) TYPE c,
       iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE,
       lt_conid TYPE TABLE OF /psyng/sw_sel_opts_conid WITH HEADER LINE,
       l_idx_f TYPE i,
       l_idx_c TYPE i,
       l_idx_t TYPE i.

* check if TA 2.x is installed
  MOVE '/PSYNG/BC_USRHIS_018' TO lf_fmname.
  CALL FUNCTION 'FUNCTION_EXISTS'
       EXPORTING
            funcname           = lf_fmname
       EXCEPTIONS
            function_not_exist = 1
            OTHERS             = 2.
  IF sy-subrc <> 0.

  if i_conid is initial.
    MESSAGE w002(/psyng/sw) WITH
    'Execution details for Critical Authorizations'
    'Only supported with Transaction Archive'.
    exit.
  endif.

* TA 2.x is not installed
    CONCATENATE i_start_date+4(2) '/' i_start_date(4)
                INTO l_1stmon .
    CONCATENATE i_end_date+4(2) '/' i_end_date(4)
                INTO l_lastmon.

    iseltab-selname = '1STMON'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = l_1stmon.
    APPEND iseltab.
    iseltab-selname = 'LASTMON'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = l_lastmon.
    APPEND iseltab.
    iseltab-selname = 'PBNAME'.    "user ID
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = i_bname.
    APPEND iseltab.

    iseltab-selname = 'S_CONID'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = i_conid.
    APPEND iseltab.

    iseltab-selname = 'SODVRSIO'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = i_vrsio.
    APPEND iseltab.

    iseltab-selname = 'P_LOCAL'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 'X'.
    APPEND iseltab.
    iseltab-selname = 'P_CROSS'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = ''.
    APPEND iseltab.


    iseltab-selname = 'P_REMOTE'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = ''.
    APPEND iseltab.
    iseltab-selname = 'REMOTE'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = ''.
    APPEND iseltab.


    SUBMIT /psyng/sodreport_by_history
    WITH SELECTION-TABLE iseltab AND RETURN.
  ELSE.
*--Load the tcodes in the matrix
    PERFORM load_matrix
                USING
                   i_vrsio
                   ''
                   i_conid
                   i_swaudid.


    iseltab-selname = 'S_DATE'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'BT'.
    iseltab-low     = i_start_date.
    iseltab-high    = i_end_date.
    APPEND iseltab.
    CLEAR iseltab.


    iseltab-selname = 'S_USERS'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = i_bname.
    APPEND iseltab.
    CLEAR iseltab.
    iseltab-selname = 'R_SUME'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 'X'.
    APPEND iseltab.
    CLEAR iseltab.
    iseltab-selname = 'R_DAY'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 'X'.
    APPEND iseltab.
    CLEAR iseltab.

*--Show Changes
    iseltab-selname = 'CHANGES'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 'X'.
    APPEND iseltab.
    CLEAR iseltab.
*--get all transactions from this conflict
    IF i_conid <> ''.
      READ TABLE gt_confdet WITH KEY conid = i_conid
      BINARY SEARCH TRANSPORTING NO FIELDS.
      CHECK sy-subrc = 0.
      l_idx_c = sy-tabix.
      LOOP AT gt_confdet FROM l_idx_c.
        IF gt_confdet-conid <> i_conid.
          EXIT.
        ENDIF.

*  --Tcodes directly in functions
        READ TABLE gt_functtran
        WITH KEY functionid = gt_confdet-functionid
        BINARY SEARCH TRANSPORTING NO FIELDS.
        CHECK sy-subrc = 0.
        l_idx_f = sy-tabix.
        LOOP AT gt_functtran FROM l_idx_f.
          IF gt_functtran-functionid <> gt_confdet-functionid.
            EXIT.
          ENDIF.
          iseltab-selname = 'S_TCODE'.
          iseltab-kind    = 'S'.
          iseltab-sign    = 'I'.
          iseltab-option  = 'EQ'.
          iseltab-low     = gt_functtran-tcode.
          APPEND iseltab.
*  --Tcodes in Objects
          READ TABLE gt_faobj
          WITH KEY funid = gt_confdet-functionid
                   tcode = gt_functtran-tcode
          BINARY SEARCH TRANSPORTING NO FIELDS.
          CHECK sy-subrc = 0.
          l_idx_t = sy-tabix.
          LOOP AT gt_faobj FROM l_idx_t.
            IF gt_faobj-funid <> gt_confdet-functionid OR
               gt_faobj-tcode <> gt_functtran-tcode.
              EXIT.
            ENDIF.
            IF gt_faobj-val_to = ''.
              iseltab-option  = 'CP'.
              iseltab-low     = gt_faobj-val_from.
            ELSE.
              iseltab-option  = 'EQ'.
              iseltab-low     = gt_faobj-val_from.
              iseltab-high    = gt_faobj-val_to.
            ENDIF.
            APPEND iseltab.
          ENDLOOP.
        ENDLOOP.
      ENDLOOP.
      CLEAR iseltab.

    ELSEIF i_swaudid <> ''.
*--Collect the SOD Conflict Info for doing tcode execution check
*--Functions
      READ TABLE gt_ca_confdet WITH KEY conid = i_swaudid
      BINARY SEARCH TRANSPORTING NO FIELDS.
      CHECK sy-subrc = 0.
      l_idx_c = sy-tabix.
      LOOP AT gt_ca_confdet FROM l_idx_c.
        IF gt_ca_confdet-conid <> i_swaudid.
          EXIT.
        ENDIF.
*          APPEND gt_ca_confdet TO lt_confdet.

*--Transactions
        READ TABLE gt_ca_functtran
        WITH KEY functionid = gt_ca_confdet-functionid
        BINARY SEARCH TRANSPORTING NO FIELDS.
        CHECK sy-subrc = 0.
        l_idx_f = sy-tabix.
        LOOP AT gt_ca_functtran FROM l_idx_f.
          IF gt_ca_functtran-functionid <> gt_ca_confdet-functionid.
            EXIT.
          ENDIF.
          iseltab-selname = 'S_TCODE'.
          iseltab-kind    = 'S'.
          iseltab-sign    = 'I'.
          iseltab-option  = 'EQ'.
          iseltab-low     = gt_ca_functtran-tcode.

*--Objects
          READ TABLE gt_ca_faobj
          WITH KEY funid = gt_ca_confdet-functionid
                   tcode = gt_ca_functtran-tcode
          BINARY SEARCH TRANSPORTING NO FIELDS.
          CHECK sy-subrc = 0.
          l_idx_t = sy-tabix.
          LOOP AT gt_ca_faobj FROM l_idx_t.
            IF gt_ca_faobj-funid <> gt_confdet-functionid OR
               gt_ca_faobj-tcode <> gt_functtran-tcode.
              EXIT.
            ENDIF.
            IF gt_ca_faobj-val_to = ''.
              iseltab-option  = 'CP'.
              iseltab-low     = gt_ca_faobj-val_from.
            ELSE.
              iseltab-option  = 'EQ'.
              iseltab-low     = gt_ca_faobj-val_from.
              iseltab-high    = gt_ca_faobj-val_to.
            ENDIF.
          ENDLOOP.
        ENDLOOP.
      ENDLOOP.
    ENDIF.
    CLEAR iseltab.
    SUBMIT /psyng/bc_usrhis_36
    WITH SELECTION-TABLE iseltab AND RETURN.

  ENDIF.





ENDFUNCTION.
