*----------------------------------------------------------------------*
* FUNCTION: /psyng/sw_user_info.                                       *
* AUTHOR:   Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
FUNCTION /psyng/sw_user_info.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(ENHANCED_SCANTABLE) TYPE  /PSYNG/BAPIFLAGX DEFAULT ''
*"     VALUE(I_NAME_ONLY) TYPE  FLAG DEFAULT ''
*"     VALUE(I_MR_COMPANY) TYPE  FLAG DEFAULT ''
*"     VALUE(I_MR_DEPARTMENT) TYPE  FLAG DEFAULT ''
*"     VALUE(I_CENTRAL_UID) TYPE  FLAG DEFAULT ''
*"     VALUE(I_SODCOUNDT) TYPE  FLAG DEFAULT ''
*"  TABLES
*"      SW_UINFO STRUCTURE  /PSYNG/SW_UINFO
*"      IUSGRPT STRUCTURE  USGRPT OPTIONAL
*"      FUNCTION STRUCTURE  /PSYNG/FUNCTION OPTIONAL
*"      SWAUDHDR STRUCTURE  /PSYNG/SWAUDHDR OPTIONAL
*"      CONFLICT STRUCTURE  /PSYNG/CONFLICT OPTIONAL
*"      KOSTL_RESP STRUCTURE  /PSYNG/SW_KOSTL_RESP OPTIONAL
*"      CUSCON STRUCTURE  /PSYNG/SW_CUSCON OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_USER_INFO'.
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
  CONSTANTS: lc_erp_class(16) TYPE c VALUE '/PSYNG/SW_CL_ERP',
             lc_method(17)    TYPE c VALUE 'GET_USERS_FROM_HR'.

  DATA: username TYPE STANDARD TABLE OF /psyng/bc_userid_name
        WITH HEADER LINE,
        iusr02 TYPE STANDARD TABLE OF usr02 WITH HEADER LINE.
  DATA: ccfm TYPE /psyng/param_value,
        lo_classtype TYPE REF TO cl_abap_typedescr,
        lf_use_erp   TYPE /psyng/bapiflagx,
        ls_bname     TYPE /psyng/range_bname,
        lt_bname     TYPE /psyng/range_bname_t,
        lt_user      TYPE /psyng/hr_user_t,
        ls_user      TYPE /psyng/hr_user,
        g_scantable  TYPE tabname,
        l_cnt        type I,
        lf_exit      type flag.
  DATA : lf_no_email TYPE flag.

*--Special scenario : if there's only 1 record,
*  and it contains BNAME = '000000000000'
*  exit early because we're not analyzing a real user
  describe table SW_UINFO lines l_cnt.
  if l_cnt = 1.
    read table SW_UINFO with key BNAME = '000000000000'
    transporting no fields.
    if sy-subrc = 0.
      lf_exit = 'X'.
    endif.
  endif.
  check lf_exit is initial.


  lf_no_email = i_name_only.

* Determine whether or not to use ERP tables
  CALL METHOD cl_abap_classdescr=>describe_by_name
    EXPORTING
      p_name         = lc_erp_class
    RECEIVING
      p_descr_ref    = lo_classtype
     EXCEPTIONS
       type_not_found = 1
       OTHERS         = 2.

  IF sy-subrc = 0.
    lf_use_erp = 'X'.
  ENDIF.

