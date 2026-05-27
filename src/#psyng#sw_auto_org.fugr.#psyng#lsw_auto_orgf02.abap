*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/LSW_AUTO_ORGF02                                     *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  sw125_filter_matrix
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
FORM sw125_filter_matrix
TABLES
  it_confdet     STRUCTURE /psyng/confdet
  it_functtran   STRUCTURE /psyng/functtran
  it_faobj       STRUCTURE /psyng/faobj2
  et_confdet     STRUCTURE /psyng/confdet
  et_functtran   STRUCTURE /psyng/functtran
  et_faobj       STRUCTURE /psyng/faobj2
USING
  i_conid        TYPE /psyng/conflict_id
  i_vrsio        TYPE /psyng/sodvrsio
  i_summary      TYPE flag
  i_rewrite_type TYPE string
  i_field        TYPE xufield
.

  TYPES :
   BEGIN OF t_conflicts,
      vrsio     TYPE /psyng/sodvrsio,
      conid     TYPE /psyng/conflict_id,
      type      TYPE string,
      field     TYPE xufield,
      confdet   TYPE STANDARD TABLE OF /psyng/confdet WITH DEFAULT KEY,
      faobj     TYPE STANDARD TABLE OF /psyng/faobj2 WITH DEFAULT KEY,
      functtran TYPE STANDARD TABLE OF /psyng/functtran
                     WITH DEFAULT KEY,
   END OF t_conflicts.
  STATICS :
    st_conflicts TYPE HASHED TABLE OF t_conflicts
                 WITH UNIQUE KEY vrsio conid type field
                 WITH HEADER LINE.
  REFRESH : et_faobj[],et_confdet[],et_functtran[].

*--Get from buffer if possible
  READ TABLE st_conflicts WITH TABLE KEY
    vrsio = i_vrsio
    conid = i_conid
    type  = i_rewrite_type
    field = i_field.
  IF sy-subrc = 0.
    et_faobj[]     = st_conflicts-faobj[].
    et_confdet[]   = st_conflicts-confdet[].
    et_functtran[] = st_conflicts-functtran[].

  ELSE.
*--take what we need from the SOD matrix
    IF i_summary <> 'X'.
*--In detailed view, we only have the faobj table, and not other details
      SELECT * FROM /psyng/confdet
      INTO TABLE it_confdet
      WHERE
        vrsio = i_vrsio AND
        conid = i_conid
        .
      IF NOT it_confdet[] IS INITIAL.
        SELECT * FROM /psyng/functtran
        INTO TABLE it_functtran
        FOR ALL ENTRIES IN it_confdet
          WHERE
          vrsio       = i_vrsio AND
          functionid =  it_confdet-functionid
          .
      ENDIF.
    ENDIF.
*--All data for all three tables is provided
    LOOP AT it_confdet WHERE conid = i_conid.
      APPEND it_confdet TO et_confdet.
      LOOP AT it_functtran WHERE functionid = it_confdet-functionid.
        APPEND it_functtran TO et_functtran.
        LOOP AT it_faobj WHERE funid = it_confdet-functionid AND
                               tcode = it_functtran-tcode.
*--if we use an explicit SOD matrix, only the org placeholders
*  for fields relevant for this custom logic should be included
          IF it_faobj-val_from CP '$*'.
            CASE i_rewrite_type.
              WHEN 'FIELD'.
                IF it_faobj-field = i_field.
                  APPEND it_faobj TO et_faobj.
                ENDIF.
              WHEN 'REL'.
                CASE i_field.
                  WHEN 'EKORG'.
                    CASE it_faobj-field.
                      WHEN 'EKORG' OR 'WERKS'.
                        APPEND it_faobj TO et_faobj.
                    ENDCASE.
                  WHEN 'VKORG'.
                    CASE it_faobj-field.
                      WHEN 'VKORG' OR 'VTWEG' OR 'SPART'.
                        APPEND it_faobj TO et_faobj.
                    ENDCASE.
                ENDCASE.
            ENDCASE.
          ELSE.
            APPEND it_faobj TO et_faobj.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
