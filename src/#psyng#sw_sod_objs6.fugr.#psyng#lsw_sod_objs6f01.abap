*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_SOD_OBJS6F01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  fill_internal_tables
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_internal_tables
TABLES
  it_ba              STRUCTURE /psyng/range_busarea_role
USING
  i_local_sod_matrix TYPE flag
  i_comproles        TYPE flag
  i_singleroles      TYPE flag
  i_assignedroles    TYPE flag
  i_nabap            TYPE flag
  i_cfg_set          TYPE /psyng/seconfid
  i_org_field TYPE flag "AKUMAR OPL645
  CHANGING
    gt_faobj_org LIKE gt_faobj_org1[]. "AKUMAR OPL645
  DATA: lt_conflict   TYPE TABLE OF /psyng/conflict,
        lt_confdet    TYPE TABLE OF /psyng/confdet,
        ls_agr_define TYPE agr_define,
        lt_agr_define TYPE TABLE OF agr_define WITH HEADER LINE,
        wa_agr_users  TYPE agr_users,
       lt_ba_roles   TYPE TABLE OF /psyng/busarea_role WITH HEADER LINE.

  MESSAGE s002 WITH 'Loading SOD Matrix'.
  COMMIT WORK.

*--Get SOD Matrix
  IF i_local_sod_matrix = 'X'.
    CALL FUNCTION '/PSYNG/SW_028'
      EXPORTING
        i_orgcheck         = g_org_check
        i_vrsio            = g_vrsio
        i_enhance          = g_enh_fm
        i_orphan_functions = i_nabap
        i_config_set       = i_cfg_set
        if_analysis        = 'X'
        i_org_field        = i_org_field "AKUMAR OPL645
      TABLES
        it_spconfs         = gt_confs
        it_imp             = gt_sens
        it_risk            = gt_risk
*      it_org             = orglvl
        et_conflict        = lt_conflict
        et_confdet         = lt_confdet
        et_functtran       = functtran
        et_faobj           = faobj
        et_swsodorgm       = swsodorgm
        et_tcodes          = gt_enh_tcodes
        et_functran_no_enh = gt_functran_no_enh
        et_faobj_org       = gt_faobj_org "AKUMAR OPL645
        .

    conflict[] = lt_conflict[].
    confdet[]  = lt_confdet[].
    confs2[] = confdet[].

*   Remove rows with no object
    DELETE faobj WHERE object = space.
  ELSE.
*--tables filled in main FM

  ENDIF.


  MESSAGE s002 WITH 'Loading Selected Roles'.
  COMMIT WORK.

  CALL FUNCTION '/PSYNG/BC_071'
   EXPORTING
     if_single                = i_singleroles
     if_composite             = i_comproles
     if_assigned              = i_assignedroles
     i_change_from_date       = g_rchdatf
     i_change_to_date         = g_rchdatt
   TABLES
     it_roles                 = gt_roles
     it_busarea               = it_ba
     et_busarea_role          = lt_ba_roles.
  REFRESH iagr_define.
  LOOP AT lt_ba_roles.
    ls_agr_define-agr_name = lt_ba_roles-agr_name.
    INSERT ls_agr_define INTO TABLE iagr_define.
  ENDLOOP.

**--Get selected roles
*  REFRESH iagr_define.
** B8101 - If no role filter is supplied, all roles should be analyzed
**  if not gt_roles[] is initial.
*  SELECT agr_name create_dat change_dat
*             INTO CORRESPONDING FIELDS OF ls_agr_define
*             FROM agr_define
*             WHERE agr_name IN gt_roles.
*    IF g_rchdatf IS INITIAL.   "role change date from
*      INSERT ls_agr_define INTO TABLE iagr_define.
*    ELSE.
*      IF ls_agr_define-change_dat IS INITIAL.
*        CHECK ls_agr_define-create_dat >= g_rchdatf AND
*              ls_agr_define-create_dat <= g_rchdatt.
*        INSERT ls_agr_define INTO TABLE iagr_define.
*      ELSE.
*        CHECK ls_agr_define-change_dat >= g_rchdatf AND
*              ls_agr_define-change_dat <= g_rchdatt.
*        INSERT ls_agr_define INTO TABLE iagr_define.
*      ENDIF.
*    ENDIF.
*  ENDSELECT.
**  endif.
*  CHECK NOT iagr_define[] IS INITIAL.
**** SE 3.1 Get & filter by assigned roles
*  IF i_assignedroles = 'X'.
*    LOOP AT iagr_define.
*** if role is assigned to one user it is assigned
*      SELECT SINGLE *  FROM agr_users INTO wa_agr_users
*      WHERE agr_name = iagr_define-agr_name
*      AND to_dat GE sy-datum
*      AND from_dat LE sy-datum.
*      IF sy-subrc NE 0.
*        APPEND iagr_define TO lt_agr_define.
*      ENDIF.
*    ENDLOOP.
*    LOOP AT lt_agr_define.
*      DELETE iagr_define WHERE agr_name = lt_agr_define-agr_name.
*    ENDLOOP.
*  ENDIF.
*
*
**-- filter by single and/or composite roles
*  IF i_comproles = 'X' AND i_singleroles = 'X'.
**--All roles, no filtering needed
*  ELSE.
*   DATA : lt_roleinfo TYPE TABLE OF /psyng/sw_roleinfo WITH HEADER LINE.
*    CONCATENATE sy-sysid sy-mandt INTO lt_roleinfo.
*    LOOP AT  iagr_define.
*      lt_roleinfo-agr_name = iagr_define-agr_name.
*      APPEND lt_roleinfo.
*    ENDLOOP.
*
*    CALL FUNCTION '/PSYNG/SW_ROLE_INFO'
**   EXPORTING
**     I_SPRAS        = 'EN'
*      TABLES
*        it_roles       = lt_roleinfo.
*    IF i_comproles IS INITIAL.
**--filter out composite roles
*      LOOP AT lt_roleinfo WHERE composite = 'X'.
*        DELETE iagr_define WHERE agr_name = lt_roleinfo-agr_name.
*      ENDLOOP.
*    ENDIF.
*    IF i_singleroles IS INITIAL.
**--filter out single roles
*      LOOP AT lt_roleinfo WHERE composite <> 'X'.
*        DELETE iagr_define WHERE agr_name = lt_roleinfo-agr_name.
*      ENDLOOP.
*    ENDIF.
*
*  ENDIF.

ENDFORM.                    " fill_internal_tables

*&---------------------------------------------------------------------*
*&      Form  get_simulation_roles_for_role
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_simulation_roles_for_role.
  DATA : ls_agr_define TYPE agr_define.
*        fields TYPE rfc_db_fld OCCURS 0 WITH HEADER LINE,
*        data   TYPE tab512 OCCURS 0 WITH HEADER LINE,
*        agrs   TYPE agr_define OCCURS 0 WITH HEADER LINE,
*        data_agrs TYPE tab512 OCCURS 0 WITH HEADER LINE.
*
  IF g_simu_rfc = space.
    CALL FUNCTION '/PSYNG/SW_102'
      TABLES
        it_roles_range      = gt_roles_simu
       et_roles             = simuagrs.

  ELSE.
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
    CALL FUNCTION '/PSYNG/SW_102'
    DESTINATION g_simu_rfc
      TABLES
        it_roles_range      = gt_roles_simu
       et_roles             = simuagrs.          "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  ENDIF.

*   check if roles that were requested exist
  DATA : ls_simu LIKE LINE OF gt_roles_simu.
  LOOP AT gt_roles_simu INTO ls_simu WHERE sign = 'I'
                                       AND option = 'EQ' .
    READ TABLE simuagrs WITH KEY agr_name = ls_simu-low.
    IF sy-subrc <> 0.
      MESSAGE i154(/psyng/sw) WITH ls_simu-low.
      g_return-type = 'W'.
      CONCATENATE text-002 ls_simu-low INTO g_return-message.

*   Simulated role & does not exist.

    ENDIF.
  ENDLOOP.

ENDFORM.                    " get_simulation_roles_for_role
*&---------------------------------------------------------------------*
*&      Form  get_roles_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  <--  ET_RETURN  Return messages
*----------------------------------------------------------------------*
FORM get_roles_data TABLES
  et_return STRUCTURE bapiret2
  it_faobj  STRUCTURE /psyng/faobj2
  it_simu_role_removal STRUCTURE /psyng/sw_role_removal_simu
  et_simu_removed_roles STRUCTURE /psyng/sw_removed_roles_role.
  DATA : rfcdest TYPE rfcdest.
  DATA: lt_iagr_part TYPE STANDARD TABLE OF agr_define
        WITH HEADER LINE,
        lt_iagr_all TYPE STANDARD TABLE OF agr_define
        WITH HEADER LINE,
        lt_objects TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
        lt_unique_objects TYPE HASHED TABLE OF /psyng/faobj2
        WITH UNIQUE KEY object,
        l_agr_name TYPE agr_name.
  RANGES : range_roles FOR l_agr_name.

  lt_objects[] = it_faobj[].
  lt_objects-object = 'S_TCODE'.
  APPEND lt_objects.
  SORT lt_objects BY object.
  DELETE ADJACENT DUPLICATES FROM lt_objects COMPARING object.
  lt_unique_objects[] = lt_objects[].
  FREE lt_objects[].

*--Convert role removal simu structure to range
  LOOP AT it_simu_role_removal.
    MOVE-CORRESPONDING it_simu_role_removal TO range_roles.
    APPEND range_roles.
  ENDLOOP.


************** Get all data from database at once ********************

  lt_iagr_all[] = iagr_define[].
  WHILE NOT lt_iagr_all[] IS INITIAL.
    FREE : lt_iagr_part[],lt_totalagr[].
    APPEND LINES OF lt_iagr_all FROM 1 TO 1000 TO lt_iagr_part.
    DELETE lt_iagr_all FROM 1 TO 1000.
* get child roles from composite roles
    IF NOT lt_iagr_part[] IS INITIAL.
     SELECT agr_name child_agr                          "#EC CI_NOORDER
            INTO CORRESPONDING FIELDS OF TABLE lt_agrs
            FROM agr_agrs
            FOR ALL ENTRIES IN lt_iagr_part
            WHERE agr_name = lt_iagr_part-agr_name
            AND   attributes <> 'X'.
    ENDIF.

* collect all single role names into one table
*Role removal Simulation, don't add roles that are 'removed'
    IF NOT range_roles[] IS INITIAL.
      CONCATENATE sy-sysid sy-mandt INTO et_simu_removed_roles-rfcdest.
      LOOP AT lt_agrs.
        IF lt_agrs-child_agr IN range_roles.
          et_simu_removed_roles-comp_agr = lt_agrs-agr_name.
          et_simu_removed_roles-agr_name = lt_agrs-child_agr.
          APPEND et_simu_removed_roles.
        ENDIF.
      ENDLOOP.
    ENDIF.
    LOOP AT et_simu_removed_roles.
      DELETE lt_agrs WHERE agr_name  = et_simu_removed_roles-comp_agr
                     AND   child_agr = et_simu_removed_roles-agr_name
                          .

    ENDLOOP.


    APPEND LINES OF lt_iagr_part TO lt_totalagr.
    LOOP AT lt_agrs.
      lt_totalagr-agr_name = lt_agrs-child_agr.
      APPEND lt_totalagr.
    ENDLOOP.
    LOOP AT simuagrs.
      lt_totalagr-agr_name = simuagrs-agr_name.
      APPEND lt_totalagr.
    ENDLOOP.
    SORT lt_totalagr.
    DELETE ADJACENT DUPLICATES FROM lt_totalagr.
    CHECK NOT  lt_totalagr[] IS INITIAL.



* get profiles of single roles
    SELECT agr_name profile
           INTO CORRESPONDING FIELDS OF TABLE lt_1016
           FROM agr_1016
           FOR ALL ENTRIES IN lt_totalagr
           WHERE agr_name = lt_totalagr-agr_name.

* get auth names of roles.
    IF NOT lt_1016[] IS INITIAL.
      SELECT profn aktps objct auth
             INTO CORRESPONDING FIELDS OF TABLE lt_ust10s
             FROM ust10s
             FOR ALL ENTRIES IN lt_1016
             WHERE profn = lt_1016-profile AND aktps = 'A'.
    ENDIF.

************** Database selection complete ********************


* Find role's tcodes/authorizations/profiles
    SORT lt_iagr_part.
    SORT faobj.
    LOOP AT lt_iagr_part.
      LOOP AT lt_agrs WHERE agr_name = lt_iagr_part-agr_name.

        CLEAR:   roleauth_fm, roletcode_fm, roleprof_fm,
                 et_1016, et_1251, et_1252, et_ust10s.
        REFRESH: roletcode_fm, roleprof_fm, roleauth_fm,
                 et_1016, et_1251, et_1252, et_ust10s.

        PERFORM move_data_to_temp_tabs
                USING lt_agrs-child_agr.

        CALL FUNCTION '/PSYNG/SW_SODSYS_GET_ROLE_DATA'
             EXPORTING
                  agr_name  = lt_agrs-child_agr
                  bname     = ''
             TABLES
                  roleauth  = roleauth_fm
                  roletcode = roletcode_fm
                  roleprof  = roleprof_fm
                  functtran = functtran
                  faobj     = faobj
                  it_1016   = et_1016
                  it_ust10s = et_ust10s.

        CLEAR: wa_roletcode, wa_roleauth.
        LOOP AT roletcode_fm.
          wa_roletcode-agr_name = lt_iagr_part-agr_name.
          wa_roletcode-child_agr = lt_agrs-child_agr.
          wa_roletcode-tcode    = roletcode_fm-tcode.
          wa_roletcode-rfcdest   = roletcode_fm-rfcdest.
          INSERT wa_roletcode INTO TABLE roletcode.
        ENDLOOP.
*--Begin of placeholder tcodes
        CONCATENATE sy-sysid sy-mandt INTO rfcdest.
        LOOP AT functtran WHERE tcode CP
          /psyng/sw_cl_constants=>placeholder_tcode_prefix.
*        LOOP AT lt_agrs.
          wa_roletcode-agr_name  = lt_iagr_part-agr_name.
          wa_roletcode-child_agr = lt_agrs-child_agr.

          wa_roletcode-tcode     = functtran-tcode.
          wa_roletcode-rfcdest   = rfcdest.
          INSERT wa_roletcode INTO TABLE roletcode.
*        ENDLOOP.
        ENDLOOP.
*--End of placeholder tcodes
        LOOP AT roleauth_fm.
          MOVE-CORRESPONDING roleauth_fm TO wa_roleauth.
          wa_roleauth-agr_name  = lt_iagr_part-agr_name.
          wa_roleauth-child_agr = lt_agrs-child_agr.

          CLEAR:
                 wa_roleauth-von,
                 wa_roleauth-bis,
                 wa_roleauth-child_agr.
          INSERT wa_roleauth INTO TABLE roleauth.
        ENDLOOP.
      ENDLOOP.   "lt_agr_agrs
      subrc = sy-subrc.

      IF g_bysimu = 'X' .
        PERFORM get_simulation_roles_data TABLES et_return.
      ENDIF.

      CHECK subrc <> 0.  "next role if role is composite

      CLEAR:   roleauth_fm, roletcode_fm, roleprof_fm,
               et_1016, et_1251, et_1252, et_ust10s.
      REFRESH: roletcode_fm, roleprof_fm, roleauth_fm,
               et_1016, et_1251, et_1252, et_ust10s.

      PERFORM move_data_to_temp_tabs
              USING lt_iagr_part-agr_name.

      CALL FUNCTION '/PSYNG/SW_SODSYS_GET_ROLE_DATA'
           EXPORTING
                agr_name  = lt_iagr_part-agr_name
                bname     = ''
           TABLES
                roleauth  = roleauth_fm
                roletcode = roletcode_fm
                roleprof  = roleprof_fm
                functtran = functtran
                faobj     = faobj
                it_1016   = et_1016
                it_ust10s = et_ust10s.
*              it_1251   = et_1251
*              it_1252   = et_1252.

      CLEAR: wa_roletcode, wa_roleauth.
      LOOP AT roletcode_fm.
        MOVE-CORRESPONDING roletcode_fm TO wa_roletcode.
        CLEAR: wa_roletcode-child_agr.
        INSERT wa_roletcode INTO TABLE roletcode.
      ENDLOOP.
*--Begin of placeholder tcodes
      CONCATENATE sy-sysid sy-mandt INTO rfcdest.
      LOOP AT functtran WHERE tcode CP
        /psyng/sw_cl_constants=>placeholder_tcode_prefix.
        wa_roletcode-agr_name  = lt_iagr_part-agr_name.
        wa_roletcode-tcode     = functtran-tcode.
        wa_roletcode-rfcdest   = rfcdest.
        INSERT wa_roletcode INTO TABLE roletcode.
      ENDLOOP.
