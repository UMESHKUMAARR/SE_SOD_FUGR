FUNCTION /psyng/sw_enh_read.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IF_FORCE) TYPE  FLAG OPTIONAL
*"     REFERENCE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  EXPORTING
*"     REFERENCE(EF_UPDATE) TYPE  FLAG
*"  TABLES
*"      IT_FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      ET_TCODES STRUCTURE  /PSYNG/SW_PAR_TCODE_OUTPUT OPTIONAL
*"----------------------------------------------------------------------

  DATA: l_enh_buffer_days   TYPE /psyng/param,
        l_enh_buffer_days_i TYPE i,
        l_last_update_days  TYPE i,
        lf_force            TYPE flag,
        lt_swenhbuff        TYPE STANDARD TABLE OF /psyng/swenhbuff,
        ls_swenhbuff        TYPE /psyng/swenhbuff.

*--Get buffer days defined in parameters
  se_config_param 'SW_ENH_BUFFER_DAYS' l_enh_buffer_days.
  l_enh_buffer_days_i = l_enh_buffer_days.
  lf_force = if_force.
*--Fetch last update date of buffer table for the input version
  SELECT *
    FROM /psyng/swenhbuff
    INTO ls_swenhbuff
      UP TO 1 ROWS
   WHERE vrsio EQ i_vrsio.
  ENDSELECT.
  IF sy-subrc EQ 0.
    l_last_update_days = sy-datum - ls_swenhbuff-update_date.
  ELSE.
    lf_force = 'X'.
  ENDIF.
*--If the data currently stored in the buffer
*--is older than SW_ENH_BUFFER_DAYS or there is no data stored"
*--Or IF_FORCE = X first recreate the data in the buffer
*--by calling FM /PSYNG/SW_ENH_UPDATE
  IF l_last_update_days GT l_enh_buffer_days_i
  OR lf_force EQ 'X'.
    CALL FUNCTION '/PSYNG/SW_ENH_UPDATE'
         EXPORTING
              i_vrsio    = i_vrsio
         IMPORTING
              ef_success = ef_update
         TABLES
              IT_FUNCTTRAN = IT_FUNCTTRAN.
  ENDIF.
  SORT it_functtran BY tcode.
*--Read the stored Dynamic Enhanced data and return in table ET_TCODES
  SELECT *
    FROM /psyng/swenhbuff
    INTO TABLE lt_swenhbuff
   WHERE vrsio EQ i_vrsio.

  IF sy-subrc EQ 0.
    LOOP AT lt_swenhbuff INTO ls_swenhbuff.
      IF NOT it_functtran[] IS INITIAL.
        READ TABLE it_functtran
          WITH KEY tcode = ls_swenhbuff-called_tcode
          TRANSPORTING NO FIELDS
          BINARY SEARCH.
        IF sy-subrc NE 0.
          CONTINUE.
        ENDIF.
      ENDIF.
      et_tcodes-called_tcode  = ls_swenhbuff-called_tcode.
      et_tcodes-calling_tcode = ls_swenhbuff-calling_tcode.
      APPEND et_tcodes.
    ENDLOOP.
  ENDIF.

ENDFUNCTION.
