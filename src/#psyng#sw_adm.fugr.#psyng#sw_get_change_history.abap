FUNCTION /psyng/sw_get_change_history.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IF_FUNCT) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CONID) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CONT) TYPE  FLAG OPTIONAL
*"     VALUE(IF_USERID) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CLASS) TYPE  FLAG OPTIONAL
*"     VALUE(IF_AUDID) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CAROLE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ROLE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CAUTH) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CTCODE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CROLE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CPROF) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CONF) TYPE  FLAG OPTIONAL
*"  TABLES
*"      IT_DATE STRUCTURE  /PSYNG/SW_SEL_OPTS_DATE OPTIONAL
*"      IT_BNAME STRUCTURE  /PSYNG/SW_SEL_OPTS_XUBNAME OPTIONAL
*"      ET_CDHDR STRUCTURE  CDHDR OPTIONAL
*"      ET_CDPOS STRUCTURE  CDPOS OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_GET_CHANGE_HISTORY'.
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
  TABLES: cdhdr, cdpos.
  RANGES: lr_objclas FOR cdhdr-objectclas,
          lr_objid   FOR cdhdr-objectid,
          lr_tabname FOR cdpos-tabname,
          lr_mcusr_tab FOR cdpos-tabname.                   " C0693

  DATA: BEGIN OF lt_cdpos_uid OCCURS 0,
        keyguid(32) type c,
        objectclas TYPE cdpos-objectclas,
        objectid TYPE cdpos-objectid,
        changenr TYPE cdpos-changenr,
        tabname   TYPE tabname,
        tabkey    TYPE cdfldvaln,
        END OF lt_cdpos_uid,
        lt_cdpos_tmp LIKE TABLE OF et_cdpos  WITH HEADER LINE.
  CONSTANTS c_cdpos_uid TYPE tabname VALUE 'CDPOS_UID'.

  lr_objclas-sign   = lr_objid-sign   = lr_tabname-sign   =
  lr_mcusr_tab-sign =  'I'.
  lr_objclas-option = lr_objid-option = lr_tabname-option
  = lr_mcusr_tab = 'EQ'.

  IF if_funct = 'X'.
    lr_objclas-low = '/PSYNG/FUNCTS'.
    APPEND lr_objclas.
    lr_objclas-low = '/PSYNG/FAOBJ'.
    APPEND lr_objclas.

    lr_tabname-low = '/PSYNG/FUNCTION'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/FUNCTTRAN'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/FAOBJ2'.
    APPEND lr_tabname.
  ENDIF.

  IF if_conid = 'X'.
    lr_objclas-low = '/PSYNG/CONFLICT'.
    APPEND lr_objclas.

    lr_tabname-low = '/PSYNG/CONFLICT'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/CONFDET'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/CONOWNER'.
    APPEND lr_tabname.
  ENDIF.

  IF if_cont = 'X'.
    lr_objclas-low = '/PSYNG/MIT'.
    APPEND lr_objclas.

    lr_tabname-low = '/PSYNG/MCHDR'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/MCAUDITOR'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/MCTRAN'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/MCREPID'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/MCRVWHDR'.
    APPEND lr_tabname.

  ENDIF.

  IF if_userid = 'X'.
    lr_objclas-low = '/PSYNG/MIT'.
    COLLECT lr_objclas.

    lr_tabname-low = '/PSYNG/MCUSER'.
    APPEND lr_tabname.

    lr_mcusr_tab-low = '/PSYNG/MCUSER'.
    APPEND lr_mcusr_tab.
  ENDIF.

  IF if_class = 'X'.
    lr_objclas-low = '/PSYNG/MIT'.
    COLLECT lr_objclas.

    lr_tabname-low = '/PSYNG/MCUSRGRP'.
    APPEND lr_tabname.
  ENDIF.

  IF if_audid = 'X'.
    lr_objclas-low = '/PSYNG/MIT'.
    COLLECT lr_objclas.

    lr_tabname-low = '/PSYNG/MCCAUSER'.
    APPEND lr_tabname.
  ENDIF.

  IF if_carole = 'X'.
    lr_objclas-low = '/PSYNG/MIT'.
    COLLECT lr_objclas.

    lr_tabname-low = '/PSYNG/MCCAROLE'.
    APPEND lr_tabname.
  ENDIF.

  IF if_role = 'X'.
    lr_objclas-low = '/PSYNG/MIT'.
    COLLECT lr_objclas.

    lr_tabname-low = '/PSYNG/MCROLE'.
    APPEND lr_tabname.
  ENDIF.

  IF if_cauth = 'X'.
    lr_objclas-low = '/PSYNG/SWAUD'.
    APPEND lr_objclas.

    lr_tabname-low = '/PSYNG/SWAUDHDR'.
    APPEND lr_tabname.
    lr_tabname-low = '/PSYNG/SWAUDC2'.
    APPEND lr_tabname.
  ENDIF.

  IF if_ctcode = 'X'.

    lr_objclas-low = '/PSYNG/CRIT_OBJ'.
    APPEND lr_objclas.

    lr_tabname-low = '/PSYNG/CRITCODES'.
    APPEND lr_tabname.
  ENDIF.

  IF if_crole = 'X'.
    lr_objclas-low = '/PSYNG/CRIT_OBJ'.
    APPEND lr_objclas.

    lr_tabname-low = '/PSYNG/CRIROLES'.
    APPEND lr_tabname.
  ENDIF.

  IF if_cprof = 'X'.
    lr_objclas-low = '/PSYNG/CRIT_OBJ'.
    APPEND lr_objclas.

    lr_tabname-low = '/PSYNG/CRIPROF'.
    APPEND lr_tabname.
  ENDIF.

  IF if_conf = 'X'.
    lr_objclas-low = '/PSYNG/SECONFIG'.
    APPEND lr_objclas.

    lr_tabname-low = '/PSYNG/SWCONFIG'.
    APPEND lr_tabname.
  ENDIF.


  SELECT * INTO TABLE et_cdhdr FROM cdhdr
         WHERE objectclas IN lr_objclas
           AND objectid   IN lr_objid
           AND username   IN it_bname
           AND udate      IN it_date.

  CHECK NOT et_cdhdr[] IS INITIAL.
  SORT et_cdhdr BY objectclas objectid changenr.

  SELECT * INTO TABLE et_cdpos                          "#EC CI_NOORDER
  FROM cdpos FOR ALL ENTRIES IN et_cdhdr
         WHERE objectclas = et_cdhdr-objectclas
           AND objectid   = et_cdhdr-objectid
           AND changenr   = et_cdhdr-changenr
           AND tabname   IN lr_tabname.

