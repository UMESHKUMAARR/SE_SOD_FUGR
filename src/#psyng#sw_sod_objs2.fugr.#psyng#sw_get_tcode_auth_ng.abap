*----------------------------------------------------------------------*
* Function Module       : /PSYNG/SW_GET_TCODE_AUTH_DATA
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS: Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_get_tcode_auth_ng.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(REM_EXECUTION) TYPE  CHAR01 OPTIONAL
*"     VALUE(RFCDEST) LIKE  RFCDES-RFCDEST OPTIONAL
*"     VALUE(AGR_NAME) TYPE  AGR_DEFINE-AGR_NAME
*"  TABLES
*"      TCD STRUCTURE  /PSYNG/PSSWTCD
*"      FAOBJ STRUCTURE  /PSYNG/FAOBJ2
*"      FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN
*"      TCDAUT STRUCTURE  /PSYNG/PSSWTCDAUT OPTIONAL
*"      UNIQUEAUTHS STRUCTURE  /PSYNG/UNIQUEAUTHS OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_GET_TCODE_AUTH_NG'.
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

  DATA: dest LIKE rfcdes-rfcdest,
        iust12_idx     TYPE i.

  CHECK NOT uniqueauths[] IS INITIAL.

  IF rem_execution <> space.  "read FM documentation
    CHECK rfcdest <> space.
    dest = rfcdest.
  ELSE.
    CONCATENATE sy-sysid sy-mandt INTO dest.
  ENDIF.

  SORT: faobj, tcd.
  DELETE ADJACENT DUPLICATES FROM tcd COMPARING ALL FIELDS.
  itcd[] = tcd[].
  ifaobj[] = faobj[].

*  SELECT * FROM ust12
  SELECT * FROM agr_1251
           INTO CORRESPONDING FIELDS OF wa_agr_1251
           FOR ALL ENTRIES IN uniqueauths
           WHERE agr_name = agr_name AND
                 object = uniqueauths-objct  AND
                 auth  = uniqueauths-auth   AND
                 deleted = space.
    IF wa_agr_1251-low+0(1) <> '$'.    "if field is not org level
      wa_1ust12-objct = wa_agr_1251-object.
      wa_1ust12-aktps = 'A'.
      wa_1ust12-field = wa_agr_1251-field.
      wa_1ust12-auth = wa_agr_1251-auth.
      wa_1ust12-von = wa_agr_1251-low.
      wa_1ust12-bis = wa_agr_1251-high.
      INSERT wa_1ust12 INTO TABLE 1ust12.
    ELSE.
      SELECT * FROM agr_1252 WHERE agr_name = agr_name AND
                                      varbl = wa_agr_1251-low.
        wa_1ust12-objct = wa_agr_1251-object.
        wa_1ust12-aktps = 'A'.
        wa_1ust12-field = wa_agr_1251-field.
        wa_1ust12-auth = wa_agr_1251-auth.
        wa_1ust12-von = agr_1252-low.
        wa_1ust12-bis = agr_1252-high.
        INSERT wa_1ust12 INTO TABLE 1ust12.
      ENDSELECT.
    ENDIF.
  ENDSELECT.

  PERFORM get_in_scope_tcd_obj_auth
*                  TABLES functtran faobj tcd uniqueauths
                  TABLES functtran uniqueauths
                  USING dest.

  PERFORM get_auths_for_in_scope_tcodes.

  LOOP AT iust12.
    tcdaut-rfcdest = dest.
    MOVE-CORRESPONDING iust12 TO tcdaut.
    APPEND tcdaut.
  ENDLOOP.


ENDFUNCTION.


*&---------------------------------------------------------------------*
*&      Form  GET_IN_SCOPE_TCD_OBJ_AUTH
*&---------------------------------------------------------------------*
FORM get_in_scope_tcd_obj_auth TABLES
                           functtran   STRUCTURE /psyng/functtran
                           uniqueauths STRUCTURE /psyng/uniqueauths
                           USING dest.

  LOOP AT functtran.
    READ TABLE itcd WITH KEY tcode = functtran-tcode rfcdest = dest
                                   BINARY SEARCH TRANSPORTING NO FIELDS.
    CHECK sy-subrc = 0.
    READ TABLE wfaobj WITH KEY funid = functtran-functionid
                               tcode = functtran-tcode
                               BINARY SEARCH
                               TRANSPORTING NO FIELDS.
    CHECK sy-subrc <> 0.
    READ TABLE ifaobj WITH KEY funid = functtran-functionid
                               tcode = functtran-tcode
                               BINARY SEARCH
                               TRANSPORTING NO FIELDS.
    ifaobj_idx = sy-tabix.
    LOOP AT ifaobj FROM ifaobj_idx
                   WHERE funid = functtran-functionid AND
                         tcode = functtran-tcode.
      MOVE-CORRESPONDING ifaobj TO wa_wfaobj.
      INSERT wa_wfaobj INTO TABLE wfaobj.
      REFRESH iiust12.
      CLEAR dbust12_idx.
      READ TABLE 1ust12 WITH KEY objct = ifaobj-object
                                 aktps = 'A'
                                 field = ifaobj-field
                                 BINARY SEARCH
                                 TRANSPORTING NO FIELDS.
      dbust12_idx = sy-tabix.
      LOOP AT 1ust12 FROM dbust12_idx
                      WHERE objct = ifaobj-object AND
                            aktps = 'A' AND
                            field = ifaobj-field.
        INSERT 1ust12 INTO TABLE xust12.
      ENDLOOP.

    ENDLOOP.   "ifaobj
  ENDLOOP.

  REFRESH iiust12.
