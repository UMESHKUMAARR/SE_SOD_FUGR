*----------------------------------------------------------------------*
***INCLUDE /PSYNG/Z_SODREPORT_ORG_45_CF01.
*----------------------------------------------------------------------*
FORM create_output_table
  USING
      i_mode          TYPE string
      if_texts        TYPE flag
  CHANGING
      er_table        TYPE REF TO data
      et_fieldcat     TYPE slis_t_fieldcat_alv
      es_layout       TYPE slis_layout_alv.
  DATA :
    ls_alv_fieldcat TYPE slis_fieldcat_alv,
    lt_typedesc     TYPE cl_abap_structdescr=>component_table,
    ls_typedesc     TYPE abap_componentdescr,
    l_role_short_desc TYPE dd03p-scrtext_s,
    l_role_mid_desc TYPE dd03p-scrtext_m,
    l_role_long_desc TYPE dd03p-scrtext_l.

  FIELD-SYMBOLS :
      <fs_structure>  TYPE any,
      <fcat>          TYPE slis_fieldcat_alv.

  REFRESH : et_fieldcat[].
  CLEAR   : es_layout, l_role_short_desc, l_role_mid_desc,
            l_role_long_desc.
  FREE    : er_table.

*--Macros
  DEFINE add_column.
*--Dynamic Table definition
    clear ls_typedesc.
    ls_typedesc-name = &1.
    if &6 is initial.
      ls_typedesc-type = cl_abap_elemdescr=>get_c( &2 ).
    else.
      ls_typedesc-type ?= cl_abap_datadescr=>describe_by_name( &6 ).
*      cast
*      cl_abap_datadescr(
*      cl_abap_datadescr=>describe_by_name( &6 ) ) .
    endif.
    append ls_typedesc to lt_typedesc.
   if &6 = 'FLAG'.
     ls_alv_fieldcat-checkbox = 'X'.
     ls_alv_fieldcat-just     = 'X'.
   else.
     clear ls_alv_fieldcat-checkbox.
   endif.
*--create field catalog for ALV
   add 1 to ls_alv_fieldcat-col_pos.
   ls_alv_fieldcat-fieldname    = &1.
   ls_alv_fieldcat-outputlen    = &3.
   ls_alv_fieldcat-seltext_s    = &7.
   if &8 is initial.
     ls_alv_fieldcat-seltext_m    = ls_alv_fieldcat-seltext_s.
   else.
     ls_alv_fieldcat-seltext_m    = &8.
   endif.
   if &9 is initial.
     ls_alv_fieldcat-seltext_l    = ls_alv_fieldcat-seltext_m.
   else.
     ls_alv_fieldcat-seltext_l    = &9.
   endif.
   ls_alv_fieldcat-reptext_ddic = ls_alv_fieldcat-seltext_l.
   ls_alv_fieldcat-hotspot      = &4.
   ls_alv_fieldcat-no_out       = &5.

*BOC:HBHALLA
    CLEAR ls_alv_fieldcat-lowercase.

    if p_nabap = 'X'.
      if ls_alv_fieldcat-fieldname  = 'AGR_NAME'
       OR ls_alv_fieldcat-fieldname = 'OBJCT'
       OR ls_alv_fieldcat-fieldname = 'FIELD'
       OR ls_alv_fieldcat-fieldname = 'VON'
       OR ls_alv_fieldcat-fieldname = 'BIS'
       OR ls_alv_fieldcat-fieldname = 'OBJCTDESC'    "Description fields
       OR ls_alv_fieldcat-fieldname = 'DESCRIPTION'
       OR ls_alv_fieldcat-fieldname = 'FUNDESC'
       OR ls_alv_fieldcat-fieldname = 'AGR_DESC'
       OR ls_alv_fieldcat-fieldname = 'BNAME_DESC' "HBHALLA(PN-6875)
       OR ls_alv_fieldcat-fieldname = 'TCODEDESC'.
        ls_alv_fieldcat-lowercase    = 'X'.
      endif.
    endif.

    if p_abap = 'X'.
      if ls_alv_fieldcat-fieldname  = 'OBJCTDESC'    "Description fields
       OR ls_alv_fieldcat-fieldname = 'DESCRIPTION'
       OR ls_alv_fieldcat-fieldname = 'FUNDESC'
       OR ls_alv_fieldcat-fieldname = 'AGR_DESC'
       OR ls_alv_fieldcat-fieldname = 'BNAME_DESC' "HBHALLA(PN-6875)
       OR ls_alv_fieldcat-fieldname = 'TCODEDESC'.
        ls_alv_fieldcat-lowercase    = 'X'.
      endif.
    endif.

*END OF CHANGE: HBHALLA

   append ls_alv_fieldcat to et_fieldcat.
  END-OF-DEFINITION.
  DEFINE set_icon.
    read table et_fieldcat assigning <fcat> with key fieldname = &1.
    if sy-subrc = 0.
      <fcat>-icon = 'X'.
    endif.
  END-OF-DEFINITION.
  DEFINE remove_column.
    delete lt_typedesc where name = &1.
    delete et_fieldcat where fieldname = &1.
  END-OF-DEFINITION.
  DEFINE remove_column_if_equal.
    if &1 = &2.
        remove_column &3.
    endif.
  END-OF-DEFINITION.
  DEFINE remove_column_if_different.
    if &1 <> &2.
        remove_column &3.
    endif.
  END-OF-DEFINITION.
*--define the structure/fields of the output table
*&---------------------------------------------------------------------*

  add_column :
