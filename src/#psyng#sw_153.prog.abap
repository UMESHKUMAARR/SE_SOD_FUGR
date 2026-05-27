REPORT /psyng/sw_153.

TABLES: /psyng/swreshdr.
INCLUDE :
   /psyng/sw_config,
   /psyng/sw_153_top,
   /psyng/sw_153_cl1,
   /psyng/sw_153_o01,
   /psyng/sw_153_i01,
   /psyng/sw_153_f01.

SELECTION-SCREEN: BEGIN OF BLOCK user_o WITH FRAME TITLE text-001.
PARAMETERS: p_laid TYPE /psyng/serrsid,
            p_paid TYPE /psyng/serrsid.
PARAMETERS: p_confv TYPE flag DEFAULT 'X'
            RADIOBUTTON GROUP r1 USER-COMMAND conf,
            p_rolev TYPE flag RADIOBUTTON GROUP r1.
SELECTION-SCREEN: END OF BLOCK user_o.

*--Hidden parameters to directly drill down to the details
PARAMETERS : p_det     TYPE flag               NO-DISPLAY,
             p_conid   TYPE /psyng/conflict_id NO-DISPLAY,
             p_new     TYPE flag               NO-DISPLAY,
             p_old     TYPE flag               NO-DISPLAY.

INITIALIZATION.
*--Check if Configuration Set functionality is enabled.
  se_config_param 'DFLT_ROLE_COMP_VIEW' g_confv.
  IF g_confv = 'C'.
    p_confv = 'X'.
    CLEAR p_rolev.
  ELSEIF g_confv = 'R'.
    p_rolev = 'X'.
    CLEAR p_confv.
  ENDIF.

AT SELECTION-SCREEN ON p_laid.
  SELECT COUNT(*)
    FROM /psyng/swrrshdr
  WHERE aid EQ p_laid.
  IF sy-subrc NE 0.
    MESSAGE e002(/psyng/sw)
    WITH 'Please enter correct Latest Result ID'(e01).
  ENDIF.

AT SELECTION-SCREEN ON p_paid.
  SELECT COUNT(*)
    FROM /psyng/swrrshdr
  WHERE aid EQ p_paid.
  IF sy-subrc NE 0.
    MESSAGE e002(/psyng/sw)
    WITH 'Please enter correct Previous Result ID'(e02).
  ENDIF.

START-OF-SELECTION.

*BOC AKUMAR SE VF scan changes-12/04/2024

  AUTHORITY-CHECK OBJECT 'S_PROGRAM'
         ID 'P_GROUP' FIELD 'SW_SE'
         ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) WITH 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-12/04/2024

  DATA: ls_pre_hdr    TYPE /psyng/swrrshdr,
        ls_latest_hdr TYPE /psyng/swrrshdr.

  IF p_laid IS INITIAL
  OR p_paid IS INITIAL.
    MESSAGE s002(/psyng/sw) WITH 'Please enter both result IDs'(e00).
    RETURN.
  ENDIF.

  IF p_laid LE p_paid.
    g_latest_aid = p_paid.
    g_pre_aid    = p_laid.
  ELSE.
    g_latest_aid = p_laid.
    g_pre_aid    = p_paid.
  ENDIF.

  SELECT *
    FROM /psyng/swrrshdr
    INTO TABLE gt_hdr
    WHERE aid EQ g_latest_aid
  OR aid EQ g_pre_aid.
  IF sy-subrc EQ 0.
    SORT gt_hdr BY aid.
    READ TABLE gt_hdr INTO ls_pre_hdr
      WITH KEY aid = g_pre_aid
      BINARY SEARCH.
    READ TABLE gt_hdr INTO ls_latest_hdr
      WITH KEY aid = g_latest_aid
      BINARY SEARCH.
  ENDIF.


  IF ls_pre_hdr-no_restrictions IS INITIAL
  OR ls_latest_hdr-no_restrictions IS INITIAL.
    MESSAGE s352(/psyng/sw).
  ENDIF.


  CREATE OBJECT gr_event_handler_comp.

  CALL FUNCTION '/PSYNG/SW_COMPARE_RSLT_IDS'
    EXPORTING
      i_role_latest_aid         = g_latest_aid
      i_role_pre_aid            = g_pre_aid
      i_vrsio                   = ls_latest_hdr-sodvrsio
      i_vrsio_pre               = ls_pre_hdr-sodvrsio
      if_role                   = 'X'
      if_role_view              = 'X'
      i_con_role_det            = 'X' "Code Logic Line AKUMAR++
      i_role_con_det            = 'X' "Code Logic Line AKUMAR++
    TABLES
      et_detail            = gt_detail
      et_detail_role_view  = gt_detail_role_view
      et_newconflict_roles = gt_newconflict_roles
      et_remconflict_roles = gt_remconflict_roles
      et_con_new_rem_role = gt_con_new_rem_role "AKUMAR++ PN15658
      et_role_new_rem_con = gt_role_new_rem_con. "AKUMAR++ PN15658
  IF NOT p_confv IS INITIAL.
    g_confv = p_confv.
  ELSE.
    CLEAR g_confv.
  ENDIF.
  IF p_det IS INITIAL.
    CALL SCREEN '0100'.
  ELSE.
    PERFORM navigate_to_details
      USING
        p_conid
        p_new
        p_old.
  ENDIF.
