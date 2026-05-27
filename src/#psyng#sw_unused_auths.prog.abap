*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_UNUSED_AUTHS
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
REPORT /psyng/sw_unused_auths .
TABLES : ust12.
TYPE-POOLS: slis. "Define Type-Pool

TYPES: BEGIN OF typ_ust12,
        objct LIKE ust12-objct,
        auth LIKE ust12-auth,
      END OF typ_ust12.
DATA gt_ust12 TYPE TABLE OF typ_ust12 WITH HEADER LINE.
DATA: gv_wa_ust12 TYPE typ_ust12.
DATA: gt_output TYPE STANDARD TABLE OF typ_ust12 INITIAL SIZE 0 WITH
HEADER LINE .

DATA gv_l TYPE i.

TYPES: BEGIN OF typ_ust10s,
        objct LIKE ust10s-objct,
        auth LIKE ust10s-auth,
      END OF typ_ust10s.
DATA: gwa_ust10s TYPE typ_ust10s.
DATA : gt_ust10s TYPE TABLE OF typ_ust10s WITH HEADER LINE.
*DATA: iust10s TYPE SORTED TABLE OF typ_ust10s WITH UNIQUE KEY
*            objct auth
*            WITH HEADER LINE.
DATA: g_indx LIKE sy-tabix.

DATA: gv_alv_fieldcat TYPE slis_t_fieldcat_alv,  "Field Catalog
      l_sort TYPE slis_t_sortinfo_alv.

************************************************************************
*********              SELECTION SCREEN                      ***********
************************************************************************

SELECTION-SCREEN  BEGIN OF BLOCK b1 WITH FRAME TITLE text-003.
SELECT-OPTIONS: s_objct FOR ust12-objct.
SELECTION-SCREEN SKIP .
SELECT-OPTIONS: s_auth  FOR ust12-auth.
SELECTION-SCREEN END OF BLOCK b1 .

************************************************************************
**               START OF SELECTION                                   **
************************************************************************
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
  PERFORM get_data.
  PERFORM fill_fieldcat.
  PERFORM output.

*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_data.
  SELECT DISTINCT objct auth
         FROM ust12
         INTO CORRESPONDING FIELDS OF TABLE gt_ust12
         WHERE objct IN s_objct
         AND auth IN s_auth.

  IF sy-subrc = 0.

    SELECT DISTINCT objct auth
           FROM ust10s
           INTO CORRESPONDING FIELDS OF TABLE gt_ust10s
           WHERE objct IN s_objct
           AND auth IN s_auth.

    SORT gt_ust10s BY objct auth.
    LOOP AT gt_ust12.
      READ TABLE gt_ust10s WITH KEY objct = gt_ust12-objct
                                  auth = gt_ust12-auth
                                  BINARY SEARCH
                                  TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        gt_output-objct = gt_ust12-objct.
        gt_output-auth = gt_ust12-auth.
        APPEND gt_output.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF gt_output[] IS INITIAL.
    MESSAGE s174(/psyng/sw).
    LEAVE LIST-PROCESSING.
  ENDIF.


ENDFORM.                    " GET_DATA
*&---------------------------------------------------------------------*
*&      Form  FILL_fieldcat
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_fieldcat.

 DATA: w_fieldcat TYPE slis_fieldcat_alv.        "Field Catalog Workarea
  DATA: w_sort TYPE slis_sortinfo_alv.

  REFRESH : gv_alv_fieldcat,l_sort.

  w_fieldcat-fieldname = 'OBJCT'.
  w_fieldcat-tabname   = 'GT_OUTPUT'.
  w_fieldcat-seltext_l = text-001.
  w_fieldcat-key = 'X'.
  w_fieldcat-hotspot = 'X'.
  w_fieldcat-col_pos = 1.
  APPEND w_fieldcat TO gv_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'AUTH'.
  w_fieldcat-tabname   = 'GT_OUTPUT'.
  w_fieldcat-seltext_l = text-002.
  w_fieldcat-col_pos = 2.
  APPEND w_fieldcat TO gv_alv_fieldcat.
  CLEAR w_fieldcat.


  w_sort-spos = '1'.
  w_sort-fieldname = 'OBJCT'.
  w_sort-tabname = 'GT_OUTPUT'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

ENDFORM.                    " FILL_fieldcat
*&---------------------------------------------------------------------*
*&      Form  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM output.

  DATA: ls_variant TYPE disvariant.
  DATA: program         LIKE sy-repid,
        alv_layout      TYPE slis_layout_alv.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program      = program
            i_callback_user_command = 'USER_DOUBLE_CLICK'
            is_layout               = alv_layout
            it_fieldcat             = gv_alv_fieldcat
            it_sort                 = l_sort
            i_save                  = 'A'
            is_variant              = ls_variant
       TABLES
            t_outtab                = gt_output[]
       EXCEPTIONS
            program_error           = 1
            OTHERS                  = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.


ENDFORM.                    " OUTPUT

*---------------------------------------------------------------------*
*       FORM user_double_click                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM user_double_click  USING r_ucomm LIKE sy-ucomm
                                 rs_selfield TYPE slis_selfield.
  DATA: iobjct    LIKE tobj-objct.
  CASE r_ucomm.
    WHEN '&IC1'.
      CHECK rs_selfield-fieldname = 'OBJCT'.
      CHECK rs_selfield-value <> space.
      READ TABLE gt_output INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.
      iobjct = rs_selfield-value.
      CALL FUNCTION 'SUSR_SHOW_OBJECT'
           EXPORTING
                object  = iobjct
                eu_mode = ' '.
  ENDCASE.

ENDFORM.
