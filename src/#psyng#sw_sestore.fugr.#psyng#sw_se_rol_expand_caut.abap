FUNCTION /psyng/sw_se_rol_expand_caut.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_AID) TYPE  /PSYNG/SERRSID
*"     REFERENCE(I_FUNINDEX) TYPE  /PSYNG/SERES_FUNINDEX
*"     REFERENCE(I_ROLEINDEX) TYPE  /PSYNG/SERES_ROLEINDEX
*"  TABLES
*"      ET_ROLEDETAILS STRUCTURE  /PSYNG/SERRS_AUTHDETAIL
*"----------------------------------------------------------------------
  DATA :
*--max nr of roles that will be buffered in static memory
  l_buffer_max     TYPE i VALUE '500',
  lt_caut          TYPE TABLE OF /psyng/swrrscaut WITH HEADER LINE,
  lt_chdrole       TYPE TABLE OF /psyng/swrrsrchd,
  ls_chdrole       TYPE /psyng/swrrsrchd,
  l_data           TYPE string,
  lt_records       TYPE TABLE OF string WITH HEADER LINE,
     BEGIN OF ls_authdetails_s,
       childindex  TYPE string,
       tcodeindex  TYPE string,
       objectindex TYPE string,
       fieldindex  TYPE string,
       vbaindex    TYPE string,
       authindex   TYPE string,
    END OF ls_authdetails_s,
    BEGIN OF ls_authdetails,
       childindex  TYPE i,
       tcodeindex  TYPE i,
       objectindex TYPE i,
       fieldindex  TYPE i,
       vbaindex    TYPE i,
       authindex   TYPE i,
    END OF ls_authdetails,
    BEGIN OF ls_range,
      sign         TYPE tvarv_sign,
      option       TYPE tvarv_opti,
      low          TYPE i,
      high         TYPE i,
    END OF ls_range,
    lt_authdetails LIKE TABLE OF ls_authdetails WITH HEADER LINE,
    l_buffer_lines TYPE i,

    lr_childrole  LIKE SORTED TABLE OF ls_range WITH UNIQUE KEY low
    WITH HEADER LINE,
    lr_tcode  LIKE SORTED TABLE OF ls_range WITH UNIQUE KEY low
    WITH HEADER LINE,
    lr_object LIKE SORTED TABLE OF ls_range WITH UNIQUE KEY low
    WITH HEADER LINE,
    lr_field  LIKE SORTED TABLE OF ls_range WITH UNIQUE KEY low
    WITH HEADER LINE,
    lr_vba    LIKE SORTED TABLE OF ls_range WITH UNIQUE KEY low
    WITH HEADER LINE,
    lr_auth   LIKE SORTED TABLE OF ls_range WITH UNIQUE KEY low
    WITH HEADER LINE,
*    ls_role     TYPE /psyng/swresipro,
    ls_function TYPE /psyng/swrrsifun,
*    ls_system   TYPE /psyng/swresisys,
    lr_childrole_s  LIKE STANDARD TABLE OF ls_range ,
    lr_tcode_s  LIKE STANDARD TABLE OF ls_range ,
    lr_object_s LIKE STANDARD TABLE OF ls_range ,
    lr_field_s  LIKE STANDARD TABLE OF ls_range ,
    lr_vba_s    LIKE STANDARD TABLE OF ls_range ,
    lr_auth_s   LIKE STANDARD TABLE OF ls_range ,

    lt_idx_childrole  TYPE HASHED TABLE OF /psyng/swrrsichd
                  WITH UNIQUE KEY childindex WITH HEADER LINE,
    lt_idx_tcode  TYPE HASHED TABLE OF /psyng/swrrsitcd
                  WITH UNIQUE KEY tcodeindex WITH HEADER LINE,
    lt_idx_object TYPE HASHED TABLE OF  /psyng/swrrsiobj
                  WITH UNIQUE KEY objectindex WITH HEADER LINE,
    lt_idx_field  TYPE HASHED TABLE OF /psyng/swrrsifld
                  WITH UNIQUE KEY fieldindex WITH HEADER LINE,
    lt_idx_auth   TYPE HASHED TABLE OF /psyng/swrrsiaut
                  WITH UNIQUE KEY authindex WITH HEADER LINE,
    lt_idx_vba    TYPE HASHED TABLE OF /psyng/swresvba
                  WITH UNIQUE KEY vbaindex WITH HEADER LINE,
    lf_auth_in_buffer TYPE flag.
  TYPES :
      BEGIN OF typ_auth_buffer,
        aid          TYPE /psyng/seresid,
        funindex     TYPE /psyng/seres_funindex,
        roleindex    TYPE /psyng/seres_roleindex,
        t_details    TYPE STANDARD TABLE OF /psyng/serrs_authdetail
                          WITH NON-UNIQUE DEFAULT KEY,
        END OF typ_auth_buffer.