ENDFORM.                    " GET_IN_SCOPE_TCD_OBJ_AUTH

*&---------------------------------------------------------------------*
*&      Form  GET_AUTHS_FOR_IN_SCOPE_TCODES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_auths_for_in_scope_tcodes.
  LOOP AT wfaobj.
    one_exist = space.
    PERFORM get_auth_that_match_sod_values.
    IF one_exist > space.
      wfaobj-flag = 'X'.
      MODIFY wfaobj.
    ENDIF.
    AT END OF valueset.
      PERFORM delete_non_existing_fields.
      APPEND LINES OF iust12 TO kust12.     "for performance
      REFRESH: iust12, just12.              "for performance
    ENDAT.
  ENDLOOP.
  REFRESH: iust12, just12.                  "for performance
  SORT kust12.                              "for performance
  DELETE ADJACENT DUPLICATES FROM kust12.   "for performance
  iust12[] = kust12[].                      "for performance
  REFRESH: kust12.                          "for performance

*  LOOP AT wvr_sod_objects WHERE flag NE 'X'.
*    REFRESH iust12. REFRESH just12.
*  ENDLOOP.
*  PERFORM delete_non_existing_fields.

ENDFORM.                    " GET_AUTHS_FOR_IN_SCOPE_TCODES
*&---------------------------------------------------------------------*
*&      Form  GET_AUTH_THAT_MATCH_SOD_VALUES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*

FORM get_auth_that_match_sod_values.
  READ TABLE xust12 WITH KEY objct = wfaobj-object
                             aktps = 'A'
                             field = wfaobj-field
                             BINARY SEARCH
                             TRANSPORTING NO FIELDS.
  xust12_idx = sy-tabix.
  LOOP AT xust12 FROM xust12_idx
          WHERE objct = wfaobj-object
          AND aktps   = 'A'
          AND field   = wfaobj-field.
    exist = space.

    TRANSLATE wfaobj-val_from TO UPPER CASE.
    TRANSLATE wfaobj-val_to   TO UPPER CASE.
    TRANSLATE xust12-von                TO UPPER CASE.
    TRANSLATE xust12-bis                TO UPPER CASE.

* If fist Value is *
    IF xust12-von = '*'.
      exist = 'X'.
    ENDIF.

* If second Value is *
    IF xust12-bis = '*' AND xust12-von <= wfaobj-val_to.
      exist = 'X'.
    ENDIF.

* If Any of the Values Matches

    IF wfaobj-val_from = xust12-von.
      exist = 'X'.
    ENDIF.
    IF wfaobj-val_to = xust12-von.
      exist = 'X'.
    ENDIF.
    IF wfaobj-val_from = xust12-bis.
      exist = 'X'.
    ENDIF.
    IF wfaobj-val_to = xust12-bis AND
       wfaobj-val_to <> space.
      exist = 'X'.
    ENDIF.
* If both the fields in UST12 is populated
    IF ust12-bis > space.
      IF wfaobj-val_to > space.
        IF wfaobj-val_from >= xust12-von
        AND wfaobj-val_from <= xust12-bis.
          exist = 'X'.
        ENDIF.
        IF wfaobj-val_from <= xust12-von
        AND wfaobj-val_from <= xust12-bis.
          exist = 'X'.
        ENDIF.
*==========================================================
*IF UST12 IS A* TO B*     AND SOD TABLE IS BKPF TO BZES
        CLEAR sy-fdpos.
        REPLACE '*' WITH '!' INTO xust12-bis.
        SEARCH xust12-bis FOR '!'.
        IF sy-subrc = 0.
          REPLACE '!' WITH '*' INTO xust12-bis.
          IF sy-fdpos = 0.
            sy-fdpos = 1.
          ENDIF.
          IF xust12-bis(sy-fdpos) = wfaobj-val_from(sy-fdpos).
            exist = 'X'.
          ENDIF.
        ENDIF.