*   |FIELDNAME
*   |              |Length
*   |              |   |Output Length
*   |              |   |       |Hotspot
*   |              |   |       |   |No Output
*   |              |   |       |   |    |Data Type
*   |              |   |       |   |    |        |Labels (short, medium, long, when blank takes one longer)
    'BNAME'        12  12      'X' ' '  'XUBNAME'
                                                  'User ID'
                                                  ''
                                                  '',
*BOC AKUMAR PN3723
 'BNAME_DESC'       80  80      ' ' ' '  'AD_NAMTEXT'
                                                  'User Name'
                                                  ''
                                                  '',
*EOC AKUMAR PN3723
*Begin of Addition <HBHALLA> PN-15675 27/10/2025
 'CLASS'       80  80      ' ' ' '  'XUCLASS'
                                                  'User Group'
                                                  ''
                                                  '',

 'DEPARTMENT'       80  80      ' ' ' '  'TEXT40'
                                                  'Department'
                                                  ''
                                                  '',
*End of Addition <HBHALLA> PN-15675 27/10/2025
   'ORG_ABB'        10  10      ' ' ' '  '/PSYNG/DORG_ABB'
                                                'Abbr.'
                                                'Org Area Abbr. '
                                     'Organizational Area Abbreviation',

    'IMP'            8   8       ' ' 'X'  '/PSYNG/IMPORTANCE'
                                     'Sens'
                                     'Sensitivity'
                                     '',
    'CONID'          12  12      'X' ' '  '/PSYNG/CONFLICT_ID'
                                     'Con ID'
                                     'Conflict ID'
                                     '',

    'RISK'           10  10      'X' ' '  '/PSYNG/RISK'
                                     'Risk'
                                     'Risk Desc'
                                     'Risk Description',
    'DESCRIPTION'    200 200     ' ' ' '  '/PSYNG/RSKDSC'
                                     'Con Desc.'
                                     'Conflict Desc'
                                     'Conflict Description',
    'FUNCTIONID'     12  12      'X' ' '  '/PSYNG/FUNCTION_ID'
                                     'Func. ID'
                                     'Function ID'
                                     '',
    'FUNDESC'        200 200     ' ' ' '  '/PSYNG/FUNDSC'
                                     'Fun Desc'
                                     'Function Desc'
                                     'Function Description',
    'COMP_AGR'       30  30      'X' ' '  'AGR_NAME'
                                     'Comp Role'
                                     'Composite Role' '' .
  IF p_nabap = 'X' .
    add_column:
    'AGR_NAME'       128  128      'X' ' '  'CHAR128'
                                                   'Role'
                                                   ''
                                                   ''.
  ELSE.
    add_column :
    'AGR_NAME'       30  30      'X' ' '  'AGR_NAME'
                                                  'Role'
                                                  ''
                                                  ''.
  ENDIF.
  add_column :
    'AGR_DESC'       128  128      ' ' ' '  'CHAR128'" CHANGED FROM 80 TO 128
                                                  'Role Desc'
                                                  'Short Role Desc'
                                               'Short Role Description',
    'APPLICATION'    10  10      ' ' ' '  '/PSYNG/APPLICATION'
                                               'Application'
                                               ''
                                               '',
     'RFCDEST'        8   8       ' ' ' '  '/PSYNG/SYSTEM'
                                               'System'
                                               ''
                                               '',
     'TCODE'          20  20      'X' ' '  'XUVALUE'
                                               'Src Tcode'
                                               'Src Tcode / Screen'
                                             'Source Tcode / Screen ID',
     'TCODEDESC'      255 255     ' ' ' '  '/PSYNG/SW_FIORINAME'
                                             'Tcode/App Desc'
                                             'Tcode/App Description'
                                  'Transaction / Fiori App Description',
*BOC:HBHALLA (PN-4026) (07/03/25)
     'FIORIID'          100  100      'X' ' '  '/PSYNG/SW_FIORIID'
                                               'Fiori ID'
                                               'Fiori ID'
                                               'Fiori ID',
*EOC:HBHALLA (PN-4026) (07/03/25)
     'EXE_USER'       10  10      'X' ' '  '/PSYNG/BC_HIS_DIA_STEPS'
                                  'User'
                                  'User Dialog Steps'
                                  'User Dialog Steps in Tcode',
     'EXE_ROLE'       10  10      ' ' ' '  '/PSYNG/BC_HIS_DIA_STEPS'
                                  'Any'
                                  'User with Role Steps'
                                  'User with role Steps in Tcode',
     'EXE_DER'        10  10      ' ' ' '  '/PSYNG/BC_HIS_DIA_STEPS'
                                  'All'
                                  'Der. Role User Steps'
                          'User with role in derived role family steps'.
IF p_nabap = 'X' .
add_column:
     'OBJCT'          128  128      'X' ' '  'CHAR128' " length inc changes by kamalpreet for c1279 for non abap
                          'Object'
                          'Authorization Object' ''.
ELSE.
add_column:
     'OBJCT'          10  10      'X' ' '  'XUOBJECT'
                          'Object'
                          'Authorization Object'
                          ''.
