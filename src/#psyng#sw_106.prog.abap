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

REPORT /psyng/sw_106 LINE-SIZE 255.


***Type pools Declaration.

TYPE-POOLS: slis.                                      "For ALV call

*Global Declarations for alv

DATA: g_program         LIKE sy-repid.                 "For ALV call

DATA: g_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call

DATA: g_sort TYPE STANDARD TABLE OF slis_sortinfo_alv.




*****Global Table for Critical Authorization Header
DATA: gt_caheader TYPE SORTED TABLE OF /psyng/swaudhdr WITH UNIQUE KEY
              swaudid
              WITH HEADER LINE.

*****Global Table for Critical Authorization Details
DATA: gt_cadetails TYPE SORTED TABLE OF /psyng/swaudc2 WITH UNIQUE KEY
              swaudid tcode object valueset field val_from val_to
              WITH HEADER LINE.

*****Global Table for T-Code Names
DATA: gt_tcodes TYPE SORTED TABLE OF tstct WITH UNIQUE KEY
              tcode
              WITH HEADER LINE.


********************************************


***Declaration for Final output internal table

DATA: BEGIN OF gt_output OCCURS 0,
l_critauthid      LIKE /psyng/swaudhdr-swaudid,
l_cadesc         LIKE /psyng/swaudhdr-description,
l_catcode        LIKE /psyng/swaudc2-tcode,
l_tcodetext      LIKE tstct-ttext,
l_imp            LIKE /psyng/swaudhdr-imp,
l_owner          LIKE /psyng/swaudhdr-owner,
l_caobject       LIKE /psyng/swaudc2-object,
l_valueset       LIKE /psyng/swaudc2-valueset,
l_field          LIKE /psyng/swaudc2-field,
l_val_from       LIKE /psyng/swaudc2-val_from,
l_val_to         LIKE /psyng/swaudc2-val_to,
       END OF gt_output.

**********************************************

*Option for answer whether  Output IN  ALV OR Stndard format
*DATA: g_answer.


**SELECTION-SCREEN DETAILS

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.

PARAMETERS: p_vrsio LIKE /psyng/swaudhdr-vrsio.

SELECTION-SCREEN END OF BLOCK blk1.

INITIALIZATION.
  PERFORM exelog.

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
*Popup display for selecting  Output IN  ALV OR Stndard format
*  CALL FUNCTION 'POPUP_TO_DECIDE'
*       EXPORTING
*            textline1    = text-000
*            text_option1 = text-001  "ALV output
*            text_option2 = text-002  "Standard output
*            titel        = text-003
*       IMPORTING
*            answer       = g_answer.
*
*  CHECK g_answer NE 'A'.


  REFRESH:gt_caheader,gt_cadetails.
  CLEAR:gt_caheader,gt_cadetails.


***Fetching required data into global tables


  SELECT * FROM /psyng/swaudhdr INTO TABLE gt_caheader
         WHERE vrsio = p_vrsio.

  SELECT * FROM /psyng/swaudc2 INTO TABLE gt_cadetails
         WHERE vrsio = p_vrsio.

  SELECT * FROM tstct INTO TABLE gt_tcodes
         WHERE sprsl = sy-langu.

*  IF g_answer = '1'." for ALV output

  PERFORM format_and_output_alv.

**************************************
*  ELSEIF g_answer = '2'." for Standard output
*
****************************************
*    PERFORM format_stand_output.
*  ENDIF.


*TOP-OF-PAGE.
*
***Printing filed names in output for standard output
*
*  WRITE:/ text-021, 10 sy-datum.
*
*  ULINE.
*  WRITE:/ text-007, 10 text-008, 50 text-011,
*        70 text-023, 90 text-025,
*        100 text-027, 110 text-031, 120 text-032.




