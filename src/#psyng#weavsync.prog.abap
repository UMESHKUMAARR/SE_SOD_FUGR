REPORT /psyng/weavsync NO STANDARD PAGE HEADING.
*----------------------------------------------------------------------
*
* PROGRAM               : /PSYNG/WEAVSYNC
* AUTHOR                : Security Weaver LLC
* RELEASE               : 1.0
* DATE OF RELEASE       : 10/19/2004
* TRANSPORT REQUEST #   :
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*
*----------------------------------------------------------------------*
TABLES: /psyng/position, agr_users, /psyng/user, /psyng/usrdet.

TABLES: /psyng/rolehdr, agr_agrs, /psyng/posndet.

TABLES: /psyng/roletrans, agr_1251.
TYPE-POOLS:slis.
DATA : BEGIN OF gt_log OCCURS 0,
        insap         LIKE icon-id,
        insw          LIKE icon-id,
        type1         LIKE t100-text,
        id1           LIKE t100-text,
        description1   LIKE t100-text,
        type2         LIKE t100-text,
        id2           LIKE t100-text,
        description2   LIKE t100-text,
      END OF gt_log.
DATA : BEGIN OF gt_header OCCURS 0,
        description   LIKE t100-text,
        count         TYPE i,
      END OF gt_header.

DATA:gf_missing_auth TYPE flag.
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call
DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.


DATA i TYPE i.
**********************************************************
DATA: BEGIN OF uitab OCCURS 0,
      userid LIKE /psyng/user-userid,
      saptechname LIKE /psyng/position-saptechname,
      description1 LIKE /psyng/position-description,
      description2 LIKE /psyng/position-description,
END OF uitab.

DATA: BEGIN OF ujtab OCCURS 0,
      userid LIKE /psyng/user-userid,
      saptechname LIKE /psyng/position-saptechname,
      description1 LIKE /psyng/position-description,
      description2 LIKE /psyng/position-description,
END OF ujtab.

DATA: BEGIN OF u2itab OCCURS 0,
      userid LIKE /psyng/user-userid,
      saptechname LIKE /psyng/position-saptechname,
      description1 LIKE /psyng/position-description,
      description2 LIKE /psyng/position-description,
END OF u2itab.

DATA: BEGIN OF u2jtab OCCURS 0,
      userid LIKE /psyng/user-userid,
      saptechname LIKE /psyng/position-saptechname,
      description1 LIKE /psyng/position-description,
      description2 LIKE /psyng/position-description,
END OF u2jtab.
***********************************************************

***********************************************************
DATA: BEGIN OF pitab OCCURS 0,
      positionid LIKE /psyng/position-positionid,
      saptechname LIKE /psyng/rolehdr-saptechname,
      description1 LIKE /psyng/position-description,
      description2 LIKE /psyng/position-description,
END OF pitab.

DATA: BEGIN OF pjtab OCCURS 0,
      positionid LIKE /psyng/position-positionid,
      saptechname LIKE /psyng/rolehdr-saptechname,
      description1 LIKE /psyng/position-description,
      description2 LIKE /psyng/position-description,
END OF pjtab.

DATA: BEGIN OF p2itab OCCURS 0,
      positionid LIKE /psyng/position-positionid,
      saptechname LIKE /psyng/rolehdr-saptechname,
      description1 LIKE /psyng/position-description,
      description2 LIKE /psyng/position-description,
END OF p2itab.

DATA: BEGIN OF p2jtab OCCURS 0,
      positionid LIKE /psyng/position-positionid,
      saptechname LIKE /psyng/rolehdr-saptechname,
      description1 LIKE /psyng/position-description,
      description2 LIKE /psyng/position-description,
END OF p2jtab.

***********************************************************

***********************************************************
DATA: BEGIN OF ritab OCCURS 0,
      roleid LIKE /psyng/rolehdr-roleid,
      tcode LIKE /psyng/roletrans-tcode,
      description1 LIKE /psyng/position-description,
      description2 LIKE /psyng/position-description,
END OF ritab.