ENDIF.
add_column:
     'OBJCTDESC'      60  60      ' ' ' '  'XUTEXT'
                          'Object Desc'
                          'Object Description'
                          '',
     'AUTH'           12  12      ' ' ' '  'XUAUTH'
                          'Authorization'
                          ''
                          ''.
  IF p_nabap = 'X' .
    add_column:
      'FIELD'         128  128      'X' ' '  'CHAR128'
                                                   'Field'
                                                   'Field Name'
                                                   ''.
  ELSE.
    add_column:
      'FIELD'          10  10      'X' ' '  'XUFIELD'
                          'Field'
                          'Field Name'
                          ''.
  ENDIF.
  IF p_nabap = 'X'.
  add_column :
       'VON'           128 128      'X' ' '  'CHAR128'
                          'From Value'
                          ''
                          ''.
  else.
  add_column :
       'VON'           40  40      'X' ' '  'XUVAL'
                          'From Value'
                          ''
                          ''.
  endif.
  add_column :
      'BIS'            40  40      'X' ' '  'XUVAL'
                          'To Value'
                          ''
                          '',
      'PROFILE'        12  12      'X' ' '  'XUPROFILE'
                          'Profile'
                          ''
                          '',
      'COMP_PROF'      12  12      'X' ' '  'XUPROFILE'
                          'Composite Profile'
                          ''
                          '',
       'SIMU'           1   1       ' ' ' '  'FLAG'
                          'Simulation'
                          ''
                          '',
       'ENHANCED'       1   1       'X' ' '  'FLAG'
                          'Enhanced'
                          ''
                          '',
       'ER'             1   1       ' ' ' '  'FLAG'
                          'Emergency Repair'
                          ''
                          '',
       'COLOR_CELL'     0   0       ' ' 'X'  'LVC_T_SCOL'
                          ''
                          ''
                          '',
       'CONTID'         12  12      'X' ' '  '/PSYNG/CONTID'
                          'Mitigation ID'
                          ''
                          '',
        'MIT_ICON'       4   4       'X' ' '  'ICON_D'
                          'Mitigation Type'
                          ''
                          '',
        'ORG_TYPE'       1   4       ' ' 'X'  'INT4'
                          'Org Type'
                          ''
                          ''.


*--Remove fields based on what type of data we want to display
  CASE i_mode.
    WHEN 'SIMPLE'.
      remove_column :
       'OBJCT',
       'OBJCTDESC',
       'AUTH',
       'FIELD',
       'VON',
       'BIS',
       'PROFILE',
       'FUNCDESC',
       'ER',
       'PROFILE',
       'ORG_TYPE'.
  ENDCASE.

*--Remove unneeded fields
*--Remove cell color fields if not needed
IF p_hienhn IS INITIAL AND NOT ( gf_cfg_set_enabled = 'X' AND orgchk = 'X' ).
    remove_column 'COLOR_CELL'.
  ELSE.
    MOVE 'COLOR_CELL' TO es_layout-coltab_fieldname.
  ENDIF.

*--Remove Simulation field if not needed
  IF bysimu IS INITIAL AND byrsimu IS INITIAL and ebysimu is INITIAL
    and ebrsimu is INITIAL.
    remove_column :
      'SIMU'.
  ENDIF.
*--Remove historical fields if not needed
  IF h_usr <> 'X' OR p_shhis <> 'X' .
    remove_column 'EXE_USER'.
  ENDIF.
  IF h_any <> 'X' OR p_shhis <> 'X'.
    remove_column 'EXE_ROLE'.
  ENDIF.
  IF h_all <> 'X' OR p_shhis <> 'X'.
    remove_column 'EXE_DER'.
  ENDIF.

*--Remove fields if certain parameter has certain value

*--Remove enhanced checkbox
  remove_column_if_equal p_enhanc '' 'ENHANCED'.
*--Remove ER checkbox
  remove_column_if_equal erroles '' 'ER'.
*--Remove text fields if not needed
  remove_column_if_equal if_texts '' :
   'FUNDESC',
   'OBJCTDESC',
   'AGR_DESC',
   'TCODEDESC',
   'BNAME_DESC'. "PN3723

*--Remove composite role fields if not needed
  remove_column_if_equal showcomp '' 'COMP_AGR'.
  remove_column_if_equal showpcom '' 'COMP_PROF'.
*--Remove Org fields if not needed
  remove_column_if_equal orgchk '' :
     'ORG_ABB'.
  remove_column_if_equal orgchk '' :
     'ORG_ABB'.
*--Remove Mitigation Related fields
  remove_column_if_equal shosimp ' ' :
    'CONTID', 'MIT_ICON'.
  remove_column_if_equal xmc ' ' :
    'CONTID', 'MIT_ICON'.
  remove_column_if_equal gf_cfg_set_enabled '' :
    'ORG_TYPE'.

*--Mark mitigation icon field as icon field
  set_icon 'MIT_ICON'.

  es_layout-zebra = 'X'.
  es_layout-colwidth_optimize = 'X'.

  go_struct = cl_abap_structdescr=>create( lt_typedesc ).
  go_table  = cl_abap_tabledescr=>create( p_line_type = go_struct ).
  CREATE DATA er_table TYPE HANDLE go_table.
  SORT et_fieldcat BY fieldname."for faster searching



ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SHOW_TEXTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_texts .
*--Submit current report with the same parameters,
*      but include the historical data
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
    EXPORTING
      i_repid           = g_program
      if_no_logging     = 'X'
      if_ignore_initial = ''
    TABLES
      et_params         = lt_params.
  set_param :
    'P_SHTEXT' 'X'  '' 'P' 'I' 'EQ'.
  SUBMIT (g_program) "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(11/12/24)
   WITH SELECTION-TABLE lt_params AND RETURN.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  SHOW_SIMPLIFIED_VIEW
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_simplified_view .
*--Submit current report with the same parameters,
*      but include the historical data
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
    EXPORTING
      i_repid           = g_program
      if_no_logging     = 'X'
      if_ignore_initial = ''
    TABLES
      et_params         = lt_params.
  set_param :
    'SHOSIMP' 'X'  '' 'P' 'I' 'EQ',
    'SHODET'  ''  '' 'P' 'I' 'EQ'.
  SUBMIT (g_program) "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Function name is variable so it can’t be fixed.(11/12/24)
   WITH SELECTION-TABLE lt_params AND RETURN.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  TOGGLE_ORG_VALUES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM toggle_org_values .
  IF gf_org_fields_display = 'X'.
    CLEAR gf_org_fields_display.
  ELSE.
    gf_org_fields_display = 'X'.
  ENDIF.
  PERFORM toggle_org_filter USING gf_org_fields_display.
