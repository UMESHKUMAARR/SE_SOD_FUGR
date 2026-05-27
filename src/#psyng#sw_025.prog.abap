*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_025
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sw_025 LINE-SIZE 200 MESSAGE-ID /psyng/sw.

TABLES: /psyng/functtran, /psyng/function, /psyng/confdet,
        /psyng/conflict.

TYPE-POOLS: slis.                                      "For ALV call
DATA: g_program         LIKE sy-repid.                   "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call
DATA: gt_isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA: gt_confdet TYPE STANDARD TABLE OF /psyng/confdet WITH HEADER LINE.
DATA: gt_function TYPE SORTED TABLE OF /psyng/function
      WITH UNIQUE KEY function WITH HEADER LINE.
DATA: gt_conflict TYPE SORTED TABLE OF /psyng/conflict
      WITH UNIQUE KEY conid WITH HEADER LINE.
DATA: gt_itstct TYPE SORTED TABLE OF tstct WITH UNIQUE KEY sprsl tcode
      WITH HEADER LINE.
DATA gt_fiorit TYPE SORTED TABLE OF /psyng/sw_fioria WITH UNIQUE KEY
      fioriid WITH HEADER LINE. "C1322 Odubey 29/02/2024
DATA:gf_missing_auth TYPE flag,
      g_dynnr        TYPE sy-dynnr.
DATA: BEGIN OF output OCCURS 10,
        tcode LIKE /psyng/functtran-tcode,
        ttext LIKE tstct-ttext,
        functionid LIKE /psyng/functtran-functionid,
        description LIKE /psyng/function-description,
        conid LIKE /psyng/confdet-conid,
        cdescription LIKE /psyng/conflict-description,
        functionid2 LIKE /psyng/functtran-functionid,
        description2 LIKE /psyng/function-description,
      END OF output,
      g_current_user TYPE sy-uname. "C0700

TYPES: BEGIN OF ty_fiori_f4,
        fioriid TYPE /psyng/sw_fioria-fioriid,
        appname TYPE /psyng/sw_fioria-appname,
       END OF ty_fiori_f4.

TYPES: BEGIN OF ty_funct_fiori,
       fioriid TYPE /psyng/functtran-fioriid,
      END OF ty_funct_fiori.

DATA: lt_funct_fiori TYPE TABLE OF ty_funct_fiori,
       lt_fiori_f4 TYPE TABLE OF ty_fiori_f4.

DATA: gt_return TYPE TABLE OF ddshretval,
      gs_return TYPE ddshretval.

SELECTION-SCREEN: BEGIN OF BLOCK exe WITH FRAME TITLE text-001.
PARAMETERS: p_vrsio LIKE /psyng/function-vrsio.
SELECT-OPTIONS: tcodes FOR /psyng/functtran-tcode,
                fioriid FOR /psyng/functtran-fioriid, "C1322
                func FOR /psyng/function-function,
                cons FOR /psyng/conflict-conid.

SELECTION-SCREEN: END OF BLOCK exe.

*------------------------- AT SELECTION-SCREEN ------------------------*
AT SELECTION-SCREEN.
* Validate version
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/swsodvers
                WHERE vrsio = p_vrsio.
  IF sy-subrc <> 0.
    MESSAGE e128(/psyng/sw) WITH text-008.
  ENDIF.
* BOC by RGUPTA on 29.03.22 for C0700

AT SELECTION-SCREEN OUTPUT.

  SELECT fioriid
  FROM /psyng/functtran
    INTO TABLE lt_funct_fiori
  WHERE vrsio = p_vrsio AND type = 'F'.


  IF NOT lt_funct_fiori[] IS INITIAL.
    SELECT fioriid
           appname
      FROM /psyng/sw_fioria
      INTO TABLE lt_fiori_f4
      FOR ALL ENTRIES IN lt_funct_fiori
      WHERE fioriid = lt_funct_fiori-fioriid.
  ENDIF.

  SORT lt_fiori_f4 BY fioriid.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR fioriid-low.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
 EXPORTING
   retfield        = 'FIORIID'
   value_org       = 'S'
   multiple_choice = 'X'
   dynpprog        = sy-repid
   dynpnr          = sy-dynnr
   dynprofield     = 'FIORIID-LOW'
 TABLES
   value_tab       = lt_fiori_f4
   return_tab      = gt_return
 EXCEPTIONS
   parameter_error = 1
   no_values_found = 2
   OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  LOOP AT gt_return INTO gs_return.
    fioriid-low = gs_return-fieldval.
    fioriid-sign = 'I'.
    fioriid-option = 'EQ'.
    APPEND fioriid.
  ENDLOOP.

