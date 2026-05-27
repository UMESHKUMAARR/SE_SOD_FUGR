*----------------------------------------------------------------------*
* Report  /PSYNG/SW_123                                               *
* AUTHOR: Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

REPORT /psyng/sw_123 .

TABLES : agr_define,
         tstc,
         /psyng/functtran,
         /psyng/function,
         /psyng/confdet,
         /psyng/conflict.

TYPE-POOLS : slis.

DATA : gt_comp TYPE TABLE OF agr_agrs WITH HEADER LINE,
       gt_role_list TYPE TABLE OF /psyng/role_tcode WITH HEADER LINE.

DATA : BEGIN OF gt_role OCCURS 0,
         agr_name   TYPE agr_define-agr_name,
       END OF gt_role.

DATA : BEGIN OF gt_roletexts OCCURS 0,
         agr_name   TYPE agr_define-agr_name,
         text       TYPE agr_texts-text,
       END OF gt_roletexts.

DATA : BEGIN OF gt_tcodetexts OCCURS 0,
         tcode      TYPE tstct-tcode,
         text       TYPE tstct-ttext,
       END OF gt_tcodetexts.

DATA : BEGIN OF gt_agr_users OCCURS 0,
*        uname       TYPE agr_users-uname,
        agr_name    TYPE agr_users-agr_name,
       END OF gt_agr_users.

RANGES : r_role FOR agr_define-agr_name,
         r_tcode FOR tstct-tcode,
         r_comp FOR agr_define-agr_name.

DATA : BEGIN OF gt_output OCCURS 0,
        agr_name    LIKE agr_define-agr_name,
        agr_text    LIKE agr_texts-text,
        agr_type(1) TYPE c,
        parent_agr  LIKE agr_define-agr_name,
        tcode(30),
        tcode_text  LIKE tstct-ttext,
       END OF gt_output.

DATA : BEGIN OF gt_output_detail OCCURS 0,
        parent_agr  LIKE agr_define-agr_name,
        agr_name    LIKE agr_define-agr_name,
        agr_text    LIKE agr_texts-text,
        tcode(30),
        tcode_text  LIKE tstct-ttext,
        crittrans   TYPE flag,
        critauth    LIKE /psyng/swaudhdr-swaudid,
        critdesc    LIKE /psyng/swaudhdr-description,
        funcid      LIKE /psyng/functtran-functionid,
        funcdesc    LIKE /psyng/function-description,
        conid       LIKE /psyng/confdet-conid,
        confdesc    LIKE /psyng/conflict-description,
        conffunc    LIKE /psyng/functtran-functionid,
        funcdesc2   LIKE /psyng/function-description,
       END OF gt_output_detail.

DATA : gs_fieldcat  TYPE                   slis_fieldcat_alv,
       gt_fieldcat  TYPE                   slis_t_fieldcat_alv,
       gt_sort        TYPE STANDARD TABLE OF slis_sortinfo_alv,
       gt_sortdet     TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA:  g_ucomm       LIKE sy-ucomm,
       g_button_set  TYPE flag,
       gt_output_temp LIKE gt_output OCCURS 0.

DATA: gt_confdet     TYPE STANDARD TABLE OF /psyng/confdet
                                    WITH HEADER LINE,
      gt_conflict    TYPE STANDARD TABLE OF /psyng/conflict
                                    WITH HEADER LINE,
      gt_function    TYPE STANDARD TABLE OF /psyng/function
                                    WITH HEADER LINE,
      gt_critcodes   TYPE STANDARD TABLE OF /psyng/critcodes
                                    WITH HEADER LINE,
      gt_swaudhdr    TYPE STANDARD TABLE OF /psyng/swaudhdr
                                    WITH HEADER LINE,
      gt_functtran   TYPE STANDARD TABLE OF /psyng/functtran
                                    WITH HEADER LINE.
