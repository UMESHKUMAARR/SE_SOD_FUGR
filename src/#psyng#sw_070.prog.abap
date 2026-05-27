*----------------------------------------------------------------------*
* Report  /PSYNG/SW_070                                                *
* AUTHOR: Security Weaver, LLC                                         *
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
REPORT /psyng/sw_070 MESSAGE-ID /psyng/sw.

TYPE-POOLS: slis.            "For ALV call

DATA: BEGIN OF gt_output OCCURS 0,
        type(20)   TYPE c,
        object(20) TYPE c,
        vrsio      LIKE /psyng/swsodvers-vrsio,
        desc       LIKE /psyng/function-description,
      END OF gt_output.

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
PARAMETERS: p_funid  AS CHECKBOX DEFAULT 'X',
            p_contid AS CHECKBOX DEFAULT 'X',
            p_roleid AS CHECKBOX DEFAULT 'X',
            p_posn   AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK blk1.

*------------------------- AT SELECTION-SCREEN ------------------------*
AT SELECTION-SCREEN.
  IF p_funid IS INITIAL AND p_contid IS INITIAL AND p_roleid IS INITIAL
  AND p_posn IS INITIAL.
    MESSAGE e127.
  ENDIF.

*------------------------- START-OF-SELECTION -------------------------*
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
  IF NOT p_funid IS INITIAL.
    PERFORM find_funid.
  ENDIF.
  IF NOT p_contid IS INITIAL.
    PERFORM find_contid.
  ENDIF.
  IF NOT p_roleid IS INITIAL.
    PERFORM find_roleid.
  ENDIF.
  IF NOT p_posn IS INITIAL.
    PERFORM find_posn.
  ENDIF.

  MESSAGE s113 WITH text-m01.
  PERFORM output.

*&---------------------------------------------------------------------*
*&      Form  find_funid
*&---------------------------------------------------------------------*
*       Find unused functions
*----------------------------------------------------------------------*
FORM find_funid.
DATA: BEGIN OF lt_function OCCURS 0,
        function    TYPE /psyng/function-function,
        vrsio       TYPE /psyng/function-vrsio,
        description TYPE /psyng/function-description,
      END OF lt_function.


  MESSAGE s113 WITH text-001 text-002.

* Get all functions
  SELECT function vrsio description INTO TABLE lt_function
         FROM /psyng/function.

  gt_output-type = text-002.
  LOOP AT lt_function.
*   Search conflicts
    SELECT SINGLE mandt INTO sy-mandt      "#EC CI_SEL_NESTED
                 FROM /psyng/confdet
                  WHERE functionid = lt_function-function
                    AND vrsio      = lt_function-vrsio.
    CHECK sy-subrc <> 0.

    gt_output-object = lt_function-function.
    gt_output-vrsio  = lt_function-vrsio.
    gt_output-desc   = lt_function-description.
    APPEND gt_output.
  ENDLOOP.
ENDFORM.                    " find_funid

*&---------------------------------------------------------------------*
*&      Form  find_contid
*&---------------------------------------------------------------------*
*       Find unused mitigating controls
*----------------------------------------------------------------------*
FORM find_contid.
DATA: lt_mchdr TYPE TABLE OF /psyng/mchdr.

FIELD-SYMBOLS: <mchdr> TYPE /psyng/mchdr.


  MESSAGE s113 WITH text-001 text-003.

* Get all mitigating controls
  SELECT * INTO TABLE lt_mchdr FROM /psyng/mchdr.

  gt_output-type = text-003.
  LOOP AT lt_mchdr ASSIGNING <mchdr>.
*   Search mitigation assignments to users
    SELECT SINGLE mandt INTO sy-mandt         "#EC CI_SEL_NESTED
           FROM /psyng/mcuser
                  WHERE contid = <mchdr>-contid.
    CHECK sy-subrc <> 0.

*   Search mitigation assignments to user groups
    SELECT SINGLE mandt INTO sy-mandt          "#EC CI_SEL_NESTED
           FROM /psyng/mcusrgrp
                  WHERE contid = <mchdr>-contid.
    CHECK sy-subrc <> 0.

*   Search mitigation assignments to roles
    SELECT SINGLE mandt INTO sy-mandt           "#EC CI_SEL_NESTED
           FROM /psyng/mcrole
                  WHERE contid = <mchdr>-contid.
    CHECK sy-subrc <> 0.

*   Search mitigation assigment to critical auth. users
    SELECT SINGLE mandt INTO sy-mandt          "#EC CI_SEL_NESTED
     FROM /psyng/mccauser
        WHERE contid = <mchdr>-contid.
    CHECK sy-subrc <> 0.

