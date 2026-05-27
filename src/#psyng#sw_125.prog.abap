***INCLUDE /PSYNG/SW_125 .

DATA: usertype TYPE /psyng/xuustyp.
DATA: swconfig TYPE /psyng/swconfig.
DATA: l_table(6) TYPE c,
      lt_tvarv   TYPE TABLE OF tvarv WITH HEADER LINE,
      gf_has_display type flag. "report called in sapgui

SELECTION-SCREEN BEGIN OF SCREEN 1300 AS SUBSCREEN.
SELECTION-SCREEN: BEGIN OF BLOCK b_usr .

PARAMETERS: validusr AS CHECKBOX DEFAULT ' '  MODIF ID usr
 USER-COMMAND usr_fil.
SELECT-OPTIONS : usrtype FOR usertype MODIF ID usr.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 1.
SELECTION-SCREEN COMMENT 1(79) text-100 MODIF ID usr.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 1.
PARAMETERS: exlckusr AS CHECKBOX DEFAULT ' '  MODIF ID usr.
SELECTION-SCREEN COMMENT 3(79) text-102 MODIF ID usr.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 1.
PARAMETERS: outvdate AS CHECKBOX DEFAULT ' '  MODIF ID usr.
SELECTION-SCREEN COMMENT 3(79) text-101 MODIF ID usr.
SELECTION-SCREEN END OF LINE.

PARAMETERS: p_flag TYPE c NO-DISPLAY.

SELECTION-SCREEN: END OF BLOCK b_usr .
SELECTION-SCREEN END OF SCREEN 1300.

INITIALIZATION.
*--Only do this when report called with User Interface (so not from fiori)
TRY.
DATA : ls_runtime type CL_SALV_BS_RUNTIME_INFO=>S_TYPE_RUNTIME_INFO.
CALL METHOD cl_salv_bs_runtime_info=>get
  RECEIVING
    value  = ls_runtime.
 gf_has_display = ls_runtime-display.
 CATCH cx_salv_bs_sc_runtime_info .
*--unable to determine runtime, assume there's a display
   gf_has_display = 'X'.
ENDTRY.
if gf_has_display = 'X'."only do this when we have a display,
                            "otherwise this overwrites the selection criteria
*  -- Check if anything maintained for usertype in starv
    IF sy-saprl >= '620'.
*      l_table = 'TVARVC'.
      SELECT * INTO CORRESPONDING FIELDS OF TABLE
        lt_tvarv FROM tvarvc
           WHERE name = '/PSYNG/USERTYPE'
             AND type = 'S'.
    ELSE.
*      l_table = 'TVARV'.
      SELECT * INTO CORRESPONDING FIELDS OF TABLE
        lt_tvarv FROM tvarv
           WHERE name = '/PSYNG/USERTYPE'
             AND type = 'S'.
    ENDIF.

*    SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_tvarv FROM (l_table)
*           WHERE name = '/PSYNG/USERTYPE'
*             AND type = 'S'. "#EC SAST_CI_GEN_CHECK
*HBHALLA: As table name is variable so it can’t be fixed. (13/12/24)

    IF NOT lt_tvarv[] IS INITIAL.
      REFRESH usrtype.
      CLEAR usrtype.
    ENDIF.

    LOOP AT lt_tvarv.
      MOVE-CORRESPONDING lt_tvarv TO usrtype.
      usrtype-option = lt_tvarv-opti.
      APPEND usrtype.
    ENDLOOP.

    IF usrtype[] IS INITIAL.
      PERFORM set_def_usrtype.
    ENDIF.

*  Valid & Dialog Users only
    CLEAR swconfig.
    se_config_param 'DFLT_VALID_DIALOG' swconfig-value.

    IF swconfig-value = 'Y'.
      validusr = 'X'.
      exlckusr = 'X'.
      outvdate = 'X'.
    ELSEIF swconfig-value = 'N'.
      validusr = ' '.
    ENDIF.

    IF validusr IS INITIAL.
*  -- Default locked users
      CLEAR swconfig.
      se_config_param 'DFLT_EXCLUDE_LOCKED' swconfig-value.

      IF swconfig-value = 'Y'.
        exlckusr = 'X'.
      ELSEIF swconfig-value = 'N'.
        exlckusr = ' '.
      ENDIF.

*  -- Default expired users
      CLEAR swconfig.
      se_config_param 'DFLT_EXCL_OUT_VALID' swconfig-value.
      IF swconfig-value = 'Y'.
        outvdate = 'X'.
      ELSEIF swconfig-value = 'N'.
        outvdate = ' '.
      ENDIF.
    ENDIF.
endif.



*---------------------------------------------------------------------*
*       FORM set_def_usrtype                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM set_def_usrtype.
  REFRESH usrtype.
  CLEAR usrtype.
  usrtype-sign = 'I'.
  usrtype-option = 'EQ'.
  usrtype-low = 'A'.
  APPEND usrtype.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  get_config_usr
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_config_usr.
  if gf_has_display = 'X'.
  CHECK p_flag IS INITIAL.
*-- Check if anything maintained for usertype in starv
    IF sy-saprl >= '620'.
*      l_table = 'TVARVC'.
      SELECT * INTO CORRESPONDING FIELDS OF TABLE
        lt_tvarv FROM tvarvc
           WHERE name = '/PSYNG/USERTYPE'
             AND type = 'S'.
    ELSE.
*      l_table = 'TVARV'.
      SELECT * INTO CORRESPONDING FIELDS OF TABLE
        lt_tvarv FROM tvarv
           WHERE name = '/PSYNG/USERTYPE'
             AND type = 'S'.
    ENDIF.

*  SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_tvarv FROM (l_table)
*         WHERE name = '/PSYNG/USERTYPE'
*           AND type = 'S'."#EC SAST_CI_GEN_CHECK
*HBHALLA: As table name is variable so it can’t be fixed. (13/12/24)

  IF NOT lt_tvarv[] IS INITIAL.
    REFRESH usrtype.
    CLEAR usrtype.
  ENDIF.

  LOOP AT lt_tvarv.
    MOVE-CORRESPONDING lt_tvarv TO usrtype.
    usrtype-option = lt_tvarv-opti.
    APPEND usrtype.
  ENDLOOP.

  IF usrtype[] IS INITIAL.
    PERFORM set_def_usrtype.
  ENDIF.

*-- Default locked users
  CLEAR swconfig.
  se_config_param 'DFLT_EXCLUDE_LOCKED' swconfig-value.
  IF swconfig-value = 'Y'.
    exlckusr = 'X'.
  ELSEIF swconfig-value = 'N'.
    exlckusr = ' '.
  ENDIF.

*-- Default expired users
  CLEAR swconfig.
  se_config_param 'DFLT_EXCL_OUT_VALID' swconfig-value.
  IF swconfig-value = 'Y'.
    outvdate = 'X'.
  ELSEIF swconfig-value = 'N'.
    outvdate = ' '.
  ENDIF.

  p_flag = 'X'.
  endif.
ENDFORM.                    " get_config_usr