*--End of placeholder tcodes

      LOOP AT roleauth_fm.
        MOVE-CORRESPONDING roleauth_fm TO wa_roleauth.
        CLEAR: wa_roleauth-field,
               wa_roleauth-von,
               wa_roleauth-bis,
               wa_roleauth-child_agr.
        INSERT wa_roleauth INTO TABLE roleauth.
      ENDLOOP.
    ENDLOOP.    "IAGR_DEFINE

    CLEAR: roleauth_fm, roletcode_fm, roleprof_fm, lt_agrs.
    FREE:  lt_agrs, roletcode_fm, roleprof_fm, roleauth_fm,
           et_1016, et_1251, et_1252, et_ust10s,
           lt_1016, lt_1251, lt_1252, lt_ust10s.
*--Prevent process from timing out
    CALL FUNCTION '/PSYNG/BASIS_GET_WPINFO'
         EXPORTING
              i_commit_pct = 20.

  ENDWHILE.

ENDFORM.                    " get_roles_data
*&---------------------------------------------------------------------*
*&      Form  move_data_to_temp_tabs
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM move_data_to_temp_tabs USING rolename TYPE agr_define-agr_name.

  DATA: lf_value(50),
        if_value(50),
        lf_foundone.

*  PERFORM move_data_via_loops USING rolename.
*  exit.

* Data will be moved using loops if last charcter of role name is
* 'Z' or '9'.

  MOVE rolename TO lf_value.
  CALL FUNCTION '/PSYNG/BC_GET_NEXT_CHAR'
       EXPORTING
            if_value            = lf_value
       IMPORTING
            ef_value            = if_value
            ef_foundone         = lf_foundone
       EXCEPTIONS
            value_over_50_chars = 1
            OTHERS              = 2.

  IF sy-subrc <> 0 OR lf_foundone IS INITIAL.
    PERFORM move_data_via_loops USING rolename.
  ELSE.
    MOVE if_value TO next_agr_name.
    PERFORM move_data_via_no_loops USING rolename .
  ENDIF.

ENDFORM.                    " move_data_to_temp_tabs
*&---------------------------------------------------------------------*
*&      Form  move_data_via_no_loops
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM move_data_via_no_loops USING rolename LIKE agr_define-agr_name.

  DATA: lf_value(50),
        if_value(50),
        lf_foundone.

* This logic may not work properly if the role name is 30 chars
* long and the last character of it is '~'.
*  next_agr_name = lt_agrs-child_agr.
*  length = strlen( next_agr_name ) .  "get current length
*  length = length - 1 .               "get proper off-set
*  next_agr_name+length(1) = '~'.      "replace last char

* Problem:
*   Instead of replacing the last character to '~', the last character
*   should be replaced by the next character or digit based on the
*   current last character.  Replacing the last char to '~'  will
*   include all values from current last char to '~', which is not
*   desired.

* Solution:
*   Need to implement SY-ABCDE or something similar


*     AGR_1016
  READ TABLE lt_1016 WITH KEY agr_name = rolename
             BINARY SEARCH TRANSPORTING NO FIELDS.
  idx1 = sy-tabix.
  READ TABLE lt_1016 WITH KEY agr_name = next_agr_name
             BINARY SEARCH TRANSPORTING NO FIELDS.
  idx2 = sy-tabix.
  IF idx2 GT 1.
    idx2 = idx2 - 1.
  ENDIF.
  APPEND LINES OF lt_1016 FROM idx1 TO idx2 TO et_1016 .
*--START DHORIONS 2011/05/25

**     AGR_1251
*  READ TABLE lt_1251 WITH KEY agr_name = rolename
*             BINARY SEARCH TRANSPORTING NO FIELDS.
*  idx1 = sy-tabix.
*  READ TABLE lt_1251 WITH KEY agr_name = next_agr_name
*             BINARY SEARCH TRANSPORTING NO FIELDS.
*  idx2 = sy-tabix.
*  IF idx2 GT 1.
*    idx2 = idx2 - 1.
*  ENDIF.
*  APPEND LINES OF lt_1251 FROM idx1 TO idx2 TO et_1251 .
*
**     AGR_1252
*  READ TABLE lt_1252 WITH KEY agr_name = rolename
*             BINARY SEARCH TRANSPORTING NO FIELDS.
*  idx1 = sy-tabix.
*  READ TABLE lt_1252 WITH KEY agr_name = next_agr_name
*             BINARY SEARCH TRANSPORTING NO FIELDS.
*  idx2 = sy-tabix.
*  IF idx2 GT 1.
*    idx2 = idx2 - 1.
*  ENDIF.
*  APPEND LINES OF lt_1252 FROM idx1 TO idx2 TO et_1252 .
*--END DHORIONS 2011/05/25

*     UST10S
  READ TABLE lt_1016 WITH KEY agr_name = rolename
             BINARY SEARCH TRANSPORTING NO FIELDS.
  idx1 = sy-tabix.
  LOOP AT lt_1016 FROM idx1 WHERE agr_name = rolename.

    MOVE lt_1016-profile TO lf_value.
    CALL FUNCTION '/PSYNG/BC_GET_NEXT_CHAR'
         EXPORTING
              if_value            = lf_value
         IMPORTING
              ef_value            = if_value
              ef_foundone         = lf_foundone
         EXCEPTIONS
              value_over_50_chars = 1
              OTHERS              = 2.

    IF sy-subrc <> 0 OR lf_foundone IS INITIAL.
      READ TABLE lt_ust10s WITH KEY profn = lt_1016-profile
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      idx2 = sy-tabix.
      LOOP AT lt_ust10s FROM idx2 INTO et_ust10s
              WHERE profn = lt_1016-profile.
        APPEND et_ust10s.
      ENDLOOP.
    ELSE.
      MOVE if_value TO next_profn.
      READ TABLE lt_ust10s WITH KEY profn = lt_1016-profile
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      idx2 = sy-tabix.
      READ TABLE lt_ust10s WITH KEY profn = next_profn
           BINARY SEARCH TRANSPORTING NO FIELDS.
      idx3 = sy-tabix.
      IF idx3 GT 1.
        idx3 = idx3 - 1.
      ENDIF.
      APPEND LINES OF lt_ust10s FROM idx2 TO idx3 TO et_ust10s.
    ENDIF.

  ENDLOOP.

ENDFORM.                    " move_data_via_no_loops
*&---------------------------------------------------------------------*
*&      Form  move_data_via_loops
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM move_data_via_loops USING rolename TYPE agr_define-agr_name.

*     AGR_1016
  READ TABLE lt_1016 WITH KEY agr_name = rolename
             BINARY SEARCH TRANSPORTING NO FIELDS.
  idx1 = sy-tabix.
  LOOP AT lt_1016 FROM idx1 INTO et_1016
          WHERE agr_name = rolename.
    APPEND et_1016.
  ENDLOOP.
*--START DHORIONS 2011/05/25
*     AGR_1251
*  READ TABLE lt_1251 WITH KEY agr_name = rolename
*             BINARY SEARCH TRANSPORTING NO FIELDS.
*  idx1 = sy-tabix.
*  LOOP AT lt_1251 FROM idx1 INTO et_1251
*          WHERE agr_name  = rolename.
*    APPEND et_1251.
*  ENDLOOP.
*
**     AGR_1252
*  READ TABLE lt_1252 WITH KEY agr_name = rolename
*             BINARY SEARCH TRANSPORTING NO FIELDS.
*  idx1 = sy-tabix.
*  LOOP AT lt_1252 FROM idx1 INTO et_1252
*          WHERE  agr_name  = rolename.
*    APPEND et_1252.
*  ENDLOOP.
*--END DHORIONS 2011/05/25

*     UST10S
  READ TABLE lt_1016 WITH KEY agr_name = rolename
             BINARY SEARCH TRANSPORTING NO FIELDS.
  idx1 = sy-tabix.
  LOOP AT lt_1016 FROM idx1 WHERE agr_name = rolename.
    READ TABLE lt_ust10s WITH KEY profn = lt_1016-profile
               BINARY SEARCH TRANSPORTING NO FIELDS.
    idx2 = sy-tabix.
    LOOP AT lt_ust10s FROM idx2 INTO et_ust10s
            WHERE profn = lt_1016-profile.
      APPEND et_ust10s.
    ENDLOOP.
  ENDLOOP.

ENDFORM.                    " move_data_via_loops

*&---------------------------------------------------------------------*
*&      Form  COMPARE_SODDEF_WITH_AUTH_ROLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM compare_soddef_with_auth_role
*--> BOC UMITTAL IBS SOD PN14272 21/07/2025
*--> Check AND relation between Valuesets for all users
  TABLES
  et_match_role_out STRUCTURE /psyng/match_usr.
*--> EOC UMITTAL IBS SOD PN14272 21/07/2025
  DATA : l_enh_tcode TYPE flag.
  DATA : BEGIN OF lt_enh_tcode_con OCCURS 0,
            agr_name TYPE agr_name,
            conid TYPE /psyng/conflict_id,
            funid TYPE /psyng/function_id,
            tcode TYPE tstc-tcode,
         END OF lt_enh_tcode_con.
  DATA : BEGIN OF ls_enh_simu_con ,
            agr_name TYPE agr_name,
            conid TYPE /psyng/conflict_id,
            funid TYPE /psyng/function_id,
            simu_agr TYPE agr_name,
         END OF ls_enh_simu_con,
         lt_enh_simu_con LIKE SORTED TABLE OF ls_enh_simu_con
         WITH UNIQUE KEY agr_name conid funid simu_agr,
         l_simu_subrc LIKE sy-subrc,
         l_analyzed_subrc LIKE sy-subrc.
*orgchk variables
  DATA :  lt_confs_org TYPE SORTED TABLE OF type_confs_org
          WITH UNIQUE KEY agr_name funid abb
          WITH HEADER LINE,
         ls_confs_org LIKE LINE OF lt_confs_org,
         lt_confs_org_unique TYPE TABLE OF
         type_confs_org WITH HEADER LINE,
         ls_hit TYPE flag,
         lf_rolehas TYPE flag.
  DATA : lt_outputdet LIKE TABLE OF routdet WITH HEADER LINE.
  FIELD-SYMBOLS : <confs_org> LIKE ls_confs_org,
                  <confs> LIKE LINE OF confs1,
                  <sysauth> TYPE /psyng/swsodorgauth,
                  <rout> LIKE LINE OF routdet2,
                  <tobjs1> LIKE tobjs1.
  DATA : wa_systemauth TYPE /psyng/swsodorgauth.
  DATA : ls_out TYPE typ_routdet,
         ls_orgm TYPE /psyng/swsodorgm.
  DATA : lt_systemauths TYPE SORTED TABLE OF /psyng/swsodorgauth
         WITH NON-UNIQUE KEY object auth,
         ls_routput LIKE LINE OF gt_routput.
*end orgchk variables

*--DHORIONS 2011/02 Org Level Changes START
  DATA : ls_org_obj TYPE type_org_obj,
      lt_systemauths_tmp TYPE  TABLE OF /psyng/swsodorgauth,
      lt_systemauths_a TYPE SORTED TABLE OF /psyng/swsodorgauth
      WITH  NON-UNIQUE KEY rfcdest auth object abb ,
      lt_org_obj LIKE TABLE OF ls_org_obj WITH HEADER LINE,
      lt_unique_org_abb TYPE TABLE OF /psyng/swsodorgm WITH HEADER LINE,
lt_unique_org_obj_h TYPE HASHED TABLE OF /psyng/swsodorgm WITH UNIQUE KEY object WITH HEADER LINE,
lt_unique_org_obj TYPE  TABLE OF /psyng/swsodorgm  WITH HEADER LINE,
ls_faobj_org TYPE /psyng/faobj2, "AKUMAR OPL645
l_analysis_counter TYPE i,
l_role_count TYPE i,
l_mod TYPE i,
l_roleindex_str TYPE string,
l_pct TYPE f,
l_pct_str TYPE string,
l_pct_i TYPE i,
l_prev_pct_str TYPE string,
l_rol_no_con_cnt TYPE i,
l_progress1 TYPE string,
l_progress2 TYPE string,
l_progress3 TYPE string,
l_confcount TYPE i,
l_confcount_str TYPE string.
  FIELD-SYMBOLS : <org_obj> LIKE ls_org_obj.


*--> BOC UMITTAL IBS SOD PN14272 21/07/2025
*--> Check AND relation between Valuesets for all users
  TYPES : BEGIN OF ty_valuesets,
                vrsio TYPE /psyng/sw_faobj2-vrsio,
                funid TYPE /psyng/sw_faobj2-funid,
                tcode TYPE /psyng/sw_faobj2-tcode,
                object TYPE /psyng/object,
              count TYPE i,
              END OF ty_valuesets ,

         BEGIN OF ty_role_auth_val,
*            bname     TYPE xubname,
            agr_name  TYPE agr_name,
            funid     TYPE /psyng/function_id,
            tcode     TYPE tcode,
            objct     TYPE xuobject,
            valueset  TYPE /psyng/valueset,
          END OF ty_role_auth_val.
  DATA : lt_role_auth_val TYPE STANDARD TABLE OF ty_role_auth_val,
         ls_role_auth_val TYPE ty_role_auth_val,
         lt_match_role_auth TYPE STANDARD TABLE OF /psyng/match_usr,
         ls_match_role_auth TYPE /psyng/match_usr,
*BOC UMITTAL IBS LATEST
        lt_org_obj_temp   TYPE STANDARD TABLE OF type_org_obj.

  FIELD-SYMBOLS : <fs_org_obj_temp> TYPE type_org_obj,
                  <unique_abb> TYPE /psyng/swsodorgm .
*EOC UMITTAL IBS LATEST

  DATA : lt_faobj_u TYPE STANDARD TABLE OF /psyng/sw_faobj2,
         ls_faobj_u TYPE /psyng/sw_faobj2,
         lt_faobj_t TYPE STANDARD TABLE OF ty_valuesets,
         ls_faobj_t TYPE ty_valuesets,
         ls_vrs_and  TYPE /psyng/vrs_and,
         lv_valueset_and_flag TYPE flag,
         lv_flag TYPE flag.
  FIELD-SYMBOLS : <ft_tobjs>      TYPE typ_tobjs.
  CLEAR lv_valueset_and_flag.
**determining the relation between Valuesets
*
  SELECT SINGLE *
    FROM /psyng/vrs_and
    INTO  ls_vrs_and
     WHERE vrsio EQ faobj-vrsio AND
           valueset_and EQ 'X'.
  IF sy-subrc EQ 0.
    lv_valueset_and_flag = 'X' .
  ELSE.
    CLEAR lv_valueset_and_flag.
  ENDIF.

  IF lv_valueset_and_flag EQ 'X'.

    "get count of valuesets for each object inside functions.
    CLEAR lt_faobj_u[].
    lt_faobj_u[] = faobj[].
    SORT lt_faobj_u BY vrsio funid tcode object valueset.
    DELETE ADJACENT DUPLICATES FROM lt_faobj_u COMPARING vrsio funid
                    tcode object valueset."get data with unique valusets
    CLEAR: ls_faobj_u,lt_faobj_t[].
    LOOP AT lt_faobj_u INTO ls_faobj_u.
      ls_faobj_t-vrsio = ls_faobj_u-vrsio.
      ls_faobj_t-funid = ls_faobj_u-funid .
      ls_faobj_t-tcode = ls_faobj_u-tcode .
      ls_faobj_t-object = ls_faobj_u-object .
      ls_faobj_t-count = 1.

      COLLECT ls_faobj_t INTO lt_faobj_t.
    ENDLOOP.

    "Keep only thos objects which have more then one valuesets
*    DELETE lt_faobj_t WHERE count EQ 1.
  ENDIF.
*--> EOC UMITTAL IBS SOD PN14272 21/07/2025




*BOC AKUMAR OPL645
  IF gf_org_field = 'X'.
    SORT gt_faobj_org BY funid tcode object.
  ENDIF.
*EOC AKUMAR OPL645

  lt_unique_org_abb[] = swsodorgm[].
  SORT lt_unique_org_abb BY abb.
  DELETE ADJACENT DUPLICATES FROM lt_unique_org_abb COMPARING abb.

  lt_systemauths_tmp[] = gt_systemauths[].
  SORT lt_systemauths_tmp BY rfcdest auth object abb.
  DELETE ADJACENT DUPLICATES FROM lt_systemauths_tmp
  COMPARING rfcdest auth object abb .

*--Create a hashed table of org relevant objects
  lt_unique_org_obj[] = swsodorgm[].
  SORT lt_unique_org_obj BY object.
  DELETE ADJACENT DUPLICATES FROM lt_unique_org_obj COMPARING object.
  INSERT LINES OF lt_unique_org_obj INTO TABLE lt_unique_org_obj_h.
  FREE lt_unique_org_obj.

  lt_systemauths_a[] = lt_systemauths_tmp[].
  FREE : lt_systemauths_tmp.
*--DHORIONS 2011/02 Org Level Changes END


  MESSAGE s002 WITH 'SOD Analysis'.
  COMMIT WORK.


  IF NOT g_org_check IS INITIAL.
    lt_systemauths = gt_systemauths[].
  ENDIF.


  functtran2[] = functtran[].
  SORT functtran2 BY tcode.
  lt_funcctran[] = functtran2[].
  functtran2[] = functtran[].

