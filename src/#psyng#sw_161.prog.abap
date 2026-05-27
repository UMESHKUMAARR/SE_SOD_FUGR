*&---------------------------------------------------------------------*
*& Report  /PSYNG/SW_161
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT /PSYNG/SW_161.
type-POOLs slis.
TABLES: /psyng/conflict,
        /psyng/busarea,
        /psyng/bus_proce,
        /psyng/swsodorgm,
        /psyng/swresusr,
        rfcdes,
        ust04,
        usr21,
        /psyng/sw_uinfo,
        /psyng/ex_caobj_lock,
        usr02,
        /psyng/sw_sod_remote_roles,
        /psyng/sw_role_removal_simu.

DATA: BEGIN OF 1stoutput OCCURS 10.            "Table to output 1st
DATA: sel(1)        TYPE c,           "selected row by user in ALV grid
      class         LIKE usr02-class,
      company       LIKE /psyng/sw_uinfo-company,
      compshort     LIKE /psyng/sw_uinfo-company,
      department    LIKE /psyng/sw_uinfo-department,
      central_uid   LIKE /psyng/sw_uinfo-central_uid,
      ustyp         LIKE usr02-ustyp,
      bname         LIKE ust04-bname,
      name_text     LIKE adrp-name_text,
      conid         LIKE /psyng/conflict-conid,
      description   LIKE /psyng/conflict-description,
      imp           LIKE /psyng/1stoutput_u-imp,
      impsort       TYPE n,
      contid        LIKE /psyng/1stoutput_u-contid,
      inactive      LIKE /psyng/mchdr-inactive,
      auditor       LIKE /psyng/mcuser-auditor,
      from_date     LIKE /psyng/mcuser-from_date,
      to_date       LIKE /psyng/mcuser-to_date,
      mit_icon      LIKE icon-id,
      enhanced      TYPE c, "flag for enhanced ruleset
      simu          TYPE c, "flag for simulated conflict
      er            TYPE c, "flag for ER conflict
      origin(12)    TYPE c, "LOCAL/REMOTE/CROSS
      level2        TYPE c,
      level3        TYPE c,
      level4        TYPE c,
      simu_after    TYPE c,
      simu_before   TYPE c,
      abb           LIKE /psyng/sw_sod_output_org-org_abb,
      color_line(4) TYPE c,           " Line color
      color_cell    TYPE lvc_t_scol.  " Cell color
DATA: END OF 1stoutput.

DATA: usertype TYPE /psyng/xuustyp,
      l_appl   TYPE /psyng/application,
      i_fieldcat_alv  TYPE slis_t_fieldcat_alv,
      tusercount TYPE i,
      gf_missing_auth TYPE flag,
      gt_simuagrs LIKE STANDARD TABLE OF /psyng/sw_sod_remote_roles
      INITIAL SIZE 0 WITH HEADER LINE,
      gt_mcuser  TYPE TABLE OF /psyng/mitigation_assignment
      WITH HEADER LINE,
      gt_rfcdes  TYPE TABLE OF rfcdes WITH HEADER LINE,
      lt_return  TYPE TABLE OF bapiret2 WITH HEADER LINE,
      lt_role_removal_simu TYPE TABLE OF /psyng/sw_role_removal_simu
      WITH HEADER LINE,
      lf_error TYPE flag,
      lf_dont_update_scan TYPE flag,
      lt_confs   TYPE TABLE OF /psyng/sw_sel_opts_conid
                WITH HEADER LINE,
       lt_bname   TYPE TABLE OF /psyng/sw_sel_opts_xubname
                WITH HEADER LINE,
       lt_output  TYPE TABLE OF /psyng/sw_sod_output_org
                WITH HEADER LINE,
       lt_details TYPE TABLE OF /psyng/sw_level3_details
                WITH HEADER LINE.

