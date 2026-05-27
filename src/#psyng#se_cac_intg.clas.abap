class /PSYNG/SE_CAC_INTG definition
  public
  final
  create public .

public section.

  methods CALL_SE_INTEGRATION
    importing
      !SOD_VERSIO type /PSYNG/SODVRSIO .
protected section.
private section.
ENDCLASS.



CLASS /PSYNG/SE_CAC_INTG IMPLEMENTATION.


  METHOD call_se_integration.

    " Local variable declarations following naming conventions
    DATA: lv_cfg_se TYPE /psyng/param_value,
          lv_cfg_dflt_sod TYPE /psyng/param_value,
          lt_conflict TYPE STANDARD TABLE OF /psyng/conflict,
          ls_conflict TYPE /psyng/conflict,
          lv_versio TYPE /psyng/sodvrsio,
          ls_clskey TYPE seoclskey,
          ls_vseoclass TYPE vseoclass,
          lv_method TYPE string,
          lo_obj TYPE REF TO object,
          lx_error TYPE REF TO cx_root,
          lv_msg TYPE string.
    CONSTANTS : lc_method(3) TYPE c VALUE 'RUN'.

    IF NOT sod_versio IS INITIAL.

      CLEAR lv_versio.
      SELECT SINGLE vrsio
        FROM /psyng/conflict
        INTO lv_versio
        WHERE vrsio = sod_versio.
      IF sy-subrc NE 0.
MESSAGE 'Entered SOD version not found.Running on default SOD version'(306)
     TYPE 'S' DISPLAY LIKE 'E'.
        " Get DFLT_GLOBAL_VERSION configuration
        CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
          EXPORTING
            i_parameter = 'DFLT_GLOBAL_VERSION'
          IMPORTING
            e_value = lv_cfg_dflt_sod.
        IF sy-subrc <> 0.
          MESSAGE 'Error fetching DFLT_GLOBAL_VERSION config'(303)
          TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.

        ELSE.
          CLEAR lv_versio.
          lv_versio = lv_cfg_dflt_sod.
        ENDIF.
      ENDIF.

    ELSE.
      " Get DFLT_GLOBAL_VERSION configuration
      CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
        EXPORTING
          i_parameter = 'DFLT_GLOBAL_VERSION'
        IMPORTING
          e_value = lv_cfg_dflt_sod.
      IF sy-subrc <> 0.
        MESSAGE 'Error fetching DFLT_GLOBAL_VERSION config'(303)
        TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.

      ELSE.
        CLEAR lv_versio.
        lv_versio = lv_cfg_dflt_sod.
      ENDIF.
    ENDIF.

    " Get SE_CAC_INTEGRATION config
    CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
      EXPORTING
        i_parameter = 'SE_CAC_INTEGRATION'
      IMPORTING
        e_value = lv_cfg_se.
    IF sy-subrc <> 0.
      MESSAGE 'Error fetching SE_CAC_INTEGRATION config'(301)
      TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    IF lv_cfg_se EQ 'Y'.
      " Get conflict data
      CALL FUNCTION '/PSYNG/SW_028'
        EXPORTING
          i_vrsio = lv_versio
        TABLES
          et_conflict = lt_conflict.
      IF sy-subrc <> 0.
        MESSAGE 'Error fetching conflict data'(304)
        TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      CLEAR ls_clskey.
      ls_clskey-clsname = '/SAST/CL_SE_RULE_MAPPER'.

      " Get class meta info
      CALL FUNCTION 'SEO_CLASS_GET'
        EXPORTING
          clskey = ls_clskey
        IMPORTING
          class = ls_vseoclass
        EXCEPTIONS
          not_existing = 1
          deleted = 2
          is_interface = 3
          model_only = 4
          OTHERS = 5.
      IF sy-subrc <> 0.
   MESSAGE 'CAC module not found.Disable SE–CAC config to continue'(302)
   TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ELSE.
        " Exception handling for object creation
        TRY.
            CREATE OBJECT lo_obj TYPE (ls_clskey-clsname).
          CATCH cx_sy_create_object_error INTO lx_error.
            CALL METHOD lx_error->('GET_TEXT')
              RECEIVING ret_text = lv_msg.
            MESSAGE lv_msg TYPE 'S' DISPLAY LIKE 'E'.
            RETURN.
          CATCH cx_root INTO lx_error.
            CALL METHOD lx_error->('GET_TEXT')
              RECEIVING ret_text = lv_msg.
            MESSAGE lv_msg TYPE 'S' DISPLAY LIKE 'E'.
            RETURN.
        ENDTRY.
        IF lo_obj IS BOUND.
          " Check if conflict table has records before looping
          IF lt_conflict IS NOT INITIAL.
         " Loop through conflict records and call RUN method dynamically
            LOOP AT lt_conflict INTO ls_conflict.
              " Check if conflict record is valid before calling method
              IF ls_conflict-conid IS NOT INITIAL.
                TRY.
                    CALL METHOD lo_obj->(lc_method)
                      EXPORTING
                        conid = ls_conflict-conid
                        busarea = ls_conflict-busarea
                        subarea = ls_conflict-subarea
                        imp = ls_conflict-imp
                        description = ls_conflict-description
                        action = 'I'.
                  CATCH cx_sy_dyn_call_illegal_method INTO lx_error.
                    CALL METHOD lx_error->('GET_TEXT')
                      RECEIVING ret_text = lv_msg.
                    MESSAGE lv_msg TYPE 'S' DISPLAY LIKE 'E'.
                  CATCH cx_root INTO lx_error.
                    CALL METHOD lx_error->('GET_TEXT')
                      RECEIVING ret_text = lv_msg.
                    MESSAGE lv_msg TYPE 'S' DISPLAY LIKE 'E'.
                ENDTRY.
              ENDIF.
            ENDLOOP.
          ELSE.
        MESSAGE 'No conflict data found'(305)
              TYPE 'S' DISPLAY LIKE 'W'.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
