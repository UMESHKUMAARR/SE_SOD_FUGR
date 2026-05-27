FUNCTION /psyng/sw_029.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_RECURSION_LEVEL) TYPE  INT1 OPTIONAL
*"  TABLES
*"      FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN
*"      TCODES STRUCTURE  /PSYNG/SW_PAR_TCODE_OUTPUT
*"----------------------------------------------------------------------

  FIELD-SYMBOLS :
         <functtran>     TYPE             /psyng/functtran,
         <excl>          TYPE             /psyng/sw_excltx,
         <tcodes> TYPE /psyng/sw_par_tcode_output.
  DATA : ls_tcode        TYPE             tstc,
         lt_tcode        TYPE   TABLE OF  tstc,
         lt_result_1     TYPE   TABLE OF  /psyng/sw_par_tcode_output,
         ls_taskname_sw_026(8)  VALUE     'SW_026',
         ls_taskname_sw_027(8)  VALUE     'SW_027',
         lt_excl_global         TYPE   TABLE OF  /psyng/sw_excltx,
         lt_excl_local          TYPE   TABLE OF  /psyng/sw_exlltx.
  DATA : BEGIN OF lt_excl_range OCCURS 0,
         sign           TYPE              tvarv_sign,
         option         TYPE              tvarv_opti,
         low            TYPE              tcode,
         high           TYPE              tcode,
         END OF lt_excl_range,
         ls_excl_range  LIKE              lt_excl_range,
         ls_config      TYPE /psyng/swconfig,
         l_userexit_fm  LIKE rs38l-name.

  DATA: l_tcode_idx  TYPE i,
       lt_functtran TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
       et_tcodes TYPE TABLE OF /psyng/sw_par_tcode_output,
       lt_tcodes_temp type table of /PSYNG/SW_PAR_TCODE_OUTPUT.

*----------------------------------------------------------------------
* Read Global exclusion filters from table /psyng/sw_excltx
* for calling transactions
*----------------------------------------------------------------------
  SELECT * FROM /psyng/sw_excltx                     "#EC CI_SEL_NESTED
       INTO TABLE lt_excl_global.                    "#EC CI_NOWHERE
*----------------------------------------------------------------------
* Read Local exclusion filters from table /psyng/sw_exlltx
* for calling transactions. This filter is only applied when
* configuration setting SW_ENH_LOCAL_FILT = Y
*----------------------------------------------------------------------
  se_config_param 'SW_ENH_LOCAL_FILT' l_userexit_fm.
  IF sy-subrc = 0 AND ls_config-value = 'Y'.
    SELECT * FROM /psyng/sw_exlltx                   "#EC CI_SEL_NESTED
           INTO TABLE lt_excl_local.                 "#EC CI_NOWHERE
  ENDIF.
*----------------------------------------------------------------------
* Execute user exit for exclusion filters
*----------------------------------------------------------------------
  se_config_param 'SW_ENH_CALLING_EXIT' l_userexit_fm.
  IF NOT l_userexit_fm IS INITIAL.
    CALL FUNCTION 'FUNCTION_EXISTS'
         EXPORTING
              funcname           = l_userexit_fm
         EXCEPTIONS
              function_not_exist = 1
              OTHERS             = 2.
    IF sy-subrc = 0.
      CALL FUNCTION l_userexit_fm
           TABLES
                i_exclude_calling_local  = lt_excl_local
                i_exclude_calling_global = lt_excl_global.
      MESSAGE s144(/psyng/sw) WITH l_userexit_fm.
    ELSE.
      MESSAGE s143(/psyng/sw) WITH l_userexit_fm.
    ENDIF.
  ENDIF.
  LOOP AT lt_excl_global ASSIGNING <excl>.
    ls_excl_range-sign   = <excl>-sign.
    ls_excl_range-option = <excl>-type.
    ls_excl_range-low    = <excl>-low.
    ls_excl_range-high   = <excl>-high.
    APPEND ls_excl_range TO lt_excl_range.
  ENDLOOP.
  LOOP AT lt_excl_local ASSIGNING <excl>.
    ls_excl_range-sign   = <excl>-sign.
    ls_excl_range-option = <excl>-type.
    ls_excl_range-low    = <excl>-low.
    ls_excl_range-high   = <excl>-high.
    APPEND ls_excl_range TO lt_excl_range.
  ENDLOOP.

*----------------------------------------------------------------------
*Convert input data to TSTC format
*----------------------------------------------------------------------
  LOOP AT functtran ASSIGNING <functtran>
*Sf Case 2151 : Performance issues
    WHERE tcode NP /psyng/sw_cl_constants=>placeholder_tcode_prefix.
    ls_tcode-tcode = <functtran>-tcode.
    COLLECT ls_tcode INTO lt_tcode.
  ENDLOOP.
  SORT lt_tcode.
  DELETE ADJACENT DUPLICATES FROM lt_tcode.
*----------------------------------------------------------------------
*Get information about tcodes which call other tcodes in parallel
*----------------------------------------------------------------------
  FREE : gt_tasks_sw_029[].
* Analyze table CROSS
  APPEND ls_taskname_sw_027 TO gt_tasks_sw_029.
  CALL FUNCTION '/PSYNG/SW_027'
    STARTING NEW TASK ls_taskname_sw_027
    DESTINATION IN GROUP DEFAULT
    PERFORMING sw_029_receive_sw_027 ON END OF TASK
      TABLES
        i_tcodes         = lt_tcode
        o_tcodes         = gt_result_sw_027
        it_tcode_filters =  lt_excl_range
    EXCEPTIONS
        RESOURCE_FAILURE      = 1
        communication_failure = 2
        system_failure        = 3.
  IF sy-subrc <> 0.
    gf_sw_027_failed = 'X'.
    DELETE gt_tasks_sw_029 WHERE taskname = ls_taskname_sw_027.

  ENDIF.
  MESSAGE s141(/psyng/sw) WITH 'CROSS'.