*--SELECTION SCREEN

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
SELECT-OPTIONS : s_role FOR agr_define-agr_name.
SELECT-OPTIONS : s_tcode FOR tstc-tcode.
PARAMETERS : sodvrsio LIKE /psyng/conflict-vrsio MODIF ID vrs.
SELECTION-SCREEN SKIP.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : p_single AS CHECKBOX DEFAULT 'X'
             USER-COMMAND usr.
SELECTION-SCREEN: COMMENT 3(27) text-006 FOR FIELD p_single.
*SELECTION-SCREEN : POSITION 32.
*PARAMETERS : p_scomp AS CHECKBOX MODIF ID sel .
*SELECTION-SCREEN COMMENT 35(40) text-007  MODIF ID sel
*                 FOR FIELD p_scomp.
SELECTION-SCREEN: END OF LINE.

PARAMETER : p_comp AS CHECKBOX USER-COMMAND usr,
            p_assign AS CHECKBOX MODIF ID ass.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF BLOCK exe WITH FRAME TITLE text-002.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : p_sum TYPE flag RADIOBUTTON GROUP g1 DEFAULT 'X'
              MODIF ID sc1 USER-COMMAND rad.
SELECTION-SCREEN: COMMENT 5(50) text-004 FOR FIELD p_sum
                                         MODIF ID sc1.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS :  p_map TYPE flag RADIOBUTTON GROUP g1 MODIF ID sc1 .
SELECTION-SCREEN: COMMENT 5(50) text-003 FOR FIELD p_map
                                         MODIF ID sc1.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN END OF BLOCK exe.
SELECTION-SCREEN END OF BLOCK b1.

*--Initialization
INITIALIZATION.

          CALL FUNCTION '/PSYNG/SW_034'
               IMPORTING
                    e_vrsio = sodvrsio.


AT SELECTION-SCREEN.
  IF p_comp IS INITIAL AND p_single IS INITIAL.
    MESSAGE e208(00) WITH
    'Select either Composite or Single Roles or both'(010).
  ENDIF.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'SEL'.
        IF p_single IS INITIAL.
*          CLEAR p_scomp.
*        screen-active = 1.
          screen-input = 0.
          MODIFY SCREEN.
        ENDIF.

*      WHEN 'VRS'.
*        IF p_map = 'X'.
**--Get sod version default
*          CALL FUNCTION '/PSYNG/SW_034'
*               IMPORTING
*                    e_vrsio = sodvrsio.
*
*          screen-input = 1.
*          MODIFY SCREEN.
*
*        ELSE.
*          CLEAR sodvrsio.
*          screen-input = 0.
*          MODIFY SCREEN.
*        ENDIF.


    ENDCASE.

    IF p_single IS INITIAL AND p_comp IS INITIAL.
      CLEAR p_assign.
      IF screen-group1 EQ 'ASS'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.



  ENDLOOP.

*--START-OF-SELECTION
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

  PERFORM get_data.
  PERFORM get_matrix_data.
  IF p_sum = 'X'.                                  "Summary
    PERFORM output.
  ELSE.
    PERFORM sod_version_mapping TABLES gt_output . "Detail
  ENDIF.


*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_data.
  DATA : lt_role_list TYPE TABLE OF /psyng/role_tcode WITH HEADER LINE,
         lt_tcodetexts LIKE TABLE OF gt_tcodetexts,
         lt_roletexts LIKE TABLE OF gt_roletexts,
         lt_tstc TYPE TABLE OF tstc.

  RANGES : s_trole FOR agr_define-agr_name.

  r_comp-sign = 'I'.
  r_comp-option = 'EQ'.

*--Validate tcode
  IF NOT s_tcode[] IS INITIAL.
    SELECT * FROM tstc INTO TABLE lt_tstc
    WHERE tcode IN s_tcode.
    IF sy-subrc NE 0.
      MESSAGE s150(/psyng/sw).
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.

  IF p_single = 'X'.
    SELECT agr_name FROM agr_define INTO TABLE gt_role
    WHERE agr_name IN s_role.

    SORT gt_role.
  ENDIF.