DATA: BEGIN OF rjtab OCCURS 0,
      roleid LIKE /psyng/rolehdr-roleid,
      tcode LIKE /psyng/roletrans-tcode,
      saptechname LIKE /psyng/rolehdr-saptechname,
      description LIKE /psyng/rolehdr-description,
      description1 LIKE /psyng/position-description,
      description2 LIKE /psyng/position-description,
END OF rjtab.

DATA: BEGIN OF r2itab OCCURS 0,
      roleid LIKE /psyng/rolehdr-roleid,
      tcode LIKE /psyng/roletrans-tcode,
      description1 LIKE /psyng/position-description,
      description2 LIKE /psyng/position-description,
END OF r2itab.

DATA: BEGIN OF r2jtab OCCURS 0,
      roleid LIKE /psyng/rolehdr-roleid,
      tcode LIKE /psyng/roletrans-tcode,
      description1 LIKE /psyng/position-description,
      description2 LIKE /psyng/position-description,
END OF r2jtab.
**********************************************************


*--Selection Screen
SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
PARAMETERS : posit TYPE flag AS CHECKBOX USER-COMMAND posit DEFAULT 'X'.
SELECT-OPTIONS : pposit FOR /psyng/position-positionid.
PARAMETERS : roles TYPE flag AS CHECKBOX USER-COMMAND role DEFAULT 'X'.
SELECT-OPTIONS : proles FOR /psyng/rolehdr-roleid.
PARAMETERS : user TYPE flag AS CHECKBOX USER-COMMAND user DEFAULT 'X'.
SELECT-OPTIONS : pbname FOR /psyng/user-userid.
SELECTION-SCREEN END OF BLOCK blk1.

*-------------------- AT SELECTION-SCREEN OUTPUT ----------------------*
AT SELECTION-SCREEN OUTPUT.
  LOOP AT screen.
    CASE screen-name.
      WHEN 'PBNAME-LOW' OR 'PBNAME-HIGH'
      OR '%_PBNAME_%_APP_%-VALU_PUSH'.
        IF user = 'X'. "#EC SAST_CI_GEN_CHECK
          screen-input = 1.
        ELSE.
          screen-input = 0.
        ENDIF.

        MODIFY SCREEN.

      WHEN 'PROLES-LOW' OR 'PROLES-HIGH'
      OR '%_PROLES_%_APP_%-VALU_PUSH'.
        IF roles = 'X'.
          screen-input = 1.
        ELSE.
          screen-input = 0.
        ENDIF.

        MODIFY SCREEN.

      WHEN 'PPOSIT-LOW' OR 'PPOSIT-HIGH'
      OR '%_PPOSIT_%_APP_%-VALU_PUSH'.
        IF posit = 'X'.
          screen-input = 1.
        ELSE.
          screen-input = 0.
        ENDIF.

        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.

*------------------------- START-OF-SELECTION -------------------------*
START-OF-SELECTION.

*BOC AKUMAR SE VF scan changes-12/03/2024
AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.
*EOC AKUMAR SE VF scan changes-12/03/2024
Clear:gf_missing_auth.
  IF user = 'X'. "#EC SAST_CI_GEN_CHECK
    PERFORM user_synch.
    PERFORM user_report.
  ENDIF.
  IF posit = 'X'.
    PERFORM position_synch.
    PERFORM position_report.
  ENDIF.
  IF roles = 'X'.
    PERFORM role_synch.
    PERFORM role_report.
  ENDIF.
*************************************
  IF gf_missing_auth = 'X'.
*  **SF 1665
  MESSAGE s398(00) WITH
*      'Analysis Complete.'(083)
      'Missing some user authorizations'(084).
 ENDIF.
*************************************
  PERFORM output_log.

*&---------------------------------------------------------------------*
*&      Form  USER_SYNCH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM user_synch.
*  SELECT * FROM /psyng/user WHERE userid IN pbname.
  SELECT userid FROM /psyng/user INTO /psyng/user-userid
       WHERE userid IN pbname.
    SELECT * FROM /psyng/usrdet    "#EC CI_SEL_NESTED
    WHERE userid = /psyng/user-userid.