ENDFORM.
FORM toggle_org_filter
  USING    if_show TYPE flag.
  DATA : l_fld          TYPE string,
         lt_filter      TYPE lvc_t_filt,
         ls_filter      TYPE lvc_s_filt,
         ls_fm_filter   TYPE slis_filter_alv,
*         lt_new_output LIKE TABLE OF outputdet4 WITH HEADER LINE,
         lt_color_orgph TYPE lvc_t_scol,
         lt_color_varph TYPE lvc_t_scol,
         lt_color_org   TYPE lvc_t_scol,
         lt_color_var   TYPE lvc_t_scol,
         lt_color_cell  TYPE lvc_t_scol,
         ls_color_cell  TYPE lvc_s_scol,
         lf_highlight   TYPE flag,
         lr_table       TYPE REF TO data.
  STATICS : st_faobj   TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
            st_org     TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
            st_checked TYPE flag.
  FIELD-SYMBOLS : <new_record> TYPE any,
                  <lt_output>  TYPE STANDARD TABLE.
  CONSTANTS :
*normal field, non org or var element
    c_org_type_normal TYPE i VALUE 0,
*org or var element  with actual value
    c_org_type_org    TYPE i VALUE 1,
*org or var element  with placeholder value ($ORG or /PSYNG/$VAREL
    c_org_type_orgph  TYPE i VALUE 3.
  CREATE DATA lr_table TYPE HANDLE go_table.
  ASSIGN lr_table->* TO <lt_output>.
  CREATE DATA lr_rec LIKE LINE OF <lt_output>.
  ASSIGN lr_rec->* TO <new_record>.

*--If this is the first time, get fields to be toggled
  IF st_checked IS INITIAL.
    se_config_param 'CFG_SET_HIGHLIGHT' lf_highlight.
    IF lf_highlight = 'Y'.
*    --Prepare colors
*    Add some highlighting to the placeholders
*    --Org Placeholders
      ls_color_cell-fname       = 'VON'.
      ls_color_cell-color-col   = '3'.   " yellow
      ls_color_cell-color-int   = '1'.
      ls_color_cell-color-inv   = '0'.
      APPEND ls_color_cell TO lt_color_orgph.
*    --Org Values
      ls_color_cell-fname       = 'VON'.
      ls_color_cell-color-col   = '3'.   "light yellow
      ls_color_cell-color-int   = '0'.
      ls_color_cell-color-inv   = '0'.
      APPEND ls_color_cell TO lt_color_org.
*    --Variable Elements Placeholders
      ls_color_cell-fname       = 'VON'.
      ls_color_cell-color-col   = '4'.   "darker blue
      ls_color_cell-color-int   = '1'.
      ls_color_cell-color-inv   = '0'.
      APPEND ls_color_cell TO lt_color_varph.
*    --Variable Elements
      ls_color_cell-fname       = 'VON'.
      ls_color_cell-color-col   = '4'.   "light blue
      ls_color_cell-color-int   = '0'.
      ls_color_cell-color-inv   = '0'.
      APPEND ls_color_cell TO lt_color_var.
    ENDIF.
*  --Variable Elements
    CALL FUNCTION '/PSYNG/SW_READ_SOD_MATRIX_ORG'
      EXPORTING
        vrsio      = sodvrsio
      TABLES
        faobj_fm   = st_faobj
        spconfs_fm = spconfs.
    DELETE st_faobj WHERE NOT val_from CP '/PSYNG/$*'.
    SORT st_faobj BY field object funid tcode.
    DELETE ADJACENT DUPLICATES FROM st_faobj
    COMPARING field object funid tcode.
*--Org Elements
    CALL FUNCTION '/PSYNG/SW_AO_READ'
      EXPORTING
        if_read       = 'X'
        i_setid       = cfgset
      TABLES
        et_org_values = st_org.
    DELETE st_org WHERE active <> 'X'.
    SORT st_org BY varbl.
    DELETE ADJACENT DUPLICATES FROM st_org.
    st_checked = 'X'.
*--Adjust the output to include $org and /psyng/$variable entries


    DATA : l_appl  TYPE /psyng/application,
           l_von   TYPE xuvalue,
           l_varbl TYPE xufield,
           l_objct TYPE xuobject,
           l_tcode TYPE xutcode,
           l_fun   TYPE /psyng/function_id.
    LOOP AT <gt_output> ASSIGNING <gs_output>.
      dyn_value 'ORG_TYPE' c_org_type_normal <gs_output>.
      get_dyn_value : 'APPLICATION' <gs_output> l_appl.

      IF l_appl <> 'SAP' AND
         NOT l_appl IS INITIAL.
        dyn_value 'ORG_TYPE' c_org_type_normal <gs_output>.
      ELSE.
        <new_record> = <gs_output>.
        get_dyn_value : 'FIELD'      <gs_output> l_varbl,
                        'OBJCT'      <gs_output> l_objct,
                        'TCODE'      <gs_output> l_tcode,
                        'FUNCTIONID' <gs_output> l_fun.
        READ TABLE st_org WITH KEY varbl = l_varbl
        BINARY SEARCH TRANSPORTING varbl.
        IF sy-subrc = 0.

          dyn_value 'ORG_TYPE' c_org_type_org <gs_output>.
*          APPEND LINES OF lt_color_org TO <out>-color_cell.
          dyn_value 'COLOR_CELL' lt_color_org <gs_output>.
*          lt_new_output = <out>.
*          CLEAR : lt_new_output-von,
*                  lt_new_output-bis,
*                  lt_new_output-comp_prof,
*                  lt_new_output-simu,
*                  lt_new_output-enhanced,
*                  lt_new_output-er,
*                  lt_new_output-exe_user,
*                  lt_new_output-exe_der,
*                  lt_new_output-exe_role,
*                  lt_new_output-org_abb.
          CONCATENATE '$' st_org-varbl INTO   l_von.
*           dyn_value : 'VON'        l_von            <gs_output>.
*--TODO add the new record without changing existing one
          dyn_value : 'VON'        l_von            <new_record>,
                      'ORG_TYPE'   c_org_type_orgph <new_record>,
                      'COLOR_CELL' lt_color_orgph[] <new_record>,
*                      'VON'        ''               <new_record>,
                      'BIS'        ''               <new_record>,
                      'COMP_PROF'  ''               <new_record>,
                      'SIMU'       ''               <new_record>,
                      'ENHANCED'   ''               <new_record>,
                      'ER'         ''               <new_record>,
                      'EXE_USER'   ''               <new_record>,
                      'EXE_DER'    ''               <new_record>,
                      'EXE_ROLE'   ''               <new_record>,
                      'ORG_ABB'    ''               <new_record>.
          APPEND <new_record> TO <lt_output>.
        ENDIF.
*--We are not taking function/tcode into account yet
        READ TABLE st_faobj WITH KEY field  = l_varbl
                                     object = l_objct
                                     funid  = l_fun
                                     tcode  = l_tcode
        BINARY SEARCH TRANSPORTING val_from.
        IF sy-subrc = 0.
          dyn_value 'ORG_TYPE' c_org_type_org <gs_output>.
          get_dyn_value : 'COLOR_CELL'      <gs_output> lt_color_cell.
          APPEND LINES OF lt_color_var TO lt_color_cell.
          dyn_value : 'COLOR_CELL' lt_color_cell[] <gs_output>.
          <new_record> = <gs_output>.
          dyn_value : "*''VON'        l_von             <new_record>,
                      'ORG_TYPE'   c_org_type_orgph  <new_record>,
                      'COLOR_CELL' lt_color_varph[]  <new_record>,
                      'VON'        st_faobj-val_from <new_record>,
                      'BIS'        ''                <new_record>,
                      'COMP_PROF'  ''                <new_record>,
                      'SIMU'       ''                <new_record>,
                      'ENHANCED'   ''                <new_record>,
                      'ER'         ''                <new_record>,
                      'EXE_USER'   ''                <new_record>,
                      'EXE_DER'    ''                <new_record>,
                      'EXE_ROLE'   ''                <new_record>,
                      'ORG_ABB'    ''                <new_record>.
          APPEND <new_record> TO <lt_output>.
        ENDIF.
      ENDIF.
    ENDLOOP.
    SORT <lt_output>.
    DELETE ADJACENT DUPLICATES FROM <lt_output>.
    APPEND LINES OF <lt_output> TO <gt_output>.
  ENDIF.
* Get a reference to the GRID
  FIELD-SYMBOLS <grid> TYPE REF TO cl_gui_alv_grid.
  l_fld = '(SAPLSLVC_FULLSCREEN)GT_GRID-GRID'.
  ASSIGN  ('(SAPLSLVC_FULLSCREEN)GT_GRID-GRID') TO <grid>."HBHALLA
  IF <grid> IS ASSIGNED.
*  --Get the existing filter
    CALL METHOD <grid>->get_filter_criteria
      IMPORTING
        et_filter = lt_filter[].
    DELETE lt_filter WHERE fieldname = 'ORG_TYPE' .
  ENDIF.
  IF if_show <> 'X'.
*--Filter out the fields that should be hidden
    ls_filter-fieldname = 'ORG_TYPE'.
    ls_filter-tabname   = '<GT_OUTPUT>'.
    ls_filter-ref_field = 'ORG_TYPE'.
    ls_filter-ref_table = ''.
    ls_filter-sign      = 'E'.
    ls_filter-option    = 'EQ'.
    ls_filter-low       =  c_org_type_org.
    CONDENSE ls_filter-low.
    APPEND ls_filter TO lt_filter.
  ELSE.
*--Filter out the fields that should be hidden
    ls_filter-fieldname = 'ORG_TYPE'.
    ls_filter-tabname   = '<GT_OUTPUT>'.
    ls_filter-ref_field = 'ORG_TYPE'.
    ls_filter-ref_table = ''.
    ls_filter-sign      = 'E'.
    ls_filter-option    = 'EQ'.
    ls_filter-low       =  c_org_type_orgph.
    CONDENSE ls_filter-low.
    APPEND ls_filter TO lt_filter.
  ENDIF.
*--Apply the new filter
  IF <grid> IS ASSIGNED.
    CALL METHOD <grid>->set_filter_criteria
      EXPORTING
        it_filter                 = lt_filter[]
      EXCEPTIONS
        no_fieldcatalog_available = 1
        OTHERS                    = 2.
    IF sy-subrc <> 0.
    MESSAGE i002 WITH 'Failed to apply Org and Variable element filter'.
    ENDIF.
  ENDIF.
  REFRESH : gt_filter_user_detail.
  LOOP AT lt_filter INTO ls_filter.
    MOVE-CORRESPONDING ls_filter TO ls_fm_filter.
    ls_fm_filter-sign0         = ls_filter-sign.
    ls_fm_filter-optio         = ls_filter-option.
    ls_fm_filter-valuf         = ls_filter-low.
    ls_fm_filter-valut         = ls_filter-high.
    ls_fm_filter-valuf_int     = ls_filter-low.
    ls_fm_filter-datatype      = ls_filter-datatype.
    ls_fm_filter-ref_fieldname = ls_filter-fieldname.
    ls_fm_filter-ref_tabname   = ls_filter-tabname.
    CONDENSE :
      ls_fm_filter-valuf,
      ls_fm_filter-valut.


    APPEND ls_fm_filter TO gt_filter_user_detail.
  ENDLOOP.
  IF <grid> IS ASSIGNED.
    CALL METHOD <grid>->refresh_table_display.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  toggle_alv_user_init
*&---------------------------------------------------------------------*
* if Configuration set functionality is enabled,
* prepare info for toggling variable and org values.
*----------------------------------------------------------------------*

FORM toggle_alv_user_init.
  CHECK mode = 'DET'.
  DATA : lf_show TYPE flag.
  IF gf_cfg_set_enabled = 'X'.
    se_config_param 'CFG_SET_SHOW_DFLT' lf_show.
    IF lf_show = 'Y'.
      PERFORM toggle_org_filter USING 'X'.
      gf_org_fields_display = 'X'.
    ELSE.
      PERFORM toggle_org_filter USING ''.
      CLEAR gf_org_fields_display.
    ENDIF.
  ENDIF.
ENDFORM.



FORM prepare_role_removal_simu TABLES   et_role_removal_simu STRUCTURE
                                          /psyng/sw_role_removal_simu.

  IF  NOT rr_rol_1[] IS  INITIAL.
    et_role_removal_simu-rfcdest = rr_rfc_1.
    LOOP AT rr_rol_1.
      MOVE-CORRESPONDING rr_rol_1 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.
  IF  NOT  rr_rol_2[] IS INITIAL.
    et_role_removal_simu-rfcdest = rr_rfc_2.
    LOOP AT rr_rol_2.
      MOVE-CORRESPONDING rr_rol_2 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.
  IF  NOT rr_rol_3[] IS  INITIAL.
    et_role_removal_simu-rfcdest = rr_rfc_3.
    LOOP AT rr_rol_3.
      MOVE-CORRESPONDING rr_rol_3 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.
  IF  NOT rr_rol_4[] IS  INITIAL.
    et_role_removal_simu-rfcdest = rr_rfc_4.
    LOOP AT rr_rol_4.
      MOVE-CORRESPONDING rr_rol_4 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " prepare_role_removal_simu
FORM prepare_role_addition_simu TABLES   et_role_addition_simu STRUCTURE
                                          /psyng/sw_role_addition_simu.

  IF  NOT ar_rol_1[] IS  INITIAL.
    et_role_addition_simu-source_rfcdest = ar_rfcs1.
    et_role_addition_simu-target_rfcdest = ar_rfcd1.
    LOOP AT ar_rol_1.
      MOVE-CORRESPONDING ar_rol_1 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
  CLEAR et_role_addition_simu.
  IF  NOT ar_rol_2[] IS  INITIAL.
    et_role_addition_simu-source_rfcdest = ar_rfcs2.
    et_role_addition_simu-target_rfcdest = ar_rfcd2.
    LOOP AT ar_rol_2.
      MOVE-CORRESPONDING ar_rol_2 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
  CLEAR et_role_addition_simu.
  IF  NOT ar_rol_3[] IS  INITIAL.
    et_role_addition_simu-source_rfcdest = ar_rfcs3.
    et_role_addition_simu-target_rfcdest = ar_rfcd3.
    LOOP AT ar_rol_3.
      MOVE-CORRESPONDING ar_rol_3 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
  CLEAR et_role_addition_simu.
  IF  NOT ar_rol_4[] IS  INITIAL.
    et_role_addition_simu-source_rfcdest = ar_rfcs4.
    et_role_addition_simu-target_rfcdest = ar_rfcd4.
    LOOP AT ar_rol_4.
      MOVE-CORRESPONDING ar_rol_4 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
ENDFORM.                    "
* EN Simulation by adding roles
FORM prepare_role_addition_simu_en TABLES   et_role_addition_simu
STRUCTURE
                                          /psyng/ex_role_addition_simu.
*  READ TABLE s_appl INDEX 1.
  IF  NOT ae_rol_1[] IS  INITIAL.
*    et_role_addition_simu-appl = s_appl-low.
    et_role_addition_simu-source_sysid = ar_syss1.
    et_role_addition_simu-target_sysid = ar_sysd1.
    LOOP AT ae_rol_1.
      MOVE-CORRESPONDING ae_rol_1 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
  CLEAR et_role_addition_simu.
  IF  NOT ae_rol_2[] IS  INITIAL.
*    et_role_addition_simu-appl = s_appl-low.
    et_role_addition_simu-source_sysid = ar_syss2.
    et_role_addition_simu-target_sysid = ar_sysd2.
    LOOP AT ae_rol_2.
      MOVE-CORRESPONDING ae_rol_2 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
  CLEAR et_role_addition_simu.
  IF  NOT ae_rol_3[] IS  INITIAL.
*    et_role_addition_simu-appl = s_appl-low.
    et_role_addition_simu-source_sysid = ar_syss3.
    et_role_addition_simu-target_sysid = ar_sysd3.
    LOOP AT ae_rol_3.
      MOVE-CORRESPONDING ae_rol_3 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
  CLEAR et_role_addition_simu.
  IF  NOT ae_rol_4[] IS  INITIAL.
*    et_role_addition_simu-appl = s_appl-low.
    et_role_addition_simu-source_sysid = ar_syss4.
    et_role_addition_simu-target_sysid = ar_sysd4.
    LOOP AT ae_rol_4.
      MOVE-CORRESPONDING ae_rol_4 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.


ENDFORM.
*EN Simulation by removing roles
FORM prepare_role_removal_simu_en TABLES   et_role_removal_simu
STRUCTURE
                                          /psyng/en_role_removal_simu.
*  READ TABLE s_appl INDEX 1.
  IF  NOT en_rol_1[] IS  INITIAL.
*    et_role_removal_simu-appl  = s_appl-low.
    et_role_removal_simu-sysid = rr_sys_1.
    LOOP AT en_rol_1.
      MOVE-CORRESPONDING en_rol_1 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.
  IF  NOT  en_rol_2[] IS INITIAL.
*    et_role_removal_simu-appl  = s_appl-low.
    et_role_removal_simu-sysid = rr_sys_2.
    LOOP AT en_rol_2.
      MOVE-CORRESPONDING en_rol_2 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.
  IF  NOT en_rol_3[] IS  INITIAL.
*    et_role_removal_simu-appl  = s_appl-low.
    et_role_removal_simu-sysid = rr_sys_3.
    LOOP AT en_rol_3.
      MOVE-CORRESPONDING en_rol_3 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.
  IF  NOT en_rol_4[] IS  INITIAL.
*    et_role_removal_simu-appl  = s_appl-low.
    et_role_removal_simu-sysid = rr_sys_4.
    LOOP AT en_rol_4.
      MOVE-CORRESPONDING en_rol_4 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.

ENDFORM.



*&---------------------------------------------------------------------*
*&      Form  OUTPUT_USING_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM output_using_alv .


  PERFORM set_output_variant.

*  --If Configuration set functionality is enabled,
*   prepare info for toggling variable and org values.
  PERFORM toggle_alv_user_init.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*       i_grid_title             = alv_grid_titl
      i_callback_program       = g_program
      it_sort                  = gt_alv_sort[]
      i_callback_user_command  = 'ALV_DRILLDOWN'
      i_callback_pf_status_set = 'ALV_SET_PF_STATUS'
      i_callback_top_of_page   = 'ALV_TOP_OF_PAGE'
      is_layout                = gs_alv_layout
      it_fieldcat              = gt_alv_fieldcat
      it_filter                = gt_filter_user_detail
     i_save                   = 'A'
     is_variant               = gs_variant
*       is_print                 = ls_print
    TABLES
      t_outtab                 = <gt_output>[]
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.

FORM set_output_variant.
  DATA : lf_variant_exists.
*-- Set variant
  IF NOT p_dlayo IS INITIAL.
    gs_variant-report   = sy-repid.
    gs_variant-username = g_current_user."sy-uname. C0700
    gs_variant-variant  = p_dlayo.
  ENDIF.

*-- Validate List output variants
  IF NOT gs_variant IS INITIAL.
*-- check existence of named variant
    PERFORM alv_variant_check CHANGING  lf_variant_exists.
    IF  lf_variant_exists IS INITIAL.
      MESSAGE i000(msitem) WITH gs_variant-variant.
    ENDIF.
  ELSE.
*-- check existence of default variant
    PERFORM alv_default_check CHANGING  lf_variant_exists.
  ENDIF.

  IF  lf_variant_exists IS INITIAL.
    CLEAR gs_variant.
  ENDIF.

ENDFORM.                    " set_output_variant
FORM alv_variant_check CHANGING y_varexist TYPE c.

  CALL FUNCTION 'REUSE_ALV_VARIANT_EXISTENCE'
       EXPORTING
            i_save        = 'A'
       CHANGING
            cs_variant    = gs_variant
       EXCEPTIONS
            wrong_input   = 1
            not_found     = 2
            program_error = 3
            OTHERS        = 4.
  IF sy-subrc <> 0.
    CLEAR y_varexist.
  ELSE.
    y_varexist = 'X'.
  ENDIF.
ENDFORM.                    " alv_variant_check
*&---------------------------------------------------------------------*
*&      Form  alv_default_check
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_VAREXIST  text
*----------------------------------------------------------------------*
FORM alv_default_check CHANGING y_varexist TYPE c.

  CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
       EXPORTING
            i_save        = 'A'
       CHANGING
            cs_variant    = gs_variant
       EXCEPTIONS
            wrong_input   = 1
            not_found     = 2
            program_error = 3
            OTHERS        = 4.
  IF sy-subrc <> 0.
    CLEAR y_varexist.
  ELSE.
    y_varexist = 'X'.
  ENDIF.


ENDFORM.                    " alv_default_check


FORM show_user_tcode_history USING i_bname
                                   i_tcode
                                   i_start TYPE dats
                                   i_end   TYPE dats.


  DATA:
    userresponse,
    1stmon(7),
    lastmon(7),
    lf_ta_installed TYPE flag,
    lf_use_ta_his   TYPE flag,
    lf_config_val   TYPE /psyng/swconfig-value,
    l_repid         LIKE sy-repid,
    ifields         TYPE STANDARD TABLE OF sval WITH HEADER LINE.


  se_config_param 'TA_DISPLAY_HISTORY' lf_config_val.
  IF lf_config_val = 'N'.
    CLEAR lf_use_ta_his.
  ELSE.
    lf_use_ta_his = 'X'.
  ENDIF.
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
       EXPORTING
            i_module    = 'TA'
       IMPORTING
            e_installed = lf_ta_installed.

  IF NOT lf_ta_installed = 'X' OR NOT lf_use_ta_his = 'X'.

    CLEAR: ifields.
    REFRESH: ifields.

    PERFORM get_history_months USING 1stmon lastmon.

    ifields-tabname = '/PSYNG/SW_SEL_MON_YEAR'.
    ifields-fieldname = 'MMYYYYS'.
    ifields-fieldtext = 'From (MM/YYYY)'(081).
    ifields-value = 1stmon.
    APPEND ifields.
    ifields-tabname = '/PSYNG/SW_SEL_MON_YEAR'.
    ifields-fieldname = 'MMYYYYE'.
    ifields-fieldtext = 'To (MM/YYYY)'(082).
    ifields-value = lastmon.
    APPEND ifields.

    CLEAR userresponse.
    l_repid = sy-repid.
    CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
         EXPORTING
              formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
              programname       = l_repid
              popup_title       =
              'Restrict months (available displayed)'(080)
              ok_pushbuttontext = 'Continue'(127)
         IMPORTING
              returncode        = userresponse
         TABLES
              fields            = ifields
         EXCEPTIONS
              error_in_fields   = 1
              OTHERS            = 2.

    IF sy-subrc <> 0.
      MESSAGE e208(00) WITH text-067.
    ENDIF.

    CHECK userresponse NE 'A'. "#EC SAST_CI_GEN_CHECK
     "check to see user doesn't abort

    READ TABLE ifields WITH KEY tabname = '/PSYNG/SW_SEL_MON_YEAR'
                                             fieldname = 'MMYYYYS'.
    CHECK NOT ifields-value IS INITIAL.
    1stmon = ifields-value.

    READ TABLE ifields WITH KEY tabname = '/PSYNG/SW_SEL_MON_YEAR'
                                             fieldname = 'MMYYYYE'.
    CHECK NOT ifields-value IS INITIAL.
    lastmon = ifields-value.
*--Use SE report
    SUBMIT /psyng/sw_017
            WITH pbname = i_bname
            WITH 1stmon = 1stmon
            WITH lastmon = lastmon
            WITH validusr = ' '
            AND RETURN.
  ELSE.
*--Use TA report
    IF i_tcode IS INITIAL.
      SUBMIT /psyng/bc_usrhis_36 VIA SELECTION-SCREEN
              WITH s_users  = i_bname
              WITH validusr = ' '
              AND RETURN.
    ELSE.
*--This was a drilldown on added tcode execution nr's
      SUBMIT /psyng/bc_usrhis_36
              WITH s_users  = i_bname
              WITH validusr = ' '
              with changes  = 'X'
              WITH s_date BETWEEN i_start AND i_end
              WITH s_tcode  = i_tcode

              AND RETURN.
    ENDIF.
  ENDIF.
ENDFORM.                    " show_user_tcode_history

FORM get_history_months USING 1stmon lastmon.
  DATA: 1stmonth TYPE sy-datum, lastmont TYPE sy-datum.
  DATA: idirectory TYPE STANDARD TABLE OF /psyng/sw_dates
        WITH HEADER LINE.

  CALL FUNCTION '/PSYNG/SW_GET_DIRECTORY'
       TABLES
            idirectory = idirectory.

  LOOP AT idirectory. " WHERE periodtype = 'M' AND hostid = 'TOTAL'.
    IF 1stmonth IS INITIAL OR 1stmonth > idirectory-startdate.
      1stmonth = idirectory-startdate.
    ENDIF.
    IF lastmont < idirectory-startdate.
      lastmont = idirectory-startdate.
    ENDIF.
  ENDLOOP.

  CONCATENATE 1stmonth+4(2) '/' 1stmonth(4) INTO 1stmon.
  CONCATENATE lastmont+4(2) '/' lastmont(4) INTO lastmon.
ENDFORM.                    " get_history_months

*---------------------------------------------------------------------*
*       FORM display_role_of_remote_system                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  FIELDS                                                        *
*  -->  CODE                                                          *
*  -->  ERROR                                                         *
*  -->  SHOW_POPUP                                                    *
*---------------------------------------------------------------------*
FORM display_role_of_remote_system TABLES   fields STRUCTURE sval
                   USING    code
                   CHANGING error  STRUCTURE svale show_popup.
  CASE code.
    WHEN 'EXECUTE'.
    WHEN 'EXIT'.
    WHEN 'OK'.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.
