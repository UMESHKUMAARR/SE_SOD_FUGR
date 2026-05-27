*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_UTLS7F01 .
*----------------------------------------------------------------------*
FORM get_default_dates USING    if_use_ta
                        CHANGING
                                e_hist_start
                                e_hist_end
                       .
  DATA : idirectory TYPE STANDARD TABLE OF /psyng/sw_dates
                     WITH HEADER LINE,
         l_days     TYPE i.

  IF   if_use_ta <> 'X'.
    CALL FUNCTION '/PSYNG/SW_GET_DIRECTORY'
      TABLES
        idirectory = idirectory.

    IF e_hist_start IS INITIAL AND e_hist_end IS INITIAL.


      LOOP AT idirectory.
      IF e_hist_start IS INITIAL OR e_hist_start > idirectory-startdate.
          e_hist_start = idirectory-startdate.
        ENDIF.
        IF e_hist_end < idirectory-startdate.
          e_hist_end = idirectory-startdate.
        ENDIF.
        months-month = idirectory-startdate.
        APPEND months.
      ENDLOOP.
*--   If the start of the last period is in this month, use
*     today as end date
      l_days = sy-datum - e_hist_end.
      IF l_days < 31 .
        e_hist_end = sy-datum.
      ENDIF.
    ELSE.
*--Change start date to first day of month
      e_hist_start+6(2) = '01'.
      LOOP AT idirectory WHERE startdate >=  e_hist_start AND
                               startdate <=  e_hist_end.
      IF e_hist_start IS INITIAL OR e_hist_start > idirectory-startdate.
          e_hist_start = idirectory-startdate.
        ENDIF.
        IF e_hist_end < idirectory-startdate.
          e_hist_end = idirectory-startdate.
        ENDIF.
        months-month = idirectory-startdate.
        APPEND months.
      ENDLOOP.
    ENDIF.
  ELSE.
*    MESSAGE e113(/psyng/sw) WITH 'TA integration not implemented'.

  ENDIF.
ENDFORM.                    " get_default_dates
*---------------------------------------------------------------------*
*       FORM stat_analysis                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_RESULTS                                                    *
*  -->  I_HIST_START                                                  *
*  -->  I_HIST_END                                                    *
*  -->  I_VRSIO                                                       *
*---------------------------------------------------------------------*
FORM stat_analysis
TABLES   et_results   STRUCTURE /psyng/sw_sod_output_org
         it_functtran STRUCTURE /psyng/functtran
         it_confdet   STRUCTURE /psyng/confdet
USING    i_hist_start TYPE dats
         i_hist_end   TYPE dats
         i_vrsio      TYPE /psyng/sodvrsio.
  DATA : lt_user_stat     TYPE STANDARD TABLE OF /psyng/sw_entry
                      WITH HEADER LINE,
       lt_hitlist       TYPE TABLE OF /psyng/hitlist   WITH HEADER LINE,
       lt_confdet       TYPE TABLE OF /psyng/confdet   WITH HEADER LINE,
       lt_functtran     TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
       lf_conflictfound TYPE flag,
       lf_tcodefound    TYPE flag.
  TYPES: BEGIN OF userexe_typ,
           bname LIKE usr02-bname,
           tcode LIKE sy-tcode,
         END OF userexe_typ.
  DATA: lt_userexe TYPE SORTED TABLE OF userexe_typ WITH UNIQUE KEY
                bname tcode
                WITH HEADER LINE.

  FIELD-SYMBOLS : <res>  TYPE /psyng/sw_sod_output_org,
                  <stat> TYPE /psyng/sw_entry.
  RANGES : lr_bname FOR lt_userexe-bname.
*--Load conflict details and tcodes
  IF it_functtran[] IS INITIAL.
    SELECT functionid tcode FROM /psyng/functtran    "#EC CI_SEL_NESTED
          INTO CORRESPONDING FIELDS
             OF  TABLE lt_functtran WHERE vrsio = i_vrsio.
  ELSE.
    lt_functtran[] = it_functtran[].
  ENDIF.
  IF it_confdet[] IS INITIAL.
    SELECT conid functionid                          "#EC CI_SEL_NESTED
      FROM /psyng/confdet INTO CORRESPONDING FIELDS
                             OF  TABLE lt_confdet WHERE vrsio = i_vrsio.
  ELSE.
    lt_confdet[] = it_confdet[].
  ENDIF.
  lr_bname-sign = 'I'.
  lr_bname-option  = 'EQ'.
  LOOP AT et_results ASSIGNING <res>.
    lr_bname-low = <res>-bname.
    COLLECT lr_bname.
  ENDLOOP.

*--Read all Stat DATA per month
  LOOP AT months.
    FREE : lt_user_stat, lt_hitlist.
    CALL FUNCTION '/PSYNG/SW_SUMMARY_STATISTIC'
      EXPORTING
        startdate = months-month
      TABLES
        user_stat = lt_user_stat
        hitlist   = lt_hitlist.
    SORT lt_hitlist   BY account tcode.
    SORT lt_user_stat BY account entry_id.
    LOOP AT lt_user_stat WHERE entry_id+72(1) = 'T'.  "tcode
      CHECK lt_user_stat-account IN lr_bname.
      lt_userexe-tcode = lt_user_stat-entry_id(20).
      CONDENSE lt_userexe-tcode NO-GAPS.
      lt_userexe-bname = lt_user_stat-account.
      INSERT TABLE lt_userexe.
    ENDLOOP.
    LOOP AT lt_hitlist WHERE tcode   <> space
                         AND account IN lr_bname.
      lt_userexe-bname = lt_hitlist-account.
      lt_userexe-tcode = lt_hitlist-tcode.
      INSERT TABLE lt_userexe.
    ENDLOOP.
  ENDLOOP.

  LOOP AT et_results ASSIGNING <res>                    "#EC CI_NOORDER
    WHERE level2 IS INITIAL.
    lf_conflictfound = 'X'.
    LOOP AT lt_confdet                                  "#EC CI_NOORDER
      WHERE conid = <res>-conid.
      CLEAR lf_tcodefound.
      LOOP AT lt_functtran WHERE                        "#EC CI_NOORDER
      functionid = lt_confdet-functionid.
*--look for tcode in execution history
*             search hitlist
        READ TABLE lt_userexe WITH KEY bname  = <res>-bname
                                       tcode  = lt_functtran-tcode
        BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          lf_tcodefound = 'X'.
          EXIT.                                         "#EC CI_NOORDER
        ENDIF.
      ENDLOOP.
      IF lf_tcodefound IS INITIAL.
        CLEAR lf_conflictfound.
        EXIT.                                           "#EC CI_NOORDER
      ENDIF.
    ENDLOOP.
    <res>-level2 =  lf_conflictfound .
  ENDLOOP.
ENDFORM.                    " stat_analysis
*---------------------------------------------------------------------*
*       FORM get_change_details                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_DETAILS                                                    *
*  -->  I_BNAME                                                       *
*  -->  I_TCODE                                                       *
*  -->  I_CHANGETYPE                                                  *
*  -->  I_HIST_START                                                  *
*  -->  I_HIST_END                                                    *
*---------------------------------------------------------------------*
FORM get_change_details
TABLES
  et_details STRUCTURE /psyng/sw_level3_details
USING
  i_bname
  i_tcode
  i_changetype
  i_hist_start TYPE dats
  i_hist_end   TYPE dats
  i_funid      TYPE /psyng/function_id.
  DATA : lt_cdhdr  TYPE TABLE OF cdhdr WITH HEADER LINE,
         lt_tablog TYPE TABLE OF dbtablog WITH HEADER LINE.

  DATA : ls_tablog TYPE TABLE OF /psyng/dblog WITH HEADER LINE,
         ls_uname  TYPE TABLE OF /psyng/range_bname WITH HEADER LINE,
         ls_tcode  TYPE TABLE OF /psyng/range_tcode WITH HEADER LINE.

* Changes by Om on 21.02.2023 for C0989 - Date range table declared for
* History dates
  RANGES lr_histdate FOR sy-datum.
  lr_histdate-sign = 'I'. lr_histdate-option = 'BT'.
  lr_histdate-low = i_hist_start. lr_histdate-high = i_hist_end.
  COLLECT lr_histdate.
* End of changes

  et_details-bname = i_bname.
  et_details-tcode = i_tcode.
  et_details-type  = i_changetype.
  CONCATENATE sy-sysid sy-mandt INTO et_details-system.
  et_details-funid  = i_funid.
  IF i_changetype = 'CHANGEDOC'.
SELECT DISTINCT udate utime objectclas objectid changenr "#EC CI_SEL_NESTED
                                                        "#EC CI_NOFIELD
