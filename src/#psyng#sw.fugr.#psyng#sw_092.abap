FUNCTION /psyng/sw_092.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_BNAME) TYPE  XUBNAME DEFAULT SY-UNAME
*"     VALUE(I_REPID) TYPE  PROGNAME DEFAULT '/PSYNG/SECUWELL'
*"     REFERENCE(I_DYNR) TYPE  DYNPRONR DEFAULT '0106'
*"  TABLES
*"      ET_BUTTONS STRUCTURE  /PSYNG/SW_MOST_USED_REPORTS
*"----------------------------------------------------------------------
  TYPES : BEGIN OF type_report,
    repid LIKE sy-repid,
    uses   TYPE i,
    button_name TYPE scrfname,"button currently linked to this report
  END OF type_report.

  DATA : gt_reports TYPE TABLE OF type_report WITH HEADER LINE.
  DATA : l_value TYPE /psyng/swconfig-value,
         l_delete_report.
  DATA : l_date TYPE dats,
         l_found TYPE i,
         lt_d021t TYPE TABLE OF d021t WITH HEADER LINE.
  FIELD-SYMBOLS : <button> TYPE /psyng/sw_most_used_reports.
  l_date = sy-datum - 31.
  SELECT repid COUNT(*) AS uses                         "#EC CI_NOFIELD
                                                        "#EC CI_NOFIRST
  INTO TABLE gt_reports
  FROM /psyng/exelog WHERE
    uname = i_bname AND
    datum >= l_date
    GROUP by repid.


*--- Check Config Param
    se_config_param 'SW_ROLES_POS_USRASGN' l_value.
  if l_value = 'Y'.
    CLEAR l_delete_report.
  ELSE.
* -- Delete Flag
    l_delete_report = 'X'.
  ENDIF.



  SORT gt_reports BY uses DESCENDING.
  IF i_repid = '/PSYNG/SECUWELL' AND i_dynr = '0106'.
*--Only reports that are called from the monitoring screen of /PSYNG/SW
    LOOP AT gt_reports.