PARAMETERS : p_cross TYPE flag,
             p_remote TYPE flag,
             validusr AS CHECKBOX,
             exlckusr AS CHECKBOX,
             outvdate AS CHECKBOX,
             sodvrsio LIKE /psyng/conflict-vrsio,
             xmc AS CHECKBOX,
             p_enhanc AS CHECKBOX,
             p_hienhn AS CHECKBOX,
             wp(1) TYPE n,
             pserver LIKE msxxlist-name,
             upp TYPE i,
             shonosod AS CHECKBOX,
             p_locsod TYPE flag,
             p_locusr AS CHECKBOX,
             odt AS CHECKBOX,
             p_remonl AS CHECKBOX,
             erroles AS CHECKBOX,
             lvl2 TYPE c,
             lvl2st TYPE dats,
             lvl2ed TYPE dats,
             lvl3 TYPE c,
             lvl3_cd AS CHECKBOX,
             lvl3_tl AS CHECKBOX,
             lvl4 TYPE c,
             p_nabap AS CHECKBOX,
             p_abap AS CHECKBOX,
             orgchk  AS CHECKBOX.

SELECT-OPTIONS: xusrrfc FOR rfcdes-rfcdest,
                usrtype FOR usertype,
                s_appl FOR l_appl,
                s_system FOR /psyng/ex_caobj_lock-sysid,
                s_risk  FOR /psyng/conflict-risk,
                s_depart FOR /psyng/sw_uinfo-department,
                s_comp   FOR /psyng/sw_uinfo-company,
                s_cuid   FOR  /psyng/sw_uinfo-central_uid,
                s_kostl  FOR /psyng/swresusr-kostl,
                orglvl  FOR /psyng/swsodorgm-abb,
                s_conf FOR /psyng/conflict-conid,
                s_bname FOR usr02-bname,
                s_rfcdes FOR /psyng/sw_sod_remote_roles-rfcdest,
                s_agr FOR /psyng/sw_sod_remote_roles-agr_name,
                s_sagr FOR /psyng/sw_role_removal_simu-low,
                s_srfc FOR /psyng/sw_role_removal_simu-rfcdest.

*BOC AKUMAR SE VF scan changes-25/11/2024
START-OF-SELECTION.

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-25/11/2024
lt_confs[] = s_conf[].

LOOP AT s_bname.
  lt_bname-sign   = 'I'.
  lt_bname-option = 'EQ'.
  lt_bname-low    = s_bname-low.
  lt_bname-high  = s_bname-high.
  APPEND lt_bname.
ENDLOOP.

LOOP AT s_rfcdes.
  READ TABLE s_agr INDEX sy-tabix.
  gt_simuagrs-rfcdest = s_rfcdes-low.
  gt_simuagrs-agr_name = s_rfcdes-low.
  APPEND gt_simuagrs.
ENDLOOP.

LOOP AT s_sagr.
  READ TABLE s_srfc INDEX sy-tabix.
  lt_role_removal_simu-sign   = 'I'.
  lt_role_removal_simu-option = 'EQ'.
  lt_role_removal_simu-low    = s_sagr-low.
  lt_role_removal_simu-high  = s_sagr-high.
  lt_role_removal_simu-rfcdest = s_srfc-low.
  APPEND lt_role_removal_simu.
ENDLOOP.


*--Only if remote and cross are selected,
*  pass rfc destinations to FM
DATA : lt_rfcdest TYPE TABLE OF /psyng/sw_sel_opts_rfcdest.
IF NOT p_cross IS INITIAL OR
   NOT p_remote IS INITIAL.
  lt_rfcdest[] = xusrrfc[].
ENDIF.

CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
  EXPORTING
    i_org_check          = orgchk
    i_validuser          = validusr
    i_exlckusr           = exlckusr
    i_outvdate           = outvdate
