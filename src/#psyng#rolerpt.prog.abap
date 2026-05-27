REPORT /PSYNG/ROLERPT NO STANDARD PAGE HEADING.
*----------------------------------------------------------------------
*
* PROGRAM               : /PSYNG/ROLERPT
* AUTHOR                : Principal Synergy LLC
* RELEASE               : 1.0
* DATE OF RELEASE       : 10/19/2004
* TRANSPORT REQUEST #   :
*----------------------------------------------------------------------*
*
* COPYRIGHTS Principal Synergy LLC
*
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*
*----------------------------------------------------------------------*
TABLES: AGR_USERS, AGR_AGRS, AGR_1251, AGR_DEFINE, TSTCT.
TABLES: /PSYNG/FUNCTTRAN, /PSYNG/CONFLICT, /PSYNG/SODOBJECT,
      /PSYNG/ROLEHDR, /PSYNG/CONFDET, /PSYNG/ROLETRANS.

DATA: g_EXIST TYPE C.
DATA: BEGIN OF gt_ITAB_TCODE   OCCURS 0.
DATA: SAPTECHNAME TYPE /PSYNG/ROLEHDR-SAPTECHNAME,
      TCODE TYPE TSTCT-TCODE.
DATA: END OF gt_ITAB_TCODE.

DATA:     BEGIN OF gt_ITAB_FUNCT1   OCCURS 0.
DATA:     SAPTECHNAME TYPE /PSYNG/ROLEHDR-SAPTECHNAME,
          FUNCTIONID TYPE /PSYNG/FUNCTTRAN-FUNCTIONID,
          TCODE  TYPE /PSYNG/FUNCTTRAN-TCODE.
DATA: END OF gt_ITAB_FUNCT1.

DATA:     BEGIN OF gt_ITAB_FUNCT2   OCCURS 0.
DATA:     UNAME TYPE AGR_USERS-UNAME,
          FUNCTIONID TYPE /PSYNG/FUNCTTRAN-FUNCTIONID,
          TCODE  TYPE /PSYNG/FUNCTTRAN-TCODE.
DATA: END OF gt_ITAB_FUNCT2.

DATA:     BEGIN OF gt_ITAB   OCCURS 0.
DATA:     UNAME TYPE AGR_USERS-UNAME,
          SAPTECHNAME TYPE /PSYNG/ROLEHDR-SAPTECHNAME,
          TCODE TYPE TSTCT-TCODE,
          TTEXT TYPE TSTCT-TTEXT,
          FLAG TYPE C.
DATA: END OF gt_ITAB.

DATA:     BEGIN OF G_ROLE_TRANS_ITAB   OCCURS 0.
DATA:     UNAME TYPE AGR_USERS-UNAME,
          SAPTECHNAME TYPE /PSYNG/ROLEHDR-SAPTECHNAME,
          TCODE TYPE TSTCT-TCODE,
          TTEXT TYPE TSTCT-TTEXT,
          FLAG TYPE C.
DATA: END OF G_ROLE_TRANS_ITAB.

DATA:     BEGIN OF G_ROLE_TRANS_ITAB2   OCCURS 0.
DATA:     UNAME TYPE AGR_USERS-UNAME,
          SAPTECHNAME TYPE /PSYNG/ROLEHDR-SAPTECHNAME,
          TCODE TYPE TSTCT-TCODE,
          TTEXT TYPE TSTCT-TTEXT.
DATA: END OF G_ROLE_TRANS_ITAB2.

DATA:     BEGIN OF gt_CONFLICT  OCCURS 0.
DATA:     SAPTECHNAME TYPE /PSYNG/ROLEHDR-SAPTECHNAME,
          CONID TYPE /PSYNG/CONFLICT-CONID,
          DESCRIPTION TYPE /PSYNG/CONFLICT-DESCRIPTION.
DATA:     END OF gt_CONFLICT.

DATA:     BEGIN OF gt_ITAB_CON  OCCURS 0.
DATA:     SAPTECHNAME TYPE /PSYNG/ROLEHDR-SAPTECHNAME,
          CONID TYPE /PSYNG/CONFLICT-CONID.
DATA:     END OF gt_ITAB_CON.

data : gs_program like sy-repid,
       gs_variant type disvariant.

selection-screen: begin of block a with frame title texttitl.
* INTERNAL TABLE FOR Conflicts Display
SELECT-OPTIONS: ROLEID FOR AGR_DEFINE-AGR_NAME.
PARAMETERS:     sodvrsio like /PSYNG/FUNCTTRAN-vrsio.

selection-screen: end of block a.