FROM cdhdr
INTO CORRESPONDING FIELDS OF TABLE lt_cdhdr
WHERE
username = i_bname      AND
udate IN lr_histdate  AND"C0989 - Use Date Range table
tcode   = i_tcode.
    LOOP AT lt_cdhdr.
      et_details-table    = lt_cdhdr-objectclas.
      et_details-logkey   = lt_cdhdr-objectid.
      et_details-date     = lt_cdhdr-udate.
      et_details-time     = lt_cdhdr-utime.
      et_details-objectid = lt_cdhdr-objectid.
*      change no added
      et_details-changenr = lt_cdhdr-changenr.
      APPEND et_details.
    ENDLOOP.
  ENDIF.
  IF i_changetype = 'TABLOG'.
    SELECT DISTINCT logdate logtime tabname logkey   "#EC CI_SEL_NESTED
    FROM dbtablog
    INTO CORRESPONDING FIELDS OF TABLE lt_tablog
    WHERE
    username = i_bname      AND
   logdate IN lr_histdate  AND"C0989 - Use Date Range table
    tcode    = i_tcode.
    LOOP AT lt_tablog.
      et_details-table     = lt_tablog-tabname.
      et_details-logkey    = lt_tablog-logkey.
      et_details-date      = lt_tablog-logdate.
      et_details-time      = lt_tablog-logtime.
      et_details-objectid  = lt_tablog-logid.
      APPEND et_details.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " get_change_details
*---------------------------------------------------------------------*
*       FORM get_change_tables                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_L3DETAILS                                                  *
*  -->  ET_TABLES                                                     *
*---------------------------------------------------------------------*
FORM get_change_tables
TABLES   it_l3details STRUCTURE /psyng/sw_level3_details
          et_tables STRUCTURE tcdob.
*--Collect tables from table logging changes in IT_L3DETAILS
  LOOP AT it_l3details WHERE type = 'TABLOG'.
    et_tables-tabname = it_l3details-table.
    COLLECT et_tables.
  ENDLOOP.
*--Get tables from change documents via table TCDOB
  LOOP AT it_l3details WHERE type = 'CHANGEDOC'.        "#EC CI_NOORDER
    SELECT object tabname FROM tcdob                    "#EC CI_NOORDER
    INTO CORRESPONDING FIELDS OF et_tables
    WHERE object = it_l3details-table.
      COLLECT et_tables.
    ENDSELECT.
  ENDLOOP.



ENDFORM.                    " get_change_tables
*---------------------------------------------------------------------*
*       FORM get_table_relations                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_TABLES                                                     *
*  -->  ET_RELATIONS                                                  *
*---------------------------------------------------------------------*
FORM get_table_relations TABLES   it_tables    STRUCTURE tcdob
                                  et_relations STRUCTURE graph_tabl.
  RANGES  : lr_tabname FOR it_tables-tabname.

  CHECK NOT it_tables[] IS INITIAL.
  lr_tabname-sign   = 'I'.
  lr_tabname-option = 'EQ'.
  LOOP AT it_tables.
    lr_tabname-low = it_tables-tabname.
    APPEND lr_tabname.
  ENDLOOP.
  SELECT * FROM graph_tabl INTO TABLE et_relations
  WHERE
  tabname    IN  lr_tabname AND
  checktable IN  lr_tabname."#EC SAST_CI_GEN_CHECK