*  IF p_scomp = 'X'.
**    APPEND LINES OF s_role TO s_trole.
*
*    s_trole-sign = 'I'.
*    s_trole-option = 'EQ'.
*    LOOP AT gt_role.
*      s_trole-low = gt_role-agr_name.
*      APPEND s_trole.
*    ENDLOOP.
*    SELECT * FROM agr_agrs INTO TABLE gt_comp
*    WHERE agr_name IN s_role
*       OR child_agr IN s_trole.
*  ELSE.
  SELECT * FROM agr_agrs INTO TABLE gt_comp
  WHERE agr_name IN s_role.
*  ENDIF.


  SORT gt_comp BY agr_name child_agr.

*-- Get all the assigned roles if asked

  IF p_assign = 'X'.
    SELECT DISTINCT agr_name FROM agr_users
    INTO TABLE gt_agr_users
    WHERE agr_name IN s_role
    AND from_dat LE sy-datum
    AND to_dat GE sy-datum.

    SORT gt_agr_users BY agr_name.

*-- Check for Unassigned Single role
    LOOP AT gt_role.
      READ TABLE gt_agr_users WITH KEY agr_name = gt_role-agr_name
                BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc NE 0.
        DELETE gt_role.
      ENDIF.
    ENDLOOP.

*-- Check for Unassigned Composite rolea
    LOOP AT gt_comp.
      READ TABLE gt_agr_users WITH KEY agr_name = gt_comp-agr_name
            BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc NE 0.
        DELETE gt_comp.
      ENDIF.
    ENDLOOP.

  ENDIF.


*-- Append Child roles of Composite roles to list of roles
  LOOP AT gt_comp.

    IF p_comp = 'X'.
*-- Add single role from composite roles
      READ TABLE gt_role WITH KEY agr_name = gt_comp-child_agr
      BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc NE 0.
        gt_role-agr_name = gt_comp-child_agr.
        APPEND gt_role.
      ENDIF.
    ENDIF.

    AT NEW agr_name.
      r_comp-low = gt_comp-agr_name.
      APPEND r_comp.
    ENDAT.

  ENDLOOP.

  IF p_single = 'X'.
**-- Remove all the Composite roles from the list
    IF NOT r_comp[] IS INITIAL.
      DELETE gt_role WHERE agr_name IN r_comp.
    ENDIF.
*--
    IF p_comp IS INITIAL.
      IF NOT s_role[] IS INITIAL.
        DELETE gt_role WHERE NOT agr_name IN s_role.
      ENDIF.
    ENDIF.

  ENDIF.
*--Empty composite role table if not selected
  IF p_comp NE 'X'. "AND p_scomp NE 'X'.
    REFRESH gt_comp.
  ENDIF.


  IF NOT gt_role[] IS INITIAL.
    r_role-sign = 'I'.
    r_role-option = 'EQ'.

    WHILE NOT gt_role[] IS INITIAL.

      LOOP AT gt_role FROM 1 TO 1200.
        r_role-low = gt_role-agr_name.
        APPEND r_role.
      ENDLOOP.

      DELETE gt_role FROM 1 TO 1200.

*-- Get Tcodes associated with roles

*      CALL FUNCTION '/PSYNG/BC_012'
*           TABLES
*                it_agr_name   = r_role
*                et_role_tcode = lt_role_list.

      CALL FUNCTION '/PSYNG/BC_012_BY_TCODE'
           TABLES
                it_agr_name   = r_role
                it_tcodes     = s_tcode
                et_role_tcode = lt_role_list.

      IF NOT lt_role_list[] IS INITIAL.
        APPEND LINES OF lt_role_list TO gt_role_list.
        REFRESH lt_role_list.

*-- Get roles Short description

        SELECT agr_name text FROM agr_texts   "#EC CI_SEL_NESTED
         INTO TABLE lt_roletexts
        WHERE agr_name IN r_role
        AND spras = sy-langu
        AND line = 00000.

        APPEND LINES OF lt_roletexts TO gt_roletexts.
        REFRESH lt_roletexts.
        REFRESH r_role.
      ELSE.
        REFRESH r_role.
      ENDIF.
    ENDWHILE.

