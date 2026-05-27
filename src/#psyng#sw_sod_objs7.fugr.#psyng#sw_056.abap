FUNCTION /psyng/sw_056.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  TABLES
*"      IT_USERS STRUCTURE  USR02 OPTIONAL
*"      IT_OBJECTS STRUCTURE  /PSYNG/XUOBJECT OPTIONAL
*"----------------------------------------------------------------------
  FIELD-SYMBOLS : <buf> TYPE usrbf2,
                  <obj> TYPE /psyng/xuobject.
  CHECK NOT it_users[] IS INITIAL.
  DATA :
         lt_usrbf2   TYPE TABLE OF usrbf2,
         lt_usrbf2_s TYPE sorted table  OF usrbf2
                      with unique key bname  objct auth ,
         lt_rusrbf2_s TYPE sorted table  OF usrbf2
                      with unique key bname objct auth
                      with header line.
  DATA : BEGIN OF ls_range_object,
          sign TYPE tvarv_sign,
          option TYPE tvarv_opti,
          low TYPE xuobject,
          high TYPE xuobject,
         END OF ls_range_object,
         lt_range_object LIKE TABLE OF ls_range_object.
  free: gt_usrbf2[].

    SELECT  * FROM  usrbf2          "#EC CI_IMUD_NESTED
         INTO TABLE lt_usrbf2_s
         FOR ALL ENTRIES IN it_users
         WHERE bname   = it_users-bname.
*--reference users
    if not gt_refusers[] IS INITIAL.
      SELECT  * FROM  usrbf2          "#EC CI_IMUD_NESTED
           APPENDING TABLE lt_rusrbf2_s
           FOR ALL ENTRIES IN gt_refusers
           WHERE bname   = gt_refusers-refuser.
      loop at lt_rusrbf2_s.
        insert lt_rusrbf2_s into table lt_usrbf2_s.
      endloop.
    endif.
*--Prevent Process from timing out.
  CALL FUNCTION '/PSYNG/BASIS_GET_WPINFO'
       EXPORTING
            i_commit_pct = 10.
  gt_usrbf2[] = lt_usrbf2_s[].
  FREE : lt_usrbf2,lt_usrbf2_s.
  IF NOT it_objects[] IS INITIAL.
*--create a range table for deleting objects
    SORT it_objects BY object.
    ls_range_object-sign = 'I'.
    ls_range_object-option = 'EQ'.
    LOOP AT it_objects ASSIGNING <obj>.
      ls_range_object-low = <obj>-object.
      APPEND ls_range_object TO lt_range_object.
    ENDLOOP.
    DELETE gt_usrbf2 WHERE NOT objct  IN lt_range_object.
    FREE : lt_range_object.
*--Prevent Process from timing out.
    CALL FUNCTION '/PSYNG/BASIS_GET_WPINFO'
         EXPORTING
              i_commit_pct = 20.

*--get UST12 data for buffered users
    if not  gt_usrbf2[] is initial.
      lt_usrbf2[] = gt_usrbf2[].
      SORT lt_usrbf2 BY objct auth.
      DELETE ADJACENT DUPLICATES FROM lt_usrbf2 COMPARING objct auth.
      SELECT *
             INTO TABLE gt_ust12_buffer
             FROM   ust12
             FOR ALL ENTRIES IN lt_usrbf2
             WHERE
             objct  = lt_usrbf2-objct
             AND    auth   = lt_usrbf2-auth
             AND    aktps  = 'A'.
    endif.
  ENDIF.
  gf_usrbf2_loaded = 'X'.
ENDFUNCTION.
