*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SECUWELLF02                                         *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  f4_help_profn
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_CRITPROF_ITAB_PROFN  text
*----------------------------------------------------------------------*
FORM f4_help_profn CHANGING p_profn TYPE /psyng/criprof-profile.
  DATA: BEGIN OF lt_profn OCCURS 0,
            profile TYPE /psyng/criprof-profile,
            END OF lt_profn.

  DATA: lt_usr11 TYPE TABLE OF usr11 WITH HEADER LINE.

  DATA: BEGIN OF lt_proftext OCCURS 0,
        profn TYPE usr11-profn,
        ptext  TYPE usr11-ptext,
        END OF lt_proftext.

  DATA: lt_return TYPE STANDARD TABLE OF ddshretval,
         wa_return LIKE LINE OF lt_return,
         ls_shlp      TYPE shlp_descr_t.
  DATA: lt_fields TYPE TABLE OF dfies WITH HEADER LINE,
         l_rapid LIKE sy-repid.
  l_repid =  sy-repid.

  SELECT profile FROM /psyng/criprof INTO TABLE
     lt_profn WHERE vrsio = g_sod_vrsio.

  IF NOT lt_profn[] IS INITIAL.
    SELECT profn ptext FROM usr11
    INTO CORRESPONDING FIELDS OF TABLE lt_usr11
    FOR ALL ENTRIES IN lt_profn
    WHERE profn = lt_profn-profile
     AND langu  = sy-langu.
  ENDIF.

  LOOP AT lt_profn.
    READ TABLE lt_usr11 WITH KEY
                         profn = lt_profn-profile.
    IF sy-subrc = 0.
      lt_proftext-ptext = lt_usr11-ptext.
    ELSE.
      lt_proftext-ptext = 'Profile for cross system analysis'(300).
    ENDIF.
    lt_proftext-profn = lt_profn-profile.
    APPEND lt_proftext.
  ENDLOOP.
  SORT lt_proftext BY profn.
  DELETE ADJACENT DUPLICATES FROM lt_proftext COMPARING profn.
  DELETE lt_proftext WHERE profn EQ space.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
        EXPORTING
*   DDIC_STRUCTURE         = 'EKKO'
          retfield               = 'PROFN'
*   PVALKEY                = ' '
      dynpprog               = l_repid
      dynpnr                 = sy-dynnr
*   DYNPROFIELD            = 'EBELN'
*   STEPL                  = 0
          window_title           = 'Profile Name'
*   VALUE                  = ' '
          value_org              = 'S'
*    MULTIPLE_CHOICE        = 'X'
*   DISPLAY                = ' '
*   CALLBACK_PROGRAM       = ' '
*   CALLBACK_FORM          = ' '
*   MARK_TAB               =
* IMPORTING
*   USER_RESET             = ld_ret
        TABLES
          value_tab              = lt_proftext
*    FIELD_TAB              = lt_fields
          return_tab             = lt_return
*   DYNPFLD_MAPPING        =
       EXCEPTIONS
         parameter_error        = 1
         no_values_found        = 2
         OTHERS                 = 3.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

  READ TABLE lt_return INTO wa_return INDEX 1.
  gl_criprofs-profn = wa_return-fieldval.

ENDFORM.                    " f4_help_profn

*---------------------------------------------------------------------*
*       FORM handle_toolbar                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_OBJECT                                                      *
*  -->  I_INTERACTIVE                                                 *
*---------------------------------------------------------------------*
FORM handle_toolbar USING
 i_object TYPE REF TO cl_alv_event_toolbar_set
 i_interactive.

  DATA: ls_toolbar  TYPE stb_button.
  CLEAR ls_toolbar.
  MOVE 'DISPCHANGE' TO ls_toolbar-function.
  MOVE '@3I@' TO ls_toolbar-icon.
  MOVE 'Display/Change'(c03) TO ls_toolbar-quickinfo.
  MOVE ' ' TO ls_toolbar-disabled.                          "#EC NOTEXT
  INSERT ls_toolbar INTO  i_object->mt_toolbar INDEX 1.
  DELETE i_object->mt_toolbar WHERE function = '&DETAIL'
                                OR  function = '&SORT_ASC'
                                OR  function = '&SORT_DSC'
                                OR  function = '&FIND'
                                OR  function = '&FIND_MORE'
                                OR  function = '&MB_FILTER'
                                OR  function = '&MB_SUM'
                                OR  function = '&MB_SUBTOT'
                                OR  function = '&PRINT_BACK'
                                OR  function = '&MB_VIEW'
                                OR  function = '&MB_EXPORT'
                                OR  function = '&&SEP06'
                                OR  function = '&GRAPH'
                                OR  function = '&INFO'
                                OR  function = '&COL0'
                                OR  function = '&CHECK'
                                OR  function = '&REFRESH'
                                OR  function = '&LOCAL&UNDO'
                                OR  function = '&LOCAL&PASTE'
                                OR  function = '&LOCAL&COPY'
                                OR  function = '&LOCAL&CUT'
                                OR  function = '&VIEW '
                                OR  function = '&EXPORT'.
  IF gf_dispchg1 = gc_display.
    DELETE i_object->mt_toolbar WHERE function CS '&LOCAL&'.
  ENDIF.
ENDFORM .

*---------------------------------------------------------------------*
*       FORM display_confltr_alv                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_confltr_alv.
  REFRESH: gt_fieldcat, gt_sort.
  add_column: ' ' 'APPLICATION' 'Application'(z01)
              gt_fieldcat 20 'X'  'X' '' '',

              ' ' 'SIGN' 'Sign'(z02)
              gt_fieldcat 5 'X'  'X' '' '',

              ' ' 'TYPE' 'Option'(z03)
              gt_fieldcat 7 'X'  'X' '' '',

              ' ' 'LOW' 'Low'(z04)
              gt_fieldcat 20 'X'  'X' '' '',

              ' ' 'HIGH' 'High'(z05)
              gt_fieldcat 20 'X'  'X' '' ''.

  IF gf_dispchg1 = 'D'.
    LOOP AT gt_fieldcat ASSIGNING <fcat>.
      CLEAR <fcat>-edit.
    ENDLOOP.
  ENDIF.
  PERFORM fun_sort CHANGING gt_sort.
  IF gr_alvgrid IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_ccontainer
      EXPORTING
        container_name              = 'SYS_CON_FLTR'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        others                      = 6.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Creating ALV Grid instance
    CREATE OBJECT gr_alvgrid
      EXPORTING
        i_parent          = gr_ccontainer
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        others            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Preparing layout structure
    PERFORM prepare_layout USING 'C' CHANGING gs_layout .
    SET HANDLER gr_event_handler->handle_toolbar FOR gr_alvgrid.
    SET HANDLER gr_event_handler->handle_user_command FOR gr_alvgrid.
    SET HANDLER gr_event_handler->handle_on_f4 FOR gr_alvgrid.
*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
    CALL METHOD gr_alvgrid->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
      CHANGING
        it_outtab                     = gt_syscon[]
        it_fieldcatalog               = gt_fieldcat
        it_sort                       = gt_sort
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ELSE .
    CALL METHOD gr_alvgrid->set_frontend_fieldcatalog
      EXPORTING
        it_fieldcatalog = gt_fieldcat.

    CALL METHOD gr_alvgrid->refresh_table_display
      EXCEPTIONS
        finished = 1
        OTHERS   = 2.

    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF .

