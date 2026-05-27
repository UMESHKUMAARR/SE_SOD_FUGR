REPORT /psyng/cri_tcode_list_byrole  MESSAGE-ID /psyng/sw.

TABLES : agr_define,rfcdes,/psyng/critcodes,tstct.
TYPE-POOLS:slis.


DATA : gt_rfcdest TYPE TABLE OF rfcdes WITH HEADER LINE,
       gt_functtran TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
       gt_function TYPE TABLE OF /psyng/function WITH HEADER LINE,
       g_rolecount TYPE i,
       gf_invalid_rfc TYPE C,
       ls_ba_role           type /PSYNG/BC_BA_00.

DATA : BEGIN OF gt_output OCCURS 0,
         agr_name LIKE agr_define-agr_name,
         text LIKE agr_texts-text,
         tcode LIKE tstc-tcode,
         tcode_text(80),
         rfcdest LIKE rfcdes-rfcdest,
         imp   LIKE /psyng/critcodes-imp,
         owner LIKE /psyng/critcodes-owner,
         busarea LIKE /psyng/critcodes-busarea,
         function LIKE /psyng/function-function,
         description LIKE /psyng/function-description,
         child_agr LIKE agr_define-agr_name,
       END OF gt_output,

       BEGIN OF gt_roles_tcode OCCURS 0,
         rfcdest TYPE rfcdes-rfcdest,
         agr_name TYPE agr_define-agr_name,
         tcode TYPE tstc-tcode,
       END OF gt_roles_tcode,

       BEGIN OF gt_roles OCCURS 0,
         rfcdest TYPE rfcdes-rfcdest,
         agr_name TYPE agr_define-agr_name,
         child_agr TYPE agr_define-agr_name,
       END OF gt_roles,


       BEGIN OF gt_roles_text OCCURS 0,
         rfcdest TYPE rfcdes-rfcdest,
         agr_name TYPE agr_define-agr_name,
         text TYPE agr_texts-text,
       END OF gt_roles_text,

       gt_critcodes TYPE TABLE OF /psyng/critcodes WITH HEADER LINE,
       gt_tstct TYPE TABLE OF tstct WITH HEADER LINE,
       gt_fieldcat TYPE slis_t_fieldcat_alv,
        gs_fieldcat TYPE slis_fieldcat_alv,
        g_repid TYPE sy-repid,
        gt_sort_sum  TYPE slis_t_sortinfo_alv,
        gs_sort_sum TYPE slis_sortinfo_alv.

DEFINE sort_alv.
  gs_sort_sum-spos = &1.
  gs_sort_sum-fieldname = &2.
  gs_sort_sum-tabname =  &3.
  gs_sort_sum-up = 'X'.
  append gs_sort_sum to &4.
END-OF-DEFINITION.

DEFINE adjust.
  gs_fieldcat-seltext_l      = &2.
  gs_fieldcat-seltext_m      = &2.
  gs_fieldcat-seltext_s      = &2.
  gs_fieldcat-reptext_ddic   = &2.
  gs_fieldcat-just           = 'X'.
  gs_fieldcat-key            = ' '.
  gs_fieldcat-hotspot        = &3.
  gs_fieldcat-col_pos        = &4.
  gs_fieldcat-checkbox       = &5.
  modify &1 from gs_fieldcat
                    transporting
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      checkbox
                      just
                      hotspot
                      col_pos
                   where
                      fieldname = &6.
END-OF-DEFINITION.


SELECTION-SCREEN: BEGIN OF BLOCK exe WITH FRAME TITLE text-001.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  68(12) text-002 USER-COMMAND verify_r
                                      MODIF ID usr.
SELECTION-SCREEN END OF LINE.
SELECT-OPTIONS: roles FOR agr_define-agr_name.
select-options : rba for ls_ba_role-busarea.

SELECTION-SCREEN: BEGIN OF LINE.

SELECTION-SCREEN: COMMENT 1(21) text-003 MODIF ID rol.
SELECTION-SCREEN: POSITION 33.
PARAMETERS:   rchdatf LIKE agr_define-change_dat MODIF ID rol.
SELECTION-SCREEN: COMMENT 47(3) text-004 MODIF ID rol.
SELECTION-SCREEN: POSITION 53.
PARAMETERS:   rchdatt LIKE agr_define-change_dat MODIF ID rol.
SELECTION-SCREEN PUSHBUTTON  65(10) text-005 USER-COMMAND shrl
MODIF ID rol.
SELECTION-SCREEN: END OF LINE.

PARAMETERS : singrol TYPE flag DEFAULT 'X'.
PARAMETERS : comprol TYPE flag DEFAULT 'X'.
PARAMETERS : assgn_r TYPE flag DEFAULT ' '.
SELECTION-SCREEN: END OF BLOCK exe.

*-- Remote Option
SELECTION-SCREEN: BEGIN OF BLOCK rem WITH FRAME TITLE text-006.
SELECT-OPTIONS: remrfc FOR rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll MODIF ID rem.
PARAMETERS:remote AS CHECKBOX USER-COMMAND remo DEFAULT ' '.
SELECTION-SCREEN: END OF BLOCK rem.