*--Add to bufffer for performance
    st_conflicts-conid = i_conid.
    st_conflicts-vrsio = i_vrsio.
    st_conflicts-faobj[]     = et_faobj[].
    st_conflicts-confdet[]   = et_confdet[].
    st_conflicts-functtran[] = et_functtran[].
    INSERT TABLE st_conflicts.
  ENDIF.
ENDFORM.                    " sw125_filter_matrix
*&---------------------------------------------------------------------*
*&      Form  sw125_rewrite_orgs
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_ORGM  text
*----------------------------------------------------------------------*
FORM sw125_rewrite_orgs
  TABLES   et_orgm       STRUCTURE /psyng/swsodorgm
           it_faobj      STRUCTURE /psyng/faobj2
  USING
           is_rfcdes     TYPE rfcdes
           it_swsodorgm  TYPE /psyng/sw_tab_sys_ao
           i_rewrite_type TYPE string
           i_field       TYPE xufield
           i_vrsio       TYPE /psyng/sodvrsio
           i_setid       TYPE /psyng/seconfid
           i_conid       TYPE /psyng/conflict_id.

  DATA : ls_org          TYPE /psyng/sw_sys_ao,
           ls_orgm       TYPE /psyng/swsodorgm,
           lt_orgm       TYPE TABLE OF /psyng/swcfgoe
                         WITH HEADER LINE,
           lt_vals       TYPE TABLE OF /psyng/sw_org_values_text
                          WITH HEADER LINE,
           lt_ret        TYPE TABLE OF bapiret2,
           lt_org_uniq   TYPE HASHED TABLE OF /psyng/swsodorgm WITH
                         UNIQUE KEY abb object varbl low high
                         WITH HEADER LINE,
*--Begin of insert : Umittal 01/12/2023 D67K928699
           lv_ekorg   TYPE flag,
           lv_vkorg   TYPE flag.
  CONSTANTS : lc_x    TYPE flag VALUE 'X'.
*--End of insert : Umittal 01/12/2023 D67K928699

  RANGES : lr_object FOR it_faobj-object,
           lr_field  FOR it_faobj-field.
  LOOP AT it_faobj.
    lr_object-sign   = 'I'.
    lr_object-option = 'EQ'.
    lr_object-low    =  it_faobj-object.
    APPEND lr_object.
  ENDLOOP.
  lr_field-sign   = 'I'.
  lr_field-option = 'EQ'.
  lr_field-low    =  i_field.
  APPEND lr_field.

  TYPES :
    BEGIN OF t_rewrite,
      field TYPE xufield,
      type  TYPE string,
      vrsio TYPE /psyng/sodvrsio,
      conid TYPE /psyng/conflict_id,
      setid TYPE /psyng/seconfid,
      orgm  TYPE STANDARD TABLE OF /psyng/swsodorgm WITH DEFAULT KEY,
    END OF t_rewrite.
  STATICS :
    st_rewrite TYPE HASHED TABLE OF t_rewrite WITH HEADER LINE
               WITH UNIQUE KEY
                    field type vrsio conid setid.

*--Check if we have the data in the buffer already
  READ TABLE  st_rewrite WITH TABLE KEY
    field = i_field
    type  = i_rewrite_type
    vrsio = i_vrsio
    conid = i_conid
    setid = i_setid.
  IF sy-subrc = 0.
    et_orgm[] = st_rewrite-orgm[].
  ELSE.
    CASE i_rewrite_type.
      WHEN 'FIELD'.
        READ TABLE it_swsodorgm INTO ls_org
        WITH KEY rfcdest = is_rfcdes-rfcoptions.
        DELETE ls_org-swsodorgm WHERE
           NOT object IN lr_object
        OR NOT varbl  IN lr_field .
*    --Rewrite org config
        LOOP AT ls_org-swsodorgm INTO ls_orgm.
          ls_orgm-abb = ls_orgm-low.
          APPEND ls_orgm TO et_orgm.
        ENDLOOP.
      WHEN 'REL'.
        CASE i_field.
          WHEN 'EKORG'.
*--Load the Current relations between EKORG and WERKS
*Begin of Change : Umittal 01/12/2023 D67K928699

