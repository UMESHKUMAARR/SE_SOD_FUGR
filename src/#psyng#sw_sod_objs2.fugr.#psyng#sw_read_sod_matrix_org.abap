FUNCTION /psyng/sw_read_sod_matrix_org.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(ORGCHECK) TYPE  CHAR1 OPTIONAL
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_CONFIG_SET) TYPE  /PSYNG/SECONFID OPTIONAL
*"     VALUE(I_ORPHAN_FUNCTIONS) TYPE  FLAG OPTIONAL
*"  TABLES
*"      CONFLICT_FM STRUCTURE  /PSYNG/CONFLICT OPTIONAL
*"      CONFDET_FM STRUCTURE  /PSYNG/CONFDET OPTIONAL
*"      FUNCTTRAN_FM STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      FAOBJ_FM STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"      SPCONFS_FM STRUCTURE  /PSYNG/SW_SEL_OPTS_CONID OPTIONAL
*"      BUS_AREA_FM STRUCTURE  /PSYNG/SW_SEL_OPTS_BUS_AREA OPTIONAL
*"      IMP_FM STRUCTURE  /PSYNG/SW_SEL_OPTS_IMP OPTIONAL
*"      COWNER_FM STRUCTURE  /PSYNG/SW_SEL_OPTS_CONFOWNER OPTIONAL
*"      CONTID_FM STRUCTURE  /PSYNG/SW_SEL_OPTS_CONTID OPTIONAL
*"      SWSODORGM_FM STRUCTURE  /PSYNG/SWSODORGM OPTIONAL
*"      ORG_FM STRUCTURE  /PSYNG/SW_SEL_OPTS_ORG OPTIONAL
*"      IT_RISK STRUCTURE  /PSYNG/RANGE_RISK OPTIONAL
*"      IT_FUNCTIONS STRUCTURE  /PSYNG/RANGE_FUNID OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_READ_SOD_MATRIX_ORG'.
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


DATA: l_vrsio TYPE /psyng/functtran-vrsio,
      lt_conflict_keep type table of /PSYNG/CONFLICT with header line,
      lt_confdet_keep type table of /psyng/confdet with header line,
      lt_conpmit type table of /PSYNG/CONPMIT with header line,
      lt_conowner type table of /PSYNG/CONOWNER with header line,
      l_sysid type /psyng/sysid.
  concatenate sy-sysid sy-mandt into l_sysid.
  CLEAR: conflict_fm, confdet_fm, functtran_fm, faobj_fm,
         conflict, confdet, functtran, faobj.

  REFRESH: conflict_fm, confdet_fm, functtran_fm, faobj_fm,
           conflict, confdet, functtran, faobj.

  SELECT * FROM /psyng/conflict INTO TABLE conflict  "#EC CI_SEL_NESTED
           WHERE vrsio    =  vrsio         AND
                 inactive EQ space         AND
                 conid    IN spconfs_fm    AND
                 busarea  IN bus_area_fm   AND
                 imp      IN imp_fm        AND
                 risk     IN it_risk.

*--2018/01/15
*--Filter by proposed mitigation.
*  2 types : in conflict table,
*  and in separate proposed mitigations table
  if not conflict[] is initial and not contid_fm[] is initial.
*--Proposed Mitigation in conflict table
     loop at conflict where contid in contid_fm.
       append conflict to lt_conflict_keep.
     endloop.
*--Proposed Mitigation in separate proposed mitigations table
     delete conflict where contid in contid_fm.
     if not conflict[] is initial.
       select * from /PSYNG/CONPMIT
       into corresponding fields of table lt_conpmit
       for all entries in conflict where
       conid = conflict-conid and
       contid in contid_fm and
       vrsio = vrsio.
       sort lt_conpmit by conid.
       delete adjacent duplicates from lt_conpmit comparing conid.
       loop at lt_conpmit.
         read table conflict with table key conid = lt_conpmit-conid
         transporting all fields.
         if sy-subrc = 0.
           append conflict to lt_conflict_keep.
         endif.
       endloop.
     endif.
     sort lt_conflict_keep by conid.
     conflict[] = lt_conflict_keep[].
  endif.
*--2018/01/23
*--Filter By Conflict Owner
*  2 types : in conflict table,
*  and in separate conflict owner table
  refresh : lt_conflict_keep.
  if not conflict[] is initial and not cowner_fm[] is initial.
*--Proposed Mitigation in conflict table
     loop at conflict where owner in cowner_fm. "#EC CI_SORTSEQ
       append conflict to lt_conflict_keep.
     endloop.