*    IF NOT s_tcode[] IS INITIAL.
*      DELETE gt_role_list WHERE NOT screen IN s_tcode.
**-- Remove composite roles as well
*      LOOP AT gt_comp.
*        READ TABLE gt_role_list WITH KEY rolename = gt_comp-child_agr.
*        IF sy-subrc NE 0.
*          DELETE gt_comp.
*        ENDIF.
*      ENDLOOP.
*    ENDIF.



*-- Get Tcodes Short Description

    lt_role_list[] = gt_role_list[].
    SORT lt_role_list BY screen.

    DELETE ADJACENT DUPLICATES FROM lt_role_list COMPARING screen.

    r_tcode-sign = 'I'.
    r_tcode-option = 'EQ'.

    WHILE NOT lt_role_list[] IS INITIAL.

      LOOP AT lt_role_list FROM 1 TO 1200.
        r_tcode-low = lt_role_list-screen.
        APPEND r_tcode.
      ENDLOOP.

      DELETE lt_role_list FROM 1 TO 1200.

      SELECT tcode ttext FROM tstct       "#EC CI_SEL_NESTED
      INTO TABLE lt_tcodetexts
      WHERE tcode IN r_tcode
      AND sprsl EQ sy-langu.

      APPEND LINES OF lt_tcodetexts TO gt_tcodetexts.
      REFRESH lt_tcodetexts.
      REFRESH r_tcode.
    ENDWHILE.

*-- Prepare data for output

*    SORT gt_tcodetexts BY tcode.
    SORT gt_roletexts BY agr_name.
    SORT gt_comp BY child_agr.

    LOOP AT gt_role_list.
      gt_output-agr_name = gt_role_list-rolename.
      gt_output-tcode = gt_role_list-screen.

      READ TABLE gt_tcodetexts WITH KEY tcode = gt_output-tcode.
      IF sy-subrc = 0.
        gt_output-tcode_text = gt_tcodetexts-text.
      ELSE.
        CLEAR gt_output-tcode_text.
      ENDIF.

*    at end of agr_name.
      READ TABLE gt_roletexts WITH KEY agr_name = gt_output-agr_name
                                                       BINARY SEARCH.
      IF sy-subrc = 0.
        gt_output-agr_text = gt_roletexts-text.
      ELSE.
        CLEAR gt_output-agr_text.
      ENDIF.

      LOOP AT gt_comp WHERE child_agr = gt_output-agr_name.
        gt_output-agr_type = 'C'.
        gt_output-parent_agr = gt_comp-agr_name.
        APPEND gt_output.
      ENDLOOP.
      IF sy-subrc NE 0.
        gt_output-agr_type = 'S'.
        CLEAR gt_output-parent_agr.
        APPEND gt_output.
      ENDIF.



    ENDLOOP.
  ENDIF.

  IF gt_output[] IS INITIAL.
    MESSAGE s150(/psyng/sw).
    LEAVE LIST-PROCESSING.
  ENDIF.

  SORT gt_output.
  DELETE ADJACENT DUPLICATES FROM gt_output COMPARING ALL FIELDS.

ENDFORM.                    " get_data
*&---------------------------------------------------------------------*
*&      Form  output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM output.
  DATA: ls_alv_layout    TYPE slis_layout_alv,
        ls_alv_grid_titl TYPE lvc_title,
        ls_variant    TYPE disvariant,
        lv_program       LIKE sy-repid.

  PERFORM build_field_catalog.
  PERFORM sort.

  lv_program = sy-repid.

  CLEAR ls_alv_layout.

  ls_alv_layout-zebra             = 'X'.
  ls_alv_layout-colwidth_optimize = 'X'.

  ls_alv_grid_titl = 'Role/Tcode List'.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
     EXPORTING
