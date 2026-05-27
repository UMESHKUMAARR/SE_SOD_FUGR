FUNCTION /psyng/sw_rescount_org_abb.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_AID) TYPE  /PSYNG/SERESID OPTIONAL
*"     VALUE(IF_SYS_INFO) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_COUNT_PER_SYST_ABB) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_COUNT_PER_CONF_SYST_ABB) TYPE  FLAG DEFAULT 'X'
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      ET_SYSLIST STRUCTURE  /PSYNG/SWRESISYS OPTIONAL
*"      ET_COUNT_PER_SYST_ABB STRUCTURE  /PSYNG/SW_CON_SYSTABB OPTIONAL
*"      ET_COUNT_PER_CONF_SYST_ABB STRUCTURE  /PSYNG/SW_CON_CONFSYSTABB
*"       OPTIONAL
*"      IT_SYSTEM STRUCTURE  /PSYNG/RANGES_SYSID OPTIONAL
*"      IT_ORG STRUCTURE  /PSYNG/RANGE_DORG_ABB OPTIONAL
*"      IT_CONID STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_RESCOUNT_ORG_ABB'.
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

  TYPES :
*        BEGIN OF ty_confsystabb,
*           aid           TYPE /psyng/seresid,
*           sysid         TYPE /psyng/sysid,
*           conid         TYPE /psyng/conflict_id,
*           org_abb       TYPE /psyng/dorg_abb,
*           conflicts     TYPE /psyng/nr_conflicts,
*           mitigated_con TYPE /psyng/nr_conflicts,
*         END OF ty_confsystabb,
*
*         BEGIN OF  ty_swresusr,
*           aid          TYPE /psyng/seresid,
*           userindex    TYPE /psyng/seres_userindex,
*           bname        TYPE xubname,
*           nr_conflicts TYPE /psyng/nr_conflicts,
*           nr_mitigated TYPE /psyng/nr_conflicts,
*         END OF ty_swresusr,

    BEGIN OF ty_conflict_hdr,
      conid       TYPE /psyng/conflict_id,
      description TYPE /psyng/rskdsc,
    END OF ty_conflict_hdr.

*         BEGIN OF ty_output_records,
*           bname     TYPE xubname,
*           conid     TYPE /psyng/conflict_id,
*           mitigated TYPE flag,
*           sysid     TYPE /psyng/sysid,
*           abb       TYPE /psyng/dorg_abb,
*         END OF ty_output_records.


  DATA: lm_str          TYPE string,
*        lt_users_alv    TYPE HASHED TABLE OF ty_swresusr
*                      WITH UNIQUE KEY userindex,
*        ls_users_alv    TYPE ty_swresusr,
        lt_conflict     TYPE HASHED TABLE OF /psyng/swresicon
                      WITH UNIQUE KEY conindex,
        ls_conflict     TYPE /psyng/swresicon,
        lt_abb          TYPE HASHED TABLE OF /psyng/swresiabb
                      WITH UNIQUE KEY abbindex,
        ls_abb          TYPE /psyng/swresiabb,
*        lt_usercon      TYPE TABLE OF /psyng/swrescon,
*        ls_usercon      TYPE /psyng/swrescon,
*        lt_confun       TYPE TABLE OF /psyng/swrescfun,
*        ls_confun       TYPE /psyng/swrescfun,
*        lt_usrprof      TYPE HASHED TABLE OF /psyng/swresupr
*                      WITH UNIQUE KEY sys userindex profileindex,
*        ls_usrprof      TYPE /psyng/swresupr,
*        lt_funprofile   TYPE TABLE OF /psyng/swresfpr,
*        ls_funprofile   TYPE /psyng/swresfpr,
*        lt_usrprof2     TYPE TABLE OF /psyng/swresupr,
*        lt_authdet      TYPE TABLE OF /psyng/seres_authdetail,
*        ls_authdet      TYPE /psyng/seres_authdetail,
        lt_conflict_hdr TYPE HASHED TABLE OF ty_conflict_hdr
                        WITH UNIQUE KEY conid,
        ls_conflict_hdr TYPE ty_conflict_hdr,
*        lt_swrescnt     TYPE STANDARD TABLE OF /psyng/swrescnt,
*        ls_swrescnt     TYPE /psyng/swrescnt,
        l_message       TYPE string,
        l_cnt           TYPE string,
        l_success       TYPE flag,