ENDFORM.                    " get_table_relations
**---------------------------------------------------------------------*
**       FORM find_related_change                                      *
**---------------------------------------------------------------------*
**       ........                                                      *
**---------------------------------------------------------------------*
**  -->  IT_CONFDET                                                    *
**  -->  IT_FUNCTTRAN                                                  *
**  -->  IT_L3DETAILS                                                  *
**  -->  IT_RELATIONS                                                  *
**  -->  IT_TABLES                                                     *
**  -->  IT_CONFLICTING_CHANGES                                        *
**  -->  I_BNAME                                                       *
**  -->  I_CONID                                                       *
**  -->  I_FUNID                                                       *
**  -->  I_TCODE                                                       *
**  -->  I_L3DETAIL                                                    *
**---------------------------------------------------------------------*
*FORM find_related_change
*TABLES  it_confdet             STRUCTURE /psyng/confdet
*        it_functtran           STRUCTURE /psyng/functtran
*        it_l3details           STRUCTURE /psyng/sw_level3_details
*        it_relations           STRUCTURE graph_tabl
*        it_tables              STRUCTURE tcdob
*        it_conflicting_changes STRUCTURE /psyng/sw_level3bc_details
*USING   i_bname                TYPE      xubname
*        i_conid                TYPE      /psyng/conflict_id
*        i_funid                TYPE      /psyng/function_id
*        i_tcode                TYPE      tcode
*        i_l3detail             TYPE      /psyng/sw_level3_details.
*  RANGES  : lr_tabname FOR it_tables-tabname.
*  FIELD-SYMBOLS : <confdet> TYPE /psyng/confdet,
*                  <change>  TYPE /psyng/sw_level3_details.
*  lr_tabname-sign   = 'I'.
*  lr_tabname-option = 'EQ'.
*  IF i_l3detail-type = 'CHANGEDOC'.
*    LOOP AT it_tables WHERE object = i_l3detail-table.
*      lr_tabname-low = it_tables-tabname.
*      APPEND lr_tabname.
*    ENDLOOP.
*  ELSE.
*    lr_tabname-low = i_l3detail-table.
*    APPEND lr_tabname.
*  ENDIF.
*
*  LOOP AT it_confdet ASSIGNING <confdet>
*                     WHERE conid      = i_conid AND
*                     functionid       <> i_funid.
*    LOOP AT it_functtran WHERE functionid = <confdet>-functionid.
*      LOOP AT it_relations WHERE tabname    IN lr_tabname OR
*                                 checktable IN lr_tabname.
**Table logging changes
*        LOOP AT it_l3details ASSIGNING <change>
*        WHERE bname = i_bname AND
*                                   tcode = it_functtran-tcode AND
*                                   type  = 'TABLOG' AND
*                                   (
*                                     table = it_relations-tabname OR
*                                     table = it_relations-checktable
*                                   ).
*          PERFORM check_change_is_related
*            TABLES
*              it_relations
*              it_tables
*              it_conflicting_changes
*            USING
*              i_bname
*              i_conid
*              i_funid
*              <confdet>-functionid
*              <change>
*              i_l3detail.
*        ENDLOOP.
**Change Documents
*        LOOP AT it_tables WHERE tabname = it_relations-tabname OR
*                                tabname = it_relations-checktable.
*          LOOP AT it_l3details ASSIGNING <change>
*          WHERE bname = i_bname AND
*                                     tcode = it_functtran-tcode AND
*                                     type  = 'CHANGEDOC' AND
*                                     table = it_tables-object.
*            PERFORM check_change_is_related
*              TABLES
*                it_relations
*                it_tables
*                it_conflicting_changes
*              USING
*                i_bname
*                i_conid
*                i_funid
*                <confdet>-functionid
*                <change>
*                i_l3detail.
*          ENDLOOP.
*        ENDLOOP.
*      ENDLOOP.
*    ENDLOOP.
*  ENDLOOP.
*ENDFORM.                    " find_related_change
**---------------------------------------------------------------------*
**       FORM check_change_is_related                                  *
**---------------------------------------------------------------------*
**       ........                                                      *
**---------------------------------------------------------------------*
**  -->  IT_RELATIONS                                                  *
**  -->  IT_TABLES                                                     *
**  -->  IT_CONFLICTING_CHANGES                                        *
**  -->  I_BNAME                                                       *
**  -->  I_CONID                                                       *
**  -->  I_FUNID1                                                      *
**  -->  I_FUNID2                                                      *
**  -->  I_CHANGE1                                                     *
**  -->  I_CHANGE2                                                     *
**---------------------------------------------------------------------*
*FORM check_change_is_related
*TABLES
*  it_relations           STRUCTURE graph_tabl
*  it_tables              STRUCTURE tcdob
*  it_conflicting_changes STRUCTURE /psyng/sw_level3bc_details
*USING
*  i_bname
*  i_conid
*  i_funid1
*  i_funid2
*  i_change1 TYPE /psyng/sw_level3_details
*  i_change2 TYPE /psyng/sw_level3_details.
*  STATICS : g_linkid TYPE /psyng/reporting_key.
*  DATA : lf_already_found TYPE flag,
*         lf_related       TYPE flag,
*         lt_cdpos1 TYPE TABLE OF cdpos WITH HEADER LINE,
*         lt_cdpos2 TYPE TABLE OF cdpos WITH HEADER LINE,
*         l_tabline1      TYPE REF TO data,
*         l_tabline2       TYPE REF TO data,
*         lt_fields       TYPE TABLE OF dfies WITH HEADER LINE,
*         BEGIN OF lt_where OCCURS 0,
*          line(120) TYPE c,
*         END OF lt_where,
*         l_where_field TYPE string,
*         l_idx TYPE i,
*         lf_no_table TYPE flag.
*  FIELD-SYMBOLS: <tabline_1> TYPE ANY,
*                 <tabline_2> TYPE ANY,
*                 <value> TYPE ANY,
*                 <value2> TYPE ANY,
*                 <relat> TYPE graph_tabl.
*
**--Check if we already have found this
*  LOOP AT it_conflicting_changes WHERE
*    type     = i_change1-type  AND
*    table    = i_change1-table AND
*    objectid = i_change1-objectid.
*    READ TABLE it_conflicting_changes WITH KEY
*     type      = i_change2-type
*     table     = i_change2-table
*      objectid = i_change2-objectid
*      linkid   = it_conflicting_changes-linkid
*      TRANSPORTING NO FIELDS.
*    IF sy-subrc = 0.
*      lf_already_found = 'X'.
*      EXIT.
*    ENDIF.
*  ENDLOOP.
*  CHECK lf_already_found IS INITIAL.
*  SORT it_relations BY checktable tabname.
*
**--Check if 2 changes are related
*  IF i_change1-type = 'CHANGEDOC'.
**--Get the change document details
*    REFRESH : lt_cdpos1.
*    SELECT tabname tabkey FROM cdpos  "#EC CI_SEL_NESTED "#EC CI_NOORDER
*    INTO CORRESPONDING FIELDS OF TABLE lt_cdpos1 WHERE
*      objectclas  = i_change1-table AND
*      objectid    = i_change1-objectid.
*
*    SORT lt_cdpos1 BY tabname tabkey.
*    DELETE ADJACENT DUPLICATES FROM lt_cdpos1 COMPARING tabname tabkey.
*  ENDIF.
*  IF i_change2-type = 'CHANGEDOC'.
**  --Get the change document details
*    REFRESH : lt_cdpos2.
*    SELECT tabname tabkey FROM cdpos "#EC CI_SEL_NESTED  "#EC CI_NOORDER
*    INTO CORRESPONDING FIELDS OF TABLE lt_cdpos2 WHERE
*      objectclas  = i_change2-table AND
*      objectid    = i_change2-objectid.
*
*    SORT lt_cdpos2 BY tabname tabkey.
*    DELETE ADJACENT DUPLICATES FROM lt_cdpos2 COMPARING tabname tabkey.
*  ENDIF.
*
*
*  LOOP AT lt_cdpos1.
**--Get the key in a proper structure
*    CREATE DATA l_tabline1 TYPE (lt_cdpos1-tabname).
*    ASSIGN l_tabline1->* TO <tabline_1>.
*    MOVE lt_cdpos1-tabkey TO <tabline_1>.
*    PERFORM get_fields
*      TABLES lt_fields
*      USING  lt_cdpos1-tabname
*      CHANGING lf_no_table .
*    .
*    CHECK lf_no_table <> 'X'.
**--Create where clause
*    REFRESH : lt_where.
*    l_idx = 0.
*    LOOP AT lt_fields WHERE tabname = lt_cdpos1-tabname AND
*                            keyflag = 'X'.
*      IF l_idx = 0.
*        CONCATENATE lt_fields-fieldname '=' ''''
*                    INTO lt_where-line SEPARATED BY space.
*
**            CONCATENATE lt_where-line l_where_field ''''
**                        INTO lt_where-line.
*      ELSE.
*        CONCATENATE 'AND' lt_fields-fieldname '=' ''''
*                    INTO lt_where-line SEPARATED BY space.
*      ENDIF.
*      ASSIGN COMPONENT lt_fields-fieldname
*      OF STRUCTURE   <tabline_1>
*      TO <value>.
*      CHECK sy-subrc = 0.
*      l_where_field = <value>.
*      CONDENSE l_where_field.
*
*      CONCATENATE lt_where-line l_where_field
*      '''' INTO lt_where-line.
*      APPEND lt_where.
*      ADD 1 TO l_idx.
*    ENDLOOP.
**--Get the full record
**--Todo : on unicode systems use /PSYNG/ER_UCD_DYN_SQL (dynamically)
*    SELECT SINGLE * INTO <tabline_1>   "#EC CI_SEL_NESTED
*             FROM  (lt_cdpos1-tabname)
*             WHERE (lt_where).
*    IF sy-subrc <> 0.
*      EXIT.
*    ENDIF.
**--Find related tables in lt_cdpos2
*    LOOP AT it_relations
*    WHERE
*      tabname = lt_cdpos1-tabname.
**      AND
**      checktable = lt_cdpos2-tabname.
*      AT END OF checktable.
*        LOOP AT lt_cdpos2 WHERE "tabname = it_relations-tabname OR
*                                tabname = it_relations-checktable.
*          PERFORM get_fields
*            TABLES lt_fields
*            USING  lt_cdpos2-tabname
*            CHANGING lf_no_table .
*          CHECK lf_no_table <> 'X'.
**  --Get the key in a proper structure
*          CREATE DATA l_tabline2 TYPE (lt_cdpos2-tabname).
*          ASSIGN l_tabline2->* TO <tabline_2>.
*          MOVE lt_cdpos2-tabkey TO <tabline_2>.
**      --Create where clause
*          REFRESH : lt_where.
*          l_idx = 0.
*          LOOP AT lt_fields WHERE tabname = lt_cdpos2-tabname AND
*                                  keyflag = 'X'.
*            IF l_idx = 0.
*              CONCATENATE lt_fields-fieldname '=' ''''
*                          INTO lt_where-line SEPARATED BY space.
*
**                  CONCATENATE lt_where-line l_where_field ''''
**                              INTO lt_where-line.
*            ELSE.
*              CONCATENATE 'AND' lt_fields-fieldname '=' ''''
*                          INTO lt_where-line SEPARATED BY space.
*            ENDIF.
*            ASSIGN COMPONENT lt_fields-fieldname
*            OF STRUCTURE   <tabline_2>
*            TO <value>.
*            CHECK sy-subrc = 0.
*            l_where_field = <value>.
*            CONDENSE l_where_field.
*
*            CONCATENATE lt_where-line l_where_field
*            '''' INTO lt_where-line.
*            APPEND lt_where.
*            ADD 1 TO l_idx.
*          ENDLOOP.
**      --Get the full record
**   --Todo : on unicode systems use /PSYNG/ER_UCD_DYN_SQL (dynamically)
*          SELECT SINGLE * INTO <tabline_2>  "#EC CI_SEL_NESTED
*                   FROM  (lt_cdpos2-tabname)
*                   WHERE (lt_where).
*          IF sy-subrc <> 0.
*            EXIT.
*          ENDIF.
*
** --Check if, when we load the two records from their respective tables
**  one of them contains the key of the other, if so, set lf_related to X
*          LOOP AT it_relations ASSIGNING <relat> WHERE
*            tabname    = lt_cdpos1-tabname AND
*            checktable = lt_cdpos2-tabname.
*            LOOP AT lt_fields WHERE tabname   = lt_cdpos2-tabname AND
*                                    keyflag   = 'X' AND
*                                    fieldname =  <relat>-fieldname.
*              READ TABLE lt_fields WITH KEY tabname = lt_cdpos2-tabname
**                                            keyflag   = 'X'
*                                         fieldname =  <relat>-fieldname
*                                   TRANSPORTING NO FIELDS.
*              CHECK sy-subrc = 0.
**--One of the tables contains a field that is not a key that the other
**  table also has
*              ASSIGN COMPONENT <relat>-fieldname
*              OF STRUCTURE   <tabline_2>
*              TO <value2>.
*              ASSIGN COMPONENT <relat>-fieldname
*              OF STRUCTURE   <tabline_1>
*              TO <value>.
*              IF <value> = <value2>.
*                lf_related = 'X'.
*
*              ENDIF.
*            ENDLOOP.
*          ENDLOOP.
*        ENDLOOP.
*      ENDAT.
*    ENDLOOP.
*  ENDLOOP.
*
*
**--Add to results
*  CHECK lf_related = 'X'.
*  ADD 1 TO g_linkid.
*  it_conflicting_changes-linkid = g_linkid.
*  it_conflicting_changes-bname = i_bname.
*  it_conflicting_changes-conid = i_conid.
**--Change 1
*  it_conflicting_changes-funid    = i_funid1.
*  it_conflicting_changes-type     = i_change1-type.
*  it_conflicting_changes-objectid = i_change1-objectid.
*  it_conflicting_changes-table    = i_change1-table.
*  it_conflicting_changes-logkey   = i_change1-logkey.
*
*  APPEND it_conflicting_changes.
**--Change 2
*  it_conflicting_changes-funid    = i_funid2.
*  it_conflicting_changes-type     = i_change2-type.
*  it_conflicting_changes-objectid = i_change2-objectid.
*  it_conflicting_changes-table    = i_change2-table.
*  it_conflicting_changes-logkey   = i_change2-logkey.
*
*  APPEND it_conflicting_changes.
*ENDFORM.                    " check_change_is_related
*&---------------------------------------------------------------------*
*&      Form  get_fields
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_FIELDS  text
*      -->P_LT_CDPOS1_TABNAME  text
*----------------------------------------------------------------------*
FORM get_fields TABLES   et_fields STRUCTURE dfies
                USING    i_tabname
                CHANGING ef_no_table.
  DATA : lt_fields TYPE TABLE OF dfies WITH HEADER LINE,
         l_class   TYPE dd02v-tabclass.
  READ TABLE et_fields WITH KEY tabname = i_tabname
  TRANSPORTING NO FIELDS.
  IF sy-subrc <> 0.
    CALL FUNCTION 'DDIF_FIELDINFO_GET'
      EXPORTING
        tabname        = i_tabname
