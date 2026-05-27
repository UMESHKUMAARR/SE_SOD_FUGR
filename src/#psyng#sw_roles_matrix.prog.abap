*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_ROLES_MATRIX
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sw_roles_matrix MESSAGE-ID /psyng/basis.
INCLUDE /psyng/basis_exelog.
TYPE-POOLS : slis, abap.
TYPES: BEGIN OF ty_function,
         function    TYPE /psyng/function_id,
         description TYPE /psyng/fundsc,
       END OF ty_function.
TABLES : agr_define, agr_users, usr02.
TABLES: /psyng/conflict, /psyng/function.
DATA :
  lt_roleconflicts TYPE TABLE OF /psyng/sw_out_routput
                   WITH HEADER LINE,
  lt_exe           TYPE TABLE OF /psyng/user_role_tcode_exe
                   WITH HEADER LINE,
  lt_lexe          TYPE TABLE OF /psyng/user_role_exe
                   WITH HEADER LINE,
  lt_function      TYPE STANDARD TABLE OF ty_function,
  ls_function      LIKE LINE OF lt_function,
  l_vrsn_flag      TYPE flag,   "HBHALLA
  BEGIN OF gt_functtran OCCURS 0,
    mandt	     TYPE mandt,
    functionid TYPE /psyng/function_id,
    tcode	     TYPE tcode,
    vrsio	     TYPE /psyng/sodvrsio,
    type       TYPE /psyng/tcodetype,
    fioriid	   TYPE /psyng/sw_fioriid,
  END OF gt_functtran,
  gr_table        TYPE REF TO data,
  gr_rec          TYPE REF TO data,
  l_cnt           TYPE i,
  gt_fieldcat_alv TYPE slis_t_fieldcat_alv,
  gs_fieldcat_alv TYPE slis_fieldcat_alv,
  gs_layout       TYPE slis_layout_alv,
  ls_color        TYPE lvc_s_scol,
  lf_se_installed TYPE flag,
  lf_se_version   TYPE /psyng/prog_vrsio,
  lf_ta_installed TYPE flag,
  lf_ta_version   TYPE /psyng/prog_vrsio,
  gt_role_users   TYPE TABLE OF /psyng/sw_sel_opts_xubname
                    WITH HEADER LINE,
  gv_program      LIKE sy-repid,
  gt_sort         TYPE slis_t_sortinfo_alv,
  gs_sort         TYPE slis_sortinfo_alv.


FIELD-SYMBOLS : <fs_tab>        TYPE STANDARD TABLE,
                <fs_rec>        TYPE agr_tcodes,
                <fs_o>          TYPE any,
                <fs_dynfield>   TYPE any,
                <fs_dynfield_h> TYPE any,
                <ta_color>      TYPE lvc_t_scol
                .
CONSTANTS :
  c_fm_sw036 TYPE rs38l_fnam VALUE '/PSYNG/SW_036',
  c_fm_sw028 TYPE rs38l_fnam VALUE '/PSYNG/SW_028',
  c_fm_ta071 TYPE rs38l_fnam VALUE '/PSYNG/BC_USRHIS_071'.


RANGES : r_conid FOR lt_roleconflicts-conid,
         r_tcode FOR sy-tcode.


SELECTION-SCREEN: BEGIN OF BLOCK date_o WITH FRAME TITLE text-b01  .
SELECT-OPTIONS :          dates FOR sy-datum.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  01(8) text-b03 USER-COMMAND m_but.
SELECTION-SCREEN PUSHBUTTON  10(8) text-b04 USER-COMMAND hy_but.
SELECTION-SCREEN PUSHBUTTON  19(8) text-b05 USER-COMMAND y_but.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN: END OF BLOCK date_o .

SELECTION-SCREEN: BEGIN OF BLOCK usr_o WITH FRAME TITLE text-b02  .
PARAMETERS : p_vrsio      TYPE /psyng/sodvrsio.
SELECT-OPTIONS : s_roles  FOR agr_define-agr_name OBLIGATORY.
SELECT-OPTIONS : s_class  FOR usr02-class.
SELECT-OPTIONS : s_users  FOR usr02-bname.
SELECTION-SCREEN: END OF BLOCK usr_o .

** --Look for input data errors
AT SELECTION-SCREEN ON p_vrsio.
  IF p_vrsio IS NOT INITIAL.
    SELECT SINGLE COUNT(*) INTO sy-index FROM /psyng/swsodvers WHERE
    vrsio EQ p_vrsio.
    IF sy-subrc NE 0.
      MESSAGE e113 WITH 'SOD version not found:' p_vrsio.
    ENDIF.
  ENDIF.