*        lt_confsystabb  TYPE TABLE OF ty_confsystabb,
*        ls_confsystabb  TYPE ty_confsystabb,
        lt_rescont      TYPE TABLE OF /psyng/swrescont,
        ls_rescont      TYPE /psyng/swrescont.


*  RANGES :
*    lr_conflicts FOR /psyng/swresicon-conindex,
*    lr_userindex FOR /psyng/swrescon-userindex,
*    lr_userindex_all FOR /psyng/swrescon-userindex,
*    lr_userindex_part FOR /psyng/swrescon-userindex,
*    lr_funindex  FOR /psyng/swrescfun-funindex,
*    lr_profindex FOR /psyng/swresupr-profileindex,
*    lr_sys       FOR /psyng/swresisys-sysindex.

  DATA :
*         lt_output_records TYPE STANDARD TABLE OF ty_output_records,
*         ls_output_records TYPE ty_output_records,
         l_vrsio           TYPE /psyng/sodvrsio.

*  FIELD-SYMBOLS: <swresusr> TYPE ty_swresusr,
*                 <confun>   TYPE /psyng/swrescfun.

  DEFINE enmsg.
    clear &2.
    case &1.
      when 'E'.
        IF sy-batch IS INITIAL.
        MESSAGE e002(/psyng/sw) WITH &3 &4 &5 &6
        into &2-message.
        ELSE.
        MESSAGE e002(/psyng/sw) WITH &3 &4 &5 &6.
        ENDIF.
      when 'I'.
        IF sy-batch IS INITIAL.
        MESSAGE i002(/psyng/sw) WITH &3 &4 &5 &6
        into &2-message.
        ELSE.
        MESSAGE i002(/psyng/sw) WITH &3 &4 &5 &6.
        ENDIF.
      when others.
        IF sy-batch IS INITIAL.
        MESSAGE s002(/psyng/sw) WITH &3 &4 &5 &6
        into &2-message.
        ELSE.
        MESSAGE s002(/psyng/sw) WITH &3 &4 &5 &6.
        ENDIF.
    endcase.
    &2-type = &1.
    lm_str = &5.
    &2-MESSAGE_V1 = &3.
    &2-MESSAGE_V2 = &4.
    if strlen( lm_str ) > 50.
      &2-MESSAGE_V3 = lm_str(50).
      &2-MESSAGE_V4 = lm_str+50.
    else.
      &2-MESSAGE_V3 = &5.
      &2-MESSAGE_V4 = &6.
    endif.

    concatenate sy-datum sy-uzeit into &2-PARAMETER separated by space.
    append &2.
    COMMIT WORK.
  END-OF-DEFINITION.

*  IF i_batch IS INITIAL.
  IF i_aid IS INITIAL.
**---latest stored results
    SELECT MAX( aid ) FROM /psyng/swreshdr INTO         "#EC CI_NOFIELD
    i_aid                                               "#EC CI_NOFIRST
    WHERE no_restrictions EQ 'X'
      AND finished EQ 'X'.
  ENDIF.

*---if aid doesn't exist
  CALL FUNCTION '/PSYNG/SW_AID_READ'
    EXPORTING
      i_aid      = i_aid
    IMPORTING
      ef_success = l_success.
  IF l_success IS INITIAL.
    enmsg 'E' et_return 'Entered Analysis ID does not Exist' i_aid '' ''.
    EXIT.
  ENDIF.
* Read system id
  SELECT * FROM /psyng/swresisys
    INTO TABLE et_syslist
    WHERE aid = i_aid AND
          sysid IN it_system.
  IF sy-subrc IS NOT INITIAL
  AND it_system IS NOT INITIAL.
    enmsg 'I' et_return 'No results found for input systems for ID' i_aid '' ''.
    EXIT.
  ENDIF.
*Fetch conflicts count from DB table
  SELECT *
    FROM /psyng/swrescont
    INTO TABLE lt_rescont
    WHERE aid EQ i_aid.
  IF sy-subrc IS NOT INITIAL.
    enmsg 'I' et_return 'No Conflicts Count found for analysis ID' i_aid '' ''.
*      enmsg 'I' et_return 'Please execute program /PSYNG/SW_160 to store' 'conflicts count for stored SOD user result' '' ''.
*      EXIT.
*    SELECT *
*      FROM /psyng/swrescnt
*      INTO TABLE lt_swrescnt
*      WHERE aid     EQ i_aid
*        AND sysid   IN it_system
*        AND conid   IN it_conid
*        AND org_abb IN it_org.
*    IF sy-subrc IS NOT INITIAL.
*      enmsg 'I' et_return 'No Conflicts Count found' '' '' ''.
*      enmsg 'I' et_return 'Please execute program /PSYNG/SW_160 to store' 'conflicts count for stored SOD user result' '' ''.
*      EXIT.
  ELSE.
