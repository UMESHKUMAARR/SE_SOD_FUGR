FUNCTION /PSYNG/SW_044.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(VARIFY) TYPE  CHAR1 DEFAULT 'X'
*"     REFERENCE(DELETE_FIRST) TYPE  CHAR1 DEFAULT 'X'
*"     REFERENCE(SYSID) TYPE  /PSYNG/SYSTEM DEFAULT SY-SYSID
*"     REFERENCE(VRSIO) TYPE  /PSYNG/SODVRSIO DEFAULT '000'
*"  EXPORTING
*"     REFERENCE(RECORDS_UNCOMP) TYPE  I
*"     REFERENCE(SIZE_UNCOMP) TYPE  I
*"     REFERENCE(RECORDS_COMP) TYPE  I
*"     REFERENCE(SIZE_COMP) TYPE  I
*"     REFERENCE(VARIFICATION_RESULT) TYPE  C
*"  TABLES
*"      IT_LOCCON STRUCTURE  /PSYNG/SW_LOCCON OPTIONAL
*"  EXCEPTIONS
*"      NO_DATA_TO_COMPRESS
*"      COMPRESS_FAILURE
*"      UNSUCCESSFUL_ENTRY_TO_COMPRESS
*"      UNSUCCESSFUL_DECOMPRESSION
*"      COMPRESSED_DATA_NOT_SAME
*"----------------------------------------------------------------------

  DATA:
    l_comp_size TYPE i,
    counter TYPE i,
    lf_commitcount TYPE i VALUE 5000,    "commit after this count
    lf_subrc TYPE sy-subrc.              "return code
  DATA:  l_uncomp_recordsize  TYPE /psyng/dec11,
         l_comp_recordsize  TYPE /psyng/dec11.

  DATA:
    lt_loccon TYPE STANDARD TABLE OF /psyng/sw_loccon WITH HEADER LINE,
    lt_loccon2 TYPE STANDARD TABLE OF /psyng/sw_loccon WITH HEADER LINE,
    lt_hc_con TYPE STANDARD TABLE OF /psyng/sw_hc_con WITH HEADER LINE,
    lt_hc_con2 TYPE STANDARD TABLE OF /psyng/sw_hc_con WITH HEADER LINE,
    lt_compressed TYPE  TABLE OF char255,
    l_date TYPE erdat.

  FIELD-SYMBOLS: <cmp> TYPE char255.

  CLEAR: records_uncomp, records_comp,
         l_uncomp_recordsize, l_comp_recordsize.
  IF it_loccon[] IS INITIAL.
    SELECT * FROM /psyng/sw_loccon
             INTO CORRESPONDING FIELDS OF TABLE lt_loccon
             WHERE sysid = sysid AND vrsio = vrsio.
  ELSE.
    lt_loccon[] = it_loccon[].
  ENDIF.

  FREE: it_loccon.
  SORT lt_loccon BY vrsio sysid.
  IF lt_loccon[] IS INITIAL.
    MESSAGE s398(00) WITH
    'No SOD header summary data to compress'(001) .
    RAISE no_data_to_compress.
  ELSE.
    MESSAGE s398(00) WITH
    'Starting the compression process.'(002) .
  ENDIF.

  DESCRIBE TABLE lt_loccon LINES records_uncomp.
  l_uncomp_recordsize = sy-tleng.

  CALL FUNCTION 'TABLE_COMPRESS'
       IMPORTING
            compressed_size = l_comp_size
       TABLES
            in              = lt_loccon
            out             = lt_compressed
       EXCEPTIONS
            compress_error  = 1
            OTHERS          = 2.

  IF sy-subrc <> 0.
    MESSAGE s398(00) WITH
    'Compress failure, exiting.'(003).
    RAISE compress_failure.
  ELSE.
    MESSAGE s398(00) WITH
    'Compress success. Size:'(004) l_comp_size.
  ENDIF.
