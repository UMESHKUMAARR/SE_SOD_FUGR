FUNCTION /psyng/sw_create_swrole_pfcg.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(PAGR_NAME) LIKE  AGR_DEFINE-AGR_NAME
*"     REFERENCE(PROLEID) LIKE  /PSYNG/ROLEHDR-ROLEID
*"     REFERENCE(OVRWRTE) OPTIONAL
*"  EXPORTING
*"     REFERENCE(ROLEID_CREATED)
*"     REFERENCE(ROLEIDEXISTS)
*"     REFERENCE(ROLE_HDR_CREATED)
*"     REFERENCE(ROLE_TC_ADDED)
*"     REFERENCE(ROLE_TXT_ADDED)
*"  EXCEPTIONS
*"      SW_ROLE_EXISTS
*"      NOT_AUTHORIZED
*"----------------------------------------------------------------------

  DATA: iagr_define TYPE STANDARD TABLE OF agr_define WITH HEADER LINE.
  DATA: iagr_tcodes TYPE STANDARD TABLE OF agr_tcodes WITH HEADER LINE.
  DATA: iagr_texts TYPE STANDARD TABLE OF agr_texts WITH HEADER LINE.

  DATA: irolehdr TYPE STANDARD TABLE OF /psyng/rolehdr WITH HEADER LINE.
  DATA: iroletrans TYPE STANDARD TABLE OF /psyng/roletrans
        WITH HEADER LINE.
  DATA: itexts TYPE STANDARD TABLE OF /psyng/texts WITH HEADER LINE.
  DATA: ihistory TYPE STANDARD TABLE OF /psyng/history WITH HEADER LINE.
* BOC by RGUPTA on 07.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700
  roleid_created = 'N'.
*********tsen insert on 14-01-09****************
  IF OVRWRTE = ' '.
***********************************************
 CALL FUNCTION '/PSYNG/SW_CHECK_SWROLE_EXISTS'
       EXPORTING
            proleid = proleid
       IMPORTING
            exists  = roleidexists.

  IF roleidexists = 'Y'.  "check Role ID doesn't exist already
    RAISE sw_role_exists.
  ENDIF.
********tsen insert on 14-01-09************
  ENDIF.
*******************************************
  AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
           ID 'ACTVT' FIELD '01'
           ID 'Y&SW_ROLID' FIELD proleid.
  IF sy-subrc NE 0.
    RAISE not_authorized.
  ENDIF.

  CLEAR roleidexists.

  SELECT * FROM agr_define INTO TABLE iagr_define
           WHERE agr_name = pagr_name.
*roles in menu but not in profile can not be executed by the user
*  SELECT * FROM agr_tcodes INTO TABLE iagr_tcodes
*           WHERE agr_name = pagr_name.

*  perform populate_S_TCODE.
  CALL FUNCTION '/PSYNG/SW_POPULATE_S_TCODE'
       EXPORTING
            p_agrname   = pagr_name
       TABLES
            iagr_tcodes = iagr_tcodes.

  SELECT * FROM agr_texts INTO TABLE iagr_texts
           WHERE agr_name = pagr_name AND
                 spras    = sy-langu.

  SORT: iagr_define, iagr_tcodes, iagr_texts.

  LOOP AT iagr_define.
    irolehdr-roleid = proleid.
    READ TABLE iagr_texts WITH KEY agr_name = iagr_define-agr_name
                                   spras = sy-langu
                                   line = '00000'.
    IF sy-subrc = 0.   "role description found
      irolehdr-description = iagr_texts-text.
    ELSE.
      irolehdr-description = text-013.
    ENDIF.
    irolehdr-create_usr = l_current_user. "sy-uname. C0700
    irolehdr-create_dat = sy-datum.
    irolehdr-create_tim = sy-uzeit.
    irolehdr-saptechname = iagr_define-agr_name.
    APPEND irolehdr.
  ENDLOOP.