* Determine which scan table to use
  IF enhanced_scantable = 'X'.
    g_scantable = '/PSYNG/ENHSCANDT'.
  ELSE.
    g_scantable = '/PSYNG/SYSCANDT'.
  ENDIF.

  ls_bname-sign   = 'I'.
  ls_bname-option = 'EQ'.
  IF sw_uinfo[] IS INITIAL.
    SELECT                                "#EC CI_SEL_NESTED
    bname class uflag trdat gltgb gltgv ustyp FROM usr02
           INTO CORRESPONDING FIELDS OF TABLE sw_uinfo.
    SELECT bname FROM usr02               "#EC CI_SEL_NESTED
           INTO CORRESPONDING FIELDS OF TABLE username.
    SORT: sw_uinfo BY bname, username BY bname.
    loop at sw_uinfo.
      ls_bname-low = sw_uinfo-bname.
      APPEND ls_bname TO lt_bname.
    endloop.
  ELSE.
    SELECT bname class uflag trdat gltgb gltgv ustyp "#EC CI_SEL_NESTED
    FROM usr02
           INTO CORRESPONDING FIELDS OF TABLE iusr02
           FOR ALL ENTRIES IN sw_uinfo WHERE bname = sw_uinfo-bname.

    SORT iusr02 BY bname.

    LOOP AT sw_uinfo.
      READ TABLE iusr02 WITH KEY bname = sw_uinfo-bname BINARY SEARCH.
      CHECK sy-subrc = 0.
      MOVE-CORRESPONDING iusr02 TO sw_uinfo.
      MODIFY sw_uinfo.
      MOVE-CORRESPONDING iusr02 TO username.
      APPEND username.

      ls_bname-low = sw_uinfo-bname.
      APPEND ls_bname TO lt_bname.
    ENDLOOP.
  ENDIF.

*--DHORIONS 2012/02/01 : If no valid users were in sw_uinfo, there is no
*  need to read the user names
  IF NOT username[] IS INITIAL.
    CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
         EXPORTING
              no_email = i_name_only
         TABLES
              username = username.
  ENDIF.


  SORT sw_uinfo BY bname.
  SORT username BY bname.
  SORT iusr02 BY bname.
  LOOP AT sw_uinfo.
    READ TABLE username WITH KEY bname = sw_uinfo-bname BINARY SEARCH.
    IF sy-subrc = 0.
      MOVE-CORRESPONDING username TO sw_uinfo.
      sw_uinfo-name_text = username-name_full.
      MODIFY sw_uinfo.
    ELSE.
      READ TABLE iusr02 WITH KEY bname = sw_uinfo-bname BINARY SEARCH.
      IF sy-subrc <> 0 AND NOT  sw_uinfo-bname = '000000000000'.

        DELETE sw_uinfo.
      ENDIF.
    ENDIF.


  ENDLOOP.
  REFRESH: username.
*--management reporting information
  DATA : ls_fmname    TYPE rs38l_fnam.

*--If company information is requested (For management Reporting)
* Use correct function module to determine company
  IF i_mr_company = 'X'.
      se_config_param 'SW_MGMT_COMPANY_FM' ls_fmname.
      if not ls_fmname is initial.
      CALL FUNCTION 'FUNCTION_EXISTS'
           EXPORTING
                funcname           = ls_fmname
           EXCEPTIONS
                function_not_exist = 1
                OTHERS             = 2.
      IF sy-subrc = 0.
        CALL FUNCTION ls_fmname
             TABLES
                  it_sw_uinfo = sw_uinfo
             EXCEPTIONS
                  OTHERS      = 1.
        IF sy-subrc <> 0.
          MESSAGE s113(/psyng/sw) WITH
          'Cannot determine company with FM '
          ls_fmname.

        ENDIF.
      ELSE.
        MESSAGE s113(/psyng/sw) WITH
        'Cannot determine company with FM '
        ls_fmname '. FM doesn''t exist'.

      ENDIF.
    ENDIF.
  ENDIF.

*--If department information is requested (For management Reporting)
* Use correct function module to determine department
  IF i_mr_department = 'X'.
    se_config_param 'SW_MGMT_DEPARTMENT_F' ls_fmname.
    CALL FUNCTION 'FUNCTION_EXISTS'
         EXPORTING
              funcname           = ls_fmname
         EXCEPTIONS
              function_not_exist = 1
              OTHERS             = 2.
    IF sy-subrc = 0.
      CALL FUNCTION ls_fmname
           TABLES
                it_sw_uinfo = sw_uinfo
           EXCEPTIONS
                OTHERS      = 1.
      IF sy-subrc <> 0.
        MESSAGE s113(/psyng/sw) WITH
        'Cannot determine department with FM '
        ls_fmname.

      ENDIF.
    ELSE.
      MESSAGE s113(/psyng/sw) WITH
      'Cannot determine departmentwith FM '
      ls_fmname '. FM doesn''t exist'.

    ENDIF.
  ENDIF.
