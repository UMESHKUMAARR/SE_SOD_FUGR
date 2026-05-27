*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SODREPORT
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
REPORT /psyng/sodmatrix_output LINE-SIZE 255.
INCLUDE /psyng/sw_config.
INCLUDE /psyng/basis_exelog.

TYPE-POOLS: shlp.
TABLES : /psyng/conflict, /psyng/busarea,/psyng/function.
*--Type for F4 help
TYPES: BEGIN OF ty_values,
         line(255) TYPE c,
       END OF   ty_values.

DATA :
  s_new_line(2) TYPE c,
  BEGIN OF new_line,
    x(2) TYPE x VALUE '0D0A',
  END OF new_line,
  g_dynnr            TYPE sy-dynnr,
  gf_cfg_set_enabled TYPE flag,
  lf_set_invalid     TYPE flag.

CONSTANTS :
  c_org_var_not_included TYPE flag VALUE '',
  c_org_var_included     TYPE flag VALUE 'X'.
***Type pools Declaration.

TYPE-POOLS: slis.                                      "For ALV call

*******Add Global Class
CLASS /psyng/sw_cl_constants DEFINITION LOAD.    "To check missing text


*Global Declarations for alv

DATA: g_program         LIKE sy-repid.                   "For ALV call
DATA: g_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call
DATA: g_sort          TYPE STANDARD TABLE OF slis_sortinfo_alv,
      gs_fieldcat_alv TYPE slis_fieldcat_alv,
      gs_sort         TYPE slis_sortinfo_alv.
*****Global table for Conflict Details
DATA: gt_confdet TYPE SORTED TABLE OF /psyng/confdet WITH UNIQUE KEY
              conid functionid
              WITH HEADER LINE.
*****Global table for Conflict Header
DATA: gt_conflict TYPE SORTED TABLE OF /psyng/conflict WITH UNIQUE KEY
              conid
              WITH HEADER LINE.
*****Global table for Function Details
DATA: gt_functtran TYPE SORTED TABLE OF /psyng/functtran WITH UNIQUE KEY
               functionid tcode
               WITH HEADER LINE.
*****Global table for Function  Header
DATA: gt_function TYPE SORTED TABLE OF /psyng/function WITH UNIQUE KEY
               function
               WITH HEADER LINE.
*****Global table for  Transactions
DATA: gt_tstct TYPE SORTED TABLE OF tstct WITH UNIQUE KEY
             tcode
             WITH HEADER LINE.
*****Global workarea for  Transactions
DATA: g_wa_tstct TYPE tstct.
*****Global table for  Objects
DATA: gt_faobj2    TYPE SORTED TABLE OF /psyng/faobj2 WITH UNIQUE KEY
               funid tcode object valueset field val_from val_to
                WITH HEADER LINE,
****Global table for Org Values
      gt_swsodorgm TYPE SORTED TABLE OF /psyng/swsodorgm
      WITH NON-UNIQUE KEY object varbl
      WITH HEADER LINE,
      gt_orgobj    TYPE SORTED TABLE OF tobj
         WITH NON-UNIQUE KEY objct
         WITH HEADER LINE,
****Global table for Variable Element Values
      gt_varel     TYPE SORTED TABLE OF /psyng/swcfgve
          WITH NON-UNIQUE KEY sysid      var_element
          WITH HEADER LINE.
***Declaration for Final output internal table
DATA: BEGIN OF gt_output OCCURS 0,
        l_conid        LIKE /psyng/conflict-conid,
        l_cdescription LIKE /psyng/conflict-description,
        l_functionid   LIKE /psyng/confdet-functionid,
        l_fdescription LIKE /psyng/function-description,
        l_tcode        LIKE tstc-tcode,
        l_tdescription LIKE tstct-ttext,
        l_object       LIKE /psyng/faobj2-object,
        l_valueset     LIKE /psyng/faobj2-valueset,
        l_abb          LIKE /psyng/swsodorgm-abb,
        l_field        LIKE /psyng/faobj2-field,
        l_variable     LIKE /psyng/faobj2-val_from,
        l_val_from     LIKE /psyng/faobj2-val_from,
        l_val_to       LIKE /psyng/faobj2-val_to,
        l_obj_or       LIKE /psyng/faobj2-obj_or,
        fld_and        LIKE /psyng/faobj2-fld_and,
      END OF gt_output.
DATA: BEGIN OF gt_outconmit OCCURS 0,
        conid        LIKE /psyng/conflict-conid,
        cdescription LIKE /psyng/conflict-description,
        busarea      LIKE /psyng/conflict-busarea,
        subarea      LIKE /psyng/conflict-subarea,
        risk         LIKE /psyng/conflict-risk,
        contid       LIKE /psyng/mchdr-contid,
        mdescription LIKE /psyng/mchdr-description,
        company      LIKE /psyng/conpmit-company,
        conlongt     TYPE string,
        mitlongt     TYPE string,
      END OF gt_outconmit.
DATA: BEGIN OF gt_conflictfunctions OCCURS 0,
        conid        LIKE /psyng/conflict-conid,
        cdescription LIKE /psyng/conflict-description,
        busarea      LIKE /psyng/conflict-busarea,
        subarea      LIKE /psyng/conflict-subarea,
        risk         LIKE /psyng/conflict-risk,
        functionid   LIKE /psyng/function-function,
        fdescription LIKE /psyng/function-description,
        contid       LIKE /psyng/mchdr-contid,
        mdescription LIKE /psyng/mchdr-description,
        company      LIKE /psyng/conpmit-company,
        tcode        LIKE /psyng/functtran-tcode,
        ttext        LIKE tstct-ttext,
      END OF gt_conflictfunctions.
DATA: gt_rfcdes        TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
      g_system_msg(72) TYPE c,
      gf_explicit      TYPE flag,
      gv_auth_check     TYPE flag. "(++)UMITTAL 06/01/2026 PN17034

DEFINE hidecol.
  gs_fieldcat_alv-no_out = 'X'.
  modify g_fieldcat_alv from gs_fieldcat_alv
                         transporting no_out
                         where fieldname = &1.
END-OF-DEFINITION.
DEFINE addcol.
  describe table g_fieldcat_alv lines sy-loopc.
  gs_fieldcat_alv-fieldname = &1.
  gs_fieldcat_alv-inttype   = 'C'.
  gs_fieldcat_alv-outputlen = &2.
  gs_fieldcat_alv-intlen    = &2.
  gs_fieldcat_alv-col_pos   = sy-loopc.
  add 1 to gs_fieldcat_alv-col_pos.
  append gs_fieldcat_alv to g_fieldcat_alv.
END-OF-DEFINITION.
DEFINE text.
  gs_fieldcat_alv-seltext_l = &2.
  gs_fieldcat_alv-seltext_m = &2.
  gs_fieldcat_alv-seltext_s = &2.
  gs_fieldcat_alv-reptext_ddic = &2.
  modify g_fieldcat_alv from gs_fieldcat_alv
                         transporting seltext_l
                                      seltext_m
                                      seltext_s
                                      reptext_ddic
                         where fieldname = &1.
END-OF-DEFINITION.
DEFINE hotspot.
  gs_fieldcat_alv-hotspot = 'X'.
  modify g_fieldcat_alv from gs_fieldcat_alv
                         transporting hotspot
                         where fieldname = &1.
END-OF-DEFINITION.
DEFINE hidefield.
  gs_fieldcat_alv-no_out = 'X'.
  modify g_fieldcat_alv from gs_fieldcat_alv
                         transporting no_out
                         where fieldname = &1.
END-OF-DEFINITION.


DEFINE sortcol.
  gs_sort-fieldname = &1.
  ls_sort-up        = 'X'.
  append ls_sort to g_sort.
END-OF-DEFINITION.
DEFINE sort_col.
  add 1 to gs_sort-spos.
  gs_sort-fieldname = &1.
  gs_sort-tabname   = &2.
  gs_sort-up        = 'X'.
  append gs_sort to g_sort.
END-OF-DEFINITION.
DEFINE get_mc_shorttext.
  read table &1 with key contid = &2.
  if sy-subrc = 0.
    &3 = &1-description.
  endif.
END-OF-DEFINITION.
DEFINE get_longtext.
  clear &3.
  loop at lt_texts where textname = &1 and
                         object   = &2 and
                         spras    = sy-langu.
    concatenate &3 lt_texts-text s_new_line into &3
    separated by space.
  endloop.
END-OF-DEFINITION.

DEFINE get_system.
  refresh gt_rfcdes.
  clear gt_rfcdes.
  select * from /psyng/sw_rfcdes into table gt_rfcdes
  where systid = &1.
  read table gt_rfcdes index 1.
END-OF-DEFINITION.

*--Selection Screen
SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
PARAMETERS: p_system TYPE     /psyng/sw_rfcdes-systid,
            p_vrsio  TYPE      /psyng/sodvrsio
                     MEMORY ID /psyng/vrsio  .
SELECT-OPTIONS:
   spconfs FOR /psyng/conflict-conid    MODIF ID con,
   s_func  FOR /psyng/function-function MODIF ID con,
   pappa   FOR /psyng/busarea-busarea   MODIF ID con,
   cowner  FOR /psyng/conflict-owner    MODIF ID con,
   csens   FOR /psyng/conflict-imp      MODIF ID con,
   s_risk  FOR /psyng/conflict-risk     MODIF ID con,
   cprmit  FOR /psyng/conflict-contid   MODIF ID con.
* Configuration Set Selection
PARAMETERS :
   cfgset  TYPE /psyng/seconfid         MODIF ID con.
SELECTION-SCREEN END OF BLOCK blk1.

SELECTION-SCREEN BEGIN OF BLOCK blk2 WITH FRAME TITLE text-t02.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 6(50) text-t03 MODIF ID int.
SELECTION-SCREEN END OF LINE.
PARAMETERS : p_rid   TYPE flag RADIOBUTTON GROUP g1,
             p_rtext TYPE flag RADIOBUTTON GROUP g1,
             p_rsens TYPE flag RADIOBUTTON GROUP g1.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 6(50) text-t04 MODIF ID int.
SELECTION-SCREEN END OF LINE.

PARAMETERS: p_conmit TYPE flag RADIOBUTTON GROUP g1.
PARAMETERS : p_texts TYPE flag DEFAULT ' ' MODIF ID sum NO-DISPLAY.
PARAMETERS :
  p_confun TYPE flag RADIOBUTTON GROUP g1,
  p_funmit TYPE flag RADIOBUTTON GROUP g1,
  p_contcd TYPE flag RADIOBUTTON GROUP g1,
  p_fundet TYPE flag RADIOBUTTON GROUP g1,
  p_orgvar TYPE flag RADIOBUTTON GROUP g1.
SELECTION-SCREEN END OF BLOCK blk2.


AT SELECTION-SCREEN OUTPUT.
*--Get RFC destinations
  get_system p_system.
*--Intensify the two "title" comments on selection screen
  LOOP AT SCREEN.
    IF screen-group1 = 'INT'.
      screen-intensified = 1.
      MODIFY SCREEN.
    ENDIF.
*--Hide configuration set selection if not enabled
    IF gf_cfg_set_enabled IS INITIAL AND
      ( screen-name CS 'CFGSET' OR screen-name CS 'P_ORGVAR' ).
      screen-invisible = 1.
      screen-active    = 0.
      MODIFY SCREEN.
    ENDIF.

  ENDLOOP.