*      SELECT SINGLE * FROM /psyng/position
      SELECT SINGLE saptechname description    "#EC CI_SEL_NESTED
       INTO (/psyng/position-saptechname, /psyng/position-description)
       FROM /psyng/position
      WHERE positionid = /psyng/usrdet-positionid.
      IF /psyng/position-saptechname > space.
        uitab-userid = /psyng/user-userid.
        uitab-saptechname = /psyng/position-saptechname.
        uitab-description2 = /psyng/position-description.
        APPEND uitab.
      ENDIF.
    ENDSELECT.
*    SELECT * FROM agr_users
    SELECT agr_name FROM agr_users    "#EC CI_SEL_NESTED
      INTO agr_users-agr_name
    WHERE uname  = /psyng/user-userid
    AND col_flag = space.
      ujtab-userid = /psyng/user-userid.
      ujtab-saptechname = agr_users-agr_name.
      APPEND ujtab.
    ENDSELECT.
  ENDSELECT.

  SORT uitab.
  SORT ujtab.

*--Get all user full names
  DATA lt_uname TYPE TABLE OF /psyng/bc_userid_name WITH HEADER LINE.
  LOOP AT uitab.
    lt_uname-bname = uitab-userid.
    COLLECT lt_uname.
  ENDLOOP.
  LOOP AT ujtab.
    lt_uname-bname = ujtab-userid.
    COLLECT lt_uname.
  ENDLOOP.
  CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
       EXPORTING
            no_email = 'X'
       TABLES
            username = lt_uname.
  SORT lt_uname BY bname.

  FIELD-SYMBOLS :<uitab> LIKE LINE OF uitab.
  LOOP AT uitab ASSIGNING <uitab>.
    READ TABLE lt_uname WITH KEY bname = <uitab>-userid
    BINARY SEARCH.
    IF sy-subrc = 0.
      <uitab>-description1 = lt_uname-name_full.
    ELSE.
      CLEAR <uitab>-description1.
    ENDIF.
    READ TABLE ujtab WITH KEY userid = <uitab>-userid
    saptechname = uitab-saptechname.
    IF sy-subrc <> 0.
      u2itab-userid = <uitab>-userid.
      u2itab-saptechname = <uitab>-saptechname.
      u2itab-description1 = <uitab>-description1.
      u2itab-description2 = <uitab>-description2.
      APPEND u2itab.
    ENDIF.
  ENDLOOP.


  LOOP AT ujtab.
    READ TABLE uitab WITH KEY userid = ujtab-userid
    saptechname = ujtab-saptechname.
    IF sy-subrc <> 0.
      CLEAR u2jtab.

      u2jtab-userid = ujtab-userid.
      u2jtab-saptechname = ujtab-saptechname.

      READ TABLE lt_uname WITH KEY bname = u2jtab-userid
      BINARY SEARCH.
      IF sy-subrc = 0.
        u2jtab-description1 = lt_uname-name_full.
      ELSE.
        CLEAR u2jtab-description1.
      ENDIF.

      IF ujtab-description2 IS INITIAL.
        SELECT SINGLE text FROM agr_texts INTO u2jtab-description2
        WHERE
        agr_name = ujtab-saptechname AND
        spras = sy-langu AND
        line = 0.
        IF sy-subrc <> 0.
          CLEAR u2jtab-description2.
        ENDIF.
      ENDIF.
      APPEND u2jtab.
    ENDIF.
  ENDLOOP.


ENDFORM.                    " USER_SYNCH
*&---------------------------------------------------------------------*
*&      Form  POSITION_SYNCH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM position_synch.

  SELECT * FROM /psyng/position WHERE positionid IN pposit.
****************************************
* **SF 1665
**Authorization check for Displaying SW Positions
**SF 1665
    AUTHORITY-CHECK OBJECT 'Y&SW_POSH'
               ID 'ACTVT' FIELD '03'
               ID 'Y&SW_POSID' FIELD /psyng/position-positionid.
    IF sy-subrc EQ 0.
* **SF 1665
****************************************


