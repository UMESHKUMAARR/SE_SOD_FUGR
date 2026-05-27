*----------------------------------------------------------------------*
***INCLUDE /PSYNG/Z_SODREPORT_ORG_45_PF01.
*----------------------------------------------------------------------*
FORM propose_remediation.

  DATA: lt_dhuc00 TYPE STANDARD TABLE OF /psyng/bc_dhuc00
        WITH HEADER LINE.
  DATA: lt_user TYPE STANDARD TABLE OF /psyng/sw_sel_opts_xubname
        WITH HEADER LINE.
  DATA: lt_date TYPE STANDARD TABLE OF /psyng/sw_sel_opts_date
        WITH HEADER LINE.

  DATA: lf_userid TYPE bname,
        lf_conid  TYPE /psyng/conflict-conid.

  TYPES: BEGIN OF typ_functcodes,
           tcode      TYPE tcode,
           functionid LIKE /psyng/functtran-functionid,
         END OF typ_functcodes.

  DATA: lt_functcodes TYPE SORTED TABLE OF typ_functcodes
        WITH UNIQUE KEY tcode functionid
        WITH HEADER LINE.

  TYPES: BEGIN OF typ_funcount,
           functionid LIKE /psyng/functtran-functionid,
           execount   TYPE i,
         END OF typ_funcount.

  DATA: lt_funcount TYPE SORTED TABLE OF typ_funcount
        WITH UNIQUE KEY functionid
        WITH HEADER LINE.

  TYPES: BEGIN OF typ_tcodes,
           tcode   TYPE tcode,
           rfcdest LIKE rfcdes-rfcdest,
         END OF typ_tcodes.

  DATA: lt_exetcodes TYPE SORTED TABLE OF typ_tcodes
        WITH UNIQUE KEY tcode rfcdest
        WITH HEADER LINE.

  DATA: lt_condet TYPE SORTED TABLE OF /psyng/condet
        WITH UNIQUE KEY conid funid
        WITH HEADER LINE.

  TYPES: BEGIN OF typ_remrole,
           agr_name TYPE agr_name,
           rfcdest  LIKE rfcdes-rfcdest,
           comp_agr type agr_name,
         END OF typ_remrole.
  DATA: lt_remrole TYPE SORTED TABLE OF typ_remrole
        WITH UNIQUE KEY agr_name rfcdest
        WITH HEADER LINE.

  TYPES: BEGIN OF typ_rfcdests,
           rfcdest LIKE rfcdes-rfcdest,
         END OF typ_rfcdests.
  DATA: lt_rfcdests TYPE SORTED TABLE OF typ_rfcdests
        WITH UNIQUE KEY rfcdest
        WITH HEADER LINE.

  DATA: lf_remfun      LIKE /psyng/functtran-functionid,
        lf_funcount    TYPE i VALUE 99999999,
        lf_mstdate     TYPE dats,
        lf_meddate     TYPE dats,
        lf_key(60)     VALUE 'DATES_2B_USED_4_REMEDIATION_PROPOSAL',
        lf_rfc_key(60) VALUE 'RFCS_2B_USED_4_REMEDIATION_PROPOSAL',
        lf_fmname      TYPE rs38l_fnam,
        lf_curclient   LIKE rfcdes-rfcdest,
        l_bname        TYPE xubname,
        l_conid        TYPE /psyng/conflict,
        l_obj          TYPE xuobject,
        l_fun          TYPE /psyng/function_id,
        l_tcode        TYPE xutcode,
        l_rfc          TYPE rfcdest,
        l_role         TYPE agr_name,
        l_comp         type agr_name,
        lt_fieldcat    type slis_t_fieldcat_alv with header line,
        lt_fieldcat_o  type slis_t_fieldcat_alv,
        lt_sort        TYPE STANDARD TABLE OF slis_sortinfo_alv
                            with header line,
        lt_roletcode   TYPE table of /PSYNG/ROLE_TCODE with header line.
ranges : lr_role for gt_suggout-agr_name.
* check if TA 2.x is installed
  CLEAR lf_fmname.
  MOVE '/PSYNG/BC_USRHIS_018' TO lf_fmname.
  CALL FUNCTION 'FUNCTION_EXISTS'
    EXPORTING
      funcname           = lf_fmname
    EXCEPTIONS
      function_not_exist = 1
      OTHERS             = 2.
  IF sy-subrc <> 0.
    MESSAGE e113(/psyng/sw) WITH text-198.
  ENDIF.