*-- Critical tcode Restriction
SELECTION-SCREEN: BEGIN OF BLOCK tcd WITH FRAME TITLE text-007.
SELECT-OPTIONS: s_tcode FOR tstct-tcode.             "Tcode
SELECT-OPTIONS: s_imp FOR /psyng/critcodes-imp.
SELECT-OPTIONS: s_owner FOR /psyng/critcodes-owner.
SELECT-OPTIONS: s_busare FOR /psyng/critcodes-busarea.
PARAMETER : p_sodvrs LIKE /psyng/conflict-vrsio DEFAULT '0'.
SELECTION-SCREEN: END OF BLOCK tcd .

*-- Output Block
SELECTION-SCREEN: BEGIN OF BLOCK blk2 WITH FRAME TITLE text-008.
PARAMETERS : sumfunc TYPE flag MODIF ID out user-command a.
PARAMETERS : p_noct TYPE flag MODIF ID out user-command a.
SELECTION-SCREEN: END OF BLOCK blk2.



INITIALIZATION.
  PERFORM get_initial_config.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tcode-low.
  PERFORM f4_tcodes CHANGING s_tcode-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tcode-high.
  PERFORM f4_tcodes CHANGING s_tcode-high.

AT SELECTION-SCREEN.
  SET PARAMETER ID '/PSYNG/VRSIO' FIELD p_sodvrs.
  PERFORM selection_screen.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-name .
      WHEN 'P_NOCT'.
*--Disable Show no SOD when conflict ID's are restricted
        IF NOT s_tcode[] IS INITIAL OR NOT s_imp[] IS INITIAL
        OR NOT s_owner[] IS INITIAL OR NOT s_busare[] IS INITIAL.
          IF p_noct = 'X'.
            CLEAR p_noct .
            screen-input = 0.
            MESSAGE w398(00) WITH text-c03 text-c04.
          ENDIF.
          MODIFY SCREEN.
        ENDIF.
    ENDCASE.
  ENDLOOP.


START-OF-SELECTION.
*BOC UMITTAL SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
*--Clear system filter buffer when a new analysis starts
CALL FUNCTION '/PSYNG/SW_124'
  EXPORTING
    IF_CLEAR_BUFFER = 'X'
"(++)BOC UMITTAL SE VF scan-25/11/2024
  EXCEPTIONS
    TOO_MANY_OPTIONS = 1
    OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.      .

*-- Validate SOD Version
  DATA : l_vrsio TYPE /psyng/sodvrsio.
*--If we use a local sod matrix, validate it exists
  SELECT SINGLE vrsio INTO (l_vrsio) FROM /psyng/swsodvers
  WHERE vrsio = p_sodvrs.
  IF sy-subrc NE 0.
    MESSAGE i135 WITH 'SOD Version does not exist.'(195).
    LEAVE LIST-PROCESSING.
  ENDIF.


  IF NOT remrfc[] IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.

  IF NOT remote = 'X'.
    CONCATENATE sy-sysid sy-mandt INTO gt_rfcdest-rfcoptions.
    gt_rfcdest-rfcdest = 'LOCAL'.
    APPEND gt_rfcdest.
  ENDIF.

  PERFORM get_critical_tcodes.
  PERFORM get_data.
  PERFORM process_data.
  PERFORM display_output.




*&---------------------------------------------------------------------*
*&      Form  get_initial_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_initial_config.
  DATA: l_table(6) TYPE c,
        lt_tvarv   TYPE TABLE OF tvarv WITH HEADER LINE.

*---Get sod version default
  CALL FUNCTION '/PSYNG/SW_034'
       IMPORTING
            e_vrsio = p_sodvrs.


*--Default RFC
  IF remrfc[] IS INITIAL.
    IF sy-saprl >= '620'.
*      l_table = 'TVARVC'.
      SELECT * INTO CORRESPONDING FIELDS OF TABLE
        lt_tvarv FROM tvarvc
           WHERE name = '/PSYNG/USER_XRFC'
             AND type = 'S'.
    ELSE.
*      l_table = 'TVARV'.
      SELECT * INTO CORRESPONDING FIELDS OF TABLE
        lt_tvarv FROM tvarv
           WHERE name = '/PSYNG/USER_XRFC'
             AND type = 'S'.
    ENDIF.
*    SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_tvarv FROM (l_table)
*           WHERE name = '/PSYNG/USER_XRFC'
*             AND type = 'S'. "#EC SAST_CI_GEN_CHECK
*HBHALLA: As table name is variable so it can’t be fixed. (13/12/24)

    LOOP AT lt_tvarv.
      MOVE-CORRESPONDING lt_tvarv TO remrfc.
      remrfc-option = lt_tvarv-opti.
      APPEND remrfc.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " get_initial_config
*&---------------------------------------------------------------------*
*&      Form  selection_screen
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM selection_screen.

  IF sy-ucomm = 'SHRL'.
    PERFORM show_roles_based_on_dates.
  ENDIF.

  IF sy-ucomm = 'VERIFY_R'.
    PERFORM get_roles_count.
    EXIT.
  ENDIF.

  IF comprol IS INITIAL AND singrol IS INITIAL.
    MESSAGE e208(00) WITH
    'Select either Composite or Single Roles or both'(163).
  ENDIF.

  IF  NOT rchdatf IS INITIAL.
    IF rchdatt IS INITIAL .
      rchdatt = '99991231'.
    ENDIF.
    IF rchdatf > rchdatt.
      SET CURSOR FIELD 'RCHDATT'.
      MESSAGE e650(db).
    ENDIF.
  ELSEIF roles IS INITIAL AND sy-ucomm+0(1) <> '%' AND
                               sy-ucomm <> 'SHRL' AND
                               sy-ucomm <> 'RADI' AND
                               sy-ucomm NP '*BUT' AND
                               sy-ucomm <> 'SHOW'.
  ENDIF.