* get the data from the loccon table
  READ TABLE lt_loccon INDEX 1 TRANSPORTING erdat .
  l_date = lt_loccon-erdat.
  CLEAR:lt_loccon.
  FREE: lt_loccon.

  CLEAR: lt_hc_con-counter.
  LOOP AT lt_compressed ASSIGNING <cmp>.
    lt_hc_con-mandt = sy-mandt.
    lt_hc_con-sysid = sysid.
    lt_hc_con-vrsio = vrsio.
    lt_hc_con-counter = lt_hc_con-counter + 1.
    lt_hc_con-cdate = l_date.
    lt_hc_con-data = <cmp>.
    APPEND lt_hc_con.
  ENDLOOP.
  CLEAR: lt_compressed.
  FREE: lt_compressed.

  DESCRIBE TABLE lt_hc_con LINES records_comp.
  l_comp_recordsize = sy-tleng.

  IF delete_first = 'X'.
    DELETE FROM /psyng/sw_hc_con WHERE cdate = l_date AND
                                       sysid = sysid  AND
                                       vrsio = vrsio.
    COMMIT WORK.
  ENDIF.

  CLEAR lf_subrc.
  SORT lt_hc_con.
  WHILE NOT lt_hc_con[] IS INITIAL.
    APPEND LINES OF lt_hc_con FROM 1 TO lf_commitcount TO lt_hc_con2.
    DELETE lt_hc_con FROM 1 TO lf_commitcount.
    MODIFY /psyng/sw_hc_con FROM TABLE lt_hc_con2.   "#EC CI_IMUD_NESTED
    COMMIT WORK.
    IF sy-subrc NE 0. lf_subrc = sy-subrc. ENDIF.
    REFRESH: lt_hc_con2.
  ENDWHILE.

  IF lf_subrc = 0.
    MESSAGE s398(00) WITH
    'Sucessfully entered data into compressed table'(005).
  ELSE.
    MESSAGE s398(00) WITH
    'Unsucessful data entry into compressed table format, exiting'(006).
    RAISE unsuccessful_entry_to_compress.
  ENDIF.

  size_uncomp = l_uncomp_recordsize * records_uncomp.
  size_comp = l_comp_recordsize * records_comp.

  CLEAR: lt_loccon, lt_loccon2, lt_hc_con, lt_compressed,
         l_uncomp_recordsize, l_comp_recordsize.
  FREE: lt_loccon, lt_loccon2, lt_hc_con, lt_compressed.

  varification_result = 'NOT_VARIFIED'.
  CHECK varify = 'X'.

  SELECT * FROM /psyng/sw_hc_con
           INTO CORRESPONDING FIELDS OF TABLE lt_hc_con
           WHERE cdate = l_date AND
                 SYSID = sysid  AND
                 vrsio = vrsio.

  LOOP AT lt_hc_con.
    APPEND lt_hc_con-data TO lt_compressed.
  ENDLOOP.
  FREE: lt_hc_con.

  CALL FUNCTION 'TABLE_DECOMPRESS'
       TABLES
            in                   = lt_compressed
            out                  = lt_loccon
       EXCEPTIONS
            compress_error       = 1
            table_not_compressed = 2
            OTHERS               = 3. "#EC SAST_CI_GEN_CHECK
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

  FREE: lt_compressed.

  IF sy-subrc <> 0.
    MESSAGE s398(00) WITH
    'Unsucessful decompression, exiting'(007).
    RAISE unsuccessful_decompression.
  ELSE.
    MESSAGE s398(00) WITH
    'Sucessfully decompression'(008).
  ENDIF.

  SELECT * FROM /psyng/sw_loccon
           INTO CORRESPONDING FIELDS OF TABLE lt_loccon2
           WHERE sysid = sysid AND vrsio = vrsio.
  sort : lt_loccon2, lt_loccon.
  IF lt_loccon2[] = lt_loccon[].
    MESSAGE s398(00) WITH
    'Saved compressed data same as saved actual data'(009) .
    varification_result = 'SAME'.
  ELSE.
    MESSAGE s398(00) WITH
    'Saved compressed data NOT same as saved actual data, exiting'(010).
    varification_result = 'DIFFERENT'.
    RAISE compressed_data_not_same.
  ENDIF.

  CLEAR: lt_loccon, lt_loccon2, lt_hc_con, lt_compressed,
         l_uncomp_recordsize, l_comp_recordsize.
  FREE: lt_loccon, lt_loccon2, lt_hc_con, lt_compressed,
         l_uncomp_recordsize, l_comp_recordsize.





ENDFUNCTION.