*       FIELDNAME      = ' '
*       LANGU          = SY-LANGU
*       LFIELDNAME     = ' '
*       ALL_TYPES      = ' '
      IMPORTING
*       X030L_WA       =
        ddobjtype      = l_class
*       DFIES_WA       =
*       LINES_DESCR    =
      TABLES
        dfies_tab      = lt_fields
*       FIXED_VALUES   =
      EXCEPTIONS
        not_found      = 1
        internal_error = 2
        OTHERS         = 3.
    IF sy-subrc = 0 AND ( l_class = 'TRANSP' OR l_class = 'POOL'
                          OR l_class = 'VIEW' ).
      APPEND LINES OF lt_fields TO et_fields.
      SORT et_fields BY tabname fieldname.
      CLEAR ef_no_table.
    ELSE.
      ef_no_table = 'X'.
    ENDIF.
  ENDIF.

ENDFORM.                    " get_fields


*---------------------------------------------------------------------*
*       FORM stat_analysis_func                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_RESULTS                                                    *
*  -->  I_HIST_START                                                  *
*  -->  I_HIST_END                                                    *
*  -->  I_VRSIO                                                       *
*---------------------------------------------------------------------*
FORM stat_analysis_func
TABLES   et_results   STRUCTURE /psyng/sw_output_org
         it_functtran STRUCTURE /psyng/functtran
USING    i_hist_start TYPE dats
         i_hist_end   TYPE dats
         i_vrsio      TYPE /psyng/sodvrsio.
  DATA : lt_user_stat TYPE STANDARD TABLE OF /psyng/sw_entry
                      WITH HEADER LINE,
         lt_hitlist   TYPE TABLE OF /psyng/hitlist   WITH HEADER LINE,
         lt_confdet   TYPE TABLE OF /psyng/confdet   WITH HEADER LINE,
         lt_functtran TYPE TABLE OF /psyng/functtran WITH HEADER LINE.
  TYPES: BEGIN OF userexe_typ,
           bname LIKE usr02-bname,
           tcode LIKE sy-tcode,
         END OF userexe_typ.
  DATA: lt_userexe TYPE SORTED TABLE OF userexe_typ WITH UNIQUE KEY
                bname tcode
                WITH HEADER LINE.

  FIELD-SYMBOLS : <res>  TYPE /psyng/sw_output_org,
                  <stat> TYPE /psyng/sw_entry.
  RANGES : lr_bname FOR lt_userexe-bname.
*--Load conflict details and tcodes
  IF it_functtran[] IS INITIAL.
    SELECT functionid tcode FROM /psyng/functtran    "#EC CI_SEL_NESTED
      INTO CORRESPONDING FIELDS
                           OF  TABLE lt_functtran WHERE vrsio = i_vrsio.
  ELSE.
    lt_functtran[] = it_functtran[].
  ENDIF.
* SELECT conid functionid  FROM /psyng/confdet INTO CORRESPONDING FIELDS
*                          OF  TABLE lt_confdet WHERE vrsio = i_vrsio.
  lr_bname-sign = 'I'.
  lr_bname-option  = 'EQ'.
  LOOP AT et_results ASSIGNING <res>.
    lr_bname-low = <res>-bname.
    COLLECT lr_bname.
  ENDLOOP.

*--Read all Stat DATA per month
  LOOP AT months.
    FREE : lt_user_stat, lt_hitlist.
    CALL FUNCTION '/PSYNG/SW_SUMMARY_STATISTIC'
      EXPORTING
        startdate = months-month
      TABLES
        user_stat = lt_user_stat
        hitlist   = lt_hitlist.
    SORT lt_hitlist   BY account tcode.
    SORT lt_user_stat BY account entry_id.
    LOOP AT lt_user_stat WHERE entry_id+72(1) = 'T'.  "tcode
      CHECK lt_user_stat-account IN lr_bname.
      lt_userexe-tcode = lt_user_stat-entry_id(20).
      CONDENSE lt_userexe-tcode NO-GAPS.
      lt_userexe-bname = lt_user_stat-account.
      INSERT TABLE lt_userexe.
    ENDLOOP.
    LOOP AT lt_hitlist WHERE tcode   <> space
                         AND account IN lr_bname.
      lt_userexe-bname = lt_hitlist-account.
      lt_userexe-tcode = lt_hitlist-tcode.
      INSERT TABLE lt_userexe.
    ENDLOOP.
  ENDLOOP.

  LOOP AT et_results ASSIGNING <res>                    "#EC CI_NOORDER
    WHERE executed IS INITIAL.
    LOOP AT lt_functtran                                "#EC CI_NOORDER
      WHERE functionid = <res>-funid.
*--look for tcode in execution history
*             search hitlist
      READ TABLE lt_userexe WITH KEY bname  = <res>-bname
                                     tcode  = lt_functtran-tcode
      BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        <res>-executed =  'X'.
        EXIT.                                           "#EC CI_NOORDER
      ENDIF.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    " stat_analysis

*---------------------------------------------------------------------*
*       FORM load_rfc                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_USER_RFC                                                   *
*  -->  ET_RFCDES                                                     *
*---------------------------------------------------------------------*
FORM load_rfc
    TABLES
      it_user_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
      et_rfcdes STRUCTURE rfcdes.
  .
  DATA : l_rfcdest        TYPE rfcdes-rfcdest,
         l_system_msg(80) TYPE c,
         l_local_sys      TYPE rfcdest.
  FIELD-SYMBOLS : <rfcdes> TYPE rfcdes.

  IF NOT it_user_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_user_rfc.
  ENDIF.
*--Get sysid and mandt into field RFCOPTIONS
  LOOP AT et_rfcdes ASSIGNING <rfcdes>.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
                  .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
    CALL FUNCTION '/PSYNG/BC_GET_SYSTEM_ID'
      DESTINATION <rfcdes>-rfcdest
      IMPORTING
        e_rfcdest             = l_rfcdest
      EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH
          text-e02
          l_rfcdest
          l_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH
          text-e02
          l_rfcdest.
      ENDCASE.
      COMMIT WORK.
    ELSE.
      <rfcdes>-rfcoptions = l_rfcdest.
    ENDIF.
  ENDLOOP.

*--DHORIONS 2011/01/20 : Delete any RFC pointing to the local system.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE  et_rfcdes WHERE rfcoptions = l_local_sys
  AND rfcdest <> 'LOCAL'.
*Case 2061 - If 2 rfc destinations point to the same system-client,
*            we still only output the results once.
  SORT et_rfcdes BY rfcoptions.
  DELETE ADJACENT DUPLICATES FROM et_rfcdes COMPARING rfcoptions.

ENDFORM.                    " validate_user_rfc

*---------------------------------------------------------------------*
*       FORM get_db_change_log                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_DETAILS                                                    *
*  -->  ET_DBLOG                                                      *
*---------------------------------------------------------------------*
FORM get_db_change_log
  TABLES  it_details  STRUCTURE /psyng/sw_level3_details
          et_dblog    STRUCTURE /psyng/dblog
          it_keys    STRUCTURE /psyng/sw_level3_keys
          it_tabinfo STRUCTURE /psyng/sw_level3_tabinfo.
  DATA : lt_dblog TYPE TABLE OF /psyng/dblog WITH HEADER LINE.
  DATA:e_begda TYPE dats,
       e_begtm TYPE tims VALUE '000000',
       e_endda TYPE dats,
       e_endtm TYPE tims VALUE '235959'.
  DATA:et_tcodes TYPE TABLE OF /psyng/range_tcode WITH
  HEADER LINE.
DATA:et_users         TYPE TABLE OF /psyng/range_bname WITH HEADER LINE,
     new_log_key(250) TYPE c,
     l_key(250)       TYPE c,
     l_tabname        TYPE ddobjname.

  e_begda =  sy-datum.

  REFRESH:et_tcodes, et_users.
  et_tcodes-sign = 'I'.
  et_tcodes-option = 'EQ'.
  et_users-sign = 'I'.
  et_users-option = 'EQ'.

  LOOP AT it_details WHERE type EQ 'TABLOG'.
