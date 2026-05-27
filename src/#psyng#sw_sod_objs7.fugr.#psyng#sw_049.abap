*----------------------------------------------------------------------*
* Function Module :  /PSYNG/SW_049                                     *
* AUTHOR  : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
FUNCTION /PSYNG/SW_049.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(USER_NAME) LIKE  USR02-BNAME OPTIONAL
*"  TABLES
*"      VALUES STRUCTURE  USVALUES OPTIONAL
*"      IT_OBJECTS STRUCTURE  /PSYNG/XUOBJECT
*"----------------------------------------------------------------------
  TYPES: BEGIN OF typ_prof ,
         profile TYPE ust10c-profn,
         END OF typ_prof.

  DATA : lt_refus TYPE TABLE OF usrefus,
         lt_users TYPE TABLE OF usrefus,
         ls_user TYPE usrefus,
         lt_userbuffer TYPE TABLE OF usrbf2,
         lt_profiles TYPE TABLE OF typ_prof,
         ls_prof TYPE typ_prof,
         lt_profiles_tmp TYPE TABLE OF typ_prof,
         lt_subprofs TYPE TABLE OF ust10c,
         ls_subprof TYPE ust10c,
         lt_auths TYPE sorted TABLE OF ust10s with non-unique key objct,
         ls_buf TYPE usrbf3,
         ls_value type USVALUES,
         l_idx like sy-tabix.
  FIELD-SYMBOLS : <usref> TYPE usrefus,
                  <auth>   TYPE ust10s,
                  <subp> TYPE ust10c,
                  <prof> TYPE typ_prof,
                  <buf>  TYPE usrbf2,
                  <ust12> type ust12.
  sort it_objects.
* get auths from user buffer
  DATA : lf_buf_contains_data TYPE flag.
*--check if buffer contains data
  IF gf_usrbf3_loaded = 'X'. "user buffer is filled for all users
    READ TABLE gt_usrbf3 WITH TABLE KEY bname = user_name
    TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      lf_buf_contains_data = 'X'.
    ELSE.
      CLEAR lf_buf_contains_data.
    ENDIF.
  ELSE.
    SELECT SINGLE * FROM  usrbf3 INTO ls_buf
    WHERE  bname  = user_name. "#EC SAST_CI_GEN_CHECK
    IF sy-dbcnt > 0.
      lf_buf_contains_data = 'X'.
    ELSE.
      CLEAR lf_buf_contains_data.
    ENDIF.
  ENDIF.

  IF lf_buf_contains_data = 'X'.
    if gf_usrbf2_loaded <> 'X'.
*--user buffer details not loaded
      IF it_objects[] IS INITIAL.
        SELECT * FROM  usrbf2               "#EC CI_IMUD_NESTED
             APPENDING TABLE lt_userbuffer
             WHERE bname  = user_name.
      ELSE.
        SELECT * FROM  usrbf2
             APPENDING TABLE lt_userbuffer
             FOR ALL ENTRIES IN it_objects
             WHERE objct = it_objects-object
             AND   bname  = user_name  .
      ENDIF.
      IF NOT lt_userbuffer[] IS INITIAL.
        SELECT objct auth field von bis
               APPENDING TABLE values
               FROM   ust12
               FOR ALL ENTRIES IN lt_userbuffer
               WHERE
               objct  = lt_userbuffer-objct
               AND    auth   = lt_userbuffer-auth
               AND    aktps  = 'A'.
      ENDIF.

    else.
*--user buffer details loaded
      loop at gt_usrbf2 assigning <buf>
        where bname = user_name.
          append <buf> to lt_userbuffer.
      endloop.
      IF NOT lt_userbuffer[] IS INITIAL.
        clear sy-tabix.
        sort lt_userbuffer by objct auth.
        loop at lt_userbuffer assigning <buf>.
          ls_value-objct =   <buf>-objct.
          ls_value-auth  =   <buf>-auth.
          loop at gt_ust12_buffer assigning <ust12>
          from l_idx
          where    objct = <buf>-objct AND
                   auth  = <buf>-auth.
             l_idx = sy-tabix.
             ls_value-field = <ust12>-field.
             ls_value-von   = <ust12>-von.
             ls_value-bis   = <ust12>-bis.
             append ls_value to values.
          endloop.
        endloop.
      ENDIF.

    endif.
