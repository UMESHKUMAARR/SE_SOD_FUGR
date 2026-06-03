*&---------------------------------------------------------------------*
*&      Form  SCHEMA
*&---------------------------------------------------------------------*
FORM schemas CHANGING lt_schema TYPE tt_schema.
  DATA:
        ls_schema TYPE ty_schema,
        ls_conflict TYPE /psyng/conflict,
        wa_busarea TYPE /psyng/busarea,
        lt_busarea TYPE TABLE OF /psyng/busarea.

  SELECT busarea FROM /psyng/busarea INTO TABLE lt_busarea.

  LOOP AT lt_busarea INTO wa_busarea.
    ls_schema-schema_name = wa_busarea-busarea.
    APPEND ls_schema TO lt_schema.
  ENDLOOP.

  SORT lt_schema BY schema_name.
  DELETE ADJACENT DUPLICATES FROM lt_schema COMPARING schema_name.

  CLEAR: ls_schema, ls_conflict.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SCHEMA_CSV
*&---------------------------------------------------------------------*
FORM schemas_csv  USING    lt_schema TYPE tt_schema
                         CHANGING lt_schema_csv TYPE tt_csv.
  DATA:
        ls_schema_csv TYPE ty_csv,
        ls_schema TYPE ty_schema.

  ls_schema_csv-line = 'Schema Name'(154).
  APPEND ls_schema_csv TO lt_schema_csv.

  LOOP AT lt_schema INTO ls_schema.
    ls_schema_csv-line = ls_schema-schema_name.
    APPEND ls_schema_csv TO lt_schema_csv.
  ENDLOOP.

  CLEAR: ls_schema, ls_schema_csv.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CSV_TO_B64
*&---------------------------------------------------------------------*
FORM csv_to_b64  USING    lt_csv TYPE tt_csv
                         CHANGING base64 TYPE string.
  DATA:
        lv_str_x TYPE xstring.

  CALL FUNCTION 'SCMS_TEXT_TO_XSTRING'
  IMPORTING
    buffer   = lv_str_x
  TABLES
    text_tab = lt_csv
"(++)BOC AKUMAR SE VF scan-19/12/2024
  EXCEPTIONS
    failed       = 1
    OTHERS       = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC AKUMAR SE VF scan-19/12/2024.

  IF lv_str_x IS NOT INITIAL.
    CALL FUNCTION 'SCMS_BASE64_ENCODE_STR'
      EXPORTING
        input         = lv_str_x
     IMPORTING
       output        = base64.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GROUPS
*&---------------------------------------------------------------------*
FORM groups  USING    VALUE(lt_confdet) TYPE tt_confdet
                      vrsio TYPE /psyng/sodvrsio
             CHANGING lt_group TYPE tt_group.
  DATA:
        ls_confdet TYPE /psyng/confdet,
        lv_grpdes TYPE string,
        ls_group TYPE ty_group.

  SORT lt_confdet BY functionid.
  DELETE ADJACENT DUPLICATES FROM lt_confdet COMPARING functionid.

  LOOP AT lt_confdet INTO ls_confdet.

    PERFORM get_grpdes USING ls_confdet-functionid vrsio
                       CHANGING lv_grpdes.

    ls_group-group = ls_confdet-functionid.
    ls_group-description = lv_grpdes.

    APPEND ls_group TO lt_group.
    CLEAR ls_group.

  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_GRPDES
*&---------------------------------------------------------------------*
FORM get_grpdes  USING    functionid TYPE /psyng/function_id
                          vrsio TYPE /psyng/sodvrsio
                 CHANGING grpdes TYPE string.
  SELECT SINGLE description
                FROM /psyng/function
                INTO grpdes
                WHERE vrsio = vrsio AND
                      function = functionid.
  IF sy-subrc <> 0.
    CLEAR grpdes.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GROUPS_CSV
*&---------------------------------------------------------------------*
FORM groups_csv  USING    lt_group TYPE tt_group
                 CHANGING lt_group_csv TYPE tt_csv.
  DATA:
        ls_group_csv TYPE ty_csv,
        ls_group TYPE ty_group,
        group TYPE string,
        desc TYPE string,
        type TYPE string,
        line TYPE string.

*--File header line
  CONCATENATE 'Ruleset ID'(208)
              'Group Name'(155)
              'Group Description'(156)
              'Group Type'(157)
              INTO line
              SEPARATED BY ';'.

  ls_group_csv-line = line.
  APPEND ls_group_csv TO lt_group_csv.

*--Main loop
  LOOP AT lt_group INTO ls_group.


    group = ls_group-group.
    desc  = ls_group-description.

    CONCATENATE p_plcvrs group desc type INTO line SEPARATED BY ';'.
    ls_group_csv-line = line.
    APPEND ls_group_csv TO lt_group_csv.

  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ACT_MOD_VALS
*&---------------------------------------------------------------------*
FORM act_mod_vals  USING    lt_confdet TYPE tt_confdet
                   CHANGING lt_actmodval TYPE tt_actmodval.

  DATA:
        ls_actmodval TYPE ty_actmodval,
        ls_confdet TYPE /psyng/confdet.

  LOOP AT lt_confdet INTO ls_confdet.
    ls_actmodval-actmodval = ls_confdet-functionid.
    APPEND ls_actmodval TO lt_actmodval.
    CLEAR ls_actmodval.
  ENDLOOP.

  SORT lt_actmodval BY actmodval.
  DELETE ADJACENT DUPLICATES FROM lt_actmodval COMPARING actmodval.

  CLEAR: ls_actmodval, ls_confdet.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ACTMODVAL_CSV
*&---------------------------------------------------------------------*
FORM actmodval_csv  USING    lt_actmodval TYPE tt_actmodval
                    CHANGING lt_actmodval_csv TYPE tt_csv.

  DATA:
        ls_actmodval_csv TYPE ty_csv,
        ls_actmodval TYPE ty_actmodval.

  ls_actmodval_csv-line = 'Activity Mode Value'(158).
  APPEND ls_actmodval_csv TO lt_actmodval_csv.

  LOOP AT lt_actmodval INTO ls_actmodval.
    ls_actmodval_csv-line = ls_actmodval-actmodval.
    APPEND ls_actmodval_csv TO lt_actmodval_csv.
  ENDLOOP.

  CLEAR: ls_actmodval, ls_actmodval_csv.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  RULES
*&---------------------------------------------------------------------*
FORM rules  USING    lt_conflict TYPE tt_conflict
                     lt_confdet  TYPE tt_confdet
            CHANGING lt_rule TYPE tt_rule.

  DATA:
        ls_conflict TYPE /psyng/conflict,
        ls_confdet TYPE /psyng/confdet,
        ls_rule TYPE ty_rule,
        lv_tmp_tabix TYPE sy-tabix.

  LOOP AT lt_conflict INTO ls_conflict.
    ls_rule-cmb_name = ls_conflict-conid.
    ls_rule-cmb_des =  ls_conflict-description.
    IF ls_conflict-imp IS INITIAL.
      ls_rule-risk_lev = 'None'.
    ELSE.
      ls_rule-risk_lev = ls_conflict-imp.
    ENDIF.
    ls_rule-risk_des = ''.
    ls_rule-prcs_ctrl = ''.
    ls_rule-schema = ls_conflict-busarea.

    READ TABLE lt_confdet INTO ls_confdet WITH KEY conid =
                                                     ls_conflict-conid.
    IF sy-subrc = 0.
      lv_tmp_tabix = sy-tabix + 1.
      ls_rule-obj1_type = 'Group'(159).
      ls_rule-obj1      = ls_confdet-functionid.
      READ TABLE lt_confdet INTO ls_confdet INDEX lv_tmp_tabix.
      IF sy-subrc = 0 AND ls_confdet-conid = ls_conflict-conid.
        ADD 1 TO lv_tmp_tabix.
        ls_rule-obj2_type = 'Group'(159).
        ls_rule-obj2      = ls_confdet-functionid.
        READ TABLE lt_confdet INTO ls_confdet INDEX lv_tmp_tabix.
        IF sy-subrc = 0 AND ls_confdet-conid = ls_conflict-conid.
          ADD 1 TO lv_tmp_tabix.
          ls_rule-obj3_type = 'Group'(159).
          ls_rule-obj3      = ls_confdet-functionid.
          READ TABLE lt_confdet INTO ls_confdet INDEX lv_tmp_tabix.
          IF sy-subrc = 0 AND ls_confdet-conid = ls_conflict-conid.
            ADD 1 TO lv_tmp_tabix.
            ls_rule-obj4_type = 'Group'(159).
            ls_rule-obj4      = ls_confdet-functionid.
            READ TABLE lt_confdet INTO ls_confdet INDEX lv_tmp_tabix.
            IF sy-subrc = 0 AND ls_confdet-conid = ls_conflict-conid.
              ADD 1 TO lv_tmp_tabix.
              ls_rule-obj5_type = 'Group'(159).
              ls_rule-obj5      = ls_confdet-functionid.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
    APPEND ls_rule TO lt_rule.
    CLEAR ls_rule.
    CLEAR ls_confdet.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  RULES_CSV
*&---------------------------------------------------------------------*
FORM rules_csv  USING    lt_rule TYPE tt_rule
                CHANGING lt_rule_csv TYPE tt_csv.

  DATA:
        ls_rule TYPE ty_rule,
        ls_rule_csv TYPE ty_csv.

*--File header line
  CONCATENATE 'Ruleset ID'(208)
              'Combination name'(160)
              'Combination Description'(161)
              'Risk Level'(162)
              'Risk Description'(163)
              'Process Control'(164)
              'Schema'(165)
              'Object Type'(166)
              'Object Name'(167)
              'Object Type'(166)
              'Object Name'(167)
              'Object Type'(166)
              'Object Name'(167)
              'Object Type'(166)
              'Object Name'(167)
              'Object Type'(166)
              'Object Name'(167)
              INTO ls_rule_csv-line
              SEPARATED BY ';'.

  APPEND ls_rule_csv TO lt_rule_csv.
  CLEAR ls_rule_csv.

  LOOP AT lt_rule INTO ls_rule.

    CONCATENATE p_plcvrs
                ls_rule-cmb_name
                ls_rule-cmb_des
                ls_rule-risk_lev
                ls_rule-risk_des
                ls_rule-prcs_ctrl
                ls_rule-schema
                ls_rule-obj1_type
                ls_rule-obj1
                ls_rule-obj2_type
                ls_rule-obj2
                ls_rule-obj3_type
                ls_rule-obj3
                ls_rule-obj4_type
                ls_rule-obj4
                ls_rule-obj5_type
                ls_rule-obj5
                INTO ls_rule_csv-line
                SEPARATED BY ';'.
    APPEND ls_rule_csv TO lt_rule_csv.
    CLEAR ls_rule_csv.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ACTMOD
*&---------------------------------------------------------------------*
FORM actvtmod  USING  lt_functtran TYPE tt_fundet
             CHANGING lt_actvtmod TYPE tt_actvtmod
                      lt_faobj TYPE tt_funobj
                      lt_am TYPE tt_am.

  DATA:
          ls_functtran TYPE /psyng/functtran,
          ls_faobj TYPE /psyng/faobj2,
          lv_obj TYPE /psyng/faobj2-object,
          ls_actvtmod TYPE ty_actvtmod,
          lv_authvals TYPE string,
          lf_tcode_orobj TYPE flag,
          lf_tcode_andobj TYPE flag,
*          lt_am TYPE TABLE OF ty_am,
          lt_ftorobj TYPE TABLE OF ty_ftorobj,
          ls_ftorobj TYPE ty_ftorobj,
          lt_faobj_tmp TYPE tt_funobj,
          ls_am TYPE ty_am.

*  To store OR objects of tcode whose new activity mode has been created
  RANGES: lr_torobj FOR /psyng/faobj2-object.
  DATA: ls_torobj LIKE LINE OF lr_torobj.

  CONSTANTS c_fiori TYPE string VALUE 'Fiori:'.

  LOOP AT lt_functtran INTO ls_functtran.

*  Take TCODE
    IF ls_functtran-type = 'T'.
      ls_actvtmod-actvt = ls_functtran-tcode.
    ELSEIF ls_functtran-type = 'F'.
      CONCATENATE c_fiori ls_functtran-fioriid INTO ls_actvtmod-actvt
                                               SEPARATED BY space.
*      ls_actvtmod-actvt = ls_functtran-fioriid.
    ELSE.
*    Do not sync authorizations of placeholder tcodes for now. decision
*    pending
      CONTINUE.
    ENDIF.

*  Fiori ID description part left do later
    PERFORM get_actvtdes USING ls_functtran-tcode
                     CHANGING ls_actvtmod-actvtdes.

*  Check any OR object is present in TCODE
    CLEAR lf_tcode_orobj.
    READ TABLE lt_faobj WITH KEY funid = ls_functtran-functionid
                                 tcode = ls_functtran-tcode
                                 obj_or = 'OR'
                                 TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      lf_tcode_orobj = 'X'. "OR object present
    ELSE.
      CLEAR lf_tcode_orobj. "OR object not present
    ENDIF.

    IF lf_tcode_orobj IS INITIAL. "PATH 1 (No OR objects)
