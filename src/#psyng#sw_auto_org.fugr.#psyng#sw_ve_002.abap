FUNCTION /psyng/sw_ve_002.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_VAREL_VRSIO) TYPE  /PSYNG/VE_VRSIO OPTIONAL
*"     VALUE(I_SYSID) TYPE  /PSYNG/RFCDEST OPTIONAL
*"     VALUE(IF_LOCAL_CONFIG) TYPE  FLAG DEFAULT ''
*"     VALUE(IF_IGNORE_SOD_MATRIX) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_INCLUDE_INACTIVE) TYPE  FLAG OPTIONAL
*"  TABLES
*"      IT_FAOBJ2 STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      IT_VAREL STRUCTURE  /PSYNG/SW_VAREL OPTIONAL
*"      ET_VALUES STRUCTURE  /PSYNG/SWCFGVE OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
  CONSTANTS: lc_fname TYPE rs38l_fnam
          VALUE '/PSYNG/SW_VE_002'.
*  S_RFC AUTHORITY CHECK
* BOC BNAYAK CVA scan fix DT:05-05-2026
*  AUTHORITY-CHECK OBJECT 'S_RFC'
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
* EOC BNAYAK CVA scan fix DT:05-05-2026
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  DATA :  lr_tabl     TYPE REF TO data.
  FIELD-SYMBOLS: <lt_temp> TYPE ANY TABLE.

  DATA : ls_authx TYPE authx,
         ls_dd01v  TYPE dd01v,
         l_objname TYPE ddobjname,
         lt_dfies    TYPE TABLE OF dfies WITH HEADER LINE,
         lf_valid_table TYPE flag,
         lt_sets     LIKE TABLE OF gt_varel WITH HEADER LINE,
         lt_tables   LIKE TABLE OF gt_varel WITH HEADER LINE,

         lt_ranges      TYPE rsds_trange,
         lt_where       TYPE rsds_twhere,
         lt_selopt      TYPE rsds_selopt_t,
         ls_range       TYPE rsds_range,
         ls_selopt      TYPE rsdsselopt,
       ls_where       TYPE rsds_where,
       ls_range_line  TYPE rsds_frange,
       lr_table       TYPE      REF TO data,
       lr_table_inact TYPE      REF TO data,
       lr_rec         TYPE      REF TO data,
         BEGIN OF lt_join OCCURS 0,
         table     TYPE tabname,
         field     TYPE fieldname,
         jointable TYPE tabname,
         joinfield TYPE fieldname,
       END OF lt_join,
       l_numtables TYPE i,
       l_maintable TYPE tabname,
       lf_inact  TYPE flag,
       l_classn  TYPE seoclskey,
       l_str     TYPE string.
  .
  DATA :
  lt_elements LIKE TABLE OF gt_varel WITH HEADER LINE.
  FIELD-SYMBOLS : <table>          TYPE STANDARD TABLE,
                  <table_inactive> TYPE STANDARD TABLE,
                  <field>          TYPE any,
                  <record>         TYPE any,
                  <rec>            TYPE any,
                  <varel>          TYPE /psyng/sw_varel    .

*--Macro to escape quotes on all SAP Releases
  STATICS : lf_dyn_class_checked TYPE flag,
            lf_dyn_class_exists TYPE flag.
  DEFINE escape_quotes.
    if lf_dyn_class_checked is initial.
      l_classn = 'CL_ABAP_DYN_PRG'.
      CALL FUNCTION 'SEO_CLASS_GET'
        EXPORTING
          clskey                             = l_classn
       EXCEPTIONS
         NOT_EXISTING                       = 1
         DELETED                            = 2
         IS_INTERFACE                       = 3
         MODEL_ONLY                         = 4
         OTHERS                             = 5. "#EC SAST_CI_GEN_CHECK
*BOC:HBHALLA (06/12/24)
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN 1.
                MESSAGE s002(/psyng/sw)
             WITH 'Not Existing'.
             WHEN 2.
                MESSAGE s002(/psyng/sw)
             WITH 'Deleted'.
             WHEN 3.
                MESSAGE s002(/psyng/sw)
             WITH 'IS Interface'.
             WHEN 4.
                MESSAGE s002(/psyng/sw) WITH 'Model Only'.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (06/12/24)
      IF sy-subrc = 0.
        lf_dyn_class_exists = 'X'.
      ENDIF.
      lf_dyn_class_checked = 'X'.
    endif.
    if lf_dyn_class_exists = 'X'.
