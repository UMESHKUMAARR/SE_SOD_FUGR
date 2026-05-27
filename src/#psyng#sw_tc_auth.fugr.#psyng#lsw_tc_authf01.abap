*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_TC_AUTHF01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  get_in_scope_tcd_obj_auth
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_FUNCTTRAN  text
*      -->P_TCD  text
*----------------------------------------------------------------------*
FORM get_in_scope_tcd_obj_auth
TABLES   it_functtran STRUCTURE /psyng/functtran
USING    i_dest       TYPE rfcdest.

  DATA : l_faobj_idx TYPE sy-tabix,
         l_ust_idx   TYPE sy-tabix,
         BEGIN OF lt_objectfields OCCURS 0,
           object TYPE xuobject,
           field TYPE xufield,
         END OF lt_objectfields,
         lt_ust12 TYPE SORTED TABLE OF typ_xust12 WITH HEADER LINE
         WITH UNIQUE KEY objct field auth von bis,
         ls_faobj type /psyng/faobj2.

  LOOP AT it_functtran.
    READ TABLE gt_tcd WITH TABLE KEY tcode   = it_functtran-tcode
                                     rfcdest = i_dest
                                     TRANSPORTING NO FIELDS.
    CHECK sy-subrc = 0.
    READ TABLE gt_faobj WITH KEY funid = it_functtran-functionid
                                 tcode = it_functtran-tcode
                                 BINARY SEARCH
                                 TRANSPORTING NO FIELDS.
    CHECK sy-subrc = 0.
    l_faobj_idx = sy-tabix.
    LOOP AT gt_faobj FROM l_faobj_idx.
      IF gt_faobj-funid <> it_functtran-functionid OR
         gt_faobj-tcode <> it_functtran-tcode.
        EXIT.
      ENDIF.
      lt_objectfields-object = gt_faobj-object.
      lt_objectfields-field  = gt_faobj-field.
      COLLECT lt_objectfields.
*--the actual analysis of matching objects will only be on
*  elements of the sod matrix for which we can expect a result

*--SE4.3 - We allow adding org values ($WERKS, $BUKRS) to the sod matrix
*          but we don't want to consider these as real values
      if gt_faobj-val_from cp '$*'.
        ls_faobj = gt_faobj.
        clear ls_faobj-val_from. "blank looks for any value
        insert ls_faobj into table gt_faobj_match.
      else.
        insert gt_faobj into table gt_faobj_match.
      endif.
    ENDLOOP.
  ENDLOOP.

  LOOP AT lt_objectfields.
    READ TABLE gt_ust12 WITH KEY objct  = lt_objectfields-object
                                 field  = lt_objectfields-field
         BINARY SEARCH TRANSPORTING NO FIELDS.
    if sy-subrc = 0.
      l_ust_idx = sy-tabix.
      LOOP AT gt_ust12 FROM l_ust_idx.
        IF NOT gt_ust12-objct  = lt_objectfields-object OR
           NOT gt_ust12-field  = lt_objectfields-field.
          EXIT.
        ENDIF.
        INSERT gt_ust12 INTO TABLE lt_ust12.
      ENDLOOP.
    endif.
  ENDLOOP.
  gt_ust12[] = lt_ust12[].
  FREE : lt_ust12.

ENDFORM.                    " get_in_scope_tcd_obj_auth
*&---------------------------------------------------------------------*
*&      Form  get_auths_for_in_scope_tcodes
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_auths_for_in_scope_tcodes.
  DATA : lf_field_with_and TYPE flag.
  REFRESH : gt_matching_auths,gt_no_field_match.
  LOOP AT gt_faobj_match.
    IF gt_faobj_match-fld_and =  'X'.
*--This valueset has the AND relationship between fields
      lf_field_with_and = 'X'.
    ENDIF.
    PERFORM get_auth_that_match_sod_valsfm.
    AT END OF valueset.
*--If there's a field for which there was a record for an auth that
*  didn't match, check if there is one that did match, and if not,
*  delete everything for this object for this auth
      PERFORM delete_non_existing_fields.
      IF lf_field_with_and = 'X'.
        PERFORM field_level_and_relation.
      ENDIF.
      APPEND LINES OF gt_matching_auths TO gt_matches.