*  No OR object is present in TCODE that means no separate activity
*  modes will be created for objects. Club all AND objects with one
*  activity mode which is function name

*        Create name of new activity mode (e.g. FF_1)
      PERFORM get_new_mode_name USING ls_functtran-functionid
                                      ls_functtran-tcode
                                CHANGING ls_actvtmod-actvtmod
                                         lt_am.

*      ls_actvtmod-actvtmod = ls_functtran-functionid.

*      CLEAR ls_am.
*      ls_am-funid = ls_functtran-functionid.
*      ls_am-tcode = ls_functtran-tcode.
*      ls_am-am = ls_functtran-functionid.
*      APPEND ls_am TO lt_am.


     LOOP AT lt_faobj INTO ls_faobj WHERE tcode = ls_functtran-tcode AND
                                        funid = ls_functtran-functionid.

*  Get all auth values of auth field for auth object
        PERFORM get_authvals USING ls_functtran-tcode
                                   ls_functtran-functionid
                                   ls_faobj-object
                                   ls_faobj-field
                             CHANGING lv_authvals
                                      lt_faobj
                                      lt_faobj_tmp.

        ls_actvtmod-sys = p_sys.
        ls_actvtmod-authobj = ls_faobj-object.
        ls_actvtmod-authfield = ls_faobj-field.
        ls_actvtmod-authval = lv_authvals.
        IF NOT ls_actvtmod-authval IS INITIAL.
          APPEND ls_actvtmod TO lt_actvtmod.
        ENDIF.
        CLEAR : lv_authvals.

      ENDLOOP.
      REFRESH lt_faobj_tmp. "No need to restore deleted entries

    ELSE. "PATH 2 (OR Objects exist)
*  OR object is present in TCODE that means separate activity
*  modes will be created for objects. Club combinations of AND + OR
*  objects with separate activity modes

*    Taking OR objects one by one
     LOOP AT lt_faobj INTO ls_faobj WHERE tcode = ls_functtran-tcode AND
                                    funid = ls_functtran-functionid AND
                                        obj_or = 'OR'.

*      For each new OR object create new activity mode
        AT NEW object.

*        Create name of new activity mode (e.g. FF_1)
          PERFORM get_new_mode_name USING ls_functtran-functionid
                                          ls_functtran-tcode
                                    CHANGING ls_actvtmod-actvtmod
                                             lt_am.

*        Check any AND object present in TCODE so to knwo whether
*        AND + OR combination has to be created or only each OR object
*        with separate activity mode has to be created
          CLEAR lf_tcode_andobj.
          READ TABLE lt_faobj WITH KEY funid = ls_functtran-functionid
                                       tcode = ls_functtran-tcode
                                       obj_or = ''
                                  TRANSPORTING NO FIELDS."BINARY SEARCH.
          IF sy-subrc = 0.
            lf_tcode_andobj = 'X'. "AND object present
          ELSE.
            CLEAR lf_tcode_andobj. "AND object not present
          ENDIF.

          IF lf_tcode_andobj IS INITIAL. "PATH 2A (Only OR objects)

*          Take OR object that has not yet processed
            CLEAR lv_obj.
            IF lr_torobj[] IS NOT INITIAL.
              LOOP AT lt_faobj INTO ls_faobj
                               WHERE funid = ls_functtran-functionid AND
                                     tcode = ls_functtran-tcode AND
                                     object NOT IN lr_torobj.
                lv_obj = ls_faobj-object.
                EXIT.
              ENDLOOP.
            ELSE.
              LOOP AT lt_faobj INTO ls_faobj
                          WHERE funid = ls_functtran-functionid AND
                                tcode = ls_functtran-tcode.
                lv_obj = ls_faobj-object.
                EXIT.
              ENDLOOP.
            ENDIF.

*          club all authorizations values of this object with new AM
            LOOP AT lt_faobj INTO ls_faobj
                               WHERE funid = ls_functtran-functionid AND
                                     tcode = ls_functtran-tcode AND
                                     object = lv_obj.



              PERFORM get_authvals USING ls_functtran-tcode
                                         ls_functtran-functionid
                                         ls_faobj-object
                                         ls_faobj-field
                                   CHANGING lv_authvals
                                            lt_faobj
                                            lt_faobj_tmp.

              ls_actvtmod-sys = p_sys.
              ls_actvtmod-authobj = ls_faobj-object.
              ls_actvtmod-authfield = ls_faobj-field.
              ls_actvtmod-authval = lv_authvals.
*              IF NOT ls_actvtmod-authval IS INITIAL. "later
              APPEND ls_actvtmod TO lt_actvtmod.
*              ENDIF.
              CLEAR : lv_authvals.

*   Store OR object which is processed
     READ TABLE lr_torobj WITH KEY low = ls_faobj-object TRANSPORTING NO
     FIELDS.
              IF sy-subrc <> 0.
                ls_torobj-sign = 'I'.
                ls_torobj-option = 'EQ'.
                ls_torobj-low = ls_faobj-object.
                INSERT ls_torobj INTO TABLE lr_torobj.
              ENDIF.
            ENDLOOP.
            REFRESH lt_faobj_tmp. "No need to restore deleted entries


          ELSE. "PATH 2b (Both AND + OR objects exist)

*          Take OR object that has not yet processed
            CLEAR lv_obj.
            IF lr_torobj[] IS NOT INITIAL.
              LOOP AT lt_faobj INTO ls_faobj
                               WHERE funid = ls_functtran-functionid AND
                                     tcode = ls_functtran-tcode AND
                                     obj_or = 'OR' AND
                                     object NOT IN lr_torobj.
                lv_obj = ls_faobj-object.
                EXIT.
              ENDLOOP.
            ELSE.
              LOOP AT lt_faobj INTO ls_faobj
                          WHERE funid = ls_functtran-functionid AND
                                tcode = ls_functtran-tcode AND
                                obj_or = 'OR'.
                lv_obj = ls_faobj-object.
                EXIT.
              ENDLOOP.
            ENDIF.

*          club all authorizations values of OR object with new AM
            LOOP AT lt_faobj INTO ls_faobj
                               WHERE funid = ls_functtran-functionid AND
                                     tcode = ls_functtran-tcode AND
                                     object = lv_obj.



              PERFORM get_authvals USING ls_functtran-tcode
                                         ls_functtran-functionid
                                         ls_faobj-object
                                         ls_faobj-field
                                   CHANGING lv_authvals
                                            lt_faobj
                                            lt_faobj_tmp.

              ls_actvtmod-sys = p_sys.
              ls_actvtmod-authobj = ls_faobj-object.
              ls_actvtmod-authfield = ls_faobj-field.
              ls_actvtmod-authval = lv_authvals.
*              IF NOT ls_actvtmod-authval IS INITIAL. "later
              APPEND ls_actvtmod TO lt_actvtmod.
*              ENDIF.
              CLEAR : lv_authvals.

*   Store OR object which is processed
     READ TABLE lr_torobj WITH KEY low = ls_faobj-object TRANSPORTING NO
     FIELDS.
              IF sy-subrc <> 0.
                ls_torobj-sign = 'I'.
                ls_torobj-option = 'EQ'.
                ls_torobj-low = ls_faobj-object.
                INSERT ls_torobj INTO TABLE lr_torobj.
              ENDIF.
            ENDLOOP.
            REFRESH lt_faobj_tmp.

*         Club all authorizations values of all AND object with new AM
            LOOP AT lt_faobj INTO ls_faobj
                               WHERE funid = ls_functtran-functionid AND
                                     tcode = ls_functtran-tcode AND
                                     obj_or = ''.

              ls_actvtmod-authobj = ls_faobj-object.
              ls_actvtmod-authfield = ls_faobj-field.

              PERFORM get_authvals USING ls_functtran-tcode
                                         ls_functtran-functionid
                                         ls_faobj-object
                                         ls_faobj-field
                                   CHANGING lv_authvals
                                            lt_faobj
                                            lt_faobj_tmp.

              ls_actvtmod-authval = lv_authvals.

              PERFORM get_actvtdes USING ls_functtran-tcode
                                   CHANGING ls_actvtmod-actvtdes.

              ls_actvtmod-sys = p_sys.
*              IF NOT ls_actvtmod-authval IS INITIAL. "later
              APPEND ls_actvtmod TO lt_actvtmod.
*              ENDIF.
              CLEAR : lv_authvals.

            ENDLOOP.
*            Deleted entries restored
            APPEND LINES OF lt_faobj_tmp TO lt_faobj.


          ENDIF.
        ENDAT.
      ENDLOOP.
    ENDIF.

    REFRESH: lr_torobj.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ACTVTMOD_CSV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->LT_ACTVTMOD  text
*      <--LT_ACTVTMOD_CSV  text
*----------------------------------------------------------------------*
FORM actvtmod_csv  USING    lt_actvtmod TYPE tt_actvtmod
                   CHANGING lt_actvtmod_csv TYPE tt_csv.

  DATA:
        ls_actvtmod TYPE ty_actvtmod,
        ls_actvtmod_csv TYPE ty_csv.

  CONCATENATE 'Activity'(168)
              'Activity Mode'(169)
              'Authorization Object'(170)
              'Authorization Field'(171)
              'Authorization Value'(172)
              'Activity Description'(173)
              'System'(174)
              INTO ls_actvtmod_csv-line
              SEPARATED BY ';'.
  APPEND ls_actvtmod_csv TO lt_actvtmod_csv.
  CLEAR ls_actvtmod_csv.

  LOOP AT lt_actvtmod INTO ls_actvtmod.
    CONCATENATE ls_actvtmod-actvt
                ls_actvtmod-actvtmod
                ls_actvtmod-authobj
                ls_actvtmod-authfield
                ls_actvtmod-authval
                ls_actvtmod-actvtdes
                ls_actvtmod-sys
                INTO ls_actvtmod_csv-line
                SEPARATED BY ';'.
    APPEND ls_actvtmod_csv TO lt_actvtmod_csv.
    CLEAR ls_actvtmod_csv.
  ENDLOOP.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_ACTVTDES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_FUNCTTRAN_TCODE  text
*      <--P_LS_ACTVTMOD_ACTVTDES  text
*----------------------------------------------------------------------*
FORM get_actvtdes  USING    tcode TYPE tcode
                   CHANGING actvtdes TYPE string.

  SELECT SINGLE ttext
                FROM tstct
                INTO actvtdes
                WHERE sprsl = 'E' AND
                      tcode = tcode.
  IF sy-subrc <> 0.
    CLEAR actvtdes.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GRPCMP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_FUNCTTRAN  text
*      <--P_LT_GRPCMP  text
*----------------------------------------------------------------------*
FORM grpcmp  USING    lt_functtran TYPE tt_fundet
                      lt_am TYPE tt_am
             CHANGING lt_grpcmp TYPE tt_grpcmp.

  DATA:
       ls_functtran TYPE /psyng/functtran,
       ls_grpcmp TYPE ty_grpcmp,
       ls_am TYPE ty_am.

  CONSTANTS c_fiori TYPE string VALUE 'Fiori:'.

  LOOP AT lt_functtran INTO ls_functtran.

    ls_grpcmp-grp = ls_functtran-functionid.
    IF ls_functtran-type = 'T'.
      ls_grpcmp-actvt = ls_functtran-tcode.
    ELSEIF ls_functtran-type = 'F'.
      CONCATENATE c_fiori ls_functtran-fioriid INTO ls_grpcmp-actvt
                                               SEPARATED BY space.
*      ls_grpcmp-actvt = ls_functtran-fioriid.
    ELSE.
*--No decision on placeholder tcodes for now.
    ENDIF.

    PERFORM get_actvtdes USING ls_functtran-tcode
                           CHANGING ls_grpcmp-actvtdes.

*--BOC PN7183 AKUMAR
*--Commenting below subroutine
*    PERFORM get_apparea USING ls_functtran-functionid p_vrsio
*                        CHANGING ls_grpcmp-apparea.
*--EOC PN7183 AKUMAR

    ls_grpcmp-actvtgrptyp = ''.

    PERFORM get_grpdes USING ls_functtran-functionid p_vrsio
                       CHANGING ls_grpcmp-desc.

    ls_grpcmp-sys = p_sys.

    LOOP AT lt_am INTO ls_am WHERE funid = ls_functtran-functionid AND
                                   tcode = ls_functtran-tcode.
      ls_grpcmp-actvtmod = ls_am-am.
      APPEND ls_grpcmp TO lt_grpcmp.
    ENDLOOP.

    CLEAR ls_grpcmp.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_APPAREA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->FUNCTIONID  text
*      -->VRSIO text
*      <--APPAREA  text
*----------------------------------------------------------------------*
FORM get_apparea  USING    functionid TYPE /psyng/function_id
                           vrsio TYPE /psyng/sodvrsio
                  CHANGING apparea TYPE string.

  DATA:
        lv_busarea TYPE /psyng/bus_area.

  SELECT SINGLE busarea
                FROM /psyng/function
                INTO lv_busarea
                WHERE vrsio = vrsio AND
                      function = functionid.
  IF sy-subrc = 0.

    SELECT SINGLE text
                  FROM /psyng/busarea
                  INTO apparea
                  WHERE busarea = lv_busarea.
    IF sy-subrc <> 0.
      CLEAR apparea.
    ENDIF.

  ELSE.

    CLEAR apparea.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GRPCMP_CSV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->LT_GRPCMP  text