*     I_ALLUG              =
    i_vrsio              = sodvrsio
    i_function_details   = ' '
    i_shomit             = xmc
    i_enh                = p_enhanc
    i_hienh              = p_hienhn
    i_wp                 = wp
    i_xstb               = lf_dont_update_scan
    i_pserver            = pserver
    i_max_upp            = upp
    i_shonosod           = shonosod
    i_locsod             = p_locsod
    i_locusr             = p_locusr
    i_output             = odt
    i_remote_only        = p_remonl
    i_er_roles           = erroles
    i_level_2            = lvl2
    i_level_2_start      = lvl2st
    i_level_2_end        = lvl2ed
    i_level_3            = lvl3
    i_level_3_start      = lvl2st
    i_level_3_end        = lvl2ed
    i_level_3_changedocs = lvl3_cd
    i_level_3_tablog     = lvl3_tl
    i_level_3_details    = 'X'
    i_level_4            = lvl4
    i_level_4_start      = lvl2st "only use one single timeframe
    i_level_4_end        = lvl2ed "only use one single timeframe
*Analyze users with sap_all in detail
    i_analyze_sap_all    = 'X'
    i_nonabap            = p_nabap
    i_abap               = p_abap
  IMPORTING
    e_usercount          = tusercount
    ef_missing_auth      = gf_missing_auth
  TABLES
    it_users             = lt_bname
    it_usertype          = usrtype
    it_confs             = lt_confs
    et_outputdet         = lt_output
    it_user_rfc          = lt_rfcdest "xusrrfc
    it_simu_role_rfc     = gt_simuagrs
*     et_enh_con           = gt_enh_con
    it_orglvl            = orglvl
    it_risk              = s_risk
    it_department        = s_depart
    it_company           = s_comp
    it_central_uid       = s_cuid
    it_costcenter        = s_kostl
    et_mitigations       = gt_mcuser
    et_rfcdes            = gt_rfcdes
    et_return            = lt_return
*--Role Removal Simulation
    it_simu_role_removal = lt_role_removal_simu
*     et_simu_removed_roles    = gt_removed_roles
    et_level3_details    = lt_details
*--EN Integration
    it_appl              = s_appl
    it_sysid             = s_system.

*--Handle Errors
LOOP AT lt_return.
  IF lt_return-type = 'E'.
    lf_error = 'X'.
*      lt_return-type = 'W'.
  ENDIF.
*    MESSAGE ID '/PSYNG/SW' TYPE lt_return-type NUMBER '140'
*    WITH lt_return-message.
ENDLOOP.
CALL FUNCTION '/PSYNG/SW_INFO_BAPIRET'
  TABLES
    it_bapiret2       = lt_return.

IF lf_error = 'X'.
  MESSAGE ID '/PSYNG/SW' TYPE 'S' NUMBER '140'
  WITH 'Fatal errors have occured.'(e04).
  LEAVE LIST-PROCESSING.
ENDIF.

*--Output the details
DATA : lt_display TYPE TABLE OF /psyng/sw_level3_display
WITH HEADER LINE.
CALL FUNCTION '/PSYNG/SW_104'
  TABLES
    et_details = lt_display
    it_details = lt_details
    it_rfc     = gt_rfcdes.
SORT lt_display.
DELETE ADJACENT DUPLICATES FROM lt_display.
*--Match this to conflicts
DATA : lt_confdet     TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
       lt_display_con TYPE TABLE OF /psyng/sw_level3_display
       WITH HEADER LINE.
SELECT * FROM /psyng/confdet INTO TABLE lt_confdet WHERE vrsio =
sodvrsio AND conid IN lt_confs.
LOOP AT lt_output.
  LOOP AT lt_confdet WHERE conid = lt_output-conid.
    LOOP AT lt_display WHERE bname = lt_output-bname AND
                             funid = lt_confdet-functionid.
      lt_display_con = lt_display.
      lt_display_con-conid = lt_output-conid.
      APPEND lt_display_con.
    ENDLOOP.
  ENDLOOP.
ENDLOOP.

PERFORM level3_alv_output TABLES lt_display_con.

