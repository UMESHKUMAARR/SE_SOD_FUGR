FUNCTION /PSYNG/SW_018.
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
*"     VALUE(AGR_NAME_NEU_001) LIKE  BDCDATA-FVAL DEFAULT 'ZTEST_BDC'
*"     VALUE(GRUND_002) LIKE  BDCDATA-FVAL DEFAULT 'X'
*"     VALUE(AGR_NAME_003) LIKE  BDCDATA-FVAL DEFAULT 'ZTEST_BDC'
*"     VALUE(TEXT_004) LIKE  BDCDATA-FVAL DEFAULT 'Test Bdc Module'
*"  EXPORTING
*"     VALUE(SUBRC) LIKE  SYST-SUBRC
*"  TABLES
*"      MESSTAB STRUCTURE  BDCMSGCOLL OPTIONAL
*"      TEXT STRUCTURE  AGR_DEFINE OPTIONAL
*"      TEXT2 STRUCTURE  AGR_TEXTS OPTIONAL
*"----------------------------------------------------------------------
*DATA : fnam LIKE bdcdata-fnam,
*       btext_id LIKE bdcdata-fval,
*       index(2),
*       ctu_params LIKE ctu_params,
*       tabix TYPE sy-tabix.
*
*DATA : BEGIN OF insert_agr_tabs OCCURS 0.
*         INCLUDE STRUCTURE ztest.
*DATA : END OF insert_agr_tabs.
*
*DATA : wa LIKE agr_texts.
*DATA : BEGIN OF ITAB1 OCCURS 0.
*       INCLUDE STRUCTURE AGR_TEXTS.
*DATA : END OF ITAB1.
*CLEAR wa.
*REFRESH insert_agr_tabs.
*
*subrc = 0.
*MOVE AGR_NAME_NEU_001 TO btext_id.
*
**LOOP AT text1.
**  insert_agr_tabs-agr_name = text1-agr_name.
**  insert_agr_tabs-text = SPACE.
**  insert_agr_tabs-target_sys = SPACE.
**  insert_agr_tabs-customized = 'X'.
***  INSERT wa INTO TABLE insert_agr_tabs.
**  append insert_agr_tabs.
***  CLEAR wa.
**ENDLOOP.
**
**LOOP AT TEXT2.
**ITAB1-AGR_NAME = TEXT2-AGR_NAME.
**APPEND ITAB1.
**ENDLOOP.
**
*perform bdc_nodata      using NODATA.
*
*perform open_group      using GROUP USER KEEP HOLDDATE CTU.
*
*perform bdc_dynpro      using 'SAPLPRGN_TREE' '0100'.
*perform bdc_field       using 'BDC_CURSOR'
*                              'AGR_NAME_NEU'.
*perform bdc_field       using 'BDC_OKCODE'
*                              '=SANLE'.
*perform bdc_field       using 'AGR_NAME_NEU'
*                              AGR_NAME_NEU_001.
*perform bdc_field       using 'GRUND'
*                              GRUND_002.
*perform bdc_dynpro      using 'SAPLPRGN_TREE' '0300'.
*perform bdc_field       using 'BDC_CURSOR'
*                              'S_AGR_TEXTS-TEXT'.
*perform bdc_field       using 'BDC_OKCODE'
*                              '=TAB8'.
*perform bdc_field       using 'S_AGR_DEFINE-AGR_NAME'
*                              AGR_NAME_003.
*perform bdc_field       using 'S_AGR_TEXTS-TEXT'
*                              TEXT_004.
*perform bdc_dynpro      using 'SAPLSPO1' '0100'.
*perform bdc_field       using 'BDC_OKCODE'
*                              '=YES'.
*
*********************************************************************
**CALL FUNCTION 'PRGN_ACTGRP_MULTIPLE_F4'
** EXPORTING
***   ONLY_COLLECTIVE_ACTGROUPS       =
**   ONLY_SINGLE_ACTGROUPS           = 'X'
***   SHOW_POPUP                      = ' '
***   TARGET_SYSTEM                   = ' '
***   ROLE                              =
***   DISPLAY                         = ' '
** TABLES
**   AGR_TAB                         = insert_agr_tabs .
*perform bdc_dynpro      using 'SAPLPRGN_TREE' '0310'.
**perform bdc_field       using 'BDC_OKCODE'
**                              '=TAB8'.
*perform bdc_field       using 'BDC_CURSOR'
*                              'S_AGR_TEXTS-TEXT'.
*perform bdc_field       using 'BDC_OKCODE'
*                              '=IAGR'.
**perform bdc_field       using 'I_ACTGROUPS-AGR_NAME'
**                              'S_AGR_TEXTS-TEXT'.
*
**CALL FUNCTION 'PRGN_ACTGRP_MULTIPLE_F4_DYNP'
** EXPORTING
***   ONLY_COLLECTIVE_ACTGROUPS       =
**   ONLY_SINGLE_ACTGROUPS           = 'X'
***   SHOW_POPUP                      = ' '
***   TARGET_SYSTEM                   = ' '
** TABLES
**   AGR_TAB                         = ITAB1
**          .
*
**LOOP AT insert_agr_tabs.
***LOOP AT ITAB1.
** MOVE sy-tabix TO tabix.
**    ADD 1 to tabix.
**    MOVE tabix TO index.
**     IF sy-tabix LT 9.
**       CONCATENATE '0' index into index.
**     endif.
** CONCATENATE 'I_ACTGROUPS(' index ')' INTO fnam.
** PERFORM bdc_field USING fnam insert_agr_tabs.
*** PERFORM bdc_field USING fnam ITAB1-AGR_NAME.
**ENDLOOP.
*
*********************************************************************
*
*perform bdc_transaction tables messtab
*using                         'PFCG'
*                              CTU
*                              MODE
*                              UPDATE.
*if sy-subrc <> 0.
*  subrc = sy-subrc.
*  exit.
*endif.
*
*perform close_group using     CTU.
*
*
**BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_018'.
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
*
*
ENDFUNCTION.
*INCLUDE BDCRECXY .