*      <--LT_GRPCMP_CSV  text
*----------------------------------------------------------------------*
FORM grpcmp_csv  USING    lt_grpcmp TYPE tt_grpcmp
                 CHANGING lt_grpcmp_csv TYPE tt_csv.

  DATA:
        ls_grpcmp TYPE ty_grpcmp,
        ls_grpcmp_csv TYPE ty_csv.

  CONCATENATE 'Ruleset ID'(208)
              'Group Name'(155)
              'Activity Name'(175)
              'Activity Mode'(169)
              'Activity Description'(173)
              'Application Area'(176)
              'Activity Group'(177)
              'Description'(178)
              'System'(174)
              INTO ls_grpcmp_csv-line
              SEPARATED BY ';'.
  APPEND ls_grpcmp_csv TO lt_grpcmp_csv.
  CLEAR ls_grpcmp_csv.

  LOOP AT lt_grpcmp INTO ls_grpcmp.
    CONCATENATE p_plcvrs
                ls_grpcmp-grp
                ls_grpcmp-actvt
                ls_grpcmp-actvtmod
                ls_grpcmp-actvtdes
                ls_grpcmp-apparea
                ls_grpcmp-actvtgrptyp
                ls_grpcmp-desc
                ls_grpcmp-sys
                INTO ls_grpcmp_csv-line
                SEPARATED BY ';'.
    APPEND ls_grpcmp_csv TO lt_grpcmp_csv.
    CLEAR ls_grpcmp_csv.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--LT_LOGS  text
*----------------------------------------------------------------------*
FORM alv_data  CHANGING lt_logs TYPE tt_logs.
  DATA:
        ls_logs TYPE ty_logs,
        ls_message TYPE bapiret2.

  LOOP AT gt_messages INTO ls_message.
    ls_logs-msg_typ = ls_message-type.
    ls_logs-log_msg = ls_message-message.
    IF ls_message-type = 'S'.
      ls_logs-detail = 'See details'(017).
    ENDIF.
    APPEND ls_logs TO lt_logs.
    CLEAR ls_logs.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--GT_FIELDCAT  text
*----------------------------------------------------------------------*
FORM fieldcat  CHANGING gt_fieldcat TYPE slis_t_fieldcat_alv.

  DATA : ls_fieldcat TYPE slis_fieldcat_alv.

*--Message type: E - Error , S - Success
  ls_fieldcat-fieldname = 'MSG_TYP'.
  ls_fieldcat-seltext_l = 'Message type'(179).
  ls_fieldcat-seltext_m = 'Message.'(180).
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

*--Message description
  ls_fieldcat-fieldname = 'LOG_MSG'.
  ls_fieldcat-seltext_l = 'Log message'(181).
  ls_fieldcat-seltext_m = 'Log msg.'(182).
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

*--Hotspot field to check more details
  ls_fieldcat-fieldname = 'DETAIL'.
  ls_fieldcat-seltext_l = 'Details'(190).
  ls_fieldcat-seltext_m = 'Details'(190).
  ls_fieldcat-seltext_s = 'Details'(190).
  ls_fieldcat-hotspot   = 'X'.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_DISPLAY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_display .

  DATA : lv_repid TYPE sy-repid,
         l_alv_layout TYPE slis_layout_alv.

  lv_repid = sy-repid.

*--ALV Layout
  l_alv_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   EXPORTING
     i_callback_program                 = lv_repid
      it_fieldcat                       = gt_fieldcat
      is_layout                         = l_alv_layout
      i_callback_user_command           = 'LOGS_CLICK'
    TABLES
      t_outtab                          = gt_logs
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_LOGS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_logs .
  PERFORM alv_data CHANGING gt_logs.
  PERFORM fieldcat CHANGING gt_fieldcat.
  PERFORM alv_display.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  PERFORM set_status.
  SET TITLEBAR 'TITLE_100'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Form  SET_STATUS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_status .
  SET PF-STATUS 'PF_STATUS_100'.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  IF sy-ucomm = 'BACK'.
    SET SCREEN 0.
    LEAVE SCREEN.
  ELSEIF sy-ucomm = 'SAVE'.
    IF gf_dischg = gc_change.
      PERFORM save_cfg.
      MESSAGE s160(/psyng/sw) WITH
                              'Configuration saved successfully'(183).
    ENDIF.
  ELSEIF sy-ucomm = 'DISCHG'.
    IF gf_dischg = gc_change.
      gf_dischg = gc_display.
    ELSE.
      gf_dischg = gc_change.
    ENDIF.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  CFG_DATA  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE cfg_data OUTPUT.

  CALL FUNCTION '/PSYNG/SW_BRIDGE_GET_CFG'
   IMPORTING
     e_host        = g_host
     e_port        = g_port
     e_user        = g_user
     e_pass        = g_pass.

  IF g_host IS INITIAL.
    g_host = 'pathbridge.stage.appsiangrc.com'.
  ENDIF.

  IF g_port IS INITIAL.
    g_port = '443'.
  ENDIF.

  IF g_user IS INITIAL.
    g_user = 'api_en'.
  ENDIF.

*  DATA:
*        lt_cfg TYPE TABLE OF /psyng/bridgecfg,
*        ls_cfg TYPE /psyng/bridgecfg.
*
*  SELECT *
*    FROM /psyng/bridgecfg
*    INTO TABLE lt_cfg.
*
*  IF sy-subrc = 0.
*    LOOP AT lt_cfg INTO ls_cfg.
*      IF ls_cfg-param = 'Hostname'(186).
*        g_host = ls_cfg-value.
*      ELSEIF ls_cfg-param = 'Username'(184).
*        g_user = ls_cfg-value.
*      ELSEIF ls_cfg-param = 'Password'(185).
*        PERFORM decrypt_password USING ls_cfg-value
*                                 CHANGING g_pass.
*      ELSEIF ls_cfg-param = 'Port'(195).
*        g_port = ls_cfg-value.
*      ENDIF.
*    ENDLOOP.
*  ELSE.
*    CLEAR: g_host, g_user, g_pass.
*  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Form  SAVE_CFG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_cfg .

  DATA:
      lt_cfg TYPE TABLE OF /psyng/bridgecfg,
      ls_cfg TYPE /psyng/bridgecfg,
      lv_epass TYPE char40,
      l_pass TYPE c LENGTH 255.

  l_pass = g_pass.

  ls_cfg-param = 'Hostname'(186).
  ls_cfg-value = g_host.
  APPEND ls_cfg TO lt_cfg.
  CLEAR ls_cfg.

  ls_cfg-param = 'Username'(184).
  ls_cfg-value = g_user.
  APPEND ls_cfg TO lt_cfg.
  CLEAR ls_cfg.

  PERFORM encrypt_password USING l_pass
                         CHANGING lv_epass.

  ls_cfg-param = 'Password'(185).
  ls_cfg-value = lv_epass.
  APPEND ls_cfg TO lt_cfg.
  CLEAR ls_cfg.

  ls_cfg-param = 'Port'(195).
  ls_cfg-value = g_port.
  APPEND ls_cfg TO lt_cfg.
  CLEAR ls_cfg.

  IF lt_cfg IS NOT INITIAL.
    MODIFY /psyng/bridgecfg FROM TABLE lt_cfg.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ENCRYPT_PASSWORD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IM_DECRYPTED_PASSWORD  text
*      <--CH_ENCRYPTED_PASSWORD  text
*----------------------------------------------------------------------*
FORM encrypt_password
  USING    im_decrypted_password
  CHANGING ch_encrypted_password.

  DATA:
    l_index            TYPE i,
    l_number           TYPE i,
    l_key_val          TYPE i,
    l_passwd_val       TYPE i,
    l_accumulate       TYPE i.

  CLEAR ch_encrypted_password.

  l_index      = 0.
  l_accumulate = 0.
* encrypt the maximal length of the decrypted password, not just the
* filled part of the decrypted password
  DO co_password_length TIMES.                  "#EC PATHLOCK_CI_NO_DOS
*   check out the index in the key
    PERFORM character_search
        USING
           co_password_characters
           co_key+l_index(1)
        CHANGING
           l_key_val.
*   check out the index in the decrypted password
    PERFORM character_search
        USING
           co_password_characters
           im_decrypted_password+l_index(1)
        CHANGING
           l_passwd_val.
*   calculate the index of the character for the encrypted password
    l_number = ( l_accumulate + l_key_val + l_passwd_val ) MOD
            co_number_of_characters.
    ch_encrypted_password+l_index(1) =
            co_password_characters+l_number(1).
    l_index = l_index + 1.
*   Accumulate the index of the characters in the decrypted password
    l_accumulate = l_accumulate + l_passwd_val.
  ENDDO.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CHARACTER_SEARCH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IM_STRING  text
*      -->IM_CHARACTER  text
*      <--CH_POS  text
*----------------------------------------------------------------------*
FORM character_search  USING   im_string
                               im_character
                      CHANGING ch_pos             TYPE i.

  DATA:
    l_index            TYPE i,
    l_length           TYPE i.

  l_length = strlen( im_string ).

  ch_pos     = -1.
  l_index    =  0.
  DO l_length TIMES.                            "#EC PATHLOCK_CI_NO_DOS
    IF im_string+l_index(1) = im_character.
      ch_pos = l_index.
      EXIT.
    ENDIF.
    l_index = l_index + 1.
  ENDDO.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DECRYPT_PASSWORD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IM_ENCRYPTED_PASSWORD  text
*      <--CH_DECRYPTED_PASSWORD  text
*----------------------------------------------------------------------*
FORM decrypt_password USING    im_encrypted_password
                      CHANGING ch_decrypted_password.
* We use a simple 'Vigenere-Chiffre' (but with a long key) and
* add a accumulated index to it.
* By now the encrypted and the decrypted password have the same
* length (32)

  DATA:
    l_index            TYPE i,
    l_number           TYPE i,
    l_key_val          TYPE i,
    l_passwd_val       TYPE i,
    l_accumulate       TYPE i.

  CLEAR ch_decrypted_password.

  l_index      = 0.
  l_accumulate = 0.
* encrypt the maximal length of the decrypted password, not just the
* filled part of the decrypted password
  DO co_password_length TIMES.                  "#EC PATHLOCK_CI_NO_DOS
*   check out the index in the key
    PERFORM character_search
        USING
           co_password_characters
           co_key+l_index(1)
        CHANGING
           l_key_val.
*   check out the index in the encrypted password
    PERFORM character_search
        USING
           co_password_characters
           im_encrypted_password+l_index(1)
        CHANGING
           l_passwd_val.
*   calculate the index of the character for the encrypted password
    l_number = ( l_passwd_val - l_accumulate - l_key_val ) MOD
            co_number_of_characters.
    ch_decrypted_password+l_index(1) =
            co_password_characters+l_number(1).
    l_index = l_index + 1.
*   Accumulate the index of the characters in the decrypted password
    l_accumulate = l_accumulate + l_number.
  ENDDO.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  SCREEN_MODIFICATION  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE screen_modification OUTPUT.
  IF gf_dischg = gc_display.
    LOOP AT SCREEN.
      IF screen-group1 = 'CFG'.
        screen-input = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDLOOP.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Form  DEFAULT_RISK_LEVEL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--LT_CONFLICT  text
*----------------------------------------------------------------------*
FORM default_risk_level  CHANGING lt_conflict TYPE tt_conflict.

*  DATA:
*        ls_conflict TYPE /psyng/conflict.
*
*  LOOP AT lt_conflict INTO ls_conflict WHERE imp IS INITIAL.
*    ls_conflict-imp = 'MEDIUM'.
*    MODIFY lt_conflict FROM ls_conflict INDEX sy-tabix TRANSPORTING
*  imp.
*    CLEAR ls_conflict.
*  ENDLOOP.

  FIELD-SYMBOLS <fs_con> TYPE /psyng/conflict.

  LOOP AT lt_conflict ASSIGNING <fs_con> WHERE imp IS INITIAL.
    <fs_con>-imp = 'MEDIUM'.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_SYSTEMID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f4_systemid USING VALUE(lt_pbridge_sys) TYPE tt_pbridge_sys.

  IF lt_pbridge_sys IS NOT INITIAL.
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = 'SYSTEMID'
        dynpprog        = sy-cprog
        dynpnr          = sy-dynnr
        dynprofield     = 'P_SYSID'
        value_org       = 'S'
      TABLES
        value_tab       = lt_pbridge_sys
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ELSE.
    MESSAGE s160(/psyng/sw) WITH 'No values found'(T13).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_SYSNAME
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f4_sysname USING VALUE(lt_pbridge_sys) TYPE tt_pbridge_sys.

  IF lt_pbridge_sys IS NOT INITIAL.
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = 'SYSTEMNAME'
        dynpprog        = sy-cprog
        dynpnr          = sy-dynnr
        dynprofield     = 'P_SYS'
        value_org       = 'S'
      TABLES
        value_tab       = lt_pbridge_sys
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ELSE.
    MESSAGE s160(/psyng/sw) WITH 'No values found'(T13).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  VERIFY_SYSID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_PBRIDGE_SYS  text
