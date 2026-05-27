  FUNCTION /psyng/sw_create_swrole_file.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(OVERWRITE) TYPE  C
*"  EXPORTING
*"     REFERENCE(ROLEID_CREATED)
*"     REFERENCE(ROLEIDEXISTS)
*"     REFERENCE(ROLE_HDR_CREATED)
*"     REFERENCE(ROLE_TC_ADDED)
*"     REFERENCE(ROLE_TXT_ADDED)
*"  TABLES
*"      IROLEHDR STRUCTURE  /PSYNG/ROLEHDR
*"      IROLETRANS STRUCTURE  /PSYNG/ROLETRANS
*"      ITEXTS STRUCTURE  /PSYNG/TEXTS
*"  EXCEPTIONS
*"      SW_ROLE_EXISTS
*"      MULTIPLE_ROLES_PROVIDED
*"      NOT_AUTHORIZED
*"----------------------------------------------------------------------

* Make sure there is only one record in Role Header (IROLEHDR)
* This FM is intended to create only one SW Role ID at a time

    DATA: totalroles TYPE i.
  DATA: ihistory TYPE STANDARD TABLE OF /psyng/history WITH HEADER LINE,
              l_textname TYPE /psyng/texts-textname.
* BOC by RGUPTA on 07.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700

    roleid_created = 'N'.

    DESCRIBE TABLE irolehdr LINES totalroles.
    IF totalroles GT 1.
      RAISE multiple_roles_provided.
    ENDIF.

    LOOP AT irolehdr.

      IF overwrite = ' '.

        CALL FUNCTION '/PSYNG/SW_CHECK_SWROLE_EXISTS'
             EXPORTING
                  proleid = irolehdr-roleid
             IMPORTING
                  exists  = roleidexists.

        IF roleidexists = 'Y'.  "check Role ID doesn't exist already
          RAISE sw_role_exists.
        ENDIF.

      ENDIF.

      AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
               ID 'ACTVT' FIELD '01'
               ID 'Y&SW_ROLID' FIELD irolehdr-roleid.
      IF sy-subrc NE 0.
        RAISE not_authorized.
      ENDIF.

      EXIT.

    ENDLOOP.


    CLEAR roleidexists.

    IF overwrite = 'X'.

      MODIFY /psyng/rolehdr FROM TABLE irolehdr. "#EC CI_IMUD_NESTED

    ELSE.

      INSERT /psyng/rolehdr FROM TABLE irolehdr. "#EC CI_IMUD_NESTED

    ENDIF.

    IF sy-subrc NE 0.
      EXIT.
    ENDIF.
    roleid_created = 'Y'.
    role_hdr_created = 'Y'.

*Document history of role creation
    CLEAR ihistory.
    REFRESH ihistory.
    CLEAR ihistory-vrsio .
    ihistory-tabname    = '/PSYNG/ROLEHDR'.
    ihistory-hdrfld     = 'ROLEID'.
    ihistory-create_dat = sy-datum.
    ihistory-create_tim = sy-uzeit.
    ihistory-status     = 'I'.
    ihistory-create_usr = l_current_user. "sy-uname. C0700
    LOOP AT irolehdr.
      ihistory-oldval = irolehdr-roleid.
      APPEND ihistory.
    ENDLOOP.
    IF NOT ihistory[] IS INITIAL.
      MODIFY /psyng/history FROM TABLE ihistory. "#EC CI_IMUD_NESTED
    ENDIF.

    SORT itexts.
    DELETE ADJACENT DUPLICATES FROM itexts.

    IF overwrite = 'X'.
      CONCATENATE irolehdr-roleid 'HDR' INTO l_textname.
      DELETE FROM /psyng/texts                     "#EC CI_IMUD_NESTED
              WHERE textname = l_textname.
      CONCATENATE irolehdr-roleid 'DESC' INTO l_textname.
      DELETE FROM /psyng/texts                     "#EC CI_IMUD_NESTED
              WHERE textname = l_textname.
    ENDIF.

********************ADDED BY SGOTTAPU**********
    MODIFY /psyng/texts FROM TABLE itexts.     "#EC CI_IMUD_NESTED
********************ADDED BY SGOTTAPU**********

    IF sy-subrc NE 0.
      EXIT.
    ENDIF.
    role_txt_added = 'Y'.

    SORT iroletrans.
    DELETE ADJACENT DUPLICATES FROM iroletrans.

    IF overwrite = 'X'.

      DELETE FROM /psyng/roletrans           "#EC CI_IMUD_NESTED
             WHERE roleid = irolehdr-roleid.

    ENDIF.

    INSERT /psyng/roletrans FROM TABLE iroletrans. "#EC CI_IMUD_NESTED
    IF sy-subrc = 0.
      role_tc_added = 'Y'.

*  Document history for transactions addtions to role
      REFRESH ihistory.
      CLEAR ihistory-vrsio    .
      ihistory-tabname    = '/PSYNG/ROLETRANS'.
      ihistory-dtlfld     = 'TCODE'.
      ihistory-create_dat = sy-datum.
      ihistory-create_tim = sy-uzeit.
      ihistory-status     = 'I'.
      ihistory-create_usr = l_current_user. "sy-uname. C0700
      LOOP AT iroletrans.
        ihistory-hdrfld = iroletrans-roleid.
        ihistory-oldval = iroletrans-tcode.
        APPEND ihistory.
      ENDLOOP.
      SORT ihistory.
      DELETE ADJACENT DUPLICATES FROM ihistory.
      IF NOT ihistory[] IS INITIAL.
        MODIFY /psyng/history FROM TABLE ihistory.  "#EC CI_IMUD_NESTED
      ENDIF.

    ENDIF.

    COMMIT WORK.
  ENDFUNCTION.