*--- read mcuser change key length > 70
      READ TABLE lr_mcusr_tab TRANSPORTING NO FIELDS
      WITH KEY low = '/PSYNG/MCUSER'.
      IF sy-subrc = 0.
*--collect only for mcuser table records
        LOOP AT et_cdpos WHERE tabname in lr_mcusr_tab.
          lt_cdpos_tmp-objectclas = et_cdpos-objectclas.
          lt_cdpos_tmp-objectid = et_cdpos-objectid.
          lt_cdpos_tmp-changenr = et_cdpos-changenr.
          lt_cdpos_tmp-tabkey = et_cdpos-tabkey.
          APPEND lt_cdpos_tmp.
        ENDLOOP.
        IF NOT lt_cdpos_tmp[] IS INITIAL.
          SELECT keyguid  objectclas objectid
                  changenr tabname   tabkey
  INTO TABLE lt_cdpos_uid FROM (C_CDPOS_UID) "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
            FOR ALL ENTRIES IN lt_cdpos_tmp
              WHERE  objectclas  = lt_cdpos_tmp-objectclas
                   AND objectid  = lt_cdpos_tmp-objectid
                   AND changenr  = lt_cdpos_tmp-changenr
                   AND tabname   IN lr_mcusr_tab.
*---Modify tabkey only
          LOOP AT lt_cdpos_uid.
            et_cdpos-tabkey = lt_cdpos_uid-tabkey.
            MODIFY et_cdpos TRANSPORTING tabkey
            WHERE tabkey  = lt_cdpos_uid-keyguid
                 AND tabname    = '/PSYNG/MCUSER'.
          ENDLOOP.
          free : lt_cdpos_tmp, lt_cdpos_uid.
        ENDIF.
      ENDIF.


  SORT et_cdpos BY objectclas objectid changenr.

ENDFUNCTION.