*            i_callback_top_of_page  = 'ALV_HEADER'
          i_grid_title             = ls_alv_grid_titl
          i_callback_program       = lv_program
          it_sort                  = gt_sort
          i_callback_user_command  = 'USER_CLICK_ON_TCODE'
          is_layout                = ls_alv_layout
          it_fieldcat              = gt_fieldcat
          i_save                   = 'A'
          is_variant               = ls_variant
     TABLES
          t_outtab                 = gt_output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.                    " output
*&---------------------------------------------------------------------*
*&      Form  build_field_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_field_catalog.

  IF NOT gt_comp[] IS INITIAL.
    gs_fieldcat-fieldname = 'PARENT_AGR'.
    gs_fieldcat-seltext_l = 'Composite Role'.
    gs_fieldcat-col_pos   = 1.
    APPEND gs_fieldcat TO gt_fieldcat.
    CLEAR gs_fieldcat.
  ENDIF.

  gs_fieldcat-fieldname = 'AGR_NAME'.
  gs_fieldcat-seltext_l = 'Single Role'.
  gs_fieldcat-col_pos   = 2.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'AGR_TEXT'.
  gs_fieldcat-seltext_l = 'Role Description'.
  gs_fieldcat-col_pos   = 3.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.
*
*  gs_fieldcat-fieldname = 'AGR_TYPE'.
*  gs_fieldcat-seltext_l = 'Role Type'.
*  gs_fieldcat-col_pos   = 3.
*  APPEND gs_fieldcat TO gt_fieldcat.
*  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'TCODE'.
  gs_fieldcat-seltext_l = 'Transaction Code'.
  gs_fieldcat-col_pos   = 4.
  gs_fieldcat-hotspot = 'X'.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'TCODE_TEXT'.
  gs_fieldcat-seltext_l = 'Transaction Text'.
  gs_fieldcat-col_pos   = 5.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.
ENDFORM.                    " build_field_catalog
*&---------------------------------------------------------------------*
*&      Form  sort
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM sort.
  DATA: l_sort TYPE slis_sortinfo_alv.

  IF NOT gt_comp[] IS INITIAL.
    l_sort-spos      = '1'.
    l_sort-fieldname = 'PARENT_AGR'.
    l_sort-tabname   = 'GT_OUTPUT'.
    l_sort-up        = 'X'.
    APPEND l_sort TO gt_sort.
  ENDIF.

  l_sort-spos      = '2'.
  l_sort-fieldname = 'AGR_NAME'.
  l_sort-tabname   = 'GT_OUTPUT'.
  l_sort-up        = 'X'.
  APPEND l_sort TO gt_sort.

  l_sort-spos      = '3'.
  l_sort-fieldname = 'AGR_TEXT'.
  l_sort-tabname   = 'GT_OUTPUT'.
  l_sort-up        = 'X'.
  APPEND l_sort TO gt_sort.

*  l_sort-spos      = '3'.
*  l_sort-fieldname = 'AGR_TYPE'.
*  l_sort-tabname   = 'GT_OUTPUT'.
*  l_sort-up        = 'X'.
*  APPEND l_sort TO gt_sort.




ENDFORM.                    " sort

*&---------------------------------------------------------------------*
*&      Form  USER_CLICK_ON_TCODE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM user_click_on_tcode USING r_ucomm LIKE sy-ucomm
                                  rs_selfield TYPE slis_selfield.
  DATA: ls_output LIKE gt_output.
  REFRESH gt_output_temp.
  CASE rs_selfield-fieldname.
    WHEN 'TCODE'.
      READ TABLE gt_output INDEX rs_selfield-tabindex.
      ls_output = gt_output.
      APPEND ls_output TO gt_output_temp.
      PERFORM sod_version_mapping TABLES gt_output_temp.

  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  sod_version_mapping
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM sod_version_mapping TABLES gt_output STRUCTURE gt_output.

  REFRESH gt_output_detail.

  LOOP AT gt_output.
    CLEAR gt_output_detail.
    READ TABLE gt_comp WITH KEY child_agr = gt_output-agr_name
                                              BINARY SEARCH.
    IF sy-subrc = 0.
      gt_output_detail-parent_agr = gt_comp-agr_name.
    ELSE.
      CLEAR gt_output_detail-parent_agr.
    ENDIF.
    gt_output_detail-agr_name = gt_output-agr_name.
    gt_output_detail-agr_text = gt_output-agr_text.
    gt_output_detail-tcode = gt_output-tcode.
    gt_output_detail-tcode_text = gt_output-tcode_text.
    READ TABLE gt_critcodes WITH KEY tcode = gt_output-tcode.
    IF sy-subrc = 0.
      gt_output_detail-crittrans = 'X'.
    ENDIF.

