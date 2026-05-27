*----------------------------------------------------------------------*
* Function Module       : /PSYNG/SW_GET_MATRIX_AUTHS
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS: Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_get_matrix_auths.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(REM_EXECUTION) TYPE  CHAR01 OPTIONAL
*"     REFERENCE(RFCDEST) LIKE  RFCDES-RFCDEST OPTIONAL
*"     REFERENCE(I_ADVANCED_ROLE_SIMU) TYPE  FLAG DEFAULT ' '
*"  TABLES
*"      TCD STRUCTURE  /PSYNG/PSSWTCD
*"      FAOBJ STRUCTURE  /PSYNG/FAOBJ2
*"      FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN
*"      TCDAUT STRUCTURE  /PSYNG/PSSWTCDAUT OPTIONAL
*"      UNIQUEAUTHS STRUCTURE  /PSYNG/UNIQUEAUTHS OPTIONAL
*"      IT_ADVANCED_ROLE_SIMU STRUCTURE  AGR_1251 OPTIONAL
*"      IT_SIMU_ADD_ROLEAUTH STRUCTURE  /PSYNG/USERAUTH OPTIONAL
*"      ET_MATCH_USER_OUT STRUCTURE  /PSYNG/MATCH_USR OPTIONAL
*"----------------------------------------------------------------------
* This function module is a replacement for
* /PSYNG/SW_GET_TCODE_AUTH_DATA
* It optimizes performance and memory usage
* SE release 4.0
*"----------------------------------------------------------------------
  DATA : lt_uniqueauths TYPE TABLE OF /psyng/uniqueauths,
         lt_uniqueauths_part TYPE TABLE OF /psyng/uniqueauths,
         l_max_auths TYPE i VALUE '50000',
         l_auths TYPE i,
         lf_simu_added TYPE flag.
*BOC UMITTAL 08 Jan 2025 : Define AND relation between VALUESETS
  DATA : gt_match_auth_in  TYPE STANDARD TABLE OF
                  typ_matching_auths,
         gt_match_auth_out TYPE STANDARD TABLE OF
                  typ_matching_auths,
         gt_match_user_auth TYPE STANDARD TABLE OF
                  /psyng/match_usr WITH HEADER LINE,
         gt_faobj_temp     TYPE STANDARD TABLE OF
                  /psyng/faobj2.
*EOC UMITTAL 08 Jan 2025 : Define AND relation between VALUESETS

  DESCRIBE TABLE uniqueauths LINES l_auths.
  IF l_auths > 0.
    MESSAGE s002 WITH 'Analyzing' l_auths 'unique authorizations' ''.
    COMMIT WORK.
  ENDIF.
*--Clear all global tables in this function group
  PERFORM clear_global_data.

  DATA : l_dest      LIKE rfcdes-rfcdest  .
  IF rem_execution <> space.
    CHECK rfcdest <> space.
    l_dest = rfcdest.
  ELSE.
    CONCATENATE sy-sysid sy-mandt INTO l_dest.
  ENDIF.
  SORT: faobj, tcd.
  DELETE ADJACENT DUPLICATES FROM tcd COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM faobj COMPARING
  funid tcode object valueset field val_from val_to.
  gt_tcd[]   = tcd[].
  gt_faobj[] = faobj[].



*--Get the authorization content
  lt_uniqueauths[] = uniqueauths[].
  WHILE NOT lt_uniqueauths[] IS INITIAL OR NOT gt_ust12[] IS INITIAL.
    REFRESH : lt_uniqueauths_part.
    APPEND LINES OF lt_uniqueauths FROM 1 TO l_max_auths
    TO lt_uniqueauths_part .
    DELETE lt_uniqueauths FROM 1 TO l_max_auths.
    IF NOT lt_uniqueauths_part[] IS INITIAL.
      SELECT objct field auth von bis FROM ust12
             APPENDING TABLE gt_ust12
             FOR ALL ENTRIES IN lt_uniqueauths_part
             WHERE objct = lt_uniqueauths_part-objct  AND
                   auth  = lt_uniqueauths_part-auth   AND
                   aktps = 'A'.
    ENDIF.
    IF lf_simu_added <> 'X'.