initialization.
  move TEXT-000 to texttitl.

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

  gs_program = sy-repid.
  PERFORM GET_TXNS.
  PERFORM CHECK_CONFLICT.
  PERFORM WRITE_REPORT.
*&---------------------------------------------------------------------*
*&      Form  GET_TXNS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_TXNS.
DATA: lv_agrname TYPE agr_define-agr_name.
    SELECT AGR_NAME INTO lv_agrname FROM AGR_DEFINE
    WHERE AGR_NAME IN ROLEID.

    SELECT * FROM AGR_AGRS
    WHERE AGR_NAME = lv_agrname" AGR_DEFINE-AGR_NAME
    AND   attributes <> 'X'.
     SELECT * FROM AGR_1251
      WHERE AGR_NAME = AGR_AGRS-CHILD_AGR
      AND OBJECT = 'S_TCODE'
      AND FIELD = 'TCD'
      AND DELETED <> 'X'.
       G_ROLE_TRANS_ITAB-SAPTECHNAME = lv_agrname. "AGR_DEFINE-AGR_NAME.
       G_ROLE_TRANS_ITAB-TCODE = AGR_1251-LOW.
       APPEND G_ROLE_TRANS_ITAB.
      ENDSELECT.
    ENDSELECT.
    IF SY-SUBRC <> 0.
      SELECT * FROM AGR_1251
      WHERE AGR_NAME = lv_agrname "AGR_DEFINE-AGR_NAME
      AND OBJECT = 'S_TCODE'
      AND FIELD = 'TCD'
      AND DELETED <> 'X'.
       G_ROLE_TRANS_ITAB-SAPTECHNAME = lv_agrname. " AGR_DEFINE-AGR_NAME
.
       G_ROLE_TRANS_ITAB-TCODE = AGR_1251-LOW.
       APPEND G_ROLE_TRANS_ITAB.
      ENDSELECT.
    ENDIF.
    PERFORM CHECK_CONFLICT.
    REFRESH G_ROLE_TRANS_ITAB.
    ENDSELECT.

ENDFORM.                    " GET_TXNS
*&---------------------------------------------------------------------*
*&      Form  CHECK_CONFLICT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM CHECK_CONFLICT.
*&---------------------------------------------------------------------*
*&      Form  POPULATE_SOD_CONFLICT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
 DATA: lv_desc TYPE /psyng/conflict-description.

  REFRESH gt_ITAB_TCODE.
  REFRESH G_ROLE_TRANS_ITAB2.
  LOOP AT G_ROLE_TRANS_ITAB.
    MOVE G_ROLE_TRANS_ITAB TO G_ROLE_TRANS_ITAB2.
    APPEND G_ROLE_TRANS_ITAB2.
  ENDLOOP.

  LOOP AT G_ROLE_TRANS_ITAB.
    g_EXIST = 'X'.
    SELECT * FROM /PSYNG/SODOBJECT      "#EC CI_SEL_NESTED
    WHERE TCODE =  G_ROLE_TRANS_ITAB-TCODE
    AND   VRSIO = sodvrsio.

      g_EXIST = SPACE.

      SELECT * FROM AGR_1251 INTO AGR_1251
      WHERE AGR_NAME = G_ROLE_TRANS_ITAB-SAPTECHNAME
      AND OBJECT = /PSYNG/SODOBJECT-OBJECT
      AND FIELD = /PSYNG/SODOBJECT-FIELD
      AND DELETED NE 'X'.

