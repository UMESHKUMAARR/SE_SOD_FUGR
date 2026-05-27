REPORT /psyng/sw_152.

TABLES: /psyng/swreshdr,
        /psyng/swresicon.
INCLUDE :
   /psyng/sw_config,
   /psyng/sw_152_top,
   /psyng/sw_152_cl1,
   /psyng/sw_152_o01,
   /psyng/sw_152_i01,
   /psyng/sw_152_f01.

SELECTION-SCREEN: BEGIN OF BLOCK user_o WITH FRAME TITLE text-001.
PARAMETERS: p_laid TYPE /psyng/seresid,
            p_paid TYPE /psyng/seresid.
SELECT-OPTIONS s_conid FOR /psyng/swresicon-conid.
PARAMETERS p_muser TYPE flag AS CHECKBOX.
SELECTION-SCREEN: END OF BLOCK user_o.
SELECTION-SCREEN: BEGIN OF BLOCK output WITH FRAME TITLE text-002.
PARAMETERS: p_confv TYPE flag DEFAULT 'X'
            RADIOBUTTON GROUP r1 USER-COMMAND conf,
            p_userv TYPE flag RADIOBUTTON GROUP r1,
            p_usrcov TYPE flag RADIOBUTTON GROUP r1.
SELECTION-SCREEN: END OF BLOCK output.
*--Hidden parameters to directly drill down to the details
PARAMETERS : p_det   TYPE flag               NO-DISPLAY,
             p_conid TYPE /psyng/conflict_id NO-DISPLAY,
             p_new   TYPE flag               NO-DISPLAY,
             p_old   TYPE flag               NO-DISPLAY.

INITIALIZATION.
*--Check if Configuration Set functionality is enabled.
  se_config_param 'DFLT_USER_COMP_VIEW' g_view.
  IF g_view = 'C'.
    p_confv = 'X'.
    CLEAR: p_userv, p_usrcov.
  ELSEIF g_view = 'U'.
    p_userv = 'X'.
    CLEAR: p_confv, p_usrcov.
  ELSEIF g_view = 'UC'.
    p_usrcov = 'X'.
    CLEAR: p_confv, p_userv.
  ENDIF.

AT SELECTION-SCREEN ON p_laid.
   SELECT COUNT(*)
     FROM /psyng/swreshdr
    WHERE aid EQ p_laid.
   IF sy-subrc NE 0.
    MESSAGE e002(/psyng/sw)
    WITH 'Please enter correct Latest Result ID'(e01).
   ENDIF.

AT SELECTION-SCREEN ON p_paid.
   SELECT COUNT(*)
     FROM /psyng/swreshdr
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
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-12/04/2024

  DATA: ls_pre_hdr    TYPE /psyng/swreshdr,
        ls_latest_hdr TYPE /psyng/swreshdr.

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
    FROM /psyng/swreshdr
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

  IF ls_pre_hdr-no_restrictions    IS INITIAL
  OR ls_latest_hdr-no_restrictions IS INITIAL.
    MESSAGE s352(/psyng/sw).
  ENDIF.

  CREATE OBJECT gr_event_handler_comp.

  CALL FUNCTION '/PSYNG/SW_COMPARE_RSLT_IDS'
    EXPORTING
      i_latest_aid         = g_latest_aid
      i_pre_aid            = g_pre_aid
      i_vrsio              = ls_latest_hdr-sodvrsio
      i_vrsio_pre          = ls_pre_hdr-sodvrsio
      if_user_view         = 'X'
      if_ex_missing_users  = p_muser
    TABLES
      it_conid             = s_conid
      et_detail            = gt_detail
      et_detail_user_view  = gt_detail_user_view
      et_detail_usrcon_view = gt_detail_usrcon_view
      et_newconflict_users = gt_newconflict_users
      et_remconflict_users = gt_remconflict_users.

  IF NOT p_confv IS INITIAL.
    g_view = 'C'.
  ELSEIF NOT p_userv IS INITIAL.
    g_view = 'U'.
  ELSEIF NOT p_usrcov IS INITIAL.
    g_view = 'UC'.
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
