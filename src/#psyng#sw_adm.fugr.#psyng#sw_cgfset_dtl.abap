FUNCTION /psyng/sw_cgfset_dtl.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_CFGSET_ID) TYPE  /PSYNG/SECONFID OPTIONAL
*"  TABLES
*"      ET_CFGSET STRUCTURE  /PSYNG/SW_CONFIGSET OPTIONAL
*"      IT_VERSIO STRUCTURE  /PSYNG/RANGE_SOD_VERSION OPTIONAL
*"      IT_CFGSET_RANGE STRUCTURE  /PSYNG/RANGE_REQUESTID OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CGFSET_DTL'.
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
  DATA: lt_cfgset TYPE TABLE OF /psyng/swcfgset WITH HEADER LINE,
        lt_swcfgsys TYPE TABLE OF /psyng/swcfgsys WITH HEADER LINE.

  SELECT * FROM /psyng/swcfgset INTO TABLE
 lt_cfgset WHERE setid     IN it_cfgset_range
             AND sodvrsio  IN it_versio.



*--system

  IF NOT lt_cfgset[] IS INITIAL.
    SELECT * FROM /psyng/swcfgsys INTO TABLE lt_swcfgsys
   FOR ALL ENTRIES IN lt_cfgset
   WHERE setid = lt_cfgset-setid.
  ENDIF.

*---Process itab
  LOOP AT lt_cfgset.
    MOVE-CORRESPONDING lt_cfgset TO et_cfgset.
    LOOP AT lt_swcfgsys WHERE setid = lt_cfgset-setid.
      CONCATENATE et_cfgset-system   ',' lt_swcfgsys-sysid
      INTO et_cfgset-system SEPARATED BY space.
    ENDLOOP.
    et_cfgset-system = et_cfgset-system+2.
    APPEND et_cfgset.
    CLEAR: lt_cfgset,lt_swcfgsys, et_cfgset.
  ENDLOOP.


ENDFUNCTION.
