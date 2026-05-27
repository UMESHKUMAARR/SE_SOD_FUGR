FUNCTION /psyng/sw_sod_update_stat.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(OBJECTCOUNT_FM) TYPE  I
*"     VALUE(CONCOUNT_FM) TYPE  I
*"     VALUE(BYOBJECT) TYPE  CHAR10
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_SOD_UPDATE_STAT'.
*  S_RFC AUTHORITY CHECK
* BOC BNAYAK CVA scan fix DT:05-05-2026
*  AUTHORITY-CHECK OBJECT 'S_RFC'
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
* EOC BNAYAK CVA scan fix DT:05-05-2026
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  DATA: icount(100) TYPE n,
        d_ncount(100) TYPE n,
        n_ncount(100) TYPE n,
        wa_sod_st TYPE /psyng/sw_sod_st.

  icount = objectcount_fm * concount_fm .

  IF byobject = 'USER'.
    SELECT SINGLE sodcount FROM /psyng/sw_sod_st    "#EC CI_SEL_NESTED
        INTO d_ncount
           WHERE byobject = 'USER'.
    IF sy-subrc <> 0.
      wa_sod_st-byobject = 'USER'.
      wa_sod_st-sodcount = icount.
      INSERT INTO /psyng/sw_sod_st VALUES wa_sod_st ."#EC CI_IMUD_NESTED
    ELSE.
      n_ncount = d_ncount + icount.
      UPDATE /psyng/sw_sod_st                  "#EC CI_IMUD_NESTED
        SET sodcount = n_ncount
             WHERE byobject = 'USER'.
    ENDIF.
  ELSEIF byobject = 'ROLE'.
    SELECT SINGLE sodcount FROM /psyng/sw_sod_st     "#EC CI_SEL_NESTED
        INTO d_ncount
           WHERE byobject = 'ROLE'.
    IF sy-subrc <> 0.
      wa_sod_st-byobject = 'ROLE'.
      wa_sod_st-sodcount = icount.
      INSERT INTO /psyng/sw_sod_st VALUES wa_sod_st ."#EC CI_IMUD_NESTED
    ELSE.
      n_ncount = d_ncount + icount.
      UPDATE /psyng/sw_sod_st                "#EC CI_IMUD_NESTED
          SET sodcount = n_ncount
             WHERE byobject = 'ROLE'.
    ENDIF.
  ENDIF.

  COMMIT WORK.
ENDFUNCTION.