*      REFRESH : gt_matching_auths,gt_no_field_match.
      FREE : gt_matching_auths[] ,gt_no_field_match[],
             gt_matching_auths,gt_no_field_match .
      CLEAR lf_field_with_and.
    ENDAT.
  ENDLOOP.
ENDFORM.                    " get_auths_for_in_scope_tcodes
*&---------------------------------------------------------------------*
*&      Form  get_auth_that_match_sod_valsfm
*&---------------------------------------------------------------------*
*--Put the matching auth fields in gt_matching_auths
*--Put the non-matching fields in gt_no_field_match
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_auth_that_match_sod_valsfm.
  DATA : l_ust12_idx TYPE sy-tabix.
  FIELD-SYMBOLS: <pair> TYPE /psyng/auth_compare.
  DATA : lt_compare TYPE TABLE OF /psyng/auth_compare,
         pair       TYPE /psyng/auth_compare.


  DEFINE add_match.
    if &1-match = 'X'.
*      one_exist       = 'X'.
*      wfaobj-flag     = 'X'.
      gt_matching_auths-auth  = &1-auth.
      insert table gt_matching_auths.
    else.
      gt_no_field_match-auth = &1-auth.
      insert table gt_no_field_match.
    endif.
  END-OF-DEFINITION.

  TRANSLATE gt_faobj_match-val_from TO UPPER CASE.
  TRANSLATE gt_faobj_match-val_to   TO UPPER CASE.


  pair-sod_from            = gt_faobj_match-val_from.
  pair-sod_to              = gt_faobj_match-val_to.
  gt_matching_auths-von    = gt_faobj_match-val_from.
  gt_matching_auths-bis    = gt_faobj_match-val_to.
  gt_matching_auths-field  = gt_faobj_match-field.
  gt_matching_auths-objct  = gt_faobj_match-object.
  gt_matching_auths-funid  = gt_faobj_match-funid.
  gt_matching_auths-tcode  = gt_faobj_match-tcode.

  gt_no_field_match-funid  = gt_faobj_match-funid.
  gt_no_field_match-tcode  = gt_faobj_match-tcode.
  gt_no_field_match-field  = gt_faobj_match-field.
  gt_no_field_match-objct  = gt_faobj_match-object.

  READ TABLE gt_ust12 WITH KEY objct = gt_faobj_match-object
                               field  = gt_faobj_match-field
       BINARY SEARCH TRANSPORTING NO FIELDS.
  if sy-subrc = 0.
    l_ust12_idx = sy-tabix.
    LOOP AT gt_ust12 FROM l_ust12_idx.
      IF NOT  gt_ust12-objct = gt_faobj_match-object OR
         NOT  gt_ust12-field = gt_faobj_match-field.
        EXIT.
      ENDIF.
      pair-auth_from  = gt_ust12-von.
      pair-auth_to    = gt_ust12-bis.
      pair-auth       = gt_ust12-auth.
      TRANSLATE pair-auth_from TO UPPER CASE.
      TRANSLATE pair-auth_to   TO UPPER CASE.
      IF pair-auth_to   IS INITIAL AND
         pair-auth_from NS '*'     AND
         pair-sod_to   IS INITIAL AND
         pair-sod_from NS '*'.
        IF pair-auth_from = pair-sod_from.
          pair-match = 'X'.
        ELSEIF pair-sod_from IS INITIAL.
*  --Case 1986 & 10104: Blank value functions as a wildcard,
*                Any value matches
          pair-match = 'X'.
        ENDIF.
        add_match pair.
        CLEAR pair-match.
      ELSE.
        APPEND pair TO lt_compare.
      ENDIF.
    ENDLOOP.

  endif.
*  CALL FUNCTION '/PSYNG/SW_021'
   CALL FUNCTION '/PSYNG/SW_COMPARE_RANGES'
       EXPORTING
            I_BUFFER_SIZE = 50000
       TABLES
            it_compare = lt_compare .

  LOOP AT lt_compare ASSIGNING <pair>.
    add_match <pair>.
  ENDLOOP.
  FREE : lt_compare.

