FUNCTION /PSYNG/SW_017.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(CTU) LIKE  APQI-PUTACTIVE DEFAULT 'X'
*"     VALUE(MODE) LIKE  APQI-PUTACTIVE DEFAULT 'N'
*"     VALUE(UPDATE) LIKE  APQI-PUTACTIVE DEFAULT 'L'
*"     VALUE(GROUP) LIKE  APQI-GROUPID OPTIONAL
*"     VALUE(USER) LIKE  APQI-USERID OPTIONAL
*"     VALUE(KEEP) LIKE  APQI-QERASE OPTIONAL
*"     VALUE(HOLDDATE) LIKE  APQI-STARTDATE OPTIONAL
*"     VALUE(NODATA) LIKE  APQI-PUTACTIVE DEFAULT '/'
*"     VALUE(AGR_NAME_NEU_001) LIKE  BDCDATA-FVAL DEFAULT 'ZTEST_00'
*"     VALUE(GRUND_002) LIKE  BDCDATA-FVAL DEFAULT 'X'
*"     VALUE(AGR_NAME_003) LIKE  BDCDATA-FVAL DEFAULT 'ZTEST_00'
*"     VALUE(TEXT_004) LIKE  BDCDATA-FVAL DEFAULT 'test'
*"     VALUE(AGR_NAME_005) LIKE  BDCDATA-FVAL DEFAULT 'AG_REPORT'
*"     VALUE(TEXT_006) LIKE  BDCDATA-FVAL OPTIONAL
*"     VALUE(TARGET_SYS_007) LIKE  BDCDATA-FVAL DEFAULT 'USER SYSTEM'
*"  EXPORTING
*"     VALUE(SUBRC) LIKE  SYST-SUBRC
*"  TABLES
*"      MESSTAB STRUCTURE  BDCMSGCOLL OPTIONAL
*"----------------------------------------------------------------------

**subrc = 0.
**
**perform bdc_nodata      using NODATA.
**
**perform open_group      using GROUP USER KEEP HOLDDATE CTU.
**
**perform bdc_dynpro      using 'SAPLPRGN_TREE' '0100'.
**perform bdc_field       using 'BDC_CURSOR'
**                              'AGR_NAME_NEU'.
**perform bdc_field       using 'BDC_OKCODE'
**                              '=SANLE'.
**perform bdc_field       using 'AGR_NAME_NEU'
**                              AGR_NAME_NEU_001.
**perform bdc_field       using 'GRUND'
**                              GRUND_002.
**perform bdc_dynpro      using 'SAPLPRGN_TREE' '0300'.
**perform bdc_field       using 'BDC_CURSOR'
**                              'S_AGR_TEXTS-TEXT'.
**perform bdc_field       using 'BDC_OKCODE'
**                              '=TAB8'.
**perform bdc_field       using 'S_AGR_DEFINE-AGR_NAME'
**                              AGR_NAME_003.
**perform bdc_field       using 'S_AGR_TEXTS-TEXT'
**                              TEXT_004.
**perform bdc_dynpro      using 'SAPLSPO1' '0100'.
**perform bdc_field       using 'BDC_OKCODE'
**                              '=YES'.
**perform bdc_dynpro      using 'SAPLPRGN_TREE' '0200'.
**perform bdc_field       using 'BDC_CURSOR'
**                              'I_ACTGROUPS-AGR_NAME'.
**perform bdc_field       using 'BDC_OKCODE'
**                              '=IAGR'.
**perform bdc_field       using 'I_ACTGROUPS-AGR_NAME'
**                              AGR_NAME_005.
**perform bdc_field       using 'I_ACTGROUPS-TEXT'
**                              TEXT_006.
**perform bdc_field       using 'I_ACTGROUPS-TARGET_SYS'
**                              TARGET_SYS_007.
**perform bdc_field       using 'I_ACTGROUPS-ACTIVITY'
**                              TARGET_SYS_007.
**perform bdc_field       using 'BDC_OKCODE'
**                              '=YES'.
**perform bdc_transaction tables messtab
**using                         'PFCG'
**                              CTU
**                              MODE
**                              UPDATE.
**if sy-subrc <> 0.
**  subrc = sy-subrc.
**  exit.
**endif.
**
**perform close_group using     CTU.
**
**
**
**
**

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_017'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
ENDFUNCTION.