*Fetch all conflicts
    SELECT * FROM /psyng/swresicon INTO TABLE lt_conflict
               WHERE aid   =   i_aid AND
                     conid IN  it_conid.
*--Fetch Conflict Description
*--First fetch SOD version
    SELECT SINGLE sodvrsio INTO l_vrsio
      FROM /psyng/swreshdr
      WHERE aid EQ i_aid.
*--Fetch conflict description
    IF lt_conflict IS NOT INITIAL.
      SELECT conid description
        FROM /psyng/conflict
        INTO TABLE lt_conflict_hdr
        FOR ALL ENTRIES IN lt_conflict
        WHERE conid EQ lt_conflict-conid
          AND vrsio EQ l_vrsio.
    ENDIF.
*Fetch all abb
    SELECT * FROM /psyng/swresiabb INTO TABLE lt_abb
               WHERE aid   =   i_aid AND
                     org_abb IN  it_org.
    LOOP AT lt_rescont INTO ls_rescont.
      READ TABLE lt_conflict INTO ls_conflict
       WITH TABLE KEY conindex = ls_rescont-conindex.
      IF sy-subrc = 0.
        READ TABLE et_syslist INTO et_syslist
         WITH KEY sysindex = ls_rescont-sys.
        IF sy-subrc EQ 0.
          READ TABLE lt_abb INTO ls_abb
           WITH TABLE KEY abbindex = ls_rescont-abbindex.
          IF sy-subrc EQ 0
          OR ( ls_rescont-abbindex IS INITIAL
          AND 'OTHERS' IN it_org ).
            MOVE-CORRESPONDING ls_rescont TO et_count_per_conf_syst_abb.
            IF ls_rescont-abbindex IS INITIAL.
              et_count_per_conf_syst_abb-org_abb = 'OTHERS'.
            ELSE.
              et_count_per_conf_syst_abb-org_abb = ls_abb-org_abb.
            ENDIF.
            et_count_per_conf_syst_abb-conid = ls_conflict-conid.
            et_count_per_conf_syst_abb-sysid = et_syslist-sysid.
            READ TABLE lt_conflict_hdr INTO ls_conflict_hdr
            WITH TABLE KEY conid = ls_conflict-conid.
            IF sy-subrc EQ 0.
              et_count_per_conf_syst_abb-description = ls_conflict_hdr-description.
            ENDIF.
            COLLECT et_count_per_conf_syst_abb.
            IF if_count_per_syst_abb IS NOT INITIAL.
              MOVE-CORRESPONDING et_count_per_conf_syst_abb TO et_count_per_syst_abb.
              COLLECT et_count_per_syst_abb.
            ENDIF.
            CLEAR: et_count_per_conf_syst_abb, et_count_per_syst_abb.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.

    IF if_sys_info IS INITIAL.
      REFRESH et_syslist.
    ENDIF.
  SORT: et_count_per_conf_syst_abb, et_count_per_syst_abb.
  ENDIF.
*    EXIT.
*  ENDIF.

