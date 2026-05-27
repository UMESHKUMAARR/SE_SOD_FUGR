FUNCTION /psyng/sw_ao_002 .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_SODVRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_SETID) TYPE  /PSYNG/SECONFID OPTIONAL
*"  TABLES
*"      ET_VARBLS STRUCTURE  /PSYNG/ORGFIELD OPTIONAL
*"      ET_TOBJ STRUCTURE  TOBJ OPTIONAL
*"      IT_FAOBJ STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"      ET_LIST STRUCTURE  /PSYNG/SW_AO_LIST OPTIONAL
*"  EXCEPTIONS
*"      VERSION_NO_EXIST
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_AO_002'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026

  DATA : lt_faobj     TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
         lt_tobj      TYPE TABLE OF tobj WITH HEADER LINE,
         lt_texts     TYPE TABLE OF dd04t WITH HEADER LINE,
         lt_values    TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
         l_fieldname  TYPE xufield,
         l_text       TYPE as4text,
         l_param      TYPE /psyng/param,
         l_paramval   TYPE /psyng/param_value,
         lf_org_placeholders_used
                      TYPE flag,
         lt_faobj_org TYPE TABLE OF /psyng/faobj2
                      WITH HEADER LINE.
  RANGES: lr_fields FOR et_tobj-fiel1.
  FIELD-SYMBOLS : <element> TYPE /psyng/sw_ao_list.
*--Verify SOD Matrix version exists$
  SELECT SINGLE vrsio INTO i_sodvrsio
  FROM /psyng/swsodvers WHERE vrsio = i_sodvrsio.
  IF sy-subrc <> 0.
    RAISE version_no_exist.
  ENDIF.
  IF it_faobj[] IS INITIAL.
*--Load objects from local SOD Matrix
    SELECT DISTINCT object FROM /psyng/faobj2
    INTO CORRESPONDING FIELDS OF TABLE lt_faobj
    WHERE vrsio = i_sodvrsio.
  ELSE.
    lt_faobj[] = it_faobj[].
  ENDIF.


*--Prepare the range of field names we are interested in
  lr_fields-sign   = 'I'.
  lr_fields-option = 'EQ'.
  lr_fields-low = 'BUKRS'. APPEND lr_fields.
  lr_fields-low = 'EKORG'. APPEND lr_fields.
  lr_fields-low = 'WERKS'. APPEND lr_fields.
  lr_fields-low = 'IWERK'. APPEND lr_fields.
  lr_fields-low = 'GSBER'. APPEND lr_fields.
  lr_fields-low = 'SPART'. APPEND lr_fields.
  lr_fields-low = 'VTWEG'. APPEND lr_fields.
  lr_fields-low = 'KKBER'. APPEND lr_fields.
  lr_fields-low = 'KOKRS'. APPEND lr_fields.
  lr_fields-low = 'VKORG'. APPEND lr_fields.
  lr_fields-low = 'VSTEL'. APPEND lr_fields.

*--If, anywhere in the SOD Matrix, $-placeholders are
*  used for org values, like BUKRS = $BUKRS, WERKS = $WERS ...
*  only objects for which these placeholders are present
*  will be considered as org relevant objects
  SELECT  * FROM /psyng/faobj2
  INTO TABLE lt_faobj_org
  WHERE
    vrsio    = i_sodvrsio AND
    field    IN lr_fields AND
    val_from LIKE '$%'.
  IF sy-subrc = 0.
    lf_org_placeholders_used  = 'X'.
    SORT lt_faobj_org BY object field val_from.
    DELETE ADJACENT DUPLICATES FROM lt_faobj_org
    COMPARING object field val_from.
  ENDIF.

*create a config flag to fil this table.


*--Identify the org areas associated with these objects
  IF lf_org_placeholders_used  = 'X'.
*--$ placeholders are used, an object is org relevant when
*  it has the org field with a $ placeholder
    LOOP AT lt_faobj_org WHERE val_from CP '$*'.
      IF lt_faobj_org-field IN lr_fields.
        et_varbls-field = lt_faobj_org-field.
        CONCATENATE '$' et_varbls-field INTO et_varbls-varbl.
        lt_tobj-fiel1  = et_varbls-field.
        lt_tobj-objct  = lt_faobj_org-object.

        COLLECT lt_tobj.
        COLLECT et_varbls.
      ENDIF.
    ENDLOOP.
  ELSE.