*--Set f4 enabled fields (Sorted Table!!)
  DATA: lt_f4 TYPE lvc_t_f4 WITH HEADER LINE ,
        wa_f4 LIKE LINE OF lt_f4.
  FREE : lt_f4.
  wa_f4-fieldname = 'APPLICATION'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'SIGN'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'TYPE'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'LOW'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'HIGH'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  CALL METHOD gr_alvgrid->register_f4_for_fields
    EXPORTING
      it_f4 = lt_f4[].

ENDFORM.
*---------------------------------------------------------------------*
*       FORM display_audit_alv                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_audit_alv.
  REFRESH: gt_fieldcat, gt_sort.
  add_column: ' ' 'CONTID' 'Mitigating Control'(mc1)
              gt_fieldcat 12 'X'  'X' '' '',

              ' ' 'AUDITOR' 'Reviewer'(mc2)
              gt_fieldcat 12 'X'  'X' '' '',

              ' ' 'AUDITOR_NAME' 'Reviewer Name'(mc3)
              gt_fieldcat 20 'X'  'X' '' '',

              ' ' 'FROM_DATE' 'Period Start'(mc4)
              gt_fieldcat 10 'X'  'X' '' '',

               ' ' 'TO_DATE' 'Period End'(mc5)
              gt_fieldcat 10 'X'  'X' '' '',

               ' ' 'SOD_USR_REV' 'Reviewed SOD User'(mc6)
              gt_fieldcat 12 'X'  'X' '' '',

               ' ' 'SOD_USR_UNREV' 'Unreviewed SOD User'(mc7)
              gt_fieldcat 12 'X'  'X' '' '',

               ' ' 'SOD_ROLE_REV' 'Reviewed SOD Role'(mc8)
              gt_fieldcat 12 'X'  'X' '' '',

               ' ' 'SOD_ROLE_UNREV' 'Unreviewed SOD Role'(mc9)
              gt_fieldcat 12 'X'  'X' '' '',

                ' ' 'CA_USR_REV' 'Reviewed CA User'(m11)
              gt_fieldcat 12 'X'  'X' '' '',

               ' ' 'CA_USR_UNREV' 'Unreviewed CA User'(m14)
              gt_fieldcat 12 'X'  'X' '' '',

              ' ' 'CA_ROLE_REV' 'Reviewed CA Role'(m15)
              gt_fieldcat 12 'X'  'X' '' '',

                ' ' 'CA_ROLE_UNREV' 'Unreviewed CA Role'(m16)
              gt_fieldcat 18 'X'  'X' '' ''.

  PERFORM audit_sort CHANGING gt_sort.

  IF gr_alvgrid_audit IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_ccontainer_audit
      EXPORTING
        container_name              = 'G_AUDIT_ALV'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        others                      = 6.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Creating ALV Grid instance
    CREATE OBJECT gr_alvgrid_audit
      EXPORTING
        i_parent          = gr_ccontainer_audit
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        others            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Preparing layout structure
    PERFORM prepare_layout USING 'M' CHANGING gs_layout .
*functions
    CALL METHOD gr_alvgrid_audit->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
      CHANGING
        it_outtab                     = gt_mcaudit[]
        it_fieldcatalog               = gt_fieldcat
        it_sort                       = gt_sort
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ELSE .
    CALL METHOD gr_alvgrid_audit->set_frontend_fieldcatalog
      EXPORTING
        it_fieldcatalog = gt_fieldcat.

    CALL METHOD gr_alvgrid_audit->refresh_table_display
      EXCEPTIONS
        finished = 1
        OTHERS   = 2.

    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF .

ENDFORM.
*---------------------------------------------------------------------*
*       FORM fill_syscon_header                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM fill_syscon_header.
  DATA: l_busareatext TYPE /psyng/busarea-text.
  IF NOT /psyng/conflict-busarea IS INITIAL.
    PERFORM get_apparea_text USING /psyng/conflict-busarea
                CHANGING l_busareatext.
    g_busareatext = l_busareatext.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_syscon_existing_data                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_syscon_existing_data.
  REFRESH gt_syscon.
  SELECT * FROM /psyng/sw_syscon INTO
  TABLE gt_syscon WHERE
     vrsio = g_sod_vrsio AND
     conid = /psyng/confdet-conid.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM save_syscon_data                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM save_syscon_data.
*  B8622.
  TYPES : BEGIN OF ty_appl,
          appl TYPE /psyng/application,
          sysid TYPE /psyng/system,
          END OF ty_appl.
  DATA : lt_applications TYPE TABLE OF ty_appl.
  DATA : lv_check TYPE c,
         lf_en_installed TYPE flag,
         l_tabname TYPE tabname,
         lv_rfcname TYPE /psyng/rfcname.
*  End.
*if EN installed in system
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
       EXPORTING
            i_module    = 'EN'
       IMPORTING
            e_installed = lf_en_installed.
  CALL METHOD gr_alvgrid->check_changed_data.
*  B8622.
  IF NOT gt_syscon[] IS INITIAL.
    LOOP AT gt_syscon.
      IF lf_en_installed = 'X'.
        IF NOT gt_syscon-sign IS INITIAL .
          IF NOT gt_syscon-sign NE 'I' AND
             NOT gt_syscon-sign NE 'E'.
            MESSAGE i100(/psyng/sw).
            lv_check = 'X'.
            EXIT.
          ENDIF.
        ENDIF.
        IF NOT gt_syscon-type IS INITIAL.
          IF NOT gt_syscon-type EQ 'EQ' AND
             NOT gt_syscon-type EQ 'BT' AND
             NOT gt_syscon-type EQ 'CP' AND
             NOT gt_syscon-type EQ 'NE' AND
             NOT gt_syscon-type EQ 'GE' AND
             NOT gt_syscon-type EQ 'GT' AND
             NOT gt_syscon-type EQ 'LE' AND
             NOT gt_syscon-type EQ 'LT' AND
             NOT gt_syscon-type EQ 'NP'.
            MESSAGE i100(/psyng/sw).
            lv_check = 'X'.
            EXIT.
          ENDIF.
        ENDIF.
        l_tabname = '/PSYNG/EX_SYSHDR'.
        IF NOT gt_syscon-low IS INITIAL.
          SELECT appl sysid FROM (l_tabname) "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
          INTO TABLE lt_applications
          WHERE appl  = gt_syscon-application AND
                sysid = gt_syscon-low.
          IF NOT lt_applications[] IS INITIAL AND
                NOT gt_syscon-high IS INITIAL.
      SELECT appl sysid FROM (l_tabname)  "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
            INTO TABLE lt_applications
            WHERE appl  = gt_syscon-application AND
                  sysid = gt_syscon-high.
          ENDIF.
        ENDIF.
        IF lt_applications[] IS INITIAL.
          IF gt_syscon-application = 'SAP'.
            l_tabname = '/PSYNG/SW_RFCDES'.
            IF NOT gt_syscon-low IS INITIAL.
*           SELECT SINGLE rfcname FROM (l_tabname)"#EC SAST_CI_GEN_CHECK
            SELECT SINGLE rfcname FROM /PSYNG/SW_RFCDES
*HBHALLA VF-SCAN FIX (19/12/24)
             INTO lv_rfcname WHERE
          rfcname = gt_syscon-low.
         IF NOT gt_syscon-high IS INITIAL AND NOT lv_rfcname IS INITIAL.
*           SELECT SINGLE rfcname FROM (l_tabname)"#EC SAST_CI_GEN_CHECK
           SELECT SINGLE rfcname FROM /PSYNG/SW_RFCDES