*--Check if Configuration Set functionality is enabled.
  IF gf_cfg_set_enabled = 'X' AND cfgset IS INITIAL.
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
*--   default to the latest published configuration set (highest nr)
    CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
      DESTINATION gt_rfcdes-rfcdest
      EXPORTING
        i_vrsio      = 'X'
        i_cfgvrsio   = p_vrsio
      IMPORTING
        e_config_set = cfgset
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


INITIALIZATION.
  g_program = sy-repid.
  PERFORM init_new_line.
  se_config_param 'CFG_SET_ENABLED' gf_cfg_set_enabled.
  IF gf_cfg_set_enabled = 'Y' OR gf_cfg_set_enabled = 'X'.
    gf_cfg_set_enabled  = 'X'.
  ELSE.
    CLEAR gf_cfg_set_enabled.
  ENDIF.




AT SELECTION-SCREEN.
*--Get RFC destinations
  get_system p_system.
*--Check if Configuration Set functionality is enabled.
  IF gf_cfg_set_enabled = 'X' AND cfgset IS INITIAL.
*--   default to the latest published configuration set (highest nr)
    CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
      EXPORTING
        i_vrsio      = 'X'
        i_cfgvrsio   = p_vrsio
      IMPORTING
        e_config_set = cfgset.
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_system.
  PERFORM f4_system USING 'P_SYSTEM' CHANGING p_system.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_vrsio.
  PERFORM f4_vrsio CHANGING p_vrsio.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR spconfs-low.
  PERFORM f4_conflicts CHANGING spconfs-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR spconfs-high.
  PERFORM f4_conflicts CHANGING spconfs-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_func-low.
  PERFORM f4_function CHANGING s_func-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_func-high.
  PERFORM f4_function CHANGING s_func-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pappa-low.
  PERFORM f4_busarea CHANGING pappa-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pappa-high.
  PERFORM f4_busarea CHANGING pappa-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_risk-low.
  PERFORM f4_risk CHANGING s_risk-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_risk-high.
  PERFORM f4_risk CHANGING s_risk-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR cprmit-low.
  PERFORM f4_contid CHANGING cprmit-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR cprmit-high.
  PERFORM f4_contid CHANGING cprmit-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR cfgset.
  PERFORM f4_setid CHANGING cfgset.

START-OF-SELECTION.

*BOC AKUMAR SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-25/11/2024

  PERFORM exelog.
  IF NOT gf_cfg_set_enabled IS INITIAL
  AND NOT p_orgvar IS INITIAL.
*--Check Config Set
    get_system p_system.
    CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
      DESTINATION gt_rfcdes-rfcdest
      EXPORTING
        i_setid               = cfgset
        i_vrsio               = p_vrsio
        if_show_warning       = 'X'
        IF_CALLED_FROM_OVW_REPORT = 'X'
      IMPORTING
        ef_wrong_version      = lf_set_invalid
      EXCEPTIONS
        communication_failure = 1 MESSAGE g_system_msg
        system_failure        = 2 MESSAGE g_system_msg
        OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*BOC:HBHALLA (04/12/24)
        IF sy-subrc <> 0.
       CASE sy-subrc.
         WHEN 1.
            MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
         WHEN 2.
            MESSAGE s002(/psyng/sw) WITH 'System failure'.
         WHEN OTHERS.
            MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
       ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)
    IF lf_set_invalid = 'X'.
      EXIT.
    ENDIF.
  ENDIF.

  CASE 'X'.
    WHEN p_orgvar.
      PERFORM org_variable_details.
    WHEN p_fundet.
      PERFORM functiondetails.
    WHEN p_contcd.
      PERFORM conflictfunctions USING ''  'X'.
    WHEN p_funmit.
      PERFORM conflictfunctions USING 'X' '' .
    WHEN p_confun.
      PERFORM conflictfunctions USING ''  ''.
    WHEN p_conmit.
      PERFORM conflictmitigations.
    WHEN p_rid.
      PERFORM matrix.
    WHEN p_rtext.
      PERFORM matrix.
    WHEN p_rsens.
      PERFORM matrix.
  ENDCASE.

TOP-OF-PAGE.
***Printing filed names in output for standard output
  WRITE:/ text-007, text-008, 83 text-009,
        95 text-010, 145 text-011,
        165 text-012, 202 text-023,213 text-025,
        224 text-027, 230 text-029 ,241 text-031,
        250 text-033.

*---------------------------------------------------------------------*
*       FORM matrix                                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM matrix.
  SUBMIT /psyng/sw_124 "VIA SELECTION-SCREEN
         WITH p_system = p_system
         WITH sodvrsio = p_vrsio
         WITH spconfs IN spconfs
         WITH s_func  IN s_func
         WITH pappa   IN pappa
         WITH cowner  IN cowner
         WITH csens   IN csens
         WITH s_risk  IN s_risk
         WITH s_func  IN s_func
         WITH cprmit  IN cprmit
         WITH p_rid   = p_rid
         WITH p_rtext = p_rtext
         WITH p_rsens = p_rsens
         AND RETURN.


ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  BUILD_ALV_STUFF
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_stuff.

  DATA: l_wa_fieldcat_alv TYPE slis_fieldcat_alv,
        l_sort            TYPE slis_sortinfo_alv.


  l_wa_fieldcat_alv-seltext_l = text-007.
  l_wa_fieldcat_alv-seltext_m = text-013.
  l_wa_fieldcat_alv-seltext_s = text-014.
  l_wa_fieldcat_alv-reptext_ddic = text-013.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_CONID'.



  l_wa_fieldcat_alv-seltext_l = text-008.
  l_wa_fieldcat_alv-seltext_m = text-015.
  l_wa_fieldcat_alv-seltext_s = text-015.
  l_wa_fieldcat_alv-reptext_ddic = text-015.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_CDESCRIPTION'.



  l_wa_fieldcat_alv-seltext_l = text-009.
  l_wa_fieldcat_alv-seltext_m = text-016.
  l_wa_fieldcat_alv-seltext_s = text-017.
  l_wa_fieldcat_alv-reptext_ddic = text-016.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_FUNCTIONID'.



  l_wa_fieldcat_alv-seltext_l = text-010.
  l_wa_fieldcat_alv-seltext_m = text-018.
  l_wa_fieldcat_alv-seltext_s = text-018.
  l_wa_fieldcat_alv-reptext_ddic = text-018.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_FDESCRIPTION'.


  l_wa_fieldcat_alv-seltext_l = text-023.
  l_wa_fieldcat_alv-seltext_m = text-024.
  l_wa_fieldcat_alv-seltext_s = text-024.
  l_wa_fieldcat_alv-reptext_ddic = text-024.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_OBJECT'.



  l_wa_fieldcat_alv-seltext_l = text-025.
  l_wa_fieldcat_alv-seltext_m = text-026.
  l_wa_fieldcat_alv-seltext_s = text-026.
  l_wa_fieldcat_alv-reptext_ddic = text-026.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_VALUESET'.




  l_wa_fieldcat_alv-seltext_l = text-027.
  l_wa_fieldcat_alv-seltext_m = text-028.
  l_wa_fieldcat_alv-seltext_s = text-028.
  l_wa_fieldcat_alv-reptext_ddic = text-028.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_FIELD'.



  l_wa_fieldcat_alv-seltext_l = text-029.
  l_wa_fieldcat_alv-seltext_m = text-030.
  l_wa_fieldcat_alv-seltext_s = text-030.
  l_wa_fieldcat_alv-reptext_ddic = text-030.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_VAL_FROM'.



  l_wa_fieldcat_alv-seltext_l = text-031.
  l_wa_fieldcat_alv-seltext_m = text-032.
  l_wa_fieldcat_alv-seltext_s = text-032.
  l_wa_fieldcat_alv-reptext_ddic = text-032.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_VAL_TO'.



  l_wa_fieldcat_alv-seltext_l = text-033.
  l_wa_fieldcat_alv-seltext_m = text-034.
  l_wa_fieldcat_alv-seltext_s = text-034.
  l_wa_fieldcat_alv-reptext_ddic = text-034.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_OBJ_OR'.

  l_wa_fieldcat_alv-seltext_l = text-035.
  l_wa_fieldcat_alv-seltext_m = text-036.
  l_wa_fieldcat_alv-seltext_s = text-036.
  l_wa_fieldcat_alv-reptext_ddic = text-036.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'FLD_AND'.

  CLEAR l_wa_fieldcat_alv-key.
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
   TRANSPORTING key
    WHERE key  = 'X'.


  CLEAR: l_sort, g_sort.
  REFRESH: g_sort.

  l_sort-spos = '1'.
  l_sort-fieldname = 'L_CONID'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'L_CDESCRIPTION'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'L_FUNCTIONID'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '4'.
  l_sort-fieldname = 'L_FDESCRIPTION'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '5'.
  l_sort-fieldname = 'L_TCODE'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.



  l_sort-spos = '7'.
  l_sort-fieldname = 'L_OBJECT'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.


  l_sort-spos = '8'.
  l_sort-fieldname = 'L_VALUESET'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '9'.
  l_sort-fieldname = 'L_ABB'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.


  l_sort-spos = '10'.
  l_sort-fieldname = 'L_FIELD'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.


  l_sort-spos = '11'.
  l_sort-fieldname = 'L_VARIABLE'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.



  l_sort-spos = '12'.
  l_sort-fieldname = 'L_VAL_FROM'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.


  l_sort-spos = '13'.
  l_sort-fieldname = 'L_VAL_TO'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

*  Don't store by obj_or, is confusing
*  l_sort-spos = '14'.
*  l_sort-fieldname = 'L_OBJ_OR'.
*  l_sort-tabname = 'GT_OUTPUT'.
*  l_sort-up = 'X'.
*  APPEND l_sort TO g_sort.

ENDFORM.                    " BUILD_ALV_STUFF
*&---------------------------------------------------------------------*
*&      Form  format_and_output_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM format_and_output_alv
  USING if_include_org_var TYPE flag.

****Local structure for final output

  TYPES: BEGIN OF ls_output_typ,
           l_conid        LIKE /psyng/conflict-conid,
           l_cdescription LIKE /psyng/conflict-description,
           l_functionid   LIKE /psyng/confdet-functionid,
           l_fdescription LIKE /psyng/function-description,
           l_tcode        LIKE tstc-tcode,
           l_tdescription LIKE tstct-ttext,
           l_object       LIKE /psyng/faobj2-object,
           l_valueset     LIKE /psyng/faobj2-valueset,
           l_abb          TYPE /psyng/dorg_abb,
           l_field        LIKE /psyng/faobj2-field,
           l_variable     LIKE /psyng/faobj2-val_from,
           l_val_from     LIKE /psyng/faobj2-val_from,
           l_val_to       LIKE /psyng/faobj2-val_to,
           l_obj_or       LIKE /psyng/faobj2-obj_or,
           fld_and        LIKE /psyng/faobj2-fld_and,
         END OF ls_output_typ.


  DATA: l_alv_layout    TYPE slis_layout_alv,
        l_alv_grid_titl TYPE lvc_title,
        ls_variant      TYPE disvariant,
        l_date(10),
        l_wa_output     TYPE ls_output_typ,
        ls_out_org      TYPE ls_output_typ,
        lt_output       TYPE SORTED TABLE OF ls_output_typ WITH UNIQUE
        KEY
                        l_conid l_cdescription l_functionid
                        l_fdescription
                        l_tcode l_object l_valueset l_abb
                        l_field l_val_from  l_val_to
                        WITH HEADER LINE,
        l_sysid         TYPE /psyng/sysid,
        lf_explicit     TYPE flag,
        lf_is_org_fld   TYPE flag,
        l_varbl         TYPE xufield.

  IF if_include_org_var = c_org_var_included .
    CONCATENATE sy-sysid sy-mandt INTO l_sysid.
  ENDIF.

