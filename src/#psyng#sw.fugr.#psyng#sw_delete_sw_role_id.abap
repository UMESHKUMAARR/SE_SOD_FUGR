FUNCTION /psyng/sw_delete_sw_role_id.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(PROLEID) LIKE  /PSYNG/ROLEHDR-ROLEID
*"  EXPORTING
*"     REFERENCE(ROLEID_DELETED)
*"     REFERENCE(ROLE_HDR_DELETED)
*"     REFERENCE(ROLE_TC_DELETED)
*"     REFERENCE(ROLE_TXT_DELETED)
*"  EXCEPTIONS
*"      ROLEID_DOESNT_EXIST
*"      NOT_AUTHORIZED
*"----------------------------------------------------------------------

  DATA: idexists,
        itextname LIKE /psyng/texts-textname.

  DATA: irolehdr TYPE STANDARD TABLE OF /psyng/rolehdr
                 WITH HEADER LINE,
        iroletrans TYPE STANDARD TABLE OF /psyng/roletrans
                   WITH HEADER LINE,
        itexts TYPE STANDARD TABLE OF /psyng/texts
               WITH HEADER LINE,
        ihistory TYPE STANDARD TABLE OF /psyng/history
               WITH HEADER LINE.
* BOC by RGUPTA on 07.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700
  roleid_deleted = 'N'.
  role_hdr_deleted = 'N'.
  role_tc_deleted = 'N'.
  role_txt_deleted = 'N'.

  CALL FUNCTION '/PSYNG/SW_CHECK_SWROLE_EXISTS'
       EXPORTING
            proleid = proleid
       IMPORTING
            exists  = idexists.

  IF idexists = 'N'.
    RAISE roleid_doesnt_exist.
  ENDIF.
  AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
           ID 'ACTVT' FIELD '06'
           ID 'Y&SW_ROLID' FIELD proleid.
  IF sy-subrc NE 0.
    RAISE not_authorized.
  ENDIF.

  CONCATENATE proleid 'DESC' INTO itextname.
  DELETE FROM /psyng/texts              "#EC CI_IMUD_NESTED
         WHERE textname = itextname
           AND object   = 'R'.

  CONCATENATE proleid 'HDR' INTO itextname.

  DELETE FROM /psyng/texts             "#EC CI_IMUD_NESTED
           WHERE textname = itextname
             AND object = 'R'.
  IF sy-subrc EQ 0.
    role_txt_deleted = 'Y'.
  ENDIF.

  DELETE FROM /psyng/roletrans          "#EC CI_IMUD_NESTED
                 WHERE roleid = proleid.
  IF sy-subrc EQ 0.
    role_tc_deleted = 'Y'.
  ENDIF.

  DELETE FROM /psyng/rolehdr            "#EC CI_IMUD_NESTED
              WHERE roleid = proleid.
  IF sy-subrc EQ 0.
    role_hdr_deleted = 'Y'.
    roleid_deleted = 'Y'.

*  Document history of role deletion
    CLEAR ihistory.
    REFRESH ihistory.
    clear ihistory-vrsio .
    ihistory-tabname = '/PSYNG/ROLEHDR'.
    ihistory-hdrfld = 'ROLEID'.
    ihistory-oldval = proleid.
    ihistory-create_dat = sy-datum.
    ihistory-create_tim = sy-uzeit.
    ihistory-status = 'D'.
    ihistory-create_usr = l_current_user. "sy-uname. C0700
    APPEND ihistory.
    INSERT /psyng/history FROM TABLE ihistory.

  ENDIF.

  COMMIT WORK.

ENDFUNCTION.