*---------------------------------------------------------------------*
*       FORM level3_alv_output                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_DISPLAY                                                    *
*---------------------------------------------------------------------*
FORM level3_alv_output TABLES   it_display STRUCTURE
/psyng/sw_level3_display.

  DATA: isort           TYPE STANDARD TABLE OF slis_sortinfo_alv,
        l_sort          TYPE slis_sortinfo_alv,
        alv_grid_titl   TYPE lvc_title,
        alv_layout      TYPE slis_layout_alv,
        ls_variant      TYPE disvariant,
        program         LIKE sy-repid,
        begindate_c(10),
        enddate_c(10),
        lt_fieldcat_alv TYPE slis_t_fieldcat_alv.

  DATA: ls_print TYPE slis_print_alv.


  program = sy-repid.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  alv_layout-detail_popup = 'X'.
  alv_layout-get_selinfos = 'X'.
  alv_layout-max_linesize = '200'.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname = 'IT_DISPLAY'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'CONID'.
  l_sort-tabname = 'IT_DISPLAY'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
*  add 1 to l_sort-spos.
*  l_sort-fieldname = 'CONTEXT'.
*  l_sort-tabname = 'IT_DISPLAY'.
*  l_sort-up = 'X'.
*  APPEND l_sort TO isort.
*  add 1 to l_sort-spos.
*  l_sort-fieldname = 'RISK'.
*  l_sort-tabname = 'IT_DISPLAY'.
*  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FUNID'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FUNTEXT'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'DATE'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'TIME'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'TCODE'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'TTEXT'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'TYPE'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'TABLE'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'LOGKEY'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'CHANGE_TYPE'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FIELDNAME'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FIELDTEXT'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'VALUE'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'NEWVAL'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.


*  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
*       EXPORTING
*            i_program_name     = program
*            i_internal_tabname = 'IT_DISPLAY'
*            i_inclname         = program
*       CHANGING
*            ct_fieldcat        = i_fieldcat_alv.

  CONCATENATE 'SOD Analysis based on User Changes SOD Ver'(a26)
sodvrsio
                                        INTO sy-title SEPARATED BY
space
                                        .

  CONCATENATE 'SOD Analysis based on User Changes SOD Ver'(a26)
*               lvl2st
*               'To'(a21)
*               lvl2ed
               sodvrsio
              INTO alv_grid_titl SEPARATED BY space.

  PERFORM level3_fieldcatalog TABLES lt_fieldcat_alv .
  PERFORM level3_add_texts TABLES it_display.

*  ls_print-print = 'X'.
*  ls_print-no_print_listinfos = 'X'.
*
*CALL FUNCTION 'REUSE_ALV_LIST_DISPLAY'
*        EXPORTING
**         I_INTERFACE_CHECK              = ' '
**         I_BYPASSING_BUFFER             =
**         I_BUFFER_ACTIVE                = ' '
**         I_CALLBACK_PROGRAM             = ' '
**         I_CALLBACK_PF_STATUS_SET       = ' '
**         I_CALLBACK_USER_COMMAND        = ' '
**         I_STRUCTURE_NAME               =
*          is_layout     = alv_layout
*          it_fieldcat   = lt_fieldcat_alv
**         IT_EXCLUDING  =
**         IT_SPECIAL_GROUPS              =
**         IT_SORT       =
**         IT_FILTER     =
**         IS_SEL_HIDE   =
**         I_DEFAULT     = 'X'
**         I_SAVE        = ' '
**         IS_VARIANT    =
**         IT_EVENTS     =
**         IT_EVENT_EXIT =
*          is_print      = ls_print
**         IS_REPREP_ID  =
**         I_SCREEN_START_COLUMN          = 0
**         I_SCREEN_START_LINE            = 0
**         I_SCREEN_END_COLUMN            = 0
**         I_SCREEN_END_LINE              = 0
**     IMPORTING
**         E_EXIT_CAUSED_BY_CALLER        =
**         ES_EXIT_CAUSED_BY_USER         =
*        TABLES
*          t_outtab      = it_display
*        EXCEPTIONS
*          program_error = 1
*          OTHERS        = 2.
*      IF sy-subrc <> 0.
*        MESSAGE e002(/psyng/sw) WITH 'Error Displaying ALV Grid'(e07)
*'' '' ''.
*      ENDIF.

  DESCRIBE TABLE it_display.
  MESSAGE i002(/psyng/sw) WITH sy-tfill.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_grid_title           = alv_grid_titl
      i_callback_top_of_page = 'LEVEL3_ALV_HEADER'