*-- RFC enabled FM to Load the Current relations between EKORG and WERKS
            CLEAR : lv_ekorg.
            lv_ekorg = lc_x.
            IF is_rfcdes-rfcdest EQ 'LOCAL'.
              CALL FUNCTION '/PSYNG/SW_AO_005'
               EXPORTING
                 iv_values          = ''
                 iv_ekorg           = lv_ekorg
               TABLES
                 et_swsodorgm       = lt_orgm
                 et_return          = lt_ret
                 et_values          = lt_vals.
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
              CALL FUNCTION '/PSYNG/SW_AO_005'
               DESTINATION is_rfcdes-rfcdest
               EXPORTING
                 iv_values          = ''
                 iv_ekorg           = lv_ekorg
               TABLES
                 et_swsodorgm       = lt_orgm
                 et_return          = lt_ret
                 et_values          = lt_vals
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
                EXCEPTIONS
                  SYSTEM_FAILURE = 1
                  COMMUNICATION_FAILURE = 2
                  OTHERS = 3.   "#EC SAST_CI_GEN_CHECK
 IF sy-subrc <> 0.
    CASE sy-subrc.
       WHEN 1.
          MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
       WHEN 2.
          MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
       WHEN OTHERS.
          MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
     ENDCASE.
  ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
            ENDIF.
*End of Change : Umittal 01/12/2023 D67K928699


*--Adapt the provided values to that each EKORg and WERKS are combined
* in separate ABBS
            READ TABLE it_swsodorgm INTO ls_org
            WITH KEY rfcdest = is_rfcdes-rfcoptions.
            DELETE ls_org-swsodorgm WHERE
            NOT object IN lr_object
            AND NOT ( varbl = 'WERKS' OR varbl = 'EKORG' ).
            SORT ls_org-swsodorgm BY varbl low object.
            LOOP AT lt_orgm.
              READ TABLE ls_org-swsodorgm WITH KEY
                varbl = lt_orgm-varbl
                low   = lt_orgm-value
                BINARY SEARCH TRANSPORTING NO FIELDS.
              IF sy-subrc = 0.
                LOOP AT ls_org-swsodorgm FROM sy-tabix
                INTO ls_orgm.
                  IF ls_orgm-varbl <> lt_orgm-varbl OR
                     ls_orgm-low  <> lt_orgm-value.
                    EXIT.
                  ENDIF.
                  MOVE-CORRESPONDING lt_orgm TO lt_org_uniq.
                  lt_org_uniq-varbl  = ls_orgm-varbl.
                  lt_org_uniq-object = ls_orgm-object.
                  lt_org_uniq-low    = lt_orgm-value.

                  INSERT TABLE lt_org_uniq.
                ENDLOOP.
              ENDIF.
            ENDLOOP.
            APPEND LINES OF lt_org_uniq TO et_orgm.
            FREE : lt_org_uniq.

          WHEN 'VKORG'.
*Begin of Change : Umittal 01/12/2023 D67K928699
          CLEAR : lv_vkorg.
          lv_vkorg = lc_x.
          IF is_rfcdes-rfcdest EQ 'LOCAL'.
            CALL FUNCTION '/PSYNG/SW_AO_005'
             EXPORTING
               iv_values          = ''
               iv_vkorg           = lv_vkorg
             TABLES
               et_swsodorgm       = lt_orgm
               et_return          = lt_ret
               et_values          = lt_vals.

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
            CALL FUNCTION '/PSYNG/SW_AO_005' DESTINATION is_rfcdes-rfcdest
               EXPORTING
                 iv_values          = ''
                 iv_ekorg           = lv_vkorg
               TABLES
                 et_swsodorgm       = lt_orgm
                 et_return          = lt_ret
                 et_values          = lt_vals
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            SYSTEM_FAILURE = 1
            COMMUNICATION_FAILURE = 2
            OTHERS = 3.   "#EC SAST_CI_GEN_CHECK
  IF sy-subrc <> 0.
     CASE sy-subrc.
        WHEN 1.
           MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
        WHEN 2.
           MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
        WHEN OTHERS.
           MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
      ENDCASE.
   ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          ENDIF.
