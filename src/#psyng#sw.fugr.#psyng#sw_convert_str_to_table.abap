FUNCTION /psyng/sw_convert_str_to_table.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_STRING) TYPE  STRING
*"     REFERENCE(I_TABLINE_LENGTH) TYPE  I OPTIONAL
*"  TABLES
*"      ET_TABLE TYPE  TABLE
*"----------------------------------------------------------------------

  DATA:   lv_length      TYPE i,
          lv_offset      TYPE i,
          lv_full_lines  TYPE i,
          lv_last_length TYPE i.

*--get string length
  lv_length = strlen( i_string ).
*--get number of full lines
  lv_full_lines  = lv_length DIV i_tabline_length.
*--get length of last line
  lv_last_length = lv_length MOD i_tabline_length.

*--append full lines to output table
  DO lv_full_lines TIMES.
    et_table = i_string+lv_offset(i_tabline_length).
    APPEND et_table.
    lv_offset = lv_offset + i_tabline_length.
  ENDDO.

*--append last line to output table
  et_table = i_string+lv_offset(lv_last_length).
  APPEND et_table.

ENDFUNCTION.