*      <--P_GF_SYSID_VALID  text
*----------------------------------------------------------------------*
FORM verify_sysid  USING VALUE(gt_pbridge_sys) TYPE tt_pbridge_sys
                   CHANGING gf_sysid_valid TYPE flag.

  DATA:
        ls_pbridge_sys TYPE /psyng/pbridge_systems.

  READ TABLE gt_pbridge_sys INTO ls_pbridge_sys
                                          WITH KEY systemid = p_sysid.
  IF sy-subrc EQ 0.
    gf_sysid_valid = 'X'.
  ELSE.
    CLEAR gf_sysid_valid.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  VERIFY_SYSNAME
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_PBRIDGE_SYS  text
*      <--P_GF_SYSNAME_VALID  text
*----------------------------------------------------------------------*
FORM verify_sysname  USING VALUE(gt_pbridge_sys) TYPE tt_pbridge_sys
                     CHANGING gf_sysname_valid TYPE flag.

  DATA:
        ls_pbridge_sys TYPE /psyng/pbridge_systems.

  READ TABLE gt_pbridge_sys INTO ls_pbridge_sys
                                          WITH KEY systemname = p_sys.
  IF sy-subrc EQ 0.
    gf_sysname_valid = 'X'.
  ELSE.
    CLEAR gf_sysname_valid.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0101  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0101 OUTPUT.
  SET PF-STATUS 'PF_STATUS_101'.
  SET TITLEBAR 'TITLE_101'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0101  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0101 INPUT.
  g_ucomm = sy-ucomm.
  CASE g_ucomm.
    WHEN 'BACK'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  ALV_0101  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE alv_0101 OUTPUT.

  FIELD-SYMBOLS: <fcat> TYPE lvc_s_fcat.

*--Field catalog
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = '/PSYNG/INCO_OBJECT'
    CHANGING
      ct_fieldcat            = gt_fieldcat1
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  LOOP AT gt_fieldcat1 ASSIGNING <fcat>.
    CASE <fcat>-fieldname.
      WHEN 'ROW_COUNT'.
        <fcat>-scrtext_l = <fcat>-scrtext_m = <fcat>-scrtext_s
                 = <fcat>-reptext = 'Row count'(H01).
      WHEN 'ISSUELOCATION'.
        <fcat>-scrtext_l = <fcat>-scrtext_m = <fcat>-scrtext_s
                         = <fcat>-reptext = 'Issue location'(H02).
      WHEN 'ISSUE'.
        <fcat>-scrtext_l = <fcat>-scrtext_m = <fcat>-scrtext_s
                         = <fcat>-reptext = 'Issue'(H03).
      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.

*--Layout
  gs_layout-zebra = 'X'.
  gs_layout-cwidth_opt = 'X'.

  IF g_alv_grid IS INITIAL.

*  Create Objects
    CREATE OBJECT g_cust_cont
      EXPORTING
        container_name = 'CUST_CONT'.

    CREATE OBJECT g_alv_grid
      EXPORTING
        i_parent = g_cust_cont.

    CALL METHOD g_alv_grid->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
      CHANGING
        it_outtab                     = gt_incmpobj
        it_fieldcatalog               = gt_fieldcat1
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
           WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.


ENDMODULE.

*&---------------------------------------------------------------------*
*&      Form  GET_AUTHVALS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_FUNCTTRAN_TCODE  text
*      -->P_LS_FUNCTTRAN_FUNCTIONID  text
*      -->P_LS_FAOBJ_OBJECT  text
*      -->P_LS_FAOBJ_OBJECT  text
*      <--P_LV_AUTHVALS  text
*      <--P_LT_FAOBJ  text
*----------------------------------------------------------------------*
FORM get_authvals  USING    tcode TYPE tcode
                            functionid TYPE /psyng/function_id
                            object TYPE  /psyng/object
                            field TYPE /psyng/field
                   CHANGING lv_authvals TYPE string
                            lt_faobj TYPE tt_funobj
                            lt_faobj_tmp TYPE tt_funobj.

  DATA:
         ls_faobj TYPE /psyng/faobj2,
         lv_valto TYPE string,
         lv_valfrom TYPE string,
         lf_exist TYPE flag,
         lv_rng TYPE string,
         lt_faobj_copy TYPE tt_funobj.

  lf_exist = 'X'.

  WHILE lf_exist EQ 'X'.

    READ TABLE lt_faobj INTO ls_faobj WITH KEY tcode = tcode
                                               funid = functionid
                                               object = object
                                               field = field.
    IF sy-subrc = 0.

      lv_valfrom = ls_faobj-val_from.
      lv_valto = ls_faobj-val_to.

      IF lv_authvals IS INITIAL.

        IF lv_valfrom IS INITIAL AND lv_valto IS NOT INITIAL.
          lv_authvals = lv_valto.
        ELSEIF lv_valto IS INITIAL AND lv_valfrom IS NOT INITIAL.
          lv_authvals = lv_valfrom.
        ELSE.
          IF lv_valfrom IS NOT INITIAL AND lv_valto IS NOT INITIAL.
            CONCATENATE lv_valfrom
                        lv_valto
                        INTO lv_authvals
                        SEPARATED BY '-'.
          ENDIF.
        ENDIF.

      ELSE.

        IF lv_valfrom IS INITIAL AND lv_valto IS NOT INITIAL.

          CONCATENATE lv_authvals
                      lv_valto
                      INTO lv_authvals
                      SEPARATED BY ','.

        ELSEIF lv_valto IS INITIAL AND lv_valfrom IS NOT INITIAL.

          CONCATENATE lv_authvals
                      lv_valfrom
                      INTO lv_authvals
                      SEPARATED BY ','.

        ELSE.
          CONCATENATE lv_valfrom
                      lv_valto
                      INTO lv_rng
                      SEPARATED BY '-'.

*          CONCATENATE lv_authvals
*                      lv_valfrom
*                      lv_valto
*                      INTO lv_authvals
*                      SEPARATED BY ','.

          CONCATENATE lv_authvals
                      lv_rng
                      INTO lv_authvals
                      SEPARATED BY ','.
        ENDIF.

      ENDIF.

      CLEAR: lv_valfrom, lv_valto.
      DELETE lt_faobj INDEX sy-tabix.
      APPEND ls_faobj TO lt_faobj_tmp.
    ELSE.

      CLEAR lf_exist.

    ENDIF.

  ENDWHILE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CRT_NEW_VERS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_VRSIO  text
*      -->P_P_TEXT  text
*----------------------------------------------------------------------*
FORM crt_new_vers  USING    p_vrsio TYPE /psyng/sodvrsio
                            p_text TYPE char80.

  DATA ls_swsodvers TYPE /psyng/swsodvers.

  ls_swsodvers-vrsio = p_vrsio.
  ls_swsodvers-vdesc = p_text.

  INSERT /psyng/swsodvers FROM ls_swsodvers.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  PREPARE_FILE_FOR_SE_SOD_MATRIX
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM sync_rul_t_plc .

  DATA: lt_conflict TYPE TABLE OF /psyng/conflict,
      lt_confdet  TYPE TABLE OF /psyng/confdet,
      lt_functtran TYPE TABLE OF /psyng/functtran,
      lt_function TYPE TABLE OF /psyng/function,
      lt_faobj     TYPE TABLE OF /psyng/faobj2,
      lt_schema_csv TYPE TABLE OF ty_csv,
      schema_b64 TYPE string,
      lt_group_csv TYPE TABLE OF ty_csv,
      group_b64 TYPE string,
      lt_actmodval_csv TYPE TABLE OF ty_csv,
      actmodval_b64 TYPE string,
      lt_rule_csv TYPE TABLE OF ty_csv,
      rule_b64 TYPE string,
      lt_actvtmod_csv TYPE TABLE OF ty_csv,
      actvtmod_b64 TYPE string,
      lt_grpcmp_csv TYPE TABLE OF ty_csv,
      grpcmp_b64 TYPE string,
      l_schema_count TYPE i,
      l_group_count TYPE i,
      l_rule_count TYPE i,
      l_mode_count TYPE i,
      lt_am TYPE TABLE OF ty_am.

*  Read sod matrix
  CALL FUNCTION '/PSYNG/SW_028'
   EXPORTING
     i_vrsio                  = p_vrsio
     i_orphan_functions       = 'X'
   TABLES
     et_conflict              = lt_conflict
     et_confdet               = lt_confdet
     et_functtran             = lt_functtran
     et_faobj                 = lt_faobj.

*  By default keep risk level medium if no level is defined for conflict
  PERFORM default_risk_level CHANGING lt_conflict.

*  Schemas
  REFRESH: gt_schema, lt_schema_csv.
  CLEAR schema_b64.
  PERFORM schemas CHANGING gt_schema.
  DESCRIBE TABLE gt_schema LINES l_schema_count.
  PERFORM schemas_csv USING gt_schema
                      CHANGING lt_schema_csv.
  PERFORM csv_to_b64 USING lt_schema_csv
                     CHANGING schema_b64.

*  Groups
  REFRESH: gt_group, lt_group_csv.
  CLEAR group_b64.
  PERFORM groups USING lt_confdet p_vrsio
                 CHANGING gt_group.
  DESCRIBE TABLE gt_group LINES l_group_count.
  PERFORM groups_csv USING gt_group
                     CHANGING lt_group_csv.
  PERFORM csv_to_b64 USING lt_group_csv
                     CHANGING group_b64.

*  Rules
  REFRESH: gt_rule, lt_rule_csv.
  CLEAR rule_b64.
  PERFORM rules USING lt_conflict
                      lt_confdet
                CHANGING gt_rule.
  DESCRIBE TABLE gt_rule LINES l_rule_count.
  PERFORM rules_csv USING gt_rule
                    CHANGING lt_rule_csv.
  PERFORM csv_to_b64 USING lt_rule_csv
                     CHANGING rule_b64.

*  Activity Mode
  REFRESH: gt_actvtmod, lt_actvtmod_csv.
  CLEAR actvtmod_b64.
  PERFORM actvtmod USING  lt_functtran
                 CHANGING gt_actvtmod
                          lt_faobj
                          lt_am.
  PERFORM actvtmod_csv USING gt_actvtmod
                          CHANGING lt_actvtmod_csv.
  PERFORM csv_to_b64 USING lt_actvtmod_csv
                     CHANGING actvtmod_b64.


*  Activity Mode Values
  REFRESH: gt_actmodval, lt_actmodval_csv.
  CLEAR actmodval_b64.
  PERFORM act_mod_vals_n USING lt_am
                         CHANGING gt_actmodval.
  DESCRIBE TABLE gt_actmodval LINES l_mode_count.
  PERFORM actmodval_csv USING gt_actmodval
                        CHANGING lt_actmodval_csv.
  PERFORM csv_to_b64 USING lt_actmodval_csv
                     CHANGING actmodval_b64.

*  Group Components
  REFRESH: gt_grpcmp, lt_grpcmp_csv.
  CLEAR grpcmp_b64.
  PERFORM grpcmp USING  lt_functtran
                        lt_am
                 CHANGING gt_grpcmp.
  PERFORM grpcmp_csv USING gt_grpcmp
                          CHANGING lt_grpcmp_csv.
  PERFORM csv_to_b64 USING lt_grpcmp_csv
                     CHANGING grpcmp_b64.
  IF p_sysind EQ 'X'.
* Push system independent data
    CALL FUNCTION '/PSYNG/SW_WRT_RULE_PBRIDGE_SI'
      EXPORTING
        if_schema                 = p_schema
        if_act_grp                = p_group
        if_rules                  = p_rule
        if_rules_ovrwrt           = p_roride
        if_actvt_mod_values       = p_actmod
        i_schema_b64              = schema_b64
        i_group_b64               = group_b64
        i_actmodval_b64           = actmodval_b64
        i_rule_b64                = rule_b64
        l_schema_count            = l_schema_count
        l_rules_count             = l_rule_count
        l_group_count             = l_group_count
        l_mode_count              = l_mode_count
      TABLES
        et_messages               = gt_messages.
  ELSE.
*  Push system dependent data
    CALL FUNCTION '/PSYNG/SW_WRT_RULE_PBRIDGE_SD'
      EXPORTING
        if_actvt_mod             = p_uacmod
        if_actvtmod_ovrwrt       = p_amorde
        if_grp_cmp               = p_grpcmp
        if_grpcmp_ovrwrt         = p_gcorde
        i_actvtmod_b64           = actvtmod_b64
        i_grpcmp_b64             = grpcmp_b64
        i_system                 = p_sys
      TABLES
        et_messages               = gt_messages.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  PULL_FROM_BRIDE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM sync_rul_f_plc .

  DATA: lt_messages_con TYPE TABLE OF bapiret2,
        lt_messages_fun TYPE TABLE OF bapiret2,
        lt_msg_incmpobj TYPE TABLE OF bapiret2,
        lf_success_con TYPE flag,
        lf_success_fun TYPE flag,
        lf_vrsio_exist TYPE flag,
        lt_b_con TYPE TABLE OF /psyng/api_conf,
        lt_b_con_txt TYPE TABLE OF /psyng/api_conf_txt,
        lt_b_con_det TYPE TABLE OF /psyng/api_conf_details,
        lt_b_fun  TYPE TABLE OF /psyng/pbridge_fun,
        lt_b_fun_det TYPE TABLE OF /psyng/pbridge_func_detail,
        lt_b_fun_obj TYPE TABLE OF /psyng/sw_pbridge_fun_obj,
        lt_conflict TYPE TABLE OF /psyng/conflict,
        lt_texts TYPE TABLE OF /psyng/texts,
        lt_confdet TYPE TABLE OF /psyng/confdet,
        lt_function TYPE TABLE OF /psyng/function,
        lt_fundet   TYPE TABLE OF /psyng/functtran,
        lt_funobj   TYPE TABLE OF /psyng/faobj2,
        lv_vrsio TYPE string.

