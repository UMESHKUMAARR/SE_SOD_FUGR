FUNCTION /psyng/sw_compare_ranges.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(AUTH_FROM) OPTIONAL
*"     VALUE(AUTH_TO) OPTIONAL
*"     VALUE(SOD_FROM) OPTIONAL
*"     VALUE(SOD_TO) OPTIONAL
*"     VALUE(I_BUFFER_SIZE) TYPE  I DEFAULT 0
*"  EXPORTING
*"     VALUE(MATCH) TYPE  FLAG
*"  TABLES
*"      IT_COMPARE STRUCTURE  /PSYNG/AUTH_COMPARE OPTIONAL
*"----------------------------------------------------------------------
*2020/12/01 - FM to replace /PSYNG/SW_021 to improve performance for very large analysis
*             for example for instances where 100s of millions of calls to the
*             compare form are done
*  constants :
*    c_max_buffer_size type i value 20000.
  TYPES :
    BEGIN OF typ_buffer,
      auth_from TYPE  /psyng/value,
      auth_to   TYPE  /psyng/value,
      sod_from  TYPE  /psyng/value,
      sod_to    TYPE  /psyng/value,
      match     TYPE  char1,
    END OF typ_buffer.
  FIELD-SYMBOLS :
    <pair> TYPE /psyng/auth_compare,
    <buff> TYPE typ_buffer.
  DATA :
    ls_buffer TYPE typ_buffer,
    l_mod     TYPE i,
    ls_config TYPE /psyng/swconfig.
  STATICS :
    st_buffer          TYPE HASHED TABLE OF typ_buffer WITH UNIQUE KEY auth_from auth_to sod_from sod_to,
    st_buffer_size     TYPE i,
    st_max_buffer_size TYPE i,
    st_log_last        TYPE i,
    st_config_checked  TYPE flag.
  IF st_config_checked IS INITIAL.
    se_config_param 'AUTHCOMP_BUFFERSIZE' ls_config-value.
    IF ls_config-value CO '0123456789 '.
      CONDENSE ls_config-value.
      MOVE ls_config-value TO st_max_buffer_size.
      IF st_max_buffer_size > 0.
        MESSAGE s002(/psyng/sw) WITH 'Authorization Comparison Buffer Active. Size' st_max_buffer_size ''.
      ENDIF.
    ENDIF.
    st_config_checked = 'X'.
  ENDIF.

*--I_BUFFER_SIZE will be ignored, and replaced by config parameter AUTHCOMP_BUFFERSIZE,
*  unless I_BUFFER_SIZE = 0, then no buffering will be used in this call
  IF i_buffer_size > 0.
    i_buffer_size = st_max_buffer_size.
  ENDIF.

  DEFINE buffer_add.
    if st_buffer_size < I_BUFFER_size.
      ls_buffer-auth_from = &1.
      ls_buffer-auth_to   = &2.
      ls_buffer-sod_from  = &3.
      ls_buffer-sod_to    = &4.
      ls_buffer-match     = &5.
      insert ls_buffer into table st_buffer.
      if sy-subrc = 0.
        add 1 to st_buffer_size.
      endif.
    endif.
  END-OF-DEFINITION.
  DEFINE buffer_check_loop.
    if I_BUFFER_size > 0.
      read table st_buffer with table key
        auth_from = &1
        auth_to   = &2
        sod_from  = &3
        sod_to    = &4
        assigning <buff>.
      if sy-subrc = 0.
        &5 = <buff>-match.
        continue."move on to the next check
      endif.
    endif.
  END-OF-DEFINITION.
  DEFINE buffer_check.
    if I_BUFFER_size > 0.
      read table st_buffer with table key
        auth_from = &1
        auth_to   = &2
        sod_from  = &3
        sod_to    = &4
        assigning <buff>.
      if sy-subrc = 0.
        &5 = <buff>-match.
      endif.
    endif.
  END-OF-DEFINITION.
  IF it_compare IS SUPPLIED AND
     sod_from   IS INITIAL  AND
     auth_from  IS INITIAL.
*"----------------------------------------------------------------------
*" Compare a table of sets of ranges
*"----------------------------------------------------------------------
    LOOP AT it_compare ASSIGNING <pair>.
      buffer_check_loop <pair>-auth_from <pair>-auth_to
                        <pair>-sod_from <pair>-sod_to
                        <pair>-match.
      PERFORM compare USING    <pair>-auth_from <pair>-auth_to
                               <pair>-sod_from <pair>-sod_to
                      CHANGING <pair>-match.
      buffer_add <pair>-auth_from <pair>-auth_to
                 <pair>-sod_from <pair>-sod_to
                 <pair>-match.
    ENDLOOP.
  ELSE.
*"----------------------------------------------------------------------
*" Compare a single set of ranges
*"----------------------------------------------------------------------
    buffer_check auth_from auth_to
                 sod_from  sod_to
                 match .
    PERFORM compare USING    auth_from auth_to
                             sod_from  sod_to
                    CHANGING match.
    buffer_add auth_from auth_to
               sod_from  sod_to
               match.
  ENDIF.
ENDFUNCTION.