*  if not e_begda eq 0.
    IF it_details-date LT e_begda.
      e_begda = it_details-date.
    ENDIF.

    IF it_details-date GT e_endda.
      e_endda = it_details-date.
    ENDIF.
    et_tcodes-low = it_details-tcode.
    COLLECT et_tcodes.
    et_users-low = it_details-bname.
    COLLECT et_users.

    CLEAR new_log_key.
    READ TABLE it_tabinfo WITH KEY tabname = it_details-table.
    IF sy-subrc NE 0.
      REFRESH:it_tabinfo.
      l_tabname = it_details-table.
      PERFORM get_field_info
      TABLES it_tabinfo
      USING l_tabname.
      l_key = it_details-logkey.
      CLEAR new_log_key.
      PERFORM change_key
                        TABLES it_tabinfo
                        USING l_key
                               l_tabname
                         CHANGING new_log_key.

*      it_details-logkey = new_log_key.
*      MODIFY it_details TRANSPORTING logkey.
      it_keys-tabname = it_details-table.
      it_keys-old_key = l_key.
      it_keys-new_key = new_log_key.
      APPEND it_keys.


    ELSE.

      READ TABLE it_keys WITH KEY tabname = it_details-table
                                  old_key = it_details-logkey
                                  TRANSPORTING new_key.
      IF sy-subrc NE 0.
        l_key = it_details-logkey.
        CLEAR new_log_key.
        PERFORM change_key
          TABLES it_tabinfo
          USING l_key
                                 l_tabname
                           CHANGING new_log_key.
        it_keys-tabname = it_details-table.
        it_keys-old_key = l_key.
        it_keys-new_key = new_log_key.
        APPEND it_keys.
      ENDIF.
    ENDIF.
  ENDLOOP.
*--Now load the actual changes.
  CALL FUNCTION '/PSYNG/BASIS_GET_DBLOG'
    EXPORTING
      i_begda  = e_begda
      i_begtm  = '000000'
      i_endda  = e_endda
      i_endtm  = '235959'
      i_limit  = 0
    TABLES
      it_bname = et_users
      it_tcode = et_tcodes
      et_dblog = et_dblog.

ENDFORM.                    " get_db_change_log

*---------------------------------------------------------------------*
*       FORM get_change_doc_log                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_DETAILS                                                    *
*  -->  ET_CDPOS                                                      *
*  -->  ET_KEYS                                                       *
*  -->  ET_TABINFO                                                    *
*---------------------------------------------------------------------*
FORM get_change_doc_log
  TABLES   it_details STRUCTURE /psyng/sw_level3_details
           et_cdpos   STRUCTURE cdpos
           et_keys    STRUCTURE /psyng/sw_level3_keys
           et_tabinfo STRUCTURE /psyng/sw_level3_tabinfo.

  TYPES:BEGIN OF type_cdhdr,
          objectclas TYPE cdhdr-objectclas,
          objectid   TYPE cdhdr-objectid,
          username   TYPE cdhdr-username,
        END OF type_cdhdr.
* data:lt_cdhdr type hashed table typ_cdhdr with unique key objectclas
*objectid username with header line.
  DATA:lt_cdhdr_tmp TYPE TABLE OF type_cdhdr WITH HEADER LINE.
  DATA:lt_cdhdr TYPE TABLE OF cdhdr WITH HEADER LINE.
  DATA:l_tabname        TYPE ddobjname,
       l_key(250)       TYPE c,
       new_log_key(250) TYPE c.

  LOOP AT it_details WHERE type EQ 'CHANGEDOC'.
    lt_cdhdr_tmp-objectid = it_details-logkey.
    lt_cdhdr_tmp-objectclas = it_details-table.
    lt_cdhdr_tmp-username = it_details-bname.
    COLLECT lt_cdhdr_tmp.
  ENDLOOP.

  CHECK NOT lt_cdhdr_tmp[] IS INITIAL.
  SELECT * FROM cdhdr           "#EC CI_SEL_NESTED "#EC CI_NO_TRANSFORM
   INTO TABLE lt_cdhdr
   FOR ALL ENTRIES IN lt_cdhdr_tmp
  WHERE objectclas EQ lt_cdhdr_tmp-objectclas AND
     objectid EQ lt_cdhdr_tmp-objectid AND
     username EQ lt_cdhdr_tmp-username.
  CHECK sy-subrc EQ 0 AND NOT lt_cdhdr[] IS INITIAL.

  SELECT *      "#EC CI_SEL_NESTED "#EC CI_NO_TRANSFORM "#EC CI_NOORDER
    FROM cdpos INTO TABLE  et_cdpos
    FOR ALL ENTRIES IN lt_cdhdr
       WHERE objectclas EQ lt_cdhdr-objectclas AND
       objectid EQ lt_cdhdr-objectid AND
       changenr EQ lt_cdhdr-changenr
       ORDER BY PRIMARY KEY.
  CHECK sy-subrc EQ 0.

  SORT et_cdpos BY tabname.

  LOOP AT  et_cdpos.
    l_tabname =  et_cdpos-tabname.
    l_key =  et_cdpos-tabkey.
    AT NEW tabname.
      PERFORM get_field_info
      TABLES et_tabinfo
      USING l_tabname.
    ENDAT.
    READ TABLE et_keys WITH KEY tabname =  et_cdpos-tabname
                                old_key =  et_cdpos-tabkey
                                objectid =  et_cdpos-objectid
                                TRANSPORTING NO FIELDS.
    IF sy-subrc NE 0.
      CLEAR new_log_key.
      PERFORM change_key
                         TABLES et_tabinfo
                         USING l_key
                               l_tabname
                         CHANGING new_log_key.
      et_keys-tabname =  et_cdpos-tabname.
      et_keys-old_key = l_key.
      et_keys-new_key = new_log_key.
      et_keys-objectid =  et_cdpos-objectid.
      CONCATENATE sy-sysid sy-mandt INTO et_keys-system.
      APPEND et_keys.
    ENDIF.
  ENDLOOP.


ENDFORM.                    " get_change_doc_log

*---------------------------------------------------------------------*
*       FORM change_key                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  L_KEY                                                         *
*  -->  L_TAB                                                         *
*  -->  NEW_LOG_KEY                                                   *
*---------------------------------------------------------------------*
FORM change_key
    TABLES it_tabinfo STRUCTURE /psyng/sw_level3_tabinfo
    USING    l_key
                         l_tab
                CHANGING new_log_key.
  DATA:l_offset        TYPE i,
       l_key_value(30) TYPE c.
  DATA:l_fieldname TYPE dfies-fieldname,
       l_leng      TYPE i,
       l_tabname   TYPE ddobjname,
       lf_end_key  TYPE c,
       l_key_len   TYPE i.

  l_key_len = strlen( l_key ).
  CLEAR: l_offset,lf_end_key.

  LOOP AT it_tabinfo WHERE tabname EQ l_tab AND keyflag EQ 'X'.
    l_fieldname = it_tabinfo-fieldname.
    l_leng = it_tabinfo-leng.
    l_key_len = l_key_len - l_leng.
    IF l_key_len EQ 0.
      lf_end_key = 'X'.
    ENDIF.
    l_key_value = l_key+l_offset(l_leng).
    l_offset = l_offset + l_leng.
*    AT LAST.
    IF lf_end_key = 'X'.
      CONCATENATE new_log_key l_fieldname '=' l_key_value  INTO
      new_log_key.
      CONDENSE new_log_key NO-GAPS.
      CONTINUE.
    ENDIF.
*    ENDAT.
    CONCATENATE new_log_key l_fieldname '=' l_key_value ',' INTO
     new_log_key.
    CONDENSE new_log_key NO-GAPS.
  ENDLOOP.

ENDFORM.                    " change_key


*---------------------------------------------------------------------*
*       FORM get_field_info                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_TABINFO                                                    *
*  -->  L_TABNAME                                                     *
*---------------------------------------------------------------------*
FORM get_field_info
TABLES it_tabinfo STRUCTURE /psyng/sw_level3_tabinfo
USING    l_tabname.
  DATA:lt_dfies TYPE TABLE OF dfies WITH HEADER LINE.

  READ TABLE it_tabinfo WITH KEY tabname = l_tabname.
  CHECK sy-subrc NE 0.

  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      tabname        = l_tabname
    TABLES
      dfies_tab      = lt_dfies
    EXCEPTIONS
      not_found      = 1
      internal_error = 2
      OTHERS         = 3.
  IF sy-subrc <> 0.
*-- when looking for dbtablog & table doesn't exist in the system
*-- Case#21246 odubey 2021/10/29
    IF sy-subrc = 1.
      sy-msgty = 'S'.
    ENDIF.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    LOOP AT lt_dfies.
      it_tabinfo-tabname = lt_dfies-tabname.
      it_tabinfo-fieldname = lt_dfies-fieldname .
      it_tabinfo-leng = lt_dfies-leng .
      it_tabinfo-fieldtext = lt_dfies-fieldtext.
      it_tabinfo-keyflag = lt_dfies-keyflag.
      CONCATENATE sy-sysid sy-mandt INTO it_tabinfo-system.
      APPEND it_tabinfo.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " get_feild_info
