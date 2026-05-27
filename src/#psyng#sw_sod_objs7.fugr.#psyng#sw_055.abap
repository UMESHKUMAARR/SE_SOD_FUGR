FUNCTION /psyng/sw_055.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  TABLES
*"      IT_USERS STRUCTURE  USR02
*"----------------------------------------------------------------------
*-get userbuffer settings
* The user buffer is loaded into memory for the selected users
* in table IT_USERS.
* Flag gf_usrbf3_loaded is set to X when succesfull.
* The userbuffer is now available in memory to all functions in function
* group /PSYNG/SW_SOD_OBJS7

  CLEAR  :  gf_usrbf2_loaded,
            gf_usrbf3_loaded.

  FIELD-SYMBOLS : <refuser> TYPE usrefus.

  IF NOT it_users[] IS INITIAL.
*--Select reference users
*  select bname refuser into corresponding fields of table gt_refusers
*  from usrefus for all entries in it_users
*  where bname = it_users-bname and
*  refuser <> ''.
    SORT it_users BY bname.
    SELECT bname refuser                            "#EC CI_IMUD_NESTED
    INTO CORRESPONDING FIELDS OF TABLE gt_refusers
     FROM usrefus WHERE
      refuser <> ''."#EC SAST_CI_GEN_CHECK
    LOOP AT gt_refusers ASSIGNING <refuser>.
      READ TABLE it_users WITH KEY
      bname = <refuser>-bname
      BINARY SEARCH
      TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        DELETE gt_refusers WHERE bname = <refuser>-bname.
      ENDIF.
    ENDLOOP.

*--Prevent Process from timing out.
    CALL FUNCTION '/PSYNG/BASIS_GET_WPINFO'
         EXPORTING
              i_commit_pct = 20.



    DATA : lt_usrbf3 TYPE STANDARD TABLE OF usrbf3.
    SELECT * FROM usrbf3 INTO TABLE lt_usrbf3
    FOR ALL ENTRIES IN it_users
    WHERE bname = it_users-bname. "#EC SAST_CI_GEN_CHECK
    SORT lt_usrbf3 BY bname.
    gt_usrbf3[] = lt_usrbf3[].
    FREE : lt_usrbf3[].
    gf_usrbf3_loaded = 'X'.
  ENDIF.




ENDFUNCTION.