*HBHALLA VF-SCAN FIX (19/12/24)
             INTO lv_rfcname WHERE
           rfcname = gt_syscon-high.
              ENDIF.
            ENDIF.
            IF lv_rfcname IS INITIAL.
              MESSAGE i100(/psyng/sw).
              lv_check = 'X'.
              EXIT.
            ENDIF.
          ELSE.
            MESSAGE i100(/psyng/sw).
            lv_check = 'X'.
            EXIT.
          ENDIF.
        ENDIF.
      ELSE.
        IF gt_syscon-application = 'SAP'.
          l_tabname = '/PSYNG/SW_RFCDES'.
          IF NOT gt_syscon-low IS INITIAL.
*           SELECT SINGLE rfcname FROM (l_tabname)"#EC SAST_CI_GEN_CHECK
           SELECT SINGLE rfcname FROM /PSYNG/SW_RFCDES
*HBHALLA VF-SCAN FIX (19/12/24)
              INTO lv_rfcname WHERE
           rfcname = gt_syscon-low.
         IF NOT gt_syscon-high IS INITIAL AND NOT lv_rfcname IS INITIAL.
*           SELECT SINGLE rfcname FROM (l_tabname)"#EC SAST_CI_GEN_CHECK
           SELECT SINGLE rfcname FROM /PSYNG/SW_RFCDES
*HBHALLA VF-SCAN FIX (19/12/24)
              INTO lv_rfcname WHERE
           rfcname = gt_syscon-high.
            ENDIF.
          ENDIF.
          IF lv_rfcname IS INITIAL.
            MESSAGE i100(/psyng/sw).
            lv_check = 'X'.
            EXIT.
          ENDIF.
        ELSE.
          MESSAGE i100(/psyng/sw).
          lv_check = 'X'.
          EXIT.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.
  IF lv_check = ' '.
* End.
    LOOP AT gt_syscon.
      gt_syscon-vrsio = g_sod_vrsio.
      gt_syscon-conid = /psyng/confdet-conid.
      MODIFY gt_syscon TRANSPORTING vrsio conid.
    ENDLOOP.
    SORT  gt_syscon.
    DELETE ADJACENT DUPLICATES FROM gt_syscon COMPARING ALL FIELDS.

    DELETE FROM /psyng/sw_syscon
    WHERE vrsio = g_sod_vrsio
    AND   conid = /psyng/confdet-conid.

    DELETE gt_syscon WHERE conid EQ space.
    MODIFY /psyng/sw_syscon FROM TABLE gt_syscon.
    COMMIT WORK.
    MESSAGE s039(/psyng/basis).
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM display_funfltr_alv                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_funfltr_alv.
  REFRESH: gt_fieldcat, gt_sort.
  add_column: ' ' 'APPLICATION' 'Application'(z01)
              gt_fieldcat 20 'X'  'X' '' '',

              ' ' 'SIGN' 'Sign'(z02)
              gt_fieldcat 5 'X'  'X' '' '',

              ' ' 'TYPE' 'Option'(z03)
              gt_fieldcat 7 'X'  'X' '' '',

              ' ' 'LOW' 'Low'(z04)
              gt_fieldcat 20 'X'  'X' '' '',

              ' ' 'HIGH' 'High'(z05)
              gt_fieldcat 20 'X'  'X' '' ''.

  IF gf_dispchg1 = 'D'.
    LOOP AT gt_fieldcat ASSIGNING <fcat>.
      CLEAR <fcat>-edit.
    ENDLOOP.
  ENDIF.
  PERFORM fun_sort CHANGING gt_sort.
  IF gr_alvgrid_fun IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_ccontainer_fun
      EXPORTING
        container_name              = 'FUN_FLTR_ALV'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        others                      = 6.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Creating ALV Grid instance
    CREATE OBJECT gr_alvgrid_fun
      EXPORTING
        i_parent          = gr_ccontainer_fun
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        others            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Preparing layout structure
*    gs_layout-zebra = 'X'.

    PERFORM prepare_layout USING 'F' CHANGING gs_layout .
    SET HANDLER gr_event_handler_fun->handle_toolbar
                                         FOR gr_alvgrid_fun.
    SET HANDLER gr_event_handler_fun->handle_user_command
                                          FOR gr_alvgrid_fun.
    SET HANDLER gr_event_handler_fun->handle_on_f4 FOR gr_alvgrid_fun .


*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
    CALL METHOD gr_alvgrid_fun->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
      CHANGING
        it_outtab                     = gt_sysfun[]
        it_fieldcatalog               = gt_fieldcat
        it_sort                       = gt_sort
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ELSE .
    CALL METHOD gr_alvgrid_fun->set_frontend_fieldcatalog
      EXPORTING
        it_fieldcatalog = gt_fieldcat.

    CALL METHOD gr_alvgrid_fun->refresh_table_display
      EXCEPTIONS
        finished = 1
        OTHERS   = 2.

    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF .

*--Set f4 enabled fields (Sorted Table!!)
  DATA: lt_f4 TYPE lvc_t_f4 WITH HEADER LINE ,
        wa_f4 LIKE LINE OF lt_f4.
  FREE : lt_f4.
  wa_f4-fieldname = 'APPLICATION'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'SIGN'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'TYPE'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'LOW'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'HIGH'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  CALL METHOD gr_alvgrid_fun->register_f4_for_fields
    EXPORTING
      it_f4 = lt_f4[].
ENDFORM.

*---------------------------------------------------------------------*
*       FORM fill_sysfun_header                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM fill_sysfun_header.
  DATA i_busareatext TYPE /psyng/busarea-text.
  CLEAR g_app_text.
  IF NOT /psyng/function-busarea IS INITIAL.
    g_fun_description = /psyng/function-description.
    PERFORM get_apparea_text USING /psyng/function-busarea
               CHANGING i_busareatext.
    g_app_text =   i_busareatext.
    /psyng/functtran-vrsio = g_sod_vrsio.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_sysfun_existing_data                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_sysfun_existing_data.
  REFRESH gt_sysfun.
  SELECT * FROM /psyng/sw_sysfun INTO
  TABLE gt_sysfun WHERE
     vrsio    = g_sod_vrsio AND
     function = /psyng/functtran-functionid.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM display_cafltr_alv                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_cafltr_alv.
  REFRESH: gt_fieldcat, gt_sort.
  add_column: ' ' 'APPLICATION' 'Application'(z01)
              gt_fieldcat 20 'X'  'X' '' '',

              ' ' 'SIGN' 'Sign'(z02)
              gt_fieldcat 5 'X'  'X' '' '',

              ' ' 'TYPE' 'Option'(z03)
              gt_fieldcat 7 'X'  'X' '' '',

              ' ' 'LOW' 'Low'(z04)
              gt_fieldcat 20 'X'  'X' '' '',

              ' ' 'HIGH' 'High'(z05)
              gt_fieldcat 20 'X'  'X' '' ''.

  IF gf_dispchg1 = 'D'.
    LOOP AT gt_fieldcat ASSIGNING <fcat>.
      CLEAR <fcat>-edit.
    ENDLOOP.
  ENDIF.
  PERFORM fun_sort CHANGING gt_sort.

  IF gr_alvgrid_ca IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_ccontainer_ca
      EXPORTING
        container_name              = 'SYS_AUTH_ALV'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        others                      = 6.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Creating ALV Grid instance
    CREATE OBJECT gr_alvgrid_ca
      EXPORTING
        i_parent          = gr_ccontainer_ca
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        others            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Preparing layout structure
    PERFORM prepare_layout USING 'A' CHANGING gs_layout .

    SET HANDLER gr_event_handler_ca->handle_toolbar FOR gr_alvgrid_ca.
    SET HANDLER gr_event_handler_ca->handle_user_command
                                                FOR gr_alvgrid_ca.
    SET HANDLER gr_event_handler_ca->handle_on_f4
                                               FOR gr_alvgrid_ca.