************************************************************************
  LOOP AT gt_confdet.
    READ TABLE gt_conflict WITH KEY conid = gt_confdet-conid.
    LOOP AT gt_functtran WHERE functionid = gt_confdet-functionid.
      READ TABLE gt_function WITH KEY function = gt_functtran-functionid
      .
      IF gt_functtran-type = 'F'.
        READ TABLE gt_tstct WITH KEY tcode = gt_functtran-fioriid.
      ELSE.
        READ TABLE gt_tstct WITH KEY tcode = gt_functtran-tcode.
      ENDIF.
      LOOP AT  gt_faobj2  WHERE funid = gt_functtran-functionid AND
                                   tcode = gt_functtran-tcode.
        l_wa_output-l_conid        = gt_confdet-conid.
        l_wa_output-l_cdescription = gt_conflict-description.
        l_wa_output-l_functionid   = gt_functtran-functionid.
        l_wa_output-l_fdescription = gt_function-description.
        IF gt_functtran-type = 'F'.
          l_wa_output-l_tcode        = gt_functtran-fioriid.
        ELSE.
          l_wa_output-l_tcode        = gt_functtran-tcode.
        ENDIF.
        l_wa_output-l_tdescription = gt_tstct-ttext.
**********************************************************
        l_wa_output-l_object     =  gt_faobj2-object.
        l_wa_output-l_valueset   =  gt_faobj2-valueset.
        l_wa_output-l_field      =  gt_faobj2-field.
        l_wa_output-l_val_from   =  gt_faobj2-val_from.
        l_wa_output-l_val_to     =  gt_faobj2-val_to.
        l_wa_output-l_obj_or     =  gt_faobj2-obj_or.
        l_wa_output-fld_and      =  gt_faobj2-fld_and.

************************************************************
        IF if_include_org_var = c_org_var_included.
          IF l_wa_output-l_val_from CP '/PSYNG/$*'.
*--Insert variable element values
            READ TABLE gt_varel WITH TABLE KEY
              sysid       = l_sysid
              var_element = l_wa_output-l_val_from.
            IF sy-subrc = 0.
              ls_out_org = l_wa_output.
              CLEAR : ls_out_org-l_val_from, ls_out_org-l_val_to.
              LOOP AT gt_varel FROM sy-tabix.
                IF gt_varel-sysid <> l_sysid OR
                   gt_varel-var_element <> l_wa_output-l_val_from.
                  EXIT.
                ENDIF.
                ls_out_org-l_val_from = gt_varel-value.
                ls_out_org-l_variable = gt_varel-var_element.
                INSERT ls_out_org INTO TABLE lt_output.
              ENDLOOP.
            ENDIF.
          ELSE.
*--         check if this is an org relevant field
            CLEAR lf_is_org_fld.
            IF gf_explicit = 'X' AND
               l_wa_output-l_val_from CP '$*'.
              lf_is_org_fld = 'X'.
              l_varbl = l_wa_output-l_field.
              ls_out_org = l_wa_output.
              CLEAR : ls_out_org-l_val_from, ls_out_org-l_val_to.
              READ TABLE gt_swsodorgm WITH TABLE KEY
                object = l_wa_output-l_object
                varbl  = l_varbl.
              LOOP AT gt_swsodorgm FROM sy-tabix.
                IF gt_swsodorgm-object <> l_wa_output-l_object OR
                   gt_swsodorgm-varbl  <> l_varbl.
                  EXIT.
                ENDIF.
                ls_out_org-l_val_from = gt_swsodorgm-low.
                CONCATENATE '$' l_varbl INTO
                ls_out_org-l_variable.
                ls_out_org-l_abb = gt_swsodorgm-abb.

                INSERT ls_out_org INTO TABLE lt_output.
              ENDLOOP.
            ELSE.

              READ TABLE gt_orgobj WITH TABLE
                KEY objct = l_wa_output-l_object.
              IF sy-subrc = 0.
                ls_out_org = l_wa_output.
                CLEAR : ls_out_org-l_val_from, ls_out_org-l_val_to.
                LOOP AT gt_orgobj FROM sy-tabix.
                  IF gt_orgobj-objct <> l_wa_output-l_object.
                    EXIT.
                  ENDIF.
                  l_varbl = gt_orgobj-fiel1.
                  ls_out_org-l_field = l_varbl.
                  READ TABLE gt_swsodorgm WITH TABLE KEY
                    object = l_wa_output-l_object
                    varbl  = l_varbl.
                  LOOP AT gt_swsodorgm FROM sy-tabix.
                    IF gt_swsodorgm-object <> l_wa_output-l_object OR
                       gt_swsodorgm-varbl  <> l_varbl.
                      EXIT.
                    ENDIF.
                    ls_out_org-l_val_from = gt_swsodorgm-low.
                    ls_out_org-l_val_from = gt_swsodorgm-low.
                    CONCATENATE '$' l_varbl INTO
                    ls_out_org-l_variable.
                    ls_out_org-l_abb = gt_swsodorgm-abb.
                    INSERT ls_out_org INTO TABLE lt_output.
                  ENDLOOP.
                ENDLOOP.
              ENDIF.
              INSERT l_wa_output INTO TABLE lt_output.
            ENDIF.
            IF lf_is_org_fld = 'X'.
              ls_out_org = l_wa_output.
              CLEAR : ls_out_org-l_val_from, ls_out_org-l_val_to.
              READ TABLE gt_swsodorgm WITH TABLE KEY
                object = l_wa_output-l_object
                varbl  = l_varbl.
              LOOP AT gt_swsodorgm FROM sy-tabix.
                IF gt_swsodorgm-object <> l_wa_output-l_object OR
                   gt_swsodorgm-varbl  <> l_varbl.
                  EXIT.
                ENDIF.
                ls_out_org-l_val_from = gt_swsodorgm-low.
*---- Odubey 10.08.2023 Opl 588 duplicate value of org
*           INSERT ls_out_org INTO TABLE lt_output.
              ENDLOOP.
              IF gf_explicit = ''.
                INSERT l_wa_output INTO TABLE lt_output.
              ENDIF.
            ELSE.
              INSERT l_wa_output INTO TABLE lt_output.
            ENDIF.
          ENDIF.
        ELSE.
          INSERT l_wa_output INTO TABLE lt_output.
        ENDIF.
        CLEAR l_wa_output.
      ENDLOOP.
      IF sy-subrc <> 0.
        CLEAR l_wa_output.
        l_wa_output-l_conid        = gt_confdet-conid.
        l_wa_output-l_cdescription = gt_conflict-description.
        l_wa_output-l_functionid   = gt_functtran-functionid.
        l_wa_output-l_fdescription = gt_function-description.
        IF gt_functtran-type = 'F'.
          l_wa_output-l_tcode     = gt_tstct-tcode.
        ELSE.
          l_wa_output-l_tcode        = gt_functtran-tcode.
        ENDIF.
        l_wa_output-l_tdescription = gt_tstct-ttext.
        INSERT l_wa_output INTO TABLE lt_output.
        CLEAR l_wa_output.
      ENDIF.
    ENDLOOP.
    IF sy-subrc <> 0.
      CLEAR l_wa_output.
      l_wa_output-l_conid        = gt_confdet-conid.
      l_wa_output-l_cdescription = gt_conflict-description.
      l_wa_output-l_functionid   = gt_functtran-functionid.
*      l_wa_output-l_fdescription = text-019.
      INSERT l_wa_output INTO TABLE lt_output.
    ENDIF.
  ENDLOOP.


  REFRESH gt_output.
  CLEAR   gt_output.


  gt_output[] = lt_output[].

  REFRESH lt_output.

  CLEAR   lt_output.

  g_program = sy-repid.

  l_alv_layout-zebra = 'X'.
  l_alv_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name     = g_program
      i_internal_tabname = 'GT_OUTPUT'
      i_inclname         = g_program
    CHANGING
      ct_fieldcat        = g_fieldcat_alv
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

**************************************************

  PERFORM build_alv_stuff.

  WRITE sy-datum TO l_date.

  CONCATENATE 'Security Weaver(TM) SOD Matrix version:'(020)
               p_vrsio 'as of'(022) l_date
                INTO l_alv_grid_titl SEPARATED BY space.

  hotspot 'L_CONID'.
  hotspot 'L_FUNCTIONID'.
  hotspot 'L_TCODE'.
  text  'L_TCODE' 'Tcode/App'(a01).
  text  'L_TDESCRIPTION' 'Text'(a02).
  text  'L_OBJ_OR'    'Object OR'(037).
  text  'FLD_AND'     'Field AND'(038).
  text  'L_OBJECT'    'Object'(039).
  text  'L_FIELD'     'Field'(040).
  text  'L_ABB'       'Company Code'(043).
  text  'L_VARIABLE'  'Variable'(042).

  IF if_include_org_var <> c_org_var_included.
    hidefield : 'L_ABB', 'L_VARIABLE'.
  ELSE.
    hidefield : 'L_CDESCRIPTION',
                'L_FDESCRIPTION',
                'L_TDESCRIPTION'.
*                'L_OBJ_OR',
*                'FLD_AND'.
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_grid_title            = l_alv_grid_titl
      i_callback_program      = g_program
      i_callback_top_of_page  = 'ALV_HEADER'
      i_callback_user_command = 'ALV_CLICK'
      it_sort                 = g_sort
      is_layout               = l_alv_layout
      it_fieldcat             = g_fieldcat_alv
      i_save                  = 'A'
      is_variant              = ls_variant
    TABLES
      t_outtab                = gt_output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " format_and_output_alv


*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: header     TYPE slis_t_listheader,
        wa         TYPE slis_listheader,
        l_date(12) TYPE c.

  wa-typ = 'H'.
  wa-info = 'SOD Matrix in Security Weaver'(h01).
  APPEND wa TO header.
*SOD Version.
  wa-typ = 'S'.
  wa-key = 'Sod Version'(h02).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = p_vrsio.
  CONCATENATE p_vrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*Date
  wa-typ = 'S'.
  wa-key = 'Date'(h03).
  WRITE sy-datum TO l_date.
  wa-info = l_date.
  APPEND wa TO header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = header.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.

  CASE 'X'.
    WHEN p_orgvar.
      exelog sy-repid 'ORG_VAR'.
    WHEN p_fundet.
      exelog sy-repid 'DETAILS'.
    WHEN p_contcd.
      exelog sy-repid 'CON_TRAN'.
    WHEN p_funmit.
      exelog sy-repid 'FUN_MIT'.
    WHEN p_confun.
      exelog sy-repid 'CON_FUN'.
    WHEN p_conmit.
      exelog sy-repid 'CON_MIT'.
    WHEN p_rid.
      exelog sy-repid 'MATRIX_ID'.
    WHEN p_rtext.
      exelog sy-repid 'MATRIX_TEXT'.
    WHEN p_rsens.
      exelog sy-repid 'MATRIX_SENS'.
  ENDCASE.