*   Search mitigation assigment to critical auth. roles
    SELECT SINGLE mandt INTO sy-mandt        "#EC CI_SEL_NESTED
          FROM /psyng/mccarole
        WHERE contid = <mchdr>-contid.
    CHECK sy-subrc <> 0.

    clear gt_output-vrsio.
    gt_output-object = <mchdr>-contid.
    gt_output-desc   = <mchdr>-description.
    APPEND gt_output.
  ENDLOOP.
ENDFORM.                    " find_contid

*&---------------------------------------------------------------------*
*&      Form  find_roleid
*&---------------------------------------------------------------------*
*       Find unused roles
*----------------------------------------------------------------------*
FORM find_roleid.
DATA: BEGIN OF lt_rolehdr OCCURS 0,
        roleid      TYPE /psyng/rolehdr-roleid,
        description TYPE /psyng/rolehdr-description,
      END OF lt_rolehdr.


  MESSAGE s113 WITH text-001 text-004.

* Get all roles
  SELECT roleid  description INTO TABLE lt_rolehdr
    FROM /psyng/rolehdr.

  gt_output-type = text-004.
  LOOP AT lt_rolehdr.
*   Search positions
    SELECT SINGLE mandt INTO sy-mandt   "#EC CI_SEL_NESTED
      FROM /psyng/posndet
                  WHERE roleid = lt_rolehdr-roleid.
    CHECK sy-subrc <> 0.
    clear gt_output-vrsio.
    gt_output-object = lt_rolehdr-roleid.
    gt_output-desc   = lt_rolehdr-description.
    APPEND gt_output.
  ENDLOOP.
ENDFORM.                    " find_roleid

*&---------------------------------------------------------------------*
*&      Form  find_posn
*&---------------------------------------------------------------------*
*       Find unused positions
*----------------------------------------------------------------------*
FORM find_posn.
DATA: BEGIN OF lt_position OCCURS 0,
        positionid  TYPE /psyng/position-positionid,
        description TYPE /psyng/position-description,
      END OF lt_position.


  MESSAGE s113 WITH text-001 text-005.

* Get all positions
  SELECT positionid  description INTO TABLE lt_position
         FROM /psyng/position.

  gt_output-type = text-005.
  LOOP AT lt_position.
*   Search users
    SELECT SINGLE mandt INTO sy-mandt    "#EC CI_SEL_NESTED
       FROM /psyng/usrdet
                  WHERE positionid = lt_position-positionid.
    CHECK sy-subrc <> 0.
    clear gt_output-vrsio.
    gt_output-object = lt_position-positionid.
    gt_output-desc   = lt_position-description.
    APPEND gt_output.
  ENDLOOP.
ENDFORM.                    " find_posn

*&---------------------------------------------------------------------*
*&      Form  output
*&---------------------------------------------------------------------*
*       Output report using ALV
*----------------------------------------------------------------------*
FORM output.
DATA: l_repid     TYPE sy-repid,
      ls_layout   TYPE slis_layout_alv,
      ls_variant  TYPE disvariant,
      ls_fieldcat TYPE slis_fieldcat_alv,
      lt_fieldcat TYPE slis_t_fieldcat_alv.

  l_repid = sy-repid.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = l_repid
            i_internal_tabname = 'GT_OUTPUT'
            i_inclname         = l_repid
       CHANGING
            ct_fieldcat        = lt_fieldcat
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

* Set proper column headings
  ls_fieldcat-seltext_l = text-h01.
  ls_fieldcat-seltext_m = text-h01.
  ls_fieldcat-seltext_s = text-h01.
  ls_fieldcat-reptext_ddic = text-h01.
  MODIFY lt_fieldcat FROM ls_fieldcat
         TRANSPORTING seltext_l seltext_m seltext_s reptext_ddic
         WHERE fieldname = 'TYPE'.

  ls_fieldcat-seltext_l = text-h02.
  ls_fieldcat-seltext_m = text-h02.
  ls_fieldcat-seltext_s = text-h02.
  ls_fieldcat-reptext_ddic = text-h02.
  MODIFY lt_fieldcat FROM ls_fieldcat
         TRANSPORTING seltext_l seltext_m seltext_s reptext_ddic
         WHERE fieldname = 'OBJECT'.

  ls_fieldcat-seltext_l = text-h03.
  ls_fieldcat-seltext_m = text-h03.
  ls_fieldcat-seltext_s = text-h03.
  ls_fieldcat-reptext_ddic = text-h03.
  MODIFY lt_fieldcat FROM ls_fieldcat
         TRANSPORTING seltext_l seltext_m seltext_s reptext_ddic
         WHERE fieldname = 'DESC'.

  ls_layout-zebra = 'X'.
  ls_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program = l_repid
            is_layout          = ls_layout
            it_fieldcat        = lt_fieldcat
            i_save             = 'A'
            is_variant         = ls_variant
       TABLES
            t_outtab           = gt_output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.                    " output