*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
    CALL METHOD gr_alvgrid_ca->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
      CHANGING
        it_outtab                     = gt_sysca[]
        it_fieldcatalog               = gt_fieldcat
        it_sort                       = gt_sort
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ELSE .
    CALL METHOD gr_alvgrid_ca->set_frontend_fieldcatalog
      EXPORTING
        it_fieldcatalog = gt_fieldcat.

    CALL METHOD gr_alvgrid_ca->refresh_table_display
      EXCEPTIONS
        finished = 1
        OTHERS   = 2.

    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF .

*--Set f4 enabled fields (Sorted Table!!)
  DATA: lt_f4 TYPE lvc_t_f4 WITH HEADER LINE ,
        wa_f4 LIKE LINE OF lt_f4.
  FREE : lt_f4.
  wa_f4-fieldname = 'APPLICATION'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'SIGN'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'TYPE'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'LOW'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'HIGH'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  CALL METHOD gr_alvgrid_ca->register_f4_for_fields
    EXPORTING
      it_f4 = lt_f4[].

ENDFORM.

*---------------------------------------------------------------------*
*       FORM fill_sysca_header                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM fill_sysca_header.
  DATA e_busareatext TYPE /psyng/busarea-text.
  PERFORM get_apparea_text USING /psyng/swaudhdr-busarea
                CHANGING e_busareatext.
  g_app_text = e_busareatext.
  g_cricauth_text = /psyng/swaudhdr-description.
  /psyng/swaudc2-vrsio = g_sod_vrsio.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_sysca_existing_data                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_sysca_existing_data.
  REFRESH gt_sysca.
  SELECT * FROM /psyng/sw_sysca INTO
  TABLE gt_sysca WHERE
     vrsio    = g_sod_vrsio AND
     swaudid  = /psyng/swaudc2-swaudid.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM display_funfltr_alv                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_tcdfltr_alv.
  REFRESH: gt_fieldcat, gt_sort.
  add_column: ' ' 'SIGN' 'Sign'(z02)
              gt_fieldcat 5 'X'  'X' '' '',

              ' ' 'TYPE' 'Option'(z03)
              gt_fieldcat 7 'X'  'X' '' '',

              ' ' 'LOW' 'Low'(z04)
              gt_fieldcat 20 'X'  'X' '' '',

              ' ' 'HIGH' 'High'(z05)
              gt_fieldcat 20 'X'  'X' '' ''.

  IF gf_dispchg1 = 'D'.
    LOOP AT gt_fieldcat ASSIGNING <fcat>.
      CLEAR <fcat>-edit.
    ENDLOOP.
  ENDIF.
  PERFORM tcd_sort CHANGING gt_sort.
  IF gr_alvgrid_tcd IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_ccontainer_tcd
      EXPORTING
        container_name              = 'CRIT_TRANS_ALV'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        others                      = 6.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Creating ALV Grid instance
    CREATE OBJECT gr_alvgrid_tcd
      EXPORTING
        i_parent          = gr_ccontainer_tcd
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        others            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Preparing layout structure
    PERFORM prepare_layout USING 'T' CHANGING gs_layout .

    SET HANDLER gr_event_handler_tcd->handle_toolbar FOR gr_alvgrid_tcd.
    SET HANDLER gr_event_handler_tcd->handle_user_command
                                                  FOR gr_alvgrid_tcd.
    SET HANDLER gr_event_handler_tcd->handle_on_f4 FOR
                                               gr_alvgrid_tcd.
*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
    CALL METHOD gr_alvgrid_tcd->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
      CHANGING
        it_outtab                     = gt_systcd[]
        it_fieldcatalog               = gt_fieldcat
        it_sort                       = gt_sort
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ELSE .
    CALL METHOD gr_alvgrid_tcd->set_frontend_fieldcatalog
      EXPORTING
        it_fieldcatalog = gt_fieldcat.

    CALL METHOD gr_alvgrid_tcd->refresh_table_display
      EXCEPTIONS
        finished = 1
        OTHERS   = 2.

    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF .
*--Set f4 enabled fields (Sorted Table!!)
  DATA: lt_f4 TYPE lvc_t_f4 WITH HEADER LINE ,
        wa_f4 LIKE LINE OF lt_f4.
  FREE : lt_f4.
  wa_f4-fieldname = 'SIGN'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'TYPE'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'LOW'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'HIGH'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  CALL METHOD gr_alvgrid_tcd->register_f4_for_fields
    EXPORTING
      it_f4 = lt_f4[].

ENDFORM.

*---------------------------------------------------------------------*
*       FORM fill_sysfun_header                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM fill_systcd_header.
  DATA e_busareatext TYPE /psyng/busarea-text.
  tstct-tcode = wa_trans_itab-tcode.
  tstct-ttext = wa_trans_itab-ttext.
  PERFORM get_apparea_text USING wa_trans_itab-busarea
               CHANGING e_busareatext.
  g_app_text = e_busareatext.
  g_imp      = wa_trans_itab-imp.
  /psyng/functtran-vrsio = g_sod_vrsio.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_sysfun_existing_data                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_systcd_existing_data.

  REFRESH gt_systcd.

  SELECT * FROM /psyng/sw_systcd INTO
  TABLE gt_systcd WHERE
       vrsio = g_sod_vrsio AND
       tcode = wa_trans_itab-tcode.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_apparea_text                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_BUSAREA                                                     *
*  -->  E_BUSAREATEXT                                                 *
*---------------------------------------------------------------------*
FORM get_apparea_text USING
              i_busarea TYPE /psyng/conflict-busarea
               CHANGING e_busareatext TYPE /psyng/busarea-text.

  SELECT SINGLE text FROM /psyng/busarea INTO
       e_busareatext WHERE
             busarea = i_busarea.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM save_sysfun_data                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM save_sysfun_data.
*  B8622.
  TYPES : BEGIN OF ty_appl,
          appl TYPE /psyng/application,
          sysid TYPE /psyng/system,
          END OF ty_appl.
  DATA : lt_applications TYPE TABLE OF ty_appl.
  DATA : lv_check TYPE c,
         lf_en_installed TYPE flag,
         l_tabname TYPE tabname,
         lv_rfcname TYPE /psyng/rfcname.
*  End.
*if EN installed in system
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
       EXPORTING
            i_module    = 'EN'
       IMPORTING
            e_installed = lf_en_installed.
  CALL METHOD gr_alvgrid_fun->check_changed_data.
*  B8622.
  IF NOT gt_sysfun[] IS INITIAL.
    LOOP AT gt_sysfun.
      IF lf_en_installed = 'X'.
        IF NOT gt_sysfun-sign IS INITIAL .
          IF NOT gt_sysfun-sign EQ 'I' AND
             NOT gt_sysfun-sign EQ 'E'.
            MESSAGE i100(/psyng/sw).
            lv_check = 'X'.
            EXIT.
          ENDIF.
        ENDIF.

        IF NOT gt_sysfun-type IS INITIAL.
          IF NOT gt_sysfun-type EQ 'EQ' AND
             NOT gt_sysfun-type EQ 'BT' AND
             NOT gt_sysfun-type EQ 'CP' AND
             NOT gt_sysfun-type EQ 'NE' AND
             NOT gt_sysfun-type EQ 'GE' AND
             NOT gt_sysfun-type EQ 'GT' AND
             NOT gt_sysfun-type EQ 'LE' AND
             NOT gt_sysfun-type EQ 'LT' AND
             NOT gt_sysfun-type EQ 'NP'.
            MESSAGE i100(/psyng/sw).
            lv_check = 'X'.
            EXIT.
          ENDIF.
        ENDIF.
        l_tabname = '/PSYNG/EX_SYSHDR'.
        IF NOT gt_sysfun-low IS INITIAL.
     SELECT appl sysid FROM (l_tabname)  "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
          INTO TABLE lt_applications
          WHERE appl  = gt_sysfun-application AND
                sysid = gt_sysfun-low.
  IF NOT lt_applications[] IS INITIAL AND NOT gt_sysfun-high IS INITIAL.
      SELECT appl sysid FROM (l_tabname)  "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
            INTO TABLE lt_applications
            WHERE appl  = gt_sysfun-application AND
                  sysid = gt_sysfun-high.
          ENDIF.
        ENDIF.
        IF lt_applications[] IS INITIAL.
          IF gt_sysfun-application = 'SAP'.
            l_tabname = '/PSYNG/SW_RFCDES'.
            IF NOT gt_sysfun-low IS INITIAL.