*      SELECT * FROM /psyng/posndet
      SELECT roleid FROM /psyng/posndet INTO /psyng/posndet-roleid
      WHERE positionid = /psyng/position-positionid.
*      SELECT SINGLE * FROM /psyng/rolehdr
        SELECT SINGLE saptechname description     "#EC CI_SEL_NESTED
         INTO (/psyng/rolehdr-saptechname , /psyng/rolehdr-description)
          FROM /psyng/rolehdr
           WHERE roleid = /psyng/posndet-roleid.

        pitab-positionid    = /psyng/position-positionid.
        pitab-description1  = /psyng/position-description.
        pitab-saptechname   = /psyng/rolehdr-saptechname.
        pitab-description2  = /psyng/rolehdr-description.
        APPEND pitab.

      ENDSELECT.

      SELECT * FROM agr_agrs
      WHERE agr_name  = /psyng/position-saptechname
      AND   attributes <> 'X'.
        pjtab-positionid = /psyng/position-positionid.
        pjtab-saptechname = agr_agrs-child_agr.
        APPEND pjtab.
      ENDSELECT.
      IF sy-subrc <> 0.
        pjtab-positionid   = /psyng/position-positionid.
        pjtab-saptechname  = /psyng/position-saptechname.
        pjtab-description1 = /psyng/position-description.
        APPEND pjtab.
      ENDIF.
*********************************
* **SF 1665
    ELSE.
     gf_missing_auth = 'X'.
    ENDIF.
* **SF 1665
*********************************
  ENDSELECT.

  SORT pitab.
  SORT pjtab.

  LOOP AT pitab.
    READ TABLE pjtab WITH KEY positionid = pitab-positionid
    saptechname = pitab-saptechname.
    IF sy-subrc <> 0.
      p2itab-positionid = pitab-positionid.
      p2itab-saptechname = pitab-saptechname.
      p2itab-description2 = pitab-description2.
      p2itab-description1 = pitab-description1.
      APPEND p2itab.
    ENDIF.
  ENDLOOP.

  LOOP AT pjtab.
    READ TABLE pitab WITH KEY positionid = pjtab-positionid
    saptechname = pjtab-saptechname.
    IF sy-subrc <> 0.
      CLEAR p2jtab.
      p2jtab-positionid   = pjtab-positionid.
      p2jtab-saptechname  = pjtab-saptechname.
      p2jtab-description1 = pjtab-description1.
      IF p2jtab-description2 IS INITIAL.
        SELECT SINGLE text FROM agr_texts INTO p2jtab-description2
        WHERE
        agr_name = p2jtab-saptechname AND
        spras = sy-langu AND
        line = 0.
        IF sy-subrc <> 0.
          CLEAR p2jtab-description2.
        ENDIF.
      ENDIF.

      APPEND p2jtab.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " POSITION_SYNCH
*&---------------------------------------------------------------------*
*&      Form  ROLE_SYNCH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM role_synch.

*  SELECT * FROM /psyng/rolehdr WHERE roleid IN proles.
  SELECT roleid description saptechname
  INTO CORRESPONDING FIELDS OF /psyng/rolehdr
  FROM /psyng/rolehdr
  WHERE roleid IN proles.

****************************************
**SF 1665
**Authorization check for Displaying SW Roles
    AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
               ID 'ACTVT' FIELD '03'
               ID 'Y&SW_ROLID'  FIELD  /psyng/rolehdr-roleid.
    IF sy-subrc EQ 0.

**SF 1665
****************************************

      SELECT * FROM /psyng/roletrans  "#EC CI_SEL_NESTED
      WHERE roleid = /psyng/rolehdr-roleid.
        ritab-roleid = /psyng/rolehdr-roleid.
        ritab-tcode = /psyng/roletrans-tcode.
        ritab-description1 = /psyng/rolehdr-description.
        APPEND ritab.
      ENDSELECT.
      rjtab-saptechname = /psyng/rolehdr-saptechname.
      SELECT * FROM agr_1251
      WHERE agr_name  = /psyng/rolehdr-saptechname
      AND object = 'S_TCODE'
      AND field = 'TCD'.
        rjtab-roleid =  /psyng/rolehdr-roleid.
        rjtab-tcode = agr_1251-low.
        APPEND rjtab.
      ENDSELECT.