*     &1 = cl_abap_dyn_prg=>escape_quotes( &1 ).
      CALL METHOD ('CL_ABAP_DYN_PRG')=>('ESCAPE_QUOTES')
       exporting val = &1
       receiving out = l_str.                "#EC PATHLOCK_CI_DYN_ACCES
      &1 = l_str.
    else.
*--Escape quotes backward compatible with older versions of sap
      l_str = &1.
*     CALL FUNCTION 'RS_ESCAPE_QUOTES'
*       CHANGING
*         value                     = l_str
*      EXCEPTIONS
*        PARAMETER_TOO_SHORT       = 1
*        OTHERS                    = 2.
    DO.
    replace all occurrences of substring '''' in l_str with ''''''.
    IF sy-subrc NE 0. EXIT. ENDIF.
   ENDDO.

*     replace all occurrences of substring '''' in l_str with ''''''.
      IF sy-subrc <> 0.
*      escaping failed
      else.
        &1 = l_str.
      ENDIF.

    endif.
  END-OF-DEFINITION.


  CONCATENATE sy-sysid sy-mandt INTO et_values-sysid.
*--Check if SOD Matrix contains ANY variable elements
  LOOP AT it_faobj2 WHERE val_from CP '/PSYNG/$*'.
    EXIT.
  ENDLOOP.
  CHECK sy-subrc = 0 OR if_ignore_sod_matrix = 'X'.
  IF if_local_config  = 'X'.
*--Read the local variable elements
    SELECT * FROM /psyng/sw_varel                       "#EC CI_NOFIRST
    INTO CORRESPONDING FIELDS OF TABLE gt_varel
    WHERE
     varel_vrsio = i_varel_vrsio.
    SORT gt_varel BY var_element valueset element
                     joinflag tabname field val_from val_to.


  ELSE.
*--The variable elements were passed from the server
    gt_varel[] = it_varel[].
  ENDIF.
*--Sanitize all values that will be used in dynamic SQL, so no sql injection can happen
  LOOP AT gt_varel ASSIGNING <varel>.
*      <varel>-val_from = cl_abap_dyn_prg=>escape_quotes( <varel>-val_from ).
*      <varel>-val_to   = cl_abap_dyn_prg=>escape_quotes( <varel>-val_to ).
*      <varel>-field    = cl_abap_dyn_prg=>escape_quotes( <varel>-field ).
    escape_quotes : <varel>-val_from , <varel>-val_to, <varel>-field .
  ENDLOOP.
*--Remove any values from the definition that are not used
*  in this SOD Matrix
  IF NOT if_ignore_sod_matrix = 'X'.
    SORT it_faobj2 BY field val_from.
    LOOP AT gt_varel.
      READ TABLE it_faobj2 WITH KEY
        field    = gt_varel-element
        val_from = gt_varel-var_element
        BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        APPEND gt_varel TO lt_elements.
      ENDIF.
    ENDLOOP.
    gt_varel[] = lt_elements[].
  ELSE.
    lt_elements[] = gt_varel[].
  ENDIF.
  SORT lt_elements BY var_element.
  DELETE ADJACENT DUPLICATES FROM lt_elements COMPARING var_element.

*--Get the check table
  LOOP AT lt_elements.
*--Validate the table
    PERFORM get_dfies
                TABLES
                   lt_dfies
                USING
                   lt_elements-tabname.

    IF lt_dfies[] IS INITIAL.
      CLEAR lf_valid_table.
    ELSE.
      lf_valid_table = 'X'.
      lt_sets[] = gt_varel[].
      DELETE lt_sets WHERE var_element <> lt_elements-var_element.
      SORT lt_sets BY var_element valueset.
      DELETE ADJACENT DUPLICATES FROM lt_sets COMPARING
      var_element valueset.
      lt_tables[] = gt_varel[].
      DELETE lt_tables WHERE var_element <> lt_elements-var_element.
      DELETE lt_tables WHERE outputflag  <> 'X'.

      SORT lt_tables BY tabname.
      DELETE ADJACENT DUPLICATES FROM lt_tables COMPARING tabname.


    ENDIF.
    IF lf_valid_table IS INITIAL.
      log et_return 'E' 'INVALIDTABLE'
                    'No valid table found for '
                    lt_elements-var_element
                    lt_elements-tabname ''.
    ELSE.
*--Create all ranges to be able to do dynamic selects

      SORT gt_varel BY var_element valueset tabname field.
      LOOP AT lt_sets.
        REFRESH : lt_ranges, lt_where.
        REFRESH : lt_join,lt_selopt.
        LOOP AT gt_varel WHERE var_element = lt_elements-var_element AND
                                         valueset    = lt_sets-valueset.
          ls_range-tablename      = gt_varel-tabname.
          IF gt_varel-joinflag <> 'X'.
*--Handle where clause
            ls_range_line-fieldname = gt_varel-field.
            ls_selopt-sign   = gt_varel-v_sign.
            ls_selopt-option = gt_varel-v_option.
            ls_selopt-low    = gt_varel-val_from.
            ls_selopt-high   = gt_varel-val_to.
            APPEND ls_selopt TO lt_selopt.
          ELSE.
*--Handle Join
            lt_join-table = gt_varel-tabname.
            lt_join-field = gt_varel-field.
            SPLIT gt_varel-val_from AT '-' INTO
            lt_join-jointable lt_join-joinfield.
            APPEND lt_join.
*--other direction
            lt_join-jointable = gt_varel-tabname.
            lt_join-joinfield = gt_varel-field.
            SPLIT gt_varel-val_from AT '-' INTO
            lt_join-table lt_join-field.
            APPEND lt_join.
          ENDIF.
          AT END OF field.
            ls_range_line-selopt_t[] = lt_selopt[].
            REFRESH : lt_selopt[].
            IF NOT ls_range_line-selopt_t[] IS INITIAL.
              APPEND ls_range_line TO ls_range-frange_t.
            ENDIF.
          ENDAT.

          AT END OF tabname.
            APPEND ls_range TO lt_ranges.
            CLEAR ls_range.
          ENDAT.
        ENDLOOP.
*--Convert the ranges to select clauses
        CALL FUNCTION 'FREE_SELECTIONS_RANGE_2_WHERE'
             EXPORTING
                  field_ranges  = lt_ranges[]
             IMPORTING
                  where_clauses = lt_where[].
*--Identify the table that is set as an output table.
*  There should be exactly 1,
*  and it should contain the authorization field
        CLEAR :  l_numtables,l_maintable.
        LOOP AT lt_tables.
          l_maintable = lt_tables-tabname.
          PERFORM get_dfies
               TABLES
                  lt_dfies
               USING
                  l_maintable.
          READ TABLE lt_dfies WITH KEY
          fieldname = lt_elements-element
          TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            ADD 1 TO l_numtables.
          ENDIF.
        ENDLOOP.

        IF l_numtables <> 1.
          MESSAGE s002(/psyng/sw) WITH
          'Exactly 1 table should be defined as output table'
          'and it needs to contain the Authorization Field'
          lt_elements-var_element.
        ELSE.
*--We don't want the main table at the right side of a join
          DELETE lt_join WHERE jointable = l_maintable.

          CREATE DATA lr_rec TYPE  (lt_elements-tabname).
          ASSIGN lr_rec->* TO <record>.
*--Creating dynamic tables is  not possible in older SAP versions,
*  use a workaround. Keep in mind this means there's a limit to how many
*  dynamic tables can be generated
*  (how many different tables can be in the configuration)

          PERFORM create_table
          USING    l_maintable 'ACTIVE'
          CHANGING lr_table.
          IF if_include_inactive = 'X'.
            PERFORM create_table
            USING    l_maintable 'INACTIVE'
            CHANGING
            lr_table_inact.
          ENDIF.
          IF NOT lr_table IS INITIAL.
*--In newer sap versions above form can be replaced by the next line
*      CREATE DATA lr_table TYPE TABLE OF  (ls_authx-checktable).
            ASSIGN lr_table->* TO <table>.
            ASSIGN lr_table_inact->* TO <table_inactive>.
            CLEAR ls_where.
            READ TABLE lt_where INTO ls_where
                 WITH KEY tablename = l_maintable.
*--Get data that fits the criteria ( dynamic sql fields are already sanitized/escaped, (search for "*--Sanitize")

*BOC UMITTAL CLEAN CORE FIXES 11/03/2026
            CALL METHOD /psyng/sw_dynamic_select=>select_into_table
              EXPORTING
                i_tabname      =     l_maintable
                it_where_tab   =     ls_where-where_tab
              IMPORTING
                e_data         = lr_tabl.
            IF lr_tabl IS BOUND.
              ASSIGN lr_tabl->* TO <lt_temp>.
              IF <lt_temp> IS ASSIGNED.
                <table> = <lt_temp>.
              ENDIF.
            ENDIF.
*            SELECT * FROM (l_maintable)
*                     INTO CORRESPONDING FIELDS OF TABLE  <table>
*                    WHERE (ls_where-where_tab)."#EC SAST_CI_GEN_CHECK
*EOC UMITTAL CLEAN CORE FIXES 11/03/2026

*--Get all data
            IF if_include_inactive = 'X'.
*BOC UMITTAL CLEAN CORE FIXES 11/03/2026
              CALL METHOD /psyng/sw_dynamic_select=>select_into_table
                            EXPORTING
                              i_tabname      = l_maintable
                            IMPORTING
                              e_data         = lr_tabl.
              IF lr_tabl IS BOUND.
                ASSIGN lr_tabl->* TO <lt_temp>.
                IF <lt_temp> IS ASSIGNED.
                  <table_inactive> = <lt_temp>.
                ENDIF.
              ENDIF.
*              SELECT * FROM (l_maintable)
*                       INTO CORRESPONDING FIELDS OF TABLE
*                       <table_inactive>.
*EOC UMITTAL CLEAN CORE FIXES 11/03/2026
            ENDIF.
            DATA :  lf_match TYPE flag.
            LOOP AT <table> ASSIGNING <record>.
              PERFORM check_join_table
               TABLES
                 lt_join
               USING
                 <record>
                 l_maintable
               CHANGING
                  lf_match
                  lt_ranges.
              IF lf_match <> 'X'.
                DELETE <table>.
              ENDIF.
            ENDLOOP.
          ELSE.
            MESSAGE s002(/psyng/sw) WITH
            'Table can not be generated'
            l_maintable
            lt_elements-var_element.
          ENDIF.
        ENDIF.

**--return the results for the analyzed value set.
        IF <table> IS ASSIGNED.
          et_values-var_element = lt_elements-var_element.
          LOOP AT <table> ASSIGNING <record>.
            ASSIGN COMPONENT lt_sets-element OF STRUCTURE <record>
                   TO <field>.
            IF sy-subrc = 0.
*                WRITE : / <field>.
              et_values-value  = <field>.
              et_values-active = 'X'.
              APPEND et_values.
            ENDIF.
          ENDLOOP.
*--Add the inactive records
          IF if_include_inactive = 'X'.
            LOOP AT <table_inactive> ASSIGNING <record>.
              lf_inact = 'X'.
              LOOP AT <table> ASSIGNING <rec>.
                IF  <rec> = <record>.
                  CLEAR lf_inact.
                  EXIT.
                ENDIF.
              ENDLOOP.
              IF lf_inact = 'X'.
                ASSIGN COMPONENT lt_sets-element OF STRUCTURE <record>
                     TO <field>.
                IF sy-subrc = 0.
                  et_values-value = <field>.
                  et_values-active = ''.
                  APPEND et_values.
                ENDIF.
              ENDIF.

            ENDLOOP.
          ENDIF.
        ENDIF.

      ENDLOOP.
      UNASSIGN <table>.

    ENDIF.
  ENDLOOP.

*--If the same value was returned by different value sets inside a rule,
* and the value was inactive for one set, and active for another one,
* the active one should take precedence.
  SORT et_values BY var_element ASCENDING
                    sysid ASCENDING
                    value ASCENDING
                    active DESCENDING.
  DELETE ADJACENT DUPLICATES FROM et_values COMPARING
  var_element sysid value .

ENDFUNCTION.
