FUNCTION /psyng/sw_016.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_BNAME) TYPE  XUBNAME
*"  EXPORTING
*"     VALUE(EF_HAS_CONFLICT) TYPE  /PSYNG/BAPIFLAGX
*"----------------------------------------------------------------------
DATA: BEGIN OF lt_address OCCURS 0,
        persnumber TYPE usr21-persnumber,
        addrnumber TYPE usr21-addrnumber,
        smtp_srch  TYPE adr6-smtp_srch,
      END OF lt_address.

DATA: BEGIN OF lt_adr6 OCCURS 0,
        persnumber TYPE usr21-persnumber,
        addrnumber TYPE usr21-addrnumber,
        smtp_srch  TYPE adr6-smtp_srch,
      END OF lt_adr6.

DATA: BEGIN OF lt_adr OCCURS 0,
        persnumber TYPE usr21-persnumber,
        addrnumber TYPE usr21-addrnumber,
      END OF lt_adr.

DATA: l_addr TYPE adr6-addrnumber,
      l_pers TYPE adr6-persnumber.


  CLEAR ef_has_conflict.

* Get current user
  SELECT usr21~persnumber usr21~addrnumber adr6~smtp_srch
     INTO TABLE lt_address
     FROM usr21 INNER JOIN adr6
       ON usr21~addrnumber = adr6~addrnumber
      AND usr21~persnumber = adr6~persnumber
    WHERE usr21~bname     = i_bname
      AND adr6~date_from <= sy-datum.

  SORT lt_address BY smtp_srch.
  DELETE ADJACENT DUPLICATES FROM lt_address COMPARING smtp_srch.

* Check for other users with same email address

IF NOT lt_address[] IS INITIAL.
  SELECT  adr6~persnumber adr6~addrnumber adr6~smtp_srch
    INTO TABLE lt_adr6
      FROM adr6 FOR ALL ENTRIES IN lt_address
        WHERE adr6~smtp_srch = lt_address-smtp_srch.

 IF sy-subrc EQ 0 and not lt_adr6[] is initial.
  SELECT persnumber addrnumber INTO TABLE lt_adr
      FROM usr21 FOR ALL ENTRIES IN lt_adr6
        WHERE addrnumber = lt_adr6-addrnumber
         AND persnumber = lt_adr6-persnumber.
 ENDIF.
ENDIF.

  LOOP AT lt_adr6.
    READ TABLE lt_adr WITH KEY addrnumber = lt_adr6-addrnumber
                               persnumber = lt_adr6-persnumber.
    IF sy-subrc NE 0.
      DELETE lt_adr6.
    ENDIF.
  ENDLOOP.

LOOP AT lt_address.
  LOOP AT lt_adr6 WHERE smtp_srch = lt_address-smtp_srch.
    IF lt_adr6-addrnumber <> lt_address-addrnumber
    OR lt_adr6-persnumber <> lt_address-persnumber.
       ef_has_conflict = 'X'.
       EXIT.
   ENDIF.
  ENDLOOP.

    IF ef_has_conflict = 'X'.
     EXIT.
    ENDIF.
ENDLOOP.

ENDFUNCTION.
