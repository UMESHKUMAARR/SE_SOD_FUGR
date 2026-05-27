*----------------------------------------------------------------------*
* Function Module       : /PSYNG/SW_GET_TCODE_AUTH_DATA
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_get_crit_aut_data_ng.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(REM_EXECUTION) TYPE  CHAR01 OPTIONAL
*"     VALUE(RFCDEST) LIKE  RFCDES-RFCDEST OPTIONAL
*"  TABLES
*"      TCD STRUCTURE  /PSYNG/PSSWTCD OPTIONAL
*"      TCDAUT STRUCTURE  /PSYNG/PSSWTCDAUT OPTIONAL
*"      IUST12 STRUCTURE  UST12
*"      SWAUDC STRUCTURE  /PSYNG/SWAUDC2
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_GET_CRIT_AUT_DATA_NG'.
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
*  DATA: BEGIN OF iswaudc OCCURS 0.
*          INCLUDE STRUCTURE /psyng/swaudc_1.
*  DATA: END OF iswaudc.
  DATA: iswaudc TYPE STANDARD TABLE OF /psyng/swaudc_1 WITH HEADER LINE.

  REFRESH: tcdaut.

  LOOP AT swaudc.
    MOVE-CORRESPONDING swaudc TO iswaudc.
    APPEND iswaudc.
  ENDLOOP.
*  REFRESH: swaudc.

  PERFORM get_cri_auths_ng TABLES iust12 iswaudc.

  IF rem_execution <> space.  "read FM documentation
    CHECK rfcdest <> space.
    dest = rfcdest.
  ELSE.
    CONCATENATE sy-sysid sy-mandt INTO dest.
  ENDIF.

  LOOP AT iust12a.
    tcdaut-rfcdest = dest.
    MOVE-CORRESPONDING iust12a TO tcdaut.
    APPEND tcdaut.
  ENDLOOP.

ENDFUNCTION.

*&---------------------------------------------------------------------*
*&      Form  get_cri_auths
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_cri_auths_ng TABLES
                           iust12   STRUCTURE ust12
                           iswaudc STRUCTURE /psyng/swaudc_1.
  SORT iswaudc BY valueset.
  LOOP AT iswaudc.
    one_exist = space.
    PERFORM get_auth_match_cri_values_ng
                  TABLES iust12 iswaudc.
    IF one_exist > space.
      iswaudc-flag = 'X'.
      MODIFY iswaudc.
    ENDIF.
    AT END OF valueset.
      PERFORM del_non_existing_fields_cri_ng.
      APPEND LINES OF iust12a TO kust12a.     "for performance
      REFRESH: iust12a, just12a.              "for performance
    ENDAT.
  ENDLOOP.
  REFRESH: iust12a, just12a.                  "for performance
  SORT kust12a.                              "for performance
  DELETE ADJACENT DUPLICATES FROM kust12a.   "for performance
  iust12a[] = kust12a[].                      "for performance
  REFRESH: kust12a.                          "for performance

*  LOOP AT iswaudc WHERE flag NE 'X'.
*    REFRESH iust12. REFRESH just12.
*  ENDLOOP.
*  PERFORM delete_non_existing_fields_cri.

ENDFORM.                    "
*&---------------------------------------------------------------------*
*&      Form  GET_AUTH_THAT_MATCH_cri_VALUES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*

FORM get_auth_match_cri_values_ng TABLES
                           iust12   STRUCTURE ust12
                           iswaudc STRUCTURE /psyng/swaudc_1.

  LOOP AT iust12
          WHERE objct = iswaudc-object
          AND aktps   = 'A'
          AND field   = iswaudc-field.
    exist = space.

    TRANSLATE iswaudc-val_from TO UPPER CASE.
    TRANSLATE iswaudc-val_to   TO UPPER CASE.
    TRANSLATE iust12-von                TO UPPER CASE.
    TRANSLATE iust12-bis                TO UPPER CASE.

* If fist Value is *
    IF iust12-von = '*'.
      exist = 'X'.
    ENDIF.

* If second Value is *
    IF iust12-bis = '*' AND iust12-von <= iswaudc-val_to.
      exist = 'X'.
    ENDIF.

* If Any of the Values Matches

    IF iswaudc-val_from = iust12-von.
      exist = 'X'.
    ENDIF.
    IF iswaudc-val_to = iust12-von.
      exist = 'X'.
    ENDIF.
    IF iswaudc-val_from = iust12-bis.
      exist = 'X'.
    ENDIF.
    IF iswaudc-val_to = iust12-bis AND
       iswaudc-val_to <> space.
      exist = 'X'.
    ENDIF.
* If both the fields in UST12 is populated
    IF ust12-bis > space.
      IF iswaudc-val_to > space.
        IF iswaudc-val_from >= iust12-von
        AND iswaudc-val_from <= iust12-bis.
          exist = 'X'.
        ENDIF.
        IF iswaudc-val_from <= iust12-von
        AND iswaudc-val_from <= iust12-bis.
          exist = 'X'.
        ENDIF.