*--Read conflict data from PLC
  IF p_conf = 'X'.
    CALL FUNCTION '/PSYNG/SW_READ_API_CONF'
      EXPORTING
        if_pbridge_con              = gc_true
        if_pbridge_con_txt          = gc_true
        if_pbridge_con_detail       = gc_true
        i_plcvrs                    = p_plcvrs
     IMPORTING
       ef_success                   =  lf_success_con
      TABLES
        et_messages                 = gt_messages
        et_pbridge_con              = lt_b_con
        et_pbridge_con_txt          = lt_b_con_txt
        et_pbridge_con_detail       = lt_b_con_det
      EXCEPTIONS
        no_data_found = 1
        OTHERS         = 2.
    IF sy-subrc <> 0.
      REFRESH: lt_b_con, lt_b_con_txt, lt_b_con_det.
    ENDIF.

    IF lf_success_con = 'X'.

*--Convert PLC ruleset data into SE format
      PERFORM parse_conflict USING lt_b_con[]  lt_b_con_det[]
                            CHANGING lt_conflict[]  lt_confdet[].

*--Dump PLC ruleset data into SE tables
      PERFORM update_conflict_tables USING lt_conflict[] lt_b_con_txt[]
                                            lt_confdet[].
    ENDIF.

  ENDIF.

*--Read function data from PLC
  IF p_func = 'X'.
    CALL FUNCTION '/PSYNG/SW_READ_API_FUNC'
      EXPORTING
        if_pbridge_fun              = gc_true
        if_pbridge_fun_obj          = gc_true
        if_pbridge_fun_detail       = gc_true
        i_sysid                     = p_sysid
        i_plcvrs                    = p_plcvrs
     IMPORTING
       ef_success                  =  lf_success_fun
      TABLES
        et_messages                 = gt_messages "lt_messages_fun
        et_pbridge_fun              = lt_b_fun
        et_pbridge_fun_detail       = lt_b_fun_det
        et_pbridge_fun_obj          = lt_b_fun_obj
      EXCEPTIONS
        no_data_found = 1
        OTHERS         = 2.
    IF sy-subrc <> 0.
      REFRESH : lt_b_fun, lt_b_fun_det, lt_b_fun_obj.
    ENDIF.

    IF lf_success_fun = 'X'.

*--Convert PLC ruleset data into SE format
   PERFORM parse_function USING lt_b_fun[] lt_b_fun_det[] lt_b_fun_obj[]
                         CHANGING lt_function[] lt_fundet[] lt_funobj[].

*--Dump PLC ruleset data into SE tables
      PERFORM update_function_tables USING lt_function[] lt_fundet[]
                                           lt_funobj[].
    ENDIF.

  ENDIF.

*--Read incompatible objects SE from PLC
  IF p_val = 'X'.

    CALL FUNCTION '/PSYNG/SW_INCOMPATIBLE_OBJECTS'
      EXPORTING
        i_sysid            = p_sysid
      TABLES
        et_incom_obj       = gt_incmpobj
        et_return          = gt_messages
      EXCEPTIONS
        no_data_found = 1
        OTHERS         = 2.
    IF sy-subrc <> 0.
      REFRESH: gt_incmpobj.
    ENDIF.

*--ALV to show incompatible objects
    CALL SCREEN 101.

  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  PASS_CONFLICT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM parse_conflict USING    lt_b_con     TYPE tt_pbridge_con

                             lt_b_con_det TYPE tt_pbridge_con_detail
                    CHANGING lt_conflict  TYPE tt_conflict

                             lt_confdet   TYPE tt_confdet.

  DATA: ls_b_con    TYPE /psyng/api_conf,
        ls_conflict TYPE /psyng/conflict,

        ls_b_con_txt TYPE  /psyng/api_conf_txt,
        ls_texts     TYPE /psyng/texts,

        ls_b_con_det TYPE /psyng/api_conf_details,
        ls_confdet   TYPE /psyng/confdet,
        lt_sens TYPE TABLE OF /psyng/swimpsync,
        ls_sens TYPE /psyng/swimpsync,
        lv_plc_imp TYPE /psyng/desc.

*Get mapped senstivities between SE & PLC
  SELECT se_imp plc_imp
    FROM /psyng/swimpsync
    INTO TABLE lt_sens.
  IF sy-subrc <> 0.
    REFRESH lt_sens.
  ENDIF.

  LOOP AT lt_b_con INTO ls_b_con.
    ls_conflict-vrsio = p_vrsio.
    ls_conflict-conid = ls_b_con-conid.
    TRANSLATE ls_conflict-conid TO UPPER CASE.
    ls_conflict-description = ls_b_con-description.

*Senstivity
    lv_plc_imp = ls_b_con-imp. "Character lenght adjustment.
    READ TABLE lt_sens INTO ls_sens WITH KEY plc_imp = lv_plc_imp.
    IF sy-subrc = 0.
      ls_conflict-imp = ls_sens-se_imp.
    ELSE.
*      To be discussed
*      log message
*      Conflict get saved with no senstitivity
*      conflict don't get saved
    ENDIF.
    TRANSLATE ls_conflict-imp TO UPPER CASE.

    ls_conflict-busarea = ls_b_con-busarea.
    ls_conflict-inactive = ls_b_con-inactive.
    ls_conflict-create_usr = sy-uname.
    ls_conflict-create_dat = sy-datum.
    ls_conflict-create_tim = sy-uzeit.
    ls_conflict-change_usr = sy-uname.
    ls_conflict-change_dat = sy-datum.
    ls_conflict-change_tim = sy-uzeit.
    APPEND ls_conflict TO lt_conflict.
    CLEAR ls_conflict.
  ENDLOOP.

  LOOP AT lt_b_con_det INTO ls_b_con_det.
    ls_confdet-vrsio = p_vrsio.
    ls_confdet-conid  = ls_b_con_det-conid.
    TRANSLATE ls_confdet-conid TO UPPER CASE.
    ls_confdet-functionid = ls_b_con_det-functionid.
    TRANSLATE ls_confdet-functionid TO UPPER CASE.
    APPEND ls_confdet TO lt_confdet.
    CLEAR ls_confdet.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  PARSE_FUNCTION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM parse_function  USING    lt_b_fun TYPE tt_pbridge_fun
                              lt_b_fun_det TYPE tt_pbridge_fun_detail
                              lt_b_fun_obj TYPE tt_pbridge_fun_obj
                     CHANGING lt_function TYPE tt_function
                              lt_fundet   TYPE tt_fundet
                              lt_funobj TYPE tt_funobj.

  TYPES: BEGIN OF ty_ffidx,
         function TYPE /psyng/function_id,
         fidx TYPE i,
         END OF ty_ffidx,

         BEGIN OF ty_obj_or,
           funid TYPE /psyng/function_id,
           tcode TYPE tcode,
           object TYPE /psyng/object,
           obj_or(3) TYPE c,
           END OF ty_obj_or,

* Structure for AM count
     BEGIN OF ty_am_count,
         funid TYPE /psyng/function_id,
         tcode TYPE tcode,
         am_count TYPE i,
       END OF ty_am_count.

* Structure for Object count
  TYPES: BEGIN OF ty_obj_count,
           funid TYPE /psyng/function_id,
           tcode TYPE tcode,
           object TYPE /psyng/object,
           obj_count TYPE i,
         END OF ty_obj_count.

  DATA: ls_b_fun     TYPE /psyng/pbridge_fun,
        ls_b_fun_det TYPE /psyng/pbridge_func_detail,
        ls_b_fun_obj TYPE /psyng/sw_pbridge_fun_obj,
        ls_function  TYPE /psyng/function,
        ls_fundet    TYPE /psyng/functtran,
        ls_funobj    TYPE /psyng/faobj2,
        lv_str TYPE string,
        lv_p1 TYPE string,
        lv_p2 TYPE string,
        lt_ffidx TYPE TABLE OF ty_ffidx,
        ls_ffidx TYPE ty_ffidx,
        lv_lastidx TYPE i,
        lv_newidx TYPE string,
        lt_obj_or TYPE TABLE OF ty_obj_or,
        ls_obj_or TYPE ty_obj_or.

  DATA: it_am_count TYPE TABLE OF ty_am_count,
        wa_am_count TYPE ty_am_count.

  DATA: it_obj_count TYPE TABLE OF ty_obj_count,
        wa_obj_count TYPE ty_obj_count.

  DATA: lv_prev_funid TYPE /psyng/function_id,
        lv_prev_tcode TYPE tcode,
        lv_prev_am    TYPE /psyng/value.

  DATA:lt_functtran2 TYPE TABLE OF /psyng/functtran
                  WITH HEADER LINE,
       l_fiori_ids     TYPE string,
      BEGIN OF lt_id OCCURS 0,
          id TYPE i,
        END OF lt_id,
        l_fioriid_index TYPE i,
        l_fiori TYPE /psyng/sw_fioriid,
        lt_functtran    TYPE TABLE OF /psyng/functtran WITH HEADER LINE.

  FIELD-SYMBOLS: <fs_am>  TYPE ty_am_count,
                 <fs_obj> TYPE ty_obj_count.

  LOOP AT lt_b_fun INTO ls_b_fun.
    ls_function-vrsio = p_vrsio.
    ls_function-function = ls_b_fun-function.
    TRANSLATE ls_function-function TO UPPER CASE.
    ls_function-description = ls_b_fun-description.
    ls_function-create_usr = sy-uname.
    ls_function-create_dat = sy-datum.
    ls_function-create_tim = sy-uzeit.
    ls_function-change_usr = sy-uname.
    ls_function-change_dat = sy-datum.
    ls_function-change_tim = sy-uzeit.
    APPEND ls_function TO lt_function.
    CLEAR ls_function.
  ENDLOOP.

  LOOP AT lt_b_fun_det INTO ls_b_fun_det.
    ls_fundet-vrsio = p_vrsio.
    ls_fundet-functionid = ls_b_fun_det-functionid.
    TRANSLATE ls_fundet-functionid TO UPPER CASE.
    IF ls_b_fun_det-tcode CP 'Fiori*'.

      lv_str = ls_b_fun_det-tcode.
      SPLIT lv_str AT space INTO lv_p1 lv_p2.
      l_fiori = lv_p2.

      SELECT * FROM /psyng/functtran INTO
     CORRESPONDING FIELDS OF   TABLE  lt_functtran2 WHERE
               functionid = ls_fundet-functionid
               AND vrsio =  ls_fundet-vrsio
               AND type  = 'F'.

      LOOP AT lt_functtran2.
        SPLIT lt_functtran2-tcode AT '-' INTO lt_functtran2-tcode
      l_fiori_ids.
        IF l_fiori_ids CO '0123456789'.
          lt_id-id = l_fiori_ids.
        ELSEIF strlen( lt_functtran2-fioriid ) > 12 .
          lt_id-id = sy-tabix.
        ENDIF.
        APPEND lt_id.
      ENDLOOP.
      SORT lt_id DESCENDING BY id .
      READ TABLE lt_id INDEX 1.
      l_fioriid_index = lt_id-id.

      SELECT SINGLE mandt FROM /psyng/sw_fioria INTO
         sy-mandt WHERE fioriid = l_fiori.
      IF sy-subrc <> 0.
*        MESSAGE e113(/psyng/sw) WITH
*       'Fiori Id Does not exist'(e50).
*        Log

      ELSE.
        READ TABLE lt_functtran2 WITH KEY
                    fioriid = l_fiori.
        IF sy-subrc = 0.
          ls_fundet-functionid = ls_fundet-functionid.
          ls_fundet-vrsio = ls_fundet-vrsio.
          ls_fundet-fioriid = l_fiori.
          ls_fundet-tcode = lt_functtran2-tcode.
        ELSEIF strlen( l_fiori ) > 12.
          ls_fundet-functionid = ls_fundet-functionid.
          ls_fundet-vrsio = ls_fundet-vrsio.
          ls_fundet-fioriid = l_fiori.
          ADD 1 TO l_fioriid_index.
          l_fiori_ids = l_fioriid_index.
          CONDENSE l_fiori_ids.
          CONCATENATE '/PSYNG/-' l_fiori_ids INTO
                  ls_fundet-tcode.
        ELSE.
          ls_fundet-functionid = ls_fundet-functionid.
          ls_fundet-vrsio = ls_fundet-vrsio.
          ls_fundet-fioriid = l_fiori.
          CONCATENATE '/PSYNG/-' l_fiori INTO
              ls_fundet-tcode.
        ENDIF.
        ls_fundet-type = 'F'. "Fiori
        APPEND ls_fundet TO lt_fundet.
      ENDIF.

