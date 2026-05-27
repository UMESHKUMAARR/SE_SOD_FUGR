FUNCTION /psyng/seresid_f4.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      SHLP_TAB TYPE  SHLP_DESCR_TAB_T
*"      RECORD_TAB STRUCTURE  SEAHLPRES
*"  CHANGING
*"     VALUE(SHLP) TYPE  SHLP_DESCR_T
*"     VALUE(CALLCONTROL) LIKE  DDSHF4CTRL STRUCTURE  DDSHF4CTRL
*"----------------------------------------------------------------------

  DATA: BEGIN OF lt_aid_display OCCURS 0,
        aid   TYPE /psyng/swreshdr-aid,
        bname TYPE /psyng/swreshdr-bname,
        start_date TYPE /psyng/swreshdr-start_date,
        start_time TYPE /psyng/swreshdr-start_time,
        description TYPE /psyng/swreshdr-description,
        sodvrsio TYPE /psyng/swreshdr-sodvrsio,
        setid TYPE /PSYNG/SECONFID,
        delete_date TYPE /PSYNG/SERES_DELETE_DATE,
        users_analyzed TYPE  /PSYNG/NR_USERS_C,
*"/psyng/swreshdr-users_analyzed,
        no_restrictions TYPE /psyng/swreshdr-no_restrictions,
        system  TYPE /psyng/longsystems,
  END OF lt_aid_display.

  DATA: ls_aid_display LIKE LINE OF lt_aid_display,
         wa_selopt LIKE ddshselopt,
         lt_swresisys TYPE TABLE OF /psyng/swresisys WITH HEADER LINE,
         lt_swreshdr TYPE TABLE OF  /psyng/swreshdr WITH HEADER LINE.


  DATA: lv_shlp TYPE shlp_descr_t,
          ls_ddshiface TYPE ddshiface,
          ls_record_tab TYPE seahlpres,
          ls_selopt TYPE ddshselopt.
  RANGES :
    lr_aid FOR lt_aid_display-aid,
    lr_bname FOR lt_aid_display-bname,
    lr_sdate FOR lt_aid_display-start_date,
    lr_stime FOR lt_aid_display-start_time,
    lr_des FOR lt_aid_display-description,
    lr_vrsio FOR lt_aid_display-sodvrsio,
    lr_set FOR lt_aid_display-setid,
    lr_ddate FOR lt_aid_display-delete_date,
    lr_user_ana FOR lt_aid_display-users_analyzed,
    lr_no_res FOR lt_aid_display-no_restrictions,
    lr_sys FOR lt_aid_display-system.

*--create ranges
  LOOP AT shlp-selopt INTO ls_selopt.
    CASE ls_selopt-shlpfield.
      WHEN 'AID'.
        MOVE-CORRESPONDING ls_selopt TO lr_aid.
        COLLECT lr_aid.
      WHEN 'BNAME'.
        MOVE-CORRESPONDING ls_selopt TO lr_bname.
        COLLECT lr_bname.
      WHEN 'START_DATE'.
        MOVE-CORRESPONDING ls_selopt TO lr_sdate.
        COLLECT lr_sdate.
      WHEN 'START_TIME'.
        MOVE-CORRESPONDING ls_selopt TO lr_stime.
        COLLECT lr_stime.

      WHEN 'DESCRIPTION'.
        MOVE-CORRESPONDING ls_selopt TO lr_des.
        COLLECT lr_des.

      WHEN 'SODVRSIO'.
        MOVE-CORRESPONDING ls_selopt TO lr_vrsio.
        COLLECT lr_vrsio.
      WHEN 'SETID'.
        MOVE-CORRESPONDING ls_selopt TO lr_set.
        COLLECT lr_set.

      WHEN 'DELETE_DATE'.
        MOVE-CORRESPONDING ls_selopt TO lr_ddate.
        COLLECT lr_ddate.
      WHEN 'USERS_ANALYZED'.
        MOVE-CORRESPONDING ls_selopt TO lr_user_ana.
        COLLECT lr_user_ana.
      WHEN 'NO_RESTRICTION'.
        MOVE-CORRESPONDING ls_selopt TO lr_no_res.
        COLLECT lr_no_res.
      WHEN 'SYSTEM'.
        MOVE-CORRESPONDING ls_selopt TO lr_sys.
        COLLECT lr_sys.

    ENDCASE.
  ENDLOOP.