*End of Change : Umittal 01/12/2023 D67K928699

*--Adapt the provided values to that each VKORG,SPART and VTWEG are
* combined in separate ABBS
            READ TABLE it_swsodorgm INTO ls_org
            WITH KEY rfcdest = is_rfcdes-rfcoptions.
            DELETE ls_org-swsodorgm WHERE
            NOT object IN lr_object
            AND NOT ( varbl = 'VKORG' OR varbl = 'SPART'
                   OR varbl = 'VTWEG' ).
            SORT ls_org-swsodorgm BY varbl low object.
            LOOP AT lt_orgm.
              READ TABLE ls_org-swsodorgm WITH KEY
                varbl = lt_orgm-varbl
                low   = lt_orgm-value
                BINARY SEARCH TRANSPORTING NO FIELDS.
              IF sy-subrc = 0.
                LOOP AT ls_org-swsodorgm FROM sy-tabix
                INTO ls_orgm.
                  IF ls_orgm-varbl <> lt_orgm-varbl OR
                     ls_orgm-low  <> lt_orgm-value.
                    EXIT.
                  ENDIF.
                  MOVE-CORRESPONDING lt_orgm TO lt_org_uniq.
                  lt_org_uniq-varbl  = ls_orgm-varbl.
                  lt_org_uniq-object = ls_orgm-object.
                  lt_org_uniq-low    = lt_orgm-value.

                  INSERT TABLE lt_org_uniq.
                ENDLOOP.
              ENDIF.
            ENDLOOP.
            APPEND LINES OF lt_org_uniq TO et_orgm.
            FREE : lt_org_uniq.
          WHEN OTHERS.
            MESSAGE e002(/psyng/sw) WITH
            'Custom Org Logic type REL only supports field EKORG, not'
            i_field .
        ENDCASE.
      WHEN OTHERS.
        MESSAGE e002(/psyng/sw) WITH
        'Invalid configuration for Custom Org Logic' .
*   & & & &

    ENDCASE.
*--Store in buffer
    st_rewrite-field  = i_field.
    st_rewrite-type   = i_rewrite_type.
    st_rewrite-vrsio  = i_vrsio.
    st_rewrite-conid  = i_conid.
    st_rewrite-setid  = i_setid.
    st_rewrite-orgm[] = et_orgm[].
    INSERT TABLE st_rewrite.
  ENDIF.
ENDFORM.                    " sw125_rewrite_orgs


*---------------------------------------------------------------------*
*       FORM load_ekorg_werks                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SWSODORGM                                                  *
*  -->  ET_RETURN                                                     *
*  -->  ET_VALUES                                                     *
*  -->  IF_VALUES                                                     *
*---------------------------------------------------------------------*
FORM load_ekorg_werks
TABLES
  et_swsodorgm STRUCTURE /psyng/swcfgoe
  et_return    STRUCTURE bapiret2
  et_values    STRUCTURE /psyng/sw_org_values_text
USING
  if_values    TYPE flag  .

  DATA : lt_ekorg TYPE TABLE OF t_t024e ,
         lt_werks TYPE TABLE OF t_t024w ,
         l_ret    TYPE bapireturn1,
         lf_valid TYPE flag,
         ls_tadir TYPE tadir.
  FIELD-SYMBOLS : <ekorg> TYPE t_t024e,
                  <werks> TYPE t_t024w.
*--Check if Tables exist
  SELECT SINGLE obj_name FROM tadir
  INTO CORRESPONDING FIELDS OF ls_tadir
  WHERE object = 'TABL' AND obj_name = 'T042E'.
  IF sy-subrc = 0 AND ls_tadir-obj_name = 'T042E'.
*  --Load EKORGS
    SELECT ekorg bukrs ekotx FROM (ct_t024e)"#EC SAST_CI_GEN_CHECK
*    SELECT ekorg bukrs ekotx
*      FROM T024E "(++)BOC UMITTAL SE VF scan-25/11/2024
    INTO CORRESPONDING FIELDS OF TABLE lt_ekorg.

