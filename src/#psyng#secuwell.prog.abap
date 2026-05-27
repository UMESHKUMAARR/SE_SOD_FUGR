
*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SECUWELL
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module pool       /PSYNG/SECUWELL                                   *
*&                                                                     *
*&---------------------------------------------------------------------*
*&                                                                     *
*&                                                                     *
*&---------------------------------------------------------------------*
INCLUDE /psyng/sectop.
INCLUDE /psyng/secuwelltop.
INCLUDE /psyng/basis_exelog.
INCLUDE /psyng/secuwellm01.
INCLUDE /psyng/secuwellcl1.
INCLUDE /psyng/secuwello01.
INCLUDE /psyng/secuwelli01.
INCLUDE /psyng/secuwellf01.
INCLUDE /psyng/secuwellh01.

*--------------------------- LOAD-OF-PROGRAM --------------------------*
LOAD-OF-PROGRAM.
  gt_exelog-mandt = sy-mandt.
  gt_exelog-repid = sy-repid.
* BOC by RGUPTA on 28.03.22 on C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 28.03.22 on C0700
  gt_exelog-uname = g_current_user."sy-uname. C0700
  gt_exelog-datum = sy-datum.
  gt_exelog-uzeit = sy-uzeit.
  APPEND gt_exelog.
  CALL FUNCTION '/PSYNG/BASIS_EXELOG' IN BACKGROUND TASK
    TABLES
     exelog         = gt_exelog.

  COMMIT WORK.

  CALL FUNCTION '/PSYNG/SW_034'
       IMPORTING
            e_vrsio = g_sod_vrsio.
*--Get Description
      PERFORM get_desc_sod_vrsio
                  USING
                     g_sod_vrsio
                  CHANGING
                     g_sod_vrsio_desc.

  PERFORM get_entry_point.
  PERFORM get_default_config.
  PERFORM init_rfc_dest.

*--For System Filter ALV
  CREATE OBJECT gr_event_handler.
  CREATE OBJECT gr_event_handler_fun.
  CREATE OBJECT gr_event_handler_ca.
  CREATE OBJECT gr_event_handler_tcd.
  CREATE OBJECT gr_event_handler_audit.
   gf_dispchg1 = gc_display.
*--------------------------- AT USER-COMMAND --------------------------*
* Used for screen 903
AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'CONTINUE'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'NOCONTINUE'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.

INCLUDE /PSYNG/SECUWELLF02.
