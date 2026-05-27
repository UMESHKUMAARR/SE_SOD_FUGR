FUNCTION /psyng/sw_abac_access_verify.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_USER) TYPE  XUBNAME
*"     VALUE(IT_SYSTEMAUTHS) TYPE  /PSYNG/SWSODORGAUTH_TT
*"     VALUE(I_RFC) TYPE  RFCDEST
*"     VALUE(I_USER_AUTH) TYPE  XUAUTH
*"     VALUE(I_USER_AUTH_OBJ) TYPE  XUOBJECT
*"     VALUE(I_ORG_OBJ_ABB) TYPE  /PSYNG/DORG_ABB
*"  TABLES
*"      ET_SYSTEMAUTHS_MATCH STRUCTURE  /PSYNG/SWSODORGAUTH OPTIONAL
*"  CHANGING
*"     REFERENCE(I_ORG_OBJ_USERHAS) TYPE  FLAG
*"----------------------------------------------------------------------

  DATA: lt_user_id         TYPE /psyng/bc_user_tt,
        ls_user_id         TYPE /psyng/bnames,
        lt_org_elem_values TYPE /psyng/bc_user_org_ele_tt,
        ls_org_elem_values TYPE /psyng/bc_user_org_ele_s,
        lt_compare         TYPE TABLE OF /psyng/auth_compare,
        pair               TYPE /psyng/auth_compare,
        lv_loopidx         TYPE sy-tabix,
        ls_abacrange       TYPE /psyng/auth_field_value_range,
        lf_exit            TYPE flag,
        lt_systemauths_a1  TYPE TABLE OF /psyng/swsodorgauth,
        lt_systemauths_a2  TYPE TABLE OF /psyng/swsodorgauth,
        lt_systemauths_match  TYPE TABLE OF /psyng/swsodorgauth,
        ls_systemauths  TYPE /psyng/swsodorgauth,
        lv_se_oe_cnt       TYPE i,
        lv_abac_oe_cnt     TYPE i,
        lv_tabix TYPE i,
        lv_lines TYPE i,
        lv_index1 TYPE i,
        lv_index2 TYPE i,
        lv_varbl            type tprorgvar.

  FIELD-SYMBOLS: <pair>     TYPE /psyng/auth_compare,
                 <org_auth> TYPE /psyng/swsodorgauth.


  CONSTANTS: c_fname TYPE rs38l_fnam VALUE '/APPSDM/RFC_ORG_ELE_VALUES'.


  REFRESH: lt_user_id, lt_org_elem_values, lt_systemauths_match.

  lt_systemauths_a1 = it_systemauths.

*Reading org area access maintained in ABAC for user
  ls_user_id-bname = i_user.
  APPEND ls_user_id TO lt_user_id.
  CLEAR ls_user_id.

*Existance check of ABAC API
  CALL FUNCTION '/PSYNG/BC_FUNCTION_EXISTS'
        EXPORTING
          funcname           = c_fname
        EXCEPTIONS
          function_not_exist = 1
          OTHERS             = 2.
  IF sy-subrc = 0.
    CALL FUNCTION c_fname
      EXPORTING
        it_user_id         = lt_user_id
      IMPORTING
        et_org_elem_values = lt_org_elem_values.

    LOOP AT lt_systemauths_a1 ASSIGNING <org_auth> WHERE
                     rfcdest = i_rfc AND
                     auth    = i_user_auth AND
                     object  = i_user_auth_obj AND
                     abb     = i_org_obj_abb.

      refresh lt_systemauths_a2.

      lv_varbl = <org_auth>-varbl.

      lv_tabix = sy-tabix.
      APPEND <org_auth> TO lt_systemauths_a2.
      ADD 1 TO lv_tabix.

*Collecting all records with same org element
      LOOP AT lt_systemauths_a1 INTO ls_systemauths FROM lv_tabix
                                     WHERE rfcdest = i_rfc AND
                                           auth    = i_user_auth AND
                                           object  = i_user_auth_obj AND
                                           abb     = i_org_obj_abb AND
                                           varbl   = <org_auth>-varbl.

        APPEND ls_systemauths TO lt_systemauths_a2.
        CLEAR ls_systemauths.
      ENDLOOP.

      SUBTRACT 1 FROM lv_tabix.
      DESCRIBE TABLE lt_systemauths_a2 LINES lv_lines.

*Deleting records from where values are already fetched
      IF lv_lines EQ 1.
        DELETE lt_systemauths_a1 INDEX lv_tabix.
      ELSE.
        lv_index1 = lv_tabix.
        lv_index2 = lv_tabix + lv_lines - 1.
        DELETE lt_systemauths_a1 FROM lv_index1 TO lv_index2.
      ENDIF.

*Preparing comparison table for org element values

      REFRESH lt_compare.
      LOOP AT lt_systemauths_a2 INTO ls_systemauths.
        pair-auth_from  = ls_systemauths-low.
        pair-auth_to    = ls_systemauths-high.
        pair-auth       = i_user_auth.
        TRANSLATE pair-auth_from   TO UPPER CASE.
        TRANSLATE pair-auth_to     TO UPPER CASE.

        READ TABLE lt_org_elem_values INTO ls_org_elem_values WITH KEY
                                     org_element = ls_systemauths-varbl.
        IF sy-subrc = 0.

          LOOP AT ls_org_elem_values-range INTO ls_abacrange.
            pair-sod_from   = ls_abacrange-low.
            pair-sod_to     = ls_abacrange-high.
            TRANSLATE pair-sod_from    TO UPPER CASE.
            TRANSLATE pair-sod_to      TO UPPER CASE.
            APPEND pair TO lt_compare.
          ENDLOOP.
        ENDIF.
      ENDLOOP.

*lt compare would be initial if no values for org element in ABAC
      IF lt_compare IS NOT INITIAL.
        CALL FUNCTION '/PSYNG/SW_COMPARE_RANGES'
          EXPORTING
            i_buffer_size = 50000
          TABLES
            it_compare    = lt_compare.

        loop at lt_compare assigning <pair>.
          if <pair>-sod_from = '*' or <pair>-sod_to = '*'.
            <pair>-match = 'X'.
          endif.
        endloop.

      READ TABLE lt_compare WITH KEY match = 'X' TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          i_org_obj_userhas = 'X'.
          loop at lt_compare into pair where match = 'X'.
            ls_systemauths-rfcdest = i_rfc.
            ls_systemauths-auth = i_user_auth.
            ls_systemauths-object = i_user_auth_obj.
            ls_systemauths-abb = i_org_obj_abb.
            ls_systemauths-varbl = lv_varbl.
            ls_systemauths-low = pair-auth_from.
            ls_systemauths-high = pair-auth_to.
            append ls_systemauths to lt_systemauths_match.
            clear ls_systemauths.
          endloop.
        ELSE.
          lf_exit = 'X'.
        ENDIF.

        IF lf_exit EQ 'X'.
          CLEAR i_org_obj_userhas.
          refresh lt_systemauths_match.
          EXIT.
        ENDIF.
      ELSE.
        i_org_obj_userhas = 'X'.
        append lines of lt_systemauths_a2 to lt_systemauths_match.
      ENDIF.
    ENDLOOP.
  ELSE.
    i_org_obj_userhas = 'X'.
  ENDIF.

  APPEND LINES OF lt_systemauths_match to et_systemauths_match.

ENDFUNCTION.