*  --Link to plant
    IF if_values = 'X'.
      SORT lt_ekorg BY ekorg.
    ENDIF.

    SELECT ekorg werks FROM (ct_t024w)"#EC SAST_CI_GEN_CHECK
*    SELECT ekorg werks FROM T024W "(++)BOC UMITTAL SE VF scan-25/11/2024
    INTO CORRESPONDING FIELDS OF TABLE lt_werks.
    LOOP AT lt_werks ASSIGNING <werks>.
      lf_valid  = 'X'.
*  --Check if EKORG is valid
*  ( there can be a record in T042W for an ekorg that no longer exists)
      READ TABLE lt_ekorg WITH KEY ekorg = <werks>-ekorg
      ASSIGNING <ekorg>
      BINARY SEARCH.
      IF sy-subrc <> 0.
        CLEAR lf_valid.
        log et_return 'I' 'EKORG'  <werks>-ekorg 'INACTIVE'
                                   'Invalid EKORG linked to plant '
                                   <werks>-werks .

      ELSE.
        IF if_values = 'X'.
*      --Append text values for displaying
          et_values-field = 'EKORG'.
          et_values-vtext = <ekorg>-ekotx.
          et_values-low   = <werks>-ekorg.
          APPEND et_values.
        ENDIF.
*      --Append records for SWSODORGM Table
        et_swsodorgm-abb    = <ekorg>-ekorg.
        et_swsodorgm-varbl  = 'EKORG'.
        et_swsodorgm-value    = <werks>-ekorg.
        APPEND et_swsodorgm.
        et_swsodorgm-varbl  = 'WERKS'.
        et_swsodorgm-value    = <werks>-werks.
        APPEND et_swsodorgm.
      ENDIF.
    ENDLOOP.
  ELSE.
    log et_return 'I' 'EKORG'  'T042E' 'Table does not exist.'
                               ''
                               ''.

  ENDIF.


ENDFORM.                    " load_ekorg_werks



*---------------------------------------------------------------------*
*       FORM load_vkorg_vtweg_spart                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SWSODORGM                                                  *
*  -->  ET_RETURN                                                     *
*  -->  ET_VALUES                                                     *
*  -->  IF_VALUES                                                     *
*---------------------------------------------------------------------*
FORM load_vkorg_vtweg_spart
TABLES
  et_swsodorgm STRUCTURE /psyng/swcfgoe
  et_return    STRUCTURE bapiret2
  et_values    STRUCTURE /psyng/sw_org_values_text
USING
  if_values    TYPE flag  .

  DATA : lt_vkorg TYPE TABLE OF t_tvta,
         ls_tadir TYPE tadir.
  FIELD-SYMBOLS : <vkorg> TYPE t_tvta.
*--Check if Tables exist
  SELECT SINGLE obj_name FROM tadir
  INTO CORRESPONDING FIELDS OF ls_tadir
  WHERE object = 'TABL' AND obj_name = 'TVTA'.
  IF sy-subrc = 0 AND ls_tadir-obj_name = 'TVTA'.

    SELECT vkorg spart vtweg FROM (ct_tvta)"#EC SAST_CI_GEN_CHECK
*    SELECT vkorg spart vtweg
*      FROM tvta "(++)BOC UMITTAL SE VF scan-25/11/2024
    INTO CORRESPONDING FIELDS OF TABLE lt_vkorg.

    LOOP AT lt_vkorg ASSIGNING <vkorg>.
*  --Append records for SWSODORGM Table
      CONCATENATE <vkorg>-vkorg '-' <vkorg>-spart '-' <vkorg>-vtweg
      INTO et_swsodorgm-abb.
*    et_swsodorgm-abb    = <vkorg>-vkorg.
      et_swsodorgm-varbl  = 'VKORG'.
      et_swsodorgm-value  = <vkorg>-vkorg.
      APPEND et_swsodorgm.
      et_swsodorgm-varbl  = 'SPART'.
      et_swsodorgm-value  = <vkorg>-spart.
      APPEND et_swsodorgm.
      et_swsodorgm-varbl  = 'VTWEG'.
      et_swsodorgm-value  = <vkorg>-vtweg.
      APPEND et_swsodorgm.
    ENDLOOP.
  ELSE.
    log et_return 'I' 'VKORG'  'TVTA' 'Table does not exist.'
                               ''
                               ''.

  ENDIF.

  SORT et_swsodorgm.
  DELETE ADJACENT DUPLICATES FROM et_swsodorgm.