*********************************
* **SF 1665
    ELSE.
     gf_missing_auth = 'X'.
    ENDIF.
* **SF 1665
*********************************
  ENDSELECT.

  DATA : lt_tstct TYPE TABLE OF tstct WITH HEADER LINE,
         lt_tstct2 TYPE TABLE OF tstct WITH HEADER LINE.
  LOOP AT ritab.
    lt_tstct-tcode = ritab-tcode.
    COLLECT lt_tstct.
  ENDLOOP.
  LOOP AT rjtab.
    lt_tstct-tcode = rjtab-tcode.
    COLLECT lt_tstct.
  ENDLOOP.
  IF NOT lt_tstct[] IS INITIAL.
    SELECT tcode ttext FROM tstct
    INTO CORRESPONDING FIELDS OF TABLE lt_tstct2
    FOR ALL ENTRIES IN lt_tstct WHERE tcode = lt_tstct-tcode AND
    sprsl = sy-langu.
    FREE : lt_tstct.
  ENDIF.
  SORT lt_tstct2 BY tcode.

*--DHORIONS 2011/10/21 ->Performance Improvements
  SORT ritab BY roleid tcode.
  SORT rjtab BY roleid tcode.
  LOOP AT ritab.
    READ TABLE rjtab
    WITH KEY
      roleid = ritab-roleid
      tcode  = ritab-tcode
      BINARY SEARCH.
    IF sy-subrc <> 0.
      r2itab-roleid = ritab-roleid.
      r2itab-tcode = ritab-tcode.
      r2itab-description1 = ritab-description1.
      READ TABLE lt_tstct2 WITH KEY tcode = ritab-tcode BINARY SEARCH.
      IF sy-subrc = 0.
        r2itab-description2 = lt_tstct2-ttext.
      ELSE.
        CLEAR r2itab-description2.
      ENDIF.
      APPEND r2itab.
    ENDIF.
  ENDLOOP.
  LOOP AT rjtab.
    CLEAR r2jtab.
    READ TABLE ritab
    WITH KEY
      roleid = rjtab-roleid
      tcode = rjtab-tcode
    BINARY SEARCH.
    IF sy-subrc <> 0.
      r2jtab-roleid = rjtab-roleid.
      r2jtab-tcode = rjtab-tcode.
      READ TABLE lt_tstct2 WITH KEY tcode = r2jtab-tcode BINARY SEARCH.
      IF sy-subrc = 0.
        r2jtab-description2 = lt_tstct2-ttext.
      ELSE.
        CLEAR r2jtab-description2.
      ENDIF.

      IF r2jtab-description1 IS INITIAL.
        SELECT SINGLE text FROM agr_texts INTO r2jtab-description1
        WHERE
        agr_name = rjtab-saptechname AND
        spras = sy-langu AND
        line = 0.
        IF sy-subrc <> 0.
          CLEAR r2jtab-description1.
        ENDIF.
      ENDIF.
      APPEND r2jtab.
    ENDIF.
  ENDLOOP.


ENDFORM.                    " ROLE_SYNCH
*&---------------------------------------------------------------------*
*&      Form  USER_REPORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM user_report.
*      U2ITAB. "Available in Security Weaver not in SAP
*      U2JTAB. "Available in SAP not in Weaver.

  SORT: u2itab.
  DELETE ADJACENT DUPLICATES FROM u2itab COMPARING ALL FIELDS.

  CLEAR i.
  LOOP AT u2itab.
    PERFORM log USING
                '' 'X'
                'User'(l01)                     u2itab-userid
                'SAP Technical Role Name'(l02)  u2itab-saptechname
                u2itab-description1 u2itab-description2
                .
    ADD 1 TO i.
  ENDLOOP.
  gt_header-description = 'Positions assigned in SW not in SAP'(h10).
  gt_header-count = i.
  APPEND gt_header.

  CLEAR i.
  LOOP AT u2jtab.
    PERFORM log USING
                'X' ''
                'User'(l01)                     u2jtab-userid
                'SAP Technical Role Name'(l02)  u2jtab-saptechname
                u2jtab-description1 u2jtab-description2.
    ADD 1 TO i.
  ENDLOOP.
  gt_header-description = 'Positions assigned in SAP not in SW'(h11).
  gt_header-count = i.
  APPEND gt_header.