*      AND LOW NE '*'.
        IF AGR_1251-LOW = '*'.
          g_EXIST = 'X'.
        ENDIF.

        IF /PSYNG/SODOBJECT-VAL_TO > SPACE AND
            /PSYNG/SODOBJECT-VAL_FROM > SPACE.
          IF /PSYNG/SODOBJECT-VAL_FROM <= AGR_1251-LOW AND
             /PSYNG/SODOBJECT-VAL_TO >= AGR_1251-LOW.
            g_EXIST = 'X'.
          ENDIF.
        ENDIF.

        IF /PSYNG/SODOBJECT-VAL_FROM > SPACE AND
           /PSYNG/SODOBJECT-VAL_TO = SPACE.
          IF /PSYNG/SODOBJECT-VAL_FROM = AGR_1251-LOW.
            g_EXIST = 'X'.
          ENDIF.
        ENDIF.

        IF /PSYNG/SODOBJECT-VAL_FROM = SPACE AND
           /PSYNG/SODOBJECT-VAL_TO > SPACE.
          IF /PSYNG/SODOBJECT-VAL_TO = AGR_1251-LOW.
            g_EXIST = 'X'.
          ENDIF.
        ENDIF.

        IF /PSYNG/SODOBJECT-VAL_FROM = SPACE AND
           /PSYNG/SODOBJECT-VAL_TO = SPACE.
          g_EXIST = 'X'.
        ENDIF.
      ENDSELECT.

      IF g_EXIST = SPACE.
        gt_ITAB_TCODE-SAPTECHNAME = G_ROLE_TRANS_ITAB-SAPTECHNAME.
        gt_ITAB_TCODE-TCODE = G_ROLE_TRANS_ITAB-TCODE.
        APPEND gt_ITAB_TCODE.
      ENDIF.

    ENDSELECT.
  ENDLOOP.

  LOOP AT gt_ITAB_TCODE.
    DELETE G_ROLE_TRANS_ITAB2 WHERE TCODE = gt_ITAB_TCODE-TCODE.
  ENDLOOP.

  REFRESH gt_ITAB_FUNCT1.
  LOOP AT G_ROLE_TRANS_ITAB2.
    SELECT * FROM /PSYNG/FUNCTTRAN      "#EC CI_SEL_NESTED
    WHERE TCODE = G_ROLE_TRANS_ITAB2-TCODE
    AND   VRSIO = sodvrsio.
      gt_ITAB_FUNCT1-SAPTECHNAME = G_ROLE_TRANS_ITAB2-SAPTECHNAME.
      gt_ITAB_FUNCT1-FUNCTIONID = /PSYNG/FUNCTTRAN-FUNCTIONID.
      APPEND gt_ITAB_FUNCT1.
    ENDSELECT.
  ENDLOOP.

  SORT gt_ITAB_FUNCT1.
  DELETE ADJACENT DUPLICATES FROM gt_ITAB_FUNCT1.
  REFRESH gt_ITAB_CON.
  LOOP AT gt_ITAB_FUNCT1.
    SELECT * FROM /PSYNG/CONFDET         "#EC CI_SEL_NESTED
    WHERE FUNCTIONID = gt_ITAB_FUNCT1-FUNCTIONID
    AND   VRSIO      = sodvrsio.
      gt_ITAB_CON-SAPTECHNAME = gt_ITAB_FUNCT1-SAPTECHNAME.
      gt_ITAB_CON-CONID = /PSYNG/CONFDET-CONID.
      APPEND gt_ITAB_CON.
    ENDSELECT.
  ENDLOOP.
  SORT gt_ITAB_CON.
  DELETE ADJACENT DUPLICATES FROM gt_ITAB_CON.

  LOOP AT gt_ITAB_CON.
    g_EXIST = SPACE.
    SELECT * FROM /PSYNG/CONFDET        "#EC CI_SEL_NESTED
    WHERE CONID = gt_ITAB_CON-CONID
    AND   VRSIO = SODVRSIO.
      READ TABLE gt_ITAB_FUNCT1
      WITH KEY FUNCTIONID = /PSYNG/CONFDET-FUNCTIONID.
      IF SY-SUBRC <> 0.
        g_EXIST = 'X'.
      ENDIF.
    ENDSELECT.
    IF SY-SUBRC <> 0.
      g_EXIST = 'X'.
    ENDIF.
    IF g_EXIST = SPACE.
      gt_CONFLICT-SAPTECHNAME = gt_ITAB_CON-SAPTECHNAME.
      gt_CONFLICT-CONID = gt_ITAB_CON-CONID.
      SELECT SINGLE DESCRIPTION INTO lv_desc      "#EC CI_SEL_NESTED
       FROM /PSYNG/CONFLICT
      WHERE CONID = gt_CONFLICT-CONID
      AND   VRSIO = SODVRSIO.
      gt_CONFLICT-DESCRIPTION = lv_desc. "/PSYNG/CONFLICT-DESCRIPTION.
      APPEND gt_CONFLICT.
    ENDIF.
  ENDLOOP.
  SORT gt_CONFLICT.
  DELETE ADJACENT DUPLICATES FROM gt_CONFLICT.
ENDFORM.                    " CHECK_CONFLICT
*&---------------------------------------------------------------------*
*&      Form  WRITE_REPORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM WRITE_REPORT.
CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
     EXPORTING
     i_callback_program      = gs_program
     i_save                  = 'A'
     is_variant              = gs_variant
          I_STRUCTURE_NAME   = '/PSYNG/RLECNFLTALV'
     TABLES
          T_OUTTAB           = gt_CONFLICT
"(++)BOC UMITTAL SE VF scan-25/11/2024
      EXCEPTIONS
       PROGRAM_ERROR  = 1
       OTHERS         = 2 .
      IF sy-subrc <> 0.
           MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
       ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.  .          .
ENDFORM.                    " WRITE_REPORT