*end using a sorted table for funcctran
*  itcdaut2[]   = itcdaut[].

  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
       EXPORTING
            percentage = 50
            text       = text-050.


  LOOP AT lt_funcctran ASSIGNING <functtran>.
    MOVE-CORRESPONDING <functtran> TO wa_ft.
    INSERT wa_ft INTO TABLE ft.
  ENDLOOP.   "functtran

  LOOP AT confdet.
    MOVE-CORRESPONDING confdet TO wa_cf.
    INSERT wa_cf INTO TABLE cf.
  ENDLOOP.   "confdet


  wa_tobjs1-userhas = 'Y'.
  SORT iagr_define BY agr_name.
  DESCRIBE TABLE iagr_define LINES l_role_count.
  LOOP AT iagr_define ASSIGNING <iagr_define>.
*--prevent timeout.
    ADD 1 TO l_analysis_counter.
    PERFORM prevent_timeout USING l_analysis_counter.
*--Report progress every 10%
    l_pct = ( l_analysis_counter / l_role_count ) * 100.
    l_mod = l_pct MOD 10.
    IF l_mod = 0.
      l_pct_i = l_pct.
      l_pct_str = l_pct_i.
      IF l_prev_pct_str <> l_pct_str AND NOT l_pct_i < 1.
        DESCRIBE TABLE routdet LINES l_confcount.
        l_roleindex_str = l_analysis_counter.
        l_confcount_str =  l_confcount .
        CONCATENATE
          l_pct_str '% done - '(m09)
        INTO l_progress1 SEPARATED BY space.
        CONCATENATE
              'Roles : ' l_roleindex_str  ' - '
        INTO l_progress2 SEPARATED BY space.

        CONCATENATE
              'Conflicts : '(m08) l_confcount_str
        INTO l_progress3 SEPARATED BY space.

        MESSAGE s398(00) WITH l_progress1 l_progress2 l_progress3.
        COMMIT WORK.
      ENDIF.
    ENDIF.
    l_prev_pct_str = l_pct_str.

*    ENDLOOP.



*DHORIONS 20110209
    tobjs1[] = tobjs3[].
    PERFORM refresh_internal_tables.

    READ TABLE roletcode WITH KEY agr_name = <iagr_define>-agr_name
                                  BINARY SEARCH
                                  TRANSPORTING NO FIELDS.
    roletcode_idx = sy-tabix.
    LOOP AT roletcode FROM roletcode_idx ASSIGNING <roletcode>.
*             WHERE
*                                  agr_name = <iagr_define>-agr_name.
      IF NOT <roletcode>-agr_name = <iagr_define>-agr_name.
        EXIT.
      ENDIF.
      roletcode_idx = sy-tabix.
*Is this tcode a result of the dynamict tcode enhancement?
      IF g_enh_fm = 'X'.
        READ TABLE gt_enh_tcodes WITH KEY
        calling_tcode = <roletcode>-tcode
        TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          l_enh_tcode = 'X'.
        ELSE.
          CLEAR l_enh_tcode.
        ENDIF.
      ENDIF.
      READ TABLE ft WITH KEY tcode = <roletcode>-tcode
                                               BINARY SEARCH
                                               TRANSPORTING NO FIELDS.
      ft_tabix = sy-tabix.
      LOOP AT ft FROM ft_tabix ASSIGNING <ft>
           WHERE tcode = <roletcode>-tcode.
        READ TABLE cf WITH KEY functionid = <ft>-functionid
                                            BINARY SEARCH
                                            TRANSPORTING NO FIELDS.
        cf_tabix = sy-tabix.
        LOOP AT cf FROM cf_tabix ASSIGNING <cf>
             WHERE functionid  = <ft>-functionid.

*  BELOW: Conflict-function combination already found?
          READ TABLE routdet WITH KEY agr_name = <iagr_define>-agr_name
                                                      conid = <cf>-conid
                                            functionid = <cf>-functionid
                                                           BINARY SEARCH
                                                 TRANSPORTING NO FIELDS.
*          CHECK sy-subrc <> 0.  "combination isn't already evaluated
          l_analyzed_subrc = sy-subrc.
          IF g_bysimu = 'X'.
            READ TABLE lt_enh_simu_con
            WITH KEY agr_name = <iagr_define>-agr_name
                                    conid = <cf>-conid
                               funid = <cf>-functionid
                                         BINARY SEARCH
                                TRANSPORTING NO FIELDS.
            l_simu_subrc = sy-subrc.
          ELSE.
            l_simu_subrc = 0.
          ENDIF.
*combination isn't already evaluated
*(or needs to be further evaluated because of org_check or enhanced
* ruleset or simulation)
*          CHECK
          IF
             l_analyzed_subrc <> 0
          OR l_simu_subrc <> 0 "not yet determ. if funct. is due to
                               "simulation
          OR l_enh_tcode = 'X' "not yet determ. if funct. is due to
                               "ruleset enhancement
          OR g_org_check = 'X' "not yet determ. if funct. is due to
                               "ruleset enhancement
          .

*  Are there any objects defined for the table?  If not, just document
*  tcode info
            READ TABLE faobj WITH KEY funid = <ft>-functionid
                                      tcode = <roletcode>-tcode
                                      BINARY SEARCH
                                      TRANSPORTING NO FIELDS.
            IF sy-subrc <> 0.   "if no objects specified
              wa_routdet-agr_name    = <roletcode>-agr_name.
              wa_routdet-conid       = <cf>-conid.
              wa_routdet-functionid  = <ft>-functionid.

              INSERT wa_routdet INTO TABLE routdet5.
              CLEAR wa_routdet.
            ENDIF.
            IF l_enh_tcode = 'X'.
*--2014/06/11 DHORIONS - Check if tcode was not
*                        already part of the function
              READ TABLE gt_functran_no_enh WITH KEY
              functionid = <cf>-functionid
              tcode      = <roletcode>-tcode.
              IF sy-subrc <> 0.
                lt_enh_tcode_con-agr_name =  <roletcode>-agr_name.
                lt_enh_tcode_con-conid =  <cf>-conid.
                lt_enh_tcode_con-funid =  <cf>-functionid.
                lt_enh_tcode_con-tcode = <roletcode>-tcode.
                COLLECT lt_enh_tcode_con.
              ENDIF.
            ENDIF.

*            IF g_bysimu = 'X'.
            READ TABLE simuagrs WITH KEY
            agr_name = <roletcode>-child_agr.
            IF sy-subrc = 0.
              ls_enh_simu_con-agr_name =  <roletcode>-agr_name.
              ls_enh_simu_con-conid =  <cf>-conid.
              ls_enh_simu_con-funid =  <cf>-functionid.
              ls_enh_simu_con-simu_agr = <roletcode>-child_agr.
              COLLECT ls_enh_simu_con INTO lt_enh_simu_con.
            ENDIF.
*            ENDIF.

            IF     l_enh_tcode IS INITIAL
               AND g_org_check IS INITIAL
               AND l_simu_subrc = 0.
*                EXIT.   "exit since conflict function found
            ENDIF.



            READ TABLE itcdaut WITH KEY rfcdest = <roletcode>-rfcdest
                                         funid  = <ft>-functionid
                                         tcode  = <roletcode>-tcode
                                         BINARY SEARCH
                                         TRANSPORTING NO FIELDS.
*          CHECK sy-subrc = 0.
            IF sy-subrc = 0.
              itcdaut_idx = sy-tabix.
              LOOP AT itcdaut FROM itcdaut_idx ASSIGNING <itcdaut>.

*                                    WHERE
*                                    rfcdest = <roletcode>-rfcdest AND
*                                    funid   = <ft>-functionid AND
*                                    tcode   = <roletcode>-tcode.
                IF NOT <itcdaut>-rfcdest = <roletcode>-rfcdest OR
                   NOT <itcdaut>-funid   = <ft>-functionid     OR
                   NOT <itcdaut>-tcode   = <roletcode>-tcode.
                  EXIT.
                ENDIF.
                READ TABLE roleauth WITH TABLE KEY
                                        agr_name = <roletcode>-agr_name
                                        rfcdest  = <roletcode>-rfcdest
                                        objct    = <itcdaut>-objct
                                        auth     = <itcdaut>-auth
                                      TRANSPORTING objct simu child_agr.
                CHECK sy-subrc = 0.
*--> BOC UMITTAL IBS SOD PN14272 21/07/2025
*--> Check AND relation between Valuesets for all users
                IF lv_valueset_and_flag EQ 'X'.
                  lt_match_role_auth[] = et_match_role_out[].

                  CLEAR ls_match_role_auth.
              SORT lt_match_role_auth BY rfcdest funid tcode objct auth.
*                  DELETE ADJACENT DUPLICATES FROM lt_match_role_auth
*                  COMPARING rfcdest funid tcode objct auth.

                  LOOP AT lt_match_role_auth INTO ls_match_role_auth
                                WHERE rfcdest = <roletcode>-rfcdest
                                  AND funid = <ft>-functionid
                                  AND tcode = <roletcode>-tcode
                                  AND objct = <itcdaut>-objct
                                  AND auth  = <itcdaut>-auth.

                    ls_role_auth_val-agr_name = <roletcode>-agr_name.
                    ls_role_auth_val-funid = <ft>-functionid.
                    ls_role_auth_val-tcode = <roletcode>-tcode.
                    ls_role_auth_val-objct = <itcdaut>-objct.
                ls_role_auth_val-valueset = ls_match_role_auth-valueset.
                    APPEND ls_role_auth_val TO lt_role_auth_val.

                  ENDLOOP.
                ENDIF.
*--> EOC UMITTAL IBS SOD PN14272 21/07/2025
                wa_routdet-agr_name    = <roletcode>-agr_name.
                wa_routdet-conid       = <cf>-conid.
                wa_routdet-functionid  = <ft>-functionid.
                wa_routdet-simu        = roleauth-simu.
                wa_routdet-child_agr = roleauth-child_agr.
                INSERT wa_routdet INTO TABLE routdet5.
                CLEAR wa_routdet.

                IF g_org_check = 'X'.
                  IF NOT <itcdaut>-objct = 'S_TCODE'.
*  --DHORIONS 2011/02 Org Level Changes START
                    ls_org_obj-funid  = <ft>-functionid.
                    ls_org_obj-tcode  = <roletcode>-tcode.
                    ls_org_obj-object = <itcdaut>-objct.
*                 Determine AND/OR relation
                    READ TABLE faobj WITH KEY
                      funid  = ls_org_obj-funid
                      tcode  = ls_org_obj-tcode
                      object = ls_org_obj-object
                      obj_or = 'OR'
                      TRANSPORTING NO FIELDS.
                    IF sy-subrc = 0.
                      ls_org_obj-obj_or = 'OR'.
                    ELSE.
                      ls_org_obj-obj_or = 'AND'.
                    ENDIF.
*BOC AKUMAR 04-02-2025 OPL 645
*                 Check if object is org area relevant
*                READ TABLE swsodorgm
                    IF gf_org_field = 'X'.

                      READ TABLE gt_faobj_org INTO ls_faobj_org WITH KEY
                      funid = <ft>-functionid
                      tcode = <roletcode>-tcode
                      object = <itcdaut>-objct.
                      IF sy-subrc = 0.
                        READ TABLE lt_unique_org_obj_h
                             INTO ls_orgm
                             WITH TABLE KEY
                               object = <itcdaut>-objct.
                      ENDIF.

                    ELSE.

                      READ TABLE lt_unique_org_obj_h
                      INTO ls_orgm
                      WITH TABLE KEY
                        object = <itcdaut>-objct.

                    ENDIF.
*EOC AKUMAR 04-02-2025 OPL 645
                    IF sy-subrc <> 0.
*                 NO : Consider object for all org areas
                      ls_org_obj-abb  ='*'.
                      ls_org_obj-userhas = 'X'.
                      APPEND ls_org_obj TO lt_org_obj.

                    ELSE.
*                 YES : Check which org areas user has
                      LOOP AT lt_unique_org_abb.
                        ls_org_obj-abb  = lt_unique_org_abb-abb.
                        READ TABLE lt_systemauths_a WITH TABLE KEY
                           rfcdest = <roletcode>-rfcdest
                           auth    = <itcdaut>-auth
                           object  = <itcdaut>-objct
                           abb     = ls_org_obj-abb
                           TRANSPORTING NO FIELDS.
                        IF sy-subrc = 0.
                          ls_org_obj-userhas = 'X'.
                        ELSE.
                          CLEAR ls_org_obj-userhas.
                        ENDIF.
                        APPEND ls_org_obj TO lt_org_obj.
                      ENDLOOP.
                    ENDIF.
                  ENDIF.
                ENDIF.

                IF l_enh_tcode = 'X'.
*--2014/06/11 DHORIONS - Check if tcode was not
*                        already part of the function
                  READ TABLE gt_functran_no_enh WITH KEY
                  functionid = <cf>-functionid
                  tcode      = <roletcode>-tcode.
                  IF sy-subrc <> 0.

                    lt_enh_tcode_con-agr_name =  <roletcode>-agr_name.
                    lt_enh_tcode_con-conid =  <cf>-conid.
                    lt_enh_tcode_con-funid =  <cf>-functionid.
                    lt_enh_tcode_con-tcode = <roletcode>-tcode.
                    COLLECT lt_enh_tcode_con.
                  ENDIF.
                ENDIF.
*            IF g_bysimu = 'X'.
                READ TABLE simuagrs WITH KEY
                agr_name = <roletcode>-child_agr.
                IF sy-subrc = 0.
                  ls_enh_simu_con-agr_name =  <roletcode>-agr_name.
                  ls_enh_simu_con-conid =  <cf>-conid.
                  ls_enh_simu_con-funid =  <cf>-functionid.
                  ls_enh_simu_con-simu_agr = <roletcode>-child_agr.
                  COLLECT ls_enh_simu_con INTO lt_enh_simu_con.
*              endif.

                ENDIF.
                READ TABLE tobjs1 ASSIGNING <tobjs1>
                WITH TABLE KEY funid  = <ft>-functionid
                               tcode  = <roletcode>-tcode
                              object = roleauth-objct.
                IF sy-subrc = 0.
                  <tobjs1>-userhas = wa_tobjs1-userhas.
                ENDIF.
*            MODIFY tobjs1 FROM wa_tobjs1 TRANSPORTING
*                   userhas WHERE
*                                funid  = <ft>-functionid AND
*                                tcode  = <roletcode>-tcode AND
*                                object = roleauth-objct.
              ENDLOOP.                       "ITCDAUT
            ENDIF.
          ENDIF.
        ENDLOOP.                         "CF

        AT END OF functionid.
          CLEAR lf_rolehas.
*--> BOC UMITTAL IBS SOD PN14272 21/07/2025
*--> Check AND relation between Valuesets for all users
            IF lv_valueset_and_flag EQ 'X'.
              CLEAR:  ls_faobj_u,
                      ls_role_auth_val,
                      lt_org_obj_temp[].
              "Capture all Org level values in temp table
              lt_org_obj_temp[] = lt_org_obj[].
              LOOP AT lt_faobj_u INTO ls_faobj_u.
                READ TABLE lt_role_auth_val INTO ls_role_auth_val WITH KEY
                funid   = ls_faobj_u-funid
                tcode   = ls_faobj_u-tcode
                objct   = ls_faobj_u-object
                valueset = ls_faobj_u-valueset TRANSPORTING NO FIELDS.

                IF sy-subrc NE 0.
                  READ TABLE tobjs1 ASSIGNING <ft_tobjs>
                  WITH KEY funid = ls_faobj_u-funid
                           tcode = ls_faobj_u-tcode
                           object = ls_faobj_u-object
                       BINARY SEARCH .
                  IF sy-subrc EQ 0
"Adding this condition to check only those objects
"which have Userhas EQ 'Y'
                     AND <ft_tobjs>-userhas EQ 'Y'.

                    <ft_tobjs>-userhas = space.
                    LOOP AT lt_unique_org_abb ASSIGNING <unique_abb>.
                      ls_org_obj-abb  = <unique_abb>-abb.
                      READ TABLE lt_org_obj_temp
                        ASSIGNING <fs_org_obj_temp>
                      WITH KEY funid  = <ft>-functionid
                               tcode  = <roletcode>-tcode
                               object = ls_faobj_u-object
                               abb    = <unique_abb>-abb
                               userhas = 'X'.
                      IF sy-subrc EQ 0.
                        <fs_org_obj_temp>-userhas = space.
                      ENDIF.
                    ENDLOOP.
                    CLEAR : lt_org_obj[].
                    lt_org_obj[] = lt_org_obj_temp[].
                  ENDIF.
                  IF <ft_tobjs> IS ASSIGNED.
                    UNASSIGN <ft_tobjs>.
                  ENDIF.
                  IF <fs_org_obj_temp> IS ASSIGNED.
                    UNASSIGN <fs_org_obj_temp>.
                  ENDIF.
                ENDIF.
              ENDLOOP.

              REFRESH lt_role_auth_val[].
            ENDIF.