****COMMENT START
*****--Store actual name of fiori id in separate variable
****      lv_str = ls_b_fun_det-tcode.
****      SPLIT lv_str AT space INTO lv_p1 lv_p2.
*****--Check for this function last fiori id index
****      CLEAR:lv_newidx, lv_lastidx.
****      LOOP AT lt_ffidx INTO ls_ffidx WHERE function =
****
****ls_fundet-functionid .
****        lv_lastidx = ls_ffidx-fidx.
****      ENDLOOP.
****      lv_newidx = lv_lastidx + 1.
****      CONCATENATE '/PSYNG/-' lv_newidx INTO ls_fundet-tcode.
****      ls_fundet-type = 'F'.
****      ls_fundet-fioriid = lv_p2.
****
****      CLEAR ls_ffidx.
****      ls_ffidx-function = ls_fundet-functionid.
****      ls_ffidx-fidx = lv_newidx.
****      APPEND ls_ffidx TO lt_ffidx.
****COMMENT END

    ELSE.

      ls_fundet-functionid = ls_fundet-functionid.
      ls_fundet-vrsio = ls_fundet-vrsio.
      ls_fundet-tcode = ls_b_fun_det-tcode.
      ls_fundet-type = 'T'.
      APPEND ls_fundet TO lt_fundet.
****      ls_fundet-tcode = ls_b_fun_det-tcode.
****      ls_fundet-type = 'T'.
    ENDIF.
    CLEAR ls_fundet.
****    APPEND ls_fundet TO lt_fundet.
****    CLEAR ls_fundet.
  ENDLOOP.

*AND OR CONVERSION
*---------------------------------------------------------------------*
* Step 1: Count DISTINCT Activity Modes per FUNID + TCODE
*---------------------------------------------------------------------*
  SORT lt_b_fun_obj BY funid tcode act_mod_val.

  LOOP AT lt_b_fun_obj INTO ls_b_fun_obj.

    IF lv_prev_funid NE ls_b_fun_obj-funid OR
       lv_prev_tcode NE ls_b_fun_obj-tcode OR
       lv_prev_am NE ls_b_fun_obj-act_mod_val.

      READ TABLE it_am_count ASSIGNING <fs_am>
        WITH KEY funid = ls_b_fun_obj-funid
                 tcode = ls_b_fun_obj-tcode.

      IF sy-subrc = 0.
        <fs_am>-am_count = <fs_am>-am_count + 1.
      ELSE.
        CLEAR wa_am_count.
        wa_am_count-funid = ls_b_fun_obj-funid.
        wa_am_count-tcode = ls_b_fun_obj-tcode.
        wa_am_count-am_count = 1.
        APPEND wa_am_count TO it_am_count.
      ENDIF.

      lv_prev_funid = ls_b_fun_obj-funid.
      lv_prev_tcode = ls_b_fun_obj-tcode.
      lv_prev_am    = ls_b_fun_obj-act_mod_val.

    ENDIF.

  ENDLOOP.

*---------------------------------------------------------------------*
* Step 2: Count OBJECT occurrences across AM
*---------------------------------------------------------------------*
  SORT lt_b_fun_obj BY funid tcode object act_mod_val.

  CLEAR: lv_prev_funid, lv_prev_tcode, lv_prev_am.

  DATA: lv_prev_object TYPE /psyng/object.

  LOOP AT lt_b_fun_obj INTO ls_b_fun_obj.

    IF lv_prev_funid NE ls_b_fun_obj-funid OR
       lv_prev_tcode NE ls_b_fun_obj-tcode OR
       lv_prev_object NE ls_b_fun_obj-object OR
       lv_prev_am NE ls_b_fun_obj-act_mod_val.

      READ TABLE it_obj_count ASSIGNING <fs_obj>
        WITH KEY funid = ls_b_fun_obj-funid
                 tcode = ls_b_fun_obj-tcode
                 object = ls_b_fun_obj-object.

      IF sy-subrc = 0.
        <fs_obj>-obj_count = <fs_obj>-obj_count + 1.
      ELSE.
        CLEAR wa_obj_count.
        wa_obj_count-funid = ls_b_fun_obj-funid.
        wa_obj_count-tcode = ls_b_fun_obj-tcode.
        wa_obj_count-object = ls_b_fun_obj-object.
        wa_obj_count-obj_count = 1.
        APPEND wa_obj_count TO it_obj_count.
      ENDIF.

      lv_prev_funid = ls_b_fun_obj-funid.
      lv_prev_tcode = ls_b_fun_obj-tcode.
      lv_prev_object = ls_b_fun_obj-object.
      lv_prev_am = ls_b_fun_obj-act_mod_val.

    ENDIF.

  ENDLOOP.

*---------------------------------------------------------------------*
* Step 3: Compare and build output
*---------------------------------------------------------------------*
  LOOP AT it_obj_count INTO wa_obj_count.

    READ TABLE it_am_count INTO wa_am_count
      WITH KEY funid = wa_obj_count-funid
               tcode = wa_obj_count-tcode.

    CLEAR ls_obj_or.
    ls_obj_or-funid = wa_obj_count-funid.
    ls_obj_or-tcode = wa_obj_count-tcode.
    ls_obj_or-object = wa_obj_count-object.

    IF wa_obj_count-obj_count = wa_am_count-am_count.
      CLEAR ls_obj_or-obj_or. " Present in all AM
    ELSE.
      ls_obj_or-obj_or = 'OR'.
    ENDIF.

    APPEND ls_obj_or TO lt_obj_or.

  ENDLOOP.

  LOOP AT lt_b_fun_obj INTO ls_b_fun_obj.
    ls_funobj-vrsio = p_vrsio.
    ls_funobj-funid = ls_b_fun_obj-funid.
    TRANSLATE ls_funobj-funid TO UPPER CASE.
    IF ls_b_fun_obj-tcode CP 'Fiori*'.
      lv_str = ls_b_fun_obj-tcode.
      SPLIT lv_str AT space INTO lv_p1 lv_p2.
      READ TABLE lt_fundet INTO ls_fundet
                        WITH KEY functionid = ls_funobj-funid
                                 fioriid = lv_p2.
      IF sy-subrc = 0.
        ls_funobj-tcode = ls_fundet-tcode.
      ENDIF.
    ELSE.
      ls_funobj-tcode = ls_b_fun_obj-tcode.
    ENDIF.
    ls_funobj-object = ls_b_fun_obj-object.
    ls_funobj-field = ls_b_fun_obj-field.
    ls_funobj-valueset = ls_b_fun_obj-valueset.
    ls_funobj-val_from = ls_b_fun_obj-val_from.
    ls_funobj-val_to = ls_b_fun_obj-val_to.
    CLEAR ls_obj_or.
*    READ TABLE lt_obj_or INTO ls_obj_or WITH KEY funid =
*    ls_funobj-funid
*           tcode = ls_funobj-tcode
*           object = ls_funobj-object.
    READ TABLE lt_obj_or INTO ls_obj_or
               WITH KEY funid = ls_b_fun_obj-funid
                   tcode = ls_b_fun_obj-tcode
                   object = ls_b_fun_obj-object.
    IF sy-subrc = 0.
      ls_funobj-obj_or = ls_obj_or-obj_or.
    ENDIF.

    ls_funobj-fld_and = ls_b_fun_obj-fld_and.
    APPEND ls_funobj TO lt_funobj.
    CLEAR  ls_funobj.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  UPDATE_FUNCTION_TABLES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM update_function_tables  USING lt_function TYPE tt_function
                                   lt_fundet   TYPE tt_fundet
                                   lt_funobj   TYPE tt_funobj.

  DATA:
        ls_function TYPE /psyng/function,
        lt_fundet_tmp TYPE TABLE OF /psyng/functtran,
        lt_funobj_tmp TYPE TABLE OF /psyng/faobj2,
        lf_ins_upd(1)   TYPE c,
        lt_texts TYPE TABLE OF /psyng/texts,
        ls_texts TYPE /psyng/texts.

  LOOP AT lt_function INTO ls_function.
    lt_fundet_tmp = lt_fundet.
    lt_funobj_tmp = lt_funobj.
    DELETE lt_fundet_tmp WHERE functionid <> ls_function-function.
    DELETE lt_funobj_tmp WHERE funid <> ls_function-function.

    ls_texts-vrsio = ls_function-vrsio.
    ls_texts-object = 'F'.
    ls_texts-spras = 'E'.
    ls_texts-text = ls_function-description.
    ls_texts-textname = ls_function-function.
    APPEND ls_texts TO lt_texts.
    CLEAR ls_texts.

    CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
            EXPORTING
              wa_function             = ls_function
              i_vrsio                 = p_vrsio
            IMPORTING
              funid_added             = lf_ins_upd
            TABLES
              texts                   = lt_texts
              functtran               = lt_fundet_tmp
              faobj                   = lt_funobj_tmp
            EXCEPTIONS
              target_not_specified    = 1
              not_authorized          = 2
              function_already_exists = 3
              OTHERS                  = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    REFRESH: lt_fundet_tmp, lt_funobj_tmp, lt_texts.
    CLEAR ls_function.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  UPDATE_CONFLICT_TABLES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM update_conflict_tables  USING lt_conflict  TYPE tt_conflict
                                   lt_b_con_txt TYPE tt_pbridge_con_txt
                                   lt_confdet   TYPE tt_confdet.

  DATA:
        ls_conflict TYPE /psyng/conflict,
        lt_confdet_tmp TYPE TABLE OF /psyng/confdet,
        lf_ins_upd(1)   TYPE c,
        ls_texts TYPE /psyng/texts,
        lt_texts TYPE TABLE OF /psyng/texts,
        lt_conowner   TYPE TABLE OF /psyng/conowner,
        ls_conowner TYPE /psyng/conowner,
        ls_b_con_txt TYPE /psyng/api_conf_txt.

  LOOP AT lt_conflict INTO ls_conflict.
    lt_confdet_tmp = lt_confdet.
    DELETE lt_confdet_tmp WHERE conid <> ls_conflict-conid.

    ls_texts-vrsio = ls_conflict-vrsio.
    ls_texts-object = 'C'.
    ls_texts-spras = 'E'.

    READ TABLE lt_b_con_txt INTO ls_b_con_txt
                              WITH KEY conid = ls_conflict-conid.
    IF sy-subrc = 0.
      ls_texts-text = ls_b_con_txt-text.
    ELSE.
      CLEAR ls_texts-text.
    ENDIF.

    ls_texts-textname = ls_conflict-conid.
    APPEND ls_texts TO lt_texts.
    CLEAR ls_texts.

    ls_conowner-vrsio = p_vrsio.
    ls_conowner-conid = ls_conflict-conid.
    ls_conowner-owner = ls_conflict-owner.
    APPEND ls_conowner TO lt_conowner.
    CLEAR ls_conowner.

    CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
      EXPORTING
        wa_conflict           = ls_conflict
        i_vrsio               = p_vrsio
      IMPORTING
        conid_added           = lf_ins_upd
      TABLES
        texts                 = lt_texts
        confdet               = lt_confdet_tmp
        conowner              = lt_conowner
      EXCEPTIONS
        target_not_specified  = 1
        target_already_exists = 2
        not_authorized        = 3
        locked                = 4
        OTHERS                = 5.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    REFRESH: lt_confdet_tmp, lt_texts, lt_conowner.
    CLEAR ls_conflict.
  ENDLOOP.


ENDFORM.

