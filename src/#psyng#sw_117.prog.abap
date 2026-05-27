*----------------------------------------------------------------------*
* Report  /PSYNG/SW_117                                                *
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
REPORT /psyng/sw_117.

TABLES: /psyng/criroles.

TYPE-POOLS: slis.

PARAMETERS : sodvrsio LIKE /psyng/criroles-vrsio.

DATA: gs_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call

DATA: BEGIN OF GT_OUTPUT OCCURS 0,
        agr_name   LIKE /psyng/criroles-agr_name,
        role_text  LIKE agr_texts-text,
*        vrsio      LIKE /psyng/criroles-vrsio,
        imp        LIKE /psyng/criroles-imp,
        owner      LIKE /psyng/criroles-owner,
        END OF GT_OUTPUT.

DATA: gt_criroles TYPE STANDARD TABLE OF /psyng/criroles
      WITH HEADER LINE.

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
  SELECT agr_name owner imp  FROM /psyng/criroles
           INTO CORRESPONDING FIELDS OF TABLE gt_criroles
           WHERE vrsio = sodvrsio.

  SORT gt_criroles BY agr_name.

  LOOP AT gt_criroles.

    GT_OUTPUT-agr_name = gt_criroles-agr_name.

***    fill role text

    PERFORM get_role_text USING gt_criroles-agr_name
                          CHANGING GT_OUTPUT-role_text.

*    GT_OUTPUT-vrsio = gt_criroles-vrsio.
    GT_OUTPUT-owner = gt_criroles-owner.
    GT_OUTPUT-imp   = gt_criroles-imp.


    APPEND GT_OUTPUT.

  ENDLOOP.

  SORT GT_OUTPUT.
  DELETE ADJACENT DUPLICATES FROM GT_OUTPUT.

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
  l_sort-fieldname = 'AGR_NAME'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'ROLE_TEXT'.
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


  l_sort-spos = '4'.
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

  ls_fieldcat_alv-seltext_l = 'Role Name'(008).
  ls_fieldcat_alv-seltext_m = 'Role Name'(008).
  ls_fieldcat_alv-seltext_s = 'Role Name'(008).
  ls_fieldcat_alv-reptext_ddic = 'Role Name'(008).
  MODIFY gs_fieldcat_alv FROM ls_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'AGR_NAME'.

  ls_fieldcat_alv-seltext_l = 'Role Description'(001).
  ls_fieldcat_alv-seltext_m = 'Role Description'(001).
  ls_fieldcat_alv-seltext_s = 'Role Description'(001).
  ls_fieldcat_alv-reptext_ddic = 'Role Description'(001).
  MODIFY gs_fieldcat_alv FROM ls_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ROLE_TEXT'.

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


*&---------------------------------------------------------------------*
*&      Form  get_role_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_USER_ROLE_APP_APPLICATION  text
*      -->P_GT_USER_ROLE_APP_INSTANCE  text
*      -->P_GT_USER_ROLE_APP_ROLENAME  text
*      <--P_GT_ROLE_USERNAME_ROLE_TEXT  text
*----------------------------------------------------------------------*
FORM get_role_text USING    rolename
                   CHANGING role_text.

  DATA : lt_texts TYPE TABLE OF agr_texts WITH HEADER LINE,
     lt_agr(30).

  lt_agr =  rolename.

  CALL FUNCTION 'PRGN_RFC_READ_TEXTS' "#EC SAST_CI_GEN_CHECK (HBHALLA)
       EXPORTING
            activity_group                = lt_agr
       TABLES
            texts                         = lt_texts
       EXCEPTIONS
            activity_group_does_not_exist = 1
            not_authorized                = 2
            OTHERS                        = 3.
  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_texts WITH KEY agr_name = rolename
                               spras = sy-langu
                                 line = '00000'.
  IF sy-subrc = 0.
    role_text = lt_texts-text.
  ELSE.
    role_text = 'Role for Cross System Analysis'(006).
  ENDIF.
  CLEAR lt_texts-text.

ENDFORM.                    " get_role_text