AT SELECTION-SCREEN ON s_users.
  IF s_users[] IS NOT INITIAL.
    SELECT SINGLE COUNT(*) INTO sy-index FROM usr02 WHERE bname IN
    s_users.
    IF sy-subrc NE 0.
      MESSAGE e113 WITH 'User not found:' s_users-low.
    ENDIF.
  ENDIF.

AT SELECTION-SCREEN ON s_class.
  IF s_class[] IS NOT INITIAL.
    SELECT SINGLE COUNT(*) INTO sy-index FROM usr02 WHERE class IN
    s_class.
    IF sy-subrc NE 0.
      MESSAGE e113 WITH 'User group not found:' s_class-low.
    ENDIF.
  ENDIF.

AT SELECTION-SCREEN ON s_roles.
  IF s_roles[] IS NOT INITIAL.
    SELECT SINGLE COUNT(*) INTO sy-index FROM agr_define WHERE agr_name
    IN s_roles.
    IF sy-subrc NE 0.
      MESSAGE e113 WITH 'Roles not found:' s_roles-low.
    ENDIF.
  ENDIF.



INITIALIZATION.
  gv_program = sy-repid.
*--Check if SE and TA are installed
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
    EXPORTING
      i_module         = 'SE'
    IMPORTING
      e_installed      = lf_se_installed
      e_module_version = lf_se_version.

  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
    EXPORTING
      i_module         = 'TA'
    IMPORTING
      e_installed      = lf_ta_installed
      e_module_version = lf_ta_version.

  IF NOT lf_se_installed = 'X' OR NOT lf_ta_installed = 'X'.
    MESSAGE e113(/psyng/basis) WITH 'Functionality only available if'
    'Modules SE and TA are installed'.
  ENDIF.

*BOC: HBHALLA
clear l_vrsn_flag.
if lf_se_version CP '*Q*'.
  l_vrsn_flag = 'X'.
  endif.
  IF     lf_se_version < '3.1' and l_vrsn_flag is INITIAL.
    MESSAGE e017(/psyng/basis) WITH
    'Separations Enforcer' 'SE' '3.1' 'this system'.
  ENDIF.
* END OF CHANGE: HBHALLA

  IF lf_ta_version < '2.4'.
    MESSAGE e017(/psyng/basis) WITH
    'Transaction Archive' 'TA' '2.4' 'this system'.
  ENDIF.

  IF dates[] IS INITIAL.
    dates-sign   = 'I'.
    dates-option = 'BT'.
    dates-low    = sy-datum - 30.
    dates-high   = sy-datum.
    APPEND dates.
  ENDIF.


AT SELECTION-SCREEN.
  CASE sy-ucomm.
    WHEN 'M_BUT'.
      REFRESH dates.
      dates-sign   = 'I'.
      dates-option = 'BT'.
      dates-low    = sy-datum - 30.
      dates-high   = sy-datum.
      APPEND dates.
    WHEN 'HY_BUT'.
      REFRESH dates.
      dates-sign   = 'I'.
      dates-option = 'BT'.
      dates-low    = sy-datum - ( 365 / 2 ).
      dates-high   = sy-datum.
      APPEND dates.
    WHEN 'Y_BUT'.
      REFRESH dates.
      dates-sign   = 'I'.
      dates-option = 'BT'.
      dates-low    = sy-datum - 365 .
      dates-high   = sy-datum.
      APPEND dates.
  ENDCASE.

START-OF-SELECTION.

*BOC AKUMAR SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-25/11/2024
  exelog sy-repid ''.

*--Execute SOD Analysis on role
  CALL FUNCTION c_fm_sw036 "#EC PATHLOCK_CI_DYN_ACCES
    EXPORTING
      vrsio      = p_vrsio
    TABLES
      it_roles   = s_roles
      ot_routput = lt_roleconflicts.
  IF NOT lt_roleconflicts[] IS INITIAL.
*--Collect  and collect the conflicts
    r_conid-sign   = 'I'.
    r_conid-option = 'EQ'.
    r_tcode-sign   = 'I'.
    r_tcode-option = 'EQ'.

    LOOP AT lt_roleconflicts.
      r_conid-low = lt_roleconflicts-conid.
      COLLECT r_conid.
    ENDLOOP.
    CALL FUNCTION c_fm_sw028 "#EC PATHLOCK_CI_DYN_ACCES
      EXPORTING
        i_vrsio      = p_vrsio
      TABLES
        it_spconfs   = r_conid
        et_functtran = gt_functtran.
    PERFORM get_tcodes_from_objects.