ENDFORM.                    " USER_REPORT
*&---------------------------------------------------------------------*
*&      Form  POSITION_REPORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM position_report.
  SORT: p2itab.
  DELETE ADJACENT DUPLICATES FROM p2itab COMPARING ALL FIELDS.
  CLEAR i.
  LOOP AT p2itab.
    PERFORM log USING
                '' 'X'
                'Position'(l03) p2itab-positionid
                'SAP Technical Role Name'(l02)  p2itab-saptechname
                p2itab-description1 p2itab-description2.
    ADD 1 TO i.
  ENDLOOP.
  gt_header-description = 'Positions defined in SW not in SAP'(h12).
  gt_header-count = i.
  APPEND gt_header.
  CLEAR i.

  LOOP AT p2jtab.
    PERFORM log USING
                'X' ''
                'Position'(l03)                 p2jtab-positionid
                'SAP Technical Role Name'(l02)  p2jtab-saptechname
                p2jtab-description1 p2jtab-description2.
    ADD 1 TO i.

  ENDLOOP.
  gt_header-description = 'Positions defined in SAP not in SW'(h13).
  gt_header-count = i.
  APPEND gt_header.
ENDFORM.                    " POSITION_REPORT
*&---------------------------------------------------------------------*
*&      Form  ROLE_REPORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM role_report.
  SORT: r2itab.
  DELETE ADJACENT DUPLICATES FROM r2itab COMPARING ALL FIELDS.
  CLEAR i.
  LOOP AT r2itab.
    PERFORM log USING
                '' 'X'
                'Role'(l04)         r2itab-roleid
                'Transaction'(l05)  r2itab-tcode
                r2itab-description1 r2itab-description2.
    ADD 1 TO i.

  ENDLOOP.
  gt_header-description = 'Transactions defined in SW not in SAP'(h14).
  gt_header-count = i.
  APPEND gt_header.
  CLEAR i.
  LOOP AT r2jtab.
    PERFORM log USING
                'X' ''
                'Role'(l04)         r2jtab-roleid
                'Transaction'(l05)  r2jtab-tcode
                r2jtab-description1 r2jtab-description2.
    ADD 1 TO i.
  ENDLOOP.
  gt_header-description = 'Transactions defined in SAP not in SW'(h15).
  gt_header-count = i.
  APPEND gt_header.
ENDFORM.                    " ROLE_REPORT
*&---------------------------------------------------------------------*
*&      Form  log
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0805   text
*      -->P_0806   text
*      -->P_0807   text
*      -->P_U2ITAB_USERID  text
*      -->P_0809   text
*      -->P_U2ITAB_SAPTECHNAME  text
*      -->P_U2ITAB_DESCRIPTION  text
*----------------------------------------------------------------------*
FORM log USING    i_insap
                  i_insw
                  i_type1
                  i_id1
                  i_type2
                  i_id2
                  i_description1
                  i_description2.
  CLEAR gt_log.
  IF i_insap = 'X'.
    gt_log-insap       = '@5B@'.
  ELSE.
    gt_log-insap       = '@5C@'.
  ENDIF.
  IF i_insw = 'X'.
    gt_log-insw       = '@5B@'.
  ELSE.
    gt_log-insw       = '@5C@'.
  ENDIF.

  gt_log-type1       = i_type1.
  gt_log-id1         = i_id1.
  gt_log-type2       = i_type2.
  gt_log-id2         = i_id2.
  gt_log-description1 = i_description1.
  gt_log-description2 = i_description2.

  APPEND gt_log.

ENDFORM.                    " log