*     i_callback_user_command = 'HOTSPOT_CLICK'
      i_callback_program     = program
*      is_print               = ls_print
      it_sort                = isort
      is_layout              = alv_layout
      it_fieldcat            = lt_fieldcat_alv
      i_save                 = 'A'
      is_variant             = ls_variant
    TABLES
      t_outtab               = it_display.

  CLEAR sy-title.
  CONCATENATE text-193 text-093 sodvrsio
              INTO sy-title SEPARATED BY space.

ENDFORM.                    " level3_alv_output
*---------------------------------------------------------------------*
*       FORM level3_fieldcatalog                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM level3_fieldcatalog
  TABLES it_fieldcat LIKE i_fieldcat_alv.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

*  LOOP AT it_fieldcat INTO wa_fieldcat_alv.
*    wa_fieldcat_alv-seltext_l = wa_fieldcat_alv-seltext_m =
*                            wa_fieldcat_alv-seltext_s =
*                            wa_fieldcat_alv-reptext_ddic =
*                            wa_fieldcat_alv-fieldname.
*    MODIFY it_fieldcat FROM wa_fieldcat_alv
*                       TRANSPORTING seltext_l seltext_m seltext_s
*                                    reptext_ddic
*                       WHERE fieldname = wa_fieldcat_alv-fieldname.
*  ENDLOOP.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'User ID'(a05).
  wa_fieldcat_alv-seltext_m = 'User ID'(a05).
  wa_fieldcat_alv-seltext_s = 'User ID'(a05).
  wa_fieldcat_alv-reptext_ddic = 'User ID'(a05).
  wa_fieldcat_alv-fieldname    = 'BNAME'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Conflict ID'(a06).
  wa_fieldcat_alv-seltext_m = 'Conflict ID'(a06).
  wa_fieldcat_alv-seltext_s = 'Conflict ID'(a06).
  wa_fieldcat_alv-reptext_ddic = 'Conflict ID'(a06).
  wa_fieldcat_alv-fieldname    = 'CONID'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Function ID'(a07).
  wa_fieldcat_alv-seltext_m = 'Function ID'(a07).
  wa_fieldcat_alv-seltext_s = 'Function ID'(a07).
  wa_fieldcat_alv-reptext_ddic = 'Function ID'(a07).
  wa_fieldcat_alv-fieldname    = 'FUNID'.
  APPEND wa_fieldcat_alv TO it_fieldcat.


  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Function Text'(a11).
  wa_fieldcat_alv-seltext_m = 'Function Text'(a11).
  wa_fieldcat_alv-seltext_s = 'Function Text'(a11).
  wa_fieldcat_alv-reptext_ddic = 'Function Text'(a11).
  wa_fieldcat_alv-fieldname    = 'FUNTEXT'.
  APPEND wa_fieldcat_alv TO it_fieldcat.



  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Transaction Code'(a01).
  wa_fieldcat_alv-seltext_m = 'Transaction Code'(a01).
  wa_fieldcat_alv-seltext_s = 'Tcode'(a02).
  wa_fieldcat_alv-reptext_ddic = 'Transaction Code'(a01).
  wa_fieldcat_alv-hotspot      = ' '.
  wa_fieldcat_alv-fieldname    = 'TCODE'.
  APPEND wa_fieldcat_alv TO it_fieldcat.
  CLEAR:wa_fieldcat_alv.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Tcode Text'(a12).
  wa_fieldcat_alv-seltext_m = 'Tcode Text'(a12).
  wa_fieldcat_alv-seltext_s = 'Tcode Text'(a12).
  wa_fieldcat_alv-reptext_ddic = 'Tcode Text'(a12).
  wa_fieldcat_alv-fieldname    = 'TTEXT'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Change Type'(a14).
  wa_fieldcat_alv-seltext_m = 'Change Type'(a14).
  wa_fieldcat_alv-seltext_s = 'Change Type'(a14).
  wa_fieldcat_alv-reptext_ddic = 'Change Type'(a14).
  wa_fieldcat_alv-fieldname    = 'TYPE'.
  APPEND wa_fieldcat_alv TO it_fieldcat.



  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Table'(a15).
  wa_fieldcat_alv-seltext_m = 'Table'(a15).
  wa_fieldcat_alv-seltext_s = 'Table'(a15).
  wa_fieldcat_alv-reptext_ddic = 'Table'(a15).
  wa_fieldcat_alv-fieldname    = 'TABLE'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Field Name'(a08).
  wa_fieldcat_alv-seltext_m = 'Field Name'(a08).
  wa_fieldcat_alv-seltext_s = 'Field Name'(a08).
  wa_fieldcat_alv-reptext_ddic = 'Field Name'(a08).
  wa_fieldcat_alv-fieldname    = 'FIELDNAME'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Field Text'(a09).
  wa_fieldcat_alv-seltext_m = 'Field Text'(a09).
  wa_fieldcat_alv-seltext_s = 'Field Text'(a09).
  wa_fieldcat_alv-reptext_ddic = 'Field Text'(a09).
  wa_fieldcat_alv-fieldname    = 'FIELDTEXT'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Log Key'(a13).
  wa_fieldcat_alv-seltext_m = 'Log Key'(a13).
  wa_fieldcat_alv-seltext_s = 'Log Key'(a13).
  wa_fieldcat_alv-reptext_ddic = 'Log Key'(a13).
  wa_fieldcat_alv-fieldname    = 'LOGKEY'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  wa_fieldcat_alv-seltext_l = 'Date'(a17).
  wa_fieldcat_alv-seltext_m = 'Date'(a17).
  wa_fieldcat_alv-seltext_s = 'Date'(a17).
  wa_fieldcat_alv-reptext_ddic = 'Date'(a17).
  wa_fieldcat_alv-fieldname    = 'DATE'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  wa_fieldcat_alv-seltext_l = 'Time'(a16).
  wa_fieldcat_alv-seltext_m = 'Time'(a16).
  wa_fieldcat_alv-seltext_s = 'Time'(a16).
  wa_fieldcat_alv-reptext_ddic = 'Time'(a16).
  wa_fieldcat_alv-fieldname    = 'TIME'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Change Type'(a10).
  wa_fieldcat_alv-seltext_m = 'Change Type'(a10).
  wa_fieldcat_alv-seltext_s = 'Change Type'(a10).
  wa_fieldcat_alv-reptext_ddic = 'Change Type'(a10).
  wa_fieldcat_alv-fieldname    = 'CHANGE_TYPE'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  wa_fieldcat_alv-seltext_l = 'Old Value'(a03).
  wa_fieldcat_alv-seltext_m = 'Old Value'(a03).
  wa_fieldcat_alv-seltext_s = 'Old Value'(a03).
  wa_fieldcat_alv-reptext_ddic = 'Old Value'(a03).
  wa_fieldcat_alv-fieldname    = 'VALUE'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'New Value'(a04).
  wa_fieldcat_alv-seltext_m = 'New Value'(a04).
  wa_fieldcat_alv-seltext_s = 'New Value'(a04).
  wa_fieldcat_alv-reptext_ddic = 'New Value'(a04).
  wa_fieldcat_alv-fieldname    = 'NEWVAL'.
  APPEND wa_fieldcat_alv TO it_fieldcat.