*--get functions
    LOOP AT gt_functtran WHERE tcode = gt_output-tcode .
      gt_output_detail-funcid =  gt_functtran-functionid.
     READ TABLE gt_function WITH KEY function = gt_functtran-functionid.
      IF sy-subrc = 0.
        gt_output_detail-funcdesc = gt_function-description.
      ENDIF.

*--get conflicts
      LOOP AT gt_confdet WHERE functionid = gt_functtran-functionid.
        gt_output_detail-conid = gt_confdet-conid.
        READ TABLE gt_conflict WITH KEY conid = gt_confdet-conid.
        IF sy-subrc = 0.
          gt_output_detail-confdesc = gt_conflict-description.
        ENDIF.

*--get all functions in the conflict
        LOOP AT gt_confdet WHERE conid = gt_confdet-conid.
          gt_output_detail-conffunc = gt_confdet-functionid.
       READ TABLE gt_function WITH KEY function = gt_confdet-functionid.
          IF sy-subrc = 0.
            gt_output_detail-funcdesc2 = gt_function-description.
          ENDIF.

*--get critical auths
          LOOP AT gt_swaudhdr WHERE tcode = gt_output-tcode.
            gt_output_detail-critauth = gt_swaudhdr-swaudid.
            gt_output_detail-critdesc = gt_swaudhdr-description..
            APPEND gt_output_detail.
          ENDLOOP.

*--If no critical auth found for the corresponding tcode
          IF sy-subrc NE 0.
            APPEND gt_output_detail.
          ENDIF.
        ENDLOOP.
      ENDLOOP.

*--If no conflicts found for corresponding function
      IF sy-subrc NE 0.
        LOOP AT gt_swaudhdr WHERE tcode = gt_output-tcode.
          gt_output_detail-critauth = gt_swaudhdr-swaudid.
          gt_output_detail-critdesc = gt_swaudhdr-description.
          APPEND gt_output_detail.
        ENDLOOP.
        IF sy-subrc NE 0.
          APPEND gt_output_detail.
        ENDIF.
      ENDIF.
    ENDLOOP.

*--if only critical auth or critical tcode
    IF sy-subrc NE 0.
      LOOP AT gt_swaudhdr WHERE tcode = gt_output-tcode.
        gt_output_detail-critauth = gt_swaudhdr-swaudid.
        gt_output_detail-critdesc = gt_swaudhdr-description.
        APPEND gt_output_detail.
      ENDLOOP.

*--if only critical tcode no other details
*      IF sy-subrc NE 0 AND gt_output_detail-crittrans = 'X'.
*-- Case 11 - Display all the tcodes in detail mode whether they are in
*-- SOD matrix or not
      IF sy-subrc NE 0.
        APPEND gt_output_detail.
      ENDIF.
    ENDIF.
  ENDLOOP.

  SORT gt_output_detail.
  DELETE ADJACENT DUPLICATES FROM gt_output_detail COMPARING ALL FIELDS.
  IF NOT gt_output_detail[] IS INITIAL.
    PERFORM detail_output.
  ELSE.
    MESSAGE s128(/psyng/sw) WITH 'Details'(005).
  ENDIF.