*--> EOC UMITTAL IBS SOD PN14272 21/07/2025

          LOOP AT tobjs1 WHERE funid = <ft>-functionid AND
                               tcode = <roletcode>-tcode AND
                               obj_or NE 'OR' AND
                               userhas <> 'Y'.   "#EC SAST_CI_GEN_CHECK
            FREE routdet5.
            DELETE lt_enh_tcode_con WHERE
                                    agr_name = <roletcode>-agr_name
                                    AND   funid = <ft>-functionid
                                    AND   tcode = <roletcode>-tcode.
            "AND   conid = <cf>-conid.
            EXIT.
          ENDLOOP.
          IF sy-subrc <> 0.
            lf_rolehas = 'X'.
          ENDIF.
          READ TABLE tobjs1 WITH KEY funid = <ft>-functionid
                               tcode = <roletcode>-tcode
                               obj_or = 'OR'.
          IF sy-subrc = 0.
            READ TABLE tobjs1 WITH KEY funid = <ft>-functionid
                                 tcode = <roletcode>-tcode
                                 obj_or = 'OR'
                                 userhas = 'Y'.
            IF sy-subrc <> 0.
              CLEAR lf_rolehas.
              FREE routdet5.

            ENDIF.
          ENDIF.
*         CHECK sy-subrc <> 0.  "if role has at least 1 auth for all
*objs
          IF lf_rolehas = 'X'.
            LOOP AT routdet5.
              INSERT routdet5 INTO TABLE routdet.
            ENDLOOP.
          ENDIF.
          FREE routdet5.
          tobjs1[] = tobjs3[].
        ENDAT.
      ENDLOOP.  "FT
    ENDLOOP.  "roletcode
*--DHORIONS 2011/02 Org Level Changes START
    AT END OF agr_name.

      IF NOT g_org_check IS INITIAL.
        SORT lt_org_obj.
        DELETE ADJACENT DUPLICATES FROM lt_org_obj.
        LOOP AT cf ASSIGNING <cf>.
          AT NEW functionid.
            PERFORM determine_org_area_for_func_nw
              USING
                <cf>-functionid
                <iagr_define>-agr_name
              CHANGING
                    lt_org_obj[]
                    lt_unique_org_abb[]
                    lt_confs_org[].
*             endif.
          ENDAT.
        ENDLOOP.
        REFRESH : lt_org_obj[].
      ENDIF.
    ENDAT.
*--DHORIONS 2011/02 Org Level Changes END

*--Delete data related to analyzed role
    DELETE roletcode WHERE agr_name = <iagr_define>-agr_name.
  ENDLOOP.    "iagr_define.
  FREE : roletcode[], roleauth[], itcdaut[].
  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
       EXPORTING
            percentage = 90
            text       = text-052.
**data for org level reporting
  FIELD-SYMBOLS :
         <confs1>           LIKE LINE OF   confs1,
         <routdet>         LIKE routdet .
*data for org level reporting
  DATA : l_confs_idx LIKE sy-tabix,
         lf_simu TYPE flag.
  SORT confs2.
  routdet2[] = routdet[].

  IF NOT g_org_check IS INITIAL.
*--Collect functions that are org area relevant
    lt_confs_org_unique[] = lt_confs_org[].
    SORT lt_confs_org_unique BY agr_name funid abb.
    DELETE ADJACENT DUPLICATES FROM lt_confs_org_unique
    COMPARING agr_name funid.
*--Limit based on org level
    IF  NOT gt_orglvl[] IS INITIAL.
      DELETE lt_confs_org WHERE NOT abb IN gt_orglvl
      AND NOT abb = '*'.                                "#EC CI_SORTSEQ
    ENDIF.
  ENDIF.

  LOOP AT routdet ASSIGNING <routdet>.
    AT NEW agr_name.
      confs1[] = confs2[].
    ENDAT.
    READ TABLE confs1 WITH KEY conid = <routdet>-conid
    BINARY SEARCH TRANSPORTING NO FIELDS.
    l_confs_idx = sy-tabix.
    LOOP AT confs1 FROM l_confs_idx ASSIGNING <confs1>.
      IF NOT <confs1>-conid = <routdet>-conid.
        EXIT.
      ENDIF.
      IF <confs1>-functionid = <routdet>-functionid.
        <confs1>-userhas = 'Y'.
      ENDIF.
    ENDLOOP.

    IF sy-subrc = 0. ENDIF.

    AT END OF agr_name.
      LOOP AT confs1 ASSIGNING <confs1>
           WHERE userhas NE 'Y'.                 "#EC SAST_CI_GEN_CHECK
        DELETE routdet2 WHERE agr_name = <routdet>-agr_name AND
                                 conid = <confs1>-conid.
        DELETE confs1 WHERE conid = <confs1>-conid.

      ENDLOOP.
      IF NOT g_org_check IS INITIAL.
**--Collect functions that are org area relevant
        SORT : confs1.", lt_confs_org.
        LOOP AT confs1.
*       check if at least 1 orglevel for this function
*       occurs in all other functions for conflict
          CLEAR ls_hit.
          LOOP AT confs1 ASSIGNING <confs>
                  WHERE conid      = confs1-conid AND
                        functionid <> confs1-functionid.
            READ TABLE lt_confs_org_unique WITH KEY
                 agr_name = <routdet>-agr_name
                 funid    = confs1-functionid
                 BINARY SEARCH TRANSPORTING NO FIELDS.
            IF sy-subrc = 0.
              READ TABLE lt_confs_org WITH KEY
                agr_name = <routdet>-agr_name
                     funid = confs1-functionid
                TRANSPORTING NO FIELDS.
              LOOP AT lt_confs_org ASSIGNING <confs_org>
               FROM sy-tabix
               WHERE agr_name = <routdet>-agr_name AND
                     funid = confs1-functionid.
                READ TABLE lt_confs_org WITH KEY
                    agr_name = <routdet>-agr_name
                    funid = <confs>-functionid
                    abb   = <confs_org>-abb.
                IF  sy-subrc = 0 AND NOT <confs_org>-abb IS INITIAL .
                  ls_hit = 'X'.
                  EXIT.
                ELSE.
                  READ TABLE lt_confs_org WITH KEY
                      agr_name = <routdet>-agr_name
                      funid = <confs>-functionid
                      abb   = '*'.
                  IF sy-subrc = 0 OR <confs_org>-abb = '*'.
*                   All org areas match.
                    ls_hit = 'X'.
                  ENDIF.
                ENDIF.
              ENDLOOP.    "lt_confs_org
            ELSE.
*         there are no org levels in this conflict.
*--DHORIONS 2019/05/10 - objects with no org were added with a * so
*                        not finding anything means the object was org
*                        relevant, but no matching value found
*              ls_hit = 'X'.
            ENDIF.
          ENDLOOP.                                          "confs1
          IF sy-subrc = 0.
            IF ls_hit <> 'X'.
              "org not found and more
              "than 1 function in onflict

              DELETE routdet2 WHERE agr_name = <routdet>-agr_name AND
                     conid = confs1-conid.
            ENDIF.
          ELSE.
            "this is a one sided conflict,
            "but it didn't match any org fully
            READ TABLE lt_confs_org WITH KEY
                      agr_name = <routdet>-agr_name
                      funid    = confs1-functionid
                      TRANSPORTING NO FIELDS.
            IF sy-subrc <> 0.
*  Function not found at all
              DELETE routdet2 WHERE agr_name = <routdet>-agr_name AND
                     conid = confs1-conid.
            ENDIF.
          ENDIF.
        ENDLOOP.                                            "confs1
      ENDIF.     "IF NOT g_org_check IS INITIAL

      REFRESH confs1.
      confs1[] = confs2[].
    ENDAT.
  ENDLOOP.
  DELETE routdet2 WHERE agr_name = space.
  REFRESH routdet.
  FREE : routdet[].
* buffer conflict headers
  DATA : lt_conhdr TYPE SORTED TABLE OF /psyng/conflict
                                      WITH HEADER LINE
                                      WITH UNIQUE KEY conid.
  DATA : lt_routdet LIKE TABLE OF routdet2.
  lt_routdet[] = routdet2[].
  SORT lt_routdet BY conid.
  DELETE ADJACENT DUPLICATES FROM lt_routdet COMPARING conid.

  IF NOT lt_routdet[] IS INITIAL.
    IF conflict[] IS INITIAL.
      SELECT * FROM /psyng/conflict INTO TABLE lt_conhdr
      FOR ALL ENTRIES IN lt_routdet
      WHERE
        conid = lt_routdet-conid
        AND
        vrsio = g_vrsio.
    ELSE.
      lt_conhdr[] = conflict[].
    ENDIF.
    FREE : lt_routdet[].

  ENDIF.

  CONCATENATE sy-sysid sy-mandt INTO wa_routdet-rfcdest.
  LOOP AT routdet2.
    READ TABLE lt_conhdr WITH KEY conid = routdet2-conid
    BINARY SEARCH.
    CHECK sy-subrc = 0.
    wa_routdet-description = lt_conhdr-description.
    wa_routdet-imp         = lt_conhdr-imp.
    wa_routdet-risk        = lt_conhdr-risk.

    MODIFY routdet2 FROM wa_routdet TRANSPORTING description imp rfcdest
                                                                    risk
                                                                   WHERE
                                        agr_name = routdet2-agr_name AND
                                              conid    = routdet2-conid.
  ENDLOOP.
  FREE : lt_conhdr[]."free conhdr buffer

*gt_routdet_sum and gt_routdet
  DELETE ADJACENT DUPLICATES FROM routdet2.
  LOOP AT routdet2 ASSIGNING <rout>.
    MOVE-CORRESPONDING <rout> TO ls_routput.
    APPEND ls_routput TO gt_routput.
  ENDLOOP.
  FREE  routdet2[].
  gt_routput_sum[] = gt_routput[].
  SORT gt_routput_sum BY agr_name conid simu DESCENDING.
  DELETE ADJACENT DUPLICATES FROM gt_routput_sum COMPARING
  agr_name conid.
  CLEAR ls_routput-functionid.
  IF NOT gt_routput_sum[] IS INITIAL.
    MODIFY gt_routput_sum FROM ls_routput TRANSPORTING functionid
    WHERE functionid <> ''.
  ENDIF.
*-Mark the correct records as enhanced
  LOOP AT lt_enh_tcode_con.
    CLEAR wa_routdet.
    ls_routput-enhanced = 'X'.
    MODIFY  gt_routput FROM ls_routput
          TRANSPORTING enhanced
          WHERE
          agr_name  = lt_enh_tcode_con-agr_name AND
          conid     = lt_enh_tcode_con-conid    AND
          functionid = lt_enh_tcode_con-funid.
    MODIFY  gt_routput_sum FROM ls_routput
    TRANSPORTING enhanced
          WHERE
          agr_name  = lt_enh_tcode_con-agr_name AND
          conid     = lt_enh_tcode_con-conid.
  ENDLOOP.
*-Mark the correct records as simulated
  LOOP AT lt_enh_simu_con INTO ls_enh_simu_con.
    CLEAR wa_routdet.
    ls_routput-simu = 'X'.
    ls_routput-child_agr = ls_enh_simu_con-simu_agr.
    MODIFY  gt_routput FROM ls_routput
          TRANSPORTING simu child_agr
          WHERE
          agr_name  = ls_enh_simu_con-agr_name AND
          conid     = ls_enh_simu_con-conid    AND
          functionid = ls_enh_simu_con-funid.
    MODIFY  gt_routput_sum FROM ls_routput
          TRANSPORTING simu child_agr
          WHERE
          agr_name  = ls_enh_simu_con-agr_name AND
          conid     = ls_enh_simu_con-conid.

  ENDLOOP.

ENDFORM.                    " COMPARE_SODDEF_WITH_AUTH_FOR_R

*&---------------------------------------------------------------------*
*&      Form  get_org_level_auth
*&---------------------------------------------------------------------*
*       Select authorizations that contain org levels
*----------------------------------------------------------------------*
FORM get_org_level_auth
  TABLES it_simu_auths STRUCTURE /psyng/roleauth.
  DATA : l_idx           LIKE sy-tabix,
         lf_match        TYPE flag,
         lt_systemauths  TYPE TABLE OF /psyng/swsodorgauth,
         ls_systemauth   LIKE LINE OF lt_systemauths.
DATA: lt_simu_auth  TYPE TABLE OF agr_1251," WITH NON-UNIQUE KEY object field,  "HBHALL
ls_simu_auth  TYPE  agr_1251,                                           "HBHALLA
lt_systemauths_local  TYPE TABLE OF /psyng/swsodorgauth,                "HBHALLA
ls_systemauths_local  TYPE /psyng/swsodorgauth.                         "HBHALLA

  IF g_org_check IS INITIAL.
    EXIT.
  ENDIF.
  MESSAGE s002 WITH 'Reading Org Level Configuration'.
  COMMIT WORK.

*  MESSAGE s208(00) WITH text-152.
*Using own FM

  lt_systemauths[] = gt_systemauths[].
  FREE gt_systemauths[].
  CALL FUNCTION '/PSYNG/SW_024'
       TABLES
            swsodorgm   = swsodorgm
            uniqueauths = uniqueauths
            systemauths = lt_systemauths.

  LOOP AT it_simu_auths.                                 "BOC HBHALLA
    ls_simu_auth-agr_name = it_simu_auths-agr_name.
    ls_simu_auth-object   = it_simu_auths-objct   .
    ls_simu_auth-auth     = it_simu_auths-auth    .
    ls_simu_auth-field    = it_simu_auths-field   .
    ls_simu_auth-low      = it_simu_auths-von     .
    ls_simu_auth-high     = it_simu_auths-bis     .
    APPEND ls_simu_auth TO lt_simu_auth.
    CLEAR ls_simu_auth.
  ENDLOOP.

  IF lt_simu_auth[] IS NOT INITIAL.
    CALL FUNCTION '/PSYNG/SW_024'
     EXPORTING
       i_fielddetails       = 'X'
      TABLES
        swsodorgm            =   swsodorgm
        uniqueauths          =   uniqueauths
        systemauths          =   lt_systemauths_local
        it_simu_auths        =   lt_simu_auth.

* LOOP AT lt_systemauths_local INTO ls_systemauths_local.      "HBHALLA
*      APPEND ls_systemauths_local TO lt_systemauths.          "HBHALLA
*      CLEAR ls_systemauths_local.                             "HBHALLA
* ENDLOOP.                                                     "HBHALLA

    APPEND LINES OF lt_systemauths_local TO lt_systemauths.   "GSINGH
    FREE lt_systemauths_local.                                "GSINGH
  ENDIF.

* END OF CHANGE

*--Also analyze all simulated auths
***  sort swsodorgm by object varbl.                               "Start of Commenting: HBHALLA
***  loop at it_simu_auths.
***    read table swsodorgm with key object = it_simu_auths-objct
***                                  varbl  = it_simu_auths-field
***    binary search.
***    if sy-subrc = 0.
***      l_idx = sy-tabix.
***      loop at swsodorgm from l_idx.
***        if swsodorgm-object <> it_simu_auths-objct or
***           swsodorgm-varbl  <> it_simu_auths-field.
***           exit.
***        endif.
****        CALL FUNCTION '/PSYNG/SW_021'
***        CALL FUNCTION '/PSYNG/SW_COMPARE_RANGES'
***         EXPORTING
***           AUTH_FROM        = it_simu_auths-von
***           AUTH_TO          = it_simu_auths-bis
***           SOD_FROM         = swsodorgm-LOW
***           SOD_TO           = swsodorgm-high
***           I_BUFFER_SIZE    = 50000
***         IMPORTING
***           MATCH            = lf_match.
***        if lf_match = 'X'.
***          move-corresponding it_simu_auths to ls_systemauth.
***          ls_systemauth-object = it_simu_auths-objct.
***          ls_systemauth-abb    = swsodorgm-abb.
***          append ls_systemauth to lt_systemauths.
***        endif.
***      endloop.
***    endif.
***  endloop.                                                       "End of Commenting: HBHALLA


  SORT lt_systemauths.
  DELETE ADJACENT DUPLICATES FROM lt_systemauths
  COMPARING rfcdest auth object abb.
SORT lt_systemauths[] BY auth.                                       "HBHALLA bug prevent
  gt_systemauths[] = lt_systemauths[].
  FREE lt_systemauths[].
ENDFORM. " get_org_level_auth

*&---------------------------------------------------------------------*
*&      Form  get_simulation_roles_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_simulation_roles_data TABLES et_return STRUCTURE bapiret2.
  DATA : rfcdest TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO rfcdest.
  LOOP AT simuagrs.
    REFRESH: roletcode_fm, roleprof_fm, roleauth_fm.
    CLEAR: roletcode_fm, roleprof_fm, roleauth_fm.
    IF g_simu_rfc = space.
      CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
           EXPORTING
                agr_name       = simuagrs-agr_name
                bname          = ''
           TABLES
                roleauth       = roleauth_fm
                roletcode      = roletcode_fm
                roleprof       = roleprof_fm
                functtran      = functtran
                faobj          = faobj
           EXCEPTIONS
                role_not_found = 1
                OTHERS         = 2.
      IF sy-subrc <> 0.
        MESSAGE i154 WITH simuagrs-agr_name INTO et_return-message.
        et_return-type       = 'I'.
        et_return-id         = '/PSYNG/SW'.
        et_return-number     = '154'.
        et_return-message_v1 = simuagrs-agr_name.
        APPEND et_return.
        CONTINUE.
      ENDIF.

    ELSEIF g_simu_rfc <> space.
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
      CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
           DESTINATION g_simu_rfc
           EXPORTING
                agr_name  = simuagrs-agr_name
                bname     = ''