*           SELECT SINGLE rfcname FROM (l_tabname)
           SELECT SINGLE rfcname FROM /PSYNG/SW_RFCDES
*HBHALLA VF-SCAN FIX (19/12/24)
             INTO lv_rfcname WHERE
           rfcname = gt_sysfun-low.
         IF NOT gt_sysfun-high IS INITIAL AND NOT lv_rfcname IS INITIAL.
*           SELECT SINGLE rfcname FROM (l_tabname)"#EC SAST_CI_GEN_CHECK
           SELECT SINGLE rfcname FROM /PSYNG/SW_RFCDES
*HBHALLA VF-SCAN FIX (19/12/24)
              INTO lv_rfcname WHERE
           rfcname = gt_sysfun-high.
              ENDIF.
            ENDIF.
            IF lv_rfcname IS INITIAL.
              MESSAGE i100(/psyng/sw).
              lv_check = 'X'.
              EXIT.
            ENDIF.
          ELSE.
            MESSAGE i100(/psyng/sw).
            lv_check = 'X'.
            EXIT.
          ENDIF.
        ENDIF.
      ELSE.
        IF gt_sysfun-application = 'SAP'.
          l_tabname = '/PSYNG/SW_RFCDES'.
          IF NOT gt_sysfun-low IS INITIAL.
*           SELECT SINGLE rfcname FROM (l_tabname)"#EC SAST_CI_GEN_CHECK
           SELECT SINGLE rfcname FROM /PSYNG/SW_RFCDES
*HBHALLA VF-SCAN FIX (19/12/24)
             INTO lv_rfcname WHERE
           rfcname = gt_sysfun-low.
         IF NOT gt_sysfun-high IS INITIAL AND NOT lv_rfcname IS INITIAL.
*           SELECT SINGLE rfcname FROM (l_tabname)"#EC SAST_CI_GEN_CHECK
           SELECT SINGLE rfcname FROM /PSYNG/SW_RFCDES
*HBHALLA VF-SCAN FIX (19/12/24)
              INTO lv_rfcname WHERE
          rfcname = gt_sysfun-high.
            ENDIF.
          ENDIF.
          IF lv_rfcname IS INITIAL.
            MESSAGE i100(/psyng/sw).
            lv_check = 'X'.
            EXIT.
          ENDIF.
        ELSE.
          MESSAGE i100(/psyng/sw).
          lv_check = 'X'.
          EXIT.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.
  IF lv_check = ' '.
* End.
    LOOP AT gt_sysfun.
      gt_sysfun-vrsio = g_sod_vrsio.
      gt_sysfun-function = /psyng/functtran-functionid.
      MODIFY gt_sysfun TRANSPORTING vrsio function.
    ENDLOOP.
    SORT  gt_sysfun.
    DELETE ADJACENT DUPLICATES FROM gt_sysfun COMPARING ALL FIELDS.

    DELETE FROM /psyng/sw_sysfun
    WHERE vrsio = g_sod_vrsio
    AND   function = /psyng/functtran-functionid.

    DELETE gt_sysfun WHERE function EQ space.
    MODIFY /psyng/sw_sysfun FROM TABLE gt_sysfun.
    COMMIT WORK.
    MESSAGE s039(/psyng/basis).
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM save_sysca_data                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM save_sysca_data.
*  B8622.
  TYPES : BEGIN OF ty_appl,
          appl TYPE /psyng/application,
          sysid TYPE /psyng/system,
          END OF ty_appl.
  DATA : lt_applications TYPE TABLE OF ty_appl.
  DATA : lv_check TYPE c,
         lf_en_installed TYPE flag,
         l_tabname TYPE tabname,
         lv_rfcname TYPE /psyng/rfcname.
*if EN installed in system
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
       EXPORTING
            i_module    = 'EN'
       IMPORTING
            e_installed = lf_en_installed.
  CALL METHOD gr_alvgrid_ca->check_changed_data.
  IF NOT gt_sysca[] IS INITIAL.
    LOOP AT gt_sysca.
      IF lf_en_installed = 'X'.
        IF NOT gt_sysca-sign IS INITIAL .
          IF NOT gt_sysca-sign EQ 'I' AND
             NOT gt_sysca-sign EQ 'E'.
            MESSAGE i100(/psyng/sw).
            lv_check = 'X'.
            EXIT.
          ENDIF.
        ENDIF.
        IF NOT gt_sysca-type IS INITIAL.
          IF NOT gt_sysca-type EQ 'EQ' AND
             NOT gt_sysca-type EQ 'BT' AND
             NOT gt_sysca-type EQ 'CP' AND
             NOT gt_sysca-type EQ 'NE' AND
             NOT gt_sysca-type EQ 'GE' AND
             NOT gt_sysca-type EQ 'GT' AND
             NOT gt_sysca-type EQ 'LE' AND
             NOT gt_sysca-type EQ 'LT' AND
             NOT gt_sysca-type EQ 'NP'.
            MESSAGE i100(/psyng/sw).
            lv_check = 'X'.
            EXIT.
          ENDIF.
        ENDIF.
        l_tabname = '/PSYNG/EX_SYSHDR'.
        IF NOT gt_sysca-low IS INITIAL.
    SELECT appl sysid FROM (l_tabname) "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
          INTO TABLE lt_applications
          WHERE appl  = gt_sysca-application AND
                sysid = gt_sysca-low.
          IF NOT lt_applications[] IS INITIAL AND
            NOT gt_sysca-high IS INITIAL.
    SELECT appl sysid FROM (l_tabname) "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
            INTO TABLE lt_applications
            WHERE appl  = gt_sysca-application AND
                  sysid = gt_sysca-high.
          ENDIF.
        ENDIF.
        IF lt_applications[] IS INITIAL.
          IF gt_sysca-application = 'SAP'.
            l_tabname = '/PSYNG/SW_RFCDES'.
            IF NOT gt_sysca-low IS INITIAL.
*           SELECT SINGLE rfcname FROM (l_tabname)"#EC SAST_CI_GEN_CHECK
           SELECT SINGLE rfcname FROM /PSYNG/SW_RFCDES
*HBHALLA VF-SCAN FIX (19/12/24)
              INTO lv_rfcname WHERE
           rfcname = gt_sysca-low.
          IF NOT gt_sysca-high IS INITIAL AND NOT lv_rfcname IS INITIAL.
*           SELECT SINGLE rfcname FROM (l_tabname)"#EC SAST_CI_GEN_CHECK
           SELECT SINGLE rfcname FROM /PSYNG/SW_RFCDES