* Adjust column positions
  CLEAR: wa_fieldcat_alv.
* wa_fieldcat_alv-col_pos = '01'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'BNAME'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'CONID'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'FUNID'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'FUNTEXT'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'DATE'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'TIME'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'TCODE'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'TTEXT'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'TABLE'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'LOGKEY'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'CHANGE_TYPE'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'FIELDNAME'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'FIELDTEXT'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'VALUE'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'NEWVAL'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'TYPE'.

*  CLEAR: wa_fieldcat_alv.
*  wa_fieldcat_alv-outputlen = 10.
*  MODIFY it_fieldcat FROM wa_fieldcat_alv
*    TRANSPORTING outputlen WHERE fieldname = 'FIELDTEXT'.



ENDFORM.
*---------------------------------------------------------------------*
*       FORM level3_add_texts                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_DISPLAY                                                    *
*---------------------------------------------------------------------*
FORM level3_add_texts
  TABLES it_display STRUCTURE /psyng/sw_level3_display.

  DATA lt_tstct TYPE HASHED TABLE OF tstct
       WITH UNIQUE KEY tcode
  WITH HEADER LINE.
  DATA lt_function TYPE HASHED TABLE OF /psyng/function
       WITH UNIQUE KEY function
  WITH HEADER LINE.

  LOOP AT it_display.
    lt_tstct-tcode = it_display-tcode.
    INSERT lt_tstct INTO TABLE lt_tstct.

    lt_function-function = it_display-funid.
    INSERT lt_function INTO TABLE lt_function.
  ENDLOOP.

  LOOP AT lt_tstct.
    SELECT ttext INTO lt_tstct-ttext FROM tstct
           WHERE sprsl = sy-langu AND  tcode = lt_tstct-tcode.
      MODIFY lt_tstct FROM lt_tstct
             TRANSPORTING ttext
             WHERE tcode = lt_tstct-tcode.
    ENDSELECT.
  ENDLOOP.

  LOOP AT lt_function.
    SELECT description INTO lt_function-description FROM
