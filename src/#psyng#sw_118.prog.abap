*----------------------------------------------------------------------*
* Report  /PSYNG/SW_118                                                *
* AUTHOR: Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
REPORT /psyng/sw_118.

TABLES: /psyng/criprof.

TYPE-POOLS: slis.

PARAMETERS : sodvrsio LIKE /psyng/criprof-vrsio.

DATA: gs_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call

DATA: BEGIN OF GT_OUTPUT OCCURS 0,
        profile   LIKE /psyng/criprof-profile,
        prof_text  LIKE agr_texts-text,
*        vrsio      LIKE /psyng/criprof-vrsio,
        imp        LIKE /psyng/criprof-imp,
        owner      LIKE /psyng/criprof-owner,
        END OF gt_output.

DATA: gt_criprofs TYPE STANDARD TABLE OF /psyng/criprof
      WITH HEADER LINE.

DATA: gt_usr11 TYPE STANDARD TABLE OF usr11 WITH HEADER LINE.


**------------------------ START-OF-SELECTION
*--------------------------*
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
  SELECT profile owner imp  FROM /psyng/criprof
           INTO CORRESPONDING FIELDS OF TABLE gt_criprofs
           WHERE vrsio = sodvrsio.

  SORT gt_criprofs BY profile.

  IF NOT gt_criprofs[] IS INITIAL.

    SELECT * FROM usr11 INTO TABLE gt_usr11
              FOR ALL ENTRIES IN gt_criprofs
                WHERE profn = gt_criprofs-profile.

  ENDIF.


  LOOP AT gt_criprofs.

    gt_output-profile = gt_criprofs-profile.

* fill profile text
    READ TABLE gt_usr11 WITH KEY profn = gt_criprofs-profile
                                 langu = sy-langu.
    IF sy-subrc EQ 0.

      gt_output-prof_text = gt_usr11-ptext.

    ELSE.

      gt_output-prof_text = 'Profile for Cross System Analysis'(009).

    ENDIF.

    CLEAR gt_usr11-ptext.
*    gt_output-vrsio = gt_criprofs-vrsio.
    gt_output-owner = gt_criprofs-owner.
    gt_output-imp   = gt_criprofs-imp.


    APPEND gt_output.

  ENDLOOP.

  SORT gt_output.
  DELETE ADJACENT DUPLICATES FROM gt_output.

**------------------------- END-OF-SELECTION --------------------------*
END-OF-SELECTION.
  PERFORM alv_output.

*---------------------------------------------------------------------*
*       FORM alv_output                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_output.
  DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
  DATA: l_sort TYPE slis_sortinfo_alv,
        ls_variant    TYPE disvariant,
        alv_layout    TYPE slis_layout_alv,
        alv_grid_titl TYPE lvc_title,
        program       LIKE sy-repid.


  program = sy-repid.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = program
            i_internal_tabname = 'GT_OUTPUT'
            i_inclname         = program
       CHANGING
            ct_fieldcat        = gs_fieldcat_alv
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

  MOVE text-004 TO alv_grid_titl.

  l_sort-spos = '1'.
  l_sort-fieldname = 'PROFILE'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'PROF_TEXT'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'OWNER'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

*  l_sort-spos = '4'.
*  l_sort-fieldname = 'VRSIO'.
*  l_sort-tabname = 'GT_OUTPUT'.
*  l_sort-up = 'X'.
*  APPEND l_sort TO isort.


  l_sort-spos = '5'.
  l_sort-fieldname = 'IMP'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  PERFORM change_catalog_info.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title       = alv_grid_titl
            i_callback_program = program
            it_sort            = isort
            is_layout          = alv_layout
            it_fieldcat        = gs_fieldcat_alv
            i_save             = 'A'
            is_variant         = ls_variant
       TABLES
            t_outtab           = GT_OUTPUT
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " alv_output
*&---------------------------------------------------------------------
*
*&      Form  change_catalog_info
*&---------------------------------------------------------------------
*
FORM change_catalog_info.

  DATA: ls_fieldcat_alv TYPE slis_fieldcat_alv.

  ls_fieldcat_alv-seltext_l = 'Profile'(008).
  ls_fieldcat_alv-seltext_m = 'Profile'(008).
  ls_fieldcat_alv-seltext_s = 'Profile'(008).
  ls_fieldcat_alv-reptext_ddic = 'Profile'(008).
  MODIFY gs_fieldcat_alv FROM ls_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'PROFILE'.

  ls_fieldcat_alv-seltext_l = 'Profile Description'(001).
  ls_fieldcat_alv-seltext_m = 'Profile Description'(001).
  ls_fieldcat_alv-seltext_s = 'Profile Description'(001).
  ls_fieldcat_alv-reptext_ddic = 'Profile Description'(001).
  MODIFY gs_fieldcat_alv FROM ls_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'PROF_TEXT'.

  ls_fieldcat_alv-seltext_l = 'Owner UID'(003).
  ls_fieldcat_alv-seltext_m = 'Owner UID'(003).
  ls_fieldcat_alv-seltext_s = 'Owner UID'(003).
  ls_fieldcat_alv-reptext_ddic = 'Owner UID'(003).
  MODIFY gs_fieldcat_alv FROM ls_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'OWNER'.

  ls_fieldcat_alv-seltext_l = 'Sensitivity Level'(002).
  ls_fieldcat_alv-seltext_m = 'Sensitivity Level'(002).
  ls_fieldcat_alv-seltext_s = 'Sensitivity Level'(002).
  ls_fieldcat_alv-reptext_ddic = 'Sensitivity Level'(002).
  MODIFY gs_fieldcat_alv FROM ls_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'IMP'.


ENDFORM.                    " change_catalog_info
