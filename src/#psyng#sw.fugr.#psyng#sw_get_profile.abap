FUNCTION /psyng/sw_get_profile.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_COMPOSITE_PROF) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_SINGLE_PROF) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_ASSIGNED_PROF) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(E_COUNT) TYPE  I
*"  TABLES
*"      IT_PROFILES STRUCTURE  /PSYNG/RANGE_PROFILE OPTIONAL
*"----------------------------------------------------------------------

  DATA : BEGIN OF lt_single_prof OCCURS 0,
         profn TYPE ust10s-profn,
         END OF lt_single_prof,
         lt_comp_prof LIKE TABLE OF lt_single_prof WITH HEADER LINE,
         lt_assnprof TYPE TABLE OF ust04 WITH HEADER LINE,
         l_single_numb TYPE i,
         l_comp_numb TYPE i.

  IF i_single_prof = 'X'.
    SELECT DISTINCT profn FROM ust10s INTO TABLE lt_single_prof
    WHERE profn IN it_profiles AND aktps = 'A'.

    DESCRIBE TABLE lt_single_prof LINES l_single_numb.
  ELSE.
    CLEAR l_single_numb.
  ENDIF.


  IF i_composite_prof = 'X'.
    SELECT DISTINCT profn FROM ust10c INTO TABLE lt_comp_prof
    WHERE profn IN it_profiles AND aktps = 'A'.

    DESCRIBE TABLE lt_comp_prof LINES l_comp_numb.
  ELSE.
    CLEAR l_comp_numb.
  ENDIF.

  IF i_assigned_prof = 'X'.
    APPEND LINES OF lt_comp_prof TO lt_single_prof.
    IF NOT lt_single_prof[] IS INITIAL.
      SELECT DISTINCT profile FROM ust04 INTO TABLE lt_assnprof
      FOR ALL ENTRIES IN lt_single_prof
      WHERE profile = lt_single_prof-profn.

      DESCRIBE TABLE lt_assnprof LINES e_count.
    ENDIF.
  ELSE.
    e_count = l_single_numb + l_comp_numb.
  ENDIF.



ENDFUNCTION.