*HBHALLA VF-SCAN FIX (19/12/24)
              INTO lv_rfcname WHERE
           rfcname = gt_sysca-high.
              ENDIF.
            ENDIF.
            IF lv_rfcname IS INITIAL.
              MESSAGE i100(/psyng/sw).
              lv_check = 'X'.
              EXIT.
            ENDIF.
          ELSE.
            MESSAGE i100(/psyng/sw).
            lv_check = 'X'.
            EXIT.
          ENDIF.
        ENDIF.
      ELSE.
        IF gt_sysca-application = 'SAP'.
          l_tabname = '/PSYNG/SW_RFCDES'.
          IF NOT gt_sysca-low IS INITIAL.
*           SELECT SINGLE rfcname FROM (l_tabname)"#EC SAST_CI_GEN_CHECK
           SELECT SINGLE rfcname FROM /PSYNG/SW_RFCDES
*HBHALLA VF-SCAN FIX (19/12/24)
              INTO lv_rfcname WHERE
           rfcname = gt_sysca-low.
          IF NOT gt_sysca-high IS INITIAL AND NOT lv_rfcname IS INITIAL.
*           SELECT SINGLE rfcname FROM (l_tabname)"#EC SAST_CI_GEN_CHECK
           SELECT SINGLE rfcname FROM /PSYNG/SW_RFCDES
*HBHALLA VF-SCAN FIX (19/12/24)
              INTO lv_rfcname WHERE
           rfcname = gt_sysca-high.
            ENDIF.
          ENDIF.
          IF lv_rfcname IS INITIAL.
            MESSAGE i100(/psyng/sw).
            lv_check = 'X'.
            EXIT.
          ENDIF.
        ELSE.
          MESSAGE i100(/psyng/sw).
          lv_check = 'X'.
          EXIT.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.
  IF lv_check = ' '.
* End.
*  CALL METHOD gr_alvgrid_ca->check_changed_data.
    LOOP AT gt_sysca.
      gt_sysca-vrsio = g_sod_vrsio.
      gt_sysca-swaudid = /psyng/swaudc2-swaudid.
      MODIFY gt_sysca TRANSPORTING vrsio swaudid.
    ENDLOOP.
    SORT  gt_sysca.
    DELETE ADJACENT DUPLICATES FROM gt_sysca COMPARING ALL FIELDS.

    DELETE FROM /psyng/sw_sysca
    WHERE vrsio = g_sod_vrsio
    AND   swaudid = /psyng/swaudc2-swaudid.

    DELETE gt_sysca WHERE swaudid EQ space.
    MODIFY /psyng/sw_sysca FROM TABLE gt_sysca.
    COMMIT WORK.
    MESSAGE s039(/psyng/basis).
  ENDIF.
ENDFORM.


*---------------------------------------------------------------------*
*       FORM save_systcd_data                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM save_systcd_data.
*B8622.
  DATA : lv_check TYPE c,
         lf_en_installed TYPE flag,
         l_tabname TYPE tabname,
         lv_rfcname TYPE /psyng/rfcname.

*if EN installed in system
*  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
*       EXPORTING
*            i_module    = 'EN'
*       IMPORTING
*            e_installed = lf_en_installed.

  CALL METHOD gr_alvgrid_tcd->check_changed_data.
  IF NOT gt_systcd[] IS INITIAL.
    LOOP AT gt_systcd.
*      IF lf_en_installed = 'X'.
      IF NOT gt_systcd-sign IS INITIAL .
        IF NOT gt_systcd-sign EQ 'I' AND
           NOT gt_systcd-sign EQ 'E'.
          MESSAGE i100(/psyng/sw).
          lv_check = 'X'.
          EXIT.
        ENDIF.
      ENDIF.
      IF NOT gt_systcd-type IS INITIAL.
        IF NOT gt_systcd-type EQ 'EQ' AND
           NOT gt_systcd-type EQ 'BT' AND
           NOT gt_systcd-type EQ 'CP' AND
           NOT gt_systcd-type EQ 'NE' AND
           NOT gt_systcd-type EQ 'GE' AND
           NOT gt_systcd-type EQ 'GT' AND
           NOT gt_systcd-type EQ 'LE' AND
           NOT gt_systcd-type EQ 'LT' AND
           NOT gt_systcd-type EQ 'NP'.
          MESSAGE i100(/psyng/sw).
          lv_check = 'X'.
          EXIT.
        ENDIF.
      ENDIF.
      l_tabname = '/PSYNG/SW_RFCDES'.
      IF NOT gt_systcd-low IS INITIAL.
*        SELECT SINGLE rfcname FROM (l_tabname)"#EC SAST_CI_GEN_CHECK
        SELECT SINGLE rfcname FROM /PSYNG/SW_RFCDES
*HBHALLA VF-SCAN FIX (19/12/24)
           INTO lv_rfcname WHERE
        rfcname = gt_systcd-low.
        IF NOT gt_systcd-high IS INITIAL AND NOT lv_rfcname IS INITIAL.
*          SELECT SINGLE rfcname FROM (l_tabname)"#EC SAST_CI_GEN_CHECK
          SELECT SINGLE rfcname FROM /PSYNG/SW_RFCDES
*HBHALLA VF-SCAN FIX (19/12/24)
             INTO lv_rfcname WHERE
           rfcname = gt_systcd-high.
        ENDIF.
      ENDIF.
      IF lv_rfcname IS INITIAL.
        MESSAGE i100(/psyng/sw).
        lv_check = 'X'.
        EXIT.
      ENDIF.
*      ENDIF.
    ENDLOOP.
  ENDIF.
  IF lv_check IS INITIAL.
* END.
    LOOP AT gt_systcd.
      gt_systcd-vrsio = g_sod_vrsio.
      gt_systcd-tcode = wa_trans_itab-tcode.
      MODIFY gt_systcd TRANSPORTING vrsio tcode.
    ENDLOOP.
    SORT  gt_systcd.
    DELETE ADJACENT DUPLICATES FROM gt_systcd COMPARING ALL FIELDS.

    DELETE FROM /psyng/sw_systcd
    WHERE vrsio = g_sod_vrsio
    AND   tcode = wa_trans_itab-tcode.

    DELETE gt_systcd WHERE tcode EQ space.
    MODIFY /psyng/sw_systcd FROM TABLE gt_systcd.
    COMMIT WORK.
*    B8624.
    MESSAGE s039(/psyng/basis).
*   END.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM f4_help                                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_FIELDNAME                                                   *
*  -->  IS_ROW_NO                                                     *
*---------------------------------------------------------------------*
FORM f4_help USING    i_fieldname TYPE lvc_fname
                      is_row_no TYPE lvc_s_roid.

  DATA: BEGIN OF lt_values OCCURS 0,
            line(255) TYPE c,
          END OF lt_values.
  DATA: lt_return    TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_fields    TYPE TABLE OF dfies      WITH HEADER LINE,
        l_installed TYPE /psyng/bapiflagx,
        lt_rfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
        l_app TYPE /psyng/sw_sysfun-application,
        l_tabname  TYPE tabname.
  FIELD-SYMBOLS: <wa_fun> LIKE LINE OF gt_sysfun,
                 <wa_con> LIKE LINE OF gt_syscon,
                 <wa_ca> LIKE LINE OF gt_sysca,
                 <wa_tcd> LIKE LINE OF gt_systcd.

  CASE sy-dynnr.
    WHEN '0908'.
      READ TABLE gt_syscon ASSIGNING <wa_con> INDEX is_row_no-row_id.
      l_app = <wa_con>-application.
    WHEN '0909'.
      READ TABLE gt_sysfun ASSIGNING <wa_fun> INDEX is_row_no-row_id.
      l_app = <wa_fun>-application.
    WHEN '0910'.
      READ TABLE gt_sysca ASSIGNING <wa_ca> INDEX is_row_no-row_id.
      l_app = <wa_ca>-application.
    WHEN '0911'.
      READ TABLE gt_systcd ASSIGNING <wa_tcd> INDEX is_row_no-row_id.
  ENDCASE.