*---------------------------------------------------------------------*
*       FORM PULL_LOGS_CLICK                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM logs_click USING r_ucomm LIKE sy-ucomm
                                       rs_selfield TYPE slis_selfield.

  DATA: ls_messages TYPE bapiret2,
        lv_msg TYPE string,
        lv_repid TYPE sy-repid.

  lv_repid = sy-repid.
  g_layout-colwidth_optimize = 'X'.
  REFRESH: gt_fieldcat, gt_top.

  CASE rs_selfield-fieldname.
    WHEN 'DETAIL'.
      CHECK rs_selfield-value <> space.

      READ TABLE gt_messages INTO ls_messages INDEX
                                                 rs_selfield-tabindex.
      lv_msg = ls_messages-message.

      IF lv_msg CS 'Function'(001).

        SELECT SINGLE mandt
                      FROM /psyng/conflict
                      INTO sy-mandt
                      WHERE vrsio    =  p_vrsio.
        IF sy-subrc = 0.
          SUBMIT /psyng/sw_sodmatrix_overview
                             WITH p_vrsio = p_vrsio
                             WITH p_fundet = 'X'
                             AND RETURN.
        ELSE.
          MESSAGE e160(/psyng/sw) WITH
         'Conflicts does not exists for pulled functions'(193).
        ENDIF.

      ELSEIF lv_msg CS 'Conflict'(002).

        SELECT SINGLE mandt
                      FROM
                      /psyng/functtran
                      INTO sy-mandt
                      WHERE vrsio =  p_vrsio.
        IF sy-subrc = 0.
          SUBMIT /psyng/sw_sodmatrix_overview
                               WITH p_vrsio = p_vrsio
                               WITH p_confun = 'X'
                               AND RETURN.
        ELSE.
          MESSAGE e160(/psyng/sw) WITH
              'Functions does not exists for pulled conflicts'(194).
        ENDIF.

      ELSEIF lv_msg CS 'Schema'(165).
        add_column: 'SCHEMA_NAME' 'Schema'(165) gt_fieldcat.
        add_header: 'H' 'Uploaded Schemas'(003).
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
         EXPORTING
           i_callback_program                 = lv_repid
            it_fieldcat                       = gt_fieldcat
            is_layout                         = g_layout
            i_callback_top_of_page            = 'TOP'
          TABLES
            t_outtab                          = gt_schema
          EXCEPTIONS
            program_error      = 1
            OTHERS             = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

      ELSEIF lv_msg CS 'Activity group'(004).
        add_column: 'GROUP' 'Group'(159) gt_fieldcat.
        add_column: 'DESCRIPTION' 'Description'(178) gt_fieldcat.
        add_column: 'TYPE' 'Type'(005) gt_fieldcat.
        add_header: 'H' 'Uploaded Activity group'(006).
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
         EXPORTING
           i_callback_program                 = lv_repid
            it_fieldcat                       = gt_fieldcat
            is_layout                         = g_layout
            i_callback_top_of_page            = 'TOP'
          TABLES
            t_outtab                          = gt_group
          EXCEPTIONS
            program_error      = 1
            OTHERS             = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

      ELSEIF lv_msg CS 'Rules'(007).
        add_column: 'CMB_NAME' 'Rules'(007) gt_fieldcat.
        add_column: 'CMB_DES' 'Description'(178) gt_fieldcat.
        add_column: 'RISK_LEV' 'Risk Level'(162) gt_fieldcat.
        add_column: 'RISK_DES' 'Risk Description'(163) gt_fieldcat.
        add_column: 'PRCS_CTRL' 'Process Control'(164) gt_fieldcat.
        add_column: 'SCHEMA' 'Schema'(165) gt_fieldcat.
        add_column: 'OBJ1' 'Object'(008) gt_fieldcat.
        add_column: 'OBJ1_TYPE' 'Object Type'(166) gt_fieldcat.
        add_column: 'OBJ2' 'Object'(008) gt_fieldcat.
        add_column: 'OBJ2_TYPE' 'Object Type'(166) gt_fieldcat.
        add_column: 'OBJ3' 'Object'(008) gt_fieldcat.
        add_column: 'OBJ3_TYPE' 'Object Type'(166) gt_fieldcat.
        add_column: 'OBJ4' 'Object'(008) gt_fieldcat.
        add_column: 'OBJ4_TYPE' 'Object Type'(166) gt_fieldcat.
        add_column: 'OBJ5' 'Object'(008) gt_fieldcat.
        add_column: 'OBJ5_TYPE' 'Object Type'(166) gt_fieldcat.
        add_header: 'H' 'Uploaded Rules'(009).
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
         EXPORTING
           i_callback_program                 = lv_repid
            it_fieldcat                       = gt_fieldcat
            is_layout                         = g_layout
            i_callback_top_of_page            = 'TOP'
          TABLES
            t_outtab                          = gt_rule
          EXCEPTIONS
            program_error      = 1
            OTHERS             = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

      ELSEIF lv_msg CS 'mode values'(010).
        add_column: 'ACTMODVAL' 'Activity Mode Value'(158) gt_fieldcat.
        add_header: 'H' 'Uploaded Activity Mode Value'(158).
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
         EXPORTING
           i_callback_program                 = lv_repid
            it_fieldcat                       = gt_fieldcat
            is_layout                         = g_layout
            i_callback_top_of_page            = 'TOP'
          TABLES
            t_outtab                          = gt_actmodval
          EXCEPTIONS
            program_error      = 1
            OTHERS             = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

      ELSEIF lv_msg CS 'Activity mode'(011).
        add_column: 'ACTVT' 'Activity'(168) gt_fieldcat.
        add_column: 'ACTVTMOD' 'Activity Mode'(169) gt_fieldcat.
        add_column: 'AUTHOBJ' 'Authorization Object'(170) gt_fieldcat.
        add_column: 'AUTHFIELD' 'Authorization Field'(171) gt_fieldcat.
        add_column: 'AUTHVAL' 'Authorization Value'(172) gt_fieldcat.
        add_column: 'ACTVTDES' 'Activity Description'(173) gt_fieldcat.
        add_column: 'SYS' 'System'(174) gt_fieldcat.
        add_header: 'H' 'Uploaded Activity Mode'(012).
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
         EXPORTING
           i_callback_program                 = lv_repid
            it_fieldcat                       = gt_fieldcat
            is_layout                         = g_layout
            i_callback_top_of_page            = 'TOP'
          TABLES
            t_outtab                          = gt_actvtmod
          EXCEPTIONS
            program_error      = 1
            OTHERS             = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

      ELSEIF lv_msg CS 'components'(013).
        add_column: 'GRP' 'Group'(159) gt_fieldcat.
        add_column: 'ACTVT' 'Activity'(168) gt_fieldcat.
        add_column: 'ACTVTMOD' 'Activity Mode'(169) gt_fieldcat.
        add_column: 'ACTVTDES' 'Activity Description'(173) gt_fieldcat.
        add_column: 'APPAREA' 'Application Area'(176) gt_fieldcat.
        add_column: 'ACTVTGRPTYP' 'Activity Group Type'(015)
gt_fieldcat.
        add_column: 'DESC' 'Description'(178) gt_fieldcat.
        add_column: 'SYS' 'System'(174) gt_fieldcat.
        add_header: 'H' 'Uploaded Group Components'(016).
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
         EXPORTING
           i_callback_program                 = lv_repid
            it_fieldcat                       = gt_fieldcat
            is_layout                         = g_layout
            i_callback_top_of_page            = 'TOP'
          TABLES
            t_outtab                          = gt_grpcmp
          EXCEPTIONS
            program_error      = 1
            OTHERS             = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ELSEIF lv_msg CS 'Mitigation definitions'.
        add_column: 'CONTID' 'Mitigation Control ID' gt_fieldcat.
        add_column: 'DESCRIPTION' 'Short Desription' gt_fieldcat.
        add_header: 'H' 'Uploaded Mitigation Definitions'.
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
                 EXPORTING
                   i_callback_program                 = lv_repid
                    it_fieldcat                       = gt_fieldcat
                    is_layout                         = g_layout
                    i_callback_top_of_page            = 'TOP'
                  TABLES
                    t_outtab                          = gt_mchdr
                  EXCEPTIONS
                    program_error      = 1
                    OTHERS             = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ELSEIF lv_msg CS 'control headers'.
        add_column: 'CONTID' 'Control ID' gt_fieldcat.
        add_column: 'STATUS' 'Status' gt_fieldcat.
        add_header: 'H' 'Pulled Mitigation Definitions'.
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
                 EXPORTING
                   i_callback_program                 = lv_repid
                    it_fieldcat                       = gt_fieldcat
                    is_layout                         = g_layout
                    i_callback_top_of_page            = 'TOP'
                  TABLES
                    t_outtab                          = gt_md_logs
                  EXCEPTIONS
                    program_error      = 1
                    OTHERS             = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ELSEIF lv_msg CS 'Mitigation assignments'.
        add_column: 'USERID' 'Employee ID' gt_fieldcat.
        add_column: 'CONID' 'Combination Name' gt_fieldcat.
        add_column: 'FROM_DATE' 'Approved From' gt_fieldcat.
        add_column: 'TO_DATE' 'Approved Untill' gt_fieldcat.
        add_header: 'H' 'Push Mitigation assignments'.
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
                 EXPORTING
                   i_callback_program                 = lv_repid
                    it_fieldcat                       = gt_fieldcat
                    is_layout                         = g_layout
                    i_callback_top_of_page            = 'TOP'
                  TABLES
                    t_outtab                          = gt_mcuser
                  EXCEPTIONS
                    program_error      = 1
                    OTHERS             = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ELSEIF lv_msg CS 'control assignments'.
        add_column: 'EMPLOYEEID' 'Employee ID' gt_fieldcat.
        add_column: 'RISK' 'Combination Name' gt_fieldcat.
        add_column: 'CONTROL' 'Mitigation Control' gt_fieldcat.
        add_column: 'DONEBY' 'Auditor' gt_fieldcat.
        add_column: 'STATUS' 'Status' gt_fieldcat.
        add_header: 'H' 'Pull Mitigation assignments'.
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
                 EXPORTING
                   i_callback_program                 = lv_repid
                    it_fieldcat                       = gt_fieldcat
                    is_layout                         = g_layout
                    i_callback_top_of_page            = 'TOP'
                  TABLES
                 t_outtab                          = gt_ma_pull_logs
               EXCEPTIONS
                 program_error      = 1
                 OTHERS             = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDIF.
  ENDCASE.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SET_BUTTON_ICONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_button_icons .

  PERFORM init_but USING 'BGD_BUT'  'X' CHANGING bgd_but .


  PERFORM handle_sections.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  init_but
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_USER_BUT  text
*      <--P_'USER_BUT'  text
*      <--P_'X'  text
*----------------------------------------------------------------------*
FORM init_but USING    i_name
                       i_default_expanded
              CHANGING i_button.

  DATA : ls_state TYPE /psyng/usr_displ,
         l_exp    TYPE flag.
  SELECT SINGLE * INTO ls_state
  FROM /psyng/usr_displ
  WHERE
    bname = g_current_user AND"sy-uname AND C0700
    repid = sy-repid AND
  button_name = i_name.
  IF sy-subrc = 0.
    l_exp = ls_state-expanded.
  ELSE.
    l_exp = i_default_expanded.
  ENDIF.

  IF l_exp = 'X'.
    PERFORM expand CHANGING i_button.
  ELSE.
    PERFORM collapse CHANGING i_button.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  expand
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM expand CHANGING button.
*--Set user button Icon
  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name       = 'ICON_COLLAPSE'
      add_stdinf = ''
    IMPORTING
      result     = button
*BOC:HBHALLA (19/12/24)
        EXCEPTIONS
             icon_not_found = 1
             outputfield_too_short = 2
             OTHERS     = 3.
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE s002(/psyng/sw)
     WITH 'Icon name unknown to system'.
      WHEN 2.
        MESSAGE s002(/psyng/sw)
     WITH 'Length of field (RESULT) is too small'.
      WHEN OTHERS.
        MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
    ENDCASE.
  ENDIF.
*EOC:HBHALLA (19/12/24)
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  collapse
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_REM_BUT  text
*----------------------------------------------------------------------*
FORM collapse CHANGING    button.

  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name       = 'ICON_EXPAND'
      add_stdinf = ''
    IMPORTING
      result     = button
"(++)BOC AKUMAR SE VF scan-19/12/2024
    EXCEPTIONS
      icon_not_found = 1
      outputfield_too_short = 2
      OTHERS     = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC AKUMAR SE VF scan-19/12/2024.

ENDFORM.                    " collapse
*&---------------------------------------------------------------------*
*&      Form  handle_sections
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_sections.
  PERFORM handle_section USING  bgd_but  'BGD'.
ENDFORM.                    " handle_sections
*---------------------------------------------------------------------*
*       FORM toggle_section                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_BUTTON                                                      *
*  -->  I_SECTION_NAME                                                *
*---------------------------------------------------------------------*
FORM handle_section USING    i_button
                             i_section_name.
  DATA : l_collapse TYPE flag.

  LOOP AT SCREEN .
    IF screen-group1 = i_section_name.
      IF i_button(3) <> '@3T'.
        screen-invisible = 1.
        screen-active    = 0.
        l_collapse = 'X'.
      ELSE.
        screen-invisible = 0.
        screen-active    = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.


ENDFORM.                    " toggle_section
*&---------------------------------------------------------------------*
*&      Form  HANDLE_BUTTON
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_button .
  CASE g_ucomm.
    WHEN 'BGD_BUT'.
      PERFORM toggle USING bgd_but 'BGD_BUT'.
  ENDCASE.
  CLEAR g_ucomm.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM toggle                                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_BUTTON                                                      *
*---------------------------------------------------------------------*
FORM toggle USING i_button i_name.
  DATA : ls_state TYPE /psyng/usr_displ.
  ls_state-repid       = sy-repid.
  ls_state-bname       = g_current_user."sy-uname. C0700
  ls_state-screen      = '1000'.
  ls_state-button_name = i_name.
  ls_state-group_name  = i_name.
  ls_state-ucomm       = g_ucomm.

  IF i_button(3) <> '@3T'.
    PERFORM expand USING i_button.
    ls_state-expanded = 'X'.
    CLEAR g_button_set.
  ELSE.
    PERFORM collapse USING i_button.
    CLEAR  ls_state-expanded.
    g_button_set = 'X'.
  ENDIF.
  MODIFY /psyng/usr_displ FROM ls_state.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SCHEDULE_BACK_JOB
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM schedule_back_job .

  DATA: curr_report LIKE rsvar-report,
        l_jobname   TYPE btcjob.

  CLEAR: curr_report, g_curr_variant.
  PERFORM create_variant_from_sel.
  curr_report = sy-repid.
  g_curr_variant = g_variant.

  IF p_pull = 'X'.
    l_jobname = 'SE-Pathlock Bridge ruleset synch job - Pull'(L01).
  ELSE.
    l_jobname = 'SE-Pathlock Bridge ruleset synch job - Push'(L02).
  ENDIF.

  CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
    EXPORTING
      in_jobname  = l_jobname
      in_repvarnt = g_curr_variant
      in_report   = curr_report.
  IF sy-subrc <> 0.
    CALL SCREEN 1000.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CREATE_VARIANT_FROM_SEL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_variant_from_sel .
  DATA: curr_report LIKE rsvar-report.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab.
  curr_report = sy-repid.
  g_curr_variant = g_variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
    EXPORTING
      curr_report   = curr_report
      curr_variant  = g_curr_variant
      vari_desc     = g_vari_desc
    TABLES
      vari_contents = g_vari_contents
      vari_text     = g_vari_text