ENDFORM.                    " exelog

*---------------------------------------------------------------------*
*       FORM load_functiondetails                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IF_ORG_VAR_INCLUDED                                           *
*---------------------------------------------------------------------*
FORM load_functiondetails
  USING if_org_var_included TYPE flag.
  REFRESH:gt_confdet,gt_conflict,gt_functtran,gt_function,gt_faobj2.
  CLEAR:gt_confdet,gt_conflict,gt_functtran,gt_function,gt_faobj2.
  DATA : lt_conflict    TYPE TABLE OF /psyng/conflict,
         lt_confdet     TYPE TABLE OF /psyng/confdet,
         lt_functtran   TYPE TABLE OF /psyng/functtran,
         lt_faobj2      TYPE TABLE OF /psyng/faobj2,
         lt_confdet_tmp TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
         lt_function    TYPE TABLE OF /psyng/function WITH HEADER LINE,
         l_sysid        TYPE /psyng/sysid,
         lt_swsodorg    TYPE TABLE OF /psyng/swsodorgm,
         lt_varel       TYPE TABLE OF /psyng/swcfgve,
         lt_tobj        TYPE TABLE OF tobj.

  get_system p_system.

*--Load sod matrix
  CALL FUNCTION '/PSYNG/SW_028'
    DESTINATION gt_rfcdes-rfcdest
    EXPORTING
      i_vrsio               = p_vrsio
      i_orgcheck            = 'X'
      if_ignore_var_elem    = 'X'
    TABLES
      it_spconfs            = spconfs
      it_bus_area           = pappa
      it_imp                = csens
      it_cowner             = cowner
      it_risk               = s_risk
      it_contid             = cprmit
      it_functions          = s_func
      et_conflict           = lt_conflict
      et_confdet            = lt_confdet
      et_functtran          = lt_functtran
      et_faobj              = lt_faobj2
    EXCEPTIONS
      communication_failure = 1 MESSAGE g_system_msg
      system_failure        = 2 MESSAGE g_system_msg
      OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*BOC:HBHALLA (04/12/24)
        IF sy-subrc <> 0.
       CASE sy-subrc.
         WHEN 1.
            MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
         WHEN 2.
            MESSAGE s002(/psyng/sw) WITH 'System failure'.
         WHEN OTHERS.
            MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
       ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)

  gt_conflict[]   = lt_conflict[].
  gt_confdet[]    = lt_confdet[].
  gt_functtran[]  = lt_functtran[].
  gt_faobj2[]     = lt_faobj2[].
  FREE : lt_conflict, lt_confdet, lt_functtran, lt_faobj2.


  IF gt_conflict[] IS INITIAL.
    MESSAGE s002(/psyng/sw) WITH
    'No Data found for corresponding input'(041).
    LEAVE LIST-PROCESSING.
  ELSE.
*--B12970for overwrite 028 success messag
    MESSAGE s002(/psyng/sw) WITH
           'Data loaded'(004).

    lt_confdet_tmp[] =  gt_confdet[].

    CALL FUNCTION '/PSYNG/SW_126'
      DESTINATION gt_rfcdes-rfcdest
      EXPORTING
        i_vrsio               = p_vrsio
        i_function            = 'X'
      TABLES
        it_confdet            = lt_confdet_tmp
        et_function           = lt_function
      EXCEPTIONS
        communication_failure = 1 MESSAGE g_system_msg
        system_failure        = 2 MESSAGE g_system_msg
        OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*BOC:HBHALLA (04/12/24)
        IF sy-subrc <> 0.
       CASE sy-subrc.
         WHEN 1.
            MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
         WHEN 2.
            MESSAGE s002(/psyng/sw) WITH 'System failure'.
         WHEN OTHERS.
            MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
       ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)

*    APPEND LINES OF lt_confdet_tmp TO gt_confdet.
    SORT lt_function BY function.
    APPEND LINES OF lt_function TO gt_function.
*---free the tmp tables
    FREE: lt_function, lt_confdet_tmp.

    LOOP AT gt_functtran.

      IF gt_functtran-type = 'F'.
        g_wa_tstct-tcode = gt_functtran-fioriid.
        PERFORM get_appname USING    gt_functtran-fioriid
                         CHANGING g_wa_tstct-ttext.
        INSERT g_wa_tstct INTO TABLE gt_tstct.

      ELSE.
        SELECT SINGLE * FROM tstct
                        INTO g_wa_tstct
                        WHERE sprsl = sy-langu AND
                              tcode = gt_functtran-tcode.
        IF sy-subrc = 0.
          INSERT g_wa_tstct INTO TABLE gt_tstct.
        ELSE.
          SELECT SINGLE * FROM tstct
                        INTO g_wa_tstct
                        WHERE sprsl = sy-langu AND
                              tcode = gt_functtran-tcode.
          IF sy-subrc = 0.
            INSERT g_wa_tstct INTO TABLE gt_tstct.
          ELSE.
*********Case#1994
            IF gt_functtran-tcode  CP
                /psyng/sw_cl_constants=>placeholder_tcode_prefix.
              g_wa_tstct-ttext =
              'Placeholder for objectlevel analysis'(191).
            ELSE.
              g_wa_tstct-ttext =
              'Tcode for cross system analysis'(192).
            ENDIF.
            g_wa_tstct-tcode = gt_functtran-tcode.
            INSERT g_wa_tstct INTO TABLE gt_tstct.
          ENDIF.
          CLEAR  g_wa_tstct.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF if_org_var_included = c_org_var_included.
    CONCATENATE sy-sysid sy-mandt INTO l_sysid.
*--Check if SOD matrix is explicit
    LOOP AT  gt_faobj2 WHERE val_from CP '$*'.
      gf_explicit = 'X'.
      EXIT.
    ENDLOOP.

*--Load Org Values of config set
    CALL FUNCTION '/PSYNG/SW_AO_READ_VALUES'
      EXPORTING
        i_vrsio      = p_vrsio
        i_setid      = cfgset
        i_sysid      = l_sysid
*       IMPORTING
*       EF_SUCCESS   =
      TABLES
        et_swsodorgm = lt_swsodorg.
    SORT lt_swsodorg BY object varbl abb low high.
    gt_swsodorgm[] = lt_swsodorg[].
    FREE : lt_swsodorg.
    IF NOT gf_explicit = 'X'.
*--Load org relevant objects
      CALL FUNCTION '/PSYNG/SW_AO_002'
        EXPORTING
          i_sodvrsio       = p_vrsio
          i_setid          = cfgset
        TABLES
          et_tobj          = lt_tobj
        EXCEPTIONS
          version_no_exist = 1
          OTHERS           = 2.
      IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*           WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.
      SORT lt_tobj BY objct.
      gt_orgobj[] = lt_tobj[].
      FREE : lt_tobj.
    ENDIF.
*--Load Variable Element values of config set
    CALL FUNCTION '/PSYNG/SW_VE_READ'
      EXPORTING
        if_read      = 'X'
        i_setid      = cfgset
*     IMPORTING
*       EF_SUCCESS   =
      TABLES
        et_ve_values = lt_varel
*BOC:HBHALLA (04/12/24)
    EXCEPTIONS
            OTHERS = 1 .
        IF sy-subrc <> 0.
       CASE sy-subrc.
         WHEN OTHERS.
            MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
       ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)
    SORT lt_varel BY sysid var_element value.

*----opl588 odubey 17.07.2023
*---- show only active variable values
    delete lt_varel where active <> 'X'.

*    end odubey
    gt_varel[] = lt_varel[].
    FREE : lt_varel.

  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  functiondetails
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM functiondetails.
  PERFORM load_functiondetails
    USING c_org_var_not_included.
  PERFORM format_and_output_alv
    USING c_org_var_not_included.
ENDFORM.                    " functiondetails
*&---------------------------------------------------------------------*
*&      Form  conflictfunctions
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM conflictfunctions USING if_mitigations TYPE flag
                             if_tcodes      TYPE flag.
  DATA : lt_conflict     TYPE TABLE OF /psyng/conflict WITH HEADER LINE,
         lt_conpmit      TYPE TABLE OF /psyng/conpmit WITH HEADER LINE,
         lt_mchdr        TYPE TABLE OF /psyng/mchdr WITH HEADER LINE,
         lt_texts        TYPE TABLE OF /psyng/texts WITH HEADER LINE,
         lt_confdet      TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
         lt_functions    TYPE TABLE OF /psyng/function WITH HEADER LINE,
         lt_functtran    TYPE TABLE OF /psyng/functtran WITH HEADER LINE
         ,
         lt_tcodes       TYPE TABLE OF tstct WITH HEADER LINE,
         l_alv_grid_titl TYPE lvc_title,
         ls_variant      TYPE disvariant,
         l_date(10),
         l_alv_layout    TYPE slis_layout_alv.

  get_system p_system.
*--Load sod matrix
  CALL FUNCTION '/PSYNG/SW_028'
    DESTINATION gt_rfcdes-rfcdest
    EXPORTING
      i_vrsio               = p_vrsio
    TABLES
      it_spconfs            = spconfs
      it_bus_area           = pappa
      it_imp                = csens
      it_cowner             = cowner
      it_risk               = s_risk
      it_functions          = s_func
      it_contid             = cprmit
      et_conflict           = lt_conflict
      et_confdet            = lt_confdet
      et_functtran          = lt_functtran
    EXCEPTIONS
      communication_failure = 1 MESSAGE g_system_msg
      system_failure        = 2 MESSAGE g_system_msg
      OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*BOC:HBHALLA (04/12/24)
        IF sy-subrc <> 0.
       CASE sy-subrc.
         WHEN 1.
            MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
         WHEN 2.
            MESSAGE s002(/psyng/sw) WITH 'System failure'.
         WHEN OTHERS.
            MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
       ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)


  IF lt_conflict[] IS INITIAL.
    MESSAGE s002(/psyng/sw) WITH
    'No Data found for corresponding input'(041).
  ELSE.
*--B12970for overwrite 028 success messag
    MESSAGE s002(/psyng/sw) WITH
           'Data loaded'(004).
*--Get the function headers
    IF NOT lt_confdet[] IS INITIAL.
*      SELECT * FROM /psyng/function
*      INTO TABLE lt_functions
*      FOR ALL ENTRIES IN lt_confdet
*      WHERE
*        vrsio = p_vrsio AND
*        function = lt_confdet-functionid.

      CALL FUNCTION '/PSYNG/SW_126'
        DESTINATION gt_rfcdes-rfcdest
        EXPORTING
          i_vrsio               = p_vrsio
          i_function            = 'X'
        TABLES
          it_confdet            = lt_confdet
          et_function           = lt_functions
        EXCEPTIONS
          communication_failure = 1 MESSAGE g_system_msg
          system_failure        = 2 MESSAGE g_system_msg
          OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*BOC:HBHALLA (04/12/24)
        IF sy-subrc <> 0.
       CASE sy-subrc.
         WHEN 1.
            MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
         WHEN 2.
            MESSAGE s002(/psyng/sw) WITH 'System failure'.
         WHEN OTHERS.
            MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
       ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)


      SORT lt_functions BY function.
      SORT lt_confdet BY conid functionid.
    ENDIF.
*--Get the transactions
    IF NOT if_tcodes IS INITIAL AND NOT lt_functtran[] IS INITIAL.