*   get values from ust12
  ELSE.
*--no buffer data
    SELECT profile  FROM  ust04
        INTO TABLE lt_profiles
            WHERE bname = user_name.
*   get values from ust12
    IF NOT lt_profiles[] IS INITIAL.
*     get subprofiles
      DATA : ust10_tabix LIKE sy-tabix.
      LOOP AT lt_profiles ASSIGNING <prof>.
        READ TABLE gt_ust10c WITH KEY profn = <prof>-profile
        BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          ust10_tabix = sy-tabix.
          LOOP AT gt_ust10c FROM ust10_tabix ASSIGNING <subp>
          WHERE profn = <prof>-profile.
*            ls_subprof-profile = <subp>-subprof.
            APPEND <subp> TO lt_subprofs.
          ENDLOOP.
        ELSE.
          SELECT profn subprof FROM  ust10c
          APPENDING CORRESPONDING FIELDS OF
                    TABLE lt_subprofs
*                FOR ALL ENTRIES IN lt_profiles
                      WHERE
                        profn  = <prof>-profile
                     AND    aktps  = 'A'.
*--   buffer subprofile -> profile link
          APPEND LINES OF lt_subprofs TO gt_ust10c.
        ENDIF.
      ENDLOOP.

      LOOP AT lt_subprofs ASSIGNING <subp>.
        ls_prof-profile = <subp>-subprof.
        APPEND ls_prof TO lt_profiles.
      ENDLOOP.

      LOOP AT lt_profiles ASSIGNING <prof>.
        READ TABLE gt_ust10s WITH KEY profn = <prof>-profile
        BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          LOOP AT gt_ust10s FROM sy-tabix ASSIGNING <auth> WHERE
            profn = <prof>-profile.
*            APPEND <auth> TO lt_auths.
            insert <auth> into table lt_auths.
          ENDLOOP.
        ELSE.
          data : lt_auths_tmp type table of ust10s.
          refresh : lt_auths_tmp[].
          SELECT profn auth objct FROM ust10s into
          CORRESPONDING FIELDS OF
          TABLE lt_auths_tmp
                 WHERE
                 profn  = <prof>-profile
*--DHORIONS 20101222 - Added AKTPS restriction, Case 1672

                 AND
                 AKTPS = 'A'.
*--buffer ust10s data
          INSERT LINES OF lt_auths_tmp INTO table gt_ust10s.
*          append lines of lt_auths_tmp to lt_auths.
          insert lines of lt_auths_tmp into table lt_auths.
        ENDIF.
      ENDLOOP.
      LOOP AT lt_auths ASSIGNING <auth>.
        READ TABLE it_objects WITH KEY table_line = <auth>-objct
        BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
           DELETE lt_auths WHERE objct = <auth>-objct.
        ENDIF.
      ENDLOOP.
      IF NOT lt_auths[] IS INITIAL.
        SELECT objct auth field von bis
               APPENDING TABLE values
               FROM   ust12
               FOR ALL ENTRIES IN lt_auths
               WHERE
               objct  = lt_auths-objct
               AND    auth   = lt_auths-auth
               AND    aktps  = 'A'.
      ENDIF.
    ENDIF.

  ENDIF.

  SORT gt_ust10c BY profn subprof.
  DELETE ADJACENT DUPLICATES FROM gt_ust10c.
*  SORT gt_ust10s.
*  DELETE ADJACENT DUPLICATES FROM gt_ust10s.

   data : lt_values_refuser type table of usvalues,
         ls_refuser type usrefus.
*--Get authorizations for reference users
    read table gt_refusers into ls_refuser
    with table key bname = USER_NAME.
    IF sy-subrc = 0.
      CALL FUNCTION '/PSYNG/SW_049'
           EXPORTING
                user_name  = ls_refuser-refuser
           TABLES
                values     = lt_values_refuser
                it_objects = it_objects.
      append lines of lt_values_refuser to values.
      sort values.
      delete adjacent duplicates from values comparing all fields.
    endif.


ENDFUNCTION.