* Analyze table TSTCP
  APPEND ls_taskname_sw_026 TO gt_tasks_sw_029.
  CALL FUNCTION '/PSYNG/SW_026'
    STARTING NEW TASK ls_taskname_sw_026
    DESTINATION IN GROUP DEFAULT
    PERFORMING sw_029_receive_sw_026 ON END OF TASK
      TABLES
        i_tcodes         = lt_tcode
        o_tcodes         = gt_result_sw_026
        it_tcode_filters =  lt_excl_range
   EXCEPTIONS
        RESOURCE_FAILURE      = 1
        communication_failure = 2
        system_failure        = 3.
  IF sy-subrc <> 0.
    gf_sw_026_failed = 'X'.
    DELETE gt_tasks_sw_029 WHERE taskname = ls_taskname_sw_026.
  ENDIF.
  MESSAGE s141(/psyng/sw) WITH 'TSTCP'.
* Wait until both tasks are finished
  WAIT UNTIL gt_tasks_sw_029[] IS INITIAL.



  IF gf_sw_027_failed = 'X'.
*  call fm in synchronous mode
    CALL FUNCTION '/PSYNG/SW_027'
         TABLES
              i_tcodes         = lt_tcode
              o_tcodes         = gt_result_sw_027
              it_tcode_filters = lt_excl_range.
    CLEAR gf_sw_027_failed.
  ENDIF.
  IF gf_sw_026_failed = 'X'.
* call fm in synchronous mode
    CALL FUNCTION '/PSYNG/SW_026'
         TABLES
              i_tcodes         = lt_tcode
              o_tcodes         = gt_result_sw_026
              it_tcode_filters =  lt_excl_range.
    CLEAR gf_sw_026_failed.
  ENDIF.


  APPEND LINES OF gt_result_sw_026 TO tcodes.
  APPEND LINES OF gt_result_sw_027 TO tcodes.
*Release memory
  FREE : gt_result_sw_026[], gt_result_sw_027[], gt_tasks_sw_029[].
  SORT tcodes BY called_tcode calling_tcode.
*Cleanup table entries
  DELETE ADJACENT DUPLICATES FROM tcodes.
  DELETE  tcodes WHERE called_tcode = '?'."delete dyn. called tcodes
*----------------------------------------------------------------------
* Apply exclusion filters
*----------------------------------------------------------------------
  IF NOT lt_excl_range[] IS INITIAL.
    DELETE tcodes WHERE NOT calling_tcode  IN lt_excl_range.
  ENDIF.
  FREE : lt_excl_range[], lt_excl_local[], lt_excl_global[].

*  SORT tcodes BY called_tcode calling_tcode.
*Release memory
  FREE : lt_excl_local[],lt_excl_global[], lt_tcode[],lt_excl_range[].

*----------------------------------------------------------------------
* HSHARMA : 30.08.2018 If new tcodes are identified which where not the
*           part of the function originaly then look for their
*           next level enhancement, up to 3 levels deep
*----------------------------------------------------------------------
  IF i_recursion_level < 2.
    ADD 1 TO i_recursion_level.
*  -- some formalities : match the enhanced tcode with functions
    LOOP AT functtran.
      READ TABLE tcodes WITH KEY called_tcode = functtran-tcode
                 TRANSPORTING NO FIELDS.
      CHECK sy-subrc = 0.
      l_tcode_idx = sy-tabix.

      LOOP AT tcodes FROM l_tcode_idx ASSIGNING <tcodes>
              WHERE called_tcode = functtran-tcode.
        lt_functtran       = functtran.
        lt_functtran-tcode = <tcodes>-calling_tcode.
        lt_functtran-vrsio = functtran-vrsio.
        APPEND lt_functtran.
      ENDLOOP.
    ENDLOOP.
*  -- Enhance the enhanced tocdes
    IF NOT lt_functtran[] IS INITIAL.
      SORT lt_functtran BY functionid tcode.
      DELETE ADJACENT DUPLICATES FROM lt_functtran
                      COMPARING functionid tcode.
      SORT tcodes BY calling_tcode.
*   Get list of called tcodes
      CALL FUNCTION '/PSYNG/SW_029'
           EXPORTING
                i_recursion_level = i_recursion_level
           TABLES
                functtran         = lt_functtran
                tcodes            = et_tcodes.
      LOOP AT et_tcodes ASSIGNING <tcodes>.
       READ TABLE tcodes WITH KEY calling_tcode = <tcodes>-called_tcode
       BINARY SEARCH.
        IF sy-subrc = 0.
          <tcodes>-called_tcode = tcodes-called_tcode.
*          APPEND <tcodes> TO tcodes.
          append <tcodes> to lt_tcodes_temp.
        ENDIF.
      ENDLOOP.
      append lines of lt_tcodes_temp to tcodes.
      free : lt_tcodes_temp.

    ELSE.
      EXIT.
    ENDIF.
  ENDIF.
  SORT tcodes BY called_tcode calling_tcode.
  DELETE ADJACENT DUPLICATES FROM tcodes COMPARING called_tcode
  calling_tcode.
ENDFUNCTION.
