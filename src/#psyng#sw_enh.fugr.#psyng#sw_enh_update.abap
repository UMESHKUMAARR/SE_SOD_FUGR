FUNCTION /psyng/sw_enh_update.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  EXPORTING
*"     REFERENCE(EF_SUCCESS) TYPE  FLAG
*"  TABLES
*"      IT_FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"----------------------------------------------------------------------

  DATA: lt_functtran TYPE TABLE OF /psyng/functtran,
        ls_functtran TYPE /psyng/functtran,
        lt_tcodes    TYPE TABLE OF /psyng/sw_par_tcode_output,
        ls_tcodes    TYPE /psyng/sw_par_tcode_output,
        lt_swenhbuff TYPE TABLE OF /psyng/swenhbuff,
        ls_swenhbuff TYPE /psyng/swenhbuff,
        lt_swaudhdr  TYPE TABLE OF /psyng/swaudhdr,
        ls_swaudhdr  TYPE /psyng/swaudhdr,
        lt_swaudc    TYPE TABLE OF /psyng/swaudc2,
        ls_swaudc    TYPE /psyng/swaudc2.

*--Read the SOD Matrix, and get all transactions that are in it

*--Om 14/09/2022
*---check if sod matrix doesn't exist
  data ls_sodvrs type /psyng/swsodvers.
  SELECT *
      FROM /psyng/swsodvers
      INTO ls_sodvrs
        UP TO 1 ROWS
     WHERE vrsio EQ i_vrsio.
  ENDSELECT.

  if sy-subrc <> 0.
    lt_functtran[] = it_functtran[].
    else.
  CALL FUNCTION '/PSYNG/SW_028'
       EXPORTING
            i_vrsio      = i_vrsio
            i_enhance    = ' '
       TABLES
            et_functtran = lt_functtran.

*--Get critical authorizations
  CALL FUNCTION '/PSYNG/SW_CR_GET_ALL_CRIAUTHS'
       EXPORTING
            vrsio      = i_vrsio
            if_details = 'X'
       TABLES
            swaudhdr   = lt_swaudhdr
            swaudc2    = lt_swaudc
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             NO_AUTHORIZATION  = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
*--Add to transactions
  LOOP AT lt_swaudhdr INTO ls_swaudhdr.
    ls_functtran-functionid = ls_swaudhdr-swaudid.
    ls_functtran-vrsio      = i_vrsio.
    ls_functtran-tcode      = ls_swaudhdr-tcode.
    APPEND ls_functtran TO lt_functtran.
  ENDLOOP.

  LOOP AT lt_swaudc INTO ls_swaudc
    WHERE object = 'S_TCODE'.
    IF ls_swaudc-val_from CS '*'.
      CONTINUE.
    ENDIF.
    ls_functtran-functionid = ls_swaudc-swaudid.
    ls_functtran-vrsio      = i_vrsio.
    ls_functtran-tcode      = ls_swaudc-val_from.
    APPEND ls_functtran TO lt_functtran.
  ENDLOOP.
 endif.
*------om Change end
*--Call FM /PSYNG/SW_029 with the list of transactions
  CALL FUNCTION '/PSYNG/SW_029'
       TABLES
            functtran = lt_functtran
            tcodes    = lt_tcodes.
  FREE lt_functtran.
*--Store the results in database table /PSYNG/SWENHBUFF
  ls_swenhbuff-vrsio       = i_vrsio.
  ls_swenhbuff-update_date = sy-datum.
  LOOP AT lt_tcodes INTO ls_tcodes.
    ls_swenhbuff-called_tcode  = ls_tcodes-called_tcode.
    ls_swenhbuff-calling_tcode = ls_tcodes-calling_tcode.
    APPEND ls_swenhbuff TO lt_swenhbuff.
  ENDLOOP.
  FREE lt_tcodes.

*---15/09/2022
DELETE FROM /psyng/swenhbuff WHERE vrsio EQ i_vrsio.

  IF NOT lt_swenhbuff IS INITIAL.
    MODIFY /psyng/swenhbuff FROM TABLE lt_swenhbuff.
    IF sy-subrc EQ 0.
      ef_success = 'X'.
      MESSAGE s002(/psyng/sw) WITH
      'Updated dynamic enhancements buffer.'(001).
      COMMIT WORK.
*   & & & &

    ENDIF.
  ENDIF.

ENDFUNCTION.