*--Static Buffering tables
  STATICS :
    st_function TYPE HASHED TABLE OF /psyng/swrrsifun WITH HEADER LINE
    WITH UNIQUE KEY aid funindex,
    st_auth     TYPE HASHED TABLE OF typ_auth_buffer WITH HEADER LINE
    WITH UNIQUE KEY aid funindex roleindex.

*--Initialize the ranges
  lr_childrole-sign = lr_tcode-sign = lr_object-sign = lr_field-sign
  = lr_vba-sign = lr_auth-sign = 'I'.
  lr_childrole-option = lr_tcode-option = lr_object-option
  = lr_field-option = lr_vba-option =  lr_auth-option = 'EQ'.
*--Get the concatenated data
  READ TABLE st_auth WITH TABLE KEY aid = i_aid
                                    funindex = i_funindex
                                    roleindex = i_roleindex.
  IF sy-subrc = 0.
    et_roledetails[] = st_auth-t_details[].
  ELSE.
    SELECT * FROM /psyng/swrrscaut INTO TABLE lt_caut
      WHERE aid      = i_aid AND
            funindex = i_funindex AND
            roleindex = i_roleindex
            ORDER BY dataindex.
    SELECT * FROM /psyng/swrrsrchd INTO TABLE lt_chdrole
      WHERE aid      = i_aid AND
            roleindex = i_roleindex.
    IF sy-subrc EQ 0.
      SORT lt_chdrole BY authindex.
    ENDIF.
*  --Convert the concatenated data
    CLEAR l_data.
    LOOP AT lt_caut.
      CONCATENATE l_data lt_caut-data INTO l_data.
    ENDLOOP.
    REFRESH : lt_records.
    SPLIT l_data AT '-' INTO TABLE lt_records.
    LOOP AT lt_records.
      SPLIT lt_records AT ',' INTO
        ls_authdetails_s-tcodeindex
        ls_authdetails_s-objectindex
        ls_authdetails_s-fieldindex
        ls_authdetails_s-vbaindex
        ls_authdetails_s-authindex.
      READ TABLE lt_chdrole INTO ls_chdrole
      WITH KEY authindex = ls_authdetails_s-authindex
      BINARY SEARCH.
      IF sy-subrc EQ 0.
        ls_authdetails_s-childindex = ls_chdrole-childindex.
      ENDIF.
      MOVE-CORRESPONDING ls_authdetails_s TO ls_authdetails.
      APPEND ls_authdetails TO lt_authdetails.
*  --Fill the index ranges
      lr_childrole-low = ls_authdetails_s-childindex.
      lr_tcode-low  = ls_authdetails-tcodeindex.
      lr_object-low = ls_authdetails-objectindex.
      lr_field-low  = ls_authdetails-fieldindex.
      lr_vba-low    = ls_authdetails-vbaindex.
      lr_auth-low   = ls_authdetails-authindex.
      INSERT TABLE : lr_childrole, lr_tcode, lr_object,
      lr_field, lr_vba, lr_auth.
    ENDLOOP.
*  --Move ranges to standard table
    lr_childrole_s[] = lr_childrole[]. FREE lr_childrole[].
    lr_tcode_s[] = lr_tcode[]. FREE lr_tcode[].
    lr_field_s[] = lr_field[]. FREE lr_field[].
    lr_object_s[] = lr_object[]. FREE lr_object[].
    lr_auth_s[] = lr_auth[]. FREE lr_auth[].
    lr_vba_s[] = lr_vba[]. FREE lr_vba[].