*--If Central User ID information is requested
* Use correct function module to determine department
  IF i_central_uid = 'X'.
    se_config_param 'SW_CENTRAL_USR_FM' ls_fmname.
    CALL FUNCTION 'FUNCTION_EXISTS'
         EXPORTING
              funcname           = ls_fmname
         EXCEPTIONS
              function_not_exist = 1
              OTHERS             = 2.
    IF sy-subrc = 0.
      CALL FUNCTION ls_fmname
           TABLES
                it_sw_uinfo = sw_uinfo
           EXCEPTIONS
                OTHERS      = 1.
      IF sy-subrc <> 0.
        MESSAGE s113(/psyng/sw) WITH
        'Cannot determine Cental User IDt with FM '
        ls_fmname.

      ENDIF.
    ELSE.
      MESSAGE s113(/psyng/sw) WITH
      'Cannot determine Cental User ID with FM '
      ls_fmname '. FM doesn''t exist'.
    ENDIF.
  ENDIF.
*--If only names were requested, do not execute rest of code
  CHECK NOT i_name_only = 'X' OR i_sodcoundt = 'X'.

  IF NOT i_name_only = 'X'.
    IF lf_use_erp = 'X'.
*   Get data from HR tables
      CALL METHOD (lc_erp_class)=>(lc_method)
        EXPORTING
          i_begda  = sy-datum
          i_endda  = sy-datum
          it_bname = lt_bname
        IMPORTING
          et_user = lt_user.

      SORT lt_user BY bname.
    ENDIF.
  ENDIF.
  FREE lt_bname.

  DATA : BEGIN OF l_scancount ,
            bname TYPE xubname,
            count TYPE i,
         END OF l_scancount.
  DATA : BEGIN OF l_scan_none ,
            bname TYPE xubname,
            count TYPE i,
         END OF l_scan_none.
  DATA : BEGIN OF l_scan_first ,
            bname TYPE xubname,
            date  TYPE dats,
         END OF l_scan_first.
  DATA : lt_scan_count LIKE HASHED TABLE OF l_scancount
         WITH UNIQUE KEY bname,
         lt_scan_none  LIKE HASHED TABLE OF l_scan_none
         WITH UNIQUE KEY bname WITH HEADER LINE,
         lt_scan_first LIKE HASHED TABLE OF l_scan_first
         WITH HEADER LINE
         WITH UNIQUE KEY bname.

  IF i_name_only <> 'X' OR i_sodcoundt = 'X'.
*  Is there any entry for user in /psyng/syscandt?
    SELECT bname COUNT( * ) AS count  "#EC CI_SEL_NESTED
    FROM (g_scantable)
           INTO CORRESPONDING FIELDS OF TABLE lt_scan_count
           WHERE vrsio = vrsio
           GROUP by bname.
*  Does the user have no conficts?
    SELECT bname COUNT( DISTINCT conid )  AS count "#EC CI_SEL_NESTED
    FROM (g_scantable)
           INTO CORRESPONDING FIELDS OF TABLE lt_scan_none
           WHERE vrsio = vrsio
           AND   conid <> 'NONE'
           GROUP by bname.
