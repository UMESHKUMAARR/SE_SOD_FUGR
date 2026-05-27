FUNCTION /psyng/sw_054.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_CONTID) TYPE  /PSYNG/MCHDR-CONTID
*"     VALUE(I_TYPE) TYPE  /PSYNG/MCREPID-FREQUENCY
*"     VALUE(I_REPID) TYPE  /PSYNG/MCREPID-REPID
*"----------------------------------------------------------------------
DATA: ls_histmon TYPE /psyng/mchistmon,
      ls_secu type SECU,
      lf_auth type flag.

* BOC by RGUPTA on 08.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 08.04.22 for C0700

  ls_histmon-contid    = i_contid.
  ls_histmon-last_exec = sy-datum.
  ls_histmon-bname     = l_current_user. "sy-uname. C0700

  CASE i_type.
    WHEN 'T'.           "Tcode
*     Call transaction and update history
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD i_repid.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH i_repid.
      ELSE.
*BOC UMITTAL CVA FIXES 11/03/2026
    CALL METHOD /psyng/sw_dynamic_select=>dynamic_call_txn
      EXPORTING
        i_prog =  i_repid .
*        CALL TRANSACTION i_repid. "#EC PATHLOCK_CI_DYN_ACCES
*EOC UMITTAL CVA FIXES 11/03/2026

        ls_histmon-tcode = i_repid.
        MODIFY /psyng/mchistmon FROM ls_histmon.
      endif.
    WHEN 'R'.           "Report
      lf_auth = 'X'.
      select single secu into ls_secu from trdir
        where name = i_repid."#EC SAST_CI_GEN_CHECK
      if sy-subrc = 0 and not ls_secu is initial.
         AUTHORITY-CHECK OBJECT 'S_PROGRAM'
         ID 'P_GROUP' FIELD ls_secu
         ID 'P_ACTION' FIELD 'SUBMIT'.
         if sy-subrc = 0.
           lf_auth = 'X'.
         else.
           clear lf_auth.
            MESSAGE e077(s#) WITH i_repid.
         endif.
      endif.
      if lf_auth = 'X'.
*       Submit reports and update history
*BOC UMITTAL CLEAN CORE FIXES 11/03/2026
        CALL METHOD /psyng/sw_dynamic_select=>call_program
          EXPORTING
            i_program = i_repid.
*        SUBMIT (i_repid) VIA SELECTION-SCREEN
*          AND RETURN."#EC PATHLOCK_CI_DYN_ACCES
*EOC UMITTAL CLEAN CORE FIXES 11/03/2026
        ls_histmon-repid = i_repid.
        MODIFY /psyng/mchistmon FROM ls_histmon.
      endif.
  ENDCASE.

  COMMIT WORK.
ENDFUNCTION.