*--- Only remote analysis Check
  IF sy-ucomm = 'REMO'.
    IF remote = 'X'.
      IF remrfc[] IS INITIAL.
        MESSAGE w140(/psyng/sw) WITH
        'Please enter RFC destinations for remote analysis'(180).
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.                    " selection_screen
*&---------------------------------------------------------------------*
*&      Form  show_roles_based_on_dates
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_roles_based_on_dates.
  DATA: ltagr_define LIKE agr_define OCCURS 0 WITH HEADER LINE.
  DATA: lifield_dif LIKE field_dif OCCURS 0 WITH HEADER LINE.
  DATA: lheader(80), lv_count TYPE i, lv_count_char(9).
  DATA: lwa_iagr_define TYPE agr_define.

  DATA: lt_roles TYPE TABLE OF /psyng/comp_role_tcode,
        ls_roles TYPE /psyng/comp_role_tcode,
        lt_range_roles TYPE TABLE OF /psyng/range_agr_name,
        ls_range_roles TYPE /psyng/range_agr_name.

  IF rchdatf IS INITIAL.
    MESSAGE i208(00) WITH 'Please enter FROM date for roles'(096).
    EXIT.
  ENDIF.
  REFRESH ltagr_define.
   CALL FUNCTION '/PSYNG/SW_GET_ROLES'
         EXPORTING
              i_composite_roles = comprol
              i_single_roles    = singrol
              i_assigned_roles  = assgn_r
              i_rchdatf         = rchdatf
              i_rchdatt         = rchdatt
              i_get_actual_data = 'X'
         TABLES
              it_roles          = roles
              it_ba             = rba
              et_roles          = lt_roles.
    ls_range_roles-sign   = 'I'.
    ls_range_roles-option = 'EQ'.
  LOOP AT lt_roles INTO ls_roles.
    ls_range_roles-low = ls_roles-agr_name.
    APPEND ls_range_roles TO lt_range_roles.
  ENDLOOP.
  IF lt_range_roles IS NOT INITIAL.
  SELECT agr_name create_dat change_usr change_dat change_tim
             INTO CORRESPONDING FIELDS OF lwa_iagr_define
             FROM agr_define
             WHERE agr_name IN lt_range_roles.
    IF rchdatf IS INITIAL.
      INSERT lwa_iagr_define INTO TABLE ltagr_define.
    ELSE.
      IF lwa_iagr_define-change_dat IS INITIAL.
        CHECK lwa_iagr_define-create_dat >= rchdatf AND
              lwa_iagr_define-create_dat <= rchdatt.
        INSERT lwa_iagr_define INTO TABLE ltagr_define.
      ELSE.
        CHECK lwa_iagr_define-change_dat >= rchdatf AND
              lwa_iagr_define-change_dat <= rchdatt.
        INSERT lwa_iagr_define INTO TABLE ltagr_define.
      ENDIF.
    ENDIF.
  ENDSELECT.
  ENDIF.

  IF NOT ltagr_define[] IS INITIAL.
  lifield_dif-tabname = 'AGR_DEFINE'.
  lifield_dif-fieldname = 'PARENT_AGR'.
  lifield_dif-no_display = 'X'.
  APPEND lifield_dif.
  lifield_dif-fieldname = 'CREATE_USR'.
  APPEND lifield_dif.
  lifield_dif-fieldname = 'CREATE_DAT'.
  APPEND lifield_dif.
  lifield_dif-fieldname = 'CREATE_TIM'.
  APPEND lifield_dif.
  lifield_dif-fieldname = 'CREATE_TMP'.
  APPEND lifield_dif.
  lifield_dif-fieldname = 'CHANGE_TMP'.
  APPEND lifield_dif.
  lifield_dif-fieldname = 'ATTRIBUTES'.
  APPEND lifield_dif.

  DESCRIBE TABLE ltagr_define LINES lv_count.
  MOVE lv_count TO lv_count_char.
  CONCATENATE lv_count_char 'Selected Roles'(134) INTO lheader
              SEPARATED BY space.

  CALL FUNCTION 'STC1_POPUP_WITH_TABLE_CONTROL'
       EXPORTING
            header         = lheader
            tabname        = 'AGR_DEFINE'
            display_only   = 'X'
            endless        = 'X'
            display_toggle = 'X'
            no_insert      = 'X'
            no_delete      = 'X'
            no_move        = 'X'
            no_undo        = 'X'
            no_button      = 'X'
            x_end          = 90
       TABLES
            table          = ltagr_define
            fielddif       = lifield_dif
       EXCEPTIONS
          NO_MORE_TABLES    = 1
          TOO_MANY_FIELDS   = 2
          NAMETAB_NOT_VALID = 3
          HANDLE_NOT_VALID  = 4
          OTHERS            = 5.

  IF sy-subrc <> 0.
 MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
  ELSE.
    MESSAGE i002 WITH 'No valid roles found'(n03).
    EXIT.
  ENDIF.