INITIALIZATION.
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 29.03.22 for C0700


*  DATA: lv_value TYPE char10.
*  LOOP AT gt_return INTO gs_return.
*    lv_value = gs_return-fieldval.
*    AT FIRST.
*      s_syst-sign = 'I'.
*      s_syst-option = 'EQ'.
*      s_syst-low = lv_value.
*      APPEND s_syst.
*      CLEAR: s_syst.
*    ENDAT.
*    s_syst-sign = 'I'.
*    s_syst-option = 'EQ'.
*    s_syst-low = gs_return-fieldval.
*    APPEND s_syst.
*    AT LAST.
*      DELETE s_syst WHERE low = lv_value.
*    ENDAT.
*  ENDLOOP.

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
  CLEAR:gf_missing_auth .
  SELECT * FROM /psyng/confdet INTO TABLE gt_confdet
         WHERE vrsio = p_vrsio.
  SELECT function description FROM /psyng/function
         INTO CORRESPONDING FIELDS OF TABLE gt_function
         WHERE vrsio = p_vrsio.
****************************************************************
**SF 1665
  LOOP AT gt_function.
**Authorization check for Displaying SW Functions
    AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
                ID 'ACTVT' FIELD '03'
                ID 'Y&SW_VRSIO'  FIELD p_vrsio
                ID 'Y&SW_FUNCT'  FIELD gt_function-function .

    IF sy-subrc NE 0.
      DELETE gt_function INDEX sy-tabix.
      gf_missing_auth = 'X'.
    ENDIF.
  ENDLOOP.
**SF 1665
************************************************
  SELECT conid description FROM /psyng/conflict
         INTO CORRESPONDING FIELDS OF TABLE gt_conflict
         WHERE vrsio = p_vrsio.
**********************************************
**SF 1665
  LOOP AT gt_conflict.
**Authorization check for Displaying SW Conflicts
    AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
             ID 'ACTVT' FIELD '01'
             ID 'Y&SW_CONID' FIELD gt_conflict-conid
             ID 'Y&SW_VRSIO' FIELD p_vrsio.

    IF sy-subrc <> 0.
      DELETE gt_conflict INDEX sy-tabix.
      gf_missing_auth = 'X'.
    ENDIF.
  ENDLOOP.
**SF 1665
*************************************************

  SELECT tcode ttext FROM tstct INTO CORRESPONDING FIELDS OF TABLE
         gt_itstct WHERE sprsl = sy-langu.

  SELECT fioriid appname FROM /psyng/sw_fioria INTO CORRESPONDING
     FIELDS OF TABLE gt_fiorit WHERE fioriid <> space.
****************************************************************

  IF tcodes[] IS INITIAL AND fioriid[] IS INITIAL OR
     tcodes[] IS NOT INITIAL AND fioriid[] IS NOT INITIAL OR
     tcodes[] IS NOT INITIAL AND fioriid[] IS INITIAL.
    SELECT * FROM /psyng/functtran WHERE tcode IN tcodes AND
                                      functionid IN func
                                     AND vrsio       = p_vrsio
                                     AND type       <> 'F'.


      SELECT * FROM /psyng/confdet                   "#EC CI_SEL_NESTED
               WHERE functionid = /psyng/functtran-functionid
                 AND conid IN cons
                 AND vrsio  = p_vrsio.

        LOOP AT gt_confdet WHERE conid = /psyng/confdet-conid.
* -- odubey29022024 C1322 start
          IF /psyng/functtran-type = 'T' OR /psyng/functtran-type = 'P'
            OR /psyng/functtran-type IS INITIAL.
*          end
            output-tcode = /psyng/functtran-tcode.
            READ TABLE gt_itstct WITH TABLE KEY sprsl = ''
                 tcode = /psyng/functtran-tcode.
            IF sy-subrc = 0.
              output-ttext = gt_itstct-ttext.
            ENDIF.
*        * -- odubey29022024 C1322 start
*      else.
*        output-tcode = /psyng/functtran-fioriid.
*        read table gt_fiorit with table key
*                  fioriid = /psyng/functtran-fioriid.
*        if sy-subrc = 0.
*          output-ttext = gt_fiorit-appname.
*          endif.

*        end
            output-functionid = /psyng/functtran-functionid.
            READ TABLE gt_function WITH TABLE KEY
                 function = /psyng/functtran-functionid.

            IF sy-subrc = 0.
              output-description = gt_function-description.
            ENDIF.

            output-conid = /psyng/confdet-conid.
            READ TABLE gt_conflict WITH TABLE KEY conid =
    /psyng/confdet-conid.

            IF sy-subrc = 0.
              output-cdescription = gt_conflict-description.
            ENDIF.

            output-functionid2 = gt_confdet-functionid.
            READ TABLE gt_function WITH TABLE KEY
                 function = gt_confdet-functionid.
            IF sy-subrc = 0.
              output-description2 = gt_function-description.
            ENDIF.

            APPEND output.
          ENDIF.
        ENDLOOP.
      ENDSELECT.
    ENDSELECT.
  ENDIF.