*--Dhorions 20101222
                rem_execution = 'X'
                rfcdest       = rfcdest
           TABLES
                roleauth  = roleauth_fm
                roletcode = roletcode_fm
                roleprof  = roleprof_fm
                functtran = functtran
                faobj     = faobj
           EXCEPTIONS
                system_failure = 1
                communication_failure = 2
                role_not_found = 3
                OTHERS         = 4.              "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

      IF sy-subrc <> 0.
        MESSAGE i154 WITH simuagrs-agr_name INTO et_return-message.
        et_return-type       = 'I'.
        et_return-id         = '/PSYNG/SW'.
        et_return-number     = '154'.
        et_return-message_v1 = simuagrs-agr_name.
        APPEND et_return.
        CONTINUE.
      ENDIF.
    ENDIF.

    CLEAR: wa_roletcode, wa_roleauth.
    LOOP AT roletcode_fm.
      wa_roletcode-child_agr = roletcode_fm-agr_name.
      wa_roletcode-agr_name = iagr_define-agr_name.
      wa_roletcode-tcode    = roletcode_fm-tcode.
*      wa_roletcode-rfcdest = roletcode_fm-rfcdest.
      wa_roletcode-rfcdest  = rfcdest.
      wa_roletcode-simu = 'X'.
      INSERT wa_roletcode INTO TABLE roletcode.
    ENDLOOP.
    LOOP AT roleauth_fm.
      MOVE-CORRESPONDING roleauth_fm TO wa_roleauth.
      wa_roleauth-child_agr = wa_roleauth-agr_name.
      wa_roleauth-agr_name  = iagr_define-agr_name.
      wa_roleauth-simu = 'X'.
*      CLEAR: wa_roleauth-field,
*             wa_roleauth-von,
*             wa_roleauth-bis.
*             wa_roleauth-child_agr.
*      wa_roleauth-rfcdest = roleauth_fm-rfcdest.

      wa_roleauth-rfcdest = rfcdest.
      INSERT wa_roleauth INTO TABLE roleauth.
    ENDLOOP.
  ENDLOOP.

ENDFORM.                    " get_simulation_roles_data
*&---------------------------------------------------------------------*
*&      Form  REFRESH_INTERNAL_TABLES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM refresh_internal_tables.
  REFRESH:    itcd.              .
ENDFORM.                    " REFRESH_INTERNAL_TABLES
*&---------------------------------------------------------------------*
*&      Form  get_advanced_simu_auths
*&---------------------------------------------------------------------*
*       Get role contents as well as a
*----------------------------------------------------------------------*
*      -->P_IT_ADVANCED_SIMU_AUTHS  text
*      -->P_ROLEAUTHS  text
*      -->P_ROLETCODES  text
*----------------------------------------------------------------------*
FORM get_advanced_simu_auths TABLES
  it_advanced_role_simu STRUCTURE agr_1251
*  it_roleauths structure /psyng/roleauth
*  it_roletcodes structure /psyng/roletcode
  et_return STRUCTURE bapiret2
  it_roles STRUCTURE /psyng/sw_sel_opts_agr_name
  it_faobj STRUCTURE /psyng/faobj2
  it_simu_role_removal STRUCTURE /psyng/sw_role_removal_simu
  et_simu_removed_roles STRUCTURE /psyng/sw_removed_roles_role.
  DATA : lt_simulated_roles TYPE TABLE OF agr_define
  WITH HEADER LINE,
  lt_range_tcode TYPE TABLE OF /psyng/range_tcode WITH HEADER LINE,
  lt_range_tcode_tmp TYPE TABLE OF /psyng/range_tcode WITH HEADER LINE,
  lt_tstc TYPE TABLE OF tstc WITH HEADER LINE,
  l_rfcdest TYPE rfcdest,
  lt_agr_agrs TYPE TABLE OF agr_agrs WITH HEADER LINE,
  lt_agr_agrs_temp TYPE TABLE OF agr_agrs WITH HEADER LINE,
  lt_ust10c TYPE TABLE OF ust10c WITH HEADER LINE,
  it_roles_temp LIKE TABLE OF it_roles,
  it_roles_temp1 LIKE TABLE OF it_roles.

  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest.
*--Fetch all possible tcodes
  FREE lt_range_tcode.
  LOOP AT it_advanced_role_simu WHERE object = 'S_TCODE' AND
                                      field  = 'TCD'.
    CLEAR lt_range_tcode.

**** Changes for Case#2441
** ------- No selection needed if value contains only * or space
    IF  it_advanced_role_simu-low EQ '*' OR
           it_advanced_role_simu-low IS INITIAL.
      REFRESH lt_range_tcode.
      lt_range_tcode-sign   = 'I'.
      lt_range_tcode-option = 'CP'.
      lt_range_tcode-low    = '*'.
      APPEND lt_range_tcode.
      EXIT.
    ENDIF.

***  -------------------------------------------------------------

    IF it_advanced_role_simu-low NS '*' AND
       it_advanced_role_simu-high IS INITIAL.
*--     no selection needed, direct values will be used
    ELSE.
      IF NOT it_advanced_role_simu-high IS INITIAL.
        lt_range_tcode-sign   = 'I'.
        lt_range_tcode-option = 'BT'.
        lt_range_tcode-low    = it_advanced_role_simu-low.
        lt_range_tcode-high   = it_advanced_role_simu-high.
      ELSE.
        lt_range_tcode-sign   = 'I'.
        lt_range_tcode-option = 'CP'.
        lt_range_tcode-low    = it_advanced_role_simu-low.
        CLEAR lt_range_tcode-high.
      ENDIF.
      APPEND lt_range_tcode.
    ENDIF.

  ENDLOOP.

  SORT lt_range_tcode BY sign option low high.
  DELETE ADJACENT DUPLICATES FROM lt_range_tcode COMPARING ALL FIELDS.

  DESCRIBE TABLE lt_range_tcode LINES sy-tfill.
  IF sy-tfill LT 5000.
    WHILE NOT lt_range_tcode[] IS INITIAL.
      APPEND LINES OF lt_range_tcode
      FROM 1 TO 1000 TO lt_range_tcode_tmp .
      SELECT tcode FROM tstc INTO TABLE lt_tstc     "#EC CI_IMUD_NESTED
      WHERE tcode IN lt_range_tcode_tmp.
      DELETE lt_range_tcode FROM 1 TO 1000.
      FREE lt_range_tcode_tmp.
    ENDWHILE.
  ELSE.
    SELECT tcode INTO TABLE lt_tstc FROM tstc.      "#EC CI_IMUD_NESTED
    DELETE lt_tstc WHERE NOT tcode IN lt_range_tcode.
  ENDIF.

*--Advanced Role Simulation
  it_roles_temp1[] = it_roles[].
  LOOP AT it_advanced_role_simu.
    AT NEW agr_name.
*--Remove simulated roles from list of roles to load
      lt_simulated_roles-agr_name = it_advanced_role_simu-agr_name.
      APPEND lt_simulated_roles.
      simuagrs-agr_name = it_advanced_role_simu-agr_name.
      APPEND simuagrs.
*--DHORIONS 20130606 - If something was deleted from a single role, we
*  put it in the it_simu_role_removal table, and remove it later, to
*  ensure that the authorizations for that role are not loaded by
*  calling get_roles_data
      CONCATENATE sy-sysid sy-mandt INTO it_simu_role_removal-rfcdest.
      it_simu_role_removal-sign    = 'I'.
      it_simu_role_removal-option  = 'EQ'.
      it_simu_role_removal-low     = it_advanced_role_simu-agr_name.
      it_simu_role_removal-high    = ''.
      APPEND it_simu_role_removal.
      DELETE iagr_define WHERE
      agr_name = it_advanced_role_simu-agr_name.
*--Identify composite roles
      FREE lt_agr_agrs.
*      SELECT * FROM agr_agrs                        "#EC CI_IMUD_NESTED
*      INTO TABLE lt_agr_agrs
*      WHERE
*      agr_name  IN it_roles AND
*      child_agr = it_advanced_role_simu-agr_name AND
*      attributes <> 'X'.
*-- identify composite roles
      it_roles[] = it_roles_temp1[].
      WHILE NOT it_roles[] IS INITIAL.
        APPEND LINES OF it_roles FROM 1 TO 1200 TO it_roles_temp.
        SELECT * FROM agr_agrs                      "#EC CI_IMUD_NESTED
         INTO TABLE lt_agr_agrs_temp
         WHERE
         agr_name  IN it_roles_temp AND
         child_agr = it_advanced_role_simu-agr_name AND
         attributes <> 'X'.
        APPEND LINES OF lt_agr_agrs_temp TO lt_agr_agrs.
        REFRESH lt_agr_agrs_temp.
        DELETE it_roles FROM 1 TO 1200.
        REFRESH : it_roles_temp.
      ENDWHILE.

      IF lt_agr_agrs[] IS INITIAL.
        it_roles[] = it_roles_temp1[].
*-- identify composite profile
        WHILE NOT it_roles[] IS INITIAL.
          APPEND LINES OF it_roles FROM 1 TO 1200 TO it_roles_temp.
          SELECT * FROM ust10c
          INTO TABLE lt_ust10c
          WHERE
          profn  IN it_roles_temp AND
          subprof = it_advanced_role_simu-agr_name
          AND aktps = 'A'.
          LOOP AT lt_ust10c.
            lt_agr_agrs-agr_name = lt_ust10c-profn.
            lt_agr_agrs-child_agr = lt_ust10c-subprof.
            APPEND lt_agr_agrs.
          ENDLOOP.
          REFRESH lt_ust10c.
          DELETE it_roles FROM 1 TO 1200.
          REFRESH : it_roles_temp.
        ENDWHILE.
      ENDIF.
*       loop at lt_agr_agrs.
*          lt_simulated_roles-agr_name = IT_ADVANCED_ROLE_SIMU-agr_name.
*          append lt_simulated_roles.
*          simuagrs-agr_name = IT_ADVANCED_ROLE_SIMU-agr_name.
*          append simuagrs.
*          delete iagr_define where
*          agr_name = IT_ADVANCED_ROLE_SIMU-agr_name.
*       endloop.
    ENDAT.
*--Add simulated role contents to roleauth table
    roleauth-agr_name = it_advanced_role_simu-agr_name.
    roleauth-rfcdest  = l_rfcdest.
    roleauth-objct    = it_advanced_role_simu-object.
    roleauth-auth     = it_advanced_role_simu-auth.
    roleauth-field    = it_advanced_role_simu-field.
    roleauth-von      = it_advanced_role_simu-low.
    roleauth-bis      = it_advanced_role_simu-high.
    roleauth-child_agr = it_advanced_role_simu-agr_name.
*        roleauth-PROFN.
    roleauth-simu     = 'X'.
    INSERT TABLE roleauth.
*--Also for composite roles
    LOOP AT lt_agr_agrs.
      roleauth-agr_name = lt_agr_agrs-agr_name.
      INSERT TABLE roleauth.
    ENDLOOP.
*--Add simulated role contents to roletcode table
    IF it_advanced_role_simu-object = 'S_TCODE' AND
       it_advanced_role_simu-field  = 'TCD'.

      roletcode-agr_name = it_advanced_role_simu-agr_name.
      roletcode-rfcdest  = l_rfcdest.
      roletcode-auth     = it_advanced_role_simu-auth .
*            roletcode-PROFN.
      roletcode-child_agr = it_advanced_role_simu-agr_name.
      roletcode-simu = 'X'.

      IF it_advanced_role_simu-low NS '*' AND
        it_advanced_role_simu-high IS INITIAL.
        roletcode-tcode =  it_advanced_role_simu-low.
        INSERT TABLE roletcode.
*--Also for composite roles
        LOOP AT lt_agr_agrs.
          roletcode-agr_name = lt_agr_agrs-agr_name.
          INSERT TABLE roletcode.
        ENDLOOP.

      ELSE.
        FREE lt_range_tcode.
        IF NOT it_advanced_role_simu-high IS INITIAL.
          lt_range_tcode-sign   = 'I'.
          lt_range_tcode-option = 'BT'.
          lt_range_tcode-low    = it_advanced_role_simu-low.
          lt_range_tcode-high   = it_advanced_role_simu-high.
        ELSE.
          lt_range_tcode-sign   = 'I'.
          lt_range_tcode-option = 'CP'.
          lt_range_tcode-low    = it_advanced_role_simu-low.
          CLEAR lt_range_tcode-high.
        ENDIF.
        APPEND lt_range_tcode.
*             select tcode from tstc into table lt_tstc
*             where tcode in lt_range_tcode.
*             if not lt_tstc[] is initial.
*               loop at lt_tstc.
*                 roletcode-tcode =  lt_tstc-tcode.
*                  insert table roletcode.
*               endloop.
*             endif.
        LOOP AT lt_tstc WHERE tcode IN lt_range_tcode.
          roletcode-agr_name = it_advanced_role_simu-agr_name.
          roletcode-tcode =  lt_tstc-tcode.
          INSERT TABLE roletcode.
*--Also for composite roles
          LOOP AT lt_agr_agrs.
            roletcode-agr_name = lt_agr_agrs-agr_name.
            INSERT TABLE roletcode.
          ENDLOOP.

        ENDLOOP.

      ENDIF.
    ENDIF.
*--Begin of placeholder tcodes
*        CONCATENATE sy-sysid sy-mandt INTO rfcdest.
    LOOP AT functtran WHERE tcode CP
      /psyng/sw_cl_constants=>placeholder_tcode_prefix.
*        LOOP AT lt_agrs.
      roletcode-agr_name = it_advanced_role_simu-agr_name.
      roletcode-tcode =  functtran-tcode.
      roletcode-rfcdest  = l_rfcdest.
      INSERT TABLE roletcode.
*        ENDLOOP.
    ENDLOOP.
  ENDLOOP.
  it_roles[] = it_roles_temp1[].
  FREE it_roles_temp1[].

*--Load all data from roles that are not simulated
  PERFORM get_roles_data TABLES
    et_return
    it_faobj
    it_simu_role_removal
    et_simu_removed_roles.
*--Add simulated roles back to list of roles.
  LOOP AT lt_simulated_roles.
    iagr_define-agr_name = lt_simulated_roles-agr_name.
    INSERT TABLE iagr_define.
*--DHORIONS 20130606 - If something was deleted from a single role, we
*  put it in the it_simu_role_removal before calling get_roles_data
*  now we remove it again
    DELETE  it_simu_role_removal
    WHERE low = lt_simulated_roles-agr_name.
  ENDLOOP.


ENDFORM.                    " get_advanced_simu_auths
*---------------------------------------------------------------------*
*       FORM determine_org_area_for_func                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_FUNID                                                       *
*  -->  I_AGR_NAME                                                    *
*  -->  IT_ORG_OBJ                                                    *
*  -->  IT_UNIQUE_ORG_ABB                                             *
*  -->  IT_CONFS_ORG                                                  *
*---------------------------------------------------------------------*
FORM determine_org_area_for_func
USING
         i_funid TYPE /psyng/function_id
         i_agr_name TYPE agr_name
CHANGING
  it_org_obj         LIKE  g_org_obj[]
  it_unique_org_abb  LIKE g_swsodorgm[]
  it_confs_org       LIKE g_confs_org[].
  FIELD-SYMBOLS : <confs> LIKE confs1,
                  <unique_org_abb> TYPE /psyng/swsodorgm,
                  <org_obj> TYPE type_org_obj,
                  <org_obj2> TYPE type_org_obj.

  DATA : l_tcode_count TYPE i,
         l_tcode_found_count TYPE i,
         l_tcode_found TYPE flag,
         l_obj_count TYPE i,
         l_obj_found_count TYPE i,
         l_obj_found TYPE flag,
         l_prev_obj TYPE xuobject,
         l_next_obj TYPE xuobject,
         l_prev_org TYPE /psyng/dorg_abb,
         l_org_obj_tabix LIKE sy-tabix,
         l_org_obj_tabix_nxt LIKE sy-tabix,
         ls_confs_org TYPE type_confs_org,
         lt_obj_org TYPE SORTED TABLE OF type_org_obj
         WITH NON-UNIQUE KEY funid tcode object abb.

*--SF Case 3442 : Only the objects for which a user had access to at
*           least one configured ABB was considered when counting the
*           number of org relevant objects for a tcode.
  DATA :   lt_tcode_obj TYPE SORTED TABLE OF type_org_obj
           WITH UNIQUE KEY tcode object WITH HEADER LINE,
           BEGIN OF lt_tcode_obj_count OCCURS 0,
             tcode     TYPE tcode,
             obj_count TYPE i,
           END OF lt_tcode_obj_count.



  FREE : lt_obj_org,lt_tcode_obj,lt_tcode_obj_count.
  LOOP AT it_org_obj ASSIGNING <org_obj>
     WHERE funid = i_funid.

*--SF Case 2072 : for AND relations between objects,
*                 we ignore the '*' for orabb
    IF NOT ( <org_obj>-obj_or  = 'AND' AND
                <org_obj>-abb = '*' ).
      INSERT  <org_obj> INTO TABLE lt_obj_org .
    ENDIF.