*==========================================================
        IF wfaobj-val_to >= xust12-von
        AND wfaobj-val_to <= xust12-bis.
          exist = 'X'.
        ENDIF.
      ELSE.
*================================================================
* IF UST12 IS ABCD   ADEF  AND SOD FROM IS A*
        CLEAR sy-fdpos.
        REPLACE '*' WITH '!' INTO wfaobj-val_from.
        SEARCH wfaobj-val_from FOR '!'.
        IF sy-subrc = 0.
          REPLACE '!' WITH '*' INTO wfaobj-val_from.
          IF sy-fdpos = 0.
            sy-fdpos = 1.
          ENDIF.
          IF wfaobj-val_from(sy-fdpos) = xust12-von(sy-fdpos).
            exist = 'X'.
          ENDIF.
          IF wfaobj-val_from(sy-fdpos) = xust12-bis(sy-fdpos).
            exist = 'X'.
          ENDIF.
        ENDIF.
*================================================================
        IF wfaobj-val_from >= xust12-von
        AND wfaobj-val_from <= xust12-bis.
          exist = 'X'.
        ENDIF.
      ENDIF.
    ELSE.
* Only From Value in UST12 is populated
      IF wfaobj-val_to > space.
        IF xust12-von >= wfaobj-val_from
        AND xust12-von <= wfaobj-val_to.
          exist = 'X'.
        ENDIF.
      ELSE.
*========================================================
* * LOGIC FOR BOTH UST12 AND wfaobj-FROM
        CLEAR sy-fdpos.
        REPLACE '*' WITH '!' INTO xust12-von.
        SEARCH xust12-von FOR '!'.
        IF sy-subrc = 0.
          REPLACE '!' WITH '*' INTO xust12-von.
          IF sy-fdpos = 0.
            sy-fdpos = 1.
          ENDIF.
          IF xust12-von(sy-fdpos) = wfaobj-val_from(sy-fdpos).
            exist = 'X'.
          ENDIF.
        ENDIF.
*=========================================================
        CLEAR sy-fdpos.
        REPLACE '*' WITH '!' INTO wfaobj-val_from.
        SEARCH wfaobj-val_from FOR '!'.
        IF sy-subrc = 0.
          REPLACE '!' WITH '*' INTO wfaobj-val_from.
          IF sy-fdpos = 0.
            sy-fdpos = 1.
          ENDIF.
          IF wfaobj-val_from(sy-fdpos) = xust12-von(sy-fdpos).
            exist = 'X'.
          ENDIF.
        ENDIF.

      ENDIF.
    ENDIF.
*=========================================================
    IF wfaobj-val_from >= xust12-von AND
       wfaobj-val_from <= xust12-bis AND
       wfaobj-val_to >= xust12-bis.
      exist = 'X'.
    ENDIF.
*=========================================================

    IF exist > space.
      one_exist = 'X'.
      wfaobj-flag = 'X'.
      MOVE-CORRESPONDING xust12 TO wa_iust12.
      wa_iust12-von = wfaobj-val_from. "document WEAVER values
      wa_iust12-bis = wfaobj-val_to.   "instead of UST12
      wa_iust12-tcode = wfaobj-tcode.
      wa_iust12-funid = wfaobj-funid.
      INSERT wa_iust12 INTO TABLE iust12.
    ELSE.
      MOVE-CORRESPONDING xust12 TO wa_just12.
*      wa_just12-von = wfaobj-val_from. "document WEAVER values
*      wa_just12-bis = wfaobj-val_to.   "instead of UST12
      wa_just12-tcode = wfaobj-tcode.
      wa_just12-funid = wfaobj-funid.
      INSERT wa_just12 INTO TABLE just12.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " GET_AUTH_THAT_MATCH_SOD_VALUES

*&---------------------------------------------------------------------*
*&      Form  DELETE_NON_EXISTING_FIELDS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM delete_non_existing_fields.
  LOOP AT just12.
    READ TABLE iust12 WITH KEY funid = just12-funid
                               tcode = just12-tcode
                               mandt = just12-mandt "#EC SAST_CI_GEN_CHECK
                               objct = just12-objct
                               auth  = just12-auth
                               aktps = just12-aktps
                               field = just12-field
*                               von   = just12-von
*                               bis   = just12-bis
                               BINARY SEARCH
                               TRANSPORTING NO FIELDS.
    IF sy-subrc NE 0.
      DELETE iust12
        WHERE funid = just12-funid AND
              tcode = just12-tcode AND
              mandt = just12-mandt AND
              objct = just12-objct AND
              auth  = just12-auth.
    ENDIF.
  ENDLOOP.

ENDFORM.