*  --Only 5 most used reports
      IF l_found GE 5 .
        EXIT.
      ENDIF.
      CLEAR et_buttons.
      CASE gt_reports-repid.
        WHEN '/PSYNG/SODREPORT_SYS_WIDE_ORG'.
          et_buttons-fldn    = 'SOD1'.
          et_buttons-ok_code = 'SUMRPT'.
        WHEN '/PSYNG/SOD_SYSWIDE_BYROLE'.
          et_buttons-fldn    = 'SOD3'.
          et_buttons-ok_code = 'BYROLE'.
        WHEN '/PSYNG/SW_104'.
          et_buttons-fldn    = 'SOD4'.
          et_buttons-ok_code = 'ADVSIM'.
        WHEN '/PSYNG/SW_SOD_SUM_RP'.
          et_buttons-fldn    = 'SOD5'.
          et_buttons-ok_code = 'SODSMRP'.
        WHEN '/PSYNG/SW_099'.
          et_buttons-fldn    = 'SOD6'.
          et_buttons-ok_code = 'SODCRITAUTH'.
        WHEN '/PSYNG/SW_095'.
          et_buttons-fldn    = 'SOD7'.
          et_buttons-ok_code = 'FUNCREP'.
        WHEN '/PSYNG/CRI_TCODE_LIST'.
          et_buttons-fldn    = 'CRI1'.
          et_buttons-ok_code = 'CRITICAL'.
        WHEN '/PSYNG/SW_CRIT_AUTHS'.
          et_buttons-fldn    = 'CRI2'.
          et_buttons-ok_code = 'SAUTHMON'.
        WHEN '/PSYNG/SW_CRIT_AUTHS_BYROLE'.
          et_buttons-fldn    = 'CRI3'.
          et_buttons-ok_code = 'SAUTHMONROLE'.
        WHEN '/PSYNG/SW_030'.
          et_buttons-fldn    = 'CRI4'.
          et_buttons-ok_code = 'CRIPROF'.
        WHEN '/PSYNG/SW_031'.
          et_buttons-fldn    = 'CRI5'.
          et_buttons-ok_code = 'CRIROLES'.
        WHEN '/PSYNG/SODREPORT_BY_HISTORY'.
          et_buttons-fldn    = 'HIS1'.
          et_buttons-ok_code = 'BYHIST'.
        WHEN '/PSYNG/SW_082' OR '/PSYNG/BC_USRHIS_05'.
          et_buttons-fldn    = 'HIS2'.
          et_buttons-ok_code = 'ROLEEFF'.
        WHEN '/PSYNG/SW_040'.
          et_buttons-fldn    = 'HIS3'.
          et_buttons-ok_code = 'EXEHIST'.
        WHEN '/PSYNG/USER_EXE_TCODE'.
          et_buttons-fldn    = 'HIS4'.
          et_buttons-ok_code = 'TRANSUM'.
        WHEN '/PSYNG/SW_017'.
          et_buttons-fldn    = 'HIS5'.
          et_buttons-ok_code = 'VWHIST'.
        WHEN '/PSYNG/SW_102'.
          et_buttons-fldn    = 'MIT1'.
          et_buttons-ok_code = 'MITHDRRPT'.
        WHEN '/PSYNG/SW_003'.
          et_buttons-fldn    = 'MIT2'.
          et_buttons-ok_code = 'MCREPO'.
        WHEN '/PSYNG/SW_105'.
          et_buttons-fldn    = 'MIT3'.
          et_buttons-ok_code = 'MCREPOADV'.
        WHEN '/PSYNG/SW_043'.
          et_buttons-fldn    = 'MIT4'.
          et_buttons-ok_code = 'AUDIT'.
        WHEN '/PSYNG/SOD_MANG_REPO'.
          et_buttons-fldn    = 'MGM1'.
          et_buttons-ok_code = 'MGRPH'.
        WHEN '/PSYNG/SW_033'.
          et_buttons-fldn    = 'MGM2'.
          et_buttons-ok_code = 'GRUGRP'.
        WHEN '/PSYNG/SW_034'.
          et_buttons-fldn    = 'MGM3'.
          et_buttons-ok_code = 'GRAPAR'.
        WHEN '/PSYNG/SW_035'.
          et_buttons-fldn    = 'MGM4'.
          et_buttons-ok_code = 'GRPRAR'.
        WHEN '/PSYNG/USER_LOGON_MONITOR'.
          et_buttons-fldn    = 'USR1'.
          et_buttons-ok_code = 'INACT'.
        WHEN '/PSYNG/SW_015'.
          et_buttons-fldn    = 'USR2'.
          et_buttons-ok_code = 'BKJOBU'.
        WHEN '/PSYNG/SW_016'.
          et_buttons-fldn    = 'USR3'.
          et_buttons-ok_code = 'MULTU'.
        WHEN '/PSYNG/SW_032'.
          et_buttons-fldn    = 'USR4'.
          et_buttons-ok_code = 'NEWUID'.
        WHEN '/PSYNG/SODMATRIX_OUTPUT'.
          et_buttons-fldn    = 'DOC1'.
          et_buttons-ok_code = 'LMTRX'.
        WHEN '/PSYNG/SW_106'.
          et_buttons-fldn    = 'DOC2'.
          et_buttons-ok_code = 'CADET'.
        WHEN '/PSYNG/SW_022'.
          et_buttons-fldn    = 'DOC3'.
          et_buttons-ok_code = 'RLERPT'.
        WHEN '/PSYNG/SW_023'.
          et_buttons-fldn    = 'DOC4'.
          et_buttons-ok_code = 'PSNRPT'.
        WHEN '/PSYNG/SW_024'.
          et_buttons-fldn    = 'DOC5'.
          et_buttons-ok_code = 'USRPT'.
        WHEN '/PSYNG/CNFLTRPT'.
          et_buttons-fldn    = 'DOC6'.
          et_buttons-ok_code = 'CNFLTRPT'.
        WHEN '/PSYNG/SUMRYRPT'.
          et_buttons-fldn    = 'DOC7'.
          et_buttons-ok_code = 'SUMRYRPT'.
        when '/PSYNG/SW_137'."Display Stored User Results
          et_buttons-fldn    = 'SW_137'.
          et_buttons-ok_code = 'SW_137'.
        when '/PSYNG/SW_138'."Manage Stored User Results
          et_buttons-fldn    = 'SW_138'.
          et_buttons-ok_code = 'SW_138'.
        when '/PSYNG/SW_140'."Store User SOD Results
          et_buttons-fldn    = 'SW_140'.
          et_buttons-ok_code = 'SW_140'.
        when '/PSYNG/SW_150'. "Display Stored Role Results
          et_buttons-fldn    = 'SW_150'.
          et_buttons-ok_code = 'SW_150'.
        when '/PSYNG/SW_149'."Manage  stored role results
          et_buttons-fldn    = 'SW_149'.
          et_buttons-ok_code = 'SW_149'.
        when '/PSYNG/SW_148'."Store role results
          et_buttons-fldn    = 'SW_148'.
          et_buttons-ok_code = 'SW_148'.
      ENDCASE.
      IF NOT et_buttons IS INITIAL.
        IF l_delete_report = 'X'.
          CHECK NOT et_buttons-fldn = 'DOC3' AND
                NOT et_buttons-fldn = 'DOC4' AND
                NOT et_buttons-fldn = 'DOC5' AND
                NOT et_buttons-fldn = 'DOC6' AND
                NOT et_buttons-fldn = 'DOC7'.
        ENDIF.


        ADD 1 TO l_found.
        et_buttons-uses = gt_reports-uses.
        APPEND et_buttons.
      ENDIF.
    ENDLOOP.
  ENDIF.
  CHECK NOT et_buttons[] IS INITIAL.

  SELECT fldn dtxt FROM d021t
  INTO CORRESPONDING FIELDS OF TABLE lt_d021t
  FOR ALL ENTRIES IN et_buttons WHERE
   prog = i_repid AND
   dynr = i_dynr AND
   fldn = et_buttons-fldn AND
   lang = sy-langu.
  CHECK NOT et_buttons[] IS INITIAL.
  LOOP AT et_buttons ASSIGNING <button>.
    READ TABLE lt_d021t WITH KEY fldn = <button>-fldn.
    IF sy-subrc = 0.
      <button>-button_text = lt_d021t-dtxt.
    ELSE.
*--default to english
      SELECT SINGLE  dtxt FROM d021t                 "#EC CI_SEL_NESTED
      INTO <button>-button_text
      WHERE
       prog = i_repid AND
       dynr = i_dynr AND
       fldn = <button>-fldn AND
       lang = 'EN'.
    ENDIF.
  ENDLOOP.
ENDFUNCTION.