*--SF Case 3442 : keep track of tcode object combinations objects
    IF <org_obj>-obj_or = 'OR'.
      CHECK <org_obj>-userhas = 'X'.
    ENDIF.

    IF <org_obj>-obj_or = 'AND'.
      CHECK NOT <org_obj>-abb = '*'.
    ENDIF.

    lt_tcode_obj-tcode  = <org_obj>-tcode.
    lt_tcode_obj-object = <org_obj>-object.
    lt_tcode_obj-obj_or = <org_obj>-obj_or.
    INSERT TABLE lt_tcode_obj.

  ENDLOOP.
*--SF Case 3442 : count objects per tcode
  LOOP AT lt_tcode_obj WHERE obj_or = 'AND'.            "#EC CI_SORTSEQ
    lt_tcode_obj_count-obj_count = 1.
    lt_tcode_obj_count-tcode     = lt_tcode_obj-tcode.
    COLLECT lt_tcode_obj_count.
  ENDLOOP.

  DELETE ADJACENT DUPLICATES FROM lt_obj_org COMPARING ALL FIELDS.
*  DELETE lt_obj_org WHERE NOT userhas = 'X'.

*    SORT lt_obj_org BY funid tcode object ASCENDING userhas DESCENDING.

  LOOP AT it_unique_org_abb ASSIGNING <unique_org_abb>.
    CLEAR : l_tcode_count, l_tcode_found_count,l_prev_obj,l_prev_org.
    LOOP AT lt_obj_org ASSIGNING <org_obj> WHERE NOT abb = '*'.
      l_org_obj_tabix = sy-tabix.
      lt_tcode_obj_count-tcode = <org_obj>-tcode.
      AT NEW tcode.
        ADD 1 TO l_tcode_count.
        CLEAR l_tcode_found.
      ENDAT.
*--SF Case 3442 : get object count for tcode
      AT NEW object.
        READ TABLE lt_tcode_obj WITH KEY tcode = <org_obj>-tcode
                                     object = <org_obj>-object
                                     obj_or = 'OR'.
        IF sy-subrc = 0.
*--Only one object is required incase if all objects are joined with OR
*condition
          l_obj_count = l_obj_count + 1.
        ELSE.
          READ TABLE lt_tcode_obj_count
          WITH KEY tcode = lt_tcode_obj_count-tcode
          TRANSPORTING obj_count.
          l_obj_count = lt_tcode_obj_count-obj_count.
        ENDIF.
      ENDAT.

      IF  l_prev_obj <> <org_obj>-object.
        l_prev_obj = <org_obj>-object.
        CLEAR l_obj_found.
      ENDIF.

      IF  ( <org_obj>-abb = <unique_org_abb>-abb OR
            <org_obj>-abb = '*' )
          AND <org_obj>-userhas = 'X'.
        l_obj_found = 'X'.
      ENDIF.


      AT END OF object.
        IF l_obj_found = 'X'.
          ADD 1 TO l_obj_found_count.
        ENDIF.

*-- For OR object check found object and Expected object here only
*-- Means process one object at a time
*-- For AND We will look for all the objects at once
        IF <org_obj>-obj_or = 'OR'.
          IF l_obj_found_count = l_obj_count AND
             l_obj_count       > 0 .
            ADD 1 TO l_tcode_found_count.
          ENDIF.
          CLEAR : l_obj_found_count,
                  l_obj_count,
                 l_prev_obj.
        ENDIF.

      ENDAT.

*--check if all AND objects match org area
      AT END OF tcode.
        IF l_obj_found_count = l_obj_count AND
*--Case 2072 : 0 objects and 0 found = NO MATCH
           l_obj_count       > 0 .

          ADD 1 TO l_tcode_found_count.
        ENDIF.
        CLEAR : l_obj_found_count,
                l_obj_count,
* added 2017/04/18 - DHORIONS
                l_prev_obj.
      ENDAT.

    ENDLOOP.
    IF sy-subrc <> 0.
*--No org levels defined for any objects in functions we are analyzing
      CLEAR ls_confs_org.
*        ls_confs_org-conid = <confs>-conid.
      ls_confs_org-funid = i_funid.
      ls_confs_org-abb   = '*'.
*        ls_confs_org-abb   = '-'.
      ls_confs_org-agr_name = i_agr_name.
      INSERT ls_confs_org INTO TABLE it_confs_org.
    ENDIF.

*      IF l_tcode_found_count = l_tcode_count.
    IF l_tcode_found_count > 0 .

*--                This function has the ORG ABB we are looking for
**                add these org levels for the function
      CLEAR ls_confs_org.
*        ls_confs_org-conid = <confs>-conid.
      ls_confs_org-funid = i_funid.
      ls_confs_org-abb   = <unique_org_abb>-abb.
      ls_confs_org-agr_name = i_agr_name.
      INSERT ls_confs_org INTO TABLE it_confs_org.
    ELSE.
*--                This function does not have
*                the ORG ABB we are looking for
    ENDIF.
  ENDLOOP.
  IF sy-subrc <> 0 OR lt_tcode_obj_count[] IS INITIAL.
*--No org levels defined for any objects in functions we are analyzing
    CLEAR ls_confs_org.
    ls_confs_org-funid = i_funid.
    ls_confs_org-abb   = '*'.
    ls_confs_org-agr_name = i_agr_name.
    INSERT ls_confs_org INTO TABLE it_confs_org.
  ENDIF.


ENDFORM.                    " determine_org_area_for_func



*--
* 2020/02/24 - New version of determine org area
* better performance
*--

FORM determine_org_area_for_func_nw
USING
         i_funid TYPE /psyng/function_id
         i_agr_name TYPE agr_name
CHANGING
  it_org_obj         LIKE  g_org_obj[]
  it_unique_org_abb  LIKE g_swsodorgm[]
  it_confs_org       LIKE g_confs_org[].

  DATA : lt_and_objs TYPE SORTED TABLE OF type_org_obj
                     WITH UNIQUE KEY object
                     WITH HEADER LINE,
         lt_or_objs  TYPE SORTED TABLE OF type_org_obj
                     WITH UNIQUE KEY object
                     WITH HEADER LINE,
         lt_userhas_objs TYPE SORTED TABLE OF type_org_obj
                     WITH UNIQUE KEY abb object
                     WITH HEADER LINE,
         ls_confs_org TYPE type_confs_org,
         lf_userhas_all_and TYPE flag,
         lf_userhas_one_or  TYPE flag,
         lf_obj_with_star TYPE flag.
  FIELD-SYMBOLS :
    <unique_org_abb> TYPE    /psyng/swsodorgm,
    <org_obj>        TYPE    type_org_obj    .
*loop at it_confs1.
  READ TABLE it_org_obj WITH KEY funid = i_funid
    BINARY SEARCH TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    LOOP AT it_org_obj FROM sy-tabix ASSIGNING <org_obj>.
      IF NOT <org_obj>-funid = i_funid.
        EXIT.
      ENDIF.
      AT NEW tcode.
        REFRESH : lt_and_objs, lt_or_objs, lt_userhas_objs.
        CLEAR lf_obj_with_star.
      ENDAT.
      IF <org_obj>-obj_or = 'AND' AND NOT <org_obj>-abb = '*'.
        lt_and_objs-object = <org_obj>-object.
        INSERT TABLE lt_and_objs.
      ELSEIF NOT <org_obj>-abb = '*'.
        lt_or_objs-object = <org_obj>-object .
        INSERT TABLE lt_or_objs.
        lf_obj_with_star = 'X'.
      ENDIF.
      IF <org_obj>-userhas = 'X'.
        lt_userhas_objs-abb    = <org_obj>-abb.
        lt_userhas_objs-object = <org_obj>-object.
        INSERT TABLE lt_userhas_objs.
      ENDIF.
      AT END OF tcode.
        IF lt_and_objs[] IS INITIAL AND
           lt_or_objs[] IS INITIAL.
*--This is not Org Relevant
          CLEAR ls_confs_org.
*        ls_confs_org-conid = it_confs1-conid.
          ls_confs_org-funid = i_funid.
          ls_confs_org-abb   = '*'.
          ls_confs_org-agr_name = i_agr_name.
          INSERT ls_confs_org INTO TABLE it_confs_org.
        ELSE.
          LOOP AT it_unique_org_abb ASSIGNING <unique_org_abb>.
            CLEAR :  lf_userhas_all_and, lf_userhas_one_or.
*  --check if  user has all AND objects for tcode
            lf_userhas_all_and = 'X'.
            LOOP AT lt_and_objs.
              READ TABLE lt_userhas_objs WITH TABLE KEY
                  abb    = <unique_org_abb>-abb
                  object = lt_and_objs-object
                  TRANSPORTING NO FIELDS.
              IF sy-subrc <> 0.
                CLEAR lf_userhas_all_and.
                EXIT.
              ELSE.
                IF lf_obj_with_star = 'X'.
                  READ TABLE lt_userhas_objs WITH TABLE KEY
                      abb    = '*'
                      object = lt_or_objs-object
                      TRANSPORTING NO FIELDS.
                  IF sy-subrc = 0.
                    lf_userhas_one_or = 'X'.
                    EXIT.
                  ENDIF.
                ENDIF.
              ENDIF.
            ENDLOOP.
*  --check if  user has 1 or objects for tcode (if any exist)
            CLEAR lf_userhas_one_or.
            IF NOT lt_or_objs[] IS INITIAL.
              LOOP AT lt_or_objs.
                READ TABLE lt_userhas_objs WITH TABLE KEY
                    abb    = <unique_org_abb>-abb
                    object = lt_or_objs-object
                    TRANSPORTING NO FIELDS.
                IF sy-subrc = 0.
                  lf_userhas_one_or = 'X'.
                  EXIT.
                ENDIF.
              ENDLOOP.
            ELSE.
              lf_userhas_one_or = 'X'."there are no orgs, so irrelevant
            ENDIF.
            IF lf_userhas_one_or = 'X' AND lf_userhas_all_and = 'X'.
*  --the user has this ABB for this Tcode
              CLEAR ls_confs_org.
*          ls_confs_org-conid = it_confs1-conid.
              ls_confs_org-funid = i_funid.
              ls_confs_org-abb   = <unique_org_abb>-abb.
              ls_confs_org-agr_name = i_agr_name.
              INSERT ls_confs_org INTO TABLE it_confs_org.
            ENDIF.
          ENDLOOP.
        ENDIF.

      ENDAT.
    ENDLOOP.
  ELSE.
*--No org levels defined for any objects (with AND) in function
    CLEAR ls_confs_org.
*     ls_confs_org-conid = it_confs1-conid.
    ls_confs_org-funid = i_funid.
    ls_confs_org-abb   = '*'.
    ls_confs_org-agr_name = i_agr_name.
    INSERT ls_confs_org INTO TABLE it_confs_org.
  ENDIF.
*endloop.


ENDFORM.                    " determine_org_area_for_func_new


*&---------------------------------------------------------------------*
*&      Form  prevent_timeout
*&---------------------------------------------------------------------*
*       Prevent process from timing out
*----------------------------------------------------------------------*
*      -->P_L_ANALYSIS_COUNTER  text
*----------------------------------------------------------------------*
FORM prevent_timeout USING    i_counter.
  DATA : l_remain TYPE i.
  l_remain = i_counter MOD 750.
  IF l_remain = 0.
*--Prevent Process from timing out.
    CALL FUNCTION '/PSYNG/BASIS_GET_WPINFO'
         EXPORTING
              i_commit_pct = 20.
  ENDIF.
ENDFORM.                    " prevent_timeout
*&---------------------------------------------------------------------*
*&      Form  report_roles_without_conflict
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM report_roles_without_conflict.
  DATA : ls_out LIKE LINE OF gt_routput_sum,
         l_date(10) TYPE c.

  WRITE sy-datum TO l_date.
  ls_out-conid    = '----'.
  CONCATENATE
'No SOD issues based on SOD matrix defined in Security Weaver on '(077)
  l_date INTO
  ls_out-description SEPARATED BY space.
  CONCATENATE sy-sysid sy-mandt INTO ls_out-rfcdest.
  LOOP AT iagr_define.
    READ TABLE gt_routput_sum WITH KEY agr_name = iagr_define-agr_name
    TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      ls_out-agr_name = iagr_define-agr_name.

      APPEND ls_out TO gt_routput_sum.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " report_roles_without_conflict
*&---------------------------------------------------------------------*
*&      Form  load_mitigations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->ET_MCROLE    Role mitigations
*      -->ET_MCCAROLE  Critical auth role mitigations
*----------------------------------------------------------------------*
FORM load_mitigations TABLES   et_mcrole STRUCTURE /psyng/mcrole
                               et_mccarole STRUCTURE /psyng/mccarole
                     it_simu_roles STRUCTURE /psyng/sw_sod_remote_roles.

  DATA : lt_agr_define TYPE TABLE OF agr_define WITH HEADER LINE,
         ls_mcrole LIKE LINE OF et_mcrole,
         ls_mccarole TYPE /psyng/mccarole,
         ls_swconfig TYPE /psyng/swconfig,
         lt_mcrole TYPE TABLE OF /psyng/mcrole,
         lt_mccarole TYPE TABLE OF /psyng/mccarole.


*  CHECK NOT iagr_define[] IS INITIAL.
*--Get Roles that are mitigated
* Role mitigations are controlled by configuration
* parameter SW_MIT_BY_ROLE
* Possible values :
*  Blank (or 0, or parameter not set). Role Mitigations do not make a
*  difference in SOD Role or User reports. The software behaves as it
* behaved before. Even if values exist in /PSYNG/MCROLE, these are not
*  considered in the SOD User or Role Report.
*  1. Mitigations by Role apply to the SOD User Report only.
*  2. Mitigations by Role apply to the SOD Role Report only.
*  3. Mitigations by Role apply to SOD User and Role reports.
  CLEAR ls_swconfig.
  se_config_param 'SW_MIT_BY_ROLE' ls_swconfig-value.

  IF ls_swconfig-value EQ '2' OR ls_swconfig-value EQ '3'.
    MESSAGE s002 WITH 'Loading Mitigated Roles'.
    COMMIT WORK.


    SELECT *                                        "#EC CI_IMUD_NESTED
           FROM /psyng/mcrole
           INTO CORRESPONDING FIELDS OF TABLE et_mcrole
           WHERE vrsio     =  g_vrsio    AND
                 from_date LE sy-datum AND
                 to_date   GE sy-datum .

*--Also add derived roles as mitigated roles
    IF NOT et_mcrole[] IS INITIAL.
      SELECT agr_name parent_agr                    "#EC CI_IMUD_NESTED
        FROM agr_define
           INTO CORRESPONDING FIELDS OF TABLE lt_agr_define
           FOR ALL ENTRIES IN et_mcrole
           WHERE parent_agr =  et_mcrole-agr_name.

      LOOP AT lt_agr_define.
        LOOP AT et_mcrole WHERE
         agr_name = lt_agr_define-parent_agr.
          ls_mcrole = et_mcrole.
          ls_mcrole-agr_name = lt_agr_define-agr_name.
          APPEND ls_mcrole TO et_mcrole.
        ENDLOOP.
      ENDLOOP.

      LOOP AT et_mcrole.
        READ TABLE it_simu_roles WITH KEY agr_name = et_mcrole-agr_name.
        CHECK sy-subrc = 0.
        ls_mcrole = et_mcrole.
        ls_mcrole-agr_name = it_simu_roles-agr_name.
        APPEND ls_mcrole TO lt_mcrole.
      ENDLOOP.

      IF NOT lt_mcrole[] IS INITIAL.
        APPEND LINES OF lt_mcrole TO et_mcrole.
      ENDIF.

    ENDIF.

    SELECT * INTO TABLE et_mccarole FROM /psyng/mccarole
           WHERE vrsio     =  g_vrsio    AND
                 from_date LE sy-datum AND
                 to_date   GE sy-datum.             "#EC CI_IMUD_NESTED

*--Also add derived roles as mitigated roles
    CHECK NOT et_mccarole[] IS INITIAL.
    SELECT agr_name parent_agr                      "#EC CI_IMUD_NESTED
      FROM agr_define
         INTO CORRESPONDING FIELDS OF TABLE lt_agr_define
         FOR ALL ENTRIES IN et_mccarole
         WHERE parent_agr =  et_mccarole-agr_name.

    LOOP AT lt_agr_define.
      LOOP AT et_mccarole WHERE agr_name = lt_agr_define-parent_agr.
        ls_mccarole = et_mccarole.
        ls_mccarole-agr_name = lt_agr_define-agr_name.
        APPEND ls_mccarole TO et_mccarole.
      ENDLOOP.
    ENDLOOP.

    LOOP AT et_mccarole.
      READ TABLE it_simu_roles WITH KEY agr_name = et_mccarole-agr_name.
      CHECK sy-subrc = 0.
      ls_mccarole = et_mccarole.
      ls_mccarole-agr_name = lt_agr_define-agr_name.
      APPEND ls_mccarole TO lt_mccarole.
    ENDLOOP.

    IF NOT lt_mccarole[] IS INITIAL.
      APPEND LINES OF lt_mccarole TO et_mccarole.
    ENDIF.

  ENDIF.