* get user ID and conflict ID (the one the user's cursor is on)
  READ TABLE <gt_output> ASSIGNING <gs_output>
  INDEX gs_selfield-tabindex.
  IF sy-subrc = 0.
    get_dyn_value  :
    'BNAME'    <gs_output> lf_userid,
    'CONID'    <gs_output> lf_conid .
  ENDIF.
* get unique function IDs, tcodes and conflicts
  REFRESH: lt_condet.

  LOOP AT <gt_output> ASSIGNING <gs_output>.
    get_dyn_value  :
      'BNAME'      <gs_output> l_bname,
      'CONID'      <gs_output> l_conid,
      'OBJCT'      <gs_output> l_obj,
      'FUNCTIONID' <gs_output> l_fun,
      'TCODE'      <gs_output> l_tcode,
      'RFCDEST'    <gs_output> l_rfc.
    CHECK l_bname = lf_userid AND
          l_conid = lf_conid  AND
          ( l_obj   = 'S_TCODE'  or mode = 'SIMPLE' ).
    lt_functcodes-functionid = l_fun.
    lt_functcodes-tcode      = l_tcode.
    INSERT lt_functcodes INTO TABLE lt_functcodes.

    lt_condet-conid = l_conid.
    lt_condet-funid = l_fun.
    INSERT lt_condet INTO TABLE lt_condet.

    lt_rfcdests-rfcdest = l_rfc.
    INSERT lt_rfcdests INTO TABLE lt_rfcdests.
  ENDLOOP.

  CONCATENATE sy-sysid sy-mandt INTO lf_curclient.

* get user's tcode execution history

  lf_mstdate = g_his_begda.
  lf_meddate = g_his_endda.

  IF lf_mstdate IS INITIAL AND lf_meddate IS INITIAL.
* If nothing is found in memory for start/end dates use start and
* end dates of all history available in TA.  These dates will be used
* for getting history from remote systems also.
    PERFORM populate_avail_ta.
    lf_mstdate = g_his_begda.
    lf_meddate = g_his_endda.

    lt_date-sign   = 'I'.
    lt_date-option = 'BT'.
    lt_date-low    = lf_mstdate.
    lt_date-high   = lf_meddate.
    APPEND lt_date.
  ELSE.
    IF lf_meddate IS INITIAL.
* if only start date is specified/found
      lt_date-sign   = 'I'.
      lt_date-option = 'EQ'.
      lt_date-low    = lf_mstdate.
      APPEND lt_date.
    ELSE.
* both start & end dates are specified/found
      lt_date-sign   = 'I'.
      lt_date-option = 'BT'.
      lt_date-low    = lf_mstdate.
      lt_date-high   = lf_meddate.
      APPEND lt_date.
    ENDIF.
  ENDIF.

  REFRESH: lt_user.
  lt_user-sign   = 'I'.
  lt_user-option = 'EQ'.
  lt_user-low    = lf_userid.
  APPEND lt_user.

  CLEAR lf_fmname.
  MOVE '/PSYNG/BC_USRHIS_018' TO lf_fmname.

  CALL FUNCTION 'FUNCTION_EXISTS'
    EXPORTING
      funcname           = lf_fmname
    EXCEPTIONS
      function_not_exist = 1
      OTHERS             = 2.
  IF sy-subrc <> 0.
    MESSAGE e113(/psyng/sw) WITH text-198.
  ENDIF.

  if not p_remonl = 'X'.
      CALL FUNCTION lf_fmname "#EC PATHLOCK_CI_DYN_ACCES
        TABLES
          it_users  = lt_user
          it_date   = lt_date
*         IT_TCODE  =
          ot_dhuc00 = lt_dhuc00.

*     get unique tcodes executed by user
      REFRESH: lt_exetcodes.
      LOOP AT lt_dhuc00.
        lt_exetcodes-tcode = lt_dhuc00-tcode.
        MOVE gt_rfcdest-rfcoptions TO lt_exetcodes-rfcdest.
        INSERT lt_exetcodes INTO TABLE lt_exetcodes.
      ENDLOOP.
      FREE: lt_dhuc00.
      CLEAR: lt_dhuc00.
  endif.
  LOOP AT gt_rfcdest.
    IF gt_rfcdest-rfcoptions <> lf_curclient.

*BOC: HBHALLA
"Confirming Function/TA existance in RFC Dest.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
                  .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
CALL FUNCTION 'FUNCTION_EXISTS'
  DESTINATION gt_rfcdest-rfcdest
  EXPORTING
    funcname                 = lf_fmname
  EXCEPTIONS
    FUNCTION_NOT_EXIST = 1
    SYSTEM_FAILURE = 2
    COMMUNICATION_FAILURE = 3
    OTHERS             = 4. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  IF sy-subrc = 0.
      CALL FUNCTION lf_fmname  "#EC PATHLOCK_CI_DYN_ACCES
 "HBHALLA " FM = /PSYNG/BC_USRHIS_018
        DESTINATION gt_rfcdest-rfcdest "#EC SAST_CI_GEN_CHECK
        TABLES
          it_users  = lt_user
          it_date   = lt_date
*         IT_TCODE  =
          ot_dhuc00 = lt_dhuc00
        EXCEPTIONS
        SYSTEM_FAILURE = 1
        COMMUNICATION_FAILURE = 2
        OTHERS             = 3."#EC SAST_CI_GEN_CHECK

       IF sy-subrc = 0.
       ENDIF.
  ELSE.
      MESSAGE e113(/psyng/sw) WITH text-198.
  ENDIF.
*EOC: HBHALLA
*     get unique tcodes executed by user
      REFRESH: lt_exetcodes.
      LOOP AT lt_dhuc00.
        lt_exetcodes-tcode = lt_dhuc00-tcode.
        MOVE gt_rfcdest-rfcoptions TO lt_exetcodes-rfcdest.
        INSERT lt_exetcodes INTO TABLE lt_exetcodes.
      ENDLOOP.
      FREE: lt_dhuc00.
      CLEAR: lt_dhuc00.
    ENDIF.
  ENDLOOP.  "irfc

* Find functions' tcode executed count
* Each remote systems tcode exeuction will add to execution count
* Same tcode can be executed once in 5 systems, it would be counted as5
* Another tcode can be executed 500 times in 1 system, it would be
* counted as 1
  REFRESH: lt_funcount.
  lt_funcount-execount = 1.
  LOOP AT lt_exetcodes.
    READ TABLE lt_functcodes WITH KEY tcode = lt_exetcodes-tcode
    BINARY SEARCH.
    CHECK sy-subrc = 0.
    lt_funcount-functionid = lt_functcodes-functionid.
    COLLECT lt_funcount.

  ENDLOOP.

* find the lowest executed function
  LOOP AT lt_condet.
    READ TABLE lt_funcount
    WITH TABLE KEY functionid = lt_condet-funid.
    IF sy-subrc <> 0.
      lf_remfun = lt_condet-funid.
      lf_funcount = 0.
      EXIT.
    ENDIF.
    IF lf_funcount >= lt_funcount-execount.
      lf_funcount = lt_funcount-execount.
      lf_remfun = lt_condet-funid.
    ENDIF.
  ENDLOOP.

* get unique roles of the function to remove
  REFRESH: lt_remrole.
  LOOP AT <gt_output> ASSIGNING <gs_output>.
    get_dyn_value  :
      'BNAME'      <gs_output> l_bname,
      'CONID'      <gs_output> l_conid,
      'OBJCT'      <gs_output> l_obj,
      'FUNCTIONID' <gs_output> l_fun,
      'TCODE'      <gs_output> l_tcode,
      'RFCDEST'    <gs_output> l_rfc,
      'AGR_NAME'   <gs_output> l_role.
    if showcomp = 'X'.
      get_dyn_value  :
      'COMP_AGR'      <gs_output> l_comp.
    endif.

    CHECK l_bname = lf_userid AND
          l_conid = lf_conid  AND
          l_fun   = lf_remfun AND
          ( l_obj   = 'S_TCODE'  or mode = 'SIMPLE' ) AND
          l_role  <> ''.
    lt_remrole-agr_name = l_role.
    lt_remrole-rfcdest  = l_rfc.
    if showcomp = 'X'.
      lt_remrole-comp_agr = l_comp.
    endif.
    INSERT lt_remrole INTO TABLE lt_remrole.
  ENDLOOP.
  CHECK NOT lt_remrole[] IS INITIAL.

* build the output table
  REFRESH: gt_suggout.
  gt_suggout-bname      = lf_userid.
  gt_suggout-conid      = lf_conid.
  gt_suggout-exetcode   = lf_funcount.
  gt_suggout-functionid = lf_remfun.
  SELECT SINGLE description INTO gt_suggout-description
         FROM /psyng/conflict
         WHERE conid = lf_conid AND
               vrsio = sodvrsio.
"#EC CI_SUBRC
  SELECT SINGLE description INTO gt_suggout-fundesc
         FROM /psyng/function
         WHERE function = lf_remfun AND
               vrsio = sodvrsio.
"#EC CI_SUBRC
  LOOP AT lt_remrole.
    gt_suggout-agr_name = lt_remrole-agr_name.
    gt_suggout-rfcdest = lt_remrole-rfcdest.
    if showcomp = 'X'.
      gt_suggout-comp_agr = lt_remrole-comp_agr.
    endif.
    SELECT SINGLE text INTO gt_suggout-agrdesc
           FROM agr_texts
           WHERE agr_name = lt_remrole-agr_name AND
                 spras = sy-langu AND
                 line = '00000'.
 "#EC CI_SUBRC
*--Check if other tcodes in this role (or composite) were executed
    refresh : lr_role, lt_roletcode.
    lr_role-sign   = 'I'.
    lr_role-option = 'EQ'.
    lr_role-low    = lt_remrole-agr_name.
    append lr_role.
    if not lt_remrole-comp_agr is initial.
      lr_role-low    = lt_remrole-comp_agr.
      append lr_role.
    endif.
*--Get all tcodes from the role
    iF lt_remrole-rfcdest <> lf_curclient.
      CALL FUNCTION '/PSYNG/BC_012'
        TABLES
          IT_AGR_NAME         = lr_role
          et_role_tcode       = lt_roletcode.
    else.
      read table gt_rfcdest with key rfcoptions = lt_remrole-rfcdest.
      if sy-subrc = 0.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
                  .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      CALL FUNCTION '/PSYNG/BC_012'
      destination gt_rfcdest-rfcdest
        TABLES
          IT_AGR_NAME         = lr_role
          et_role_tcode       = lt_roletcode
        EXCEPTIONS
            SYSTEM_FAILURE = 1
            COMMUNICATION_FAILURE = 2
            OTHERS             = 3.  "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

      endif.
    endif.
    sort lt_roletcode by screen.
    delete adjacent duplicates from lt_roletcode comparing screen.
    clear gt_suggout-exeother.
 loop at lt_exetcodes where rfcdest = lt_remrole-rfcdest. "#EC CI_SORTSEQ
      READ TABLE lt_functcodes WITH KEY tcode = lt_exetcodes-tcode
      BINARY SEARCH.
      if sy-subrc <> 0.
        read table lt_roletcode with key screen = lt_exetcodes-tcode
        binary search transporting no fields.
        if sy-subrc = 0.
           add 1 to  gt_suggout-exeother.
        endif.
      endif.
 endloop.
    INSERT gt_suggout INTO TABLE gt_suggout.
  ENDLOOP.

* move data from local fields to global fields to be used in form
* used in form ALV_TOP_OF_PAGE_PROP_REM
  gf_mstdate  = lf_mstdate.
  gf_meddate  = lf_meddate.
  gf_funcount = lf_funcount.

* output data
  g_program = sy-repid.
  REFRESH: lt_fieldcat.
  define add_prop_mit_col.
*--create field catalog for ALV
   add 1 to lt_fieldcat-col_pos.
   lt_fieldcat-fieldname    = &1.
   lt_fieldcat-outputlen    = &2.
   lt_fieldcat-seltext_s    = &3.
   if &4 is initial.
     lt_fieldcat-seltext_m    = lt_fieldcat-seltext_s.
   else.
     lt_fieldcat-seltext_m    = &4.
   endif.
   if &5 is initial.
     lt_fieldcat-seltext_l    = lt_fieldcat-seltext_m.
   else.
     lt_fieldcat-seltext_l    = &5.
   endif.
   lt_fieldcat-reptext_ddic = lt_fieldcat-seltext_l.
   append lt_fieldcat.
  end-of-definition.

  add_prop_mit_col :
    'BNAME'       '12'  'User'(p01)           'User Name'(p10)             '',
    'CONID'       '12'  'Con. ID'(p02)        'Conflict ID'(p11)           '',
    'DESCRIPTION' '200' 'Conflict Desc.'(p03) 'Conflict Description'(p12)  '',
    'EXETCODE'    '12'  'Tcode Exe'(p04)      'Conflicting Tcode Execution'(p13) '',
    'EXEOTHER'     '12'  'Other Exe'(p21)      'Other Tcode Exe. Cnt'(m22)
    'Other Tcode Execution Cnt'(p22),
    'FUNCTIONID'  '12'  'Func ID'(p05)        'Function ID'(p14)           '',
    'FUNDESC'     '200' 'Func Desc'(p06)      'Function Description'(p15)  '',
    'RFCDEST'     '8'   'System'(p07)         'System'(p16)                '',
    'AGR_NAME'    '40'  'Remove Role'(p08)    'Role to be removed'(p17)    '',
    'AGRDESC'     '200' 'Role Desc.'(p09)     'Role Description'(p18)      '',
    'COMP_AGR'    '40'  'Comp. Role'(p19)     'Composite Role'(p20)        ''.



  CLEAR: lt_sort, lt_sort.
  REFRESH: lt_sort.

  lt_sort-spos = '1'.
  lt_sort-fieldname = 'BNAME'.
  lt_sort-tabname = 'GT_SUGGOUT'.
  lt_sort-up = 'X'.
  APPEND lt_sort TO lt_sort.

  lt_sort-spos = '2'.
  lt_sort-fieldname = 'CONID'.
  lt_sort-tabname = 'GT_SUGGOUT'.
  lt_sort-up = 'X'.
  APPEND lt_sort TO lt_sort.

  lt_sort-spos = '3'.
  lt_sort-fieldname = 'DESCRIPTION'.
  lt_sort-tabname = 'GT_SUGGOUT'.
  lt_sort-up = 'X'.
  APPEND lt_sort TO lt_sort.

  lt_sort-spos = '4'.
  lt_sort-fieldname = 'EXETCODE'.
  lt_sort-tabname = 'GT_SUGGOUT'.
  lt_sort-up = 'X'.
  APPEND lt_sort TO lt_sort.

  lt_sort-spos = '5'.
  lt_sort-fieldname = 'FUNCTIONID'.
  lt_sort-tabname = 'GT_SUGGOUT'.
  lt_sort-up = 'X'.
  APPEND lt_sort TO lt_sort.

  lt_sort-spos = '6'.
  lt_sort-fieldname = 'FUNDESC'.
  lt_sort-tabname = 'GT_SUGGOUT'.
  lt_sort-up = 'X'.
  APPEND lt_sort TO lt_sort.

  lt_sort-spos = '7'.
  lt_sort-fieldname = 'RFCDEST'.
  lt_sort-tabname = 'GT_SUGGOUT'.
  lt_sort-up = 'X'.
  APPEND lt_sort TO lt_sort.

  lt_sort-spos = '8'.
  lt_sort-fieldname = 'AGR_NAME'.
  lt_sort-tabname = 'GT_SUGGOUT'.
  lt_sort-up = 'X'.
  APPEND lt_sort TO lt_sort.

  lt_fieldcat_o[] = lt_fieldcat[].
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_top_of_page = 'ALV_TOP_OF_PAGE_PROP_REM'
      i_callback_program     = g_program
      it_sort                = lt_sort[]
*     i_callback_user_command  = 'ROLE_DOUBLE_CLICK_ON_DETL'
      is_layout              = gs_alv_layout
      it_fieldcat            = lt_fieldcat_o[]
    TABLES
      t_outtab               = gt_suggout
    EXCEPTIONS
      program_error          = 1
      OTHERS                 = 2.

  IF sy-subrc <> 0.
*       MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*               WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " show_easy_way_out