*&---------------------------------------------------------------------*
*&      Form  BUILD_ALV_STUFF
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_stuff.

  DATA: l_wa_fieldcat_alv TYPE slis_fieldcat_alv,
         l_sort            TYPE slis_sortinfo_alv.



  l_wa_fieldcat_alv-seltext_l = 'CA ID'(007).
  l_wa_fieldcat_alv-seltext_m = 'CA ID'(007).
  l_wa_fieldcat_alv-seltext_s = 'CA ID'(007).
  l_wa_fieldcat_alv-reptext_ddic = 'CA ID'(007).
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_CRITAUTHID'.




  l_wa_fieldcat_alv-seltext_l = 'Description'(008).
  l_wa_fieldcat_alv-seltext_m = 'Description'(008).
  l_wa_fieldcat_alv-seltext_s = 'Description'(008).
  l_wa_fieldcat_alv-reptext_ddic = 'Description'(008).
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_CADESC'.


  l_wa_fieldcat_alv-seltext_l = 'TCode'(011).
  l_wa_fieldcat_alv-seltext_m = 'TCode'(011).
  l_wa_fieldcat_alv-seltext_s = 'TCode'(011).
  l_wa_fieldcat_alv-reptext_ddic = 'TCode'(011).
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_CATCODE'.


  l_wa_fieldcat_alv-seltext_l = 'TCode Name'(012).
  l_wa_fieldcat_alv-seltext_m = 'TCode Name'(012).
  l_wa_fieldcat_alv-seltext_s = 'TCode Name'(012).
  l_wa_fieldcat_alv-reptext_ddic = 'TCode Name'(012).
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_TCODETEXT'.


  l_wa_fieldcat_alv-seltext_l = 'Object'(023).
  l_wa_fieldcat_alv-seltext_m = 'Object'(023).
  l_wa_fieldcat_alv-seltext_s = 'Object'(023).
  l_wa_fieldcat_alv-reptext_ddic = 'Object'(023).
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_CAOBJECT'.



  l_wa_fieldcat_alv-seltext_l = 'ValueSet'(025).
  l_wa_fieldcat_alv-seltext_m = 'ValueSet'(025).
  l_wa_fieldcat_alv-seltext_s = 'ValueSet'(025).
  l_wa_fieldcat_alv-reptext_ddic = 'ValueSet'(025).
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_VALUESET'.



  l_wa_fieldcat_alv-seltext_l = 'Field'(027).
  l_wa_fieldcat_alv-seltext_m = 'Field'(027).
  l_wa_fieldcat_alv-seltext_s = 'Field'(027).
  l_wa_fieldcat_alv-reptext_ddic = 'Field'(027).
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_FIELD'.



  l_wa_fieldcat_alv-seltext_l = 'From'(031).
  l_wa_fieldcat_alv-seltext_m = 'From'(031).
  l_wa_fieldcat_alv-seltext_s = 'From'(031).
  l_wa_fieldcat_alv-reptext_ddic = 'From'(031).
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_VAL_FROM'.



  l_wa_fieldcat_alv-seltext_l = 'To'(032).
  l_wa_fieldcat_alv-seltext_m = 'To'(032).
  l_wa_fieldcat_alv-seltext_s = 'To'(032).
  l_wa_fieldcat_alv-reptext_ddic = 'To'(032).
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_VAL_TO'.

  l_wa_fieldcat_alv-seltext_l = 'Sensitivity Level'(034).
  l_wa_fieldcat_alv-seltext_m = 'Sensitivity Level'(034).
  l_wa_fieldcat_alv-seltext_s = 'Sensitivity Level'(034).
  l_wa_fieldcat_alv-reptext_ddic = 'Sensitivity Level'(034).
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_IMP'.


  l_wa_fieldcat_alv-seltext_l = 'Owner UID'(033).
  l_wa_fieldcat_alv-seltext_m = 'Owner UID'(033).
  l_wa_fieldcat_alv-seltext_s = 'Owner UID'(033).
  l_wa_fieldcat_alv-reptext_ddic = 'Owner UID'(033).
  MODIFY g_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'L_OWNER'.



  CLEAR: l_sort, g_sort.
  REFRESH: g_sort.

  l_sort-spos = '1'.
  l_sort-fieldname = 'L_CRITAUTHID'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'L_CADESC'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'L_CATCODE'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '4'.
  l_sort-fieldname = 'L_TCODETEXT'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '5'.
  l_sort-fieldname = 'L_OWNER'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.


  l_sort-spos = '6'.
  l_sort-fieldname = 'L_IMP'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.


  l_sort-spos = '7'.
  l_sort-fieldname = 'L_CAOBJECT'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '8'.
  l_sort-fieldname = 'L_VALUESET'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '9'.
  l_sort-fieldname = 'L_FIELD'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '10'.
  l_sort-fieldname = 'L_VAL_FROM'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.

  l_sort-spos = '11'.
  l_sort-fieldname = 'L_VAL_TO'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO g_sort.