*  --Load function and profile
    READ TABLE st_function INTO ls_function
      WITH TABLE KEY aid = i_aid funindex = i_funindex.
    IF sy-subrc <> 0.
      SELECT SINGLE * FROM /psyng/swrrsifun INTO ls_function
      WHERE aid = i_aid AND funindex = i_funindex .
      INSERT ls_function INTO TABLE st_function.
    ENDIF.
*  --Load the index data
    SELECT * FROM /psyng/swrrsichd INTO TABLE lt_idx_childrole WHERE
      aid = i_aid AND
      childindex IN lr_childrole_s.
    SELECT * FROM /psyng/swresvba INTO TABLE lt_idx_vba WHERE
      vbaindex IN lr_vba_s.
    SELECT * FROM /psyng/swrrsitcd INTO TABLE lt_idx_tcode WHERE
      aid = i_aid AND
      tcodeindex IN lr_tcode_s.
    SELECT * FROM /psyng/swrrsiobj INTO TABLE lt_idx_object WHERE
      aid = i_aid AND
      objectindex IN lr_object_s.
    SELECT * FROM /psyng/swrrsiaut INTO TABLE lt_idx_auth WHERE
      aid = i_aid AND
      authindex IN lr_auth_s.
    SELECT * FROM /psyng/swrrsifld INTO TABLE lt_idx_field WHERE
      aid = i_aid AND
      fieldindex IN lr_field_s.
*  -- create the actual expanded table
    et_roledetails-funid    = ls_function-funid.
    LOOP AT lt_authdetails.
*  --Child Role
      READ TABLE lt_idx_childrole WITH TABLE KEY
        childindex = lt_authdetails-childindex.
      IF sy-subrc = 0.
        et_roledetails-childrole = lt_idx_childrole-agr_name.
      ELSE.
        CLEAR : et_roledetails-childrole.
      ENDIF.
*  --VON-BIS-ABB
      READ TABLE lt_idx_vba WITH TABLE KEY
        vbaindex = lt_authdetails-vbaindex.
      IF sy-subrc = 0.
        et_roledetails-von = lt_idx_vba-von.
        et_roledetails-bis = lt_idx_vba-bis.
        et_roledetails-abb = lt_idx_vba-abb.
      ELSE.
        CLEAR : et_roledetails-von,
                et_roledetails-bis,
                et_roledetails-abb.
      ENDIF.
*  --AUTH
      READ TABLE lt_idx_auth WITH TABLE KEY
        authindex = lt_authdetails-authindex.
      IF sy-subrc = 0.
        et_roledetails-auth = lt_idx_auth-auth.
      ELSE.
        CLEAR : et_roledetails-auth.
      ENDIF.
*  --TCODE
      READ TABLE lt_idx_tcode WITH TABLE KEY
        tcodeindex = lt_authdetails-tcodeindex.
      IF sy-subrc = 0.
        et_roledetails-tcode = lt_idx_tcode-tcode.
      ELSE.
        CLEAR : et_roledetails-tcode.
      ENDIF.
*  --OBJECT
      READ TABLE lt_idx_object WITH TABLE KEY
        objectindex = lt_authdetails-objectindex.
      IF sy-subrc = 0.
        et_roledetails-object = lt_idx_object-object.
      ELSE.
        CLEAR : et_roledetails-object.
      ENDIF.
*  --FIELD
      READ TABLE lt_idx_field WITH TABLE KEY
        fieldindex = lt_authdetails-fieldindex.
      IF sy-subrc = 0.
        et_roledetails-field = lt_idx_field-field.
      ELSE.
        CLEAR : et_roledetails-field.
      ENDIF.
      APPEND et_roledetails.
    ENDLOOP.
    DESCRIBE TABLE st_auth LINES l_buffer_lines.
    IF l_buffer_lines >= l_buffer_max.
*--Our memory buffer for auths is full, delete a random one.
*  for a hashed table, we don't know which record is at index 1
*  nor do we care
      LOOP AT st_auth.
        DELETE TABLE st_auth
          WITH TABLE KEY aid = st_auth-aid
                         funindex = st_auth-funindex
                         roleindex = st_auth-roleindex.
        EXIT.
      ENDLOOP.
    ENDIF.
    st_auth-t_details[] = et_roledetails[].
    st_auth-aid          = i_aid.
    st_auth-funindex     = i_funindex.
    st_auth-roleindex = i_roleindex.
    INSERT TABLE st_auth.
  ENDIF.

ENDFUNCTION.