*if EN installed in system
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
       EXPORTING
            i_module    = 'EN'
       IMPORTING
            e_installed = l_installed.

  CASE i_fieldname.
    WHEN 'APPLICATION'.
      IF l_installed = 'X'.
        l_tabname = '/PSYNG/EX_SYSHDR'.
        DATA : BEGIN OF lt_syshdr OCCURS 0,
          mandt  TYPE	mandt,
          appl   TYPE	/psyng/application,
          sysid  TYPE	/psyng/system,
          sdesc  TYPE	/psyng/system_desc,
        END OF lt_syshdr.

        SELECT * FROM (l_tabname)  "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
           INTO CORRESPONDING FIELDS OF
            TABLE lt_syshdr .                           "#EC CI_NOWHERE
        SORT lt_syshdr BY appl.
        DELETE ADJACENT DUPLICATES FROM lt_syshdr COMPARING appl.
        LOOP AT lt_syshdr.
          lt_values-line = lt_syshdr-appl.
          APPEND lt_values.
        ENDLOOP.
      ENDIF.
      lt_values-line = 'SAP'.
      APPEND lt_values.

      lt_fields-tabname   = '/PSYNG/SW_SYSFUN'.
      lt_fields-fieldname = 'APPLICATION'.
      APPEND lt_fields.

      CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
           EXPORTING
                retfield        = 'APPLICATION'
           TABLES
                value_tab       = lt_values
                field_tab       = lt_fields
                return_tab      = lt_return
           EXCEPTIONS
                parameter_error = 1
                no_values_found = 2
                OTHERS          = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.


      IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL
              AND gf_dispchg1 = gc_change.
        READ TABLE lt_return INDEX 1.
        CASE sy-dynnr.
          WHEN '0908'.
            <wa_con>-application = lt_return-fieldval.
            CALL METHOD gr_alvgrid->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.

          WHEN '0909'.
            <wa_fun>-application = lt_return-fieldval.
            CALL METHOD gr_alvgrid_fun->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.

          WHEN '0910'.
            <wa_ca>-application = lt_return-fieldval.
            CALL METHOD gr_alvgrid_ca->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.
        ENDCASE.
      ENDIF.
    WHEN 'SIGN'.

      lt_values-line = 'I'.
      APPEND lt_values.
      lt_values-line = 'E'.
      APPEND lt_values.

      lt_fields-tabname   = '/PSYNG/SW_SYSFUN'.
      lt_fields-fieldname = 'SIGN'.
      APPEND lt_fields.

      CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
           EXPORTING
                retfield        = 'SIGN'
           TABLES
                value_tab       = lt_values
                field_tab       = lt_fields
                return_tab      = lt_return
           EXCEPTIONS
                parameter_error = 1
                no_values_found = 2
                OTHERS          = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL
              AND gf_dispchg1 = gc_change.
        READ TABLE lt_return INDEX 1.
        CASE sy-dynnr.
          WHEN '0908'.
            <wa_con>-sign = lt_return-fieldval.
            CALL METHOD gr_alvgrid->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.

          WHEN '0909'.
            <wa_fun>-sign = lt_return-fieldval.
            CALL METHOD gr_alvgrid_fun->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.

          WHEN '0910'.
            <wa_ca>-sign = lt_return-fieldval.
            CALL METHOD gr_alvgrid_ca->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.

          WHEN '0911'.
            <wa_tcd>-sign = lt_return-fieldval.
            CALL METHOD gr_alvgrid_tcd->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.
        ENDCASE.
      ENDIF.
    WHEN 'TYPE'.

      lt_values-line = 'EQ'.
      APPEND lt_values.
      lt_values-line = 'BT'.
      APPEND lt_values.
      lt_values-line = 'CP'.
      APPEND lt_values.
      lt_values-line = 'NE'.
      APPEND lt_values.
      lt_values-line = 'GE'.
      APPEND lt_values.
      lt_values-line = 'GT'.
      APPEND lt_values.
      lt_values-line = 'LE'.
      APPEND lt_values.
      lt_values-line = 'LT'.
      APPEND lt_values.
      lt_values-line = 'NP'.
      APPEND lt_values.

      lt_fields-tabname   = '/PSYNG/SW_SYSFUN'.
      lt_fields-fieldname = 'TYPE'.
      APPEND lt_fields.

      CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
           EXPORTING
                retfield        = 'TYPE'
           TABLES
                value_tab       = lt_values
                field_tab       = lt_fields
                return_tab      = lt_return
           EXCEPTIONS
                parameter_error = 1
                no_values_found = 2
                OTHERS          = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL
              AND gf_dispchg1 = gc_change.
        READ TABLE lt_return INDEX 1.
        CASE sy-dynnr.
          WHEN '0908'.
            <wa_con>-type = lt_return-fieldval.
            CALL METHOD gr_alvgrid->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.

          WHEN '0909'.
            <wa_fun>-type = lt_return-fieldval.
            CALL METHOD gr_alvgrid_fun->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.

          WHEN '0910'.
            <wa_ca>-type = lt_return-fieldval.
            CALL METHOD gr_alvgrid_ca->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.

          WHEN '0911'.
            <wa_tcd>-type = lt_return-fieldval.
            CALL METHOD gr_alvgrid_tcd->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.
        ENDCASE.
      ENDIF.

    WHEN 'LOW'.
      REFRESH lt_rfcdes.

      IF l_app = 'SAP' OR sy-dynnr = '0911'.
        SELECT * FROM /psyng/sw_rfcdes INTO TABLE
        lt_rfcdes.                                      "#EC CI_NOWHERE

        LOOP AT lt_rfcdes.
          lt_values-line = lt_rfcdes-rfcdest.
          APPEND lt_values.
          lt_values-line = lt_rfcdes-rfcname.
          APPEND lt_values.
          lt_values-line = lt_rfcdes-description.
          APPEND lt_values.
        ENDLOOP.
        lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
        lt_fields-fieldname = 'RFCDEST'.
        APPEND lt_fields.

        lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
        lt_fields-fieldname = 'RFCNAME'.
        APPEND lt_fields.

        lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
        lt_fields-fieldname = 'DESCRIPTION'.
        APPEND lt_fields.

        CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
             EXPORTING
                  retfield        = 'RFCNAME'
             TABLES
                  value_tab       = lt_values
                  field_tab       = lt_fields
                  return_tab      = lt_return
             EXCEPTIONS
                  parameter_error = 1
                  no_values_found = 2
                  OTHERS          = 3.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

      ELSE.
        IF l_installed = 'X'.
          REFRESH lt_syshdr.
          l_tabname = '/PSYNG/EX_SYSHDR'.
   SELECT * FROM (l_tabname)  INTO TABLE "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
                    lt_syshdr WHERE appl = l_app.
          LOOP AT lt_syshdr .
            lt_values-line = lt_syshdr-appl.
            APPEND lt_values.
            lt_values-line = lt_syshdr-sysid.
            APPEND lt_values.
            lt_values-line = lt_syshdr-sdesc.
            APPEND lt_values.
          ENDLOOP.

          lt_fields-tabname   = '/PSYNG/EX_SYSHDR'.
          lt_fields-fieldname = 'APPL'.
          APPEND lt_fields.

          lt_fields-tabname   = '/PSYNG/EX_SYSHDR'.
          lt_fields-fieldname = 'SYSID'.
          APPEND lt_fields.

          lt_fields-tabname   = '/PSYNG/EX_SYSHDR'.
          lt_fields-fieldname = 'SDESC'.
          APPEND lt_fields.

          CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
               EXPORTING
                    retfield        = 'SYSID'
               TABLES
                    value_tab       = lt_values
                    field_tab       = lt_fields
                    return_tab      = lt_return
               EXCEPTIONS
                    parameter_error = 1
                    no_values_found = 2
                    OTHERS          = 3.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
        ENDIF.
      ENDIF.

      IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL
              AND gf_dispchg1 = gc_change.
        READ TABLE lt_return INDEX 1.
        CASE sy-dynnr.
          WHEN '0908'.
            <wa_con>-low = lt_return-fieldval.
            CALL METHOD gr_alvgrid->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.

          WHEN '0909'.
            <wa_fun>-low = lt_return-fieldval.
            CALL METHOD gr_alvgrid_fun->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.

          WHEN '0910'.
            <wa_ca>-low = lt_return-fieldval.
            CALL METHOD gr_alvgrid_ca->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.

          WHEN '0911'.
            <wa_tcd>-low = lt_return-fieldval.
            CALL METHOD gr_alvgrid_tcd->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.
        ENDCASE.
      ENDIF.

    WHEN 'HIGH'.
      REFRESH lt_rfcdes.

      IF l_app = 'SAP' OR sy-dynnr = '0911'.
        SELECT * FROM /psyng/sw_rfcdes INTO TABLE
        lt_rfcdes.                                      "#EC CI_NOWHERE

        LOOP AT lt_rfcdes.
          lt_values-line = lt_rfcdes-rfcdest.
          APPEND lt_values.
          lt_values-line = lt_rfcdes-rfcname.
          APPEND lt_values.
          lt_values-line = lt_rfcdes-description.
          APPEND lt_values.
        ENDLOOP.
        lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
        lt_fields-fieldname = 'RFCDEST'.
        APPEND lt_fields.

        lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
        lt_fields-fieldname = 'RFCNAME'.
        APPEND lt_fields.

        lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
        lt_fields-fieldname = 'DESCRIPTION'.
        APPEND lt_fields.

        CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
             EXPORTING
                  retfield        = 'RFCNAME'
             TABLES
                  value_tab       = lt_values
                  field_tab       = lt_fields
                  return_tab      = lt_return
             EXCEPTIONS
                  parameter_error = 1
                  no_values_found = 2
                  OTHERS          = 3.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

      ELSE.
        IF l_installed = 'X'.
          REFRESH lt_syshdr.
          l_tabname = '/PSYNG/EX_SYSHDR'.

   SELECT * FROM (l_tabname) INTO TABLE "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
                    lt_syshdr WHERE appl = l_app.
          LOOP AT lt_syshdr .
            lt_values-line = lt_syshdr-appl.
            APPEND lt_values.
            lt_values-line = lt_syshdr-sysid.
            APPEND lt_values.
            lt_values-line = lt_syshdr-sdesc.
            APPEND lt_values.
          ENDLOOP.

          lt_fields-tabname   = '/PSYNG/EX_SYSHDR'.
          lt_fields-fieldname = 'APPL'.
          APPEND lt_fields.

          lt_fields-tabname   = '/PSYNG/EX_SYSHDR'.
          lt_fields-fieldname = 'SYSID'.
          APPEND lt_fields.

          lt_fields-tabname   = '/PSYNG/EX_SYSHDR'.
          lt_fields-fieldname   = 'SDESC'.
          APPEND lt_fields.

          CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
               EXPORTING
                    retfield        = 'SYSID'
               TABLES
                    value_tab       = lt_values
                    field_tab       = lt_fields
                    return_tab      = lt_return
               EXCEPTIONS
                    parameter_error = 1
                    no_values_found = 2
                    OTHERS          = 3.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
        ENDIF.
      ENDIF.

      IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL
              AND gf_dispchg1 = gc_change.
        READ TABLE lt_return INDEX 1.
        CASE sy-dynnr.
          WHEN '0908'.
            <wa_con>-high = lt_return-fieldval.
            CALL METHOD gr_alvgrid->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.

          WHEN '0909'.
            <wa_fun>-high = lt_return-fieldval.
            CALL METHOD gr_alvgrid_fun->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.

          WHEN '0910'.
            <wa_ca>-high = lt_return-fieldval.
            CALL METHOD gr_alvgrid_ca->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.

          WHEN '0911'.
            <wa_tcd>-high = lt_return-fieldval.
            CALL METHOD gr_alvgrid_tcd->refresh_table_display
              EXCEPTIONS
                finished = 1
                OTHERS   = 2.
            IF sy-subrc <> 0.
