FUNCTION /psyng/sw_019.
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
*"     VALUE(GRUND_002) LIKE  BDCDATA-FVAL DEFAULT 'X'
*"     VALUE(GRUND_006) LIKE  BDCDATA-FVAL DEFAULT 'X'
*"     VALUE(AGR_NAME) LIKE  /PSYNG/POSITION-SAPTECHNAME
*"     VALUE(AGR_TEXT) LIKE  /PSYNG/POSITION-DESCRIPTION
*"  EXPORTING
*"     VALUE(SUBRC) LIKE  SYST-SUBRC
*"  TABLES
*"      MESSTAB STRUCTURE  BDCMSGCOLL OPTIONAL
*"      ROLES STRUCTURE  /PSYNG/ROLES OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_019'.
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
  DATA : agr_name1  LIKE bdcdata-fval,
         text       LIKE bdcdata-fval,
         fnam       LIKE bdcdata-fnam,
         tabix      TYPE sy-tabix,
         index(2),
         line_count TYPE i.

  DATA : BEGIN OF itab OCCURS 0.
           INCLUDE STRUCTURE /psyng/roles.
         DATA : END OF itab.
  DATA : wa LIKE /psyng/roles.


  AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'PFCG'.
  IF sy-subrc <> 0.
    MESSAGE e077(s#) WITH 'PFCG'.
  ELSE.
    CLEAR wa.
    REFRESH itab.

    subrc = 0.
    MOVE agr_name TO agr_name1.
    MOVE agr_text TO text.
    LOOP AT roles.
*   WA-SAPTECHNAME = ROLES-SAPTECHNAME.
*   INSERT ROLES INTO ITAB.
      itab[] = roles[].
      APPEND itab.
      line_count = line_count + 1.
    ENDLOOP.

    PERFORM bdc_nodata      USING nodata.

    PERFORM open_group      USING group user keep holddate ctu.

    PERFORM bdc_dynpro      USING 'SAPLPRGN_TREE' '0100'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'AGR_NAME_NEU'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=SANLE'.
    PERFORM bdc_field       USING 'AGR_NAME_NEU' agr_name1.
*                                AGR_NAME_NEU_001.
    PERFORM bdc_field       USING 'GRUND'
                                  grund_002.
    PERFORM bdc_dynpro      USING 'SAPLPRGN_TREE' '0300'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'S_AGR_TEXTS-TEXT'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=TAB8'.
    PERFORM bdc_field       USING 'S_AGR_DEFINE-AGR_NAME' agr_name1.
*                                AGR_NAME_003.
    PERFORM bdc_field       USING 'S_AGR_TEXTS-TEXT' text.
*                                TEXT_004.
    PERFORM bdc_dynpro      USING 'SAPLSPO1' '0100'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=YES'.
    PERFORM bdc_transaction TABLES messtab
    USING                         'PFCG'
                                  ctu
                                  mode
                                  update.
    IF sy-subrc <> 0.
      subrc = sy-subrc.
      EXIT.
    ENDIF.
    COMMIT WORK.
    PERFORM bdc_dynpro      USING 'SAPLPRGN_TREE' '0100'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'AGR_NAME_NEU'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=AEND'.
    PERFORM bdc_field       USING 'AGR_NAME_NEU' agr_name1.
*                                AGR_NAME_NEU_005.
    PERFORM bdc_field       USING 'GRUND'
                                  grund_006.
    PERFORM bdc_dynpro      USING 'SAPLPRGN_TREE' '0300'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'S_AGR_TEXTS-TEXT'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=TAB8'.
    PERFORM bdc_field       USING 'S_AGR_TEXTS-TEXT' text.
*                                TEXT_007.
    PERFORM bdc_dynpro      USING 'SAPLPRGN_TREE' '0300'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '/00'.
    PERFORM bdc_field       USING 'S_AGR_TEXTS-TEXT' text.
*                                TEXT_008.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'I_ACTGROUPS-AGR_NAME(02)'.

*  perform bdc_field       using 'I_ACTGROUPS-AGR_NAME(01)' NAME1.
*                                AGR_NAME_01_009.
*  perform bdc_field       using 'I_ACTGROUPS-AGR_NAME(02)'
*                                AGR_NAME_02_010.
*  perform bdc_field       using 'I_ACTGROUPS-AGR_NAME(03)'
*                                AGR_NAME_03_011.
*  ******************************************************************
    LOOP AT itab.
      MOVE sy-tabix TO tabix.
      MOVE tabix TO index.
      IF sy-tabix LT 9.
        CONCATENATE '0' index INTO index.
      ENDIF.
      CONCATENATE 'I_ACTGROUPS-AGR_NAME(' index ')' INTO fnam.
      PERFORM bdc_field USING fnam itab-saptechname.
      IF index > line_count.

*  *******************************************************************
        PERFORM bdc_dynpro      USING 'SAPLPRGN_TREE' '0300'.
        PERFORM bdc_field       USING 'BDC_CURSOR'
                                 'S_AGR_TEXTS-TEXT'.
        PERFORM bdc_field       USING 'BDC_OKCODE'
                                 '=P+'.
        PERFORM bdc_field       USING 'S_AGR_TEXTS-TEXT' text.
*                                  'test'.
*  *******************************************************************
      ENDIF.

    ENDLOOP.
*  *******************************************************************
    PERFORM bdc_dynpro      USING 'SAPLPRGN_TREE' '0300'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'S_AGR_TEXTS-TEXT'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=SAVE'.
    PERFORM bdc_field       USING 'S_AGR_TEXTS-TEXT' text.
*                                TEXT_012.
    PERFORM bdc_transaction TABLES messtab
    USING                         'PFCG'
                                  ctu
                                  mode
                                  update.
    IF sy-subrc <> 0.
      subrc = sy-subrc.
      EXIT.
    ENDIF.

    PERFORM close_group USING     ctu.

  ENDIF.



ENDFUNCTION.
INCLUDE bdcrecxy .