/psyng/function
              WHERE function = lt_function-function AND vrsio =
sodvrsio
              .
      MODIFY lt_function FROM lt_function
             TRANSPORTING description
             WHERE function = lt_function-function.
    ENDSELECT.
  ENDLOOP.

  LOOP AT it_display.
    READ TABLE lt_tstct WITH TABLE KEY tcode = it_display-tcode.
    IF sy-subrc = 0.
      it_display-ttext = lt_tstct-ttext.
    ENDIF.

    READ TABLE lt_function WITH TABLE KEY function =
 it_display-funid.
    IF sy-subrc = 0.
      it_display-funtext = lt_function-description.
    ENDIF.
    MODIFY it_display.
  ENDLOOP.

  CLEAR: it_display.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM level3_alv_header                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM level3_alv_header.
  DATA: header           TYPE slis_t_listheader,
        wa               TYPE slis_listheader,
        l_count          TYPE i,
        c_count          TYPE string,
        l_alv_grid_titl2 TYPE lvc_title,
        l_date(12)       TYPE c.
  .
  wa-typ = 'H'.
  CONCATENATE 'SOD Analysis based on User Changes SOD Ver'(a26)
*               lvl2st
*               'To'(a21)
*               lvl2ed
               sodvrsio
              INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*SOD Version.
  wa-typ = 'S'.
  wa-key = 'Sod Version'(a21).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  CONCATENATE sodvrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
**Date
*  wa-typ = 'S'.
*  wa-key = 'Date'(a22).
*  WRITE sy-datum TO l_date.
*  wa-info = l_date.
*  APPEND wa TO header.
*Start Date for changes
  wa-typ = 'S'.
  wa-key = 'From'(a23).
  wa-info = lvl2st.
  APPEND wa TO header.
*End Date for changes
  wa-typ = 'S'.
  wa-key = 'To'(a24).
  wa-info = lvl2ed.
  APPEND wa TO header.
  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = header.
ENDFORM.