ENDFORM.                    " show_roles_based_on_dates
*&---------------------------------------------------------------------*
*&      Form  get_roles_count
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_roles_count.
  DATA : lt_roles TYPE TABLE OF agr_define WITH HEADER LINE,
         lt_assnroles TYPE TABLE OF agr_users WITH HEADER LINE,
         l_numb TYPE i,
         l_total_num TYPE i.
  RANGES: idatseltab FOR sy-datum.

  PERFORM rfc_validations.
  CHECK gf_invalid_rfc  IS INITIAL.
  if remote is initial.
    CALL FUNCTION '/PSYNG/SW_GET_ROLES'
         EXPORTING
              i_composite_roles = comprol
              i_single_roles    = singrol
              i_assigned_roles  = assgn_r
              i_rchdatf         = rchdatf
              i_rchdatt         = rchdatt
         IMPORTING
              e_count           = l_numb
         TABLES
              it_roles          = roles
              it_ba             = rba.


  ADD l_numb TO l_total_num.
  endif.
*-- Adding remote roles count
  LOOP AT gt_rfcdest.
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
    CALL FUNCTION '/PSYNG/SW_GET_ROLES'
    DESTINATION gt_rfcdest-rfcdest
         EXPORTING
              i_composite_roles = comprol
              i_single_roles    = singrol
              i_assigned_roles  = assgn_r
              i_rchdatf         = rchdatf
              i_rchdatt         = rchdatt
         IMPORTING
              e_count           = l_numb
         TABLES
              it_roles          = roles
              it_ba             = rba "#EC SAST_CI_GEN_CHECK
*BOC:HBHALLA PN:11269 (15/01/25)
EXCEPTIONS
    communication_failure = 1
    system_failure = 2
    OTHERS = 3 .
     IF sy-subrc <> 0.
 CASE sy-subrc.
   WHEN 1.
      MESSAGE e002(/psyng/sw) WITH 'Communication failure'(t01).
   WHEN 2.
      MESSAGE e002(/psyng/sw) WITH 'System failure'(t02).
   WHEN OTHERS.
      MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(t03).
 ENDCASE.
  ENDIF.
*EOC:HBHALLA PN:11269 (15/01/25)
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    ADD l_numb TO l_total_num.
  ENDLOOP.

  MESSAGE i002 WITH
  'Number of role(s) that will be analyzed : '(009)
  l_total_num.


ENDFORM.                    " get_roles_count
*&---------------------------------------------------------------------*
*&      Form  rfc_validations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM rfc_validations.
  DATA : l_continue TYPE flag,
       r_rfcs TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER LINE.
clear gf_invalid_rfc.
  APPEND LINES OF remrfc TO r_rfcs.

  CLEAR l_continue.
  DELETE r_rfcs WHERE low = ' '.
*--Validate RFC Destinations
  CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
       EXPORTING
            i_popup    = 'X'
            i_module   = 'SE'
       IMPORTING
            e_continue = l_continue
       TABLES
            it_rfcdes  = r_rfcs.
  IF l_continue <> 'X'.
    gf_invalid_rfc = 'X'.
    LEAVE LIST-PROCESSING.
  ENDIF.


  FREE : gt_rfcdest.
  PERFORM load_role_rfc
              TABLES
                 r_rfcs
                 gt_rfcdest.



ENDFORM.                    " rfc_validations
*&---------------------------------------------------------------------*
*&      Form  load_role_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_R_RFCS  text
*      -->P_GT_RFCDEST  text
*----------------------------------------------------------------------*
FORM load_role_rfc TABLES
           it_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
           et_rfcdes STRUCTURE rfcdes.
  DATA : l_rfcdest TYPE rfcdes-rfcdest.
  DATA: BEGIN OF lt_dest OCCURS 0,
           rfcdest TYPE rfcdes-rfcdest,
         END OF lt_dest,
        lt_rfc_log TYPE TABLE OF rfclog WITH HEADER LINE,
        l_rfc_test TYPE rfctest,
        l_system_msg(80) TYPE c.

  FIELD-SYMBOLS :<rfcdes> TYPE rfcdes.
  IF NOT it_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_rfc
             AND rfctype = '3'.
  ENDIF.

  LOOP AT et_rfcdes ASSIGNING <rfcdes>.
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
    CALL FUNCTION '/PSYNG/BC_GET_SYSTEM_ID'
    DESTINATION <rfcdes>-rfcdest
     IMPORTING
       e_rfcdest       = l_rfcdest
  EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      DELETE et_rfcdes.
      CONTINUE.
    ELSE.
      <rfcdes>-rfcoptions = l_rfcdest.
    ENDIF.
  ENDLOOP.

  SORT et_rfcdes BY rfcoptions.
  DELETE ADJACENT DUPLICATES FROM et_rfcdes COMPARING rfcoptions.
  DATA : l_local_sys TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE et_rfcdes WHERE rfcoptions = l_local_sys.

