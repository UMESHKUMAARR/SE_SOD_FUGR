FUNCTION /PSYNG/SW_052.
*"----------------------------------------------------------------------
*"*"Local interface:
*"       IMPORTING
*"             REFERENCE(PARENT_ROLE) TYPE  AGR_NAME
*"             REFERENCE(DERIVED_ROLE) TYPE  AGR_NAME
*"             REFERENCE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"       TABLES
*"              FAOBJ_FIELDS STRUCTURE  /PSYNG/FAOBJ2
*"       EXCEPTIONS
*"              NOT_IDENTICAL
*"----------------------------------------------------------------------
*This FM checks if a parent and a derived role are the same,
*ignoring the org level fields.
  DATA : lt_ust12_parent TYPE TABLE OF ust12,
         lt_ust12_derived TYPE TABLE OF ust12,
         l_profname TYPE xuprofile,
         BEGIN OF ls_auth ,
           auth TYPE xuauth,
           objct TYPE xuobject,
         END OF ls_auth,
         lt_auths LIKE TABLE OF ls_auth,
         BEGIN OF lt_profname OCCURS 0,
           profile TYPE xuprofile,
         END OF lt_profname,
         ls_parent_role TYPE type_parent_role,
         ls_ust12 TYPE ust12.
  FIELD-SYMBOLS : <org> TYPE xufield,
                  <ust12> TYPE ust12.
*when function module is called directly, get the faobj data from
*the database
  IF faobj_fields[] IS INITIAL.
    SELECT * FROM /psyng/faobj2     "#EC CI_SEL_NESTED
    INTO TABLE faobj_fields
    WHERE vrsio = vrsio.
*Add S_TCODE to the faobj table
    DATA : ls_faobj LIKE LINE OF   faobj_fields.
    ls_faobj-object = 'S_TCODE'.
    ls_faobj-field  = 'TCD'.
    APPEND ls_faobj TO faobj_fields.
    SORT faobj_fields BY object field.
    DELETE ADJACENT DUPLICATES FROM faobj_fields
    COMPARING object field.
  ENDIF.
*select data from ust12 1 time.
  IF gt_ust12[] IS INITIAL AND gt_parent_role[] IS INITIAL. "first time
    "fm is called
    SELECT auth objct field von bis FROM ust12    "#EC CI_SEL_NESTED
    INTO CORRESPONDING FIELDS OF TABLE gt_ust12
    FOR ALL ENTRIES IN faobj_fields WHERE
                               objct = faobj_fields-object
                               AND aktps = 'A'
                               AND field = faobj_fields-field.
  ENDIF.
*parent roles are buffered in table gt_parent_role
  READ TABLE gt_parent_role INTO ls_parent_role
  WITH TABLE KEY agr_name = parent_role.
  IF sy-subrc = 0.
    lt_ust12_parent[] = ls_parent_role-ust12[].
  ELSE.
    SELECT profile FROM agr_1016 INTO TABLE lt_profname
      WHERE agr_name = parent_role.
    IF NOT lt_profname[] IS INITIAL.
*     get the profile contents , but only the objects that are in
*     the sod matrix
      SELECT DISTINCT auth  "#EC CI_NO_TRANSFORM  "#EC CI_SEL_NESTED
        FROM ust10s
          INTO ls_auth-auth
      FOR ALL ENTRIES IN lt_profname WHERE profn = lt_profname-profile.
        LOOP AT gt_ust12 ASSIGNING <ust12> WHERE auth  = ls_auth-auth.
          ls_ust12-objct = <ust12>-objct .
          ls_ust12-field = <ust12>-field .
          ls_ust12-von   = <ust12>-von .
          ls_ust12-bis   = <ust12>-bis .
          APPEND ls_ust12 TO lt_ust12_parent.
        ENDLOOP.
      ENDSELECT.
    ENDIF.
    ls_parent_role-agr_name = parent_role.
    ls_parent_role-ust12[] = lt_ust12_parent.
    INSERT ls_parent_role INTO TABLE gt_parent_role.
  ENDIF.
  SELECT profile FROM agr_1016 INTO TABLE lt_profname
    WHERE agr_name = derived_role.
  IF NOT lt_profname[] IS INITIAL.
    SELECT auth objct FROM ust10s INTO TABLE lt_auths
    FOR ALL ENTRIES IN lt_profname WHERE profn = lt_profname-profile.
    IF NOT lt_profname[] IS INITIAL.
*   get the profile contents , but only the objects that are in
*   the sod matrix
      SELECT DISTINCT auth FROM ust10s         "#EC CI_SEL_NESTED
        INTO ls_auth-auth
         FOR ALL ENTRIES IN lt_profname
           WHERE profn = lt_profname-profile.

        LOOP AT gt_ust12 ASSIGNING <ust12> WHERE auth  = ls_auth-auth.
          ls_ust12-objct = <ust12>-objct .
          ls_ust12-field = <ust12>-field .
          ls_ust12-von   = <ust12>-von .
          ls_ust12-bis   = <ust12>-bis .
          APPEND ls_ust12 TO lt_ust12_derived.
        ENDLOOP.
      ENDSELECT.
    ENDIF.
  ENDIF.
  SORT : lt_ust12_derived[], lt_ust12_parent[].
  IF lt_ust12_derived[] <> lt_ust12_parent[].
    RAISE not_identical.
  ENDIF.

ENDFUNCTION.