ENDFORM.                    " get_auth_that_match_sod_valsfm
*&---------------------------------------------------------------------*
*&      Form  delete_non_existing_fields
*&---------------------------------------------------------------------*
*--If there's a field for which there was a record for an auth that
*  didn't match, check if there is one that did match, and if not,
*  delete everything for this object for this auth
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM delete_non_existing_fields.
data : l_tabix like sy-tabix.
  LOOP AT gt_no_field_match.
    READ TABLE gt_matching_auths WITH  KEY
      funid = gt_no_field_match-funid
      tcode = gt_no_field_match-tcode
      objct = gt_no_field_match-objct
      auth  = gt_no_field_match-auth
      field = gt_no_field_match-field
      binary search
      TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
    READ TABLE gt_matching_auths WITH  KEY
      funid = gt_no_field_match-funid
      tcode = gt_no_field_match-tcode
      objct = gt_no_field_match-objct
      auth  = gt_no_field_match-auth
      binary search
      TRANSPORTING NO FIELDS.
      if sy-subrc = 0.
        l_tabix = sy-tabix.
*--One field didn't match at all, so delete entire object for auth
        DELETE gt_matching_auths
        from l_tabix
        WHERE
          funid = gt_no_field_match-funid AND
          tcode = gt_no_field_match-tcode AND
          objct = gt_no_field_match-objct AND
          auth  = gt_no_field_match-auth.
       endif.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " delete_non_existing_fields
*&---------------------------------------------------------------------*
*&      Form  clear_global_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM clear_global_data.
  FREE :
    gt_ust12,
    gt_faobj,
    gt_tcd,gt_matches,
    gt_matching_auths,
    gt_no_field_match,
    gt_faobj_match.

ENDFORM.                    " clear_global_data
*&---------------------------------------------------------------------*
*&      Form  field_level_and_relation
*&---------------------------------------------------------------------*
*      at least one field in this valueset had fld_and set to X
*      for the fields with fld_and = X, there needs to be one record
*      for each line in wfaobj for that field in order for an auth to be
*      considered for that field
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM field_level_and_relation.
  FIELD-SYMBOLS :
          <faobj> LIKE gt_faobj.
  DATA : l_tabix TYPE sy-tabix,
         l_nr_vals_for_fields TYPE i,
         l_nr_vals_for_auth TYPE i,
         lf_and TYPE flag,
         l_prev_auth TYPE xuauth.

  READ TABLE gt_faobj WITH KEY
            funid    = gt_faobj_match-funid
            tcode    = gt_faobj_match-tcode
            object   = gt_faobj_match-object
            valueset = gt_faobj_match-valueset
  BINARY SEARCH TRANSPORTING NO FIELDS.
  l_tabix = sy-tabix.

  LOOP AT gt_faobj ASSIGNING <faobj> FROM l_tabix.
    IF NOT <faobj>-funid    = gt_faobj_match-funid OR
       NOT <faobj>-tcode    = gt_faobj_match-tcode OR
       NOT <faobj>-object   = gt_faobj_match-object OR
       NOT <faobj>-valueset = gt_faobj_match-valueset.
      EXIT.
    ENDIF.
    AT NEW field.
      CLEAR l_nr_vals_for_fields.
    ENDAT.
    ADD 1 TO l_nr_vals_for_fields.
    lf_and = <faobj>-fld_and.
    AT END OF field.
      CHECK lf_and = 'X'.
      CLEAR :  l_nr_vals_for_auth,l_prev_auth.
      LOOP AT gt_matching_auths WHERE objct = <faobj>-object AND
                                      field = <faobj>-field.
*BOC UMITTAL/GGAUTAM   PN 13355 23/05/2025
*Siemens issue for AND relation between Objects
        IF  l_prev_auth <> gt_matching_auths-auth.
*                check if the previous auth did not match for
*                all the values that were defined
          IF NOT l_prev_auth  IS INITIAL AND
             l_nr_vals_for_auth < l_nr_vals_for_fields.
            DELETE gt_matching_auths WHERE
            funid =  <faobj>-funid AND
            auth  =  l_prev_auth.
          ENDIF.
          CLEAR l_nr_vals_for_auth.
        ENDIF.
*EOC UMITTAL/GGAUTAM   PN 13355 23/05/2025
        ADD 1 TO l_nr_vals_for_auth.
        l_prev_auth = gt_matching_auths-auth.

      ENDLOOP.

*              check if the previous auth did not match for
*              all the values that were defined
      IF NOT l_prev_auth  IS INITIAL AND
         l_nr_vals_for_auth < l_nr_vals_for_fields.
        DELETE gt_matching_auths WHERE auth = l_prev_auth.
      ENDIF.


    ENDAT.
  ENDLOOP.

ENDFORM.                    " field_level_and_relation
