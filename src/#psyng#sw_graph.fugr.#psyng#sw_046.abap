FUNCTION /PSYNG/SW_046.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_START_DATE) TYPE  DATS DEFAULT SY-DATUM
*"     REFERENCE(I_END_DATE) TYPE  DATS DEFAULT SY-DATUM
*"     REFERENCE(I_SYSID) TYPE  /PSYNG/SYSTEM DEFAULT SY-SYSID
*"     REFERENCE(I_VRSIO) TYPE  /PSYNG/SODVRSIO DEFAULT '000'
*"  TABLES
*"      ET_LOCCON STRUCTURE  /PSYNG/SW_LOCCON
*"      IT_ORGNR STRUCTURE  /PSYNG/RANGE_ORGNR OPTIONAL
*"      IT_CONID STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"  EXCEPTIONS
*"      UNSUCCESSFUL_DECOMPRESSION
*"----------------------------------------------------------------------

  DATA:
   lt_loccon TYPE STANDARD TABLE OF /psyng/sw_loccon WITH HEADER LINE,
   lt_loccon2 TYPE STANDARD TABLE OF /psyng/sw_loccon WITH HEADER LINE,
   lt_hc_con TYPE STANDARD TABLE OF /psyng/sw_hc_con WITH HEADER LINE,
   lt_compressed TYPE  TABLE OF char255.

  DATA:
   wa_loccon TYPE /psyng/sw_loccon,
   l_end_date LIKE i_end_date,
   lf_date LIKE i_start_date.

  l_end_date = i_end_date.
  IF l_end_date IS INITIAL.
    l_end_date = i_start_date.
  ELSE.
    CHECK i_start_date LE l_end_date.
  ENDIF.

  SELECT cdate counter data
         FROM /psyng/sw_hc_con
         INTO CORRESPONDING FIELDS OF TABLE lt_hc_con
         WHERE cdate GE i_start_date AND
               cdate LE l_end_date
               and vrsio = i_vrsio AND
               sysid = i_sysid.

  CHECK NOT lt_hc_con[] IS INITIAL.

  SORT lt_hc_con BY cdate counter.

  LOOP AT lt_hc_con.
    APPEND lt_hc_con-data TO lt_compressed.
    lf_date = lt_hc_con-cdate.

    AT END OF cdate.
      CALL FUNCTION 'TABLE_DECOMPRESS'
           TABLES
                in                   = lt_compressed
                out                  = lt_loccon2
           EXCEPTIONS
                compress_error       = 1
                table_not_compressed = 2
                OTHERS               = 3.

      IF sy-subrc <> 0.
        MESSAGE s398(00) WITH
        'Unsucessful decompression, exiting'(011) .
        RAISE unsuccessful_decompression.
      ELSE.
        MESSAGE s398(00) WITH
        'Sucessfully decompression'(012).
      ENDIF.

      REFRESH: lt_compressed.
      APPEND LINES OF lt_loccon2 TO lt_loccon.
      CLEAR lt_loccon2.
      REFRESH: lt_loccon2.

    ENDAT.
  ENDLOOP.
  CLEAR: lt_hc_con, lt_compressed, lt_loccon2.
  FREE: lt_hc_con, lt_compressed, lt_loccon2.

  IF NOT it_orgnr[] IS INITIAL.
    DELETE lt_loccon WHERE NOT orgnr IN it_orgnr  .
  ENDIF.
  IF NOT it_conid[] IS INITIAL.
    DELETE lt_loccon WHERE NOT conid IN it_conid  .
  ENDIF.

  SORT  lt_loccon BY sysid vrsio erdat  .
  ET_loccon[] = lt_loccon[].
  free : lt_loccon.
ENDFUNCTION.