ENDFORM.                    " sod_version_mapping
*&---------------------------------------------------------------------*
*&      Form  detail_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM detail_output.
  DATA: ls_alv_layout    TYPE slis_layout_alv,
          ls_alv_grid_titl TYPE lvc_title,
          ls_variant    TYPE disvariant,
          lv_program       LIKE sy-repid.

  PERFORM build_det_catalogue.
  PERFORM sort_det.

  lv_program = sy-repid.

  CLEAR ls_alv_layout.

  ls_alv_layout-zebra             = 'X'.
  ls_alv_layout-colwidth_optimize = 'X'.

  ls_alv_grid_titl = 'SOD Version Mapping'.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
     EXPORTING
*         i_callback_top_of_page  = 'ALV_HEADER'
          i_grid_title             = ls_alv_grid_titl
          i_callback_program       = lv_program
          it_sort                  = gt_sortdet
          is_layout                = ls_alv_layout
          it_fieldcat              = gt_fieldcat
          i_save                   = 'A'
          is_variant               = ls_variant
     TABLES
          t_outtab                 = gt_output_detail
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.



ENDFORM.                    " detail_output
*&---------------------------------------------------------------------*
*&      Form  build_det_catalogue
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_det_catalogue.
  REFRESH gt_fieldcat.

  IF NOT gt_comp[] IS INITIAL.
    gs_fieldcat-fieldname = 'PARENT_AGR'.
    gs_fieldcat-seltext_l = 'Composite Role'.
    gs_fieldcat-col_pos   = 1.
    APPEND gs_fieldcat TO gt_fieldcat.
    CLEAR gs_fieldcat.
  ENDIF.

  gs_fieldcat-fieldname = 'AGR_NAME'.
  gs_fieldcat-seltext_l = 'Single Role'.
  gs_fieldcat-col_pos   = 2.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'AGR_TEXT'.
  gs_fieldcat-seltext_l = 'Role Description'.
  gs_fieldcat-col_pos   = 3.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'TCODE'.
  gs_fieldcat-seltext_l = 'Transaction Code'.
  gs_fieldcat-col_pos   = 4.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'TCODE_TEXT'.
  gs_fieldcat-seltext_l = 'Transaction Text'.
  gs_fieldcat-col_pos   = 5.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'CRITTRANS'.
  gs_fieldcat-seltext_l = 'Critical Transaction'.
  gs_fieldcat-seltext_s = 'Crit Tcode'.
  gs_fieldcat-col_pos   = 6.
  gs_fieldcat-just = 'C'.
  gs_fieldcat-checkbox = 'X'.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'CRITAUTH'.
  gs_fieldcat-seltext_l = 'Critical Authorizations'.
  gs_fieldcat-seltext_s = 'Crit. Auth'.
  gs_fieldcat-col_pos   = 7.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'CRITDESC'.
  gs_fieldcat-seltext_l = 'Critical Auth Description'.
  gs_fieldcat-col_pos   = 8.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'FUNCID'.
  gs_fieldcat-seltext_l = 'Function'.
  gs_fieldcat-col_pos   = 9.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'FUNCDESC'.
  gs_fieldcat-seltext_l = 'Function Description'.
  gs_fieldcat-col_pos   = 10.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'CONID'.
  gs_fieldcat-seltext_l = 'Conflict'.
  gs_fieldcat-col_pos   = 11.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'CONFDESC'.
  gs_fieldcat-seltext_l = 'Conflict Description'.
  gs_fieldcat-col_pos   = 12.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'CONFFUNC'.
  gs_fieldcat-seltext_l = 'Conflict Functions'.
  gs_fieldcat-col_pos   = 13.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'FUNCDESC2'.
  gs_fieldcat-seltext_l = 'Function Description'.
  gs_fieldcat-col_pos   = 14.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.
