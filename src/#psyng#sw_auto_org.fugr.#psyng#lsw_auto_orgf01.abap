*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LZ_SW_AUTO_ORGF01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  load_bukrs
*&---------------------------------------------------------------------*
*       Validation Rules
*       Company Code should have a non empty KTOPL field in T001
*       The OPVAR field in T001 should have a corresponding open period
*       > last year.
*       CAUTION : In T001B the field containing the Posting Period
*       Variant is called BUKRS instead of OPVAR
*----------------------------------------------------------------------*
*      -->P_ET_SWSODORGM  text
*      -->P_ET_RETURN  text
*      -->P_ET_VALUES  text
*----------------------------------------------------------------------*
FORM load_bukrs
TABLES
  et_swsodorgm STRUCTURE /psyng/swcfgoe
  et_return    STRUCTURE bapiret2
  et_values    STRUCTURE /psyng/sw_org_values_text
USING
  if_values    TYPE flag  .

  DATA : lt_bukrs TYPE TABLE OF t_t001 ,
         l_ret    TYPE bapireturn1,
         l_checkyear(4) TYPE c,
         l_checkyear_i TYPE i,
         l_bukrs(4) TYPE c,
         lt_fields TYPE TABLE OF dfies WITH HEADER LINE,
         lf_toye3 TYPE flag,
         lf_valid TYPE flag,
         lf_exist type flag.
  FIELD-SYMBOLS : <bukrs> TYPE t_t001.

  l_checkyear_i = sy-datum(4).
  SUBTRACT 1 FROM l_checkyear_i.
  l_checkyear = l_checkyear_i.

  SELECT bukrs butxt opvar ktopl FROM (ct_t001) "#EC SAST_CI_GEN_CHECK
  INTO CORRESPONDING FIELDS OF TABLE lt_bukrs.



*--Check if the TOYE3 field exists in table T001B

  CALL FUNCTION 'DDIF_FIELDINFO_GET'
       EXPORTING
            tabname        = 'T001B'
       TABLES
            dfies_tab      = lt_fields
       EXCEPTIONS
            not_found      = 1
            internal_error = 2
            OTHERS         = 3.
*BOC:HBHALLA (06/12/24)
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN 1.
                MESSAGE s002(/psyng/sw)
             WITH 'Nothing Found'.
             WHEN 2.
                MESSAGE s002(/psyng/sw)
             WITH 'Internal Error Occured'.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (06/12/24)
  READ TABLE lt_fields WITH KEY fieldname = 'TOYE3'.
  IF sy-subrc = 0.
    lf_toye3 = 'X'.
  ENDIF.

lf_exist = 'X'.
*--Arpan OPL 551 21.10.2022 : STARTS
*--Checking existance of function module
  CALL FUNCTION 'FUNCTION_EXISTS'
    EXPORTING
      FUNCNAME           = cf_bukrs_validate
    EXCEPTIONS
      FUNCTION_NOT_EXIST = 1
      OTHERS             = 2.
  IF SY-SUBRC <> 0.
    CLEAR lf_exist.
  ENDIF.

  LOOP AT lt_bukrs ASSIGNING <bukrs>.
    lf_valid = 'X'.
    IF <bukrs>-ktopl IS INITIAL.
      log et_return 'I' 'BUKRS' <bukrs>-bukrs 'INACTIVE'
                                              'No chart of accounts '
                                              '(T001-KTOPL blank)'.
      CLEAR lf_valid. "No chart of accounts
    ENDIF.
    IF <bukrs>-opvar IS INITIAL.
      log et_return 'I' 'BUKRS' <bukrs>-bukrs 'INACTIVE'
                                              'No Posting period variant '
                                              '(T001-OPVAR blank)'.
      CLEAR lf_valid. "No Posting period variant
    ENDIF.
    IF lf_valid = 'X'.
