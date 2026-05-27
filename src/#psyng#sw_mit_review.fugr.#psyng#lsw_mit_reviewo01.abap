*----------------------------------------------------------------------*
***INCLUDE LZSW_REVIEW_SCREENO01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_9001  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_9001 OUTPUT.
  SET PF-STATUS '9001'.
  PERFORM assign_values.
  PERFORM get_text.

  LOOP AT SCREEN.

    CASE gw_summary-type.
      WHEN '1'.
        IF screen-name = 'G_AGR_NAME' OR
           screen-name = 'G_AGR_DESC' OR
           screen-name = 'TXTROLE'    OR
           screen-name = 'TXTCID'     OR
           screen-name = 'GCAID'      or
           screen-name = 'G_CRAUTH_DESC'.
          screen-active = 0.
        ENDIF.

      WHEN '2'.
        IF screen-name = 'G_AGR_NAME' OR
                   screen-name = 'G_AGR_DESC' OR
                   screen-name = 'TXTROLE'    OR
                   screen-name = 'TXTCID'     OR
                   screen-name = 'GCAID'      OR
                   screen-name = 'G_USER'    OR
                   screen-name = 'G_USER_NM' or
                   screen-name = 'TXTUSER'   or
                   screen-name = 'G_CRAUTH_DESC'.
          screen-active = 0.
        ENDIF.

      WHEN '3'.
        IF screen-name = 'G_CONID'    OR
           screen-name = 'G_CONID_NM' OR
           screen-name = 'TXTCONF'    OR
           screen-name = 'G_AGR_NAME' OR
           screen-name = 'TXTROLE'    OR
           screen-name = 'G_AGR_DESC' or
           screen-name = 'G_CRAUTH_DESC'.
          screen-active = 0.
        ENDIF.
      WHEN '4'.
        IF screen-name = 'GCAID'     OR
           screen-name = 'TXTCID'    OR
           ( g_user is initial and screen-name = 'TXTUSER'   )  OR
           ( g_user is initial and screen-name = 'G_USER'    )  OR
           ( g_user is initial and screen-name = 'G_USER_NM' ) or
           screen-name = 'G_CRAUTH_DESC'.
          screen-active = 0.
        ENDIF.
      WHEN '5'.
        IF screen-name = 'G_CONID'    OR
           screen-name = 'TXTCONF'    OR
           screen-name = 'G_CONID_NM' OR
           ( g_user is initial and screen-name = 'TXTUSER'   )  OR
           ( g_user is initial and screen-name = 'G_USER'    )  OR
           ( g_user is initial and screen-name = 'G_USER_NM' )  or
           screen-name = 'G_CRAUTH_DESC'.
          screen-active = 0.
        ENDIF.

    ENDCASE.
*--Hide CA details button if this is a conflict
    IF gw_summary-conid IS INITIAL AND screen-name = 'BTNCDET'.
      screen-active = 0.
    ENDIF.
*--Hide SOD details button if this is a CA
    IF gw_summary-swaudid IS INITIAL AND screen-name = 'BTNCADET'.
      screen-active = 0.
    ENDIF.

    IF g_cexe = ''.
      IF screen-name = 'BTNTEXE'.
        screen-input = 0.
      ENDIF.
    ENDIF.
    IF g_cchg = ''.
      IF screen-name = 'BTNTCHG'.
        screen-input = 0.
      ENDIF.
    ENDIF.
    IF g_coam = ''.
      IF screen-name = 'BTNOPAM'.
        screen-input = 0.
      ENDIF.
    ENDIF.
    if gf_mit_by_org <> 'Y' and screen-group1 = 'ORG'.
       screen-active = 0.
       screen-output = 0.
    endif.
    MODIFY SCREEN.
  ENDLOOP.



ENDMODULE.                 " STATUS_9001  OUTPUT