*      SELECT tcode ttext
*      FROM tstct
*      INTO CORRESPONDING FIELDS OF TABLE lt_tcodes
*      FOR ALL ENTRIES IN lt_functtran WHERE
*      sprsl = sy-langu AND
*      tcode = lt_functtran-tcode.
      CALL FUNCTION '/PSYNG/SW_126'
        DESTINATION gt_rfcdes-rfcdest
        EXPORTING
          if_tcodes             = 'X'
        TABLES
          it_functtran          = lt_functtran
          et_tstct              = lt_tcodes
        EXCEPTIONS
          communication_failure = 1 MESSAGE g_system_msg
          system_failure        = 2 MESSAGE g_system_msg
          OTHERS                = 3. "#EC SAST_CI_GEN_CHECK

      SORT lt_functtran BY functionid tcode.
      SORT lt_tcodes BY tcode.

    ENDIF.
    IF if_mitigations = 'X'.
      PERFORM get_proposed_mitigations TABLES lt_conflict
                                              lt_conpmit
                                              lt_mchdr
                                              lt_texts
                                       USING ''.
    ENDIF.
*--Combine in output format
    gt_conflict[] = lt_conflict[].
    LOOP AT gt_conflict.
      CLEAR gt_conflictfunctions.
      gt_conflictfunctions-conid         =   gt_conflict-conid.
      gt_conflictfunctions-cdescription  =   gt_conflict-description.
      gt_conflictfunctions-busarea       =   gt_conflict-busarea.
      gt_conflictfunctions-subarea       =   gt_conflict-subarea.
      gt_conflictfunctions-risk          =   gt_conflict-risk.
      IF NOT gt_conflict-contid IS INITIAL.
        gt_conflictfunctions-contid      = gt_conflict-contid.
        get_mc_shorttext lt_mchdr
                         gt_conflictfunctions-contid
                         gt_conflictfunctions-mdescription.
        PERFORM add_functions
          TABLES lt_confdet
                 lt_functions
                 lt_functtran
                 lt_tcodes
          USING  if_tcodes.
*      APPEND gt_conflictfunctions.
      ENDIF.
      LOOP AT lt_conpmit WHERE conid = gt_conflictfunctions-conid.
        gt_conflictfunctions-company =   lt_conpmit-company.
        gt_conflictfunctions-contid  =   lt_conpmit-contid.
        get_mc_shorttext lt_mchdr
                         gt_conflictfunctions-contid
                         gt_conflictfunctions-mdescription.
*      APPEND gt_conflictfunctions.
        PERFORM add_functions
          TABLES lt_confdet
                 lt_functions
                 lt_functtran
                 lt_tcodes
          USING  if_tcodes.

      ENDLOOP.
      IF sy-subrc <> 0 AND gt_conflict-contid IS INITIAL..
*--No Mitigation found
*      APPEND gt_outconmit.
        PERFORM add_functions
          TABLES lt_confdet
                 lt_functions
                 lt_functtran
                 lt_tcodes
          USING  if_tcodes.

      ENDIF.
    ENDLOOP.

*--ALV Output
    g_program = sy-repid.
    l_alv_layout-zebra = 'X'.
    l_alv_layout-colwidth_optimize = 'X'.
    l_alv_layout-max_linesize = 2500.
    REFRESH : g_fieldcat_alv.
    CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
      EXPORTING
        i_program_name     = g_program
        i_internal_tabname = 'GT_CONFLICTFUNCTIONS'
        i_inclname         = g_program
      CHANGING
        ct_fieldcat        = g_fieldcat_alv
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
    WRITE sy-datum TO l_date.

    CONCATENATE text-020 p_vrsio text-022 l_date
                  INTO l_alv_grid_titl SEPARATED BY space.

*--modify text
    text  'TCODE'    'Tcode/App'(a01).
    text  'TTEXT'    'Text'(a02).

*--Hotspots
    hotspot 'CONID'.
    hotspot 'FUNCTIONID'.
    hotspot 'CONTID'.
    hotspot 'TCODE'.

*--Sorting
    CLEAR gs_sort-spos.
    sort_col 'CONID'        'GT_CONFLICTFUNCTIONS'.
    sort_col 'CDESCRIPTION' 'GT_CONFLICTFUNCTIONS'.
    sort_col 'BUSAREA'      'GT_CONFLICTFUNCTIONS'.
    sort_col 'SUBAREA'      'GT_CONFLICTFUNCTIONS'.
    sort_col 'RISK'         'GT_CONFLICTFUNCTIONS'.
    sort_col 'FUNCTIONID'   'GT_CONFLICTFUNCTIONS'.
    sort_col 'FDESCRIPTION' 'GT_CONFLICTFUNCTIONS'.
    IF if_mitigations = 'X'.
      sort_col 'CONTID'       'GT_CONFLICTFUNCTIONS'.
      sort_col 'MDESCRIPTION' 'GT_CONFLICTFUNCTIONS'.
      sort_col 'COMPANY'      'GT_CONFLICTFUNCTIONS'.
    ENDIF.
    IF if_tcodes = 'X'.
      sort_col 'TCODE'       'GT_CONFLICTFUNCTIONS'.
      sort_col 'TTEXT'       'GT_CONFLICTFUNCTIONS'.
    ENDIF.


*--Don't show fields related to mitigation
    IF if_mitigations IS INITIAL.
      DELETE g_fieldcat_alv WHERE fieldname = 'CONTID' OR
                                  fieldname = 'MDESCRIPTION' OR
                                  fieldname = 'COMPANY' OR
                                  fieldname = 'MITLONGT'.
    ENDIF.
*--Don't show fields related to tcode
    IF if_tcodes IS INITIAL.
      DELETE g_fieldcat_alv WHERE fieldname = 'TCODE' OR
                                  fieldname = 'TTEXT'.
    ENDIF.
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_grid_title            = l_alv_grid_titl
        i_callback_program      = g_program
        i_callback_top_of_page  = 'ALV_HEADER'
        i_callback_user_command = 'ALV_CLICK'
        it_sort                 = g_sort
        is_layout               = l_alv_layout
        it_fieldcat             = g_fieldcat_alv
        i_save                  = 'A'
        is_variant              = ls_variant
      TABLES
        t_outtab                = gt_conflictfunctions
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

  ENDIF.
ENDFORM.                    " conflictfunctions


*---------------------------------------------------------------------*
*       FORM alv_click                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM alv_click USING r_ucomm LIKE sy-ucomm
                     rs_selfield TYPE slis_selfield.
*--Store default SOD version temporarily
*  then set default version to current version and navigate to SE
*  when getting back, restore default
  DATA : l_sodvrsio TYPE /psyng/sodvrsio,
         lf_go      TYPE flag,
         l_type     TYPE /psyng/tcodetype,
         l_tcode    TYPE tstct-tcode.

  CLEAR lf_go.
  CASE rs_selfield-fieldname.
    WHEN 'CONID' OR 'L_CONID'.
      lf_go = 'X'.
      SET PARAMETER ID '/PSYNG/CON' FIELD rs_selfield-value.
      g_dynnr = '0202'.
    WHEN 'FUNCTIONID' OR 'L_FUNCTIONID'.
      lf_go = 'X'.
      SET PARAMETER ID '/PSYNG/FUN' FIELD rs_selfield-value.
      g_dynnr = '0201'.
    WHEN 'CONTID'.
      lf_go = 'X'.
      SET PARAMETER ID '/PSYNG/SW_MIT' FIELD rs_selfield-value.
      g_dynnr = '0211'.
    WHEN 'TCODE'.
      READ TABLE gt_conflictfunctions INDEX rs_selfield-tabindex.
      PERFORM get_function_type USING
                  gt_conflictfunctions-tcode
                  gt_conflictfunctions-functionid
                  CHANGING l_type.
      PERFORM tcode_drill_down
            USING l_type
            gt_conflictfunctions-tcode.
    WHEN 'L_TCODE'.
      READ TABLE gt_output INDEX rs_selfield-tabindex.
      PERFORM get_function_type USING
               gt_output-l_tcode
               gt_output-l_functionid
               CHANGING l_type.
      PERFORM tcode_drill_down
          USING l_type
            gt_output-l_tcode.
  ENDCASE.
  IF lf_go = 'X'.
    CALL FUNCTION '/PSYNG/SW_DISPLAY_OBJECT'
      EXPORTING
        i_objecttype = rs_selfield-fieldname
        i_objectid   = rs_selfield-value
        i_vrsio      = p_vrsio.
    CLEAR lf_go.
  ENDIF.

ENDFORM.

FORM tcode_drill_down USING
            i_type  TYPE /psyng/tcodetype
            i_tcode TYPE tstct-tcode .
  CALL FUNCTION '/PSYNG/SW_DISPLAY_TCODE'
    EXPORTING
      i_type        = i_type
      i_tcode       = i_tcode.

*  DATA: l_fioriid   TYPE /psyng/sw_fioriid.
*  CASE  i_type.
*    WHEN 'F'.
*      l_fioriid =   i_tcode.
*      PERFORM show_app_detail_screen
*          USING l_fioriid.
*    WHEN 'T'.
*      PERFORM execute_tcode_popup
*           USING i_tcode.
*    WHEN 'P'.
*      MESSAGE i113(/psyng/sw) WITH
*      'No info for Placeholder Transactions'(087).
*  ENDCASE.
ENDFORM .

*FORM show_app_detail_screen
*     USING i_fioriid TYPE /psyng/sw_fioriid.
*
*  CALL FUNCTION '/PSYNG/SW_FIORIAPP_SHOW'
*    EXPORTING
*      i_fioriid = i_fioriid
*    EXCEPTIONS
*      not_found = 1
*      OTHERS    = 2.
*  IF sy-subrc <> 0.
** Implement suitable error handling here
*  ENDIF.
*ENDFORM.

*FORM execute_tcode_popup USING
*      i_tcode TYPE tstct-tcode.
*  DATA: line(80),
*        answer.
*
*  SELECT ttext FROM tstct INTO line
*       WHERE sprsl = sy-langu AND tcode = i_tcode.
*    EXIT.
*  ENDSELECT.
*  CALL FUNCTION 'POPUP_TO_CONFIRM'
*    EXPORTING
*      titlebar              = i_tcode
*      text_question         = line
*      text_button_1         = text-121
*      icon_button_1         = 'ICON_EXECUTE_OBJECT'
*      text_button_2         = text-122
*      icon_button_2         = 'ICON_SYSTEM_CANCEL'
*      default_button        = '2'
*      display_cancel_button = ' '
*    IMPORTING
*      answer                = answer.
*
*  CHECK answer = '1'.
*  AUTHORITY-CHECK OBJECT 'S_TCODE'
*           ID 'TCD' FIELD i_tcode.
*  IF sy-subrc = 0.
*    SELECT SINGLE tcode FROM tstc INTO i_tcode
*      WHERE tcode = i_tcode .
*    IF sy-subrc = 0.
*      CALL TRANSACTION i_tcode.
*    ELSE.
*      MESSAGE s398(00) WITH
*        'Transaction does not exist.'(086).
*    ENDIF.
*  ELSE.
*    MESSAGE s398(00) WITH
*    'Not authorized to run transaction'(085).
*  ENDIF.
*ENDFORM.