*--No $ placeholders are used, an object is org relevant when
*  it has a field that is org relevant
*  (field doesn't need to be in matrix)
    IF NOT lt_faobj[] IS INITIAL.
      SELECT * FROM tobj
      INTO CORRESPONDING FIELDS OF TABLE et_tobj
      FOR ALL ENTRIES IN lt_faobj
      WHERE objct = lt_faobj-object
      AND
      (
        fiel1 IN lr_fields OR
        fiel2 IN lr_fields OR
        fiel3 IN lr_fields OR
        fiel4 IN lr_fields OR
        fiel5 IN lr_fields OR
        fiel6 IN lr_fields OR
        fiel7 IN lr_fields OR
        fiel8 IN lr_fields OR
        fiel9 IN lr_fields
      ).
    ENDIF.

    LOOP AT et_tobj.
      lt_tobj-objct = et_tobj-objct.
      IF et_tobj-fiel1 IN lr_fields.
        et_varbls-field = et_tobj-fiel1.
        CONCATENATE '$' et_varbls-field INTO et_varbls-varbl.
        lt_tobj-fiel1 = et_varbls-field.
        COLLECT lt_tobj.
        COLLECT et_varbls.
      ENDIF.
      IF et_tobj-fiel2 IN lr_fields.
        et_varbls-field = et_tobj-fiel2.
        CONCATENATE '$' et_varbls-field INTO et_varbls-varbl.
        lt_tobj-fiel1 = et_varbls-field.
        COLLECT lt_tobj.
        COLLECT et_varbls.
      ENDIF.
      IF et_tobj-fiel3 IN lr_fields.
        et_varbls-field = et_tobj-fiel3.
        CONCATENATE '$' et_varbls-field INTO et_varbls-varbl.
        COLLECT et_varbls.
        lt_tobj-fiel1 = et_varbls-field.
        COLLECT lt_tobj.
      ENDIF.
      IF et_tobj-fiel4 IN lr_fields.
        et_varbls-field = et_tobj-fiel4.
        CONCATENATE '$' et_varbls-field INTO et_varbls-varbl.
        COLLECT et_varbls.
        lt_tobj-fiel1 = et_varbls-field.
        COLLECT lt_tobj.
      ENDIF.
      IF et_tobj-fiel5 IN lr_fields.
        et_varbls-field = et_tobj-fiel5.
        CONCATENATE '$' et_varbls-field INTO et_varbls-varbl.
        COLLECT et_varbls.
        lt_tobj-fiel1 = et_varbls-field.
        COLLECT lt_tobj.
      ENDIF.
      IF et_tobj-fiel6 IN lr_fields.
        et_varbls-field = et_tobj-fiel6.
        CONCATENATE '$' et_varbls-field INTO et_varbls-varbl.
        COLLECT et_varbls.
        lt_tobj-fiel1 = et_varbls-field.
        COLLECT lt_tobj.
      ENDIF.
      IF et_tobj-fiel7 IN lr_fields.
        et_varbls-field = et_tobj-fiel7.
        CONCATENATE '$' et_varbls-field INTO et_varbls-varbl.
        COLLECT et_varbls.
        lt_tobj-fiel1 = et_varbls-field.
        COLLECT lt_tobj.
      ENDIF.
      IF et_tobj-fiel8 IN lr_fields.
        et_varbls-field = et_tobj-fiel8.
        CONCATENATE '$' et_varbls-field INTO et_varbls-varbl.
        COLLECT et_varbls.
        lt_tobj-fiel1 = et_varbls-field.
        COLLECT lt_tobj.
      ENDIF.
      IF et_tobj-fiel9 IN lr_fields.
        et_varbls-field = et_tobj-fiel9.
        CONCATENATE '$' et_varbls-field INTO et_varbls-varbl.
        COLLECT et_varbls.
        lt_tobj-fiel1 = et_varbls-field.
        COLLECT lt_tobj.
      ENDIF.
    ENDLOOP.
  ENDIF.
*--Move lt_tobj to output table,
*  it always contains the org field in fiel1.
  SORT lt_tobj.
  DELETE ADJACENT DUPLICATES FROM lt_tobj.
  et_tobj[] = lt_tobj[].


  IF et_list IS REQUESTED.
    LOOP AT lr_fields.
      CLEAR et_list-selected.
      et_list-field = lr_fields-low.
      CONCATENATE '$' lr_fields-low INTO et_list-varbl.
*-- set the default Based on Config Parameters ORG_DFLT_*
      CONCATENATE 'ORG_DFLT_' lr_fields-low INTO l_param.
      se_config_param l_param l_paramval.
      CLEAR et_list-default.
      IF l_paramval = 'X' OR l_paramval = 'Y'.
        et_list-default = 'X'.
      ENDIF.
      IF et_list-default = 'X'.
        et_list-selected  = 'X'.
      ELSE.
        READ TABLE et_varbls WITH KEY field = et_list-field
        TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          et_list-selected  = 'X'.
        ENDIF.
      ENDIF.
*--Get the label
      l_fieldname = et_list-field.
      CALL FUNCTION 'SAUT_AUTHX_FIELD_GET_INFO'
           EXPORTING
                fieldname = l_fieldname
           IMPORTING
                text      = l_text.
      IF sy-subrc <> 0 OR l_text IS INITIAL.
        et_list-description = et_list-varbl.
      ELSE.
        READ TABLE lt_texts INDEX 1.
        et_list-description = l_text.
      ENDIF.

      APPEND et_list.
    ENDLOOP.
*--Apply the already saved data to the selection
    IF NOT i_setid IS INITIAL.
*--If there are already values for the provided configuration set
*  that are active, mark these as selected
      SELECT DISTINCT varbl FROM /psyng/swcfgoe
      INTO CORRESPONDING FIELDS OF TABLE lt_values
      WHERE setid = i_setid AND active = 'X' ORDER BY varbl.
      IF NOT lt_values[] IS INITIAL.
        LOOP AT lt_values.
          et_list-selected = 'X'.
          MODIFY et_list
          TRANSPORTING selected
          WHERE field = lt_values-varbl.
        ENDLOOP.
      ENDIF.
*--If there are selected org areas (that are not default) for which
*  there are no values, deselect them
      LOOP AT et_list ASSIGNING <element> WHERE selected =  'X' AND
                                                default  <> 'X'.
        READ TABLE lt_values WITH KEY varbl = <element>-field
        BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          CLEAR <element>-selected.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

ENDFUNCTION.