*==========================================================
*IF UST12 IS A* TO B*     AND SOD TABLE IS BKPF TO BZES
        CLEAR sy-fdpos.
        REPLACE '*' WITH '!' INTO iust12-bis.
        SEARCH iust12-bis FOR '!'.
        IF sy-subrc = 0.
          REPLACE '!' WITH '*' INTO iust12-bis.
          IF sy-fdpos = 0.
            sy-fdpos = 1.
          ENDIF.
          IF iust12-bis(sy-fdpos) = iswaudc-val_from(sy-fdpos).
            exist = 'X'.
          ENDIF.
        ENDIF.
*==========================================================
        IF iswaudc-val_to >= iust12-von
        AND iswaudc-val_to <= iust12-bis.
          exist = 'X'.
        ENDIF.
      ELSE.
*================================================================
* IF UST12 IS ABCD   ADEF  AND SOD FROM IS A*
        CLEAR sy-fdpos.
        REPLACE '*' WITH '!' INTO iswaudc-val_from.
        SEARCH iswaudc-val_from FOR '!'.
        IF sy-subrc = 0.
          REPLACE '!' WITH '*' INTO iswaudc-val_from.
          IF sy-fdpos = 0.
            sy-fdpos = 1.
          ENDIF.
          IF iswaudc-val_from(sy-fdpos) = iust12-von(sy-fdpos).
            exist = 'X'.
          ENDIF.
          IF iswaudc-val_from(sy-fdpos) = iust12-bis(sy-fdpos).
            exist = 'X'.
          ENDIF.
        ENDIF.
*================================================================
        IF iswaudc-val_from >= iust12-von
        AND iswaudc-val_from <= iust12-bis.
          exist = 'X'.
        ENDIF.
      ENDIF.
    ELSE.
* Only From Value in UST12 is populated
      IF iswaudc-val_to > space.
        IF iust12-von >= iswaudc-val_from
        AND iust12-von <= iswaudc-val_to.
          exist = 'X'.
        ENDIF.
      ELSE.
*========================================================
* * LOGIC FOR BOTH UST12 AND iswaudc-FROM
        CLEAR sy-fdpos.
        REPLACE '*' WITH '!' INTO iust12-von.
        SEARCH iust12-von FOR '!'.
        IF sy-subrc = 0.
          REPLACE '!' WITH '*' INTO iust12-von.
          IF sy-fdpos = 0.
            sy-fdpos = 1.
          ENDIF.
          IF iust12-von(sy-fdpos) = iswaudc-val_from(sy-fdpos).
            exist = 'X'.
          ENDIF.
        ENDIF.
*=========================================================
        CLEAR sy-fdpos.
        REPLACE '*' WITH '!' INTO iswaudc-val_from.
        SEARCH iswaudc-val_from FOR '!'.
        IF sy-subrc = 0.
          REPLACE '!' WITH '*' INTO iswaudc-val_from.
          IF sy-fdpos = 0.
            sy-fdpos = 1.
          ENDIF.
          IF iswaudc-val_from(sy-fdpos) = iust12-von(sy-fdpos).
            exist = 'X'.
          ENDIF.
        ENDIF.

      ENDIF.
    ENDIF.
*=========================================================
    IF iswaudc-val_from >= iust12-von AND
       iswaudc-val_from <= iust12-bis AND
       iswaudc-val_to >= iust12-bis.
      exist = 'X'.
    ENDIF.
*=========================================================

    IF exist > space.
      one_exist = 'X'.
      iswaudc-flag = 'X'.
      MOVE-CORRESPONDING iust12 TO wa_iust12.
      wa_iust12-funid = iswaudc-swaudid.
      wa_iust12-von = iswaudc-val_from. "document WEAVER values
      wa_iust12-bis = iswaudc-val_to.   "instead of UST12
      wa_iust12-tcode = iswaudc-tcode.
      INSERT wa_iust12 INTO TABLE iust12a.
    ELSE.
      MOVE-CORRESPONDING iust12 TO wa_just12.
      wa_just12-funid = iswaudc-swaudid.
*      wa_just12-von = iswaudc-val_from. "document WEAVER values
*      wa_just12-bis = iswaudc-val_to.   "instead of UST12
      wa_just12-tcode = iswaudc-tcode.
      INSERT wa_just12 INTO TABLE just12a.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " GET_cri_auth

*&---------------------------------------------------------------------*
*&      Form  DELETE_NON_EXISTING_FIELDS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM del_non_existing_fields_cri_ng.
  LOOP AT just12a.
*    READ TABLE iust12 WITH KEY funid = just12a-funid
    READ TABLE iust12a WITH KEY funid = just12a-funid
                               tcode = just12a-tcode
                               mandt = just12a-mandt "#EC SAST_CI_GEN_CHECK
                               objct = just12a-objct
                               auth  = just12a-auth
                               aktps = just12a-aktps
                               field = just12a-field
*                               von   = just12a-von
*                               bis   = just12a-bis
                               BINARY SEARCH
                               TRANSPORTING NO FIELDS.
    IF sy-subrc NE 0.
      DELETE iust12a
        WHERE funid = just12a-funid AND
              tcode = just12a-tcode AND
              mandt = just12a-mandt AND "#EC SAST_CI_GEN_CHECK
              objct = just12a-objct AND
              auth  = just12a-auth. " AND
*              aktps = just12a-aktps AND
*              field = just12a-field AND
*              von   = just12a-von AND
*              bis   = just12a-bis.
    ENDIF.
  ENDLOOP.

ENDFORM.
