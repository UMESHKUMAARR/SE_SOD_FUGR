FUNCTION /PSYNG/SE_WORD_WRAP.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_TEXT) TYPE  STRING
*"     REFERENCE(IV_LINE_LENGTH) TYPE  I DEFAULT 132
*"  TABLES
*"      ET_LINES TYPE  /PSYNG/SW_LINE_TT OPTIONAL
*"----------------------------------------------------------------------
 DATA: lt_words   TYPE TABLE OF string,
        lv_line    TYPE string,
        lv_word    TYPE string,
        l_tabix TYPE i.

  DATA: l_line TYPE i,
        l_word TYPE i,
        l_count TYPE i.
  " Ensure line length is valid
  IF iv_line_length < 10.
    RAISE too_short_line_length.
  ENDIF.

  " Step 1: Split text into words based on space
  SPLIT iv_text AT space INTO TABLE lt_words.

  " Step 2: Reconstruct lines of max IV_LINE_LENGTH characters
  LOOP AT lt_words INTO lv_word.
    l_tabix = sy-tabix.
    CLEAr: l_line,
           l_word,
           l_count.
    l_line = STRLEN( lv_line ).
    l_word = STRLEN( lv_word ).
    l_count = l_line + l_word + 1.
*    IF STRLEN( lv_line ) + STRLEN( lv_word ) + 1 <= iv_line_length.
    if l_count <= iv_line_length.
      IF l_tabix = 1.
      " Add word to current line with space
      CONCATENATE lv_line lv_word INTO lv_line.
      else.
      " Add word to current line with space
      CONCATENATE lv_line lv_word INTO lv_line SEPARATED BY space.
      ENDIF.
    ELSE.
      " Store current line and start a new one
      APPEND lv_line TO et_lines.
      lv_line = lv_word.
    ENDIF.
  ENDLOOP.

  " Add the last remaining line
  IF NOT lv_line IS INITIAL.
    APPEND lv_line TO et_lines.
  ENDIF.




ENDFUNCTION.