* -- odubey29022024 C1322 start
*---Fiori iD
  IF tcodes[] IS INITIAL AND fioriid[] IS INITIAL OR
     tcodes[] IS NOT INITIAL AND fioriid[] IS NOT INITIAL OR
     tcodes[] IS INITIAL AND fioriid[] IS NOT INITIAL.
    SELECT * FROM /psyng/functtran WHERE fioriid IN fioriid AND
                                    functionid IN func
                                   AND vrsio       = p_vrsio
                                   AND type = 'F'.


      SELECT * FROM /psyng/confdet                   "#EC CI_SEL_NESTED
               WHERE functionid = /psyng/functtran-functionid
                 AND conid IN cons
                 AND vrsio  = p_vrsio.

        LOOP AT gt_confdet WHERE conid = /psyng/confdet-conid.
          output-tcode = /psyng/functtran-fioriid.
          READ TABLE gt_fiorit WITH TABLE KEY
                    fioriid = /psyng/functtran-fioriid.
          IF sy-subrc = 0.
            output-ttext = gt_fiorit-appname.
          ENDIF.

*        end
          output-functionid = /psyng/functtran-functionid.
          READ TABLE gt_function WITH TABLE KEY
               function = /psyng/functtran-functionid.

          IF sy-subrc = 0.
            output-description = gt_function-description.
          ENDIF.

          output-conid = /psyng/confdet-conid.
          READ TABLE gt_conflict WITH TABLE KEY conid =
  /psyng/confdet-conid.

          IF sy-subrc = 0.
            output-cdescription = gt_conflict-description.
          ENDIF.

          output-functionid2 = gt_confdet-functionid.
          READ TABLE gt_function WITH TABLE KEY
               function = gt_confdet-functionid.
          IF sy-subrc = 0.
            output-description2 = gt_function-description.
          ENDIF.

          APPEND output.
        ENDLOOP.
      ENDSELECT.
    ENDSELECT.
  ENDIF.
*  End C1322
*============================
  IF output[] IS INITIAL.
    MESSAGE i174.
    STOP.
  ENDIF.

****************************************************************
  PERFORM build_alv_catalog.
*************************************
  IF gf_missing_auth = 'X'.
*  **SF 1665
    MESSAGE s398(00) WITH
*      'Analysis Complete.'(083)
        'Missing some user authorizations'(084).
  ENDIF.
*************************************
  PERFORM output_using_alv.

*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_catalog.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  g_program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'OUTPUT'
            i_inclname         = g_program
       CHANGING
            ct_fieldcat        = i_fieldcat_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             INCONSISTENT_INTERFACE = 1
             PROGRAM_ERROR          = 2
             OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

  wa_fieldcat_alv-seltext_l = text-005.
  wa_fieldcat_alv-seltext_m = text-006.
  wa_fieldcat_alv-seltext_s = text-007.
  wa_fieldcat_alv-reptext_ddic = text-005.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TCODE'.

  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                    hotspot
                   WHERE
                      fieldname = 'FUNCTIONID'.

  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                    hotspot
                   WHERE
                      fieldname = 'CONID'.

   wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                    hotspot
                   WHERE
                      fieldname = 'FUNCTIONID2'.

ENDFORM.                    " build_alv_catalog
*&---------------------------------------------------------------------*
*&      Form  OUTPUT_using_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_using_alv.
  DATA: alv_grid_titl TYPE lvc_title,
        alv_layout    TYPE slis_layout_alv,
        ls_variant    TYPE disvariant.
  DATA: lt_excluding TYPE slis_t_extab,
              ls_excluding TYPE slis_extab.

*---exclude info
ls_excluding-fcode = '&INFO'.
append ls_excluding to lt_excluding.

  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  PERFORM build_sort_table.
  alv_grid_titl = text-004.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title       = alv_grid_titl
            i_callback_program = g_program
            it_sort            = gt_isort
            is_layout          = alv_layout
             i_callback_user_command  = 'DOUBLE_CLICK_ON_SUM'
            it_fieldcat        = i_fieldcat_alv
            IT_EXCLUDING       = lt_excluding
            i_save             = 'A'
            is_variant         = ls_variant
       TABLES
            t_outtab           = output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " OUTPUT_using_alv