*************tsen insert on 14-01-09******************
  IF OVRWRTE = 'X'.
  MODIFY /psyng/rolehdr FROM TABLE irolehdr. "#EC CI_IMUD_NESTED
  ELSE.
  INSERT /psyng/rolehdr FROM TABLE irolehdr. "#EC CI_IMUD_NESTED
  ENDIF.
**********************************************
 IF sy-subrc NE 0.
    EXIT.
  ENDIF.
  roleid_created = 'Y'.
  role_hdr_created = 'Y'.

*Document history of role creation
  CLEAR ihistory.
  REFRESH ihistory.
  clear ihistory-vrsio.
  ihistory-tabname = '/PSYNG/ROLEHDR'.
  ihistory-hdrfld = 'ROLEID'.
  ihistory-oldval = proleid.
  ihistory-create_dat = sy-datum.
  ihistory-create_tim = sy-uzeit.
  ihistory-status = 'I'.
  ihistory-create_usr = l_current_user. "sy-uname. C0700
  APPEND ihistory.
***********Added by sgottapu***********
  SORT ihistory.
  DELETE ADJACENT DUPLICATES FROM ihistory.
  MODIFY /psyng/history FROM TABLE ihistory.  "#EC CI_IMUD_NESTED
***********Added by sgottapu***********

  clear itexts-vrsio.
  itexts-object = 'R'.
  CONCATENATE proleid 'HDR' INTO itexts-textname.
  LOOP AT iagr_texts.
    CHECK iagr_texts-line NE '00000'.
    itexts-spras = iagr_texts-spras.
    itexts-line = iagr_texts-line.
    itexts-text = iagr_texts-text.
    APPEND itexts.
  ENDLOOP.
  SORT itexts.
  DELETE ADJACENT DUPLICATES FROM itexts.
****************tsen insert on 14-01-09******************************
  DELETE FROM /PSYNG/TEXTS                  "#EC CI_IMUD_NESTED
        WHERE TEXTNAME = ITEXTS-TEXTNAME and
              object   = itexts-object.
******************************************************
  INSERT /psyng/texts FROM TABLE itexts.   "#EC CI_IMUD_NESTED
  IF sy-subrc EQ 0.
    role_txt_added = 'Y'.
  ENDIF.

  iroletrans-roleid = proleid.
  REFRESH ihistory.
  LOOP AT iagr_tcodes.
    iroletrans-tcode = iagr_tcodes-tcode.
    APPEND iroletrans.
*Document history for transactions addtions to role
    CLEAR ihistory.
    clear ihistory-vrsio  .
    ihistory-tabname = '/PSYNG/ROLETRANS'.
    ihistory-hdrfld = proleid.
    ihistory-dtlfld = 'TCODE'.
    ihistory-oldval = iagr_tcodes-tcode.
    ihistory-create_dat = sy-datum.
    ihistory-create_tim = sy-uzeit.
    ihistory-status = 'I'.
    ihistory-create_usr = l_current_user. "sy-uname. C0700
    APPEND ihistory.
  ENDLOOP.
  SORT iroletrans.
  DELETE ADJACENT DUPLICATES FROM iroletrans.
*********************tsen insert on 14-01-09**************
DELETE FROM /PSYNG/ROLETRANS              "#EC CI_IMUD_NESTED
         WHERE ROLEID =  PROLEID.
**********************************************************
  INSERT /psyng/roletrans FROM TABLE iroletrans.
  IF sy-subrc = 0.
    role_tc_added = 'Y'.
    SORT ihistory.
    DELETE ADJACENT DUPLICATES FROM ihistory.
    IF NOT ihistory[] IS INITIAL.
***********Added by sgottapu***********
      MODIFY /psyng/history FROM TABLE ihistory. "#EC CI_IMUD_NESTED
***********Added by sgottapu***********
    ENDIF.
  ENDIF.

  COMMIT WORK.
ENDFUNCTION.