ENDFORM.                    " load_role_rfc
*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_data.
  DATA :
   l_local_rfc TYPE rfcdes-rfcdest,
   l_system type /PSYNG/RFCNAME,
   lt_roles TYPE TABLE OF /psyng/comp_role_tcode WITH HEADER LINE,
   lt_roles_temp TYPE TABLE OF /psyng/comp_role_tcode WITH HEADER LINE,
   lt_roles_tcode TYPE TABLE OF /psyng/role_tcode WITH HEADER LINE,
   lt_role_tcode_t TYPE TABLE OF /psyng/role_tcode,
   lt_roles_text TYPE TABLE OF agr_texts WITH HEADER LINE,
   lt_critcodes_system type table of /PSYNG/CRITCODES with header line.

  RANGES : r_tcode FOR tstc-tcode,
           r_role FOR agr_define-agr_name.

  if gt_critcodes[] is initial.
    MESSAGE s174(/psyng/sw).
    EXIT.
  endif.

  r_tcode-sign = 'I'.
  r_tcode-option = 'EQ'.


  CONCATENATE sy-sysid sy-mandt INTO l_local_rfc.

  clear g_rolecount.
  LOOP AT gt_rfcdest.
*    --Filter Transactions by System
  l_system = gt_rfcdest-rfcoptions.
  lt_critcodes_system[] = gt_critcodes[].
  refresh : r_tcode.
  CALL FUNCTION '/PSYNG/SW_124'
    EXPORTING
     IF_TCODE           = 'X'
     i_system           = l_system
     i_vrsio            = p_sodvrs
   TABLES
     IT_CRITCODES        = lt_critcodes_system
"(++)BOC UMITTAL SE VF scan-25/11/2024
   EXCEPTIONS
     TOO_MANY_OPTIONS = 1
     OTHERS           = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.       .

  LOOP AT lt_critcodes_system.
    r_tcode-low = lt_critcodes_system-tcode.
    COLLECT r_tcode.
  ENDLOOP.
    IF  gt_rfcdest-rfcdest = 'LOCAL' OR
        gt_rfcdest-rfcdest IS INITIAL OR
        gt_rfcdest-rfcdest = l_local_rfc.
*-- Get Roles
      clear lt_roles_temp.
      CALL FUNCTION '/PSYNG/SW_GET_ROLES'
           EXPORTING
                i_composite_roles = comprol
                i_single_roles    = singrol
                i_assigned_roles  = assgn_r
                i_rchdatf         = rchdatf
                i_rchdatt         = rchdatt
                i_get_actual_data = 'X'
           TABLES
                it_roles          = roles
                it_ba             = rba
                et_roles          = lt_roles_temp
                et_texts          = lt_roles_text.

      LOOP AT lt_roles_temp.
        gt_roles-rfcdest = gt_rfcdest-rfcdest.
        MOVE-CORRESPONDING lt_roles_temp TO gt_roles.
        READ TABLE gt_roles WITH KEY agr_name = lt_roles_temp-agr_name
*--B8104 - the rfc destination of the remote role was copied to the
*          local role by this read statement.
        transporting no fields.
        IF sy-subrc <> 0.
        g_rolecount = g_rolecount + 1.
        ENDIF.
        APPEND gt_roles.
      ENDLOOP.
      if not r_tcode[] is initial.
        WHILE NOT lt_roles_temp[] IS INITIAL.
          APPEND LINES OF lt_roles_temp FROM 1 TO 1200 TO lt_roles .
          DELETE lt_roles_temp FROM 1 TO 1200.

          LOOP AT lt_roles.
            IF lt_roles-child_agr IS INITIAL.
              r_role-low = lt_roles-agr_name.
            ELSE.
              r_role-low = lt_roles-child_agr.
            ENDIF.
            r_role-sign = 'I'.
            r_role-option = 'EQ'.

            COLLECT r_role.
          ENDLOOP.

*  -- Get tcodes for all the roles
          CALL FUNCTION '/PSYNG/BC_012_BY_TCODE'
               TABLES
                    it_agr_name   = r_role
                    it_tcodes     = r_tcode
                    et_role_tcode = lt_role_tcode_t.

          APPEND LINES OF lt_role_tcode_t TO lt_roles_tcode.
          REFRESH : lt_role_tcode_t,r_role,lt_roles.

        ENDWHILE.
      endif.
      LOOP AT lt_roles_tcode.
        gt_roles_tcode-rfcdest  = gt_rfcdest-rfcdest.
        gt_roles_tcode-agr_name = lt_roles_tcode-rolename.
        gt_roles_tcode-tcode    = lt_roles_tcode-screen.
        APPEND gt_roles_tcode.
      ENDLOOP.

      LOOP AT lt_roles_text.
        gt_roles_text-rfcdest  = gt_rfcdest-rfcdest.
        gt_roles_text-agr_name = lt_roles_text-agr_name.
        gt_roles_text-text    = lt_roles_text-text..
        APPEND gt_roles_text.
      ENDLOOP.

    ELSE.
*-- Get Roles
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
      CALL FUNCTION '/PSYNG/SW_GET_ROLES'
      DESTINATION gt_rfcdest-rfcdest
           EXPORTING
                i_composite_roles = comprol
                i_single_roles    = singrol
                i_assigned_roles  = assgn_r
                i_rchdatf         = rchdatf
                i_rchdatt         = rchdatt
                i_get_actual_data = 'X'
           TABLES
                it_roles          = roles
                it_ba             = rba
                et_roles          = lt_roles_temp
            et_texts          = lt_roles_text "#EC SAST_CI_GEN_CHECK
