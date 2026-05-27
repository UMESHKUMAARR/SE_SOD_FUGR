FUNCTION /psyng/sw_custmer_audit_info.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  EXPORTING
*"     VALUE(E_AUDIT_INFO) TYPE  /PSYNG/SW_SYS_AUDIT_INFO
*"  TABLES
*"      ET_SOD_ST STRUCTURE  /PSYNG/SW_SOD_ST OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CUSTMER_AUDIT_INFO'.
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

  TABLES: usr02, /psyng/exelog, uscompany, /psyng/sw_sod_st.

  DATA:   yulock   TYPE x VALUE '80',     "Locked by incorrect login
          yusloc   TYPE x VALUE '40',     "Locked by Administrator
         yugloc   TYPE x VALUE '20'.     "Locked by global Administrator

   DATA: iusr02 LIKE usr02 OCCURS 0 WITH HEADER LINE,
        gt_uidn TYPE TABLE OF /psyng/bc_uidn WITH HEADER LINE.

  DATA: tvdia TYPE i,    "total valid dialog users
        tvndia TYPE i,   "total valid non-dialog users
        tvusers TYPE i,  "total valid users

        tldia TYPE i,    "total locked dialog users
        tlndia TYPE i,   "total locked non-dialog users
        tlusers TYPE i,  "total locked dialog users

        teusers TYPE i,  "total expired users
        tedia TYPE i,    "total expired dialog users
        tendia TYPE i,   "total expired non-dialog users

        tusers TYPE i,   "total users.
        tdia  TYPE i,    "total dialog
        tcomm TYPE i,    "total communication
        tsys  TYPE i,    "total system (background)
        tservice TYPE i, "total service
        tref  TYPE i,    "total reference

        comp LIKE uscompany-company,   "company name
        usname LIKE adrp-name_text.    "execution user name

  DATA: sodcount(100), " type n.
        l_uflagx TYPE x.


  RANGES: gt_bname FOR /psyng/bc_uidn-bname.
* BOC by RGUPTA on 07.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700
  SELECT uflag ustyp gltgv gltgb FROM usr02
      INTO CORRESPONDING FIELDS OF TABLE iusr02.
  LOOP AT iusr02.
    tusers = tusers + 1.
    CASE iusr02-ustyp.
      WHEN 'A'.
        tdia = tdia + 1.
      WHEN 'B'.
        tsys = tsys + 1.
      WHEN 'C'.
        tcomm = tcomm + 1.
      WHEN 'L'.
        tref = tref + 1.
      WHEN 'S'.
        tservice = tservice + 1.
    ENDCASE.
*--SF case 1405
    l_uflagx = iusr02-uflag."unicode
    IF l_uflagx O yusloc OR "locked by admin
       l_uflagx O yugloc.    "locked by CUA admin

*    IF iusr02-uflag GE 64.           "if user is locked
      tlusers = tlusers + 1.
      IF iusr02-ustyp = 'A'.
        tldia = tldia + 1.
      ELSE.
        tlndia = tlndia + 1.
      ENDIF.
    ELSE.                     "if user is not locked
      IF ( iusr02-gltgv LE sy-datum AND iusr02-gltgb GE sy-datum ) OR
         ( iusr02-gltgb IS INITIAL ).
        "user is valid.
        tvusers = tvusers + 1.
        IF iusr02-ustyp = 'A'.
          tvdia = tvdia + 1.
        ELSE.
          tvndia = tvndia + 1.
        ENDIF.
      ELSE.   "user is NOT valid
*        break ssangha.
        teusers = teusers + 1.
        IF iusr02-ustyp = 'A'.
          tedia = tedia + 1.
        ELSE.
          tendia = tendia + 1.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.

*--Company
  gt_bname-sign   = 'I'.
  gt_bname-option = 'EQ'.
  gt_bname-low    = l_current_user. "C0700
  APPEND gt_bname.
  CALL FUNCTION '/PSYNG/BC_011'
       TABLES
            it_bname = gt_bname
            et_uidn  = gt_uidn.

  SORT gt_uidn BY bname.
  READ TABLE gt_uidn INDEX 1.
  usname = gt_uidn-name_text.
  SELECT SINGLE company INTO comp FROM uscompany
                WHERE addrnumber = gt_uidn-addrnumber.

*---SOD stats
  SELECT * FROM /psyng/sw_sod_st."#EC CI_NOWHERE
    MOVE /psyng/sw_sod_st-sodcount TO sodcount .
    SHIFT sodcount LEFT DELETING LEADING '0' .
    et_sod_st-byobject = /psyng/sw_sod_st-byobject.
    et_sod_st-sodcount = sodcount.
    APPEND et_sod_st.
  ENDSELECT.

*---add info to export table
  e_audit_info-tuser   = tusers.
  e_audit_info-dusers  = tdia.
  e_audit_info-susers  = tsys.
  e_audit_info-cusers  = tcomm.
  e_audit_info-rusers  =  tref.
  e_audit_info-srusers = tservice.
  e_audit_info-vusers  = tvusers.
  e_audit_info-vdusers = tvdia.
  e_audit_info-vndusers = tvndia.
  e_audit_info-lusers   = tlusers.
  e_audit_info-ldusers  = tldia.
  e_audit_info-lndusers = tlndia.
  e_audit_info-ueusers  = teusers.
  e_audit_info-uedusers = tedia.
  e_audit_info-uendusers = tendia.
  e_audit_info-sys_id  = sy-sysid(3).
  e_audit_info-sys_client = sy-mandt.
  e_audit_info-company = comp.

ENDFUNCTION.