ENDFORM.                    " load_bukrs
*&---------------------------------------------------------------------*
*&      Form  LOAD_ANALYZED_SYSTEMS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IF_LOCAL_SYSTEM  text
*      -->P_IT_SYSTEMS  text
*      -->P_IT_RFCDEST  text
*----------------------------------------------------------------------*
FORM load_analyzed_systems
  TABLES   et_systems STRUCTURE /psyng/swcfgsys
           it_rfcdest STRUCTURE /psyng/sw_sel_opts_rfcdest
  USING    if_local_system TYPE flag
  .
  DATA : lt_rfcdest  TYPE TABLE OF /psyng/sw_sel_opts_rfcdest
                     WITH HEADER LINE,
         lt_dest     TYPE TABLE OF rfcdes WITH HEADER LINE,
         lt_def_dest TYPE TABLE OF /psyng/sw_rfcdes
                     WITH HEADER LINE,
         l_system_msg(80) TYPE c..
  IF if_local_system = 'X'.
    CONCATENATE sy-sysid sy-mandt INTO et_systems-sysid.
    APPEND et_systems.
  ENDIF.
  lt_rfcdest[] = it_rfcdest[].
  IF NOT it_rfcdest[] IS INITIAL.
SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_def_dest WHERE rfcdest IN it_rfcdest.
    LOOP AT lt_def_dest.
      et_systems-sysid = lt_def_dest-systid.
      APPEND et_systems.
      DELETE  lt_rfcdest WHERE low =  lt_def_dest-rfcdest.
    ENDLOOP.
    IF NOT lt_rfcdest[] IS INITIAL.
      LOOP AT lt_rfcdest WHERE sign = 'I' AND option = 'EQ'.
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
        DESTINATION lt_rfcdest-low
         IMPORTING
           e_rfcdest       = et_systems-sysid
         EXCEPTIONS
             communication_failure = 1 MESSAGE l_system_msg
             system_failure        = 2 MESSAGE l_system_msg
             OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
        IF sy-subrc = 0.
          APPEND et_systems.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
  SORT et_systems.
  DELETE ADJACENT DUPLICATES FROM et_systems.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SAVE_CONFIGSET_HEADER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_g_set_id  text
*----------------------------------------------------------------------*
FORM save_configset_header  USING  if_description TYPE flag
                              i_desc TYPE /PSYNG/LONGTEXTFIELD
                              l_vrsio type /PSYNG/SODVRSIO
                              i_global_dflt_sod TYPE flag.
****    Insert into config set
  DATA : ls_swcfgset1 TYPE /psyng/swcfgset,
       ls_swcfgset2 TYPE /psyng/swcfgset.

  SELECT SINGLE * FROM /psyng/swcfgset INTO  ls_swcfgset1
  WHERE setid =  g_set_id.

  IF sy-subrc = 0.
    ls_swcfgset2-change_user = sy-uname."sy-uname. C0700
    ls_swcfgset2-change_date = sy-datum.
    ls_swcfgset2-change_time = sy-uzeit.
    ls_swcfgset2-setid = g_set_id.
    ls_swcfgset2-create_user = ls_swcfgset1-create_user.
    ls_swcfgset2-create_date = ls_swcfgset1-create_date.
    ls_swcfgset2-create_time = ls_swcfgset1-create_time.
  ELSE.
    ls_swcfgset2-create_user = sy-uname."sy-uname. C0700
    ls_swcfgset2-create_date = sy-datum.
    ls_swcfgset2-create_time = sy-uzeit.
    ls_swcfgset2-setid = g_set_id.
    ls_swcfgset2-change_user = sy-uname."sy-uname. C0700
    ls_swcfgset2-change_date = sy-datum.
    ls_swcfgset2-change_time = sy-uzeit.
  ENDIF.