*--Collect the relevant tcodes
    LOOP AT gt_functtran.
      r_tcode-low = gt_functtran-tcode.
      COLLECT r_tcode.
    ENDLOOP.

* Get all the Functional descriptions.
    IF lines( gt_functtran ) GT 0.
      SELECT function description INTO TABLE lt_function FROM
      /psyng/function
                                           FOR ALL ENTRIES IN
                                           gt_functtran
                                                        WHERE function
                                                        EQ
gt_functtran-functionid
                                                          AND vrsio
                                                          EQ p_vrsio.
    ENDIF.

    CALL FUNCTION '/PSYNG/BC_USRHIS_071'
      EXPORTING
        if_summarized_by   = 'O' "Overall Basis
        if_role_type       = 'S'
        if_srole_dir_ind   = 'X'
        if_role_tcode_dtl  = 'X'
        i_batch_size       = 0
        i_min_common_roles = 0
      TABLES
        it_users           = s_users
        it_class           = s_class
        it_date            = dates
        it_tcode           = r_tcode
        it_roles           = s_roles
        ot_urolexe         = lt_lexe
        ot_uroltc_exe      = lt_exe
      EXCEPTIONS
        invalid_role_type  = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.
*--get rid of tcodes in matrix but not in roles
    REFRESH :  r_tcode,gt_role_users .
    gt_role_users-sign   = 'I'.
    gt_role_users-option = 'EQ'.

* Where no execution of conflicting tcodes, we should see
* no ALV grid but a status bar message.
    IF lines( lt_exe ) EQ 0.
      MESSAGE s002(/psyng/sw) WITH
          'No execution of conflicting tcodes'(004).
      LEAVE LIST-PROCESSING.
    ENDIF.


    LOOP AT lt_exe.
      r_tcode-low = lt_exe-tcode.
*      IF ( exeonly = 'X' AND  lt_exe-tot_diasteps > 0 )
*      OR exeonly IS INITIAL.
**--Delete all tcodes that were never executed
      COLLECT r_tcode.
*      ENDIF.
*--Collect the role users for drilldown
      gt_role_users-low =  lt_exe-bname.
      COLLECT gt_role_users.

    ENDLOOP.
    IF r_tcode[] IS INITIAL.
      REFRESH gt_functtran.
    ELSE.
      DELETE gt_functtran WHERE NOT  tcode IN r_tcode.
    ENDIF.
    DEFINE clean_tcode.
      while &1 cs '-'.
        replace '-' with '_' into &1.
      endwhile.
      while &1 cs '.'.
        replace '.' with '_' into &1.
      endwhile.
    END-OF-DEFINITION.

    PERFORM create_dynamic_table.

    DEFINE assign_value.
      assign component &1 of structure <fs_o> to <fs_dynfield>.
      <fs_dynfield> = &2.
      unassign <fs_dynfield>.
    END-OF-DEFINITION.

    SORT lt_roleconflicts BY agr_name conid functionid.
    SORT lt_function BY function.
    LOOP AT lt_roleconflicts.
      READ TABLE lt_function INTO ls_function WITH KEY function =
      lt_roleconflicts-functionid
BINARY SEARCH.
      assign_value 'AGR_NAME' lt_roleconflicts-agr_name.
      assign_value 'CONID'    lt_roleconflicts-conid.
      assign_value 'CDESCR'   lt_roleconflicts-description.
      assign_value 'FUNID'    lt_roleconflicts-functionid.
      assign_value 'FDESCR'   ls_function-description.
      assign_value 'IMP'      lt_roleconflicts-imp.

      LOOP AT gt_functtran WHERE functionid EQ
      lt_roleconflicts-functionid
                             AND type EQ 'T'. "Tranactions.
        CLEAR l_cnt.
        LOOP AT lt_exe WHERE agr_name = lt_roleconflicts-agr_name AND
                             tcode    = gt_functtran-tcode.
*--Each record represents 1 user using it
*--if we want something different than nr of users,
*        use other fields like "add TOT_DIASTEPS to l_cnt", days_used ..
          CHECK lt_exe-tot_diasteps > 0.
          ADD 1 TO l_cnt.
        ENDLOOP.