*--Exception handling
            ENDIF.
        ENDCASE.
      ENDIF.

  ENDCASE.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM fun_sort                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  P_GT_SORT                                                     *
*---------------------------------------------------------------------*
FORM fun_sort  CHANGING p_gt_sort.
  DATA : ls_sort TYPE lvc_s_sort.
  ls_sort-up   = 'X'.
  ls_sort-spos = '1'.
  ls_sort-fieldname = 'APPLICATION'.
  APPEND ls_sort TO gt_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'SIGN'.
  APPEND ls_sort TO gt_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'TYPE'.
  APPEND ls_sort TO gt_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'LOW'.
  APPEND ls_sort TO gt_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'HIGH'.
  APPEND ls_sort TO gt_sort.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM tcd_sort                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  P_GT_SORT                                                     *
*---------------------------------------------------------------------*
FORM tcd_sort  CHANGING p_gt_sort.
  DATA : ls_sort TYPE lvc_s_sort.

  ls_sort-up   = 'X'.
  ls_sort-spos = '1'.
  ls_sort-fieldname = 'SIGN'.
  APPEND ls_sort TO gt_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'TYPE'.
  APPEND ls_sort TO gt_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'LOW'.
  APPEND ls_sort TO gt_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'HIGH'.
  APPEND ls_sort TO gt_sort.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM audit_sort                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  P_GT_SORT                                                     *
*---------------------------------------------------------------------*
FORM audit_sort  CHANGING p_gt_sort.
  DATA : ls_sort TYPE lvc_s_sort.
  ls_sort-up   = 'X'.
  ls_sort-spos = '1'.
  ls_sort-fieldname = 'CONTID'.
  APPEND ls_sort TO gt_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'AUDITOR'.
  APPEND ls_sort TO gt_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'FROM_DATE'.
  APPEND ls_sort TO gt_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'TO_DATE'.
  APPEND ls_sort TO gt_sort.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM prepare_layout                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_TYPE                                                        *
*  -->  PS_LAYOUT                                                     *
*---------------------------------------------------------------------*
FORM prepare_layout USING i_type TYPE c
                  CHANGING ps_layout TYPE lvc_s_layo.
  DATA l_title TYPE string.
  ps_layout-zebra = 'X' .
  ps_layout-smalltitle = 'X'.
  CASE i_type.
    WHEN 'C'.
      l_title = 'System Filters for Conflicts'(t95) .
    WHEN 'A'.
      l_title = 'System Filters for Critical Authorizations'(t96) .
      WHEN'F'.
      l_title = 'System Filters for Functions'(t97) .
    WHEN 'T'.
      l_title = 'System Filters for Critical Transactions'(t98) .
    WHEN 'M'.
      l_title = 'Overview of pending reviews'(t99) .

  ENDCASE.
*  ps_layout-grid_title = 'System Filters'(s94).
  ps_layout-grid_title = l_title.
ENDFORM.