*CALL FUNCTION '/PSYNG/SW_131'
** EXPORTING
**   I_GLOBLE_VRSIO       =
** IMPORTING
**   E_SOD_VERSION        =
*          .

if l_vrsio is INITIAL
  AND i_global_dflt_sod IS NOT INITIAL .
  CALL FUNCTION '/PSYNG/SW_131'
   EXPORTING
   I_GLOBLE_VRSIO        = 'X'
   IMPORTING
     e_sod_version       = ls_swcfgset2-sodvrsio.
  else.
    ls_swcfgset2-sodvrsio = l_vrsio.
    endif.

*---Description for config set
  IF if_description NE 'X'.
    ls_swcfgset2-description = i_desc.
  ELSE.
    CLEAR ls_swcfgset1.
    PERFORM latest_pubset_desc
    using ls_swcfgset2-sodvrsio CHANGING ls_swcfgset1.
    ls_swcfgset2-description = ls_swcfgset1-description.
  ENDIF.

  se_config_param 'DFLT_VAREL_VERSION'
  ls_swcfgset2-varel_vrsio.

  MODIFY /psyng/swcfgset FROM ls_swcfgset2.
  COMMIT WORK AND WAIT.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SAVE_CONFIGSET_SYSTEMS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_configset_systems TABLES it_systems STRUCTURE /psyng/swcfgsys.
  DATA : lt_swcfgsys TYPE TABLE OF /psyng/swcfgsys,
         ls_swcfgsys TYPE /psyng/swcfgsys,
        ls_systems LIKE LINE OF it_systems.

  IF NOT g_set_id  IS  INITIAL.
    LOOP AT it_systems INTO ls_systems.
      ls_swcfgsys-setid = g_set_id.
      ls_swcfgsys-sysid = ls_systems-sysid.
      APPEND ls_swcfgsys TO lt_swcfgsys.
      CLEAR ls_swcfgsys.
    ENDLOOP.
  ENDIF.

  DELETE FROM /psyng/swcfgsys WHERE setid = g_set_id.
  MODIFY /psyng/swcfgsys FROM TABLE lt_swcfgsys.
  COMMIT WORK AND WAIT.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  LATEST_PUBSET_DESC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LS_SWCFGSET1  text
*----------------------------------------------------------------------*
FORM latest_pubset_desc USING
         p_vrsio type /psyng/swcfgset-sodvrsio
   CHANGING p_ls_swcfgset1 TYPE  /psyng/swcfgset.
  DATA : lt_swcfgset TYPE TABLE OF /psyng/swcfgset,
         l_total_published_set TYPE i.

  SELECT *
         FROM /psyng/swcfgset
         INTO TABLE lt_swcfgset
         WHERE published = 'X'
         and sodvrsio    = p_vrsio.

  IF sy-subrc = 0.
    DESCRIBE TABLE lt_swcfgset LINES l_total_published_set.
 READ TABLE lt_swcfgset INTO p_ls_swcfgset1 INDEX l_total_published_set.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SAVE_OE_VE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_ORG_VALUES  text
*      -->P_GT_VARIABLE1  text
*----------------------------------------------------------------------*
FORM save_oe_ve  TABLES it_selections STRUCTURE /psyng/swcfsel.
  FIELD-SYMBOLS : <fs_selection> TYPE /psyng/swcfsel.

  LOOP AT it_selections ASSIGNING <fs_selection>.
    <fs_selection>-setid = g_set_id.
    MODIFY it_selections FROM  <fs_selection>.
  ENDLOOP.

  DELETE FROM /psyng/swcfsel WHERE setid = g_set_id.
  COMMIT WORK.

  MODIFY /psyng/swcfsel FROM TABLE it_selections.
  COMMIT WORK.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  PUBLISH_CFGSET
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM publish_cfgset USING i_desc TYPE /PSYNG/LONGTEXTFIELD .
  IF NOT g_set_id IS INITIAL.
    IF i_desc IS INITIAL.
      "maintain description
    ELSE.
      UPDATE /psyng/swcfgset SET published = 'X'
              WHERE setid = g_set_id.
    ENDIF.
  ENDIF.
ENDFORM.