*BOC:HBHALLA PN:11269 (15/01/25)
EXCEPTIONS
    communication_failure = 1
    system_failure = 2
    OTHERS = 3 .
     IF sy-subrc <> 0.
 CASE sy-subrc.
   WHEN 1.
      MESSAGE e002(/psyng/sw) WITH 'Communication failure'(t01).
   WHEN 2.
      MESSAGE e002(/psyng/sw) WITH 'System failure'(t02).
   WHEN OTHERS.
      MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(t03).
 ENDCASE.
  ENDIF.
*EOC:HBHALLA PN:11269 (15/01/25)
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

      LOOP AT lt_roles_temp.
        gt_roles-rfcdest = gt_rfcdest-rfcdest.
        MOVE-CORRESPONDING lt_roles_temp TO gt_roles.
      READ TABLE gt_roles WITH KEY agr_name = lt_roles_temp-agr_name
*--B8104 - the rfc destination of the remote role was copied to the
*          local role by this read statement.
      transporting no fields.
        IF sy-subrc <> 0.
        g_rolecount = g_rolecount + 1.
        ENDIF.
        APPEND gt_roles.
      ENDLOOP.
      if not r_tcode[] is initial.
        WHILE NOT lt_roles_temp[] IS INITIAL.
          APPEND LINES OF lt_roles_temp FROM 1 TO 1200 TO lt_roles .
          DELETE lt_roles_temp FROM 1 TO 1200.

          LOOP AT lt_roles.

            IF lt_roles-child_agr IS INITIAL.
*  -- Single roles
              r_role-low = lt_roles-agr_name.
            ELSE.
*  -- Composite singles
              r_role-low = lt_roles-child_agr.
            ENDIF.
            r_role-sign = 'I'.
            r_role-option = 'EQ'.
*            r_role-low = lt_roles-agr_name.
            COLLECT r_role.
          ENDLOOP.

*  -- Get tcodes for all the roles
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
          CALL FUNCTION '/PSYNG/BC_012_BY_TCODE'
          DESTINATION gt_rfcdest-rfcdest
               TABLES
                    it_agr_name   = r_role
                    it_tcodes     = r_tcode
           et_role_tcode = lt_role_tcode_t."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          APPEND LINES OF lt_role_tcode_t TO lt_roles_tcode.
          REFRESH: lt_role_tcode_t,r_role,lt_roles.
        ENDWHILE.
      endif.
      LOOP AT lt_roles_tcode.
        gt_roles_tcode-rfcdest = gt_rfcdest-rfcdest.
        gt_roles_tcode-agr_name = lt_roles_tcode-rolename.
        gt_roles_tcode-tcode = lt_roles_tcode-screen.
        APPEND gt_roles_tcode.
      ENDLOOP.

      LOOP AT lt_roles_text.
        gt_roles_text-rfcdest = gt_rfcdest-rfcdest.
        gt_roles_text-agr_name = lt_roles_text-agr_name.
        gt_roles_text-text = lt_roles_text-text..
        APPEND gt_roles_text.
      ENDLOOP.
    ENDIF.
    REFRESH : lt_roles_text,lt_roles_tcode,lt_roles_temp.
  ENDLOOP.

*-- Get Functions as well
  SELECT * FROM /psyng/functtran
  INTO TABLE gt_functtran
  WHERE vrsio = p_sodvrs
    AND tcode IN s_tcode.

*-- Function Desc
  SELECT * FROM /psyng/function
  INTO TABLE gt_function
  WHERE vrsio = p_sodvrs.

ENDFORM.                    " get_data
*&---------------------------------------------------------------------*
*&      Form  get_critical_tcodes
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_critical_tcodes.
*-- Get critical tcodes
  SELECT tcode imp owner busarea FROM /psyng/critcodes
  INTO CORRESPONDING FIELDS OF TABLE gt_critcodes
  WHERE vrsio = p_sodvrs
    AND imp IN s_imp
    AND owner IN s_owner
    AND busarea IN s_busare.

*-- Filter out non critical tcodes
  DELETE gt_critcodes WHERE NOT tcode IN s_tcode.

*-- Get Tcode descriptions
  IF NOT gt_critcodes[] IS INITIAL.

    SELECT DISTINCT * FROM tstct
    INTO CORRESPONDING FIELDS OF TABLE gt_tstct
    FOR ALL ENTRIES IN gt_critcodes
    WHERE tcode = gt_critcodes-tcode
      AND sprsl = sy-langu.

  ENDIF.
ENDFORM.                    " get_critical_tcodes
*&---------------------------------------------------------------------*
*&      Form  display_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_output.
  PERFORM create_fieldcatalog.
  PERFORM ouput_alv.
ENDFORM.                    " display_output
*&---------------------------------------------------------------------*
*&      Form  process_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM process_data.
  DATA : l_date(10) TYPE c,
         l_agrname TYPE agr_define-agr_name.
  WRITE sy-datum TO l_date.
  LOOP AT gt_rfcdest.
    LOOP AT gt_roles WHERE rfcdest = gt_rfcdest-rfcdest.
      clear gt_output.
      gt_output-rfcdest = gt_rfcdest-rfcdest.

      IF NOT gt_roles-child_agr IS INITIAL.
