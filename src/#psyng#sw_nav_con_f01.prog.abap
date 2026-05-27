*&---------------------------------------------------------------------*
*&      Form  VALIDATE_FIELD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM validate_field .
  DATA : lv_conid TYPE /psyng/confdet-conid,
         ls_config TYPE /psyng/swconfig,
         lv_vrsio TYPE /psyng/confdet-vrsio.
  IF p_vrsio IS INITIAL.
*BOC UMITTAL SE-CAC Integration 17/02/2026
    CLEAR  ls_config-value.
    se_config_param 'DFLT_GLOBAL_VERSION' ls_config-value.
    p_vrsio = ls_config-value.
    IF p_vrsio IS INITIAL.
*    p_vrsio = lv_vrsio.
      MESSAGE 'Enter Version as there is no default vrs.' TYPE 'E'.
*    DISPLAY LIKE 'E'.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.
  IF p_conid IS INITIAL.
    MESSAGE 'Enter Conflict ID' TYPE 'E' .
*    DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.



  IF p_conid IS NOT INITIAL AND p_vrsio IS NOT INITIAL.
    SELECT SINGLE conid INTO lv_conid FROM /psyng/confdet
      WHERE conid = p_conid
        AND vrsio = p_vrsio.
    IF sy-subrc NE 0.
      MESSAGE 'Conflict does not exist' TYPE 'E'.
*        DISPLAY LIKE 'E'.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SET_DEFAULT_SODVERSION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_VRSIO  text
*      -->P_L_UNAME  text
*      -->P_0      text
*----------------------------------------------------------------------*
FORM set_default_sodversion USING l_sod TYPE /psyng/swsodvers-vrsio
                                  l_uname TYPE sy-uname
                                  l_delete TYPE sy-subrc.
  DATA: lt_param  TYPE TABLE OF bapiparam WITH HEADER LINE,
          lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE,
          ls_paramx TYPE bapiparamx.


  SELECT parid parva INTO TABLE lt_param
    FROM usr05                                       "#EC CI_SEL_NESTED
         WHERE bname = l_uname.
                                                          "#EC CI_SUBRC

  READ TABLE lt_param WITH KEY parid = '/PSYNG/VRSIO'.
  lt_param-parva = l_sod.

  IF sy-subrc = 0.
    MODIFY lt_param INDEX sy-tabix.
  ELSE.
    lt_param-parid = '/PSYNG/VRSIO'.
    APPEND lt_param.
  ENDIF.
  IF l_delete <> 0.
    DELETE lt_param WHERE parid = '/PSYNG/VRSIO'.
  ENDIF.

  ls_paramx-parid = 'X'.
  ls_paramx-parva = 'X'.
  CALL FUNCTION 'BAPI_USER_CHANGE'     "#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
      username   = l_uname
      parameterx = ls_paramx
    TABLES
      parameter  = lt_param
      return     = lt_return.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SEARCH_HELP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM search_help .
  "------------------------------------------------------------
  "1) Read current screen value of P_VRSIO
  "------------------------------------------------------------


  TYPES: BEGIN OF lty_f4,
           vrsio TYPE /psyng/confdet-vrsio,
           conid TYPE /psyng/confdet-conid,
         END OF lty_f4.

  DATA: lt_f4      TYPE STANDARD TABLE OF lty_f4 ,
        ls_f4      TYPE lty_f4,
        lt_conids  TYPE STANDARD TABLE OF lty_f4,
        ls_conids  TYPE lty_f4,
        lt_return  TYPE TABLE OF ddshretval,
        ls_return  TYPE ddshretval.
  DATA: lt_dynp TYPE TABLE OF dynpread,
        ls_dynp TYPE dynpread,
        lv_vrsio TYPE /psyng/confdet-vrsio.
  CLEAR lt_dynp.
  ls_dynp-fieldname = 'P_VRSIO'.
  APPEND ls_dynp TO lt_dynp.
  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname     = sy-repid
      dynumb     = sy-dynnr
      translate_to_upper = abap_true
    TABLES
      dynpfields = lt_dynp
    EXCEPTIONS
      invalid_abapworkarea = 1
      invalid_dynprofield  = 2
      invalid_dynproname   = 3
      invalid_dynpronummer = 4
      invalid_request      = 5
      no_fielddescription  = 6
      invalid_parameter    = 7
      undefind_error       = 8
      double_conversion    = 9
      stepl_not_found      = 10
      OTHERS               = 11.
  IF sy-subrc <> 0.
    MESSAGE 'An Exception occurred'(001) TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ELSE.

    READ TABLE lt_dynp INTO ls_dynp WITH KEY fieldname = 'P_VRSIO'.
    IF sy-subrc = 0 AND ls_dynp-fieldvalue IS NOT INITIAL.
      lv_vrsio = ls_dynp-fieldvalue.
    ENDIF.
  ENDIF.

  "If still empty, stop
  IF lv_vrsio IS INITIAL.
    MESSAGE 'Please enter P_VRSIO first to get Conflict F4 help.'(002)
      TYPE 'I'.
    RETURN.
  ENDIF.

  "Optionally sync it back to the program variable too
  p_vrsio = lv_vrsio.



  "2) Fetch conflicts filtered by version
  "   (Change field names if your table uses different ones)
  SELECT DISTINCT
         vrsio conid
         FROM /psyng/confdet
         INTO TABLE lt_conids
         WHERE vrsio = p_vrsio.

  IF sy-subrc <> 0 OR lt_conids IS INITIAL.
    MESSAGE 'No conflicts found'(003) TYPE 'I'.
    RETURN.
  ENDIF.
  "3) Build F4 list
  CLEAR lt_f4[].
  LOOP AT lt_conids INTO ls_conids.

    ls_f4-conid = ls_conids-conid.
    ls_f4-vrsio = ls_conids-vrsio.
    APPEND ls_f4 TO lt_f4 .
  ENDLOOP.

  "4) Call F4 help (user picks one -> fills P_CONID)
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CONID'        "field returned
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'P_CONID'      "screen field name (must match
*parameter)
      value_org       = 'S'
    TABLES
      value_tab       = lt_f4
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0 OR lt_return IS INITIAL.
    RETURN.
  ENDIF.

  "5) First match from return (user selection)
  READ TABLE lt_return INTO ls_return INDEX 1.
  IF sy-subrc = 0 AND ls_return-fieldval IS NOT INITIAL.
    p_conid = ls_return-fieldval.
  ENDIF.


ENDFORM.