*B7836 - Validate BUKRS (ensure it's actually used and is not a template
*--- om 20.01.2023 comenting for opl 550
*--- invalide company codes should be in inactive state
*      IF lf_exist = 'X'.
*      CALL FUNCTION cf_bukrs_validate
*           EXPORTING
*                companycodeid = <bukrs>-bukrs
*                posting_date  = sy-datum
*           IMPORTING
*                return        = l_ret.
*      endif.
*      CHECK l_ret-type <> 'E'.
*---opl550   end of comment
*       IF LF_EXIST = 'X'.
      IF lf_toye3 IS INITIAL.
        SELECT SINGLE bukrs FROM (ct_t001b) "#EC SAST_CI_GEN_CHECK
        INTO l_bukrs
        WHERE
*  --In T001B the field containing the Posting Period Variant is called
*    BUKRS instead of OPVAR
*        bukrs = <bukrs>-bukrs AND
        bukrs = <bukrs>-opvar AND

        (
          toye1 >= l_checkyear OR
          toye2 >= l_checkyear
        ).
      ELSE.
        SELECT SINGLE bukrs FROM (ct_t001b) "#EC SAST_CI_GEN_CHECK
        INTO l_bukrs
        WHERE
*  --In T001B the field containing the Posting Period Variant is called
*    BUKRS instead of OPVAR
*        bukrs = <bukrs>-bukrs AND
        bukrs = <bukrs>-opvar AND

        (
          toye1 >= l_checkyear OR
          toye2 >= l_checkyear OR
          toye3 >= l_checkyear
        ).
      ENDIF.
*      endif.
      IF sy-subrc <> 0.
*  --Invalid/Inactive company code
        log et_return 'I' 'BUKRS' <bukrs>-bukrs 'INACTIVE'
                                              'Invalid Posting Period '
                                      '(T001-TOYE1, TOYE2, TOYE3)' .
        CLEAR lf_valid.
      ENDIF.
    ENDIF.
    IF if_values = 'X'.
*  --Append text values for displaying
      et_values-field = 'BUKRS'.
      et_values-vtext = <bukrs>-butxt.
      et_values-low   = <bukrs>-bukrs.
      APPEND et_values.
    ENDIF.
*  --Append records for SWSODORGM Table
    et_swsodorgm-active = lf_valid.
    et_swsodorgm-abb    = <bukrs>-bukrs.
    et_swsodorgm-varbl  = 'BUKRS'.
*   et_swsodorgm-object = ''.
    et_swsodorgm-value  = <bukrs>-bukrs.
    APPEND et_swsodorgm.

  ENDLOOP.
ENDFORM.                    " load_bukrs

*---------------------------------------------------------------------*
*       FORM load_ekorg                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SWSODORGM                                                  *
*  -->  ET_RETURN                                                     *
*  -->  ET_VALUES                                                     *
*  -->  IF_VALUES                                                     *
*---------------------------------------------------------------------*
FORM load_ekorg
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
         lf_t024w type flag.
  FIELD-SYMBOLS : <ekorg> TYPE t_t024e,
                  <werks> TYPE t_t024w.
*--Link to Company Code
  SELECT ekorg bukrs ekotx FROM (ct_t024e) "#EC SAST_CI_GEN_CHECK
      INTO CORRESPONDING FIELDS OF TABLE lt_ekorg.


  LOOP AT lt_ekorg ASSIGNING <ekorg>.
    lf_valid = 'X'.
    READ TABLE et_swsodorgm WITH KEY varbl = 'BUKRS'
                                     value = <ekorg>-bukrs.
    IF sy-subrc <> 0.
*--Invalid Purchasing Org
    ELSE.
      IF et_swsodorgm-active IS INITIAL.
        CLEAR lf_valid.
        log et_return 'I' 'EKORG' <ekorg>-ekorg 'INACTIVE'
                                  'Inactive Company Code'
                                  <ekorg>-bukrs .

      ENDIF.

      IF if_values = 'X'.
*--Append text values for displaying
        et_values-field = 'EKORG'.
        et_values-vtext = <ekorg>-ekotx.
        et_values-low   = <ekorg>-ekorg.
        APPEND et_values.
      ENDIF.
*--Append records for SWSODORGM Table
      et_swsodorgm-active = lf_valid.
      et_swsodorgm-abb    = et_swsodorgm-abb.
      et_swsodorgm-varbl  = 'EKORG'.
*     et_swsodorgm-object = ''.
      et_swsodorgm-value    = <ekorg>-ekorg.
      APPEND et_swsodorgm.
    ENDIF.
  ENDLOOP.


*--Link to plant
  IF if_values = 'X'.
    SORT lt_ekorg BY ekorg.
  ENDIF.
  perform check_table_exists using 'T024W' changing lf_t024w.
  if lf_t024w = 'X'.
    SELECT ekorg werks FROM (ct_t024w) "#EC SAST_CI_GEN_CHECK
    INTO CORRESPONDING FIELDS OF TABLE lt_werks.
  endif.
  LOOP AT lt_werks ASSIGNING <werks>.
    lf_valid = 'X'.
*--Check if EKORG is valid
* ( there can be a record in T042W for an ekorg that no longer exists)
    READ TABLE lt_ekorg WITH KEY ekorg = <werks>-ekorg
    ASSIGNING <ekorg>
    BINARY SEARCH.
    CHECK sy-subrc = 0.
    READ TABLE et_swsodorgm WITH KEY varbl = 'WERKS'
                                     value = <werks>-werks.
    IF sy-subrc <> 0.
*--Invalid Purchasing Org
    ELSE.
      IF et_swsodorgm-active IS INITIAL.
        CLEAR lf_valid.
        log et_return 'I' 'EKORG' <werks>-ekorg 'INACTIVE'
                                  'Inactive Plant'
                                  <werks>-werks .
      ENDIF.

      IF if_values = 'X'.
*--Commented out, the validation check takes care or reading
*  record into fs
*        READ TABLE lt_ekorg WITH KEY ekorg = <werks>-ekorg
*        ASSIGNING <ekorg>
*        BINARY SEARCH.
*        IF sy-subrc = 0.
*--Append text values for displaying
        et_values-field = 'EKORG'.
        et_values-vtext = <ekorg>-ekotx.
        et_values-low   = <werks>-ekorg.
        APPEND et_values.
*        ENDIF.
      ENDIF.
*--Append records for SWSODORGM Table
*       read table et_swsodorgm with key
*                                  varbl = 'EKORG'
*                                  abb = <werks>-ekorg.
*      if sy-subrc <> 0.
      et_swsodorgm-active = lf_valid.
      et_swsodorgm-abb    = et_swsodorgm-abb.
      et_swsodorgm-varbl  = 'EKORG'.
*     et_swsodorgm-object = ''.
      et_swsodorgm-value    = <werks>-ekorg.
      APPEND et_swsodorgm.
*      else.
*        et_swsodorgm-active = lf_valid.
*        modify et_swsodorgm  transporting active
*        where abb   = et_swsodorgm-abb
*         and  varbl = 'EKORG'
*         and  value = <werks>-ekorg.
*     endif.
    ENDIF.
  ENDLOOP.



ENDFORM.

*---------------------------------------------------------------------*
*       FORM load_vstel                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SWSODORGM                                                  *
*  -->  ET_RETURN                                                     *
*  -->  ET_VALUES                                                     *
*  -->  IF_VALUES                                                     *
*---------------------------------------------------------------------*
FORM load_vstel
TABLES
  et_swsodorgm STRUCTURE /psyng/swcfgoe
  et_return    STRUCTURE bapiret2
  et_values    STRUCTURE /psyng/sw_org_values_text
USING
  if_values    TYPE flag
  if_val_cal   TYPE flag.

  DATA : lt_werks TYPE TABLE OF t_tvswz,
         lt_vstel TYPE TABLE OF t_tvst,
         lt_text TYPE TABLE OF t_tvstt WITH HEADER LINE,
         l_ret    TYPE bapireturn1,
         lf_valid TYPE flag,
         lf_valid_cal TYPE flag,
         lf_tvst type flag.
  FIELD-SYMBOLS : <vstel> TYPE t_tvst,
                  <werks> TYPE t_tvswz.

PERFORM check_table_exists
            USING
               'TVST'
            CHANGING
               lf_tvst.
if lf_tvst = 'X'.
*--Shipping points
  SELECT vstel fabkl FROM (ct_TVST) "#EC SAST_CI_GEN_CHECK
  INTO CORRESPONDING FIELDS OF TABLE lt_vstel.
*--Texts
  IF NOT lt_vstel[] IS INITIAL.
    SELECT vstel vtext FROM  (ct_TVSTT) "#EC SAST_CI_GEN_CHECK
    INTO CORRESPONDING FIELDS OF TABLE lt_text
    FOR ALL ENTRIES IN lt_vstel
    WHERE vstel = lt_vstel-vstel AND spras = sy-langu
    .
  ENDIF.
*--Link to Plant
  SELECT * FROM (ct_TVSWZ) "#EC SAST_CI_GEN_CHECK
      INTO CORRESPONDING FIELDS OF TABLE lt_werks.




  LOOP AT lt_vstel ASSIGNING <vstel>.
    lf_valid = 'X' .
*--Only Shipping linked to a valid factory calendar are considered
    PERFORM validate_factory_calendar
                USING
                   <vstel>-fabkl
                CHANGING
                   lf_valid_cal.
***BOC
    IF lf_valid_cal <> 'X' AND if_val_cal = 'X'.
      CLEAR lf_valid.
      log et_return 'I' 'VSTEL' <vstel>-vstel 'INACTIVE'
                                'Invalid Factory Calendar '
                                <vstel>-fabkl .
    ENDIF.

    READ TABLE lt_werks
    ASSIGNING <werks>
    WITH KEY vstel =  <vstel>-vstel.
    IF sy-subrc = 0.
      READ TABLE et_swsodorgm WITH KEY varbl = 'WERKS'
                                       value = <werks>-werks.
      IF sy-subrc <> 0.
*  --Invalid Shipping Point
      ELSE.
        IF et_swsodorgm-active IS INITIAL.
          CLEAR lf_valid.
          log et_return 'I' 'VSTEL' <vstel>-vstel 'INACTIVE'
                                    'Inactive Plant'
                                    <werks>-werks .

        ENDIF.

        IF if_values = 'X'.
*  --Append text values for displaying
          et_values-field = 'VSTEL'.
*          et_values-vtext = <vstel>-ekotx.
          et_values-low   = <vstel>-vstel.
          READ TABLE lt_text WITH KEY vstel = <vstel>-vstel
          BINARY SEARCH.
          IF sy-subrc = 0.
            et_values-vtext = lt_text-vtext.
          ELSE.
            CLEAR et_values-vtext.
          ENDIF.
          APPEND et_values.
        ENDIF.
*  --Append records for SWSODORGM Table
        et_swsodorgm-active   = lf_valid.
        et_swsodorgm-abb      = et_swsodorgm-abb.
        et_swsodorgm-varbl    = 'VSTEL'.
*        et_swsodorgm-object   = ''.
        et_swsodorgm-value    = <vstel>-vstel.
        APPEND et_swsodorgm.
      ENDIF.
    ENDIF.
  ENDLOOP.
endif.



ENDFORM.

*---------------------------------------------------------------------*
*       FORM validate_factory_calendar                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_IDENT                                                       *
*  -->  EF_VALID                                                      *
*---------------------------------------------------------------------*
FORM validate_factory_calendar USING i_ident
                               CHANGING ef_valid TYPE flag.
  STATICS :
  lt_tfacd TYPE TABLE OF t_tfacd WITH HEADER LINE."factory calenda
  DATA :    l_year(4) TYPE c.
  IF lt_tfacd[] IS INITIAL.
*--Load valid factory calendars
    l_year = sy-datum(4).
    SELECT ident vjahr bjahr FROM
      (ct_TFACD) INTO TABLE lt_tfacd "#EC SAST_CI_GEN_CHECK
    WHERE vjahr <= l_year AND bjahr >= l_year.
    SORT lt_tfacd BY ident.
  ENDIF.
  READ TABLE lt_tfacd WITH KEY ident = i_ident
  BINARY SEARCH
  TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    ef_valid = 'X'.
  ELSE.
    CLEAR ef_valid.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM load_vkorg                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SWSODORGM                                                  *
*  -->  ET_RETURN                                                     *
*  -->  ET_VALUES                                                     *
*  -->  IF_VALUES                                                     *
*---------------------------------------------------------------------*
FORM load_vkorg
TABLES
  et_swsodorgm STRUCTURE /psyng/swcfgoe
  et_return    STRUCTURE bapiret2
  et_values    STRUCTURE /psyng/sw_org_values_text
USING
  if_values    TYPE flag
  if_validate_cal TYPE flag.

  DATA : BEGIN OF lt_vkorg OCCURS 0,
          vkorg(4) TYPE c,
          bukrs(4) TYPE c,
          vkokl(2) TYPE c,
          END OF lt_vkorg,
         l_ret    TYPE bapireturn1,
         lf_valid_cal TYPE flag,
         BEGIN OF lt_text OCCURS 0,
         vkorg(4) TYPE c,
         vtext(20) TYPE c,
         END OF lt_text,
         lf_valid TYPE flag,
         lf_tvko  type flag.
  .

  FIELD-SYMBOLS : <vkorg> LIKE lt_vkorg.
*--Get headers
  PERFORM check_table_exists
              USING
                 'TVKO'
              CHANGING
                 lf_tvko.
  if lf_tvko = 'X'.
    SELECT vkorg bukrs vkokl
    FROM (ct_TVKO) "#EC SAST_CI_GEN_CHECK
    INTO CORRESPONDING FIELDS OF TABLE lt_vkorg.
*  --get texts
    IF NOT lt_vkorg[] IS INITIAL.
      SELECT vkorg vtext
      FROM (ct_TVKOT) "#EC SAST_CI_GEN_CHECK
      INTO CORRESPONDING FIELDS OF TABLE lt_text
      FOR ALL ENTRIES IN lt_vkorg
      WHERE vkorg = lt_vkorg-vkorg AND
      spras = sy-langu.
      SORT lt_text BY vkorg.
    ENDIF.
  endif.


*********************************************************************
*--Get Sales Org directly linked to company code
*********************************************************************
  LOOP AT lt_vkorg ASSIGNING <vkorg>.
*--Only Sales orgs linked to a valid factory calendar are considered
    lf_valid = 'X'.
    IF if_validate_cal = 'X'.
      PERFORM validate_factory_calendar
                  USING
                     <vkorg>-vkokl
                  CHANGING
                     lf_valid_cal.
      IF NOT lf_valid_cal = 'X'.
        CLEAR lf_valid.
        log et_return 'I' 'VKORG' <vkorg>-vkorg 'INACTIVE'
                                      'Invalid Factory Calendar '
                                      'TVKO-VKOKL' .

      ENDIF.
    ENDIF.
    READ TABLE et_swsodorgm WITH KEY varbl = 'BUKRS'
                                     value = <vkorg>-bukrs.
    IF sy-subrc <> 0.
*--Invalid Sales Org
    ELSE.
      IF et_swsodorgm-active IS INITIAL.
*--  (company code not active)
        CLEAR lf_valid.
        log et_return 'I' 'VKORG' <vkorg>-vkorg 'INACTIVE'
                                      'Inactive Company Code '
                                      <vkorg>-bukrs .

      ENDIF.
      IF if_values = 'X'.
*--Append text values for displaying
        et_values-field = 'VKORG'.
        et_values-low   = <vkorg>-vkorg.
        READ TABLE lt_text WITH KEY vkorg = <vkorg>-vkorg
        BINARY SEARCH.
        IF sy-subrc = 0.
          et_values-vtext = lt_text-vtext.
        ELSE.
          et_values-vtext = <vkorg>-vkorg.
        ENDIF.
        APPEND et_values.
      ENDIF.
*--Append records for SWSODORGM Table
      et_swsodorgm-active = lf_valid.
      et_swsodorgm-abb    = et_swsodorgm-abb.
      et_swsodorgm-varbl  = 'VKORG'.
*     et_swsodorgm-object = ''.
      et_swsodorgm-value    = <vkorg>-vkorg.
      APPEND et_swsodorgm.
    ENDIF.

  ENDLOOP.
ENDFORM.                    " load_bukrs



*---------------------------------------------------------------------*
*       FORM load_werks                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SWSODORGM                                                  *
*  -->  ET_RETURN                                                     *
*  -->  ET_VALUES                                                     *
*  -->  IF_VALUES                                                     *
*---------------------------------------------------------------------*
FORM load_werks
TABLES
  et_swsodorgm STRUCTURE /psyng/swcfgoe
  et_return    STRUCTURE bapiret2
  et_values    STRUCTURE /psyng/sw_org_values_text
USING
  if_values    TYPE flag
  if_val_cal   TYPE flag.

  DATA : lt_werks TYPE TABLE OF t_t001w,
         lt_links TYPE TABLE OF t_t001k,
         l_ret    TYPE bapireturn1,
         lf_valid_cal  TYPE flag,
         lf_valid TYPE flag.
  FIELD-SYMBOLS : <werks> TYPE t_t001w,
                  <combo> TYPE t_t001k.

  SELECT werks ekorg vkorg name1 fabkl bwkey
    FROM (ct_T001W) "#EC SAST_CI_GEN_CHECK
  INTO CORRESPONDING FIELDS OF TABLE lt_werks.

  SELECT bwkey bukrs FROM (ct_T001K) "#EC SAST_CI_GEN_CHECK
  INTO CORRESPONDING FIELDS OF TABLE lt_links.


  LOOP AT lt_werks ASSIGNING <werks>.
    lf_valid = 'X'.
*--Only Plants linked to a valid factory calendar are considered
    PERFORM validate_factory_calendar
                USING
                   <werks>-fabkl
                CHANGING
                   lf_valid_cal.
***BOC
    IF lf_valid_cal <> 'X' AND if_val_cal = 'X'.
      CLEAR lf_valid.
      log et_return 'I' 'WERKS' <werks>-werks 'INACTIVE'
                                'Invalid Factory Calendar '
                                <werks>-fabkl .
    ENDIF.
    IF <WERKS>-bwkey is initial.
      CLEAR lf_valid.
      log et_return 'I' 'WERKS' <werks>-werks 'INACTIVE'
                                'No Valuation Area Maintained '
                                '' .

    ENDIF.
    LOOP AT lt_links ASSIGNING <combo> WHERE bwkey = <werks>-bwkey .
      READ TABLE et_swsodorgm WITH KEY varbl = 'BUKRS'
                                       value = <combo>-bukrs.
      IF sy-subrc <> 0.
*  --Invalid Plant
      ELSE.
        IF et_swsodorgm-active IS INITIAL.
          CLEAR lf_valid.
          log et_return 'I' 'WERKS' <werks>-werks 'INACTIVE'
                                    'Inactive Company Code'
                                    <combo>-bukrs .
        ENDIF.
        IF if_values = 'X'.
*  --Append text values for displaying
          et_values-field = 'WERKS'.
          et_values-vtext = <werks>-name1.
*          et_values-low   = <combo>-bwkey.
          et_values-low   = <werks>-werks.
          APPEND et_values.


        ENDIF.
*  --Append records for SWSODORGM Table
        et_swsodorgm-active = lf_valid.
        et_swsodorgm-abb    = et_swsodorgm-abb.
        et_swsodorgm-varbl  = 'WERKS'.
*     et_swsodorgm-object = ''.
        et_swsodorgm-value  = <werks>-werks.
*        et_swsodorgm-value  = <combo>-bwkey.
        APPEND et_swsodorgm.
      ENDIF.
    ENDLOOP.

  ENDLOOP.
ENDFORM.                    " load_bukrs



*---------------------------------------------------------------------*
*       FORM load_spart                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SWSODORGM                                                  *
*  -->  ET_RETURN                                                     *
*  -->  ET_VALUES                                                     *
*  -->  IF_VALUES                                                     *
*---------------------------------------------------------------------*
FORM load_spart
TABLES
  et_swsodorgm STRUCTURE /psyng/swcfgoe
  et_return    STRUCTURE bapiret2
  et_values    STRUCTURE /psyng/sw_org_values_text
USING
  if_values    TYPE flag  .

  DATA : BEGIN OF lt_spart OCCURS 0,
           spart(2) TYPE c,
           vkorg(4) TYPE c,
           vtext(20) TYPE c,
         END OF lt_spart,
         begin of lt_tvta occurs 0,
            vkorg(4) type c,
            spart(2) type c,
         end of lt_tvta,
         lt_tspat TYPE TABLE OF t_tspat WITH HEADER LINE,
         l_ret    TYPE bapireturn1,
         l_year(4)   TYPE n,
         lf_valid TYPE flag,
         lf_tvkos type flag,
         lf_TVTA  type flag.
  FIELD-SYMBOLS : <spart> LIKE lt_spart.
PERFORM check_table_exists
            USING
               'TVKOS'
            CHANGING
               lf_tvkos.
PERFORM check_table_exists
            USING
               'TVTA'
            CHANGING
               lf_TVTA.
if lf_tvkos = 'X'.
*--Load Sales Orgs
  SELECT DISTINCT spart vkorg
  FROM (ct_TVKOS) "#EC SAST_CI_GEN_CHECK
  INTO CORRESPONDING FIELDS OF TABLE lt_spart.
  if lf_tvta = 'X'.
*--Validate that the spart and vkorg are define in table  TVTA
    if not lt_spart[] is initial.
      select distinct vkorg spart
        FROM (ct_TVTA) "#EC SAST_CI_GEN_CHECK
        into corresponding fields of table lt_tvta
        for all entries in lt_spart where vkorg = lt_spart-vkorg and
                                          spart = lt_spart-spart.
        sort lt_tvta by spart vkorg.
    endif.

  endif.

  IF if_values = 'X'.
    SELECT spart vtext FROM (ct_TSPAT) "#EC SAST_CI_GEN_CHECK
    INTO CORRESPONDING FIELDS OF TABLE lt_tspat
    WHERE spras = sy-langu.
    SORT lt_tspat BY spart.
  ENDIF.


  SORT lt_spart.
  DELETE ADJACENT DUPLICATES FROM lt_spart.

  LOOP AT lt_spart ASSIGNING <spart>.
    lf_valid = 'X'.
    READ TABLE et_swsodorgm WITH KEY varbl = 'VKORG'
                                     value = <spart>-vkorg.
    IF sy-subrc <> 0.
*--Invalid Sales Org
    ELSE.
      IF et_swsodorgm-active IS INITIAL.
        CLEAR lf_valid.
        log et_return 'I' 'SPART' <spart>-spart 'INACTIVE'
                                  'Inactive Sales Org '
                                  <spart>-vkorg.
      ENDIF.
      if lf_tvta = 'X'.
*--Validate Against TVTA
         read table lt_tvta with key spart = <spart>-spart
                                     vkorg = <spart>-vkorg
                                     binary search TRANSPORTING NO FIELDS.
         if sy-subrc <> 0.
            CLEAR lf_valid.
            log et_return 'I' 'SPART' <spart>-spart 'INACTIVE'
                                      'SPART-VKORG not in TVTA'
                                      <spart>-vkorg.
         endif.

      endif.


      IF if_values = 'X'.
        CLEAR lt_tspat.
        READ TABLE lt_tspat WITH KEY spart = <spart>-spart
        BINARY SEARCH TRANSPORTING vtext.
*--Append text values for displaying
        et_values-field = 'SPART'.
        et_values-vtext = lt_tspat-vtext.
        et_values-low   = <spart>-spart.
        APPEND et_values.
      ENDIF.
*--Append records for SWSODORGM Table
      et_swsodorgm-active = lf_valid.
      et_swsodorgm-abb    = et_swsodorgm-abb.
      et_swsodorgm-varbl  = 'SPART'.
*     et_swsodorgm-object = ''.
      et_swsodorgm-value  = <spart>-spart.
      APPEND et_swsodorgm.
    ENDIF.
  ENDLOOP.
  endif.
ENDFORM.




*---------------------------------------------------------------------*
*       FORM load_vtweg                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SWSODORGM                                                  *
*  -->  ET_RETURN                                                     *
*  -->  ET_VALUES                                                     *
*  -->  IF_VALUES                                                     *
*---------------------------------------------------------------------*
FORM load_vtweg
TABLES
  et_swsodorgm STRUCTURE /psyng/swcfgoe
  et_return    STRUCTURE bapiret2
  et_values    STRUCTURE /psyng/sw_org_values_text
USING
  if_values    TYPE flag  .

  DATA : BEGIN OF lt_vtweg OCCURS 0,
           vtweg(2) TYPE c,
           vkorg(4) TYPE c,
           vtext(20) TYPE c,
         END OF lt_vtweg,

         begin of lt_tvta occurs 0,
            vkorg(4) type c,
            VTWEG(2) type c,
         end of lt_tvta,


         lt_tvtw TYPE TABLE OF t_tvtwt WITH HEADER LINE,
         l_ret    TYPE bapireturn1,
         lf_valid TYPE flag,
         lf_tvkov type flag,
         lf_tvta type flag.

  FIELD-SYMBOLS : <vtweg> LIKE lt_vtweg.
PERFORM check_table_exists
            USING
               'TVKOV'
            CHANGING
               lf_tvkov.

PERFORM check_table_exists
              USING
                 'TVTA'
              CHANGING
                 lf_TVTA.
if lf_tvkov = 'X'.
  SELECT DISTINCT vtweg vkorg  FROM (ct_TVKOV) "#EC SAST_CI_GEN_CHECK
  INTO CORRESPONDING FIELDS OF TABLE lt_vtweg.

if lf_tvta = 'X'.
*--Validate that the spart and vkorg are define in table  TVTA
      if not lt_vtweg[] is initial.
        select distinct vkorg VTWEG
                FROM (ct_TVTA)"#EC SAST_CI_GEN_CHECK
                into corresponding fields of table lt_tvta
                for all entries in lt_vtweg where vkorg = lt_vtweg-vkorg and
                                                  VTWEG = lt_vtweg-VTWEG.
        sort lt_tvta by vtweg vkorg.
      endif.
    endif.

  IF if_values = 'X'.
    SELECT vtweg vtext FROM (ct_TVTWT) "#EC SAST_CI_GEN_CHECK
    INTO CORRESPONDING FIELDS OF TABLE lt_tvtw
    WHERE spras = sy-langu.
    SORT lt_tvtw BY vtweg.
  ENDIF.


  SORT lt_vtweg.
  DELETE ADJACENT DUPLICATES FROM lt_vtweg.

  LOOP AT lt_vtweg ASSIGNING <vtweg>.
    lf_valid = 'X'.
    READ TABLE et_swsodorgm WITH KEY varbl = 'VKORG'
                                     value = <vtweg>-vkorg.
    IF sy-subrc <> 0.
*--Invalid Sales Org
    ELSE.
      IF et_swsodorgm-active IS INITIAL.
        CLEAR lf_valid.
        log et_return 'I' 'VTWEG' <vtweg>-vtweg 'INACTIVE'
                                  'Inactive Sales Org '
                                  <vtweg>-vkorg.

      ENDIF.

       if lf_tvta = 'X'.
*--Validate Against TVTA
          read table lt_tvta with key vtweg = <vtweg>-vtweg
                                      vkorg = <vtweg>-vkorg
                                      binary search TRANSPORTING NO FIELDS.
          if sy-subrc <> 0.
            CLEAR lf_valid.
            log et_return 'I' 'VTWEG' <vtweg>-vtweg 'INACTIVE'
                                      '<vtweg>-VKORG not in TVTA'
                                      <vtweg>-vkorg.
          endif.

        endif.

      IF if_values = 'X'.
        CLEAR lt_tvtw.
        READ TABLE lt_tvtw WITH KEY vtweg = <vtweg>-vtweg
        BINARY SEARCH TRANSPORTING vtext.
*--Append text values for displaying
        et_values-field = 'VTWEG'.
        et_values-vtext = lt_tvtw-vtext.
        et_values-low   = <vtweg>-vtweg.
        APPEND et_values.
      ENDIF.
*--Append records for SWSODORGM Table
      et_swsodorgm-active = lf_valid.
      et_swsodorgm-abb    = et_swsodorgm-abb.
      et_swsodorgm-varbl  = 'VTWEG'.
*     et_swsodorgm-object = ''.
      et_swsodorgm-value    = <vtweg>-vtweg.
      APPEND et_swsodorgm.
    ENDIF.

  ENDLOOP.
  endif.
ENDFORM.                    " load_bukrs
*&---------------------------------------------------------------------*
*&      Form  load_gsber
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ET_SWSODORGM  text
*      -->P_ET_RETURN  text
*      -->P_ET_VALUES  text
*      -->P_LF_VALUES  text
*----------------------------------------------------------------------*
FORM load_gsber
TABLES
  et_swsodorgm STRUCTURE /psyng/swcfgoe
  et_return    STRUCTURE bapiret2
  et_values    STRUCTURE /psyng/sw_org_values_text
USING
  if_values    TYPE flag.
  DATA : lt_t134g TYPE TABLE OF t_t134g WITH HEADER LINE,
         lt_t134h TYPE TABLE OF t_t134h WITH HEADER LINE,
         lt_t100k TYPE TABLE OF t_t001k WITH HEADER LINE,
         lt_tgsbt TYPE TABLE OF t_tgsbt WITH HEADER LINE.


  FIELD-SYMBOLS : <gsber> TYPE t_t134g,
                  <gsber2> TYPE t_t134h.
  TYPES: BEGIN OF ty_t001w,
          werks TYPE char4,
          bwkey TYPE char4,
         END OF ty_t001w,

         BEGIN OF ty_t001k,
          bwkey TYPE char4,
          bukrs TYPE char4,
         END OF ty_t001k.

  DATA: lv_bwkrs TYPE char1,
        lv_tab_name TYPE char30.

  DATA: r_bukrs TYPE RANGE OF char4,
        r_bukrs_l LIKE LINE OF r_bukrs.

  DATA: lt_t001k TYPE TABLE OF ty_t001k,
        ls_t001k TYPE ty_t001k,
        lt_t001w TYPE TABLE OF ty_t001w,
        ls_t001w TYPE ty_t001w,
        lf_valid TYPE flag,
        lf_tgsbt type flag.


  CONSTANTS: c_tcurm TYPE char5 VALUE 'TCURM'.

PERFORM check_table_exists
            USING
               'TGSBT'
            CHANGING
               lf_tgsbt.

if lf_tgsbt = 'X'.
  SELECT SINGLE tabname FROM dd02l
                        INTO lv_tab_name
                        WHERE tabname = c_tcurm."#EC SAST_CI_GEN_CHECK
  IF sy-subrc EQ 0.
    SELECT SINGLE bwkrs_cus
           FROM (lv_tab_name) INTO lv_bwkrs.
  ENDIF.
  IF if_values = 'X'.
    SELECT gsber gtext FROM (ct_TGSBT) "#EC SAST_CI_GEN_CHECK
    INTO CORRESPONDING FIELDS OF TABLE lt_tgsbt
    WHERE spras = sy-langu.
    SORT lt_tgsbt BY gsber.
  ENDIF.

  IF lv_bwkrs = 3.
*--Load Business Areas  (GSBER)
*     linked to Company Code (BUKRS)
*     TCODE OMJ7 - View V_134H - table T001K (val area to bukrs)

    SELECT bwkey spart gsber FROM (ct_T134H) "#EC SAST_CI_GEN_CHECK
    INTO CORRESPONDING FIELDS OF TABLE lt_t134h.
    SORT lt_t134h BY bwkey.
    SORT lt_t100k BY bukrs.

    IF NOT lt_t134h[] IS INITIAL.
      SELECT bukrs bwkey FROM (ct_T001K) "#EC SAST_CI_GEN_CHECK
           INTO CORRESPONDING FIELDS OF TABLE lt_t100k
      FOR ALL ENTRIES IN lt_t134h WHERE bwkey =  lt_t134h-bwkey.
    ENDIF.
    LOOP AT lt_t100k.
      lf_valid = 'X'.
      READ TABLE lt_t134h WITH KEY bwkey = lt_t100k-bwkey
      BINARY SEARCH
      ASSIGNING <gsber2>.
      IF sy-subrc = 0.
        READ TABLE et_swsodorgm WITH KEY varbl = 'BUKRS'
                                         value =  lt_t100k-bukrs.
        IF sy-subrc <> 0.
*  --Invalid Business Areas
        ELSE.
          IF et_swsodorgm-active IS INITIAL.
            CLEAR lf_valid.
            log et_return 'I' 'GSBER' <gsber2>-gsber 'INACTIVE'
                          'Inactive Company Code '
                          lt_t100k-bukrs.
          ENDIF.
          IF if_values = 'X'.
            CLEAR lt_tgsbt.
            READ TABLE lt_tgsbt WITH KEY gsber = <gsber2>-gsber
            BINARY SEARCH TRANSPORTING gtext.
*  --Append text values for displaying
            et_values-field = 'GSBER'.
            et_values-vtext = lt_tgsbt-gtext.
            et_values-low   = <gsber2>-gsber.
            APPEND et_values.
          ENDIF.
*  --Append records for SWSODORGM Table
          et_swsodorgm-active = lf_valid.
          et_swsodorgm-abb    = et_swsodorgm-abb.
          et_swsodorgm-varbl  = 'GSBER'.
*     et_swsodorgm-object = ''.
          et_swsodorgm-value    = <gsber2>-gsber.
          APPEND et_swsodorgm.
        ENDIF.
      ENDIF.
    ENDLOOP.


*--Load Business Areas (GSBER) linked to Plants (WERKS)
*     TCODE OMJ7 - View V_T134G_WS
  ELSE.
    LOOP AT et_swsodorgm WHERE varbl = 'BUKRS'.
      r_bukrs_l-option = 'EQ'.
      r_bukrs_l-sign = 'I'.
      r_bukrs_l-low = et_swsodorgm-value.
      APPEND r_bukrs_l TO r_bukrs.
      CLEAR: r_bukrs_l.
    ENDLOOP.

    IF NOT r_bukrs[] IS INITIAL.
      SELECT bwkey
             bukrs
             FROM (ct_T001K) "#EC SAST_CI_GEN_CHECK
             INTO TABLE lt_t001k
             FOR ALL ENTRIES IN r_bukrs
             WHERE bukrs = r_bukrs-low.
      IF sy-subrc EQ 0 and not lt_t001k[] is initial.
        SELECT werks
               bwkey
               FROM (ct_T001W) "#EC SAST_CI_GEN_CHECK
               INTO TABLE lt_t001w
               FOR ALL ENTRIES IN lt_t001k
               WHERE bwkey = lt_t001k-bwkey.
      ENDIF.
    ENDIF.

    SELECT werks spart gsber FROM (ct_T134G) "#EC SAST_CI_GEN_CHECK
    INTO CORRESPONDING FIELDS OF TABLE lt_t134g.
    LOOP AT lt_t134g ASSIGNING <gsber>.
      lf_valid = 'X'.
      READ TABLE lt_t001w INTO ls_t001w WITH KEY werks = <gsber>-werks.
      IF sy-subrc EQ 0.
      READ TABLE lt_t001k INTO ls_t001k WITH KEY bwkey = ls_t001w-bwkey.
        IF sy-subrc EQ 0.
          READ TABLE et_swsodorgm WITH KEY varbl = 'BUKRS'
                                           value =  ls_t001k-bukrs.
          IF sy-subrc <> 0.
*--Invalid Business Areas
          ELSE.
            IF et_swsodorgm-active IS INITIAL.
              CLEAR lf_valid.
              log et_return 'I' 'GSBER' <gsber>-gsber 'INACTIVE'
                            'Inactive Company Code '
                            lt_t100k-bukrs.
            ENDIF.

            IF if_values = 'X'.
              CLEAR lt_tgsbt.
              READ TABLE lt_tgsbt WITH KEY gsber = <gsber>-gsber
              BINARY SEARCH TRANSPORTING gtext.
*--Append text values for displaying
              et_values-field = 'GSBER'.
              et_values-vtext = lt_tgsbt-gtext.
              et_values-low   = <gsber>-gsber.
              APPEND et_values.
            ENDIF.
*--Append records for SWSODORGM Table
            et_swsodorgm-active = lf_valid.
            et_swsodorgm-abb    = et_swsodorgm-abb.
            et_swsodorgm-varbl  = 'GSBER'.
*     et_swsodorgm-object = ''.
            et_swsodorgm-value  = <gsber>-gsber.
            APPEND et_swsodorgm.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.
  endif.

ENDFORM.                    " load_gsber
*---------------------------------------------------------------------*
*       FORM load_kokrs                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SWSODORGM                                                  *
*  -->  ET_RETURN                                                     *
*  -->  ET_VALUES                                                     *
*  -->  IF_VALUES                                                     *
*---------------------------------------------------------------------*
FORM load_kokrs
TABLES
  et_swsodorgm STRUCTURE /psyng/swcfgoe
  et_return    STRUCTURE bapiret2
  et_values    STRUCTURE /psyng/sw_org_values_text
USING
  if_values    TYPE flag  .



  DATA : lt_kokrs TYPE TABLE OF t_tka02 WITH HEADER LINE,
         lt_tka01 TYPE TABLE OF t_tka01 WITH HEADER LINE,
         lf_valid TYPE flag,
         lf_tka02 type flag.
PERFORM check_table_exists
            USING
               'TKA02'
            CHANGING
               lf_tka02.
if lf_tka02 = 'X'.
  SELECT DISTINCT bukrs kokrs FROM (ct_TKA02) "#EC SAST_CI_GEN_CHECK
  INTO CORRESPONDING FIELDS OF TABLE
  lt_kokrs.

  FIELD-SYMBOLS : <kokrs> TYPE t_tka02.

  SELECT kokrs bezei lmona FROM (ct_TKA01) "#EC SAST_CI_GEN_CHECK
  INTO CORRESPONDING FIELDS OF TABLE lt_tka01.

  SORT lt_tka01 BY kokrs.
  LOOP AT lt_kokrs ASSIGNING <kokrs>.
    lf_valid = 'X'.
    READ TABLE et_swsodorgm WITH KEY varbl = 'BUKRS'
                                     value = <kokrs>-bukrs.
    IF sy-subrc <> 0.
*--Invalid Sales Org
    ELSE.
      IF et_swsodorgm-active IS INITIAL.
        CLEAR lf_valid.
        log et_return 'I' 'KOKRS' <kokrs>-kokrs 'INACTIVE'
                      'Inactive Company Code '
                      <kokrs>-bukrs.
      ENDIF.
      READ TABLE lt_tka01 WITH KEY kokrs = <kokrs>-kokrs
      BINARY SEARCH TRANSPORTING bezei.
      IF sy-subrc <> 0.
        CLEAR lf_valid.
        log et_return 'I' 'KOKRS' <kokrs>-kokrs 'INACTIVE'
                      'Controlling Area no defined '
                      'TKA02'.
*--TODO : check fiscal year variant lmona
      ENDIF.

      IF if_values = 'X'.
*--Append text values for displaying
        et_values-field = 'KOKRS'.
        et_values-vtext = lt_tka01-bezei.
        et_values-low   = <kokrs>-kokrs.
        APPEND et_values.
      ENDIF.
*--Append records for SWSODORGM Table
      et_swsodorgm-active = lf_valid.
      et_swsodorgm-abb    = et_swsodorgm-abb.
      et_swsodorgm-varbl  = 'KOKRS'.
*     et_swsodorgm-object = ''.
      et_swsodorgm-value  = <kokrs>-kokrs.
      APPEND et_swsodorgm.
    ENDIF.
  ENDLOOP.
  endif.
ENDFORM.                    " load_KOKRS


*---------------------------------------------------------------------*
*       FORM load_kkber                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SWSODORGM                                                  *
*  -->  ET_RETURN                                                     *
*  -->  ET_VALUES                                                     *
*  -->  IF_VALUES                                                     *
*---------------------------------------------------------------------*
FORM load_kkber
TABLES
  et_swsodorgm STRUCTURE /psyng/swcfgoe
  et_return    STRUCTURE bapiret2
  et_values    STRUCTURE /psyng/sw_org_values_text
USING
  if_values    TYPE flag  .
*--Load Control Area (KKBER)
*     linked to Company Code (BUKRS)
*     TCODE OX19 - View V_TKA02



  DATA :
         lt_kkbert TYPE TABLE OF t_t014t WITH HEADER LINE,
         lt_t001   TYPE TABLE OF t_t001 WITH HEADER LINE,
         lt_t001cm TYPE TABLE OF t_t001cm WITH HEADER LINE,
         lf_valid  TYPE flag,
         lf_t001cm type flag.
PERFORM check_table_exists
            USING
               'T001CM'
            CHANGING
               lf_t001cm.

if lf_t001cm = 'X'.
  SELECT DISTINCT bukrs kkber FROM (ct_T001) "#EC SAST_CI_GEN_CHECK
  INTO CORRESPONDING FIELDS OF TABLE
  lt_t001 WHERE kkber <> ''.

SELECT DISTINCT bukrs kkber FROM (ct_T001CM) "#EC SAST_CI_GEN_CHECK
  INTO CORRESPONDING FIELDS OF TABLE
  lt_t001cm.


  FIELD-SYMBOLS : <kkber> TYPE t_t014t,
                  <t001>  TYPE t_t001,
                  <t001cm>  TYPE t_t001cm.

  SELECT kkber kkbtx FROM (ct_T014T) "#EC SAST_CI_GEN_CHECK
  INTO CORRESPONDING FIELDS OF TABLE lt_kkbert
  WHERE spras = sy-langu.

  SORT lt_kkbert BY kkber.
*--2016/09/27 - Also look at direct assignments in T001 table
  LOOP AT lt_t001.
    MOVE-CORRESPONDING lt_t001 TO lt_t001cm.
    APPEND lt_t001cm.
  ENDLOOP.
  SORT lt_t001cm BY kkber.


  LOOP AT lt_t001cm ASSIGNING <t001cm>.
    lf_valid = 'X'.
    READ TABLE et_swsodorgm WITH KEY varbl = 'BUKRS'
                                     value = <t001cm>-bukrs.
    IF sy-subrc <> 0.
*--Invalid company code
    ELSE.
      IF et_swsodorgm-active IS INITIAL.
        CLEAR lf_valid.
        log et_return 'I' 'KKBER' <t001cm>-kkber 'INACTIVE'
                      'Inactive Company Code '
                      <t001cm>-bukrs.
      ENDIF.

      IF if_values = 'X'.
        et_values-field = 'KKBER'.
        et_values-low   = <t001cm>-kkber.
*--Append text values for displaying
        READ TABLE lt_kkbert WITH KEY kkber = <t001cm>-kkber
        BINARY SEARCH TRANSPORTING ALL FIELDS.
        IF sy-subrc = 0.
          et_values-vtext = lt_kkbert-kkbtx.
        ELSE.
          et_values-vtext = et_values-low.
        ENDIF.
        APPEND et_values.
      ENDIF.

*--Append records for SWSODORGM Table
      et_swsodorgm-active = lf_valid.
      et_swsodorgm-abb    = et_swsodorgm-abb.
      et_swsodorgm-varbl  = 'KKBER'.
*     et_swsodorgm-object = ''.
      et_swsodorgm-value    = <t001cm>-kkber.
      APPEND et_swsodorgm.
    ENDIF.
  ENDLOOP.
  endif.
ENDFORM.                    " load_kkber


*---------------------------------------------------------------------*
*       FORM get_values                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_VAREL                                                      *
*  -->  ET_LOG                                                        *
*  -->  IT_FAOBJ                                                      *
*  -->  IT_ELEMENTS                                                   *
*  -->  I_CHECKTABLE                                                  *
*---------------------------------------------------------------------*
FORM get_values TABLES   it_varel     STRUCTURE  gt_varel
                         et_log       STRUCTURE  bapiret2
                         it_faobj     STRUCTURE  /psyng/faobj2
                USING    it_elements  LIKE gt_varel
                         i_checktable TYPE tabname.
  DATA: BEGIN OF lt_where OCCURS 0,
          line(60) TYPE c ,
        END OF lt_where,
        lt_valuesets LIKE TABLE OF gt_varel WITH HEADER LINE,
        lt_values LIKE TABLE OF gt_varel WITH HEADER LINE,
        lt_fields LIKE TABLE OF  gt_varel WITH HEADER LINE,
        lt_dfies     TYPE TABLE OF dfies,
        lt_fnames  TYPE TABLE OF fieldname WITH HEADER LINE,
        lt_results TYPE TABLE OF /psyng/value WITH HEADER LINE,
        lt_faobj_new TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
        l_validx TYPE i.
  lt_fnames = it_elements-element.
  APPEND lt_fnames.
  lt_valuesets[] = it_varel[].
  DELETE lt_valuesets WHERE var_element <> it_elements-var_element.
  SORT lt_valuesets BY valueset.
  lt_values[] = lt_valuesets[].
  DELETE ADJACENT DUPLICATES FROM lt_valuesets COMPARING valueset.
  SORT lt_values BY valueset field.
*--Load all fields of checktable
  CALL FUNCTION 'DDIF_FIELDINFO_GET'
       EXPORTING
            tabname        = i_checktable
       TABLES
            dfies_tab      = lt_dfies
       EXCEPTIONS
            not_found      = 1
            internal_error = 2
            OTHERS         = 3.
  IF sy-subrc <> 0.
    log et_log 'E' 'TABLENOTFOUND'
     'Table not found :'
     i_checktable
     it_elements-var_element ''.
  ELSE.
    SORT lt_dfies BY fieldname.
    LOOP AT lt_valuesets.
      lt_fields[] = lt_values[].
      DELETE lt_fields WHERE valueset <> lt_valuesets-valueset.
      DELETE ADJACENT DUPLICATES FROM lt_fields COMPARING field.
      REFRESH lt_where.
*      delete lt_fields where valueset <> lt_valuesets-valueset.
      LOOP AT lt_fields.
        IF sy-tabix <> 1.
          where lt_where 'AND' ''  .
        ENDIF.
        where lt_where '(' ''  .
        CLEAR l_validx.
        LOOP AT lt_values WHERE field    = lt_fields-field AND
                                valueset = lt_valuesets-valueset.
          ADD 1 TO l_validx.
          IF l_validx <> 1.
            where lt_where 'OR' ''  .
          ENDIF.
          IF lt_values-val_to IS INITIAL.
            IF lt_values-val_from CA '*+'.
              WHILE lt_values-val_from CS '*'.
                REPLACE '*' WITH '%' INTO lt_values-val_from.
              ENDWHILE.
              WHILE lt_values-val_from CS '+'.
                REPLACE '+' WITH '_' INTO lt_values-val_from.
              ENDWHILE.
              wherefield lt_where lt_fields-field 'LIKE'
                             lt_values-val_from .
            ELSE.
              wherefield lt_where lt_fields-field '='
                             lt_values-val_from .
            ENDIF.
          ELSE.
            where lt_where  '(' ''.
            wherefield lt_where lt_fields-field '>='
                                lt_values-val_from.

            where lt_where  'AND' ''.
            wherefield lt_where lt_fields-field '<='
                            lt_values-val_to.
            where lt_where ')' ''.
          ENDIF.
        ENDLOOP.
        where lt_where ')' ''.
      ENDLOOP.
      REFRESH : lt_results.
      SELECT (lt_fnames)
      FROM   (i_checktable)
      INTO lt_results
      WHERE  (lt_where) . "#EC SAST_CI_GEN_CHECK
*HBHALLA: As table name is variable so it can’t be fixed. (13/12/24)
        APPEND lt_results.
      ENDSELECT.
*--Put the values in the SOD Matrix
      LOOP AT it_faobj WHERE val_from = it_elements-var_element.
        MOVE-CORRESPONDING it_faobj TO lt_faobj_new.
        LOOP AT lt_results.
          lt_faobj_new-val_from = lt_results.
          APPEND lt_faobj_new.
        ENDLOOP.
      ENDLOOP.
      REFRESH : lt_results.
    ENDLOOP.
    DELETE it_faobj WHERE val_from = it_elements-var_element..
    APPEND LINES OF lt_faobj_new TO it_faobj.
    SORT it_faobj.
  ENDIF.
ENDFORM.                    " get_values




*---------------------------------------------------------------------*
*       FORM load_ekorg_rel                                           *
*---------------------------------------------------------------------*
*       Load EKORG, but use the BUKRS_EKORG as the ABB                *
*---------------------------------------------------------------------*
*  -->  ET_SWSODORGM                                                  *
*  -->  ET_RETURN                                                     *
*  -->  ET_VALUES                                                     *
*  -->  IF_VALUES                                                     *
*---------------------------------------------------------------------*
FORM load_ekorg_rel
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
         lf_t024w type flag.
  FIELD-SYMBOLS : <ekorg> TYPE t_t024e,
                  <werks> TYPE t_t024w.
*--Link to Company Code
  SELECT ekorg bukrs ekotx FROM (ct_T024E) "#EC SAST_CI_GEN_CHECK
  INTO CORRESPONDING FIELDS OF TABLE lt_ekorg.


  LOOP AT lt_ekorg ASSIGNING <ekorg>.
    lf_valid  = 'X'.
    READ TABLE et_swsodorgm WITH KEY varbl = 'BUKRS'
                                     value = <ekorg>-bukrs.
    IF sy-subrc = 0.
*--Invalid Purchasing Org
      IF et_swsodorgm-active IS INITIAL.
        CLEAR lf_valid.
        log et_return 'I' 'EKORG' <ekorg>-ekorg 'INACTIVE'
                                  'Inactive Company Code '
                                  <ekorg>-bukrs .

      ENDIF.
      IF if_values = 'X'.
*--Append text values for displaying
        et_values-field = 'EKORG'.
        et_values-vtext = <ekorg>-ekotx.
        et_values-low   = <ekorg>-ekorg.
        APPEND et_values.
      ENDIF.
*--Append records for SWSODORGM Table
      CONCATENATE <ekorg>-bukrs '_' <ekorg>-ekorg INTO et_swsodorgm-abb.
      et_swsodorgm-active  = lf_valid.
      et_swsodorgm-abb     = et_swsodorgm-abb.
      et_swsodorgm-varbl   = 'EKORG'.
*      et_swsodorgm-object  = ''.
      et_swsodorgm-value   = <ekorg>-ekorg.
      APPEND et_swsodorgm.
    ENDIF.
  ENDLOOP.


*--Link to plant
  IF if_values = 'X'.
    SORT lt_ekorg BY ekorg.
  ENDIF.
  perform check_table_exists using 'T024W' changing lf_t024w.
  if lf_t024w = 'X'.
  SELECT ekorg werks FROM (ct_T024W) "#EC SAST_CI_GEN_CHECK
  INTO CORRESPONDING FIELDS OF TABLE lt_werks.
  LOOP AT lt_werks ASSIGNING <werks>.
    lf_valid  = 'X'.
*--Check if EKORG is valid
* ( there can be a record in T042W for an ekorg that no longer exists)
    READ TABLE lt_ekorg WITH KEY ekorg = <werks>-ekorg
    ASSIGNING <ekorg>
    BINARY SEARCH.
    IF sy-subrc <> 0.
      CLEAR lf_valid.
      log et_return 'I' 'EKORG'  <werks>-ekorg 'INACTIVE'
                                 'Invalid EKORG linked to plant '
                                 <werks>-werks .

    ENDIF.
    READ TABLE et_swsodorgm WITH KEY varbl = 'BUKRS'
                                     value = <ekorg>-bukrs.
    IF sy-subrc = 0.
      IF et_swsodorgm-active IS INITIAL.
        CLEAR lf_valid.
        log et_return 'I' 'EKORG'  <ekorg>-ekorg 'INACTIVE'
                               'Inactive Company Code '
                                <ekorg>-bukrs.
      ENDIF.
      IF if_values = 'X'.
*  --Append text values for displaying
        et_values-field = 'EKORG'.
        et_values-vtext = <ekorg>-ekotx.
        et_values-low   = <werks>-ekorg.
        APPEND et_values.
      ENDIF.
*  --Append records for SWSODORGM Table
      CONCATENATE <ekorg>-bukrs '_' <ekorg>-ekorg INTO et_swsodorgm-abb.
      et_swsodorgm-abb    = et_swsodorgm-abb.
*     et_swsodorgm-object = ''.
      et_swsodorgm-varbl  = 'EKORG'.
      et_swsodorgm-value    = <werks>-ekorg.
      APPEND et_swsodorgm.
      et_swsodorgm-varbl  = 'WERKS'.
      et_swsodorgm-value    = <werks>-werks.
      APPEND et_swsodorgm.
    ENDIF.
  ENDLOOP.
  endif.


ENDFORM.                    " load_bukrs


*---------------------------------------------------------------------*
*       FORM load_werks_rel                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SWSODORGM                                                  *
*  -->  ET_RETURN                                                     *
*  -->  ET_VALUES                                                     *
*  -->  IF_VALUES                                                     *
*---------------------------------------------------------------------*
FORM load_werks_rel
TABLES
  et_swsodorgm STRUCTURE /psyng/swcfgoe
  et_return    STRUCTURE bapiret2
  et_values    STRUCTURE /psyng/sw_org_values_text
USING
  if_values    TYPE flag
  if_val_cal   TYPE flag.

  DATA : lt_werks TYPE TABLE OF t_t001w,
         lt_links TYPE TABLE OF t_t001k,
         lt_ekorg TYPE TABLE OF t_t024e,
         l_ret    TYPE bapireturn1,
         lf_valid_cal  TYPE flag,
         lf_valid TYPE flag.
  FIELD-SYMBOLS : <werks> TYPE t_t001w,
                  <combo> TYPE t_t001k.

  SELECT werks ekorg vkorg name1 fabkl
    FROM (ct_T001W) "#EC SAST_CI_GEN_CHECK
  INTO CORRESPONDING FIELDS OF TABLE lt_werks.

  SELECT bwkey bukrs FROM (ct_T001K) "#EC SAST_CI_GEN_CHECK
  INTO CORRESPONDING FIELDS OF TABLE lt_links.

*--Link to Company Code
  SELECT ekorg bukrs ekotx FROM (ct_T024E) "#EC SAST_CI_GEN_CHECK
  INTO CORRESPONDING FIELDS OF TABLE lt_ekorg.



  LOOP AT lt_werks ASSIGNING <werks>.
    lf_valid = 'X'.
*--Only Plants linked to a valid factory calendar are considered
    PERFORM validate_factory_calendar
                USING
                   <werks>-fabkl
                CHANGING
                   lf_valid_cal.
    IF lf_valid_cal <> 'X' AND if_val_cal = 'X'.
      CLEAR lf_valid.
      log et_return 'I' 'WERKS' <werks>-werks 'INACTIVE'
                                    'Invalid Factory Calendar '
                                    <werks>-fabkl .

    ENDIF.
    LOOP AT lt_links ASSIGNING <combo> WHERE bwkey = <werks>-werks .
      READ TABLE et_swsodorgm WITH KEY varbl = 'BUKRS'
                                       value = <combo>-bukrs .
      IF sy-subrc <> 0.
*  --Invalid Plant
      ELSE.
        IF et_swsodorgm-active <> 'X'.
*--        (company code not actice)
          CLEAR lf_valid.
          log et_return 'I' 'WERKS' <werks>-werks 'INACTIVE'
                                        'Inactive Company Code '
                                        <combo>-bukrs .

        ENDIF.
        IF if_values = 'X'.
*  --Append text values for displaying
          et_values-field = 'WERKS'.
          et_values-vtext = <werks>-name1.
          et_values-low   = <combo>-bwkey.
          APPEND et_values.
        ENDIF.
*  --Append records for SWSODORGM Table
        et_swsodorgm-active = lf_valid.
        et_swsodorgm-abb    = et_swsodorgm-abb.
        et_swsodorgm-varbl  = 'WERKS'.
*     et_swsodorgm-object = ''.
        et_swsodorgm-value  = <combo>-bwkey.
        APPEND et_swsodorgm.

*********************************************************************
*--Get Plant Direcly linked to Purchase Org
*********************************************************************
        READ TABLE lt_ekorg WITH KEY bukrs = <combo>-bukrs
                                     ekorg = <werks>-ekorg
        TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
*--Invalid Plant
        ELSE.
          IF if_values = 'X'.
*--Append text values for displaying
            et_values-field = 'WERKS'.
            et_values-vtext = <werks>-name1.
            et_values-low   = <werks>-werks.
            APPEND et_values.
          ENDIF.
*--Append records for SWSODORGM Table
          et_swsodorgm-active = lf_valid.
          CONCATENATE
          <combo>-bukrs '_' <werks>-ekorg INTO et_swsodorgm-abb.
          et_swsodorgm-abb    = et_swsodorgm-abb.
          et_swsodorgm-varbl  = 'WERKS'.
*     et_swsodorgm-object = ''.
          et_swsodorgm-value    = <werks>-werks.
          APPEND et_swsodorgm.
        ENDIF.
      ENDIF.
    ENDLOOP.

  ENDLOOP.

ENDFORM.                    " load_bukrs



*---------------------------------------------------------------------*
*       FORM check_join_table                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_JOIN                                                       *
*  -->  I_RECORD                                                      *
*  -->  I_TABNAME                                                     *
*  -->  EF_MATCH                                                      *
*  -->  IT_RANGES                                                     *
*---------------------------------------------------------------------*
FORM check_join_table  TABLES
                                it_join STRUCTURE gt_join
                       USING    i_record  TYPE any
                                i_tabname TYPE tabname
                       CHANGING ef_match TYPE flag
                                it_ranges TYPE rsds_trange.
  DATA : l_jointab      TYPE tabname,
         lr_jointable   TYPE REF TO data,
         ls_range       TYPE rsds_range,
         lt_ranges_join TYPE rsds_trange,
         lt_where_j     TYPE rsds_twhere,
         lf_join_match  TYPE flag,
         ls_range_line  TYPE rsds_frange,
         ls_selopt      TYPE rsdsselopt,
         ls_where       TYPE rsds_where.
  FIELD-SYMBOLS : <joinfield>,<field>,
                  <jointable>  TYPE      STANDARD  TABLE,
                  <joinrecord> TYPE      ANY.
*BOC UMITTAL CLEAN CORE FIXES 11/03/2026
  DATA :  lr_tabl     TYPE REF TO data.
  FIELD-SYMBOLS: <lt_temp> TYPE ANY TABLE.
*EOC UMITTAL CLEAN CORE FIXES 11/03/2026
  CLEAR : l_jointab, ef_match.
  READ TABLE it_join WITH KEY table = i_tabname.
  IF sy-subrc = 0.
    l_jointab = it_join-jointable.
  ENDIF.
  IF l_jointab IS INITIAL.
*--No Joins found all records are a match
    ef_match = 'X'.
  ELSE.
    PERFORM create_table
    USING    l_jointab
             'JOIN'
    CHANGING lr_jointable.
    IF NOT lr_jointable IS INITIAL.
      ASSIGN lr_jointable->* TO <jointable>.

      READ TABLE it_ranges WITH KEY tablename = l_jointab
      INTO ls_range.
      IF ls_range-tablename IS INITIAL.
        ls_range-tablename = l_jointab.
      ENDIF.

      REFRESH : lt_ranges_join , lt_where_j.
      LOOP AT it_join WHERE table     = i_tabname AND
                            jointable = l_jointab.
        REFRESH : ls_range_line-selopt_t.
        ls_range_line-fieldname = it_join-joinfield.
        ls_selopt-sign   = 'I'.
        ls_selopt-option = 'EQ'.
        ASSIGN COMPONENT it_join-field OF STRUCTURE i_record TO <field>.
"#EC PATHLOCK_CI_DYN_ACCES
        ls_selopt-low    = <field>.
        ls_selopt-high   = ''.
        APPEND ls_selopt TO ls_range_line-selopt_t.
        APPEND ls_range_line TO ls_range-frange_t.
      ENDLOOP.
*    --Remove this joins inverse after it's handled
      DELETE it_join WHERE
      ( jointable = i_tabname AND table = l_jointab ).

      APPEND ls_range TO lt_ranges_join.
      CALL FUNCTION 'FREE_SELECTIONS_RANGE_2_WHERE'
           EXPORTING
                field_ranges  = lt_ranges_join[]
           IMPORTING
                where_clauses = lt_where_j[].
      READ TABLE lt_where_j WITH KEY tablename = l_jointab
      INTO ls_where.
*-- dynamic sql fields are already sanitized/escaped
*  (search for "*--Sanitize" in calling FM /PSYNG/SW_VE_002)
*BOC UMITTAL CLEAN CORE FIXES 11/03/2026
            CALL METHOD /psyng/sw_dynamic_select=>select_into_table
              EXPORTING
                i_tabname      =     l_jointab
                it_where_tab   =     ls_where-where_tab
              IMPORTING
                e_data         = lr_tabl.
            IF lr_tabl IS BOUND.
              ASSIGN lr_tabl->* TO <lt_temp>.
              IF <lt_temp> IS ASSIGNED.
                <jointable> = <lt_temp>.
              ENDIF.
            ENDIF.
*      SELECT * FROM (l_jointab)
*                 INTO CORRESPONDING FIELDS OF TABLE  <jointable>
*    WHERE (ls_where-where_tab). "#EC SAST_CI_GEN_CHECK
*EOC UMITTAL CLEAN CORE FIXES 11/03/2026
      IF NOT <jointable>[] IS INITIAL.
        LOOP AT <jointable> ASSIGNING <joinrecord>.
          PERFORM check_join_table
                      TABLES
                         it_join
                      USING
                         <joinrecord>
                         l_jointab
                      CHANGING
                         lf_join_match
                         it_ranges.
          IF lf_join_match = 'X'.
            ef_match = 'X'.
            EXIT."one match is enough
          ENDIF.
        ENDLOOP.
      ELSE.
        CLEAR ef_match. "not a matching record
      ENDIF.
    ELSE.
      MESSAGE s002(/psyng/sw) WITH
      'Join Table can not be generated'
      l_jointab.

    ENDIF.
  ENDIF.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM create_table                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_TYPE                                                        *
*  -->  ER_TABLE                                                      *
*---------------------------------------------------------------------*
FORM create_table USING    i_type
                           i_purpose
                  CHANGING er_table TYPE any.
  DATA : lt_fieldcat TYPE lvc_t_fcat,
         lt_dfies    TYPE TABLE OF dfies WITH HEADER LINE,
         ls_fieldcat TYPE lvc_s_fcat.

  TYPES : BEGIN OF typ_tables,
    name  TYPE tabname,
    purpose TYPE tabname,
    table TYPE REF TO data,
          END OF typ_tables.
  STATICS : st_tables TYPE HASHED TABLE OF typ_tables
            WITH UNIQUE KEY name purpose WITH HEADER LINE.

  READ TABLE st_tables WITH TABLE KEY name    = i_type
                                      purpose = i_purpose.
  IF sy-subrc = 0.
    er_table = st_tables-table.
  ELSE.

    PERFORM get_dfies
                TABLES
                   lt_dfies
                USING
                   i_type.
    SORT lt_dfies BY position.
    LOOP AT lt_dfies.
      MOVE-CORRESPONDING lt_dfies TO ls_fieldcat.
      ADD 1 TO ls_fieldcat-col_pos.
      ls_fieldcat-fieldname = lt_dfies-fieldname.
      ls_fieldcat-intlen    = lt_dfies-intlen.

      APPEND ls_fieldcat TO lt_fieldcat.
    ENDLOOP.
    IF NOT lt_fieldcat[] IS INITIAL.
      CALL METHOD cl_alv_table_create=>create_dynamic_table
      EXPORTING
        it_fieldcatalog           = lt_fieldcat
      IMPORTING
        ep_table                  = er_table
      EXCEPTIONS
        generate_subpool_dir_full = 1
        OTHERS                    = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      st_tables-table = er_table.
      st_tables-name  = i_type.
      st_tables-purpose  = i_purpose.
      INSERT TABLE st_tables.
    ENDIF.
  ENDIF.
ENDFORM.                    " create_table
*---------------------------------------------------------------------*
*       FORM get_dfies                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_DFIES                                                      *
*  -->  I_TABNAME                                                     *
*---------------------------------------------------------------------*
FORM get_dfies  TABLES   et_dfies  STRUCTURE dfies
                USING    i_tabname TYPE      ddobjname.

  TYPES :
    BEGIN OF ty_dfies_list,
      tabname TYPE ddobjname,
      dfies   TYPE ddfields,
    END OF  ty_dfies_list.

  STATICS : st_dfies_list TYPE HASHED TABLE OF ty_dfies_list
                          WITH UNIQUE KEY tabname
                          WITH HEADER LINE.

  READ TABLE st_dfies_list WITH TABLE KEY tabname = i_tabname.
  IF sy-subrc = 0.
    et_dfies[] = st_dfies_list-dfies[].
  ELSE.
    CALL FUNCTION 'DDIF_NAMETAB_GET'
         EXPORTING
              tabname   = i_tabname
         TABLES
              dfies_tab = et_dfies
         EXCEPTIONS
              not_found = 1
              OTHERS    = 2.
*BOC:HBHALLA (06/12/24)
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN 1.
                MESSAGE s002(/psyng/sw)
             WITH 'No Active Runtime Object Found for TABNAME'.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (06/12/24)
    SORT et_dfies BY fieldname.
    st_dfies_list-tabname = i_tabname.
    st_dfies_list-dfies[] = et_dfies[].

    INSERT TABLE st_dfies_list.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_conf_set_rfcs                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_RFCDEST                                                    *
*  -->  I_SETID                                                       *
*---------------------------------------------------------------------*
FORM get_conf_set_rfcs
  TABLES et_rfcdest STRUCTURE /psyng/sw_rfcdes
         it_sysid   STRUCTURE /psyng/swcfgsys
  USING  i_setid
  .
  DATA : l_local_sysid    TYPE     rfcdest,
    ls_syst          TYPE     /psyng/swcfgsys.
  IF it_sysid[] IS INITIAL.
*  --Load all the systems, and their configured RFC Destination
    SELECT * FROM /psyng/sw_rfcdes
    INNER JOIN /psyng/swcfgsys ON
    /psyng/swcfgsys~sysid = /psyng/sw_rfcdes~systid
    INTO CORRESPONDING FIELDS OF TABLE et_rfcdest  WHERE
  /psyng/swcfgsys~setid = i_setid.
*--Check if local system was requested (may not be in /psyng/sw_rfcdes)
    CONCATENATE sy-sysid sy-mandt INTO l_local_sysid.
    SORT et_rfcdest BY systid.
    READ TABLE et_rfcdest WITH KEY systid = l_local_sysid
    BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      SELECT SINGLE * FROM /psyng/swcfgsys
      INTO ls_syst
      WHERE setid = i_setid AND
            sysid = l_local_sysid.
      IF sy-subrc = 0.
        CLEAR et_rfcdest.
        et_rfcdest-systid = l_local_sysid.
        APPEND et_rfcdest.
        SORT et_rfcdest BY systid.
      ENDIF.
    ENDIF.
  ELSE.
*  --Load all the systems, and their configured RFC Destination
    SELECT * FROM /psyng/sw_rfcdes
    INTO CORRESPONDING FIELDS OF TABLE et_rfcdest
     FOR ALL ENTRIES IN it_sysid
     WHERE systid = it_sysid-sysid.
*--Check if local system was requested (may not be in /psyng/sw_rfcdes)
    CONCATENATE sy-sysid sy-mandt INTO l_local_sysid.
    READ TABLE it_sysid WITH KEY sysid =  l_local_sysid.
    IF sy-subrc = 0.
      SORT et_rfcdest BY systid.
      READ TABLE et_rfcdest WITH KEY systid = l_local_sysid
      BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        IF sy-subrc = 0.
          CLEAR et_rfcdest.
          et_rfcdest-systid = l_local_sysid.
          APPEND et_rfcdest.
          SORT et_rfcdest BY systid.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  analyze_org_elements
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ET_ORG_VALUES  text
*      -->P_ET_RETURN  text
*      -->P_ET_TEXTS  text
*      -->P_IT_ANALYZE_ELEMENTS  text
*----------------------------------------------------------------------*
FORM analyze_org_elements

TABLES  et_org_values       STRUCTURE /psyng/swcfgoe
        et_return           STRUCTURE bapiret2
        et_texts            STRUCTURE /psyng/sw_org_values_text
        it_analyze_elements STRUCTURE /psyng/sw_ao_list
        it_systems         STRUCTURE /psyng/swcfgsys
USING   i_setid             TYPE /psyng/seconfid
CHANGING ef_success         TYPE flag.


  DATA :
  lf_bukrs       TYPE flag,
  lf_ekorg       TYPE flag,
  lf_werks       TYPE flag,
  lf_vkorg       TYPE flag,
  lf_gsber       TYPE flag,
  lf_spart       TYPE flag,
  lf_vtweg       TYPE flag,
  lf_kkber       TYPE flag,
  lf_kokrs       TYPE flag,
  lf_vstel       TYPE flag,
  lf_validate_cal  TYPE     flag,
  lf_org_det_hier  TYPE     flag,
  lt_systems       TYPE     TABLE OF /psyng/sw_rfcdes
                            WITH HEADER LINE,
  lt_org_values    TYPE     TABLE OF /psyng/swcfgoe
                            WITH HEADER LINE,
  lt_texts         TYPE     TABLE OF /psyng/sw_org_values_text
                            WITH HEADER LINE,
  l_system_msg(72) TYPE     c,
  lf_is_erp        TYPE     flag.



**--Load all the systems, and their configured RFC Destination
  PERFORM get_conf_set_rfcs
              TABLES
                 lt_systems
                 it_systems
              USING
                 i_setid.



*--Check if Factory Calendar needs to be validated
  se_config_param 'ORG_VAL_FABKL' lf_validate_cal.
  IF
     lf_validate_cal = 'Y' OR lf_validate_cal = 'X' .
    lf_validate_cal = 'X'.
  ELSE.
    CLEAR  lf_validate_cal.
  ENDIF.

*--Check if Org Level Determination should consider Plant/Purchase Org
*  Relation or relate everything to company code
  se_config_param 'ORG_DET_HIER' lf_org_det_hier.
  IF
     lf_org_det_hier = 'Y' OR lf_org_det_hier = 'X' .
    lf_org_det_hier = 'X'.
  ELSE.
    CLEAR  lf_org_det_hier.
  ENDIF.

*--Check which elements need to be analyzed
  LOOP AT it_analyze_elements WHERE selected = 'X' OR default = 'X'.
    CASE it_analyze_elements-field.
      WHEN 'BUKRS'.
        lf_bukrs = 'X'.
      WHEN 'EKORG'.
        lf_ekorg = 'X'.
      WHEN 'WERKS'.
        lf_werks = 'X'.
      WHEN 'VKORG'.
        lf_vkorg = 'X'.
      WHEN 'GSBER'.
        lf_gsber = 'X'.
      WHEN 'SPART'.
        lf_spart = 'X'.
      WHEN 'VTWEG'.
        lf_vtweg = 'X'.
      WHEN 'KKBER'.
        lf_kkber = 'X'.
      WHEN 'KOKRS'.
        lf_kokrs = 'X'.
      WHEN 'VSTEL'.
        lf_vstel = 'X'.
    ENDCASE.
  ENDLOOP.
*--Do the org level analysis for all systems defined
*  in this configuration set
  LOOP AT lt_systems.

*--Check if the system is an ERP system where we can analyze org levels
    CLEAR lf_is_erp.
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
    CALL FUNCTION '/PSYNG/SW_AO_CHECK_ERP'
      DESTINATION lt_systems-rfcdest
     IMPORTING
       ef_is_erp                = lf_is_erp
     EXCEPTIONS
          communication_failure = 1 MESSAGE l_system_msg
          system_failure        = 2 MESSAGE l_system_msg
          OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    IF sy-subrc <> 0.
      log et_return 'E' 'ERP_CHECK_ERROR'
                        'Unable to Check if system is ERP'
                        lt_systems-systid  l_system_msg ''.
      CLEAR ef_success.
    ENDIF.
    IF lf_is_erp <> 'X'.
      log et_return 'E' 'NO_ERP'
                        'System' lt_systems-systid
                        'is not an ERP system.'
                        'Org level analysis impossible'.
    ELSE.
      IF lf_org_det_hier = 'X'.
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
        CALL FUNCTION '/PSYNG/SW_AO_004'
             DESTINATION lt_systems-rfcdest
             EXPORTING
                  if_bukrs     = lf_bukrs
                  if_ekorg     = lf_ekorg
                  if_werks     = lf_werks
                  if_vkorg     = lf_vkorg
                  if_gsber     = lf_gsber
                  if_spart     = lf_spart
                  if_vtweg     = lf_vtweg
                  if_kkber     = lf_kkber
                  if_kokrs     = lf_kokrs
                  if_vstel     = lf_vstel
                  if_val_cal   = lf_validate_cal
             TABLES
                  et_swsodorgm = lt_org_values
                  et_return    = et_return
                  et_values    = lt_texts
             EXCEPTIONS
                  communication_failure = 1 MESSAGE l_system_msg
                  system_failure        = 2 MESSAGE l_system_msg
                  OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

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
        CALL FUNCTION '/PSYNG/SW_AO_001'
             DESTINATION lt_systems-rfcdest
             EXPORTING
                  if_bukrs     = lf_bukrs
                  if_ekorg     = lf_ekorg
                  if_werks     = lf_werks
                  if_vkorg     = lf_vkorg
                  if_gsber     = lf_gsber
                  if_spart     = lf_spart
                  if_vtweg     = lf_vtweg
                  if_kkber     = lf_kkber
                  if_kokrs     = lf_kokrs
                  if_vstel     = lf_vstel
                  if_val_cal   = lf_validate_cal
             TABLES
                  et_swsodorgm = lt_org_values
                  et_return    = et_return
                  et_values    = lt_texts
             EXCEPTIONS
                  communication_failure = 1 MESSAGE l_system_msg
                  system_failure        = 2 MESSAGE l_system_msg
                  OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

      ENDIF.
      IF sy-subrc <> 0.
        log et_return 'E' 'ANALYZE_ERROR'
                          'Analysis failed on' lt_systems-systid
                          l_system_msg ''.
        CLEAR ef_success.
      ENDIF.
      lt_org_values-sysid = lt_systems-systid.
      MODIFY lt_org_values TRANSPORTING sysid
             WHERE sysid = ''
             .
      APPEND LINES OF lt_org_values  TO et_org_values.
      APPEND LINES OF lt_texts       TO et_texts.
      REFRESH : lt_org_values, lt_texts.
      CLEAR l_system_msg.
    ENDIF.
  ENDLOOP.
  SORT : lt_org_values, lt_texts.
  DELETE ADJACENT DUPLICATES FROM  : lt_org_values, lt_texts.

ENDFORM.                    " analyze_org_elements


*---------------------------------------------------------------------*
*       FORM analyze_ve_elements                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_VE_VALUES                                                  *
*  -->  ET_RETURN                                                     *
*  -->  IT_SYSTEMS                                                    *
*  -->  IT_ANALYZE_ELEMENTS                                           *
*  -->  I_SETID                                                       *
*  -->  I_VAREL_VRSIO                                                 *
*  -->  EF_SUCCESS                                                    *
*---------------------------------------------------------------------*
FORM analyze_ve_elements
TABLES
  et_ve_values        STRUCTURE /psyng/swcfgve
  et_return           STRUCTURE bapiret2
  it_systems          STRUCTURE /psyng/swcfgsys
  it_analyze_elements STRUCTURE /psyng/range_se_varel
  it_rfcdest          STRUCTURE rfcdes
USING
  i_setid             TYPE /psyng/seconfid
  i_varel_vrsio       TYPE /psyng/sodvrsio
  if_include_inactive TYPE flag
CHANGING
  ef_success          TYPE flag.


  CALL FUNCTION '/PSYNG/SW_VE_003'
       EXPORTING
            i_varel_vrsio       = i_varel_vrsio
            if_local_config     = 'X'
            if_include_inactive = if_include_inactive
       TABLES
            et_return           = et_return
            it_elements         = it_analyze_elements
            et_values           = et_ve_values
            it_systems          = it_systems
            it_rfcdest          = it_rfcdest.
*  et_ve_values-active = 'X'.
*  modify  et_ve_values transporting active where active <> 'X'.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM read_org_elements                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_ORG_VALUES                                                 *
*  -->  ET_RETURN                                                     *
*  -->  ET_TEXTS                                                      *
*  -->  IT_ANALYZE_ELEMENTS                                           *
*  -->  I_SETID                                                       *
*  -->  EF_SUCCESS                                                    *
*---------------------------------------------------------------------*
FORM read_org_elements

TABLES  et_org_values       STRUCTURE /psyng/swcfgoe
        et_return           STRUCTURE bapiret2
        et_texts            STRUCTURE /psyng/sw_org_values_text
        it_analyze_elements STRUCTURE /psyng/sw_ao_list
        it_systems          STRUCTURE  /psyng/swcfgsys
USING   i_setid             TYPE /psyng/seconfid
        if_read_texts       TYPE flag
CHANGING ef_success         TYPE flag.

  DATA : lt_values TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
         l_val TYPE xuvalue.
  FIELD-SYMBOLS : <text> TYPE /psyng/sw_org_values_text.
  SELECT * FROM /psyng/swcfgoe INTO TABLE lt_values
  WHERE setid = i_setid
  ORDER BY abb varbl value.

  et_org_values[] = lt_values[].
*--Determine the texts for the values
  LOOP AT et_org_values.
    MOVE-CORRESPONDING et_org_values TO et_texts .
    et_texts-low   = et_org_values-value.
    et_texts-field = et_org_values-varbl.
    APPEND et_texts.
  ENDLOOP.
  SORT et_texts.
  DELETE ADJACENT DUPLICATES FROM et_texts.
  IF if_read_texts = 'X'.
    LOOP AT et_texts ASSIGNING <text>.
      l_val = <text>-low.
      PERFORM get_orgvalue_text
        TABLES
          it_systems
        USING
          <text>-field
          l_val
          i_setid
        CHANGING
          <text>-vtext.
    ENDLOOP.
  ENDIF.



ENDFORM.                    " read_org_elements

*---------------------------------------------------------------------*
*       FORM read_ve_elements                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_VE_VALUES                                                  *
*  -->  ET_RETURN                                                     *
*  -->  IT_ANALYZE_ELEMENTS                                           *
*  -->  I_SETID                                                       *
*  -->  EF_SUCCESS                                                    *
*---------------------------------------------------------------------*
FORM read_ve_elements

TABLES  et_ve_values       STRUCTURE  /psyng/swcfgve
        et_return           STRUCTURE bapiret2
USING   i_setid             TYPE /psyng/seconfid
CHANGING ef_success         TYPE flag.

  DATA : lt_values TYPE TABLE OF /psyng/swcfgve WITH HEADER LINE.

  FIELD-SYMBOLS : <text> TYPE /psyng/sw_org_values_text.
  SELECT * FROM /psyng/swcfgve INTO TABLE lt_values
  WHERE setid = i_setid
  ORDER BY var_element sysid value.

  et_ve_values[] = lt_values[].
ENDFORM.                    " read_org_elements

*&---------------------------------------------------------------------*
*&      Form  get_orgvalue_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_<TEXT>_FIELD  text
*      -->P_<TEXT>_VTEXT  text
*      -->P_I_SETID  text
*----------------------------------------------------------------------*
FORM get_orgvalue_text
TABLES
          it_systems          STRUCTURE  /psyng/swcfgsys
USING     i_field TYPE xufield
          i_value TYPE xuvalue
          i_setid TYPE /psyng/seconfid
CHANGING e_text  TYPE xutext.
  DATA :  lt_texts TYPE TABLE OF /psyng/sw_org_values_text
                                WITH HEADER LINE,
          l_system_msg(72) TYPE c.
  STATICS : s_setid TYPE /psyng/seconfid,
            st_systems  TYPE  TABLE OF /psyng/sw_rfcdes
                              WITH HEADER LINE,
            st_texts TYPE TABLE OF /psyng/sw_org_values_text
                                WITH HEADER LINE.
  CLEAR e_text.
*--Load the defined systems for this configuration set if not done yet
  IF  i_setid <> s_setid OR  st_systems[] IS INITIAL.
    REFRESH : st_systems, st_texts.
    PERFORM get_conf_set_rfcs
              TABLES
                 st_systems
                 it_systems
              USING
                 i_setid.
    s_setid = i_setid.
  ENDIF.

  IF NOT st_texts[] IS INITIAL.
    READ TABLE st_texts WITH KEY field = i_field
                                 low   = i_value
                        BINARY SEARCH.
    IF sy-subrc = 0.
      e_text = st_texts-vtext.
    ENDIF.
  ENDIF.
  IF e_text IS INITIAL.
    LOOP AT st_systems.
      REFRESH : lt_texts.
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
      CALL FUNCTION '/PSYNG/SW_AO_GET_VALUE_TEXT'
      DESTINATION st_systems-rfcdest
        EXPORTING
          i_field       = i_field
          i_value       = i_value
         i_langu        = sy-langu
       IMPORTING
         e_text        = e_text
       TABLES
         et_text       = lt_texts
       EXCEPTIONS
          communication_failure = 1 MESSAGE l_system_msg
          system_failure        = 2 MESSAGE l_system_msg
          OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
      IF sy-subrc = 0.
        DELETE lt_texts WHERE vtext = ''.
        APPEND LINES OF lt_texts TO st_texts.
        SORT st_texts BY field low.
        DELETE ADJACENT DUPLICATES FROM st_texts COMPARING  field low.
        IF NOT e_text IS INITIAL.
          EXIT."we found it, no need to look further
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " get_orgvalue_text
*&---------------------------------------------------------------------*
*&      Form  get_value_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ET_TEXT  text
*      <--P_E_TEXT  text
*      -->P_I_FIELD  text
*      -->P_I_VALUE  text
*      -->P_IF_ALL  text
*----------------------------------------------------------------------*
FORM get_value_text
TABLES   et_text STRUCTURE /psyng/sw_org_values_text
USING    i_field TYPE xufield
         i_value TYPE xuvalue
         i_langu TYPE sylangu
         if_all  TYPE flag
CHANGING e_text  TYPE  xutext
         .
*--Macro get_text----------------------------------------
* &1 - table that contains the texts
* &2 - fielld that contains the text
* &3 - field that contains the org value
* &4 - field that contains the language
*     ( use mandt if no language field exists in &1)
* &5 - language value
*     ( use sy-mandt if no language field exists in &1)
*---------------------------------------------------------
  DEFINE get_text.
    e_text = i_value. "if no text found, return value
    call function 'DDIF_FIELDINFO_GET'
         exporting
              tabname        = &1
         exceptions
              not_found      = 1
              internal_error = 2
              others         = 3.
    if sy-subrc = 0.
      if if_all =  'X'.
*--   select all texts from table &1
        select &2 as vtext &3 as low from (&1)
        into corresponding fields of table et_text
        where &4 = &5 order by &3. "#EC SAST_CI_GEN_CHECK
*(HBHALLA)(17/12/24)
        if sy-subrc = 0.
*--     put text for value i_value into e_text field
          read table et_text with key low = i_value binary search.
          e_text  = et_text-vtext.
          et_text-field = i_field.
*--     update field to i_field.
          modify  et_text  transporting field where field = ''.
        endif.
      else.
*--   select just the text for value i_value from table &1
        select single &2 as vtext  from (&1)
        into e_text
        where &4 = &5 and &3 = i_value. "#EC SAST_CI_GEN_CHECK
*(HBHALLA)(17/12/24)
      endif.
    endif.
  END-OF-DEFINITION.

*--Use macro to select text from appropriate table for field
  CASE i_field.
    WHEN 'GSBER'.
      get_text 'TGSBT' gtext gsber spras i_langu.
    WHEN 'KKBER'.
      get_text 'T014T' kkbtx kkber spras i_langu.
    WHEN 'SPART'.
      get_text 'TSPAT' vtext spart spras i_langu.
    WHEN 'VKORG'.
      get_text 'TVKOT' vtext vkorg spras i_langu.
    WHEN 'VSTEL'.
      get_text 'TVSTT' vtext vstel spras i_langu.
    WHEN 'BUKRS'.
      get_text 'T001'  butxt bukrs mandt
      sy-mandt. "#EC SAST_CI_GEN_CHECK (HBHALLA)
    WHEN 'KOKRS'.
      get_text 'TKA01' bezei kokrs mandt
      sy-mandt. "#EC SAST_CI_GEN_CHECK (HBHALLA)
    WHEN 'EKORG'.
      get_text 'T024E' ekotx ekorg mandt
      sy-mandt. "#EC SAST_CI_GEN_CHECK (HBHALLA)
    WHEN 'WERKS'.
      get_text 'T001W' name1  werks mandt
      sy-mandt. "#EC SAST_CI_GEN_CHECK (HBHALLA)
    WHEN 'FAKE'.
*--Include a fake table here, to ensure macro code compiles and
*  can run on systems that don't have 1 or more of the above tables
      get_text 'INVALID' invalid invalid invalid i_langu.
    WHEN OTHERS.
*if no text found, return value
      e_text = i_value.
  ENDCASE.

ENDFORM.                    " get_value_text

*---------------------------------------------------------------------*
*       FORM get_varel_text                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_VALUES                                                     *
*  -->  ET_TEXTS                                                      *
*  -->  I_SETID                                                       *
*---------------------------------------------------------------------*
FORM get_varel_text
TABLES
          et_values STRUCTURE /psyng/swcfgve
          et_texts  STRUCTURE /psyng/sw_ve_values_text
USING     i_setid   TYPE /psyng/seconfid.

  DATA :  l_system_msg(72) TYPE c,
          lt_values_part TYPE TABLE OF /psyng/swcfgve,
          lt_texts TYPE TABLE OF /psyng/sw_ve_values_text,
          lt_sysid TYPE TABLE OF /psyng/swcfgsys.
  STATICS : s_setid TYPE /psyng/seconfid,
            st_systems  TYPE  TABLE OF /psyng/sw_rfcdes
                              WITH HEADER LINE,
*            st_texts TYPE TABLE OF /PSYNG/SW_VE_VALUES_TEXT
*                                WITH HEADER LINE,
            s_set    TYPE /psyng/swcfgset,
            s_varel  TYPE TABLE OF /psyng/sw_varel WITH HEADER LINE.
*--Load the defined systems for this configuration set if not done yet
  IF  i_setid <> s_setid OR  st_systems[] IS INITIAL.
    REFRESH : st_systems.
    PERFORM get_conf_set_rfcs
              TABLES
                 st_systems
                 lt_sysid
              USING
                 i_setid.
    SELECT SINGLE * FROM /psyng/swcfgset INTO s_set
    WHERE setid = i_setid.
    s_setid = i_setid.
    SELECT DISTINCT var_element element tabname
    INTO CORRESPONDING FIELDS OF TABLE s_varel
    FROM /psyng/sw_varel WHERE

      varel_vrsio = s_set-varel_vrsio AND outputflag = 'X'.
  ENDIF.
  SORT et_values BY sysid.
  LOOP AT st_systems.
    READ TABLE et_values WITH KEY sysid = st_systems-systid
    BINARY SEARCH TRANSPORTING NO FIELDS.
    REFRESH : lt_values_part.
    LOOP AT et_values FROM sy-tabix.
      IF et_values-sysid <> st_systems-systid.
        EXIT.
      ENDIF.
      APPEND et_values TO lt_values_part.
    ENDLOOP.

    REFRESH : lt_texts.
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
    CALL FUNCTION '/PSYNG/SW_VE_GET_VALUE_TEXT'
    DESTINATION st_systems-rfcdest
     EXPORTING
        I_VAREL_VRSIO     = s_set-varel_vrsio
     TABLES
       it_values     = lt_values_part
       et_texts      = lt_texts
       it_varel      = s_varel
     EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc = 0.
      DELETE lt_texts WHERE vtext = ''.
      APPEND LINES OF lt_texts TO et_texts.
      SORT et_texts.
      DELETE ADJACENT DUPLICATES FROM et_texts COMPARING  ALL FIELDS.
    ENDIF.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CHECK_TABLE_EXISTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0408   text
*      <--P_LF_T024W  text
*----------------------------------------------------------------------*
FORM check_table_exists  USING    i_tabname type TYPENAME
                         CHANGING ef_exists.
  DATA : ls_type TYPE ddtypekind.
    CALL FUNCTION 'DDIF_TYPEINFO_GET'
         EXPORTING
              typename = i_tabname
         IMPORTING
              typekind = ls_type.
    IF ls_type IS INITIAL.
      CLEAR ef_exists.
    else.
      ef_exists = 'X'.
    ENDIF.

ENDFORM.