ENDFORM.                    " BUILD_ALV_STUFF
*&---------------------------------------------------------------------*
*&      Form  format_and_output_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM format_and_output_alv.

****Local stracture for final output

  TYPES: BEGIN OF ls_output_typ,
            l_critauthid      LIKE /psyng/swaudhdr-swaudid,
            l_cadesc          LIKE /psyng/swaudhdr-description,
            l_catcode         LIKE /psyng/swaudc2-tcode,
            l_tcodetext       LIKE tstct-ttext,
            l_imp             LIKE /psyng/swaudhdr-imp,
            l_owner           LIKE /psyng/swaudhdr-owner,
            l_caobject        LIKE /psyng/swaudc2-object,
            l_valueset        LIKE /psyng/swaudc2-valueset,
            l_field           LIKE /psyng/swaudc2-field,
            l_val_from        LIKE /psyng/swaudc2-val_from,
            l_val_to          LIKE /psyng/swaudc2-val_to,
           END OF ls_output_typ.


  DATA: l_alv_layout    TYPE slis_layout_alv,
        l_alv_grid_titl TYPE lvc_title,
        ls_variant    TYPE disvariant,
        l_date(10),
        l_wa_output     TYPE ls_output_typ,
        lt_output     TYPE SORTED TABLE OF ls_output_typ WITH UNIQUE KEY
                          l_critauthid l_cadesc l_catcode l_caobject
                          l_valueset l_field l_val_from l_val_to
                      WITH HEADER LINE.

************************************************************************
*  LOOP AT gt_confdet.
*    READ TABLE gt_conflict WITH KEY conid = gt_confdet-conid.
*    LOOP AT gt_functtran WHERE functionid = gt_confdet-functionid.
*    READ TABLE gt_function WITH KEY function = gt_functtran-functionid.
*      READ TABLE gt_tstct WITH KEY tcode = gt_functtran-tcode.


  LOOP AT gt_caheader. "Loop through CA Header

    "Loop through CA details

    LOOP AT gt_cadetails WHERE swaudid = gt_caheader-swaudid.

      l_wa_output-l_critauthid = gt_caheader-swaudid.
      l_wa_output-l_cadesc = gt_caheader-description.
      l_wa_output-l_catcode = gt_caheader-tcode.
      l_wa_output-l_owner   = gt_caheader-owner.
      l_wa_output-l_imp     = gt_caheader-imp.
      l_wa_output-l_caobject = gt_cadetails-object.
      l_wa_output-l_valueset = gt_cadetails-valueset.
      l_wa_output-l_field = gt_cadetails-field.
      l_wa_output-l_val_from = gt_cadetails-val_from.
      l_wa_output-l_val_to = gt_cadetails-val_to.


************************************************************

      PERFORM get_tcode_text USING gt_caheader-tcode
      CHANGING l_wa_output-l_tcodetext.


************************************************************
      INSERT l_wa_output INTO TABLE lt_output.

      CLEAR l_wa_output.

    ENDLOOP. "Loop through CA Details


