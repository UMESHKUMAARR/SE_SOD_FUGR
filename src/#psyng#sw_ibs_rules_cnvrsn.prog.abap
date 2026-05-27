*&---------------------------------------------------------------------*
*& Report  /PSYNG/SW_IBS_RULES_CNVRSN
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT /psyng/sw_ibs_rules_cnvrsn.
*================ INCLUDES ========================
INCLUDE /psyng/sw_ibs_rule_top.
INCLUDE /psyng/sw_ibs_global_sel.        " global top include
INCLUDE /psyng/sw_ibs_rule_imp.         " implementation include


AT SELECTION-SCREEN.
  IF p_vdesc IS INITIAL.
    SELECT SINGLE vdesc INTO  p_vdesc FROM /psyng/swsodvers
    WHERE vrsio = p_vrsn.
  ENDIF.

* -------------------- AT SELECTION-SCREEN OUTPUT

*If use existing version description checked,
*   Then Inactive option to add new description.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF p_ibstxt = 'X'.
      CLEAR p_vdesc.
      IF screen-name = 'P_VDESC'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.

  LOOP AT SCREEN.
    IF p_tstrun = 'X'.
      CLEAR :  p_ovrwrt , p_noval.
      IF screen-name = 'P_OVRWRT'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'P_NOVAL'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.


    IF p_tstrun = ''.
      IF screen-name = 'P_OVRWRT'.
        screen-input = 1.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'P_NOVAL'.
        screen-input = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.
* -------------------- START-OF-SELECTION

START-OF-SELECTION.

  AUTHORITY-CHECK OBJECT 'S_PROGRAM'
         ID 'P_GROUP' FIELD 'SW_SE'
         ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) WITH 'execute '(009) sy-repid.
    EXIT.
  ENDIF.
  PERFORM input_validation.


* -------------------- OBJECT CREATION

  CREATE OBJECT converter
    TYPE /psyng/cl_sw_ibs_rules_conv
    EXPORTING
      delete_db = p_dlt_db.

* -------------------- CALLING METHOD
  converter->convert_data(
  EXPORTING   i_vrsn      = p_vrsn     " SOD Version Export
              i_exstng    = p_ibstxt   " Existing version description
              i_vrs_desc  = p_vdesc    " New version description
              i_ovrwrt    = p_ovrwrt   " Overwrite Version
              i_testrun   = p_tstrun   " Testrun
              i_skp_vald  = p_noval    " Skip validations
  IMPORTING   exp_log     = gt_log ).  " Log table


END-OF-SELECTION.
* -------------------- OUTPUT LOG ALV
  SORT gt_log BY filename
                 type
                 object
                 object_id
                 fieldname
                 value .

  PERFORM output_log TABLES gt_log.
*&-------------------------------------------------------------------*
*&      Form  INPUT_VALIDATIO
*&-------------------------------------------------------------------*
*       text
*--------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*--------------------------------------------------------------------*
FORM input_validation .
*SOD Version field should not be null

  IF p_vrsn EQ '000' OR
     p_vrsn EQ '999' .
    MESSAGE s002(/psyng/sw) WITH
      'SOD Version can not be 000 or 999.'(202)
     DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.


  IF p_vrsn IS INITIAL.
    MESSAGE s002(/psyng/sw) WITH 'Please enter the SOD Version'(200)
     DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

*verify if version alreay exists or not
  CLEAR lv_mandt.
  SELECT SINGLE mandt INTO lv_mandt FROM /psyng/swsodvers
  WHERE vrsio = p_vrsn.
  IF sy-subrc = 0.
    CLEAR lv_vers_exst.
    lv_vers_exst = 'X'.
  ENDIF.
  CLEAR lv_mandt.

*IF "use exising description" is unchecked
*and version doesnt exist earlier,
*then new description field cannot be null
  IF p_vdesc IS INITIAL AND
     p_ibstxt NE 'X' AND
     lv_vers_exst IS INITIAL.
    MESSAGE s002(/psyng/sw) WITH 'Please enter the Description'(201)
     DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.


  IF    p_tstrun IS INITIAL AND
        p_ovrwrt IS INITIAL AND
        p_noval  IS NOT INITIAL .
    MESSAGE 'Please select either Test Run or Overwrite'(204)
      TYPE 'I' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ELSEIF p_tstrun IS INITIAL AND
         p_ovrwrt IS INITIAL AND
         p_noval  IS INITIAL ..
    MESSAGE 'Please select atleast One Operation'(203)
      TYPE 'I' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.