*--Simulation data will be added to the first batch of auths
*  that is analyzed
*--Add authorizations for Adding Roles Simulation
      LOOP AT it_simu_add_roleauth.
        gt_ust12-objct = it_simu_add_roleauth-objct.
        gt_ust12-auth  = it_simu_add_roleauth-auth.
        gt_ust12-field = it_simu_add_roleauth-field.
        gt_ust12-von   = it_simu_add_roleauth-von.
        gt_ust12-bis   = it_simu_add_roleauth-bis.
        INSERT TABLE gt_ust12.
      ENDLOOP.
*--Add Authorizations for advanced role simulation
      IF i_advanced_role_simu  = 'X'.
        LOOP AT it_advanced_role_simu.
          AT NEW auth.
            DELETE gt_ust12 WHERE auth = it_advanced_role_simu-auth.
          ENDAT.
        ENDLOOP.
        LOOP AT it_advanced_role_simu.
          gt_ust12-objct = it_advanced_role_simu-object.
          gt_ust12-auth  = it_advanced_role_simu-auth.
          gt_ust12-field = it_advanced_role_simu-field.
          gt_ust12-von   = it_advanced_role_simu-low.
          gt_ust12-bis   = it_advanced_role_simu-high.
          INSERT TABLE gt_ust12.
        ENDLOOP.
      ENDIF.
      lf_simu_added = 'X'.
    ENDIF.


*--Filter the authorizations that are in scope
* based on tcodes and objects.
    PERFORM get_in_scope_tcd_obj_auth
      TABLES functtran
       USING l_dest.
    COMMIT WORK.
*--Get the authorizations that match the SOD Matrix defined values
    PERFORM get_auths_for_in_scope_tcodes.
*BOC UMITTAL 08 Jan 2025 :
    DATA : lv_valueset_and_flag  TYPE flag,
            ls_vrs_and TYPE /psyng/vrs_and,
            ls_faobj_match TYPE /psyng/faobj2.
    CLEAR lv_valueset_and_flag.
*determining the relation between Valuesets
    IF NOT gt_faobj_match[] IS INITIAL.
      READ TABLE gt_faobj_match INTO ls_faobj_match INDEX 1.
      SELECT SINGLE *
        FROM /psyng/vrs_and
        INTO  ls_vrs_and
         WHERE vrsio EQ ls_faobj_match-vrsio AND
               valueset_and EQ 'X'.
      IF sy-subrc EQ 0.
        lv_valueset_and_flag = 'X' .
      ELSE.
        CLEAR lv_valueset_and_flag.
      ENDIF.
    ENDIF.

*--> 1) Define AND relation between VALUESETS
*--> 2) Check AND relation between Valuesets for all users
    gt_faobj_temp[]    = gt_faobj_match[].
    gt_match_auth_in[] = gt_matches[].
    IF lv_valueset_and_flag EQ 'X'.
      CALL FUNCTION '/PSYNG/SW_GET_VALUESET_AND'
       EXPORTING
         it_match_auth_in   = gt_match_auth_in[]
         it_faobj           = gt_faobj_temp[]
       IMPORTING
         et_match_auth_out  = gt_match_auth_out[]
         et_match_user_out  = gt_match_user_auth[].

      gt_matches[]        = gt_match_auth_out[].
*    et_match_user_out[] = gt_match_user_auth[].

*--Return data

      LOOP AT gt_match_user_auth.

        MOVE-CORRESPONDING gt_match_user_auth TO et_match_user_out.
        et_match_user_out-rfcdest = l_dest.
        APPEND et_match_user_out.
      ENDLOOP.

      FREE : gt_match_auth_out.
    ENDIF.
*EOC UMITTAL 08 Jan 2025 : Define AND relation between VALUESETS

*--Clear the tables that were loaded inside this loop
    FREE :
      gt_ust12,
      gt_matching_auths,
      gt_no_field_match,
      gt_faobj_match.
    SORT gt_matches.
*--Return data
    tcdaut-rfcdest = l_dest.
    LOOP AT gt_matches.
      MOVE-CORRESPONDING gt_matches TO tcdaut.
      APPEND tcdaut.
    ENDLOOP.
    FREE :gt_matches .
    COMMIT WORK.
  ENDWHILE.
*--Clear all global tables in this function group
  PERFORM clear_global_data.

ENDFUNCTION.