FORM get_function_type USING i_tcode TYPE tstc-tcode
                        i_function TYPE /psyng/function_id
               CHANGING e_type TYPE /psyng/tcodetype.
  TYPES: BEGIN OF typ_tcode,
           tcode      TYPE /psyng/sw_fioria-fioriid,
           functionid TYPE /psyng/function_id,
           type       TYPE /psyng/tcodetype,
         END OF typ_tcode.
  STATICS: lt_funtcode TYPE HASHED TABLE OF typ_tcode WITH UNIQUE KEY
  tcode
     functionid.
  DATA ls_funtcode TYPE typ_tcode.
  CLEAR e_type.

  READ TABLE lt_funtcode INTO ls_funtcode WITH TABLE KEY
                    tcode      = i_tcode
                    functionid = i_function.
  IF sy-subrc = 0.
    e_type = ls_funtcode-type.
  ELSE.
    SELECT SINGLE  type INTO ls_funtcode-type        "#EC CI_SEL_NESTED
      FROM /psyng/functtran WHERE
       functionid = i_function
      AND vrsio   = p_vrsio
      AND tcode = i_tcode.
    IF sy-subrc <> 0.
      SELECT SINGLE type INTO ls_funtcode-type
        FROM /psyng/functtran WHERE
        functionid = i_function
       AND vrsio   = p_vrsio
       AND fioriid = i_tcode.
    ENDIF.
    CHECK sy-subrc = 0.
    ls_funtcode-tcode = i_tcode.
    ls_funtcode-functionid = i_function.
    INSERT ls_funtcode INTO TABLE lt_funtcode.
    e_type = ls_funtcode-type.
  ENDIF.
ENDFORM.

FORM get_appname USING    i_fioriid TYPE /psyng/sw_fioria-fioriid
                    CHANGING e_appname TYPE tstct-ttext.
  TYPES: BEGIN OF typ_appname,
           fioriid TYPE /psyng/sw_fioria-fioriid,
           appname TYPE /psyng/sw_fioria-appname,
         END OF typ_appname.

  STATICS: lt_appname TYPE HASHED TABLE OF typ_appname WITH UNIQUE KEY
  fioriid.
  DATA: ls_appname TYPE typ_appname.
  CLEAR e_appname.
  READ TABLE lt_appname INTO ls_appname WITH TABLE KEY
                    fioriid = i_fioriid.
  IF sy-subrc = 0.
    e_appname = ls_appname-appname.
  ELSE.
    SELECT SINGLE appname INTO ls_appname-appname    "#EC CI_SEL_NESTED
      FROM /psyng/sw_fioria WHERE
      fioriid = i_fioriid.
    CHECK sy-subrc = 0.
    ls_appname-fioriid = i_fioriid.
    INSERT ls_appname INTO TABLE lt_appname.
    e_appname = ls_appname-appname.
  ENDIF.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM get_proposed_mitigations                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_CONFLICTS                                                  *
*  -->  ET_CONPMIT                                                    *
*  -->  ET_MCHDR                                                      *
*---------------------------------------------------------------------*
FORM get_proposed_mitigations
  TABLES it_conflicts STRUCTURE /psyng/conflict
         et_conpmit   STRUCTURE /psyng/conpmit
         et_mchdr     STRUCTURE /psyng/mchdr
         et_texts     STRUCTURE /psyng/texts
  USING
    if_texts TYPE flag.

*  RANGES : lr_mc FOR et_mchdr-contid,
*            lr_conid FOR it_conflicts-conid.
*
*  IF NOT it_conflicts[] IS INITIAL.
**--Get Proposed Mitigations
*    SELECT * FROM /psyng/conpmit INTO TABLE et_conpmit
*    FOR ALL ENTRIES IN it_conflicts WHERE vrsio = it_conflicts-vrsio
*AND
*                                          conid = it_conflicts-conid.
**--Collect proposed mitigations
*    lr_mc-sign   = 'I'.
*    lr_mc-option = 'EQ'.
*    LOOP AT it_conflicts.
*      IF NOT it_conflicts-contid IS INITIAL.
*        lr_mc-low = it_conflicts-contid.
*        COLLECT lr_mc.
*      ENDIF.
*    ENDLOOP.
*    LOOP AT et_conpmit.
*      lr_mc-low =  et_conpmit-contid.
*      COLLECT lr_mc.
*    ENDLOOP.
**--Load Mitigation Headers
*    IF NOT lr_mc[] IS INITIAL.
*      SELECT * FROM /psyng/mchdr INTO TABLE et_mchdr
*      WHERE contid IN lr_mc.
*    ENDIF.
*  ENDIF.
*  IF if_texts  ='X'.
**--Load the long texts
*    IF NOT lr_mc[] IS INITIAL.
**--Mitigation Texts
*      SELECT * FROM /psyng/texts INTO TABLE et_texts
*      WHERE object = 'M' AND textname IN lr_mc.
*    ENDIF.
**--Conflict Texts
*    lr_conid-sign   = 'I'.
*    lr_conid-option = 'EQ'.
*    LOOP AT it_conflicts.
*      lr_conid-low = it_conflicts-conid.
*      COLLECT lr_conid.
*    ENDLOOP.
*    SELECT * FROM /psyng/texts APPENDING TABLE et_texts
*    WHERE object = 'C' AND
*    textname IN lr_conid AND
*    vrsio = p_vrsio.
*
*  ENDIF.

  CALL FUNCTION '/PSYNG/SW_126'
    DESTINATION gt_rfcdes-rfcdest
    EXPORTING
      i_vrsio               = p_vrsio
      i_propose_mitigation  = 'X'
      if_texts              = if_texts
    TABLES
      it_conflicts          = it_conflicts
      et_conpmit            = et_conpmit
      et_texts              = et_texts
      et_mchdr              = et_mchdr
    EXCEPTIONS
      communication_failure = 1 MESSAGE g_system_msg
      system_failure        = 2 MESSAGE g_system_msg
      OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*BOC:HBHALLA (04/12/24)
        IF sy-subrc <> 0.
       CASE sy-subrc.
         WHEN 1.
            MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
         WHEN 2.
            MESSAGE s002(/psyng/sw) WITH 'System failure'.
         WHEN OTHERS.
            MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
       ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)
*BOC:HBHALLA (04/12/24)
        IF sy-subrc <> 0.
       CASE sy-subrc.
         WHEN 1.
            MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
         WHEN 2.
            MESSAGE s002(/psyng/sw) WITH 'System failure'.
         WHEN OTHERS.
            MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
       ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  conflictmitigations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM conflictmitigations.
  REFRESH:gt_confdet,gt_conflict,gt_functtran,gt_function,gt_faobj2.
  CLEAR:gt_confdet,gt_conflict,gt_functtran,gt_function,gt_faobj2.
  DATA : lt_conflict     TYPE TABLE OF /psyng/conflict WITH HEADER LINE,
         lt_conpmit      TYPE TABLE OF /psyng/conpmit WITH HEADER LINE,
         lt_mchdr        TYPE TABLE OF /psyng/mchdr WITH HEADER LINE,
         lt_texts        TYPE TABLE OF /psyng/texts WITH HEADER LINE,
         l_alv_grid_titl TYPE lvc_title,
         ls_variant      TYPE disvariant,
         l_date(10),
         l_alv_layout    TYPE slis_layout_alv.

  get_system p_system.

*--Load sod matrix
  CALL FUNCTION '/PSYNG/SW_028'
    DESTINATION gt_rfcdes-rfcdest
    EXPORTING
      i_vrsio               = p_vrsio
    TABLES
      it_spconfs            = spconfs
      it_bus_area           = pappa
      it_imp                = csens
      it_cowner             = cowner
      it_functions          = s_func
      it_risk               = s_risk
      it_contid             = cprmit
      et_conflict           = lt_conflict
    EXCEPTIONS
      communication_failure = 1 MESSAGE g_system_msg
      system_failure        = 2 MESSAGE g_system_msg
      OTHERS                = 3. "#EC SAST_CI_GEN_CHECK

  gt_conflict[]   = lt_conflict[].
*  FREE : lt_conflict.
  IF gt_conflict[] IS INITIAL.
    MESSAGE s002(/psyng/sw) WITH
    'No Data found for corresponding input'(041).
  ELSE.
*--B12970for overwrite 028 success messag
    MESSAGE s002(/psyng/sw) WITH
           'Data loaded'(004).

    PERFORM get_proposed_mitigations TABLES lt_conflict
                                            lt_conpmit
                                            lt_mchdr
                                            lt_texts
                                     USING p_texts.
    IF p_texts  ='X'.
*--Load the long texts
    ENDIF.
*--Combine in output format

    LOOP AT gt_conflict.
      CLEAR gt_outconmit.
      gt_outconmit-conid         =   gt_conflict-conid.
      gt_outconmit-cdescription  =   gt_conflict-description.
      gt_outconmit-busarea       =   gt_conflict-busarea.
      gt_outconmit-subarea       =   gt_conflict-subarea.
      gt_outconmit-risk          =   gt_conflict-risk.
      IF p_texts = 'X'.
        get_longtext gt_conflict-conid 'C' gt_outconmit-conlongt.
      ENDIF.
      IF NOT gt_conflict-contid IS INITIAL.
        gt_outconmit-contid      = gt_conflict-contid.
        get_mc_shorttext lt_mchdr
                         gt_outconmit-contid gt_outconmit-mdescription.
        IF p_texts = 'X'.
          get_longtext gt_conflict-contid 'M'
                       gt_outconmit-mitlongt.
        ENDIF.
        APPEND gt_outconmit.
      ENDIF.
      LOOP AT lt_conpmit WHERE conid = gt_outconmit-conid.
        gt_outconmit-company =   lt_conpmit-company.
        gt_outconmit-contid  =   lt_conpmit-contid.
        get_mc_shorttext lt_mchdr
                         gt_outconmit-contid gt_outconmit-mdescription.
        IF p_texts = 'X'.
          get_longtext gt_conflict-contid 'M'
                       gt_outconmit-mitlongt.
        ENDIF.
        APPEND gt_outconmit.
      ENDLOOP.
      IF sy-subrc <> 0 AND gt_conflict-contid IS INITIAL..
*--No Mitigation found
        APPEND gt_outconmit.
      ENDIF.
    ENDLOOP.

*--ALV Output
    g_program = sy-repid.
    l_alv_layout-zebra = 'X'.
    l_alv_layout-colwidth_optimize = 'X'.
    l_alv_layout-max_linesize = 2500.
    REFRESH : g_fieldcat_alv.
    CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
      EXPORTING
        i_program_name     = g_program
        i_internal_tabname = 'GT_OUTCONMIT'
        i_inclname         = g_program
      CHANGING
        ct_fieldcat        = g_fieldcat_alv
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
    WRITE sy-datum TO l_date.

    CONCATENATE text-020 p_vrsio text-022 l_date
                  INTO l_alv_grid_titl SEPARATED BY space.
*--Hotspots
    hotspot 'CONID'.
    hotspot 'CONTID'.

*--Sorting
    CLEAR gs_sort-spos.
    sort_col 'CONID'        'GT_OUTCONMIT'.
    sort_col 'CDESCRIPTION' 'GT_OUTCONMIT'.
    sort_col 'BUSAREA'      'GT_OUTCONMIT'.
    sort_col 'SUBAREA'      'GT_OUTCONMIT'.
    sort_col 'RISK'         'GT_OUTCONMIT'.
    sort_col 'CONTID'       'GT_OUTCONMIT'.
    sort_col 'MDESCRIPTION' 'GT_OUTCONMIT'.
    sort_col 'COMPANY'      'GT_OUTCONMIT'.