*BOC:HBHALLA (19/12/24)
    EXCEPTIONS
      illegal_report_or_variant = 1
      illegal_variantname       = 2
      not_authorized            = 3
      not_executed              = 4
      report_not_existent       = 5
      report_not_supplied       = 6
      variant_exists            = 7
      variant_locked            = 8
      OTHERS                    = 9.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
*EOC:HBHALLA (19/12/24)
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_NEXT_VARIANT_ID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_next_variant_id .
  CLEAR: g_variant, g_vari_desc.
  REFRESH: g_vari_desc.
  CALL FUNCTION '/PSYNG/BASIS_GET_RPT_VARIANT'
    EXPORTING
      i_report        = sy-repid
   IMPORTING
     e_variant       = g_variant.

  g_vari_desc-report = sy-repid.
  g_vari_desc-variant = g_variant.
  APPEND g_vari_desc.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FILL_SEL_SCREEN_FIELDS_TO_TAB
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab .
  REFRESH : gt_irsparams[].
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
    EXPORTING
      i_repid       = g_program
      if_no_logging = 'X'
    TABLES
      et_params     = gt_irsparams.
ENDFORM.

FORM top.
  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary       = gt_top.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  PUSH_MITIGATION_CONTROLS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM sync_mc_t_plc .

*  Push mitigation controls
  CALL FUNCTION '/PSYNG/SW_PUSH_MIT_CONT_PLC'
   EXPORTING
     i_control_headers       = p_mc_d1
     i_control_assign        = p_mc_a1
     i_vrsio                 = p_vrsio
   TABLES
     et_messages             = gt_messages
     et_mchdr                = gt_mchdr
     et_mcuser               = gt_mcuser.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  PULL_MITIGATION_CONTROLS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM sync_mc_f_plc .

  DATA: lt_mc_head_plc TYPE /psyng/sw_mit_cont_head_plc_tt,
        ls_mc_head_plc TYPE /psyng/sw_mit_cont_header_plc,
        ls_md_logs TYPE ty_md_pull_logs,
        lt_mc_assign TYPE /psyng/sw_mit_emp_vlation_tt,
        ls_mc_assign TYPE /psyng/sw_mit_emp_vlation_plc,
        lt_mcuser   TYPE TABLE OF /psyng/mcuser,
        ls_mcuser TYPE /psyng/mcuser,
        trim_date TYPE char10,
        year TYPE char4,
        month TYPE char2,
        date TYPE char2,
        valid_from TYPE char12,
        valid_to TYPE char12,
        l_conid TYPE /psyng/conflict-conid,
        l_flag TYPE flag,
l_approver TYPE /psyng/mchdr-approver,
ls_ma_pull_logs TYPE ty_ma_pull_logs.


*  Get mitigation controls from PLC
  CALL FUNCTION '/PSYNG/SW_PULL_MIT_CONT_PLC'
   EXPORTING
     i_control_headers          = p_mc_def
     i_control_assign           = p_mc_ass
   IMPORTING
     et_mit_cont_head_plc       = lt_mc_head_plc
     et_mit_cont_assign         = lt_mc_assign
   TABLES
     et_messages                = gt_messages.

*  Pull Mitigatin definition requested
  IF p_mc_def EQ 'X'.

    DATA: ls_mchdr TYPE /psyng/mchdr,
          lt_texts TYPE TABLE OF /psyng/texts,
          ls_texts TYPE /psyng/texts,
          lt_text_table TYPE soli_tab,
          ls_text       TYPE soli,
          lv_long_desc TYPE string.


    LOOP AT lt_mc_head_plc INTO ls_mc_head_plc.

*  Header information
      ls_mchdr-contid = ls_mc_head_plc-control.
      TRANSLATE ls_mchdr-contid TO UPPER CASE.
      ls_mchdr-description = ls_mc_head_plc-shortdesc.
      IF ls_mc_head_plc-isactive IS INITIAL.
        ls_mchdr-inactive = 'X'.
      ELSE.
        CLEAR ls_mchdr-inactive.
      ENDIF.


*  Long description
      REFRESH lt_text_table.
      lv_long_desc = ls_mc_head_plc-longdesc. "Type conversion
      ls_texts-textname = ls_mchdr-contid.
      CALL FUNCTION '/PSYNG/SW_CONVERT_STR_TO_TABLE'
       EXPORTING
         i_string         = lv_long_desc
         i_tabline_length = 80
       TABLES
         et_table         = lt_text_table.

      LOOP AT lt_text_table INTO ls_text.
        ls_texts-text = ls_text-line.
        APPEND ls_texts TO lt_texts.
      ENDLOOP.
      CLEAR ls_texts.

      ls_md_logs-contid = ls_mchdr-contid.

*  Save mitigation control
      CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
        EXPORTING
          is_mchdr             = ls_mchdr
        TABLES
          it_texts             = lt_texts
        EXCEPTIONS
          target_not_specified = 1
          not_authorized       = 2
          locked               = 3
          OTHERS               = 4.
      CASE sy-subrc.
        WHEN 0.
          ls_md_logs-status = 'Saved'.
        WHEN 1 OR 4.
          ls_md_logs-status = 'Not Saved'.
        WHEN 2.
          ls_md_logs-status = 'Not Authorized To Change'.
        WHEN 3.
          ls_md_logs-status = 'Locked'.
      ENDCASE.

      APPEND ls_md_logs TO gt_md_logs.
      CLEAR ls_md_logs-status.
    ENDLOOP.
  ENDIF.

*  Pull Mitigatin assignments requested
  IF p_mc_ass EQ 'X'.

    CLEAR ls_mchdr.
    LOOP AT lt_mc_assign INTO ls_mc_assign.

      MOVE-CORRESPONDING ls_mc_assign TO ls_ma_pull_logs.

      REFRESH lt_mcuser.

      ls_mchdr-contid = ls_mc_assign-control. "Existance check

      ls_mcuser-userid = ls_mc_assign-employeeid. "Existance check

      ls_mcuser-conid = ls_mc_assign-risk. "Existance check

      ls_mcuser-contid = ls_mc_assign-control.

      trim_date = ls_mc_assign-validfrom(10).
      year = trim_date(4).
      month = trim_date+5(2).
      date = trim_date+8(2).
      CONCATENATE year month date INTO valid_from.
      ls_mcuser-from_date = valid_from.

      trim_date = ls_mc_assign-validto(10).
      year = trim_date(4).
      month = trim_date+5(2).
      date = trim_date+8(2).
      CONCATENATE year month date INTO valid_to.
      ls_mcuser-to_date = valid_to.

      ls_mcuser-vrsio = p_vrsio.

      ls_mcuser-auditor = ls_mc_assign-approvedby. "Existance check

      TRANSLATE ls_mcuser-auditor TO UPPER CASE.

*Mandatory fields check
      IF ls_mchdr-contid IS INITIAL OR ls_mcuser-from_date IS INITIAL
                 OR ls_mcuser-to_date IS INITIAL
                 OR ls_mcuser-userid IS INITIAL.
        ls_ma_pull_logs-status = 'Some mandatory fields are blank'.
        l_flag = 'X'.
      ELSE.
*Mitigation control check
        SELECT SINGLE approver INTO l_approver
                FROM /psyng/mchdr
                      WHERE contid = ls_mchdr-contid.
        IF sy-subrc <> 0.
          ls_ma_pull_logs-status = 'Log control does not exist in SE'.
          l_flag = 'X'.
        ELSE.
         IF ls_mcuser-userid = l_approver AND NOT l_approver IS INITIAL.
        ls_ma_pull_logs-status = 'User ID and approver can not be same'.
            l_flag = 'X'.
          ELSE.
*Auditor check
            IF NOT ls_mcuser-auditor IS INITIAL.
              "Check that user ID is not the same as the auditor ID
              IF ls_mcuser-userid = ls_mcuser-auditor.
        ls_ma_pull_logs-status = 'log user and auditor can not be same'.

                l_flag = 'X'.
              ELSE.
                CALL FUNCTION 'SUSR_USER_CHECK_EXISTENCE'
                  EXPORTING
                   user_name            = ls_mcuser-auditor
                  EXCEPTIONS
                   user_name_not_exists = 1
                  OTHERS               = 2.
                IF sy-subrc NE 0.
            ls_ma_pull_logs-status = 'Auditor does not exist in system'.
                  l_flag = 'X'.
                ELSE.
*Risk check
                  SELECT SINGLE conid INTO l_conid
                                  FROM /psyng/conflict
                                        WHERE vrsio = p_vrsio.
                  IF sy-subrc NE 0.
            ls_ma_pull_logs-status = 'Conflict does in exist in matrix'.
                    l_flag = 'X'.
                  ENDIF.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

      IF l_flag NE 'X'.

        APPEND ls_mcuser TO lt_mcuser.
        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
             EXPORTING
               is_mchdr             = ls_mchdr
               if_add_assgn_only    = 'X'
             TABLES
               it_mcuser            = lt_mcuser
             EXCEPTIONS
               target_not_specified  = 1
               not_authorized        = 2
               locked                = 3
               OTHERS                = 6.
        IF sy-subrc = 0.
          ls_ma_pull_logs-status = 'Saved'.
        ELSE.
          ls_ma_pull_logs-status = 'Not saved'.
        ENDIF.
      ENDIF.
      APPEND ls_ma_pull_logs TO gt_ma_pull_logs.

      CLEAR: ls_mcuser, l_flag, ls_ma_pull_logs.
    ENDLOOP.

  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_PLCVRS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f4_plcvrs .

  DATA: lt_plcvrs TYPE TABLE OF /psyng/sw_plcrset.

*--Get list of ruleset ID maintained in PLC
  CALL FUNCTION '/PSYNG/SW_GET_PLC_RULESET_IDS'
   IMPORTING
     et_plc_rsets       = lt_plcvrs
   EXCEPTIONS
     no_data_found = 1
     OTHERS         = 2.
  IF sy-subrc <> 0.
    REFRESH lt_plcvrs.
  ENDIF.

*--Call search help FM
  IF lt_plcvrs IS NOT INITIAL.
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = 'RULESETID'
        dynpprog        = sy-cprog
        dynpnr          = sy-dynnr
        dynprofield     = 'P_PLCVRS'
        value_org       = 'S'
      TABLES
        value_tab       = lt_plcvrs
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ELSE.
    MESSAGE s160(/psyng/sw) WITH 'No values found'(T13).
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ACT_MOD_VALS_N
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_AM  text
*      <--P_GT_ACTMODVAL  text
*----------------------------------------------------------------------*
FORM act_mod_vals_n  USING   lt_am TYPE tt_am
                     CHANGING lt_actmodval TYPE tt_actmodval.

  DATA:
          ls_actmodval TYPE ty_actmodval,
          ls_am TYPE ty_am.

  LOOP AT lt_am INTO ls_am.
    ls_actmodval-actmodval = ls_am-am.
    APPEND ls_actmodval TO lt_actmodval.
    CLEAR ls_actmodval.
  ENDLOOP.

  SORT lt_actmodval BY actmodval.
  DELETE ADJACENT DUPLICATES FROM lt_actmodval COMPARING actmodval.

  CLEAR: ls_actmodval, ls_am.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_NEW_MODE_NAME
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_FUNCTTRAN_FUNCTIONID  text
*      -->P_LS_FUNCTTRAN_TCODE  text
*      <--P_LS_ACTVTMOD_ACTVTMOD  text
*      <--P_LT_AM  text
*----------------------------------------------------------------------*
FORM get_new_mode_name  USING  funid TYPE /psyng/function_id
                               tcode TYPE tcode
                        CHANGING ls_actvtmod_actvtmod TYPE string
                                 lt_am TYPE tt_am.

  DATA: lv_rcount TYPE i,
        ls_am TYPE ty_am,
        lv_count(3) TYPE c. "length changed to 3

  LOOP AT lt_am INTO ls_am WHERE funid = funid.
    ADD 1 TO lv_rcount.
  ENDLOOP.
  ADD 1 TO lv_rcount.
  lv_count = lv_rcount.
  CONDENSE lv_count NO-GAPS.
  CONCATENATE funid lv_count INTO ls_actvtmod_actvtmod
  SEPARATED BY '_'.
  ls_am-funid = funid.
  ls_am-tcode = tcode.
  ls_am-am = ls_actvtmod_actvtmod.
  APPEND ls_am TO lt_am.

ENDFORM.
