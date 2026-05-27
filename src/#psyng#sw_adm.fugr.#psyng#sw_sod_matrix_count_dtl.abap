FUNCTION /psyng/sw_sod_matrix_count_dtl.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  TABLES
*"      ET_COUNTINFO STRUCTURE  /PSYNG/SW_SOD_OVERVIEW_COUNT OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_SOD_MATRIX_COUNT_DTL'.
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
  DATA: lt_swsodvrsio TYPE TABLE OF /psyng/swsodvers WITH HEADER LINE.

  DATA: lt_concount    TYPE TABLE OF gs_count WITH HEADER LINE,
        lt_funcount    TYPE TABLE OF gs_count WITH HEADER LINE,
        lt_crirolecnt  TYPE TABLE OF gs_count WITH HEADER LINE,
        lt_critxncnt   TYPE TABLE OF gs_count WITH HEADER LINE,
        lt_criprofcnt  TYPE TABLE OF gs_count WITH HEADER LINE,
        lt_custconcnt  TYPE TABLE OF gs_count WITH HEADER LINE,
        lt_cfgsetcnt   TYPE TABLE OF gs_count WITH HEADER LINE.

  DATA: lt_mccarole  TYPE TABLE OF gs_count WITH HEADER LINE,
        lt_mccauser  TYPE TABLE OF gs_count WITH HEADER LINE,
        lt_mcrole    TYPE TABLE OF gs_count WITH HEADER LINE,
        lt_mcuser    TYPE TABLE OF gs_count WITH HEADER LINE,
        lt_mcusrgrp  TYPE TABLE OF gs_count WITH HEADER LINE.


*-- get all existing version
  SELECT * FROM /psyng/swsodvers INTO TABLE "#EC CI_NOWHERE
  lt_swsodvrsio.

*--count the table entris defined in sod vrsio
  SELECT vrsio COUNT(*) AS count FROM /psyng/conflict INTO TABLE
  lt_concount "#EC CI_NOWHERE
  GROUP BY vrsio.

*--Conflict
*-- join will not work
* SELECT a~vrsio as vrsio
* COUNT(*) as count INTO corresponding fields of table lt_concount
* FROM /psyng/conflict as a
* inner join /psyng/swsodvers as b
* on a~vrsio = b~vrsio
*    group by a~vrsio.

  SELECT vrsio COUNT(*) AS count FROM /psyng/function INTO TABLE
   lt_funcount "#EC CI_NOWHERE
   GROUP BY vrsio.

  SELECT vrsio COUNT(*) AS count FROM /psyng/critcodes INTO TABLE
  lt_critxncnt "#EC CI_NOWHERE
  GROUP BY vrsio.

  SELECT vrsio COUNT(*) AS count FROM /psyng/criroles INTO TABLE
    lt_crirolecnt "#EC CI_NOWHERE
    GROUP BY vrsio.

  SELECT vrsio COUNT(*) AS count FROM /psyng/criprof INTO TABLE
    lt_criprofcnt "#EC CI_NOWHERE
    GROUP BY vrsio.

  SELECT sodvrsio COUNT(*) AS count FROM
/psyng/swcfgset INTO  TABLE
   lt_cfgsetcnt "#EC CI_NOWHERE
   GROUP BY sodvrsio.

  SELECT vrsio COUNT(*) AS count FROM /psyng/sw_cuscon INTO TABLE
    lt_custconcnt "#EC CI_NOWHERE
    GROUP BY vrsio.

*---Mitigation assignment
  SELECT vrsio COUNT(*) AS count FROM /psyng/mcuser INTO TABLE
    lt_mcuser "#EC CI_NOWHERE
    GROUP BY vrsio.

  SELECT vrsio COUNT(*) AS count FROM /psyng/mcusrgrp INTO TABLE
      lt_mcusrgrp "#EC CI_NOWHERE
      GROUP BY vrsio.

  SELECT vrsio COUNT(*) AS count FROM /psyng/mcrole INTO TABLE
      lt_mcrole "#EC CI_NOWHERE
      GROUP BY vrsio.

  SELECT vrsio COUNT(*) AS count FROM /psyng/mccauser INTO TABLE
      lt_mccauser "#EC CI_NOWHERE
      GROUP BY vrsio.

  SELECT vrsio COUNT(*) AS count FROM /psyng/mccarole INTO TABLE
      lt_mccarole "#EC CI_NOWHERE
      GROUP BY vrsio.

*-- dump all mit data into one table
  APPEND LINES OF lt_mcusrgrp TO lt_mcuser.
  APPEND LINES OF lt_mcrole TO lt_mcuser.
  APPEND LINES OF lt_mccauser TO lt_mcuser.
  APPEND LINES OF lt_mccarole TO lt_mcuser.

  SORT lt_mcuser BY vrsio.
  DATA lt_mitcount TYPE TABLE OF gs_count WITH HEADER LINE.
*--calculate version wise
  LOOP AT lt_mcuser.
    AT NEW vrsio.
      APPEND lt_mitcount.
      CLEAR lt_mitcount.
    ENDAT.
    lt_mitcount-count = lt_mcuser-count + lt_mitcount-count.
    lt_mitcount-vrsio = lt_mcuser-vrsio.
  ENDLOOP.
  DELETE lt_mitcount INDEX 1.

  FREE: lt_mcuser, lt_mcrole, lt_mcusrgrp,
        lt_mccauser, lt_mccarole.

