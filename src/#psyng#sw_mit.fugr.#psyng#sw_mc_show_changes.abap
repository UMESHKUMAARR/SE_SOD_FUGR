FUNCTION /psyng/sw_mc_show_changes.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_BNAME) TYPE  XUBNAME
*"     REFERENCE(I_START_DATE) TYPE  DATS
*"     REFERENCE(I_END_DATE) TYPE  DATS
*"     REFERENCE(I_VRSIO) TYPE  /PSYNG/SODVRSIO
*"     VALUE(I_CONID) TYPE  /PSYNG/CONFLICT_ID
*"     VALUE(I_SWAUDID) TYPE  /PSYNG/SWAUDID
*"     VALUE(IF_ALV) TYPE  FLAG DEFAULT 'X'
*"  TABLES
*"      ET_DETAILS STRUCTURE  /PSYNG/SW_LEVEL3_DISPLAY OPTIONAL
*"----------------------------------------------------------------------
  DATA : lt_functtran TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
         lt_faobj     TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
         lt_conflicts TYPE TABLE OF /psyng/conflict
                      WITH HEADER LINE,
         lt_confdet   TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
         lt_details   TYPE TABLE OF /psyng/sw_level3_details
                      WITH HEADER LINE,
         lt_details_display
                      TYPE TABLE OF /psyng/sw_level3_display
                      WITH HEADER LINE,
         lt_users     TYPE TABLE OF /psyng/sw_sel_opts_xubname
                      WITH HEADER LINE,
         l_idx_f      TYPE i,
         l_idx_c      TYPE i,
         l_idx_t      TYPE i,
         ls_signoff   TYPE /psyng/mcrvwsgn,
         l_str        TYPE string,
         l_str2       TYPE string.
  FIELD-SYMBOLS : <det_disp> TYPE /psyng/sw_level3_display.
*--Load the tcodes in the matrix
  ls_signoff-vrsio = i_vrsio.
  PERFORM load_matrix
              USING
                 i_vrsio
                 ''
                 i_conid
                 i_swaudid.
  lt_users-sign   = 'I'.
  lt_users-option = 'EQ'.
  lt_users-low    = i_bname.
  APPEND lt_users.
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
      lt_conflicts-conid    = i_conid.
      APPEND lt_conflicts.
      lt_confdet-conid      = i_conid.
      lt_confdet-functionid = gt_confdet-functionid.
      APPEND lt_confdet.

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
        lt_functtran-tcode = gt_functtran-tcode.
        lt_functtran-functionid = gt_confdet-functionid.
        APPEND lt_functtran.
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
          lt_faobj = gt_faobj.
          lt_faobj-tcode = lt_functtran-tcode.
          lt_faobj-funid = gt_confdet-functionid.
          APPEND lt_faobj.

        ENDLOOP.
      ENDLOOP.
    ENDLOOP.

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
      lt_conflicts-conid    = i_swaudid.
      APPEND lt_conflicts.
      lt_confdet-conid      = i_swaudid.
      lt_confdet-functionid = i_swaudid.
      APPEND lt_confdet.


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
*--We don't handle ranges here
        lt_functtran-tcode = gt_ca_functtran-tcode.
        lt_functtran-functionid = gt_ca_confdet-functionid.
        APPEND lt_functtran.
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
          lt_faobj = gt_ca_faobj.
          lt_faobj-tcode = lt_functtran-tcode.
          lt_faobj-funid = gt_ca_confdet-functionid.
          APPEND lt_faobj.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
  ENDIF.



  CALL FUNCTION '/PSYNG/SW_099'
       EXPORTING
            i_hist_start  = i_start_date
            i_hist_end    = i_end_date
            i_vrsio       = i_vrsio
            i_changedocs  = 'X'
            i_tablog      = 'X'
            i_details     = 'X'
            if_use_ta     = 'X'
            i_by_conflict = 'X'
       TABLES
            it_users      = lt_users
            it_functtran  = lt_functtran
            it_faobj      = lt_faobj
            it_conflicts  = lt_conflicts
            it_confdet    = lt_confdet
            et_details    = lt_details.

  CALL FUNCTION '/PSYNG/SW_104'
       TABLES
            et_details = lt_details_display
            it_details = lt_details.
  FREE lt_details.

*--Add the function texts to the display table
  LOOP AT lt_details_display ASSIGNING <det_disp>.
    IF i_conid <> ''.
*--Get the function text
      PERFORM get_funhdr_text
                    USING
                       <det_disp>-funid
                       i_vrsio
                    CHANGING
                       <det_disp>-funtext.
    ELSE.
*--Get the CA text
      ls_signoff-type    =  '3'.
      ls_signoff-swaudid =  <det_disp>-funid.
      PERFORM get_text
                  USING
                     ls_signoff
                  CHANGING
                     l_str
                     l_str2.

      <det_disp>-funtext = l_str.
    ENDIF.
  ENDLOOP.
  IF if_alv = 'X'.
*--Show the ALV grid
    PERFORM display_changes_made_alv
        TABLES
        lt_details_display
      USING
        i_bname
        i_conid
        i_swaudid.
  ENDIF.
  IF et_details IS REQUESTED.
    et_details[] = lt_details_display[].
  ENDIF.

ENDFUNCTION.