*&---------------------------------------------------------------------*
*&      Form  build_sort_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_sort_table.
  DATA: l_sort TYPE slis_sortinfo_alv.

  l_sort-spos = '1'.
  l_sort-fieldname = 'TCODE'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'TTEXT'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'FUNCTIONID'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '4'.
  l_sort-fieldname = 'DESCRIPTION'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '5'.
  l_sort-fieldname = 'CONID'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '6'.
  l_sort-fieldname = 'CDESCRIPTION'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '7'.
  l_sort-fieldname = 'FUNCTIONID2'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '8'.
  l_sort-fieldname = 'DESCRIPTION2'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

ENDFORM.                    " build_sort_table

*---------------------------------------------------------------------*
*       FORM user_double_click_on_sum                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM double_click_on_sum USING r_ucomm LIKE sy-ucomm
                                 rs_selfield TYPE slis_selfield.
  DATA: l_uname          LIKE sy-uname,
          l_contid       TYPE /psyng/mchdr-contid,
          l_parva        TYPE usr05-parva,
          l_sod          TYPE /psyng/swsodvers-vrsio.

  CASE rs_selfield-fieldname.
    WHEN 'CONID'.
      CHECK rs_selfield-value <> space.
      CALL FUNCTION '/PSYNG/SW_DISPLAY_OBJECT'
        EXPORTING
          i_objecttype       = 'CONID'
          i_objectid         = rs_selfield-value
          i_vrsio            = p_vrsio.

      EXIT.
    WHEN 'FUNCTIONID'.
      CHECK rs_selfield-value <> space.
      l_uname = g_current_user. "sy-uname. C0700
*-- Get user's default version
      SELECT SINGLE parva INTO l_parva FROM usr05
                 WHERE bname = l_uname
                   AND parid = '/PSYNG/VRSIO'.
      IF sy-subrc = 0 AND l_parva <> space.
        l_sod = l_parva.
      ENDIF.

      PERFORM set_default_sodversion USING p_vrsio l_uname.
      SET PARAMETER ID '/PSYNG/FUN' FIELD rs_selfield-value.
      g_dynnr = '0201'.
      EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
*      CALL TRANSACTION '/PSYNG/SE'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/SE'.
      ELSE.
        CALL TRANSACTION '/PSYNG/SE'.
      ENDIF.
*-- Set back to Default
      PERFORM set_default_sodversion USING l_sod l_uname.
      EXIT.
      when 'FUNCTIONID2'.

         CHECK rs_selfield-value <> space.
      l_uname = g_current_user. "sy-uname. C0700
*-- Get user's default version
      SELECT SINGLE parva INTO l_parva FROM usr05
                 WHERE bname = l_uname
                   AND parid = '/PSYNG/VRSIO'.
      IF sy-subrc = 0 AND l_parva <> space.
        l_sod = l_parva.
      ENDIF.

      PERFORM set_default_sodversion USING p_vrsio l_uname.
      SET PARAMETER ID '/PSYNG/FUN' FIELD rs_selfield-value.
      g_dynnr = '0201'.
      EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
*      CALL TRANSACTION '/PSYNG/SE'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/SE'.
      ELSE.
        CALL TRANSACTION '/PSYNG/SE'.
      ENDIF.
*-- Set back to Default
      PERFORM set_default_sodversion USING l_sod l_uname.
      EXIT.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  set_default_sodversion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SODVRSIO  text
*      -->P_L_UNAME  text
*----------------------------------------------------------------------*
FORM set_default_sodversion USING l_sod TYPE /psyng/swsodvers-vrsio
                                  l_uname TYPE sy-uname.
  DATA: lt_param  TYPE TABLE OF bapiparam WITH HEADER LINE,
          lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE,
          ls_paramx TYPE bapiparamx.


  SELECT parid parva INTO TABLE lt_param FROM usr05  "#EC CI_SEL_NESTED
         WHERE bname = l_uname.

  READ TABLE lt_param WITH KEY parid = '/PSYNG/VRSIO'.
  lt_param-parva = l_sod.

  IF sy-subrc = 0.
    MODIFY lt_param INDEX sy-tabix.
  ELSE.
    lt_param-parid = '/PSYNG/VRSIO'.
    APPEND lt_param.
  ENDIF.

  ls_paramx-parid = 'X'.
  ls_paramx-parva = 'X'.
  CALL FUNCTION 'BAPI_USER_CHANGE' "#EC SAST_CI_GEN_CHECK (HBHALLA)
       EXPORTING
            username   = l_uname
            parameterx = ls_paramx
       TABLES
            parameter  = lt_param
            return     = lt_return.

ENDFORM.                    " set_default_sodversion