*--Assign a color to the cell
        UNASSIGN <fs_dynfield>.
        ASSIGN COMPONENT  'COLORS' OF STRUCTURE <fs_o> TO <ta_color>.
        ls_color-fname = gt_functtran-tcode.
        clean_tcode ls_color-fname.
        IF l_cnt > 0.
          ls_color-color-col = 6.  "Red = used
          ls_color-color-int = 0.
        ELSE.
          ls_color-color-col = 5.  "Green = not used
          ls_color-color-int = 1.
        ENDIF.
        APPEND ls_color TO <ta_color>.
        CLEAR ls_color.
        clean_tcode gt_functtran-tcode.
        assign_value gt_functtran-tcode l_cnt.
      ENDLOOP.
      APPEND <fs_o> TO <fs_tab>.
      CLEAR <fs_o>.
    ENDLOOP.

*--Output ALV
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        it_fieldcat             = gt_fieldcat_alv[]
        is_layout               = gs_layout
        i_callback_program      = gv_program
        i_callback_user_command = 'CONFLICT_HOTSPOT'
        it_sort                 = gt_sort
      TABLES
        t_outtab                = <fs_tab>
      EXCEPTIONS
        program_error           = 1
        OTHERS                  = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ELSE.
    MESSAGE s002(/psyng/sw) WITH
     'No Data found for the corresponding input'(003).
    LEAVE LIST-PROCESSING.
  ENDIF. .


*---------------------------------------------------------------------*
*       FORM CONFLICT_HOTSPOT                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM conflict_hotspot USING r_ucomm LIKE sy-ucomm
                            rs_selfield TYPE slis_selfield.
  DATA : iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.
  FIELD-SYMBOLS: <role> TYPE any.

  IF rs_selfield-value > 0.
    READ TABLE <fs_tab> ASSIGNING <fs_o> INDEX rs_selfield-tabindex.
    ASSIGN COMPONENT 1 OF STRUCTURE <fs_o> TO <role>.
    LOOP AT lt_exe WHERE tot_diasteps GT 0
                     AND tcode EQ rs_selfield-fieldname
                     AND agr_name EQ <role>.
      iseltab-selname = 'S_USERS'.
      iseltab-kind    = 'S'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = lt_exe-bname.
      APPEND iseltab.
    ENDLOOP.

    iseltab-selname = 'S_TCODE'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = rs_selfield-fieldname.
    APPEND iseltab.

    iseltab-selname = 'S_DATE'.
    iseltab-kind    = 'S'.
    iseltab-sign    = dates-sign.
    iseltab-option  = dates-option.
    iseltab-low     = dates-low.
    iseltab-high    = dates-high.
    APPEND iseltab.

    SUBMIT /psyng/bc_usrhis_36 WITH SELECTION-TABLE iseltab AND RETURN.

  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  get_tcodes_from_objects
*&---------------------------------------------------------------------*
*       Get transaction codes from Function Objects definition for
*       SOD Live analysis.
*       This ensures that even functions with placeholder tcodes
*      can be analyzed with SOD Live
*      This only supports S_TCODE TCD entries with only a Tcode in the
*      val_from field, no ranges, no wildcards
*----------------------------------------------------------------------*
FORM get_tcodes_from_objects.

  DATA :
    BEGIN OF lt_faobj OCCURS 0,
      funid    TYPE /psyng/function_id,
      val_from TYPE xuvalue,
    END OF  lt_faobj,
    l_tabname TYPE tabname VALUE '/PSYNG/FAOBJ2'.

  SELECT funid val_from
*--> BOC PN 11269 - ATC fixes - HBHALLA - 23/01/25
*  FROM (l_tabname) INTO TABLE lt_faobj "#EC SAST_CI_GEN_CHECK
  FROM /PSYNG/FAOBJ2 INTO TABLE lt_faobj "#EC SAST_CI_GEN_CHECK
*--> EOC PN 11269 - ATC fixes - HBHALLA - 23/01/25
  WHERE  vrsio  = p_vrsio   AND
         object = 'S_TCODE' AND
         field  = 'TCD'     AND
         val_to = ''.

  LOOP AT lt_faobj.
    CHECK lt_faobj-val_from NS '*' .
    gt_functtran-functionid = lt_faobj-funid.
    gt_functtran-tcode      = lt_faobj-val_from.
    APPEND gt_functtran.
  ENDLOOP.
