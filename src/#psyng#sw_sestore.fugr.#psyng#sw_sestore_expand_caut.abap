FUNCTION /psyng/sw_sestore_expand_caut.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_AID) TYPE  /PSYNG/SERESID
*"     REFERENCE(I_SYS) TYPE  /PSYNG/SERES_SYSINDEX
*"     REFERENCE(I_FUNINDEX) TYPE  /PSYNG/SERES_FUNINDEX
*"     REFERENCE(I_PROFILEINDEX) TYPE  /PSYNG/SERES_PROFINDEX
*"  TABLES
*"      ET_PROFILEDETAILS STRUCTURE  /PSYNG/SERES_AUTHDETAIL
*"----------------------------------------------------------------------
  DATA :
*--max nr of profiles that will be buffered in static memory
  l_buffer_max type i value '500',
  lt_caut          TYPE TABLE OF /psyng/swrescaut WITH HEADER LINE,
  l_data           TYPE string,
  lt_records       TYPE TABLE OF string WITH HEADER LINE,
     BEGIN OF ls_authdetails_s,
       tcodeindex  TYPE string,
       objectindex TYPE string,
       fieldindex  TYPE string,
       vbaindex    TYPE string,
       authindex   TYPE string,
    END OF ls_authdetails_s,
    BEGIN OF ls_authdetails,
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
    l_buffer_lines type i,

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
    ls_profile  TYPE /psyng/swresipro,
    ls_function TYPE /psyng/swresifun,
    ls_system   TYPE /psyng/swresisys,

    lr_tcode_s  LIKE STANDARD TABLE OF ls_range ,
    lr_object_s LIKE STANDARD TABLE OF ls_range ,
    lr_field_s  LIKE STANDARD TABLE OF ls_range ,
    lr_vba_s    LIKE STANDARD TABLE OF ls_range ,
    lr_auth_s   LIKE STANDARD TABLE OF ls_range ,

    lt_idx_tcode  TYPE HASHED TABLE OF /psyng/swresitcd
                  WITH UNIQUE KEY tcodeindex WITH HEADER LINE,
    lt_idx_object TYPE HASHED TABLE OF  /psyng/swresiobj
                  WITH UNIQUE KEY objectindex WITH HEADER LINE,
    lt_idx_field  TYPE HASHED TABLE OF /psyng/swresifld
                  WITH UNIQUE KEY fieldindex WITH HEADER LINE,
    lt_idx_auth   TYPE HASHED TABLE OF /psyng/swresiaut
                  WITH UNIQUE KEY authindex WITH HEADER LINE,
    lt_idx_vba    TYPE HASHED TABLE OF /psyng/swresvba
                  WITH UNIQUE KEY vbaindex WITH HEADER LINE,
    lf_auth_in_buffer type flag.
TYPES :
    begin of typ_auth_buffer,
      aid          type /PSYNG/SERESID,
      sys          type /PSYNG/SERES_SYSINDEX,
      funindex     type /PSYNG/SERES_FUNINDEX,
      profileindex type /PSYNG/SERES_PROFINDEX,
      t_details    type standard table of /PSYNG/SERES_AUTHDETAIL
                        WITH NON-UNIQUE DEFAULT KEY,
      end of typ_auth_buffer.

*--Static Buffering tables
  STATICS :
    st_function type hashed table of /psyng/swresifun with header line
    with unique key aid funindex,
    st_profile  type hashed table of /psyng/swresipro with header line
    with unique key aid profindex,
    st_system   type hashed table of /psyng/swresisys with header line
    with unique key aid sysindex,
    st_auth     type hashed table of typ_auth_buffer with header line
    with unique key aid sys funindex profileindex.

*--Initialize the ranges
  lr_tcode-sign = lr_object-sign = lr_field-sign = lr_vba-sign =
  lr_auth-sign = 'I'.
 lr_tcode-option = lr_object-option = lr_field-option = lr_vba-option =
   lr_auth-option = 'EQ'.
*--Get the concatenated data
  read table st_auth with table key aid = i_aid
                                    sys = i_sys
                                    funindex = i_funindex
                                    profileindex = i_profileindex.
  if sy-subrc = 0.
    ET_PROFILEDETAILS[] = st_auth-t_details[].
  else.
    SELECT * FROM /psyng/swrescaut INTO TABLE lt_caut
      WHERE aid      = i_aid AND
            sys      = i_sys AND
            funindex = i_funindex AND
            profileindex = i_profileindex
            ORDER BY dataindex.
*  --Convert the concatenated data
    clear l_data.
    LOOP AT lt_caut.
      CONCATENATE l_data lt_caut-data INTO l_data.
    ENDLOOP.
    refresh : lt_records.
    SPLIT l_data AT '-' INTO TABLE lt_records.
    LOOP AT lt_records.
      SPLIT lt_records AT ',' INTO
        ls_authdetails_s-tcodeindex
        ls_authdetails_s-objectindex
        ls_authdetails_s-fieldindex
        ls_authdetails_s-vbaindex
        ls_authdetails_s-authindex.
      MOVE-CORRESPONDING ls_authdetails_s TO ls_authdetails.
      APPEND ls_authdetails TO lt_authdetails.