*  Get the earliest scan date of user
    SELECT bname MIN( scandate ) AS date   "#EC CI_SEL_NESTED
    FROM (g_scantable)
           INTO CORRESPONDING FIELDS OF TABLE lt_scan_first
           WHERE vrsio = vrsio
           GROUP by bname.
  ENDIF.

  SORT lt_scan_none.
  SORT lt_scan_first.

  LOOP AT sw_uinfo.
    IF i_name_only <> 'X'.
      IF lf_use_erp = 'X'.
        READ TABLE lt_user INTO ls_user WITH KEY bname = sw_uinfo-bname
                   BINARY SEARCH.

        IF sy-subrc = 0.
          sw_uinfo-pernr = ls_user-pernr.
          sw_uinfo-persa = ls_user-werks.
          sw_uinfo-kostl = ls_user-kostl.
          MODIFY sw_uinfo TRANSPORTING pernr persa kostl.
        ENDIF.
      ENDIF.
    ENDIF.
    IF i_name_only <> 'X' OR i_sodcoundt = 'X'.
*Is there any entry for user in /psyng/syscandt?
      READ TABLE lt_scan_count WITH TABLE KEY bname = sw_uinfo-bname
      TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.   "if no details found
       sw_uinfo-sodscandate = '18010101'. "SOD analysis not run for user
        MODIFY sw_uinfo.  "CLEAR sw_uinfo.
        CONTINUE.
      ENDIF.


*Does the user have no conficts?
      READ TABLE lt_scan_none WITH TABLE KEY bname = sw_uinfo-bname.
      IF sy-subrc = 0.
        sw_uinfo-sodcount = lt_scan_none-count.
      ELSE.
        CLEAR sw_uinfo-sodcount.
      ENDIF.
*Get the earliest scan date of user
      READ TABLE lt_scan_first WITH TABLE KEY bname = sw_uinfo-bname.
      IF sy-subrc = 0.
        sw_uinfo-sodscandate = lt_scan_first-date.
      ELSE.
        sw_uinfo-sodscandate = '18010101'.
      ENDIF.
      MODIFY sw_uinfo.  "CLEAR sw_uinfo.
    ENDIF.
  ENDLOOP.  "sw_uinfo.

  IF iusgrpt IS REQUESTED.
    SELECT DISTINCT usergroup text FROM usgrpt  "#EC CI_SEL_NESTED
           INTO CORRESPONDING FIELDS OF TABLE iusgrpt
           WHERE sprsl = sy-langu
           ORDER BY usergroup.
  ENDIF.
  IF function IS REQUESTED.
    SELECT DISTINCT function description  "#EC CI_SEL_NESTED
    FROM /psyng/function
         INTO CORRESPONDING FIELDS OF TABLE function
         WHERE vrsio = vrsio
         ORDER BY function.
  ENDIF.
  IF swaudhdr IS REQUESTED.
    SELECT swaudid description      "#EC CI_SEL_NESTED
    FROM /psyng/swaudhdr
           INTO CORRESPONDING FIELDS OF TABLE swaudhdr
           WHERE vrsio = vrsio
           ORDER BY swaudid.
  ENDIF.
  IF conflict IS REQUESTED.
   SELECT conid description owner imp busarea risk "#EC CI_SEL_NESTED
   FROM /psyng/conflict
           INTO CORRESPONDING FIELDS OF TABLE conflict
           WHERE inactive EQ space
           AND vrsio = vrsio
           ORDER BY conid.
  ENDIF.
  IF cuscon IS REQUESTED.
    SELECT conid cdesc imp busarea "#EC CI_SEL_NESTED
    FROM /psyng/sw_cuscon
           INTO CORRESPONDING FIELDS OF TABLE cuscon
           WHERE inactive EQ space AND vrsio = vrsio
           ORDER BY conid.
  ENDIF.
*If cost center responsibile person is identified
  IF kostl_resp IS REQUESTED.
    CLEAR: ccfm.
    se_config_param 'SW_CC_RESP_FM' ccfm.
    IF NOT ccfm IS INITIAL.
      CALL FUNCTION ccfm
           TABLES
                kostl_resp = kostl_resp.
    ENDIF.
  ENDIF.
ENDFUNCTION.