*-- Composite role it is
*        gt_output-agr_name = gt_roles-child_agr.
*        gt_output-child_agr = gt_roles-agr_name.
        gt_output-agr_name = gt_roles-agr_name.
        gt_output-child_agr = gt_roles-child_agr.

      ELSE.
*-- Single role it is
        gt_output-agr_name = gt_roles-agr_name.
      ENDIF.


      READ TABLE gt_roles_text WITH KEY rfcdest = gt_rfcdest-rfcdest
                                        agr_name = gt_output-agr_name.
      IF sy-subrc = 0.
        gt_output-text = gt_roles_text-text.
      ENDIF.

      IF gt_output-child_agr IS INITIAL.
      l_agrname = gt_output-agr_name.
      ELSE.
      l_agrname = gt_output-child_agr.
      ENDIF.
      LOOP AT gt_roles_tcode WHERE rfcdest = gt_rfcdest-rfcdest
                               AND agr_name = l_agrname.
"gt_output-agr_name.

        gt_output-tcode = gt_roles_tcode-tcode.
        READ TABLE gt_critcodes WITH KEY tcode = gt_roles_tcode-tcode.
        IF sy-subrc = 0.
          gt_output-imp = gt_critcodes-imp.
          gt_output-owner = gt_critcodes-owner.
          gt_output-busarea = gt_critcodes-busarea.
        ENDIF.

        READ TABLE gt_tstct WITH KEY tcode = gt_roles_tcode-tcode.
        IF sy-subrc = 0.
          gt_output-tcode_text = gt_tstct-ttext.
        ENDIF.

        IF sumfunc = 'X'.
          LOOP AT gt_functtran WHERE tcode = gt_output-tcode.
            gt_output-function = gt_functtran-functionid.
            READ TABLE gt_function
            WITH KEY function = gt_output-function.
            IF sy-subrc = 0.
              gt_output-description = gt_function-description.
            ENDIF.
            APPEND gt_output.
          ENDLOOP.
          IF sy-subrc NE 0.
            APPEND gt_output.
          ENDIF.
        ELSE.
          APPEND gt_output.
        ENDIF.
      ENDLOOP.
      IF sy-subrc NE 0 AND p_noct = 'X'.
        gt_output-tcode = '----'.
        CONCATENATE
  'No Critical Transactions based on SOD matrix defined in SW on '(077)
        l_date INTO
        gt_output-tcode_text SEPARATED BY space.

        APPEND gt_output.
        CLEAR gt_output.

      ENDIF.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    " process_data
*&---------------------------------------------------------------------*
*&      Form  create_fieldcatalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_fieldcatalog.
  g_repid = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name         = g_repid
            i_internal_tabname     = 'GT_OUTPUT'
            i_client_never_display = 'X'
            i_inclname             = g_repid
       CHANGING
            ct_fieldcat            = gt_fieldcat
       EXCEPTIONS
            inconsistent_interface = 1
            program_error          = 2
            OTHERS                 = 3.
  IF sy-subrc <> 0.
    LEAVE LIST-PROCESSING.
  ENDIF.

*-- Adjust Fieldcatalog
  IF NOT comprol = 'X'.
    DELETE gt_fieldcat WHERE fieldname = 'CHILD_AGR'.
  ENDIF.

  IF sumfunc = ' '.
    DELETE gt_fieldcat WHERE fieldname = 'FUNCTION'
                          OR fieldname = 'DESCRIPTION'.
  ENDIF.


  adjust gt_fieldcat 'Role Name'        '' '1' '' 'AGR_NAME'.
  adjust gt_fieldcat 'Role Description' '' '2' '' 'TEXT'.
  adjust gt_fieldcat 'Transaction'      '' '3' '' 'TCODE'.
  adjust gt_fieldcat 'Transaction text' '' '4' '' 'TCODE_TEXT'.
  adjust gt_fieldcat 'System'           '' '5' '' 'RFCDEST'.
  adjust gt_fieldcat 'Sensitivity'      '' '6' '' 'IMP'.
  adjust gt_fieldcat 'Owner'            '' '7' '' 'OWNER'.
  adjust gt_fieldcat 'App. Area'        '' '8' '' 'BUSAREA'.
  adjust gt_fieldcat 'Function ID'      '' '9' '' 'FUNCTION'.
*  adjust gt_fieldcat 'App. Area'       '' '8' '' 'BUSAREA'.
  adjust gt_fieldcat 'Single Role Name'  '' '10' '' 'CHILD_AGR'.


ENDFORM.                    " create_fieldcatalog
*&---------------------------------------------------------------------*
*&      Form  ouput_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ouput_alv.
  DATA : ls_alv_layout TYPE slis_layout_alv,
          ls_variant       TYPE disvariant.
*-- Sort Alv
  sort_alv '1' 'AGR_NAME'   'GT_OUTPUT' gt_sort_sum.
  sort_alv '2' 'TEXT'       'GT_OUTPUT' gt_sort_sum.
  sort_alv '3' 'TCODE'      'GT_OUTPUT' gt_sort_sum.
  sort_alv '4' 'TCODE_TEXT' 'GT_OUTPUT' gt_sort_sum.
  sort_alv '5' 'RFCDEST'    'GT_OUTPUT' gt_sort_sum.
  sort_alv '6' 'IMP'        'GT_OUTPUT' gt_sort_sum.
  sort_alv '7' 'OWNER'      'GT_OUTPUT' gt_sort_sum.
  sort_alv '8' 'BUSAREA'    'GT_OUTPUT' gt_sort_sum.
  IF sumfunc = 'X'.
    sort_alv '9' 'FUNCTION'   'GT_OUTPUT' gt_sort_sum.
    sort_alv '10' 'DESCRIPTION'   'GT_OUTPUT' gt_sort_sum.
  ENDIF.
  IF comprol = 'X'.
    sort_alv '10' 'CHILD_AGR'   'GT_OUTPUT' gt_sort_sum.
  ENDIF.

  ls_alv_layout-zebra = 'X'.
  ls_alv_layout-colwidth_optimize = 'X'.