ENDFORM.                    " load_mitigations
*&---------------------------------------------------------------------*
*&      Form  compare_func_with_auth_role
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM compare_func_with_auth_role.
  DATA : l_enh_tcode TYPE flag.
  DATA : BEGIN OF lt_enh_tcode_con OCCURS 0,
            agr_name TYPE agr_name,
            conid TYPE /psyng/conflict_id,
            funid TYPE /psyng/function_id,
            tcode TYPE tstc-tcode,
         END OF lt_enh_tcode_con.
  DATA : BEGIN OF ls_enh_simu_con ,
            agr_name TYPE agr_name,
            conid TYPE /psyng/conflict_id,
            funid TYPE /psyng/function_id,
            simu_agr TYPE agr_name,
         END OF ls_enh_simu_con,
         lt_enh_simu_con LIKE SORTED TABLE OF ls_enh_simu_con
         WITH UNIQUE KEY agr_name conid funid simu_agr WITH HEADER LINE,
         l_simu_subrc LIKE sy-subrc,
         l_analyzed_subrc LIKE sy-subrc.
*orgchk variables
  DATA :  lt_confs_org TYPE SORTED TABLE OF type_confs_org
          WITH UNIQUE KEY agr_name funid abb
          WITH HEADER LINE,
         ls_confs_org LIKE LINE OF lt_confs_org,
         ls_hit TYPE flag,
         lf_rolehas TYPE flag.
  DATA : lt_outputdet LIKE TABLE OF routdet WITH HEADER LINE.
  FIELD-SYMBOLS : <confs_org> LIKE ls_confs_org,
                  <confs> LIKE LINE OF confs1,
                  <sysauth> TYPE /psyng/swsodorgauth,
                  <rout> LIKE LINE OF routdet2.
  DATA : wa_systemauth TYPE /psyng/swsodorgauth.
  DATA : ls_out TYPE typ_routdet,
         ls_orgm TYPE /psyng/swsodorgm.
  DATA : lt_systemauths TYPE SORTED TABLE OF /psyng/swsodorgauth
         WITH NON-UNIQUE KEY object auth,
         ls_routput LIKE LINE OF gt_routput.
*end orgchk variables
  FIELD-SYMBOLS :
         <routdet>         LIKE routdet .

  DATA : ls_org_obj TYPE type_org_obj,
      lt_systemauths_tmp TYPE  TABLE OF /psyng/swsodorgauth,
      lt_systemauths_a TYPE SORTED TABLE OF /psyng/swsodorgauth
      WITH  NON-UNIQUE KEY rfcdest auth object abb ,
      lt_org_obj LIKE TABLE OF ls_org_obj WITH HEADER LINE,
      lt_unique_org_abb TYPE TABLE OF /psyng/swsodorgm WITH HEADER LINE,
      l_analysis_counter TYPE i.
  FIELD-SYMBOLS : <org_obj> LIKE ls_org_obj.
  lt_unique_org_abb[] = swsodorgm[].
  SORT lt_unique_org_abb BY abb.
  DELETE ADJACENT DUPLICATES FROM lt_unique_org_abb COMPARING abb.
  lt_systemauths_tmp[] = gt_systemauths[].
  SORT lt_systemauths_tmp BY rfcdest auth object abb.
  DELETE ADJACENT DUPLICATES FROM lt_systemauths_tmp
  COMPARING rfcdest auth object abb .
  lt_systemauths_a[] = lt_systemauths_tmp[].
  FREE : lt_systemauths_tmp.

  IF NOT g_org_check IS INITIAL.
    lt_systemauths = gt_systemauths[].
  ENDIF.


  functtran2[] = functtran[].
  SORT functtran2 BY tcode.
  lt_funcctran[] = functtran2[].
  functtran2[] = functtran[].

*end using a sorted table for funcctran
  itcdaut2[]   = itcdaut[].

  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
       EXPORTING
            percentage = 50
            text       = text-050.


  LOOP AT lt_funcctran ASSIGNING <functtran>.
    MOVE-CORRESPONDING <functtran> TO wa_ft.
    INSERT wa_ft INTO TABLE ft.
  ENDLOOP.   "functtran

  wa_tobjs1-userhas = 'Y'.
  SORT iagr_define BY agr_name.

  LOOP AT iagr_define ASSIGNING <iagr_define>.
*--prevent timeout.
    ADD 1 TO l_analysis_counter.
    PERFORM prevent_timeout USING l_analysis_counter.

    tobjs1[] = tobjs3[].
    PERFORM refresh_internal_tables.

    READ TABLE roletcode WITH KEY agr_name = <iagr_define>-agr_name
                                  BINARY SEARCH
                                  TRANSPORTING NO FIELDS.
    roletcode_idx = sy-tabix.
    LOOP AT roletcode FROM roletcode_idx
         ASSIGNING <roletcode>    WHERE
                                  agr_name = <iagr_define>-agr_name.

      roletcode_idx = sy-tabix.
*Is this tcode a result of the dynamict tcode enhancement?
      IF g_enh_fm = 'X'.
        READ TABLE gt_enh_tcodes WITH KEY
        calling_tcode = <roletcode>-tcode
        TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          l_enh_tcode = 'X'.
        ELSE.
          CLEAR l_enh_tcode.
        ENDIF.
      ENDIF.
      READ TABLE ft WITH KEY tcode = <roletcode>-tcode
                                               BINARY SEARCH
                                               TRANSPORTING NO FIELDS.
      ft_tabix = sy-tabix.
      LOOP AT ft FROM ft_tabix ASSIGNING <ft>
           WHERE tcode = <roletcode>-tcode.
**  BELOW: Conflict-function combination already found?
        READ TABLE routdet5 WITH KEY agr_name   = <iagr_define>-agr_name
                                     functionid = <ft>-functionid.

        l_analyzed_subrc = sy-subrc.
        IF g_bysimu = 'X'.
          READ TABLE lt_enh_simu_con
          WITH KEY agr_name = <iagr_define>-agr_name
                             funid = <ft>-functionid.
          l_simu_subrc = sy-subrc.
        ELSE.
          l_simu_subrc = 0.
        ENDIF.
**combination isn't already evaluated
**(or needs to be further evaluated because of org_check or enhanced
** ruleset or simulation)
        IF
           l_analyzed_subrc <> 0
        OR l_simu_subrc <> 0 "not yet determ. if funct. is due to
                             "simulation
        OR l_enh_tcode = 'X' "not yet determ. if funct. is due to
                             "ruleset enhancement
        OR g_org_check = 'X' "not yet determ. if funct. is due to
                             "ruleset enhancement
        .

          READ TABLE faobj WITH KEY funid = <ft>-functionid
                                    tcode = <roletcode>-tcode
                                    BINARY SEARCH
                                    TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.   "if no objects specified
            wa_routdet-agr_name    = <roletcode>-agr_name.
            wa_routdet-functionid  = <ft>-functionid.
            CONCATENATE sy-sysid sy-mandt INTO wa_routdet-rfcdest.
            INSERT wa_routdet INTO TABLE routdet5.
            CLEAR wa_routdet.
          ENDIF.
          IF l_enh_tcode = 'X'.
*--2014/06/11 DHORIONS - Check if tcode was not
*                        already part of the function
            READ TABLE gt_functran_no_enh WITH KEY
            functionid = <ft>-functionid
            tcode      = <roletcode>-tcode.
            IF sy-subrc <> 0.
              lt_enh_tcode_con-agr_name =  <roletcode>-agr_name.
              lt_enh_tcode_con-funid =  <ft>-functionid.
              lt_enh_tcode_con-tcode = <roletcode>-tcode.
              COLLECT lt_enh_tcode_con.
            ENDIF.
          ENDIF.

          READ TABLE simuagrs WITH KEY
          agr_name = <roletcode>-child_agr.
          IF sy-subrc = 0.
            ls_enh_simu_con-agr_name =  <roletcode>-agr_name.
            ls_enh_simu_con-funid =  <ft>-functionid.
            ls_enh_simu_con-simu_agr = <roletcode>-child_agr.
            COLLECT ls_enh_simu_con INTO lt_enh_simu_con.
          ENDIF.


          READ TABLE itcdaut WITH KEY rfcdest = <roletcode>-rfcdest
                                       funid  = <ft>-functionid
                                       tcode  = <roletcode>-tcode
                                       BINARY SEARCH
                                       TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            itcdaut_idx = sy-tabix.
            LOOP AT itcdaut FROM itcdaut_idx ASSIGNING <itcdaut>.
              IF NOT <itcdaut>-rfcdest = <roletcode>-rfcdest OR
                 NOT <itcdaut>-funid   = <ft>-functionid     OR
                 NOT <itcdaut>-tcode   = <roletcode>-tcode.
                EXIT.
              ENDIF.
              READ TABLE roleauth WITH TABLE KEY
                                      agr_name = <roletcode>-agr_name
                                      rfcdest  = <roletcode>-rfcdest
                                      objct    = <itcdaut>-objct
                                      auth     = <itcdaut>-auth
                                      TRANSPORTING objct simu child_agr
  .
              IF sy-subrc = 0.
                IF g_org_check = 'X'.
                  IF NOT <itcdaut>-objct = 'S_TCODE'.
                    ls_org_obj-funid  = <ft>-functionid.
                    ls_org_obj-tcode  = <roletcode>-tcode.
                    ls_org_obj-object = <itcdaut>-objct.
*                 Determine AND/OR relation
                    READ TABLE faobj WITH KEY
                      funid  = ls_org_obj-funid
                      tcode  = ls_org_obj-tcode
                      object = ls_org_obj-object
                      obj_or = 'OR'
                      TRANSPORTING NO FIELDS.
                    IF sy-subrc = 0.
                      ls_org_obj-obj_or = 'OR'.
                    ELSE.
                      ls_org_obj-obj_or = 'AND'.
                    ENDIF.
*                 Check if object is org area relevant
                    READ TABLE swsodorgm
                     INTO ls_orgm
                     WITH KEY
                       object = <itcdaut>-objct.
                    IF sy-subrc <> 0.
*                 NO : Consider object for all org areas
                      ls_org_obj-abb  ='*'.
                      ls_org_obj-userhas = 'X'.
                      APPEND ls_org_obj TO lt_org_obj.

                    ELSE.
*                 YES : Check which org areas user has
                      LOOP AT lt_unique_org_abb.
                        ls_org_obj-abb  = lt_unique_org_abb-abb.
                        READ TABLE lt_systemauths_a WITH TABLE KEY
                           rfcdest = <roletcode>-rfcdest
                           auth    = <itcdaut>-auth
                           object  = <itcdaut>-objct
                           abb     = ls_org_obj-abb
                           TRANSPORTING NO FIELDS.
                        IF sy-subrc = 0.
                          ls_org_obj-userhas = 'X'.
                        ELSE.
                          CLEAR ls_org_obj-userhas.
                        ENDIF.
                        APPEND ls_org_obj TO lt_org_obj.
                      ENDLOOP.
                    ENDIF.
                  ENDIF.
                ENDIF.
*  --DHORIONS 2018/02 Org Level Changes END


                wa_routdet-agr_name    = <roletcode>-agr_name.
                wa_routdet-functionid  = <ft>-functionid.
                CONCATENATE sy-sysid sy-mandt INTO wa_routdet-rfcdest.
                wa_routdet-simu        = roleauth-simu.
                wa_routdet-child_agr = roleauth-child_agr.
                INSERT wa_routdet INTO TABLE routdet5.
                CLEAR wa_routdet.

                READ TABLE simuagrs WITH KEY
                agr_name = <roletcode>-child_agr.
                IF sy-subrc = 0.
                  ls_enh_simu_con-agr_name =  <roletcode>-agr_name.
                  ls_enh_simu_con-funid =  <ft>-functionid.
                  ls_enh_simu_con-simu_agr = <roletcode>-child_agr.
                  COLLECT ls_enh_simu_con INTO lt_enh_simu_con.

                ENDIF.
                MODIFY tobjs1 FROM wa_tobjs1 TRANSPORTING
                       userhas WHERE
                                    funid  = <ft>-functionid AND
                                    tcode  = <roletcode>-tcode AND
                                    object = roleauth-objct.
              ENDIF.
            ENDLOOP.                       "ITCDAUT
          ENDIF.
          AT END OF functionid.
            CLEAR lf_rolehas.
            LOOP AT tobjs1 WHERE funid = <ft>-functionid AND
                                 tcode = <roletcode>-tcode AND
                                 obj_or NE 'OR' AND
                                 userhas <> 'Y'. "#EC SAST_CI_GEN_CHECK
              REFRESH routdet5.
              DELETE lt_enh_tcode_con WHERE
                                      agr_name = <roletcode>-agr_name
                                      AND   funid = <ft>-functionid.
              EXIT.
            ENDLOOP.
            IF sy-subrc <> 0.
              lf_rolehas = 'X'.
            ENDIF.
            READ TABLE tobjs1 WITH KEY funid = <ft>-functionid
                                 tcode = <roletcode>-tcode
                                 obj_or = 'OR'.
            IF sy-subrc = 0.
              READ TABLE tobjs1 WITH KEY funid = <ft>-functionid
                                   tcode = <roletcode>-tcode
                                   obj_or = 'OR'
                                   userhas = 'Y'.
              IF sy-subrc <> 0.
                CLEAR lf_rolehas.
                REFRESH routdet5.

              ENDIF.
            ENDIF.
            CHECK lf_rolehas = 'X'.
            LOOP AT routdet5.
              INSERT routdet5 INTO TABLE routdet.
            ENDLOOP.

            REFRESH routdet5.
            tobjs1[] = tobjs3[].
          ENDAT.
        ENDIF.
      ENDLOOP.  "FT
    ENDLOOP.  "roletcode
    AT END OF agr_name.
      IF NOT g_org_check IS INITIAL.
        SORT lt_org_obj.
        DELETE ADJACENT DUPLICATES FROM lt_org_obj.
        LOOP AT ft ASSIGNING <ft>.
          AT NEW functionid.
            PERFORM determine_org_area_for_func_nw
              USING
                <ft>-functionid
                <iagr_define>-agr_name
              CHANGING
                    lt_org_obj[]
                    lt_unique_org_abb[]
                    lt_confs_org[].
          ENDAT.
        ENDLOOP.
        REFRESH : lt_org_obj[].
        LOOP AT confs2.
        READ TABLE lt_confs_org WITH KEY
*BOC UMITTAL PN-18609 31/03/2026
*                                      agr_name = iagr_define-agr_name
                                      agr_name = <iagr_define>-agr_name
*EOC UMITTAL PN-18609 31/03/2026
                                            funid = confs2-functionid.
          IF sy-subrc <> 0.
*--No match for any org
            DELETE routdet WHERE
*BOC UMITTAL PN-18609 31/03/2026
*                   agr_name = iagr_define-agr_name
                   agr_name = <iagr_define>-agr_name
*EOC UMITTAL PN-18609 31/03/2026
            AND    functionid = confs2-functionid.
          ELSE.
*--Match for some orgs, delete the others
            LOOP AT lt_unique_org_abb.
              READ TABLE lt_confs_org WITH TABLE KEY
*BOC UMITTAL PN-18609 31/03/2026
*                      agr_name = iagr_define-agr_name
                      agr_name = <iagr_define>-agr_name
*EOC UMITTAL PN-18609 31/03/2026
                       funid    = confs2-functionid
                       abb      = lt_unique_org_abb-abb
              TRANSPORTING NO FIELDS.
              IF sy-subrc = 0.
                READ TABLE routdet
                WITH KEY
*BOC UMITTAL PN-18609 31/03/2026
*                      agr_name = iagr_define-agr_name
                      agr_name = <iagr_define>-agr_name
*EOC UMITTAL PN-18609 31/03/2026
                   conid      = ''
                   functionid = confs2-functionid.
                IF sy-subrc = 0.
                  IF routdet-org_abb IS INITIAL.
*--delete record wihout an org
                    DELETE routdet WHERE
*BOC UMITTAL PN-18609 31/03/2026
*                      agr_name = iagr_define-agr_name AND
                      agr_name = <iagr_define>-agr_name AND
*EOC UMITTAL PN-18609 31/03/2026
                      functionid = confs2-functionid AND
                      rfcdest    = routdet-rfcdest AND
                      org_abb    = ''.
                  ENDIF.
*--create new record for this org
                  routdet-org_abb = lt_unique_org_abb-abb.
                  INSERT  TABLE routdet.
                ENDIF.
              ENDIF.
            ENDLOOP.
          ENDIF.
        ENDLOOP.

      ENDIF.
    ENDAT.
  ENDLOOP.    "iagr_define.

  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
       EXPORTING
            percentage = 90
            text       = text-052.

  LOOP AT routdet ASSIGNING <rout>.
    MOVE-CORRESPONDING <rout> TO ls_routput.
    APPEND ls_routput TO gt_routput.
  ENDLOOP.
  gt_routput_sum[] = gt_routput[].
  FREE : routdet[].
  CLEAR ls_routput-functionid.