*  IF callcontrol-step = 'SELECT'.
**  REFRESH record_tab[].
**--Restrict the values on user input
*    CALL FUNCTION 'F4UT_RESULTS_MAP'
*         EXPORTING
*              source_structure   = '/PSYNG/SWRESHDR'
*              apply_restrictions = 'X'
*         TABLES
*              shlp_tab           = shlp_tab
*              record_tab         = record_tab
*              source_tab         = lt_aid_display
*         CHANGING
*              shlp               = shlp
*              callcontrol        = callcontrol
*         EXCEPTIONS
*              illegal_structure  = 1
*              OTHERS             = 2.
*    IF sy-subrc <> 0.
*      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*    ENDIF.
**    exit.
*  ELSE.
*  ENDIF.

*CALLCONTROL-STEP = 'DISP'.
  callcontrol-top_shlp = '/PSYNG/SERESID_F4'.
  callcontrol-sortoff = 'X'.
  IF callcontrol-top_shlp = '/PSYNG/SERESID_F4'.
    IF callcontrol-step = 'DISP'.
*      REFRESH record_tab[].
**---Get DB record
      SELECT  aid bname start_date start_time description
      sodvrsio  setid delete_date
      users_analyzed no_restrictions
      INTO CORRESPONDING FIELDS OF TABLE lt_swreshdr
      FROM /psyng/swreshdr
      WHERE
                   aid  IN lr_aid
       AND     bname    IN lr_bname
       AND  start_date  IN lr_sdate
       AND  start_time  IN lr_stime
       AND  description IN lr_des
       AND  sodvrsio    IN lr_vrsio
       AND  setid       IN lr_set
       AND  delete_date IN lr_ddate
       AND  users_analyzed IN lr_user_ana
       AND  no_restrictions IN lr_no_res
       and  finished      = 'X'.

      iF NOT lt_swreshdr[] IS INITIAL.
        SELECT * FROM /psyng/swresisys INTO TABLE lt_swresisys
        FOR ALL ENTRIES IN lt_swreshdr
        WHERE aid = lt_swreshdr-aid.
      ENDIF.

*---Process them
      LOOP AT lt_swreshdr.
        MOVE-CORRESPONDING lt_swreshdr TO lt_aid_display.
        LOOP AT lt_swresisys WHERE aid = lt_swreshdr-aid.
          CONCATENATE lt_aid_display-system   ',' lt_swresisys-sysid
          INTO lt_aid_display-system SEPARATED BY space.
          CONDENSE lt_aid_display-system.
        ENDLOOP.
        lt_aid_display-system = lt_aid_display-system+2.
*        shift lt_aid_display-users_analyzed left
*        deleting leading '0'.
        APPEND lt_aid_display.
        CLEAR lt_aid_display.
      ENDLOOP.

      REFRESH record_tab[].
      SORT lt_aid_display DESCENDING BY aid.
      LOOP AT lt_aid_display INTO ls_aid_display.
        IF ls_aid_display-system IN lr_sys.
*          MOVE ls_aid_display TO ls_record_tab-STRING.
          MOVE ls_aid_display TO ls_record_tab.
          APPEND ls_record_tab TO record_tab.
          CLEAR ls_record_tab.
          CLEAR ls_aid_display.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
*  callcontrol-sortoff = 'X'.
  SORT record_tab DESCENDING.
ENDFUNCTION.