*--Add columns for Long Texts
    IF p_texts = 'X'.
      addcol   'CONLONGT' 1000.
      text     'CONLONGT' 'Conflict Long Text'.
      sort_col 'CONLONGT'      'GT_OUTCONMIT'.

      addcol   'MITLONGT' 1000.
      text     'MITLONGT' 'Mitigation Long Text'.
      sort_col 'MITLONGT' 'GT_OUTCONMIT'.
    ENDIF.
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_grid_title            = l_alv_grid_titl
        i_callback_program      = g_program
        i_callback_top_of_page  = 'ALV_HEADER'
        i_callback_user_command = 'ALV_CLICK'
        it_sort                 = g_sort
        is_layout               = l_alv_layout
        it_fieldcat             = g_fieldcat_alv
        i_save                  = 'A'
        is_variant              = ls_variant
      TABLES
        t_outtab                = gt_outconmit
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  ENDIF.
ENDFORM.                    " conflictmitigations

*---------------------------------------------------------------------*
*       FORM init_new_line                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM init_new_line.
  DATA : l_class_name(24) TYPE c VALUE 'CL_ABAP_CHAR_UTILITIES',
         l_attr_name(7)   TYPE c VALUE 'NEWLINE',
         l_class_ref(33)  TYPE c.
  FIELD-SYMBOLS: <attr> TYPE any.
  IF s_new_line IS INITIAL.
    CONCATENATE l_class_name '=>' l_attr_name INTO l_class_ref.
    ASSIGN (l_class_ref) TO <attr>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(17/12/24)
    IF sy-subrc <> 0.
*CL_ABAP_CHAR_UTILITIES=>NEWLINE doesn't exist (4.6c system)
      ASSIGN new_line TO <attr>.
    ENDIF.
    MOVE <attr> TO s_new_line.
  ENDIF.
ENDFORM.                    " init_new_line
*&---------------------------------------------------------------------*
*&      Form  add_functions
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_CONFDET  text
*      -->P_LT_FUNCTIONS  text
*----------------------------------------------------------------------*
FORM add_functions TABLES   it_confdet   STRUCTURE /psyng/confdet
                            it_functions STRUCTURE /psyng/function
                            it_functtran STRUCTURE /psyng/functtran
                            it_tcodes    STRUCTURE tstct
                   USING  if_tcodes.

  SORT it_functions BY function.
  LOOP AT it_confdet WHERE conid = gt_conflictfunctions-conid.
    gt_conflictfunctions-functionid = it_confdet-functionid.
*--Get function description
    READ TABLE it_functions WITH KEY function = it_confdet-functionid
    BINARY SEARCH TRANSPORTING description.
    IF sy-subrc = 0.
      gt_conflictfunctions-fdescription = it_functions-description.
    ELSE.
      CLEAR  gt_conflictfunctions-fdescription.
    ENDIF.
    IF if_tcodes = 'X'.
      LOOP AT it_functtran WHERE
      functionid = gt_conflictfunctions-functionid.
*        gt_conflictfunctions-tcode =   it_functtran-tcode.
*        READ TABLE it_tcodes WITH KEY tcode = it_functtran-tcode
*        BINARY SEARCH TRANSPORTING ttext.
*        IF sy-subrc = 0.
*          gt_conflictfunctions-ttext = it_tcodes-ttext.
*        ELSE.
*          CLEAR gt_conflictfunctions-ttext.
*        ENDIF.
        IF it_functtran-type = 'F'.
          gt_conflictfunctions-tcode = it_functtran-fioriid.
          PERFORM get_appname USING    it_functtran-fioriid
                         CHANGING gt_conflictfunctions-ttext.
        ELSEIF it_functtran-type = 'T'.
          READ TABLE it_tcodes WITH KEY tcode = it_functtran-tcode
           BINARY SEARCH TRANSPORTING ttext.
          gt_conflictfunctions-tcode =   it_functtran-tcode.
          gt_conflictfunctions-ttext = it_tcodes-ttext.
        ELSE.
          gt_conflictfunctions-tcode =   it_functtran-tcode.
          CLEAR gt_conflictfunctions-ttext.
        ENDIF.
        APPEND gt_conflictfunctions.
      ENDLOOP.
    ELSE.
      APPEND gt_conflictfunctions.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " add_functions



*---------------------------------------------------------------------*
*       FORM f4_system                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  FIELDNAME                                                     *
*  -->  E_VALUE                                                       *
*---------------------------------------------------------------------*
FORM f4_system USING    fieldname
                 CHANGING e_value.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.
  DATA: lt_fields    TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return    TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_sw_rfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE.

  SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_sw_rfcdes.
  LOOP AT lt_sw_rfcdes.
    lt_values-line = lt_sw_rfcdes-rfcdest.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-rfcname.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-description.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-systid.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-sys_type.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-sys_category.
    APPEND lt_values.
  ENDLOOP.

  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'RFCDEST'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'RFCNAME'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'DESCRIPTION'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYSTID'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYS_TYPE'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYS_CATEGORY'.
  APPEND lt_fields.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'SYSTID'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_value = lt_return-fieldval.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  org_variable_details
*&---------------------------------------------------------------------*
*       Display output with all Org and Variable Element details
*----------------------------------------------------------------------*
FORM org_variable_details.
  PERFORM load_functiondetails
    USING c_org_var_included.
  PERFORM format_and_output_alv
    USING c_org_var_included.

ENDFORM.                    " org_variable_details
*&---------------------------------------------------------------------*
*&      Form  f4_vrsio
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_P_SVRSIO  text
*----------------------------------------------------------------------*
FORM f4_vrsio CHANGING e_vrsio TYPE /psyng/sodvrsio.

  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF help_value,
        ls_fields TYPE help_value,
        lt_vrsio  TYPE TABLE OF /psyng/swsodvers,
        ls_vrsio  TYPE /psyng/swsodvers.

*--Get RFC destinations
  get_system p_system.
  CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
    DESTINATION gt_rfcdes-rfcdest
    EXPORTING
      if_vrsio = 'X'
    TABLES
      et_vrsio = lt_vrsio
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
  SORT lt_vrsio BY vrsio ASCENDING.

  ls_fields-tabname   = '/PSYNG/SWSODVERS'.
  ls_fields-fieldname = 'VRSIO'.
  ls_fields-selectflag = 'X'.
  APPEND ls_fields TO lt_fields.

  ls_fields-fieldname = 'VDESC'.
  ls_fields-selectflag = ' '.
  APPEND ls_fields TO lt_fields.

  LOOP AT lt_vrsio INTO ls_vrsio.
    ls_values-line = ls_vrsio-vrsio.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_vrsio-vdesc.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
    EXPORTING
      titel                     = text-t15
    IMPORTING
      select_value              = e_vrsio
    TABLES
      fields                    = lt_fields
      valuetab                  = lt_values
    EXCEPTIONS
      field_not_in_ddic         = 1
      more_then_one_selectfield = 2
      no_selectfield            = 3
      OTHERS                    = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                                                    " f4_vrsio
*&---------------------------------------------------------------------*
*&      Form  f4_conflicts
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_CONID_LOW  text
*----------------------------------------------------------------------*
FORM f4_conflicts CHANGING e_conid TYPE /psyng/conflict-conid.

  DATA: lt_values   TYPE TABLE OF ty_values,
        ls_values   TYPE ty_values,
        lt_fields   TYPE TABLE OF dfies,
        ls_fields   TYPE dfies,
        lt_return   TYPE TABLE OF ddshretval,
        ls_return   TYPE ddshretval,
        lt_conflict TYPE TABLE OF /psyng/conflict,
        ls_conflict TYPE /psyng/conflict,
        l_type      TYPE dd01v-datatype.

*--Get RFC destinations
  get_system p_system.
*
  ls_fields-tabname   = '/PSYNG/CONFLICT'.
  ls_fields-fieldname = 'CONID'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'VRSIO'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'DESCRIPTION'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'OWNER'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'IMP'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'BUSAREA'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'CONTID'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'INACTIVE'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'SUBAREA'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'RISK'.
  APPEND ls_fields TO lt_fields.

  CLEAR : gv_auth_check. "(++)UMITTAL 06/01/2026 PN17034

* Get values for popup
  CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
    DESTINATION gt_rfcdes-rfcdest
    EXPORTING
      if_conflict = 'X'
*--> BOC UMITTAL 06/01/2026 PN17034
    IMPORTING "Flag to check Auth failed or not inside
       e_auth_check = gv_auth_check

*<-- EOC UMITTAL 06/01/2026 PN17034
    TABLES
      et_conflict = lt_conflict
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

  IF gv_auth_check EQ space. "(++)UMITTAL 06/01/2026 PN17034

  LOOP AT lt_conflict INTO ls_conflict.
    ls_values-line = ls_conflict-vrsio.
    CALL FUNCTION 'NUMERIC_CHECK'
      EXPORTING
        string_in = ls_values-line
      IMPORTING
        htype     = l_type.
    IF l_type NE 'NUMC'.
      CONTINUE.
    ENDIF.
    WRITE ls_conflict-conid  TO ls_values-line.
    APPEND ls_values TO lt_values.
    WRITE ls_conflict-vrsio TO ls_values-line LEFT-JUSTIFIED.
    APPEND ls_values TO lt_values.
    WRITE ls_conflict-description TO ls_values-line.
    APPEND ls_values TO lt_values.
    WRITE ls_conflict-owner TO ls_values-line.
    APPEND ls_values TO lt_values.
    WRITE ls_conflict-imp  TO ls_values-line.
    APPEND ls_values TO lt_values.
    WRITE ls_conflict-busarea  TO ls_values-line.
    APPEND ls_values TO lt_values.
    WRITE ls_conflict-contid  TO ls_values-line.
    APPEND ls_values TO lt_values.
    WRITE ls_conflict-inactive TO ls_values-line.
    APPEND ls_values TO lt_values.
    WRITE ls_conflict-subarea  TO ls_values-line.
    APPEND ls_values TO lt_values.
    WRITE ls_conflict-risk TO ls_values-line.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield         = 'CONID'
*     value_org        = 'S'
      callback_program = g_program
      callback_form    = 'F4CALLBACK_CONID'
    TABLES
      value_tab        = lt_values
      field_tab        = lt_fields
      return_tab       = lt_return
    EXCEPTIONS
      parameter_error  = 1
      no_values_found  = 2
      OTHERS           = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_conid = ls_return-fieldval.

  ENDIF.

ENDFORM.                    " f4_conflicts
*&---------------------------------------------------------------------*
*&      Form  f4_function
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_FUNCT_LOW  text
*----------------------------------------------------------------------*
FORM f4_function CHANGING e_funid TYPE /psyng/function-function.

  DATA: lt_values   TYPE TABLE OF ty_values,
        ls_values   TYPE ty_values,
        lt_fields   TYPE TABLE OF dfies,
        ls_fields   TYPE dfies,
        lt_return   TYPE TABLE OF ddshretval,
        ls_return   TYPE ddshretval,
        lt_function TYPE TABLE OF /psyng/function,
        ls_function TYPE /psyng/function,
        l_type      TYPE dd01v-datatype.

*--Get RFC destinations
  get_system p_system.