*  --Fill the index ranges
      lr_tcode-low  = ls_authdetails-tcodeindex.
      lr_object-low = ls_authdetails-objectindex.
      lr_field-low  = ls_authdetails-fieldindex.
      lr_vba-low    = ls_authdetails-vbaindex.
      lr_auth-low   = ls_authdetails-authindex.
      INSERT TABLE : lr_tcode, lr_object, lr_field, lr_vba, lr_auth.
    ENDLOOP.
*  --Move ranges to standard table
    lr_tcode_s[] = lr_tcode[]. FREE lr_tcode[].
    lr_field_s[] = lr_field[]. FREE lr_field[].
    lr_object_s[] = lr_object[]. FREE lr_object[].
    lr_auth_s[] = lr_auth[]. FREE lr_auth[].
    lr_vba_s[] = lr_vba[]. FREE lr_vba[].

*  --Load function and profile
    read table st_function into ls_function
      with table key aid = i_aid funindex = i_funindex.
    if sy-subrc <> 0.
      SELECT SINGLE * FROM /psyng/swresifun INTO ls_function
      WHERE aid = i_aid AND funindex = i_funindex .
      insert ls_function into table st_function.
    endif.
    read table st_profile  into ls_profile
      with table key aid       = i_aid
                     profindex = i_profileindex.
    if sy-subrc <> 0.
      SELECT SINGLE * FROM /psyng/swresipro INTO ls_profile
      WHERE aid = i_aid AND profindex = i_profileindex .
      insert ls_profile into table st_profile.
    endif.
    read table st_system  into ls_system
      with table key aid       = i_aid
                     sysindex  = i_sys.
    if sy-subrc <> 0.
      SELECT SINGLE * FROM /psyng/swresisys INTO ls_system
      WHERE aid = i_aid AND sysindex = i_sys .
      insert ls_system into table st_system.
    endif.


*  --Load the index data
    SELECT * FROM /psyng/swresvba INTO TABLE lt_idx_vba WHERE
      vbaindex IN lr_vba_s.
    SELECT * FROM /psyng/swresitcd INTO TABLE lt_idx_tcode WHERE
      aid = i_aid AND
      tcodeindex IN lr_tcode_s.
    SELECT * FROM /psyng/swresiobj INTO TABLE lt_idx_object WHERE
      aid = i_aid AND
      objectindex IN lr_object_s.
    SELECT * FROM /psyng/swresiaut INTO TABLE lt_idx_auth WHERE
      aid = i_aid AND
      authindex IN lr_auth_s.
    SELECT * FROM /psyng/swresifld INTO TABLE lt_idx_field WHERE
      aid = i_aid AND
      fieldindex IN lr_field_s.
*  -- create the actual expanded table
    et_profiledetails-funid    = ls_function-funid.
    et_profiledetails-profname = ls_profile-profname.
    et_profiledetails-sysid    = ls_system-sysid.
    LOOP AT lt_authdetails.
*  --VON-BIS-ABB
      READ TABLE lt_idx_vba WITH TABLE KEY
        vbaindex = lt_authdetails-vbaindex.
      IF sy-subrc = 0.
        et_profiledetails-von = lt_idx_vba-von.
        et_profiledetails-bis = lt_idx_vba-bis.
        et_profiledetails-abb = lt_idx_vba-abb.
      ELSE.
        clear : et_profiledetails-von,
                et_profiledetails-bis,
                et_profiledetails-abb.
      ENDIF.
*  --AUTH
      READ TABLE lt_idx_auth WITH TABLE KEY
        authindex = lt_authdetails-authindex.
      IF sy-subrc = 0.
        et_profiledetails-auth = lt_idx_auth-auth.
      ELSE.
        clear : et_profiledetails-auth.
      ENDIF.
*  --TCODE
      READ TABLE lt_idx_tcode WITH TABLE KEY
        tcodeindex = lt_authdetails-tcodeindex.
      IF sy-subrc = 0.
        et_profiledetails-tcode = lt_idx_tcode-tcode.
      ELSE.
        clear : et_profiledetails-tcode.
      ENDIF.
*  --OBJECT
      READ TABLE lt_idx_object WITH TABLE KEY
        objectindex = lt_authdetails-objectindex.
      IF sy-subrc = 0.
        et_profiledetails-object = lt_idx_object-object.
      ELSE.
        clear : et_profiledetails-object.
      ENDIF.
*  --FIELD
      READ TABLE lt_idx_field WITH TABLE KEY
        fieldindex = lt_authdetails-fieldindex.
      IF sy-subrc = 0.
        et_profiledetails-field = lt_idx_field-field.
      ELSE.
        clear : et_profiledetails-field.
      ENDIF.
      append et_profiledetails.
    ENDLOOP.
    describe table st_auth lines l_buffer_lines.
    if l_buffer_lines >= l_buffer_max.
*--Our memory buffer for auths is full, delete a random one.
*  for a hashed table, we don't know which record is at index 1
*  nor do we care
      loop at st_auth.
        delete table st_auth
          with table key aid = st_auth-aid
                         sys = st_auth-sys
                         funindex = st_auth-funindex
                         profileindex = st_auth-profileindex.
        exit.
      endloop.
    endif.
    st_auth-t_details[] = et_profiledetails[].
    st_auth-aid          = i_aid.
    st_auth-sys          = i_sys.
    st_auth-funindex     = i_funindex.
    st_auth-profileindex = i_profileindex.
    insert table st_auth.
  endif.

ENDFUNCTION.
