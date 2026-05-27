FUNCTION /psyng/sw_copy_sw_role_id.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(FROM_ROLEID) LIKE  /PSYNG/ROLEHDR-ROLEID
*"     REFERENCE(TO_ROLEID) LIKE  /PSYNG/ROLEHDR-ROLEID
*"  EXPORTING
*"     REFERENCE(ROLEID_COPIED)
*"     REFERENCE(ROLE_HDR_COPIED)
*"     REFERENCE(ROLE_TC_COPIED)
*"     REFERENCE(ROLE_TXT_COPIED)
*"  EXCEPTIONS
*"      TARGET_ROLEID_ALREADY_EXISTS
*"      NOT_AUTHORIZED
*"----------------------------------------------------------------------

  DATA: target_exists,
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
  roleid_copied = 'N'.
  role_hdr_copied = 'N'.
  role_tc_copied = 'N'.
  role_txt_copied = 'N'.

  CALL FUNCTION '/PSYNG/SW_CHECK_SWROLE_EXISTS'
       EXPORTING
            proleid = to_roleid
       IMPORTING
            exists  = target_exists.

  IF target_exists = 'Y'.
    RAISE target_roleid_already_exists.
  ENDIF.
  AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
           ID 'ACTVT' FIELD '01'
           ID 'Y&SW_ROLID' field TO_ROLEID.
  if sy-subrc ne 0.
    raise NOT_AUTHORIZED.
  endif.

  SELECT * FROM /psyng/rolehdr INTO TABLE irolehdr
           WHERE roleid = from_roleid.

  SELECT * FROM /psyng/roletrans INTO TABLE iroletrans
           WHERE roleid = from_roleid.

  CONCATENATE from_roleid 'HDR' INTO itextname.

  SELECT * FROM /psyng/texts INTO TABLE itexts
           WHERE textname = itextname
             AND object   = 'R'
           order by line.

  SORT: irolehdr, iroletrans, itexts.

* Add role header information
  LOOP AT irolehdr.
    irolehdr-roleid = to_roleid.
    MODIFY irolehdr.
  ENDLOOP.
  INSERT /psyng/rolehdr FROM TABLE irolehdr.
  IF sy-subrc NE 0.
    EXIT.
  ENDIF.
  roleid_copied = 'Y'.
  role_hdr_copied = 'Y'.

*Document history of role creation
  CLEAR ihistory.
  REFRESH ihistory.
  clear ihistory-vrsio  .
  ihistory-tabname = '/PSYNG/ROLEHDR'.
  ihistory-hdrfld = 'ROLEID'.
  ihistory-oldval = to_roleid.
  ihistory-create_dat = sy-datum.
  ihistory-create_tim = sy-uzeit.
  ihistory-status = 'I'.
  ihistory-create_usr = l_current_user. "sy-uname. C0700
  APPEND ihistory.
  INSERT /psyng/history FROM TABLE ihistory.

  REFRESH ihistory.
* Add role transactions
  LOOP AT iroletrans.
    CLEAR ihistory.
    iroletrans-roleid = to_roleid.
    MODIFY iroletrans.
*Document history for transactions addtions to role
    clear ihistory-vrsio .
    ihistory-tabname = '/PSYNG/ROLETRANS'.
    ihistory-hdrfld = to_roleid.
    ihistory-dtlfld = 'TCODE'.
    ihistory-oldval = iroletrans-tcode.
    ihistory-create_dat = sy-datum.
    ihistory-create_tim = sy-uzeit.
    ihistory-status = 'I'.
    ihistory-create_usr = l_current_user. "sy-uname. C0700
    APPEND ihistory.
  ENDLOOP.
*****  TSEN ON 26/02/2009 ************
*  INSERT /psyng/roletrans FROM TABLE iroletrans.
   MODIFY /psyng/roletrans FROM TABLE iroletrans.
************************************
  IF sy-subrc = 0.
    role_tc_copied = 'Y'.

    SORT ihistory.
    DELETE ADJACENT DUPLICATES FROM ihistory.
    IF NOT ihistory[] IS INITIAL.
      INSERT /psyng/history FROM TABLE ihistory.
    ENDIF.
  ENDIF.

* Add role texts
  CLEAR itextname.
  CONCATENATE to_roleid 'HDR' INTO itextname.
  LOOP AT itexts.
    itexts-textname = itextname.
    MODIFY itexts.
  ENDLOOP.
*****  TSEN ON 26/02/2009 ************
*  INSERT /psyng/texts FROM TABLE itexts.
  MODIFY  /psyng/texts FROM TABLE itexts.
*****************************************
  IF sy-subrc EQ 0.
    role_txt_copied = 'Y'.
  ENDIF.

  COMMIT WORK.
ENDFUNCTION.