*---------------------------------------------------------------------*
*       FORM add_changedoc_data                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_DETAILS                                                    *
*  -->  IT_CDPOS                                                      *
*  -->  IT_TABINFO                                                    *
*  -->  IT_KEYS                                                       *
*  -->  STRUCTIRE                                                     *
*  -->  /PSYNG/SW_LEVEL3_KEYS                                         *
*  -->  IS_DETAIL                                                     *
*---------------------------------------------------------------------*
FORM add_changedoc_data
TABLES et_details STRUCTURE /psyng/sw_level3_display
       it_cdpos   STRUCTURE cdpos
       it_tabinfo STRUCTURE /psyng/sw_level3_tabinfo
       it_keys    STRUCTURE /psyng/sw_level3_keys
USING is_detail TYPE /psyng/sw_level3_details.
  DATA:l_char.
  MOVE-CORRESPONDING is_detail TO et_details.
  LOOP AT it_cdpos WHERE objectid EQ is_detail-logkey AND
                   changenr EQ is_detail-changenr."change no included GG
***    direct check for initial not working
    CLEAR l_char.
    l_char = it_cdpos-value_new.
    IF NOT l_char IS INITIAL.
      l_char = it_cdpos-value_old.
    ENDIF.
*    CHECK NOT ( l_char IS INITIAL and it_cdpos-chngind = 'U').
***    direct check for initial not working
*    IF NOT ( it_cdpos-value_new IS INITIAL AND
*                it_cdpos-value_old IS INITIAL ).
    et_details-tcode   = is_detail-tcode.
    et_details-table   = it_cdpos-tabname.
    et_details-type    = is_detail-type.
    et_details-date    = is_detail-date.
    et_details-time    = is_detail-time.
    et_details-value = it_cdpos-value_old.
    et_details-newval = it_cdpos-value_new.
    et_details-fieldname = it_cdpos-fname.
    et_details-change_type = it_cdpos-chngind.

    READ TABLE  it_tabinfo WITH KEY tabname = it_cdpos-tabname
                                    fieldname = it_cdpos-fname
                                    system   = is_detail-system
                                    TRANSPORTING fieldtext.
    IF sy-subrc EQ 0.
      et_details-fieldtext = it_tabinfo-fieldtext.
    ENDIF.

    READ TABLE it_keys WITH KEY tabname = it_cdpos-tabname
                                old_key = it_cdpos-tabkey
                                objectid = it_cdpos-objectid
                                system   = is_detail-system
                                TRANSPORTING new_key.
    IF sy-subrc EQ 0.
      et_details-logkey  = it_keys-new_key.
    ELSE.
      et_details-logkey  = is_detail-logkey.
    ENDIF.

    APPEND et_details.
    CLEAR:et_details-fieldtext,et_details-value,
          et_details-newval, et_details-fieldname.
*    ENDIF.
  ENDLOOP.

ENDFORM.                    " add_changedoc_data
*---------------------------------------------------------------------*
*       FORM add_tablog_data                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_DETAILS                                                    *
*  -->  IT_DBLOG                                                      *
*  -->  IT_TABINFO                                                    *
*  -->  IT_KEYS                                                       *
*  -->  IS_DETAIL                                                     *
*---------------------------------------------------------------------*
FORM add_tablog_data
TABLES et_details STRUCTURE /psyng/sw_level3_display
       it_dblog   STRUCTURE /psyng/dblog
       it_tabinfo STRUCTURE /psyng/sw_level3_tabinfo
       it_keys    STRUCTURE /psyng/sw_level3_keys
USING is_detail TYPE /psyng/sw_level3_details.

  MOVE-CORRESPONDING is_detail TO et_details.

  et_details-tcode   = is_detail-tcode.
  et_details-table   = is_detail-table.
  et_details-type    = is_detail-type.
*          et_details-logkey  = is_detail-logkey.
  READ TABLE it_dblog WITH KEY username = is_detail-bname
                               tcode    = is_detail-tcode
                               tabname  = is_detail-table
*                               logkey   = is_detail-logkey
                               logdate  = is_detail-date
                               logtime  = is_detail-time.
  IF sy-subrc EQ 0.
    et_details-date        = it_dblog-logdate.
    et_details-time        = it_dblog-logtime.

    et_details-value       = it_dblog-value.
    et_details-newval      = it_dblog-newval.
    et_details-fieldname   = it_dblog-fieldname.
    et_details-change_type = it_dblog-optype.

    READ TABLE  it_tabinfo WITH KEY tabname = is_detail-table
                                 fieldname = et_details-fieldname
                                 system   = is_detail-system
                                         TRANSPORTING fieldtext.
    IF sy-subrc EQ 0.
      et_details-fieldtext = it_tabinfo-fieldtext.
    ENDIF.

    READ TABLE it_keys WITH KEY tabname = is_detail-table
                            old_key = is_detail-logkey
                            system   = is_detail-system
                            TRANSPORTING new_key.
    IF sy-subrc EQ 0.
      et_details-logkey  = it_keys-new_key.
    ELSE.
      et_details-logkey  = is_detail-logkey.
    ENDIF.

    APPEND et_details.
  ENDIF.

  CLEAR:et_details-fieldtext,et_details-value,
        et_details-newval, et_details-fieldname.

ENDFORM.                    " add_tablog_data
*---------------------------------------------------------------------*
*       FORM ta_stat_analysis                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_RESULTS                                                    *
*  -->  IT_FUNCTTRAN                                                  *
*  -->  IT_CONFDET                                                    *
*  -->  I_HIST_START                                                  *
*  -->  I_HIST_END                                                    *
*  -->  I_VRSIO                                                       *
*---------------------------------------------------------------------*
FORM ta_stat_analysis
TABLES   et_results   STRUCTURE /psyng/sw_sod_output_org
         it_functtran STRUCTURE /psyng/functtran
         it_services  STRUCTURE /psyng/functtran
         it_confdet   STRUCTURE /psyng/confdet
USING    i_hist_start TYPE dats
         i_hist_end   TYPE dats
         i_vrsio      TYPE /psyng/sodvrsio
         if_ta_v21    TYPE flag
         i_ta_version TYPE  /psyng/prog_vrsio.
  DATA : lt_user_stat     TYPE STANDARD TABLE OF /psyng/sw_entry
                      WITH HEADER LINE,
      lt_hitlist       TYPE TABLE OF /psyng/hitlist    WITH HEADER LINE,
      lt_confdet       TYPE TABLE OF /psyng/confdet    WITH HEADER LINE,
      lt_functtran     TYPE TABLE OF /psyng/functtran  WITH HEADER LINE,
      lf_conflictfound TYPE flag,
      lf_tcodefound    TYPE flag.
  TYPES: BEGIN OF userexe_typ,
           bname LIKE usr02-bname,
           tcode LIKE sy-tcode,
         END OF userexe_typ.
  DATA:
 lt_userexe TYPE SORTED TABLE OF userexe_typ             WITH UNIQUE KEY
                                                         bname tcode
                                                       WITH HEADER LINE,
lt_dates   TYPE TABLE OF        /psyng/sw_sel_opts_date WITH HEADER LINE,
lt_hist    TYPE TABLE OF        /psyng/bc_dhuc00        WITH HEADER LINE,
lt_tcodes  TYPE TABLE OF        /psyng/range_tcode      WITH HEADER LINE,
lt_tcdserv TYPE TABLE OF        /psyng/range_tcode_srv  WITH HEADER LINE,
lt_summary TYPE TABLE OF        /psyng/bc_uh_summary    WITH HEADER LINE.

  FIELD-SYMBOLS : <res>  TYPE /psyng/sw_sod_output_org,
                  <stat> TYPE /psyng/sw_entry.
  RANGES : lr_bname FOR lt_userexe-bname.
*--Load conflict details and tcodes
  IF it_functtran[] IS INITIAL.
    SELECT functionid tcode                          "#EC CI_SEL_NESTED
       FROM /psyng/functtran
          INTO CORRESPONDING FIELDS OF  TABLE lt_functtran
             WHERE vrsio = i_vrsio.
  ELSE.
    lt_functtran[] = it_functtran[].
  ENDIF.
  IF it_confdet[] IS INITIAL.
    SELECT conid functionid                          "#EC CI_SEL_NESTED
      FROM /psyng/confdet INTO CORRESPONDING FIELDS OF  TABLE lt_confdet
                          WHERE vrsio = i_vrsio.
  ELSE.
    lt_confdet[] = it_confdet[].
  ENDIF.

*--Create User Range
  lr_bname-sign = 'I'.
  lr_bname-option  = 'EQ'.
  LOOP AT et_results ASSIGNING <res>.
    lr_bname-low = <res>-bname.
    COLLECT lr_bname.
  ENDLOOP.
*--Create Tcode Range
  lt_tcodes-sign   = 'I'.
  lt_tcodes-option = 'EQ'.
  LOOP AT lt_functtran.
    lt_tcodes-low    = lt_functtran-tcode.
    COLLECT lt_tcodes.
  ENDLOOP.