*-Mark the correct records as enhanced
  LOOP AT lt_enh_tcode_con.
    CLEAR wa_routdet.
    ls_routput-enhanced = 'X'.
    MODIFY  gt_routput FROM ls_routput
          TRANSPORTING enhanced
          WHERE
          agr_name  = lt_enh_tcode_con-agr_name AND
          functionid = lt_enh_tcode_con-funid.
    MODIFY  gt_routput_sum FROM ls_routput
    TRANSPORTING enhanced
          WHERE
          agr_name  = lt_enh_tcode_con-agr_name AND
          functionid = lt_enh_tcode_con-funid.
  ENDLOOP.
*-Mark the correct records as simulated
  LOOP AT lt_enh_simu_con INTO ls_enh_simu_con.
    CLEAR wa_routdet.
    ls_routput-simu = 'X'.
    ls_routput-child_agr = ls_enh_simu_con-simu_agr.
    MODIFY  gt_routput FROM ls_routput
          TRANSPORTING simu child_agr
          WHERE
          agr_name  = ls_enh_simu_con-agr_name AND
          conid     = ls_enh_simu_con-conid    AND
          functionid = ls_enh_simu_con-funid.
    MODIFY  gt_routput_sum FROM ls_routput
          TRANSPORTING simu child_agr
          WHERE
          agr_name  = ls_enh_simu_con-agr_name AND
          conid     = ls_enh_simu_con-conid.

  ENDLOOP.

ENDFORM.                    " compare_func_with_auth_role
*&---------------------------------------------------------------------*
*&      Form  report_roles_without_functions
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM report_roles_without_functions.
  DATA : ls_out LIKE LINE OF gt_routput_sum,
          l_date(10) TYPE c.

  WRITE sy-datum TO l_date.
  ls_out-functionid    = '----'.
  CONCATENATE
'No functions based on SOD matrix defined in Security Weaver on '(079)
  l_date INTO
  ls_out-description SEPARATED BY space.
  CONCATENATE sy-sysid sy-mandt INTO ls_out-rfcdest.
  LOOP AT iagr_define.
    READ TABLE gt_routput_sum WITH KEY agr_name = iagr_define-agr_name
    TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      ls_out-agr_name = iagr_define-agr_name.

      APPEND ls_out TO gt_routput_sum.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " report_roles_without_functions
*&---------------------------------------------------------------------*
*&      Form  fill_internal_tables_func
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_LOCAL_SOD  text
*      -->P_I_COMPOSITE_ROLES  text
*      -->P_I_SINGLE_ROLES  text
*      -->P_I_ASSIGNED_ROLES  text
*----------------------------------------------------------------------*
FORM fill_internal_tables_func
  TABLES
    it_ba              STRUCTURE /psyng/range_busarea_role
   USING
    i_local_sod_matrix TYPE flag
    i_comproles        TYPE flag
    i_singleroles      TYPE flag
    i_assignedroles    TYPE flag.
  DATA: lt_conflict   TYPE TABLE OF /psyng/conflict,
        lt_confdet    TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
        ls_agr_define TYPE agr_define,
        lt_agr_define TYPE TABLE OF agr_define WITH HEADER LINE,
        wa_agr_users TYPE agr_users,
       lt_ba_roles   TYPE TABLE OF /psyng/busarea_role WITH HEADER LINE.

*--Get SOD Matrix
  IF i_local_sod_matrix = 'X'.
    CALL FUNCTION '/PSYNG/SW_028'
      EXPORTING
        i_orgcheck         = g_org_check
        i_vrsio            = g_vrsio
        i_enhance          = g_enh_fm
        if_analysis        = 'X'
      TABLES
        it_spconfs         = gt_confs
        it_imp             = gt_sens
        it_risk            = gt_risk
*      it_org             = orglvl
        et_conflict        = lt_conflict
        et_confdet         = lt_confdet
        et_functtran       = functtran
        et_faobj           = faobj
        et_swsodorgm       = swsodorgm
        et_tcodes          = gt_enh_tcodes
        et_functran_no_enh = gt_functran_no_enh
        .

    conflict[] = lt_conflict[].
    confdet[]  = lt_confdet[].
    confs2[] = confdet[].


*   Remove rows with no object
    DELETE faobj WHERE object = space.
  ELSE.
*--tables filled in main FM

  ENDIF.
**--Get selected roles
  CALL FUNCTION '/PSYNG/BC_071'
   EXPORTING
     if_single                = i_singleroles
     if_composite             = i_comproles
     if_assigned              = i_assignedroles
     i_change_from_date       = g_rchdatf
     i_change_to_date         = g_rchdatt
   TABLES
     it_roles                 = gt_roles
     it_busarea               = it_ba
     et_busarea_role          = lt_ba_roles.
  REFRESH iagr_define.
  LOOP AT lt_ba_roles.
    ls_agr_define-agr_name = lt_ba_roles-agr_name.
    INSERT ls_agr_define INTO TABLE iagr_define.
  ENDLOOP.


**--Get selected roles
*  REFRESH iagr_define.
*  SELECT agr_name create_dat change_dat
*             INTO CORRESPONDING FIELDS OF ls_agr_define
*             FROM agr_define
*             WHERE agr_name IN gt_roles.
*    IF g_rchdatf IS INITIAL.   "role change date from
*      INSERT ls_agr_define INTO TABLE iagr_define.
*    ELSE.
*      IF ls_agr_define-change_dat IS INITIAL.
*        CHECK ls_agr_define-create_dat >= g_rchdatf AND
*              ls_agr_define-create_dat <= g_rchdatt.
*        INSERT ls_agr_define INTO TABLE iagr_define.
*      ELSE.
*        CHECK ls_agr_define-change_dat >= g_rchdatf AND
*              ls_agr_define-change_dat <= g_rchdatt.
*        INSERT ls_agr_define INTO TABLE iagr_define.
*      ENDIF.
*    ENDIF.
*  ENDSELECT.
*  CHECK NOT iagr_define[] IS INITIAL.
**** SE 3.1 Get & filter by assigned roles
*  IF i_assignedroles = 'X'.
*    LOOP AT iagr_define.
*** if role is assigned to one user it is assigned
*      SELECT SINGLE *  FROM agr_users INTO wa_agr_users
*      WHERE agr_name = iagr_define-agr_name
*      AND to_dat GE sy-datum
*      AND from_dat LE sy-datum.
*      IF sy-subrc NE 0.
*        APPEND iagr_define TO lt_agr_define.
*      ENDIF.
*    ENDLOOP.
*    LOOP AT lt_agr_define.
*      DELETE iagr_define WHERE agr_name = lt_agr_define-agr_name.
*    ENDLOOP.
*  ENDIF.
*
*
**-- filter by single and/or composite roles
*  IF i_comproles = 'X' AND i_singleroles = 'X'.
**--All roles, no filtering needed
*  ELSE.
*   DATA : lt_roleinfo TYPE TABLE OF /psyng/sw_roleinfo WITH HEADER LINE.
*    CONCATENATE sy-sysid sy-mandt INTO lt_roleinfo.
*    LOOP AT  iagr_define.
*      lt_roleinfo-agr_name = iagr_define-agr_name.
*      APPEND lt_roleinfo.
*    ENDLOOP.
*
*    CALL FUNCTION '/PSYNG/SW_ROLE_INFO'
**   EXPORTING
**     I_SPRAS        = 'EN'
*      TABLES
*        it_roles       = lt_roleinfo.
*    IF i_comproles IS INITIAL.
**--filter out composite roles
*      LOOP AT lt_roleinfo WHERE composite = 'X'.
*        DELETE iagr_define WHERE agr_name = lt_roleinfo-agr_name.
*      ENDLOOP.
*    ENDIF.
*    IF i_singleroles IS INITIAL.
**--filter out single roles
*      LOOP AT lt_roleinfo WHERE composite <> 'X'.
*        DELETE iagr_define WHERE agr_name = lt_roleinfo-agr_name.
*      ENDLOOP.
*    ENDIF.
*
*  ENDIF.
ENDFORM.                    " fill_internal_tables_func
*&---------------------------------------------------------------------*
*&      Form  get_org_auth_simu_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_org_auth_simu_roles
  TABLES
    it_roleauth      STRUCTURE /psyng/roleauth
    it_advanced_simu STRUCTURE agr_1251.
  DATA : lf_match TYPE flag,
         ls_systemauth LIKE LINE OF  gt_systemauths,
         lt_roleauth TYPE TABLE OF /psyng/roleauth WITH HEADER LINE.
DATA: lt_simu_auth  TYPE TABLE OF agr_1251, "WITH NON-UNIQUE KEY object field,  "HBHALLA
ls_simu_auth  TYPE  agr_1251,                                               "HBHALLA
lt_systemauths_local  TYPE TABLE OF /psyng/swsodorgauth,                    "HBHALLA
*      WITH NON-UNIQUE KEY auth,
ls_systemauths_local  LIKE LINE OF lt_systemauths_local.                    "HBHALLA
  CHECK NOT swsodorgm[] IS INITIAL.

  APPEND LINES OF  it_roleauth TO lt_roleauth.
  CONCATENATE sy-sysid sy-mandt INTO lt_roleauth-rfcdest.
  LOOP AT it_advanced_simu.
    MOVE-CORRESPONDING it_advanced_simu TO lt_roleauth.
    lt_roleauth-objct = it_advanced_simu-object.
    lt_roleauth-von   = it_advanced_simu-low.
    lt_roleauth-bis   = it_advanced_simu-high.
    APPEND lt_roleauth.
  ENDLOOP.
  LOOP AT lt_roleauth.
*--remove the original org areas from the advanced roles from before the advanced simulation
    DELETE gt_systemauths WHERE auth   = lt_roleauth-auth AND
                                object = lt_roleauth-objct.
  ENDLOOP.

  LOOP AT lt_roleauth.                                 "BOC HBHALLA
    ls_simu_auth-agr_name = lt_roleauth-agr_name.
    ls_simu_auth-object   = lt_roleauth-objct   .
    ls_simu_auth-auth     = lt_roleauth-auth    .
    ls_simu_auth-field    = lt_roleauth-field   .
    ls_simu_auth-low      = lt_roleauth-von     .
    ls_simu_auth-high     = lt_roleauth-bis     .
    APPEND ls_simu_auth TO lt_simu_auth.
    CLEAR ls_simu_auth.
  ENDLOOP.

  IF lt_simu_auth[] IS NOT INITIAL.
    CALL FUNCTION '/PSYNG/SW_024'
     EXPORTING
       i_fielddetails       = 'X'
      TABLES
        swsodorgm            =   swsodorgm
        uniqueauths          =   uniqueauths
        systemauths          =   lt_systemauths_local
        it_simu_auths        =   lt_simu_auth.
    SORT lt_systemauths_local.
    DELETE ADJACENT DUPLICATES FROM lt_systemauths_local
    COMPARING ALL FIELDS.
SORT lt_systemauths_local BY auth.                                     "HBHALLA bug prevent
INSERT LINES OF lt_systemauths_local INTO TABLE gt_systemauths.              "HBHALLA bug prevent
*  LOOP AT lt_systemauths_local INTO ls_systemauths_local.
*  APPEND ls_systemauths_local TO gt_systemauths.
*  CLEAR ls_systemauths_local.
*  ENDLOOP.
    FREE lt_systemauths_local.
  ENDIF.

*END OF CHANGE


***  LOOP AT lt_roleauth.                                       "Start of commenting: HBHALLA
****--parse the simulated fields and add them
***    LOOP AT  swsodorgm WHERE object  = lt_roleauth-objct AND
***                             varbl   = lt_roleauth-field.
***      IF lt_roleauth-von IS INITIAL
***      OR lt_roleauth-von EQ `'`.
***         lt_roleauth-von = `' '`.
***      ENDIF.
***      CALL FUNCTION '/PSYNG/SW_021'
***           EXPORTING
***                auth_from = lt_roleauth-von
***                auth_to   = lt_roleauth-bis
***                sod_from  = swsodorgm-low
***                sod_to    = swsodorgm-high
***           IMPORTING
***                match     = lf_match.
***      IF lf_match = 'X'.
***        ls_systemauth-abb     = swsodorgm-abb.
***        ls_systemauth-object  = swsodorgm-object.
***        ls_systemauth-auth    = lt_roleauth-auth.
***        ls_systemauth-rfcdest = lt_roleauth-rfcdest.
***        ls_systemauth-varbl   = swsodorgm-varbl.
***        ls_systemauth-low     = swsodorgm-low.
***        ls_systemauth-high    = swsodorgm-high.
***        INSERT ls_systemauth INTO TABLE gt_systemauths.
***      ENDIF.
***    ENDLOOP.
***  ENDLOOP.                                                     "End of commenting: HBHALLA

ENDFORM.                    " get_org_auth_simu_roles
*&---------------------------------------------------------------------*
*&      Form  org_override
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CONFDET  text
*      -->P_FUNCTTRAN  text
*      -->P_FAOBJ  text
*      -->P_LT_RFCDES  text
*      -->P_GT_ROUTPUT_SUM  text
*      -->P_I_VRSIO  text
*      -->P_I_CONFIG_SET  text
*      -->P_I_ORG_CHECK  text
*      -->P_SWSODORGM  text
*----------------------------------------------------------------------*
FORM org_override
TABLES
 it_functtran           STRUCTURE /psyng/functtran
 it_faobj               STRUCTURE /psyng/faobj2
 et_routput_sum         STRUCTURE /psyng/sw_out_routput
 it_swsodorgm           STRUCTURE /psyng/swsodorgm
 it_advanced_role_simu  STRUCTURE	agr_1251
 it_simu_role_removal   STRUCTURE	/psyng/sw_role_removal_simu
 it_simurole_auth    STRUCTURE  /psyng/roleauth
 it_simurole_tcode     STRUCTURE  /psyng/roletcode
USING
  i_vrsio        TYPE /psyng/sodvrsio
  i_config_set TYPE /psyng/seconfid
  i_org_check  TYPE flag.
  DATA : lf_enabled     TYPE flag,
          lt_swsodorgo  TYPE TABLE OF /psyng/swsodorgo
                        WITH HEADER LINE,
          lt_conflicts  TYPE TABLE OF /psyng/sw_out_routput
                        WITH HEADER LINE,
          ls_conflict   TYPE /psyng/sw_out_routput,
          lt_invalid    TYPE TABLE OF /psyng/sw_out_routput
                        WITH HEADER LINE,
          lt_rfcdest    TYPE TABLE OF rfcdes WITH HEADER LINE,
          lt_org        TYPE /psyng/sw_tab_sys_ao,
          ls_org        TYPE /psyng/sw_sys_ao,
          lt_confdet    TYPE TABLE OF /psyng/confdet.
  CHECK i_org_check = 'X'."only if org check is active
  se_config_param 'ORG_LVL_OVERRIDE' lf_enabled.
  CHECK lf_enabled = 'Y' OR
        lf_enabled = 'X'. "is override functionality enabled
  SELECT * FROM /psyng/swsodorgo INTO TABLE lt_swsodorgo
                WHERE vrsio = i_vrsio.
  CHECK NOT lt_swsodorgo[] IS INITIAL.
  SORT et_routput_sum BY conid.
  CONCATENATE sy-sysid sy-mandt INTO lt_rfcdest-rfcoptions .
  lt_rfcdest-rfcdest = 'LOCAL'.
  APPEND lt_rfcdest.
  ls_org-rfcdest = lt_rfcdest-rfcoptions.
  ls_org-swsodorgm = it_swsodorgm[].
  APPEND ls_org TO  lt_org.
  lt_confdet[] = confdet[].
  LOOP AT lt_swsodorgo.
    REFRESH : lt_conflicts, lt_invalid .
    READ TABLE et_routput_sum WITH KEY conid = lt_swsodorgo-conid
    BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      ls_conflict-conid = lt_swsodorgo-conid.
      LOOP AT et_routput_sum FROM sy-tabix.
        IF et_routput_sum-conid <> lt_swsodorgo-conid.
          EXIT.
        ENDIF.
        APPEND et_routput_sum TO lt_conflicts.
      ENDLOOP.
*--Call FM to reanalyze
      CALL FUNCTION '/PSYNG/SW_127'
       EXPORTING
         if_summary         = 'X'
         it_swsodorgm       = lt_org
         i_sodvrsio         = i_vrsio
         i_org_check        = i_org_check
         i_cfgset           = i_config_set
         is_outputdet       = ls_conflict
* IMPORTING
*   EF_VALID           =
       TABLES
         it_rfcdes             = lt_rfcdest
         it_faobj              = it_faobj
         it_confdet            = lt_confdet
         it_functtran          = it_functtran
         it_outputdet          = lt_conflicts
         it_advanced_role_simu = 	it_advanced_role_simu
         it_simu_role_removal  = it_simu_role_removal
         it_simurole_auth      = it_simurole_auth
         it_simurole_tcode      = it_simurole_tcode
         et_invalid            = lt_invalid
                .

*--Delete false positives
      LOOP AT lt_invalid.
        DELETE et_routput_sum WHERE conid    = lt_invalid-conid AND
                                    agr_name = lt_invalid-agr_name.
      ENDLOOP.


    ENDIF.
  ENDLOOP.

ENDFORM.                    " org_override