ENDFORM.                    " get_tcodes_from_objects
*&---------------------------------------------------------------------*
*&      Form  create_dynamic_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_dynamic_table.
  DATA : lt_fieldcat TYPE lvc_t_fcat,
         ls_fieldcat TYPE lvc_s_fcat,
         l_tcode     TYPE xutcode.
  DEFINE add_field.
    ls_fieldcat-fieldname  = &1.
    ls_fieldcat-seltext    = &2.
    ls_fieldcat-intlen     = &3.
    ls_fieldcat-inttype    = &4.
    ls_fieldcat-col_opt    = abap_true.
    ls_fieldcat-fix_column = &5.
    ls_fieldcat-emphasize  = &6.
    ls_fieldcat-hotspot    = &7.

    append ls_fieldcat to lt_fieldcat.

  END-OF-DEFINITION.

  add_field 'AGR_NAME' 'Role'        '30'  'C' 'X' space space.
  add_field 'CONID'    'Conflict'    '12'  'C' 'X' space space.
  add_field 'CDESCR'   'Description' '200' 'C' 'X' space space.
  add_field 'FUNID'    'Function'    '12'  'C' 'X' space space.
  add_field 'FDESCR'   'Description' '200' 'C' 'X' space space.
  add_field 'IMP'      'Severity'    '08'  'C' 'X' space space.
  SORT r_tcode.
  LOOP AT r_tcode.
    l_tcode = r_tcode-low.
    clean_tcode l_tcode.
    add_field l_tcode r_tcode-low '5' 'N' '' '' 'X'.
  ENDLOOP.

*--Allow coloring
  ls_fieldcat-tech = 'X'.
  ls_fieldcat-fieldname = 'COLORS'.
  ls_fieldcat-ref_field = 'COLTAB'.
  ls_fieldcat-ref_table = 'CALENDAR_TYPE'.
  ls_fieldcat-scrtext_s = ls_fieldcat-scrtext_m =
  ls_fieldcat-scrtext_l = 'COLOR'.
  APPEND ls_fieldcat TO lt_fieldcat.


*--Create a dynamic table to contain our data
  CALL METHOD cl_alv_table_create=>create_dynamic_table
    EXPORTING
      it_fieldcatalog           = lt_fieldcat
    IMPORTING
      ep_table                  = gr_table
    EXCEPTIONS
      generate_subpool_dir_full = 1
      OTHERS                    = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  ASSIGN gr_table->* TO <fs_tab>.
  CREATE DATA gr_rec LIKE LINE OF <fs_tab>.
  ASSIGN gr_rec->* TO <fs_o>.

*--Also prepare ALV Field Catalog
*--Create a field catalog
  LOOP AT lt_fieldcat INTO ls_fieldcat.
    MOVE-CORRESPONDING ls_fieldcat TO gs_fieldcat_alv.
    gs_fieldcat_alv-seltext_s = ls_fieldcat-seltext.
    gs_fieldcat_alv-seltext_m = ls_fieldcat-seltext.
    gs_fieldcat_alv-seltext_l = ls_fieldcat-seltext.
    gs_fieldcat_alv-outputlen = 12.
*      gs_fieldcat_alv-COL_OPT   = 'X'.
    gs_fieldcat_alv-do_sum    = 'X'.
    APPEND gs_fieldcat_alv TO gt_fieldcat_alv.
  ENDLOOP.

  gs_layout-zebra = 'X'.
  gs_layout-colwidth_optimize = 'X'.
  gs_layout-coltab_fieldname = 'COLORS'.

*--Create Sort Table
  CLEAR gs_sort.
  gs_sort-tabname = '<fs_tab>'.
  gs_sort-up = 'X'.
  ADD 1 TO gs_sort-spos.
  gs_sort-fieldname = 'AGR_NAME'.
  APPEND gs_sort TO gt_sort.
  ADD 1 TO gs_sort-spos.
  gs_sort-fieldname = 'CONID'.
  APPEND gs_sort TO gt_sort.
  ADD 1 TO gs_sort-spos.
  gs_sort-fieldname = 'CDESCR'.
  APPEND gs_sort TO gt_sort.
  ADD 1 TO gs_sort-spos.
  gs_sort-fieldname = 'FUNID'.
  APPEND gs_sort TO gt_sort.
  ADD 1 TO gs_sort-spos.
  gs_sort-fieldname = 'FDESCR'.
  APPEND gs_sort TO gt_sort.
  ADD 1 TO gs_sort-spos.
  gs_sort-fieldname = 'IMP'.
  APPEND gs_sort TO gt_sort.


ENDFORM.                    " create_dynamic_table