*--Add odata services to that range
  IF i_ta_version >= '2.6'.
    LOOP AT lt_tcodes.
      MOVE-CORRESPONDING lt_tcodes TO lt_tcdserv.
      APPEND lt_tcdserv.
    ENDLOOP.
    LOOP AT it_services.
      lt_tcdserv-low    = it_services-fioriid.
      COLLECT lt_tcdserv.
    ENDLOOP.
  ENDIF.


  lt_dates-sign   = 'I'.
  lt_dates-option = 'BT'.
  lt_dates-low    = i_hist_start.
  lt_dates-high   = i_hist_end.
  APPEND lt_dates.
  IF if_ta_v21 IS INITIAL.
    CALL FUNCTION gc_ta_func "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Function name is variable so it can’t be fixed.(12/12/24)
      EXPORTING
        if_updates = ' ' "not only updates
        if_icons   = ' '
        if_ftexts  = ' '
      TABLES
        it_users   = lr_bname
        it_date    = lt_dates
        it_tcode   = lt_tcodes
        ot_dhuc00  = lt_hist.
  ELSE.
    IF i_ta_version >= '2.6'.
*--Analyze History based on services and tcodes
      CALL FUNCTION gc_ta_func_21 "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(12/12/24)
        EXPORTING
          if_quick_summary = 'X'
          if_webstats      = 'X'
        TABLES
          it_users         = lr_bname
          it_date          = lt_dates
          it_tcode         = lt_tcdserv
          et_summary       = lt_summary.
    ELSE.
*--Analyze History based on tcodes
      CALL FUNCTION gc_ta_func_21 "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Function name is variable so it can’t be fixed.(12/12/24)
        EXPORTING
          if_quick_summary = 'X'
        TABLES
          it_users         = lr_bname
          it_date          = lt_dates
          it_tcode         = lt_tcodes
          et_summary       = lt_summary.
    ENDIF.
    SORT lt_summary BY account tcode.
  ENDIF.

  LOOP AT et_results ASSIGNING <res> WHERE level2 IS INITIAL.
    lf_conflictfound = 'X'.
    LOOP AT lt_confdet WHERE conid = <res>-conid.       "#EC CI_NOORDER
      CLEAR lf_tcodefound.
      LOOP AT lt_functtran WHERE                        "#EC CI_NOORDER
      functionid = lt_confdet-functionid.
*--look for tcode in execution history
*             search hitlist
        IF if_ta_v21 IS INITIAL.
          READ TABLE lt_hist                            "#EC CI_NOORDER
          WITH KEY account  = <res>-bname
                                         tcode  = lt_functtran-tcode
          BINARY SEARCH TRANSPORTING NO FIELDS.
        ELSE.
          READ TABLE lt_summary                         "#EC CI_NOORDER
          WITH KEY account  = <res>-bname
                                         tcode  = lt_functtran-tcode
          BINARY SEARCH TRANSPORTING NO FIELDS.
        ENDIF.
        IF sy-subrc = 0.
          lf_tcodefound = 'X'.
          EXIT.                                         "#EC CI_NOORDER
        ENDIF.
      ENDLOOP.
      IF i_ta_version >= '2.6' AND lf_tcodefound IS INITIAL.
        LOOP AT it_services WHERE                       "#EC CI_NOORDER
           functionid = lt_confdet-functionid.
*  --      look for service in execution history

          READ TABLE lt_summary                         "#EC CI_NOORDER
          WITH KEY account  = <res>-bname
                   tcode    = it_services-fioriid
          BINARY SEARCH TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            lf_tcodefound = 'X'.
            EXIT.                                       "#EC CI_NOORDER
          ENDIF.
        ENDLOOP.
      ENDIF.
      IF lf_tcodefound IS INITIAL.
        CLEAR lf_conflictfound.
        EXIT.                                           "#EC CI_NOORDER
      ENDIF.
    ENDLOOP.
    <res>-level2 =  lf_conflictfound .
  ENDLOOP.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM ta_stat_analysis_func                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_RESULTS                                                    *
*  -->  IT_FUNCTTRAN                                                  *
*  -->  I_HIST_START                                                  *
*  -->  I_HIST_END                                                    *
*  -->  I_VRSIO                                                       *
*---------------------------------------------------------------------*
FORM ta_stat_analysis_func
TABLES   et_results   STRUCTURE /psyng/sw_output_org
         it_functtran STRUCTURE /psyng/functtran
         it_services  STRUCTURE /psyng/functtran
USING    i_hist_start TYPE dats
         i_hist_end   TYPE dats
         i_vrsio      TYPE /psyng/sodvrsio
         if_ta_v21    TYPE flag
         i_ta_version TYPE  /psyng/prog_vrsio.
  TYPES: BEGIN OF userexe_typ,
           bname LIKE usr02-bname,
           tcode LIKE sy-tcode,
         END OF userexe_typ.
  DATA :
    lt_user_stat  TYPE STANDARD TABLE OF /psyng/sw_entry
                                                       WITH HEADER LINE,
   lt_hitlist    TYPE TABLE OF /psyng/hitlist          WITH HEADER LINE,
   lt_confdet    TYPE TABLE OF /psyng/confdet          WITH HEADER LINE,
   lt_functtran  TYPE TABLE OF /psyng/functtran        WITH HEADER LINE,
   lf_tcodefound TYPE flag,
   lt_userexe    TYPE SORTED TABLE OF userexe_typ      WITH UNIQUE KEY
                                                       bname tcode
                                                       WITH HEADER LINE,
   lt_dates      TYPE TABLE OF /psyng/sw_sel_opts_date WITH HEADER LINE,
   lt_hist       TYPE TABLE OF /psyng/bc_dhuc00        WITH HEADER LINE,
   lt_tcodes     TYPE TABLE OF /psyng/range_tcode      WITH HEADER LINE,
   lt_tcdserv    TYPE TABLE OF /psyng/range_tcode_srv  WITH HEADER LINE,
   lt_summary    TYPE TABLE OF /psyng/bc_uh_summary    WITH HEADER LINE.

  FIELD-SYMBOLS :
    <res>  TYPE /psyng/sw_output_org,
    <stat> TYPE /psyng/sw_entry.
  RANGES :
   lr_bname   FOR lt_userexe-bname.
*--Load conflict details and tcodes
  IF it_functtran[] IS INITIAL.
    SELECT functionid tcode                          "#EC CI_SEL_NESTED
       FROM /psyng/functtran
         INTO CORRESPONDING FIELDS OF TABLE lt_functtran
            WHERE vrsio = i_vrsio.
  ELSE.
    lt_functtran[] = it_functtran[].
  ENDIF.
*--Create User Range
  lr_bname-sign = 'I'.
  lr_bname-option  = 'EQ'.
  LOOP AT et_results ASSIGNING <res>.
    lr_bname-low = <res>-bname.
    COLLECT lr_bname.
  ENDLOOP.
*--Create Tcode Range
  lt_tcodes-sign   = 'I'.
  lt_tcodes-option = 'EQ'.
  LOOP AT lt_functtran.
    lt_tcodes-low    = lt_functtran-tcode.
    COLLECT lt_tcodes.
  ENDLOOP.
*--Add odata services to that range
  IF i_ta_version >= '2.6'.
    LOOP AT lt_tcodes.
      MOVE-CORRESPONDING lt_tcodes TO lt_tcdserv.
      APPEND lt_tcdserv.
    ENDLOOP.
    LOOP AT it_services.
      lt_tcdserv-low    = it_services-fioriid.
      COLLECT lt_tcdserv.
    ENDLOOP.
  ENDIF.

  lt_dates-sign   = 'I'.
  lt_dates-option = 'BT'.
  lt_dates-low    = i_hist_start.
  lt_dates-high   = i_hist_end.
  APPEND lt_dates.
  IF if_ta_v21 IS INITIAL.
    CALL FUNCTION gc_ta_func "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(12/12/24)
      EXPORTING
        if_updates = ' ' "not only updates
        if_icons   = ' '
        if_ftexts  = ' '
      TABLES
        it_users   = lr_bname
        it_date    = lt_dates
        it_tcode   = lt_tcodes
        ot_dhuc00  = lt_hist.

    SORT lt_hist BY account tcode.
    DELETE ADJACENT DUPLICATES FROM lt_hist COMPARING account tcode.
  ELSE.
    IF i_ta_version >= '2.6'.
*--Analyze History based on services and tcodes
      CALL FUNCTION gc_ta_func_21 "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(12/12/24)
        EXPORTING
          if_quick_summary = 'X'
          if_webstats      = 'X'
        TABLES
          it_users         = lr_bname
          it_date          = lt_dates
          it_tcode         = lt_tcdserv
          et_summary       = lt_summary.
    ELSE.