*--Else calculate conflicts count and store in DB table
**  lr_conflicts-sign = 'I'. lr_conflicts-option = 'EQ'.
**  enmsg 'I' et_return 'Start of conflicts count for stored ' 'SOD user result ID' i_aid ''.
***Fetch all users from table
**  SELECT aid userindex bname nr_conflicts nr_mitigated
**    FROM /psyng/swresusr
**     INTO TABLE lt_users_alv
**               WHERE aid = i_aid.
**
***Fetch all conflicts
**  SELECT * FROM /psyng/swresicon INTO TABLE lt_conflict
**             WHERE aid   =   i_aid AND
**                   conid IN  it_conid.
**
**  LOOP AT lt_conflict INTO ls_conflict.
**    lr_conflicts-low = ls_conflict-conindex.
**    APPEND lr_conflicts.
**  ENDLOOP.
**
**  IF lr_conflicts[] IS INITIAL.
***--No conflicts match the selection screen
**    lr_conflicts-sign   = 'E'.
**    lr_conflicts-option = 'GT'.
**    lr_conflicts-low    = '0'.
**    APPEND lr_conflicts.
**  ENDIF.
**
***Collect user index
**  LOOP AT lt_users_alv ASSIGNING <swresusr>.
**    lr_userindex-sign = 'I'.
**    lr_userindex-option = 'EQ'.
**    lr_userindex-low = <swresusr>-userindex.
**    APPEND lr_userindex.
**  ENDLOOP.
**
*** Get User Conflict
**  IF NOT lr_userindex[] IS INITIAL.
**    lr_userindex_all[] = lr_userindex[].
**    WHILE NOT lr_userindex[] IS INITIAL.
**      APPEND LINES OF lr_userindex FROM 1 TO 5000
**      TO lr_userindex_part.
**      DELETE lr_userindex FROM 1 TO 5000.
**
**      SELECT * FROM /psyng/swrescon APPENDING TABLE lt_usercon
**                 WHERE aid       =  i_aid AND
**                       userindex IN lr_userindex_part AND
**                       conindex  IN lr_conflicts.
**
**      REFRESH : lr_userindex_part[].
**    ENDWHILE.
**    lr_userindex[] = lr_userindex_all[].
**  ENDIF.
**  FREE : lr_userindex_part, lr_userindex_all.
**
*** Get User Conflict Function
**  IF NOT lt_usercon[] IS INITIAL.
**    SELECT * FROM /psyng/swrescfun  INTO TABLE lt_confun
**    FOR ALL ENTRIES IN lt_usercon
**             WHERE aid       =  i_aid AND
**                   conindex  = lt_usercon-conindex.
**
**  ENDIF.
**  LOOP AT lt_confun ASSIGNING <confun>.
**    lr_funindex-sign = 'I'.
**    lr_funindex-option = 'EQ'.
**    lr_funindex-low = <confun>-funindex.
**    APPEND lr_funindex.
**  ENDLOOP.
**
***** Read system id
****  SELECT * FROM /psyng/swresisys
****    INTO TABLE et_syslist
****    WHERE aid = i_aid AND
****          sysid IN it_system.
****  IF sy-subrc IS NOT INITIAL.
****    enmsg 'I' et_return 'No Conflicts found for input system' '' '' ''.
****    EXIT.
****  ENDIF.
****  LOOP AT et_syslist.
****    lr_sys-sign   = 'I'.
****    lr_sys-option   = 'EQ'.
****    lr_sys-low = et_syslist-sysindex.
****    APPEND lr_sys.
****  ENDLOOP.
**
***--Approach with multiple selects, optimize use of indexes
***--Get all profiles user has
**  SELECT * FROM /psyng/swresupr
**    INTO TABLE lt_usrprof
**    WHERE aid          = i_aid AND
**          userindex    IN lr_userindex.
***--For these profiles,
***  get the ones that relate to the functions we care about
**  lr_profindex-sign   = 'I'.
**  lr_profindex-option = 'EQ'.
**  MOVE-CORRESPONDING lr_profindex TO lr_sys.
**  LOOP AT lt_usrprof INTO ls_usrprof.
**    lr_profindex-low = ls_usrprof-profileindex.
**    APPEND lr_profindex.
**    lr_sys-low = ls_usrprof-sys.
**    APPEND lr_sys.
**  ENDLOOP.
**  SORT lr_profindex BY low.
**  SORT lr_sys BY low.
**  DELETE ADJACENT DUPLICATES FROM lr_profindex COMPARING low.
**  DELETE ADJACENT DUPLICATES FROM lr_sys COMPARING low.
***Get functions Profile
**  SELECT * FROM /psyng/swresfpr
**   INTO TABLE lt_funprofile
**   WHERE
**     aid = i_aid AND
**     sys IN lr_sys AND
**     profileindex IN lr_profindex.
**
**  SORT lt_funprofile BY sys profileindex.
**  LOOP AT lt_usrprof INTO ls_usrprof.
**    READ TABLE lt_funprofile WITH KEY
**      sys           = ls_usrprof-sys
**      profileindex  = ls_usrprof-profileindex
**    BINARY SEARCH TRANSPORTING NO FIELDS.
**    IF sy-subrc = 0.
**      APPEND ls_usrprof TO lt_usrprof2.
**    ENDIF.
**  ENDLOOP.
**  lt_usrprof[] =   lt_usrprof2[].
**  FREE lt_usrprof2[].
**
**  LOOP AT lt_confun INTO ls_confun.
**    LOOP AT lt_funprofile INTO ls_funprofile
**       WHERE funindex = ls_confun-funindex.
**      LOOP AT lt_usercon INTO ls_usercon
**         WHERE conindex = ls_confun-conindex.
**
**        READ TABLE lt_usrprof INTO ls_usrprof WITH TABLE KEY
**               sys          = ls_funprofile-sys
**               userindex    = ls_usercon-userindex
**               profileindex = ls_funprofile-profileindex.
**        IF sy-subrc = 0.
**          FREE lt_authdet.
**          CLEAR ls_output_records.
**          READ TABLE lt_users_alv INTO
**          ls_users_alv WITH TABLE KEY userindex = ls_usercon-userindex.
**          IF sy-subrc = 0.
**            ls_output_records-bname = ls_users_alv-bname.
**          ENDIF.
**
**          READ TABLE lt_conflict INTO ls_conflict
**           WITH TABLE KEY conindex = ls_confun-conindex.
**
**          IF sy-subrc = 0.
**            ls_output_records-conid = ls_conflict-conid.
**            ls_output_records-mitigated = ls_usercon-mitigated.
**          ENDIF.
**          CALL FUNCTION '/PSYNG/SW_SESTORE_EXPAND_CAUT'
**            EXPORTING
**              i_aid             = i_aid
**              i_sys             = ls_usrprof-sys
**              i_funindex        = ls_confun-funindex
**              i_profileindex    = ls_usrprof-profileindex
**            TABLES
**              et_profiledetails = lt_authdet.
**          LOOP AT lt_authdet INTO ls_authdet
**            WHERE abb IS NOT INITIAL.
**            ls_output_records-sysid = ls_authdet-sysid.
**            ls_output_records-abb = ls_authdet-abb.
**            IF ls_output_records-abb IN it_org.
**              COLLECT ls_output_records INTO lt_output_records.
**            ENDIF.
**          ENDLOOP.
**          IF sy-subrc NE 0.
**            LOOP AT lt_authdet INTO ls_authdet.
**              ls_output_records-sysid = ls_authdet-sysid.
**              ls_output_records-abb = 'OTHERS'.
**              IF ls_output_records-abb IN it_org.
**                COLLECT ls_output_records INTO lt_output_records.
**              ENDIF.
**            ENDLOOP.
**          ENDIF.
**        ENDIF.
**      ENDLOOP.
**    ENDLOOP.
**  ENDLOOP.
***--free some memory
**  FREE :     lt_users_alv,
**             lt_usrprof ,
**             lt_usrprof2,
**             lt_authdet,
**             lt_funprofile,
**             lt_confun,
**             lt_usercon  .
**  LOOP AT lt_output_records INTO ls_output_records.
**    et_count_per_conf_syst_abb-aid = i_aid.
**    et_count_per_conf_syst_abb-sysid = ls_output_records-sysid.
**    et_count_per_conf_syst_abb-conid = ls_output_records-conid.
**    et_count_per_conf_syst_abb-conflicts = 1.
**    IF ls_output_records-mitigated IS NOT INITIAL.
**      et_count_per_conf_syst_abb-mitigated_con = 1.
**    ENDIF.
**    et_count_per_conf_syst_abb-org_abb = ls_output_records-abb.
***    READ TABLE lt_conflict_hdr INTO ls_conflict_hdr
***    WITH TABLE KEY conid = ls_output_records-conid.
***    IF sy-subrc EQ 0.
***      et_count_per_conf_syst_abb-description = ls_conflict_hdr-description.
***    ENDIF.
***    COLLECT et_count_per_conf_syst_abb.
***    IF if_count_per_syst_abb IS NOT INITIAL.
***      MOVE-CORRESPONDING et_count_per_conf_syst_abb TO et_count_per_syst_abb.
***      COLLECT et_count_per_syst_abb.
***    ENDIF.
**    MOVE-CORRESPONDING et_count_per_conf_syst_abb TO ls_swrescnt.
**    COLLECT ls_swrescnt INTO lt_swrescnt.
**    CLEAR: et_count_per_conf_syst_abb, ls_swrescnt.
**  ENDLOOP.
**
**  IF lt_swrescnt IS NOT INITIAL.
**    DELETE FROM /psyng/swrescnt WHERE aid EQ i_aid.
**    INSERT /psyng/swrescnt FROM TABLE lt_swrescnt.
**    IF sy-subrc EQ 0
**    AND sy-dbcnt GT 0.
**      l_cnt = sy-dbcnt.
**      enmsg 'I' et_return 'Number of records inserted in table /psyng/swrescnt' l_cnt '' ''.
**    ENDIF.
**  ELSE.
**    enmsg 'I' et_return 'No conflicts count stored in table /psyng/swrescnt' '' '' ''.
**  ENDIF.

ENDFUNCTION.
