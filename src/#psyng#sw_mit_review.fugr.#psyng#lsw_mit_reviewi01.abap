*----------------------------------------------------------------------*
***INCLUDE LZSW_REVIEW_SCREENI01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9001  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_9001 INPUT.

CONSTANTS : lc_f03(4) VALUE '&F03',
            lc_btncanc(7) VALUE 'BTNCANC',
            lc_exit(4) VALUE 'EXIT',
            lc_btnexe(6) VALUE 'BTNEXE',
            lc_btntchg(7) VALUE 'BTNTCHG',
            lc_btnopam(7) VALUE 'BTNOPAM',
            lc_btncdet(7) VALUE 'BTNCDET',
            lc_btnadsp(7) VALUE 'BTNADSP',
            lc_btnacrt(7) VALUE 'BTNACRT',
            lc_btnsoff(7) VALUE 'BTNSOFF',
            lc_1(1) VALUE '1',
            lc_3(1) VALUE '3',
            lc_4(1) VALUE '4',
            lc_5(1) VALUE '5'.

CALL METHOD text_editor->get_text_as_r3table
    IMPORTING
      table           = gt_texttab       "
    EXCEPTIONS
      error_dp        = 1
      error_dp_create = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
  ENDIF.
  G_cnt = G_cnt + 1.
*BOC UMITTAL 14 Jan 2025 ATC Checks PN11269

  CASE SY-UCOMM.
*    WHEN '&F03'.
    WHEN lc_F03.
      LEAVE TO SCREEN 0.
    WHEN lc_BTNCANC.
      LEAVE TO SCREEN 0.
    WHEN lc_EXIT. "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (06/12/24)
      LEAVE TO SCREEN 0.
    WHEN lc_BTNEXE.
      PERFORM tcod_exe_det.
    WHEN lc_BTNTCHG.
     PERFORM tcod_chg_made.
    WHEN lc_BTNOPAM.
      PERFORM am_alerts_open.
    WHEN lc_BTNCDET.
       CASE G_CTYPE.
            WHEN lc_1.
              PERFORM call_sod_rep.
            WHEN lc_3.
              PERFORM call_ca_rep.
            WHEN lc_4.
              if gw_summary-userid is initial.
                PERFORM call_rolesod_rep.
              else.
                g_user = gw_summary-userid.
                PERFORM call_sod_rep.
              endif.
            WHEN lc_5.
              if gw_summary-userid is initial.
                PERFORM call_roleca_rep.
              else.
                g_user = gw_summary-userid.
                PERFORM call_ca_rep.
              endif.
       ENDCASE.
     WHEN lc_BTNADSP.
         PERFORM attach_open.
     WHEN lc_BTNACRT.
         PERFORM attach_create.
     WHEN lc_BTNSOFF.
         PERFORM create_sign_off.
  ENDCASE.
*EOC UMITTAL 14 Jan 2025 ATC Checks PN11269
ENDMODULE.                 " USER_COMMAND_9001  INPUT