*--sort table
  SORT lt_swsodvrsio BY vrsio.
  SORT lt_concount BY vrsio.
  SORT lt_funcount BY vrsio.
  SORT lt_custconcnt BY vrsio.
  SORT lt_crirolecnt BY vrsio.
  SORT lt_critxncnt BY vrsio.
  SORT lt_criprofcnt BY vrsio.
  SORT lt_cfgsetcnt BY vrsio.
  SORT lt_mitcount  BY vrsio.

*--fill internal table for output
*-- looping on all version bcz suppose any sod matrix doesn't have
*-- matrix should be part of output

  LOOP AT lt_swsodvrsio.
    et_countinfo-vrsio    = lt_swsodvrsio-vrsio.
    et_countinfo-noedit   = lt_swsodvrsio-noedit.
    et_countinfo-vdesc    = lt_swsodvrsio-vdesc.

*----mitigation count
    READ TABLE lt_mitcount WITH KEY
                    vrsio = lt_swsodvrsio-vrsio
                    BINARY SEARCH.
    IF sy-subrc = 0.
      et_countinfo-mitassign_cnt = lt_mitcount-count.
    ELSE.
      et_countinfo-vrsio    = lt_swsodvrsio-vrsio.
      et_countinfo-mitassign_cnt   = lt_mitcount-count.
    ENDIF.

*--conflict
    READ TABLE lt_concount WITH KEY
                     vrsio = lt_swsodvrsio-vrsio
                     BINARY SEARCH.
    IF sy-subrc = 0.
      et_countinfo-con_cnt = lt_concount-count.
    ELSE.
      et_countinfo-vrsio    = lt_swsodvrsio-vrsio.
      et_countinfo-con_cnt   = lt_concount-count.
    ENDIF.
*--function
    READ TABLE lt_funcount WITH KEY
                         vrsio = lt_swsodvrsio-vrsio
                         BINARY SEARCH.
    IF sy-subrc = 0.
      et_countinfo-func_cnt = lt_funcount-count.
    ELSE.
      et_countinfo-vrsio    = lt_swsodvrsio-vrsio.
      et_countinfo-func_cnt   = lt_funcount-count.
    ENDIF.
*--Critical roles
    READ TABLE lt_crirolecnt WITH KEY
                         vrsio = lt_swsodvrsio-vrsio
                         BINARY SEARCH.
    IF sy-subrc = 0.
      et_countinfo-criroles_cnt = lt_crirolecnt-count.
    ELSE.
      et_countinfo-vrsio    = lt_swsodvrsio-vrsio.
      et_countinfo-criroles_cnt   = lt_crirolecnt-count.
    ENDIF.
*--Critical profile
    READ TABLE lt_criprofcnt WITH KEY
                         vrsio = lt_swsodvrsio-vrsio
                         BINARY SEARCH.
    IF sy-subrc = 0.
      et_countinfo-criprof_cnt = lt_criprofcnt-count.
    ELSE.
      et_countinfo-vrsio    = lt_swsodvrsio-vrsio.
      et_countinfo-criprof_cnt   = lt_criprofcnt-count.
    ENDIF.
*--Critical txn
    READ TABLE lt_critxncnt WITH KEY
                         vrsio = lt_swsodvrsio-vrsio
                         BINARY SEARCH.
    IF sy-subrc = 0.
      et_countinfo-critxn_cnt = lt_critxncnt-count.
    ELSE.
      et_countinfo-vrsio    = lt_swsodvrsio-vrsio.
      et_countinfo-critxn_cnt   = lt_critxncnt-count.
    ENDIF.
*--Custom conflict
    READ TABLE lt_custconcnt WITH KEY
                         vrsio = lt_swsodvrsio-vrsio
                         BINARY SEARCH.
    IF sy-subrc = 0.
      et_countinfo-cstmcon_cnt = lt_custconcnt-count.
    ELSE.
      et_countinfo-vrsio    = lt_swsodvrsio-vrsio.
      et_countinfo-cstmcon_cnt   = lt_custconcnt-count.
    ENDIF.
*--Configset
    READ TABLE lt_cfgsetcnt WITH KEY
                         vrsio = lt_swsodvrsio-vrsio
                         BINARY SEARCH.
    IF sy-subrc = 0.
      et_countinfo-cfgset_cnt = lt_cfgsetcnt-count.
    ELSE.
      et_countinfo-vrsio    = lt_swsodvrsio-vrsio.
      et_countinfo-cfgset_cnt   = lt_cfgsetcnt-count.
    ENDIF.
    APPEND et_countinfo.

    CLEAR: et_countinfo,lt_swsodvrsio,
           lt_concount, lt_funcount,
           lt_custconcnt, lt_crirolecnt,
           lt_critxncnt, lt_criprofcnt,
           lt_cfgsetcnt, lt_mitcount.
  ENDLOOP.

*--Free itab
  FREE: lt_swsodvrsio,lt_concount, lt_funcount,
             lt_custconcnt, lt_crirolecnt,
             lt_critxncnt, lt_criprofcnt,
             lt_cfgsetcnt, lt_mitcount.


ENDFUNCTION.