ENDFORM.                    " build_det_catalogue
*&---------------------------------------------------------------------*
*&      Form  sort_det
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM sort_det.

  DATA: l_sort TYPE slis_sortinfo_alv.

  IF NOT gt_comp[] IS INITIAL.
    l_sort-spos      = '1'.
    l_sort-fieldname = 'PARENT_AGR'.
    l_sort-tabname   = 'GT_OUTPUT_DETAIL'.
    l_sort-up        = 'X'.
    APPEND l_sort TO gt_sortdet.
  ENDIF.

  l_sort-spos      = '1'.
  l_sort-fieldname = 'AGR_NAME'.
  l_sort-tabname   = 'GT_OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  APPEND l_sort TO gt_sortdet.

  l_sort-spos      = '2'.
  l_sort-fieldname = 'AGR_TEXT'.
  l_sort-tabname   = 'GT_OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  APPEND l_sort TO gt_sortdet.

  l_sort-spos      = '3'.
  l_sort-fieldname = 'TCODE'.
  l_sort-tabname   = 'GT_OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  APPEND l_sort TO gt_sortdet.

  l_sort-spos      = '4'.
  l_sort-fieldname = 'TCODE_TEXT'.
  l_sort-tabname   = 'GT_OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  APPEND l_sort TO gt_sortdet.

  l_sort-spos      = '5'.
  l_sort-fieldname = 'CRITAUTH'.
  l_sort-tabname   = 'GT_OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  APPEND l_sort TO gt_sortdet.

  l_sort-spos      = '6'.
  l_sort-fieldname = 'CRITDESC'.
  l_sort-tabname   = 'GT_OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  APPEND l_sort TO gt_sortdet.

  l_sort-spos      = '7'.
  l_sort-fieldname = 'FUNCID'.
  l_sort-tabname   = 'GT_OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  APPEND l_sort TO gt_sortdet.

  l_sort-spos      = '8'.
  l_sort-fieldname = 'FUNCDESC'.
  l_sort-tabname   = 'GT_OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  APPEND l_sort TO gt_sortdet.

  l_sort-spos      = '9'.
  l_sort-fieldname = 'CONID'.
  l_sort-tabname   = 'GT_OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  APPEND l_sort TO gt_sortdet.

  l_sort-spos      = '10'.
  l_sort-fieldname = 'CONFDESC'.
  l_sort-tabname   = 'GT_OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  APPEND l_sort TO gt_sortdet.

  l_sort-spos      = '11'.
  l_sort-fieldname = 'CONFFUNC'.
  l_sort-tabname   = 'GT_OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  APPEND l_sort TO gt_sortdet.

  l_sort-spos      = '12'.
  l_sort-fieldname = 'FUNCDESC2'.
  l_sort-tabname   = 'GT_OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  APPEND l_sort TO gt_sortdet.

  l_sort-spos      = '13'.
  l_sort-fieldname = 'CRITTRANS'.
  l_sort-tabname   = 'GT_OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  APPEND l_sort TO gt_sortdet.
ENDFORM.                    " sort_det
*&---------------------------------------------------------------------*
*&      Form  get_matrix_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_matrix_data.

  SELECT * FROM /psyng/confdet INTO TABLE gt_confdet
         WHERE vrsio = sodvrsio.
  SELECT function vrsio description FROM /psyng/function
         INTO CORRESPONDING FIELDS OF TABLE gt_function
         WHERE vrsio = sodvrsio.
  SELECT conid  vrsio description FROM /psyng/conflict
         INTO CORRESPONDING FIELDS OF TABLE gt_conflict
         WHERE vrsio = sodvrsio.
  SELECT tcode vrsio FROM /psyng/critcodes
         INTO CORRESPONDING FIELDS OF TABLE gt_critcodes
         WHERE vrsio = sodvrsio.
  SELECT swaudid vrsio tcode description FROM /psyng/swaudhdr
         INTO CORRESPONDING FIELDS OF TABLE gt_swaudhdr
         WHERE vrsio = sodvrsio.
  SELECT * FROM /psyng/functtran INTO TABLE gt_functtran
          WHERE vrsio = sodvrsio.

ENDFORM.                    " get_matrix_data