*&---------------------------------------------------------------------*
*&      Form  output_log
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_log.
  DATA: ls_variant TYPE disvariant,
        alv_layout TYPE slis_layout_alv,
        l_program  LIKE sy-repid.

  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  l_program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = l_program
            i_internal_tabname = 'GT_LOG'
            i_inclname         = l_program
       CHANGING
            ct_fieldcat        = i_fieldcat_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             INCONSISTENT_INTERFACE = 1
             PROGRAM_ERROR          = 2
             OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  PERFORM build_sort_table.
  PERFORM adjust_columns.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_top_of_page = 'ALV_HEADER'
            i_callback_program     = l_program
            is_layout              = alv_layout
            it_fieldcat            = i_fieldcat_alv
            i_save                 = 'A'
            is_variant             = ls_variant
            it_sort                = isort
       TABLES
            t_outtab               = gt_log
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " output_log

*---------------------------------------------------------------------*
*       FORM ALV_HEADER                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader.


  LOOP AT gt_header.
    wa-typ = 'S'.
    wa-info = gt_header-description.
    wa-key = gt_header-count.
    APPEND wa TO header.
  ENDLOOP.
  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = header.
**            i_logo             = 'Z_3SW_LOGO_JPG'.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  adjust_columns
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM adjust_columns.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  wa_fieldcat_alv-seltext_l    = 'In SAP'(h01).
  wa_fieldcat_alv-seltext_m    = 'In SAP'(h01).
  wa_fieldcat_alv-seltext_s    = 'In SAP'(h01).
  wa_fieldcat_alv-reptext_ddic = 'In SAP'(h01).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'INSAP'.

  wa_fieldcat_alv-seltext_l    = 'In SW'(h02).
  wa_fieldcat_alv-seltext_m    = 'In SW'(h02).
  wa_fieldcat_alv-seltext_s    = 'In SW'(h02).
  wa_fieldcat_alv-reptext_ddic = 'In SW'(h02).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'INSW'.

  wa_fieldcat_alv-seltext_l    = 'Type'(h03).
  wa_fieldcat_alv-seltext_m    = 'Type'(h03).
  wa_fieldcat_alv-seltext_s    = 'Type'(h03).
  wa_fieldcat_alv-reptext_ddic = 'Type'(h03).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TYPE1' OR
                      fieldname = 'TYPE2'.

  wa_fieldcat_alv-seltext_l    = 'ID'(h04).
  wa_fieldcat_alv-seltext_m    = 'ID'(h04).
  wa_fieldcat_alv-seltext_s    = 'ID'(h04).
  wa_fieldcat_alv-reptext_ddic = 'ID'(h04).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ID1' OR
                      fieldname = 'ID2'.


  wa_fieldcat_alv-seltext_l    = 'Description'(h05).
  wa_fieldcat_alv-seltext_m    = 'Description'(h05).
  wa_fieldcat_alv-seltext_s    = 'Description'(h05).
  wa_fieldcat_alv-reptext_ddic = 'Description'(h05).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'DESCRIPTION1' OR
                      fieldname = 'DESCRIPTION2'.





ENDFORM.                    " adjust_columns
*&---------------------------------------------------------------------*
*&      Form  build_sort_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_sort_table.
  DATA : l_sort LIKE LINE OF isort.
  l_sort-spos = '1'.
  l_sort-fieldname = 'TYPE1'.
  l_sort-tabname = 'GT_LOG'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '2'.
  l_sort-fieldname = 'TYPE2'.
  l_sort-tabname = 'GT_LOG'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '3'.
  l_sort-fieldname = 'INSAP'.
  l_sort-tabname = 'GT_LOG'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '4'.
  l_sort-fieldname = 'INSW'.
  l_sort-tabname = 'GT_LOG'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '5'.
  l_sort-fieldname = 'ID1'.
  l_sort-tabname = 'GT_LOG'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '6'.
  l_sort-fieldname = 'DESCRIPTION1'.
  l_sort-tabname = 'GT_LOG'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '7'.
  l_sort-fieldname = 'ID2'.
  l_sort-tabname = 'GT_LOG'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '7'.
  l_sort-fieldname = 'DESCRIPTION2'.
  l_sort-tabname = 'GT_LOG'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
ENDFORM.                    " build_sort_table
