*----------------------------------------------------------------------*
* Function Module       : /PSYNG/SW_006
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*

FUNCTION /psyng/sw_006.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(ASSIGN) LIKE  /PSYNG/MCUSER STRUCTURE  /PSYNG/MCUSER
*"       OPTIONAL
*"     VALUE(UPDATEFLAG) TYPE  /PSYNG/BAPIFLAGX OPTIONAL
*"     VALUE(DELETEFLAG) TYPE  /PSYNG/BAPIFLAGX OPTIONAL
*"     VALUE(NO_EMAIL) TYPE  FLAG DEFAULT ' '
*"  EXPORTING
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  EXCEPTIONS
*"      MITIGATION_NOT_ASSIGNED
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_006'.
*  S_RFC AUTHORITY CHECK
* BOC BNAYAK CVA scan fix DT:05-05-2026
*  AUTHORITY-CHECK OBJECT 'S_RFC'
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
* EOC BNAYAK CVA scan fix DT:05-05-2026
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026


  DATA: ls_mit_assgn TYPE /psyng/mitigation_assignment,
        lf_no_change TYPE flag.


  CLEAR return.

  SELECT SINGLE * FROM /psyng/mchdr
  WHERE contid = assign-contid.


  IF sy-subrc = 0.

    IF updateflag = space AND deleteflag = space.
      MOVE-CORRESPONDING assign TO /psyng/mcuser.
      INSERT /psyng/mcuser.
      IF sy-subrc <> 0.
*--This Mitigation was already assigned, but for a different date
        MODIFY /psyng/mcuser.
        PERFORM retain_history
                    USING
                       'U'
                       assign.
      ELSE.
        PERFORM retain_history
                    USING
                       'I'
                       assign.
      ENDIF.


*     Send email to appropriate auditor(s)
      MOVE-CORRESPONDING /psyng/mcuser TO ls_mit_assgn.
      ls_mit_assgn-type = '1'.                   "User
      CALL FUNCTION '/PSYNG/SW_078'
           EXPORTING
                is_mit_assgn   = ls_mit_assgn
                i_single_recip = /psyng/mcuser-auditor.
    ENDIF.
    IF updateflag = 'X'.
      SELECT SINGLE * FROM /psyng/mcuser INTO /psyng/mcuser
      WHERE  contid = assign-contid
      AND    conid  = assign-conid
      AND    userid = assign-userid
      AND    vrsio  = assign-vrsio.
      IF sy-subrc <> 0.
        return-type = 'E'.
        return-code = '10'.
        return-message = text-007.
      ELSE.
        CLEAR /psyng/mcuser-mandt.
        IF /psyng/mcuser = assign.
*        There is no change.
          lf_no_change = 'X'.
        ENDIF.
        CHECK lf_no_change IS INITIAL.
        IF assign-auditor <> space.
          /psyng/mcuser-auditor = assign-auditor.
        ENDIF.
        IF assign-from_date <> space.
          /psyng/mcuser-from_date =  assign-from_date.
        ENDIF.
        IF assign-to_date <> space.
          /psyng/mcuser-to_date =  assign-to_date.
        ENDIF.
        UPDATE /psyng/mcuser.
        PERFORM retain_history
                    USING
                       'U'
                       assign.
        IF NOT no_email = 'X'.
*       Send email to appropriate auditor(s)
          MOVE-CORRESPONDING /psyng/mcuser TO ls_mit_assgn.
          ls_mit_assgn-type = '1'.               "User
          CALL FUNCTION '/PSYNG/SW_078'
               EXPORTING
                    is_mit_assgn   = ls_mit_assgn
                    i_single_recip = /psyng/mcuser-auditor.
        ENDIF.
      ENDIF.
    ENDIF.

    IF deleteflag = 'X'.
      SELECT SINGLE * FROM /psyng/mcuser INTO /psyng/mcuser
        WHERE  contid = assign-contid
        AND    conid  = assign-conid
        AND    userid = assign-userid
        AND    vrsio  = assign-vrsio.

      CHECK sy-subrc = 0.
      DELETE /psyng/mcuser.
      PERFORM retain_history
                  USING
                     'D'
                     assign.

    ENDIF.
  ELSE.
    return-type    = 'E'.
    return-code    = '10'.
    return-message = text-008.
  ENDIF.

  exelog_api '/PSYNG/SW_006' ''.


ENDFUNCTION.

*&---------------------------------------------------------------------*
*&      Form  retain_history
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM retain_history USING i_status
                          i_assign TYPE /psyng/mcuser.
* BOC by RGUPTA on 08.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 08.04.22 for C0700
  /psyng/tsw_hst-vrsio      = i_assign-vrsio.
  /psyng/tsw_hst-changeby   = l_current_user. "sy-uname. C0700
  /psyng/tsw_hst-changedate = sy-datum.
  /psyng/tsw_hst-changetime = sy-uzeit.
  /psyng/tsw_hst-action     = i_status.
  /psyng/tsw_hst-contid     = i_assign-contid.
  /psyng/tsw_hst-conid      = i_assign-conid.
  /psyng/tsw_hst-userid     = i_assign-userid.
  /psyng/tsw_hst-auditor    = i_assign-auditor.
  /psyng/tsw_hst-from_date  = i_assign-from_date.
  /psyng/tsw_hst-to_date    = i_assign-to_date.
  INSERT /psyng/tsw_hst.
  CLEAR /psyng/tsw_hst.
ENDFORM.                    "retain_history