*   CA without object still needs to be added:

    IF sy-subrc NE 0.

      l_wa_output-l_critauthid = gt_caheader-swaudid.
      l_wa_output-l_cadesc = gt_caheader-description.
      l_wa_output-l_owner  = gt_caheader-owner.
      l_wa_output-l_imp    = gt_caheader-imp.
      l_wa_output-l_catcode = gt_caheader-tcode.

      PERFORM get_tcode_text USING gt_caheader-tcode
       CHANGING l_wa_output-l_tcodetext.

      INSERT l_wa_output INTO TABLE lt_output.
      CLEAR l_wa_output.

    ENDIF.


  ENDLOOP. " Loop through CA Header



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

  CONCATENATE text-020 p_vrsio text-022 l_date
                INTO l_alv_grid_titl SEPARATED BY space.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title           = l_alv_grid_titl
            i_callback_program     = g_program
            i_callback_top_of_page = 'ALV_HEADER'
            it_sort                = g_sort
            is_layout              = l_alv_layout
            it_fieldcat            = g_fieldcat_alv
            i_save                 = 'A'
            is_variant             = ls_variant
       TABLES
            t_outtab               = gt_output
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



*&---------------------------------------------------------------------*
*&      Form  format_stand_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*FORM format_stand_output.
*
*   LOOP AT gt_cadetails.
*
*    AT NEW swaudid.
*      ULINE.
*    ENDAT.
*
*      WRITE:/ gt_cadetails-swaudid.
*      READ TABLE gt_caheader WITH KEY swaudid = gt_cadetails-swaudid
*                                            BINARY SEARCH.
*      IF sy-subrc = 0.
*        WRITE: 10 gt_caheader-description.
*      ENDIF.
*
*        WRITE:50  gt_cadetails-tcode.
*        WRITE:70  gt_cadetails-object.
*        WRITE:90  gt_cadetails-valueset.
*        WRITE:100 gt_cadetails-field.
*        WRITE:110 gt_cadetails-val_from.
*        WRITE:120 gt_cadetails-val_to.
*
*ENDLOOP.
*
*****************************************************************
*ENDFORM.                    " format_stand_output


*&---------------------------------------------------------------------*
*&      Form  GET_TCODE_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_L_WA_OUTPUT_L_TCODETEXT  text
*      -->P_GT_CAHEADER_TCODE  text
*----------------------------------------------------------------------*
FORM get_tcode_text  USING    i_tcode CHANGING e_text..

  READ TABLE gt_tcodes WITH KEY tcode = i_tcode.

  e_text = gt_tcodes-ttext.

* Display "All T-Codes" if the CA T-Code is *

  IF i_tcode EQ '*'.
    e_text = text-013.
  ENDIF.

* Display "No T-Code text available" if the
* T-Code description is empty

  IF e_text EQ ''.
    e_text = text-006.
  ENDIF.

* TODO: "Performance Optimization" - not read if T-Code * or does not
* exist


ENDFORM.                    " GET_TCODE_TEXT

*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: ls_header TYPE slis_t_listheader,
        ls_slis_listheader TYPE slis_listheader,
        alv_grid_titl2   TYPE lvc_title,
        l_date(12) TYPE c.
  .
  ls_slis_listheader-typ = 'H'.
  ls_slis_listheader-info =
            ' Critical Authorizations in Security Weaver'(h01).
  APPEND ls_slis_listheader TO ls_header.
*SOD Version.
  ls_slis_listheader-typ = 'S'.
  ls_slis_listheader-key = 'Sod Version'(h02).
  SELECT SINGLE vdesc INTO ls_slis_listheader-info FROM /psyng/swsodvers
                              WHERE vrsio = p_vrsio.
  CONCATENATE p_vrsio ' : '  ls_slis_listheader-info
                  INTO ls_slis_listheader-info SEPARATED BY space.
  APPEND ls_slis_listheader TO ls_header.
*Date
  ls_slis_listheader-typ = 'S'.
  ls_slis_listheader-key = 'Date'(h03).
  WRITE sy-datum TO l_date.
  ls_slis_listheader-info = l_date.
  APPEND ls_slis_listheader TO ls_header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = ls_header.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE,
        l_current_user TYPE sy-uname. "C0700
* BOC by RGUPTA on 05.04.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 05.04.22 for C0700

  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = l_current_user. "sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.

  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = exelog.
  COMMIT WORK.


ENDFORM.                    " exelog