*--Analyze History based on tcodes
      CALL FUNCTION gc_ta_func_21 "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(12/12/24)
        EXPORTING
          if_quick_summary = 'X'
        TABLES
          it_users         = lr_bname
          it_date          = lt_dates
          it_tcode         = lt_tcodes
          et_summary       = lt_summary.
    ENDIF.
    SORT lt_summary BY account tcode.
  ENDIF.
  LOOP AT et_results ASSIGNING <res>                    "#EC CI_NOORDER
  WHERE executed IS INITIAL.
    CLEAR lf_tcodefound.
    LOOP AT lt_functtran WHERE functionid = <res>-funid. "#EC CI_NOORDER
*--look for tcode in execution history
*             search hitlist
      IF if_ta_v21 IS INITIAL.
        READ TABLE lt_hist WITH KEY account  = <res>-bname
                                       tcode  = lt_functtran-tcode
        BINARY SEARCH TRANSPORTING NO FIELDS.
      ELSE.
        READ TABLE lt_summary WITH KEY account  = <res>-bname
                                       tcode  = lt_functtran-tcode
        BINARY SEARCH TRANSPORTING NO FIELDS.
      ENDIF.
      IF sy-subrc = 0.
        <res>-executed =  'X'.
        lf_tcodefound  = 'X'.
        EXIT.                                           "#EC CI_NOORDER
      ENDIF.
    ENDLOOP.
    IF i_ta_version >= '2.6' AND lf_tcodefound IS INITIAL.
      LOOP AT it_services WHERE                         "#EC CI_NOORDER
         functionid = <res>-funid.
*  --      look for service in execution history
        READ TABLE lt_summary                           "#EC CI_NOORDER
        WITH KEY account  = <res>-bname
                 tcode    = it_services-fioriid
        BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          <res>-executed = 'X'.
          lf_tcodefound  = 'X'.
          EXIT.                                         "#EC CI_NOORDER
        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDLOOP.
ENDFORM.                    " stat_analysis
*&---------------------------------------------------------------------*
*&      Form  check_ta_installed
*&---------------------------------------------------------------------*
*       Check if TA is installed.
*       Only do check once, store value in static flag
*----------------------------------------------------------------------*
*      <--P_LF_TA_INSTALLED  text
*----------------------------------------------------------------------*
FORM check_ta_installed CHANGING ef_ta_installed TYPE flag
                                 ef_ta_v21       TYPE flag
                                 e_ta_version    TYPE /psyng/prog_vrsio.
  STATICS : sf_checked   TYPE flag,
            sf_installed TYPE flag,
            sf_ta_v21    TYPE flag,
            s_version    TYPE /psyng/prog_vrsio.
  IF sf_checked = 'X'.
    ef_ta_installed = sf_installed.
    ef_ta_v21       = sf_ta_v21.
    e_ta_version    = s_version.
  ELSE.
    CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
      EXPORTING
        i_module         = 'TA'
      IMPORTING
        e_installed      = sf_installed
*       E_MODULE_NAME    =
        e_module_version = s_version.
    IF sf_installed = 'X'.

      IF s_version > '2.1'.
        sf_ta_v21 = 'X'.
      ENDIF.
      ef_ta_installed = sf_installed.
      ef_ta_v21       = sf_ta_v21.
      e_ta_version    = s_version.
*    CALL FUNCTION 'FUNCTION_EXISTS'
*         EXPORTING
*              funcname           = gc_ta_func
*         EXCEPTIONS
*              function_not_exist = 1
*              OTHERS             = 2.
*    IF sy-subrc = 0.
*      ef_ta_installed = 'X'.
*      sf_installed    = 'X'.
**--Check if TA v2.1 is installed
*
*      CALL FUNCTION 'FUNCTION_EXISTS'
*           EXPORTING
*                funcname           = gc_ta_func_21
*           EXCEPTIONS
*                function_not_exist = 1
*                OTHERS             = 2.
*      IF sy-subrc = 0.
*        ef_ta_v21 = 'X'.
*        sf_ta_v21 = 'X'.
*      ENDIF.
    ELSE.
      CLEAR : ef_ta_installed, sf_installed, ef_ta_v21, sf_ta_v21.
    ENDIF.
    sf_checked = 'X'.
  ENDIF.
ENDFORM.                    " check_ta_installed
*&---------------------------------------------------------------------*
*&      Form  get_tcodes_from_objects
*&---------------------------------------------------------------------*
*       Get transaction codes from Function Objects definition for
*       SOD Live analysis.
*       This ensures that even functions with placeholder tcodes
*      can be analyzed with SOD Live
*      This only supports S_TCODE TCD entries with only a Tcode in the
*      val_from field, no ranges, no wildcards
*----------------------------------------------------------------------*
*      -->P_IT_FAOBJ  text
*      -->P_LT_FUNCTTRAN  text
*----------------------------------------------------------------------*
FORM get_tcodes_from_objects TABLES
  it_faobj     STRUCTURE  /psyng/faobj2
  et_functtran STRUCTURE /psyng/functtran.
  DATA : lt_faobj    LIKE TABLE OF /psyng/faobj2 WITH HEADER LINE.
  lt_faobj[] = it_faobj[].
  SORT lt_faobj BY object field.
  DELETE lt_faobj WHERE object <> 'S_TCODE' OR field <> 'TCD'.
  LOOP AT lt_faobj.
    CHECK lt_faobj-val_from NS '*' AND lt_faobj-val_to IS INITIAL.
    et_functtran-functionid = lt_faobj-funid.
    et_functtran-tcode      = lt_faobj-val_from.
    APPEND et_functtran.
  ENDLOOP.


ENDFORM.                    " get_tcodes_from_objects
*&---------------------------------------------------------------------*
*&      Form  get_tcodes_from_objects
*&---------------------------------------------------------------------*
*       Get Web (odata) services from SOD matrix for
*       SOD Live analysis.
*       This only supports IWSV (odata services)
*----------------------------------------------------------------------*
*      -->P_IT_FAOBJ  text
*      -->P_LT_FUNCTTRAN  text
*----------------------------------------------------------------------*
FORM get_services_from_objects TABLES
  it_faobj     STRUCTURE  /psyng/faobj2
  et_functtran STRUCTURE /psyng/functtran.
  DATA : lt_faobj    LIKE TABLE OF /psyng/faobj2 WITH HEADER LINE.

  lt_faobj[] = it_faobj[].
  SORT lt_faobj BY object field.
  DELETE lt_faobj WHERE  object <> 'S_SERVICE' OR field <> 'SRV_NAME'.
*--Determine the complete path of the service
  DATA :
    lt_usobhash   TYPE TABLE OF usobhash      WITH HEADER LINE,
    lt_usobhashn  TYPE TABLE OF usobhash     WITH HEADER LINE,
    lt_icfservice TYPE TABLE OF icfservice    WITH HEADER LINE,
    l_namespace   TYPE string,
    l_service     TYPE string,
    l_version     TYPE string,
    l_rest        TYPE string,
    l_length      TYPE i,
    l_url         TYPE string,
    l_dummy       TYPE string.
  IF NOT lt_faobj[] IS INITIAL.
    LOOP AT lt_faobj.
      lt_usobhashn-name = lt_faobj-val_from.
      COLLECT lt_usobhashn.
    ENDLOOP.
    IF NOT lt_usobhashn[] IS INITIAL.
      SELECT *
        FROM usobhash INTO
         TABLE
        lt_usobhash FOR ALL ENTRIES IN
        lt_usobhashn WHERE name = lt_usobhashn-name."#EC SAST_CI_GEN_CHECK
      IF NOT lt_usobhash[] IS INITIAL.
        LOOP AT lt_usobhash WHERE pgmid = 'R3TR'
         AND ( object = 'IWSV'   "odata services
        OR    object = 'IWSG' )."#EC SAST_CI_GEN_CHECK"odata service Group
*  --Create the url
     SPLIT lt_usobhash-obj_name AT '/' INTO l_dummy l_namespace  l_rest.
          IF l_rest IS INITIAL OR l_namespace IS INITIAL.
            l_rest = lt_usobhash-obj_name.
            l_namespace = 'sap'.
          ENDIF.
          IF lt_usobhash-object = 'IWSV'.
            SPLIT l_rest   AT space INTO l_service l_version.
          ELSEIF lt_usobhash-object = 'IWSG'.
            l_length = strlen( l_rest ).
            l_length = l_length - 5.
            IF l_length GT 0.
              l_service = l_rest(l_length).
            ENDIF.
          ENDIF.
     CONCATENATE '/sap/opu/odata/' l_namespace '/' l_service INTO l_url.
          TRANSLATE l_url TO UPPER CASE.
          et_functtran-functionid = lt_faobj-funid.
          LOOP AT lt_faobj WHERE val_from = lt_usobhash-name.
            et_functtran-fioriid    = l_url.
            et_functtran-functionid = lt_faobj-funid.
            APPEND et_functtran.
          ENDLOOP.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.                    " get_tcodes_from_objects