*
  ls_fields-tabname   = '/PSYNG/FUNCTION'.
  ls_fields-fieldname = 'FUNCTION'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'VRSIO'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'DESCRIPTION'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'OWNER'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'BUSAREA'.
  APPEND ls_fields TO lt_fields.

  CLEAR : gv_auth_check."(++)UMITTAL 06/01/2026 PN17034
* Get values for popup
  CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
    DESTINATION gt_rfcdes-rfcdest
    EXPORTING
      if_function = 'X'
*<-- BOC UMITTAL 06/01/2026 PN17034
    IMPORTING
      e_auth_check = gv_auth_check
*<-- EOC UMITTAL 06/01/2026 PN17034
    TABLES
      et_function = lt_function
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

  IF gv_auth_check EQ space."(++)UMITTAL 06/01/2026 PN17034
  LOOP AT lt_function INTO ls_function.
    ls_values-line = ls_function-vrsio.
    CALL FUNCTION 'NUMERIC_CHECK'
      EXPORTING
        string_in = ls_values-line
      IMPORTING
        htype     = l_type.
    IF l_type NE 'NUMC'.
      CONTINUE.
    ENDIF.
    ls_values-line = ls_function-function.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_function-vrsio.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_function-description.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_function-owner.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_function-busarea.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield         = 'FUNCTION'
      callback_program = g_program
      callback_form    = 'F4CALLBACK_FUNCTION'
    TABLES
      value_tab        = lt_values
      field_tab        = lt_fields
      return_tab       = lt_return
    EXCEPTIONS
      parameter_error  = 1
      no_values_found  = 2
      OTHERS           = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_funid = ls_return-fieldval.

  ENDIF.
ENDFORM.                    " f4_function
*&---------------------------------------------------------------------*
*&      Form  f4_setid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--e_VAREL_VRSIO  text
*----------------------------------------------------------------------*
FORM f4_setid CHANGING e_setid
TYPE /psyng/swcfgset-setid.
  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF dfies,
        ls_fields TYPE dfies,
        lt_return TYPE TABLE OF ddshretval,
        ls_return TYPE ddshretval,
        lt_setid  TYPE TABLE OF /psyng/setid_f4,
        ls_setid  TYPE /psyng/setid_f4.

*--Get RFC destinations
  get_system p_system.
  DATA l_vrsio TYPE /psyng/vrsio.
  l_vrsio = p_vrsio.
*
  ls_fields-tabname   = '/PSYNG/SETID_F4'.
  ls_fields-fieldname = 'SETID'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'PUBLISHED'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'DESCRIPTION'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'VAREL_VRSIO'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'SYSTEM'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'SODVRSIO'.
  APPEND ls_fields TO lt_fields.

  CLEAR : gv_auth_check. "(++)UMITTAL 06/01/2026 PN17034
* Get values for popup
  CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
    DESTINATION gt_rfcdes-rfcdest
    EXPORTING
      if_setid = 'X'
*<-- BOC UMITTAL 06/01/2026 PN17034
    IMPORTING
      e_auth_check = gv_auth_check
*<-- EOC UMITTAL 06/01/2026 PN17034
    TABLES
      et_setid = lt_setid
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

  IF gv_auth_check EQ space."(++)UMITTAL 06/01/2026 PN17034

  SORT lt_setid DESCENDING BY setid.
**  DELETE lt_setid WHERE sodvrsio NE l_vrsio.

  LOOP AT lt_setid INTO ls_setid.
    ls_values-line = ls_setid-setid.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_setid-published.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_setid-description.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_setid-varel_vrsio.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_setid-system.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_setid-sodvrsio.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield         = 'SETID'
      callback_program = g_program
      callback_form    = 'F4CALLBACK_SETID'
    TABLES
      value_tab        = lt_values
      field_tab        = lt_fields
      return_tab       = lt_return
    EXCEPTIONS
      parameter_error  = 1
      no_values_found  = 2
      OTHERS           = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_setid = ls_return-fieldval.
  ENDIF.
ENDFORM.                                                    " f4_setid
*&---------------------------------------------------------------------*
*&      Form  f4_busarea
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_PAPPA_LOW  text
*----------------------------------------------------------------------*
FORM f4_busarea CHANGING e_busarea TYPE /psyng/busarea-busarea.

  DATA: lt_values  TYPE TABLE OF ty_values,
        ls_values  TYPE ty_values,
        lt_fields  TYPE TABLE OF dfies,
        ls_fields  TYPE dfies,
        lt_return  TYPE TABLE OF ddshretval,
        ls_return  TYPE ddshretval,
        lt_busarea TYPE TABLE OF /psyng/busarea,
        ls_busarea TYPE /psyng/busarea.

*--Get RFC destinations
  get_system p_system.
*
  ls_fields-tabname   = '/PSYNG/BUSAREA'.
  ls_fields-fieldname = 'BUSAREA'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'TEXT'.
  APPEND ls_fields TO lt_fields.

  CLEAR : gv_auth_check."(++)UMITTAL 06/01/2026 PN17034
* Get values for popup
  CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
    DESTINATION gt_rfcdes-rfcdest
    EXPORTING
      if_busarea = 'X'
*<-- BOC UMITTAL 06/01/2026 PN17034
    IMPORTING
      e_auth_check = gv_auth_check
*<-- EOC UMITTAL 06/01/2026 PN17034
    TABLES
      et_busarea = lt_busarea
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

  IF gv_auth_check EQ space."(++)UMITTAL 06/01/2026 PN17034

  LOOP AT lt_busarea INTO ls_busarea.
    ls_values-line = ls_busarea-busarea.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_busarea-text.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'BUSAREA'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_busarea = ls_return-fieldval.

  ENDIF.
ENDFORM.                    " f4_busarea
*&---------------------------------------------------------------------*
*&      Form  f4_risk
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--e_risk  text
*----------------------------------------------------------------------*
FORM f4_risk CHANGING e_risk TYPE /psyng/sw_risk-risk.

  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF dfies,
        ls_fields TYPE dfies,
        lt_return TYPE TABLE OF ddshretval,
        ls_return TYPE ddshretval,
        lt_risk   TYPE TABLE OF /psyng/sw_risk,
        ls_risk   TYPE /psyng/sw_risk.

*--Get RFC destinations
  get_system p_system.
*
  ls_fields-tabname   = '/PSYNG/SW_RISK'.
  ls_fields-fieldname = 'RISK'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'TEXT'.
  APPEND ls_fields TO lt_fields.

  CLEAR : gv_auth_check."(++)UMITTAL 06/01/2026 PN17034
* Get values for popup
  CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
    DESTINATION gt_rfcdes-rfcdest
    EXPORTING
      if_risk = 'X'
*<-- BOC UMITTAL 06/01/2026 PN17034
    IMPORTING
      e_auth_check = gv_auth_check
*<-- EOC UMITTAL 06/01/2026 PN17034
    TABLES
      et_risk = lt_risk
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

  IF gv_auth_check EQ space."(++)UMITTAL 06/01/2026 PN17034
  LOOP AT lt_risk INTO ls_risk.
    ls_values-line = ls_risk-risk.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_risk-text.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'RISK'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_risk = ls_return-fieldval.

  ENDIF.
ENDFORM.                                                    " f4_risk
*&---------------------------------------------------------------------*
*&      Form  f4_contid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--e_risk  text
*----------------------------------------------------------------------*
FORM f4_contid CHANGING e_contid TYPE /psyng/mchdr-contid.

  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF dfies,
        ls_fields TYPE dfies,
        lt_return TYPE TABLE OF ddshretval,
        ls_return TYPE ddshretval,
        lt_mchdr  TYPE TABLE OF /psyng/mchdr,
        ls_mchdr  TYPE /psyng/mchdr.
*--Get RFC destinations
  get_system p_system.
*
  ls_fields-tabname   = '/PSYNG/MCHDR'.
  ls_fields-fieldname = 'CONTID'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'DESCRIPTION'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'APPROVER'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'TYPE'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'INACTIVE'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'JUST_REQ'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'ATTACH_REQ'.
  APPEND ls_fields TO lt_fields.

  CLEAR : gv_auth_check."(++)UMITTAL 06/01/2026 PN17034
* Get values for popup
  CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
    DESTINATION gt_rfcdes-rfcdest
    EXPORTING
      if_mchdr = 'X'
*<-- BOC UMITTAL 06/01/2026 PN17034
    IMPORTING
      e_auth_check = gv_auth_check
*<-- EOC UMITTAL 06/01/2026 PN17034
    TABLES
      et_mchdr = lt_mchdr
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

  IF gv_auth_check EQ space."(++)UMITTAL 06/01/2026 PN17034

  LOOP AT lt_mchdr INTO ls_mchdr.
    ls_values-line = ls_mchdr-contid.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_mchdr-description.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_mchdr-approver.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_mchdr-type.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_mchdr-inactive.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_mchdr-just_req.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_mchdr-attach_req.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CONTID'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_contid = ls_return-fieldval.
  ENDIF.
ENDFORM.                                                    " f4_risk

*---------------------------------------------------------------------*
*       FORM f4callback_setid                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  RECORD_TAB                                                    *
*  -->  SHLP                                                          *
*  -->  CALLCONTROL                                                   *
*---------------------------------------------------------------------*
FORM f4callback_setid
TABLES record_tab STRUCTURE seahlpres
CHANGING shlp TYPE shlp_descr_t
callcontrol LIKE ddshf4ctrl.

  DATA: ls_filter TYPE ddshselopt.

  MOVE: '/PSYNG/SETID_F4' TO ls_filter-shlpname,
    'SODVRSIO' TO ls_filter-shlpfield,
    'I'     TO ls_filter-sign,
    'EQ'    TO ls_filter-option,
    p_vrsio TO ls_filter-low.
  APPEND ls_filter TO shlp-selopt.

ENDFORM.                                                    "F4_form

*---------------------------------------------------------------------*
*       FORM f4callback_conid                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  RECORD_TAB                                                    *
*  -->  SHLP                                                          *
*  -->  CALLCONTROL                                                   *
*---------------------------------------------------------------------*
FORM f4callback_conid
TABLES record_tab STRUCTURE seahlpres
CHANGING shlp TYPE shlp_descr_t
callcontrol LIKE ddshf4ctrl.

  DATA: ls_filter TYPE ddshselopt.

  MOVE: '/PSYNG/CONFLICT' TO ls_filter-shlpname,
    'VRSIO' TO ls_filter-shlpfield,
    'I'     TO ls_filter-sign,
    'EQ'    TO ls_filter-option,
    p_vrsio TO ls_filter-low.
  APPEND ls_filter TO shlp-selopt.

ENDFORM.                                                    "F4_form

*---------------------------------------------------------------------*
*       FORM f4callback_function                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  RECORD_TAB                                                    *
*  -->  SHLP                                                          *
*  -->  CALLCONTROL                                                   *
*---------------------------------------------------------------------*
FORM f4callback_function
TABLES record_tab STRUCTURE seahlpres
CHANGING shlp TYPE shlp_descr_t
callcontrol LIKE ddshf4ctrl.

  DATA: ls_filter TYPE ddshselopt.

  MOVE: '/PSYNG/FUNCTION' TO ls_filter-shlpname,
    'VRSIO' TO ls_filter-shlpfield,
    'I'     TO ls_filter-sign,
    'EQ'    TO ls_filter-option,
    p_vrsio TO ls_filter-low.
  APPEND ls_filter TO shlp-selopt.

ENDFORM.                                                    "F4_form
