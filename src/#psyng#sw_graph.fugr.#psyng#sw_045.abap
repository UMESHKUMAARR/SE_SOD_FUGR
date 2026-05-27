FUNCTION /psyng/sw_045.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_START_DATE) TYPE  DATS DEFAULT SY-DATUM
*"     REFERENCE(I_END_DATE) TYPE  DATS DEFAULT SY-DATUM
*"     REFERENCE(I_SYSID) TYPE  /PSYNG/SYSTEM DEFAULT SY-SYSID
*"     REFERENCE(I_VRSIO) TYPE  /PSYNG/SODVRSIO DEFAULT '000'
*"  TABLES
*"      ET_LOCHDR STRUCTURE  /PSYNG/SW_LOCHDR
*"      IT_ORGNR STRUCTURE  /PSYNG/RANGE_ORGNR OPTIONAL
*"  EXCEPTIONS
*"      UNSUCCESSFUL_DECOMPRESSION
*"----------------------------------------------------------------------

  DATA:
   lt_lochdr TYPE STANDARD TABLE OF /psyng/sw_lochdr WITH HEADER LINE,
   lt_lochdr2 TYPE STANDARD TABLE OF /psyng/sw_lochdr WITH HEADER LINE,
   lt_hc_hdr TYPE STANDARD TABLE OF /psyng/sw_hc_hdr WITH HEADER LINE,
   lt_compressed TYPE  TABLE OF char255.

  DATA:
   wa_lochdr TYPE /psyng/sw_lochdr,
   l_end_date LIKE i_end_date,
   lf_date LIKE i_start_date.

  l_end_date = i_end_date.
  IF l_end_date IS INITIAL.
    l_end_date = i_start_date.
  ELSE.
    CHECK i_start_date LE l_end_date.
  ENDIF.

  SELECT cdate counter data
         FROM /psyng/sw_hc_hdr
         INTO CORRESPONDING FIELDS OF TABLE lt_hc_hdr
         WHERE cdate GE i_start_date AND
               cdate LE l_end_date AND
               vrsio = i_vrsio AND
               sysid = i_sysid.

  CHECK NOT lt_hc_hdr[] IS INITIAL.

  SORT lt_hc_hdr BY cdate counter.

  LOOP AT lt_hc_hdr.
    APPEND lt_hc_hdr-data TO lt_compressed.
    lf_date = lt_hc_hdr-cdate.

    AT END OF cdate.
      CALL FUNCTION 'TABLE_DECOMPRESS'
           TABLES
                in                   = lt_compressed
                out                  = lt_lochdr2
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
      APPEND LINES OF lt_lochdr2 TO lt_lochdr.
      CLEAR lt_lochdr2.
      REFRESH: lt_lochdr2.

    ENDAT.
  ENDLOOP.
  CLEAR: lt_hc_hdr, lt_compressed, lt_lochdr2.
  FREE: lt_hc_hdr, lt_compressed, lt_lochdr2.

  IF NOT it_orgnr[] IS INITIAL.
    DELETE lt_lochdr WHERE NOT orgnr IN it_orgnr.
  ENDIF.

  SORT  lt_lochdr BY sysid vrsio erdat erzet .
  ET_LOCHDR[] = lt_lochdr[].
  free : lt_lochdr.
ENDFUNCTION.