*--Output ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_top_of_page   = 'ALV_HEADER'
*            i_callback_pf_status_set = 'PF_STATUS_SUMMARY'
            i_callback_program       = g_repid
            it_sort                  = gt_sort_sum
*            i_callback_user_command  = 'DOUBLE_CLICK_ON_SUMRY'
            is_layout                = ls_alv_layout
            it_fieldcat              = gt_fieldcat
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = gt_output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2.
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.              .

ENDFORM.                    " ouput_alv
*&---------------------------------------------------------------------*
*&      Form  f4_tcodes
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_TCODE_LOW  text
*----------------------------------------------------------------------*
FORM f4_tcodes CHANGING e_tcode TYPE /psyng/critcodes-tcode.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF help_value WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_ctcode TYPE /psyng/critcodes,
        lt_ctcode TYPE TABLE OF /psyng/critcodes WITH HEADER LINE.

  DATA : BEGIN OF ctcode OCCURS 0,
  ttext TYPE tstct-ttext.
          INCLUDE STRUCTURE /psyng/critcodes.
  DATA END OF ctcode.

  SELECT * FROM /psyng/critcodes INTO TABLE lt_ctcode
  WHERE vrsio = p_sodvrs.

  SORT lt_ctcode BY tcode.

  LOOP AT lt_ctcode.
    MOVE-CORRESPONDING lt_ctcode TO ctcode.
    SELECT SINGLE ttext FROM tstct INTO (ctcode-ttext)
    WHERE tcode = lt_ctcode-tcode
    AND sprsl EQ sy-langu.
    IF sy-subrc NE 0.
      ctcode-ttext = 'Tcode for cross system Analysis'(103).
    ENDIF.
    APPEND ctcode.
  ENDLOOP.


  lt_fields-tabname   = '/PSYNG/CRITCODES'.
  lt_fields-fieldname = 'TCODE'.
  lt_fields-selectflag = 'X'.
  APPEND lt_fields.

  lt_fields-tabname   = 'TSTCT'.
  lt_fields-fieldname = 'TTEXT'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-tabname   = '/PSYNG/CRITCODES'.
  lt_fields-fieldname = 'VRSIO'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'IMP'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'OWNER'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'BUSAREA'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  LOOP AT ctcode.
    lt_values-line = ctcode-tcode.
    APPEND lt_values.
    lt_values-line = ctcode-ttext.
    APPEND lt_values.
    lt_values-line = ctcode-vrsio.
    APPEND lt_values.
    lt_values-line = ctcode-imp.
    APPEND lt_values.
    lt_values-line = ctcode-owner.
    APPEND lt_values.
    lt_values-line = ctcode-busarea.
    APPEND lt_values.
  ENDLOOP.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
       EXPORTING
            titel                     = text-t14
       IMPORTING
            select_value              = e_tcode
       TABLES
            fields                    = lt_fields
            valuetab                  = lt_values
       EXCEPTIONS
            field_not_in_ddic         = 1
            more_then_one_selectfield = 2
            no_selectfield            = 3
            OTHERS                    = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                                                    " f4_tcodes

*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        count TYPE i,
        exedate TYPE char10,
        exetime(8) TYPE c,
        c_count TYPE string,
        alv_grid_titl2   TYPE lvc_title,
        l_date(12) TYPE c,
        l_detail(40) TYPE c,
        c_usercount(6) TYPE c,
        l_current_user TYPE sy-uname, "C0700
        l_systemid       TYPE /psyng/sysid. "C1102 AKUMAR
*BOC By RGUPTA on 28.03.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 28.03.22 for C0700
  wa-typ = 'H'.
  wa-info = 'Critical Transaction Code List'(h01).
  APPEND wa TO header.
*--Version
  wa-typ  = 'S'.
  wa-key  = 'SOD version:'(h22).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = p_sodvrs.
  CONCATENATE p_sodvrs ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*--Date
  wa-typ = 'S'.
  wa-key = 'User Date & System:'(h03).
  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO exetime SEPARATED BY ':'.
  WRITE sy-datum TO exedate.
*  CONCATENATE sy-uname text-h11 exedate exetime "C0700
   CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 AKUMAR
  CONCATENATE l_current_user text-h11 exedate exetime "C0700
    text-h23 l_systemid INTO wa-info SEPARATED BY space.
*  wa-info = l_date.
  APPEND wa TO header.


*--Summary
  wa-typ = 'S'.
  wa-key = 'Summary'(h04).
  c_usercount = g_rolecount.
  CONCATENATE c_usercount text-h05 INTO l_detail SEPARATED BY space.
  wa-info = l_detail.
  APPEND wa TO header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = header.

ENDFORM.