*--Proposed Mitigation in separate conflict owner table
     delete conflict where owner in cowner_fm. "#EC CI_SORTSEQ
     if not conflict[] is initial.
       select * from /PSYNG/CONowner
       into corresponding fields of table lt_conowner
       for all entries in conflict where
       conid = conflict-conid and
       owner in cowner_fm and
       vrsio = vrsio.
       sort lt_conowner by conid.
       delete adjacent duplicates from lt_conowner comparing conid.
       loop at lt_conowner.
         read table conflict with table key conid = lt_conowner-conid
         transporting all fields.
         if sy-subrc = 0.
           append conflict to lt_conflict_keep.
         endif.
       endloop.
     endif.
     sort lt_conflict_keep by conid.
     conflict[] = lt_conflict_keep[].
  endif.





  CHECK NOT conflict[] IS INITIAL OR i_orphan_functions = 'X'.
  IF NOT conflict[] IS INITIAL.
    SELECT * FROM /psyng/confdet    "#EC CI_SEL_NESTED  "#EC CI_NOWHERE
        INTO  TABLE confdet
      FOR ALL ENTRIES IN conflict WHERE
                 vrsio = vrsio AND
                 conid = conflict-conid.
  ENDIF.
*--2018/01/15
*--Filter by functions
  if not IT_FUNCTIONs[] is initial.
    refresh : lt_conflict_keep.
    loop at confdet where functionid in IT_FUNCTIONS. "#EC CI_SORTSEQ
      read table conflict with key conid = confdet-conid
      transporting all fields.
             append conflict to lt_conflict_keep.
    endloop.
    sort lt_conflict_keep by conid.
    delete adjacent duplicates from lt_conflict_keep comparing conid.
    conflict[] = lt_conflict_keep[].
  endif.

 if not i_orphan_functions = 'X'.
*--Delete all functions that are not in any of the conflicts that are
*  remaining after applying all filters
   loop at confdet.
       read table conflict with table key
       conid = confdet-conid transporting no fields.
       if sy-subrc = 0.
        append confdet to lt_confdet_keep.
       endif.
   endloop.
   confdet[] = lt_confdet_keep[].
 endif.


  CHECK NOT confdet[] IS INITIAL OR i_orphan_functions = 'X'.
  IF i_orphan_functions = 'X'.
    SELECT * FROM /psyng/functtran                   "#EC CI_SEL_NESTED
    INTO TABLE functtran
        WHERE  vrsio      = vrsio.
  ELSE.
  SELECT * FROM /psyng/functtran     "#EC CI_SEL_NESTED "#EC CI_NOWHERE
      INTO TABLE functtran
      FOR ALL ENTRIES IN confdet WHERE
        vrsio      = vrsio AND
        functionid = confdet-functionid.
  ENDIF.
  SORT functtran.
  DELETE ADJACENT DUPLICATES FROM functtran COMPARING ALL FIELDS.

  CHECK NOT functtran[] IS INITIAL OR i_orphan_functions = 'X'.
  if not functtran[] is initial.
  SELECT * FROM /psyng/faobj2     "#EC CI_SEL_NESTED
             INTO TABLE faobj
             FOR ALL ENTRIES IN functtran WHERE
             vrsio = vrsio                AND
             funid = functtran-functionid AND
             tcode = functtran-tcode.
  endif.
  SORT faobj BY funid tcode object field val_from val_to.
  DELETE faobj WHERE object = space. "Remove rows with no object

  conflict_fm[] = conflict[].
  confdet_fm[] =  confdet[].
  functtran_fm[] = functtran[].
  faobj_fm[] = faobj[].

  IF orgcheck = 'X'.
*--Read the Org Level values for the local system
    CALL FUNCTION '/PSYNG/SW_AO_READ_VALUES'
      EXPORTING
       i_vrsio            = vrsio
       I_SETID            = I_CONFIG_SET
       I_SYSID            = l_sysid
      tables
        et_swsodorgm      = swsodorgm_fm.
  ENDIF.
  CLEAR: conflict_fm, confdet_fm, functtran_fm, faobj_fm,
         conflict, confdet, functtran, faobj, swsodorgm_fm.

  REFRESH: conflict, confdet, functtran, faobj.
  IF i_orphan_functions = 'X'.

    LOOP AT functtran_fm.
      l_vrsio = functtran_fm-vrsio.
      AT NEW functionid.
        READ TABLE confdet_fm WITH KEY
        functionid = functtran_fm-functionid
        TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          CLEAR confdet_fm-conid.
          confdet_fm-functionid = functtran_fm-functionid.
          confdet_fm-vrsio = l_vrsio.
          APPEND confdet_fm.
        ENDIF.

      ENDAT.
    ENDLOOP.
  ENDIF.
ENDFUNCTION.
