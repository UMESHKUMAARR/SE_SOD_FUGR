*----------------------------------------------------------------------*
* Report  /PSYNG/SW_023                                                *
* AUTHOR: Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

REPORT /psyng/sw_023 LINE-SIZE 250.

TABLES:   /psyng/rolehdr, /psyng/roletrans, /psyng/position.

TYPE-POOLS: slis.                                      "For ALV call
DATA: g_program         LIKE sy-repid.                   "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
      isort TYPE STANDARD TABLE OF slis_sortinfo_alv.

DATA: BEGIN OF output OCCURS 10,
        positionid LIKE /psyng/position-positionid,
        postext LIKE /psyng/position-description,
        pospfcg LIKE /psyng/position-saptechname,
        roleid LIKE /psyng/rolehdr-roleid,
        roletext LIKE /psyng/rolehdr-description ,
        rolepfcg LIKE /psyng/rolehdr-saptechname,
        tcode LIKE /psyng/roletrans-tcode,
        ttext LIKE tstct-ttext,
      END OF output.
DATA: g_wa_output LIKE output.
TYPES : BEGIN OF ty_position,
       positionid TYPE /psyng/position-positionid,
       pdescription TYPE /psyng/position-description,
       psaptechname TYPE /psyng/position-saptechname,
       roleid TYPE /psyng/posndet-roleid,
END OF ty_position.
TYPES : BEGIN OF ty_roles,
        roleid TYPE /psyng/rolehdr-roleid,
        description TYPE /psyng/rolehdr-description,
        saptechname TYPE /psyng/rolehdr-saptechname,
        tcode TYPE /psyng/roletrans-tcode,
        END OF ty_roles.

DATA : lt_position TYPE TABLE OF ty_position WITH HEADER LINE,
       lt_roles TYPE TABLE OF ty_roles WITH HEADER LINE.

DATA : lt_roletrans TYPE TABLE OF /psyng/roletrans WITH HEADER LINE,
      lt_posdet TYPE TABLE OF /psyng/posndet WITH HEADER LINE,
      lt_rolehdr TYPE TABLE OF /psyng/rolehdr WITH HEADER LINE,
      lt_uni_roles TYPE TABLE OF /psyng/roletrans WITH HEADER LINE.



DATA: gt_itstct TYPE HASHED TABLE OF tstct WITH UNIQUE KEY
             sprsl tcode
             WITH HEADER LINE.
DATA: g_wa_posndet TYPE /psyng/posndet.
DATA:gf_missing_auth TYPE flag.
SELECTION-SCREEN: BEGIN OF BLOCK blk1 WITH FRAME TITLE text-000.
SELECT-OPTIONS: pposid FOR /psyng/position-positionid,
                ppsaptec FOR /psyng/position-saptechname.
SELECTION-SCREEN SKIP 1.
SELECT-OPTIONS: proleid FOR /psyng/rolehdr-roleid,
                pstatus FOR /psyng/rolehdr-status,
                prsaptec FOR /psyng/rolehdr-saptechname,
                powner  FOR /psyng/rolehdr-owner,
                ptcode FOR /psyng/roletrans-tcode.
SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN: END OF BLOCK blk1.

INITIALIZATION.
  PERFORM exelog.

START-OF-SELECTION.
*BOC UMITTAL SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
  PERFORM get_data.
  PERFORM build_output.

*  *************************************
  IF gf_missing_auth = 'X'.
*  **SF 1665
    MESSAGE s398(00) WITH
*      'Analysis Complete.'(083)
        'Missing some user authorizations'(084).
  ENDIF.
*************************************

  IF output[] IS INITIAL.
    MESSAGE s150(/psyng/sw).
    LEAVE LIST-PROCESSING.
  ENDIF.
  PERFORM build_alv_catalog.
  PERFORM output_using_alv.

*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_catalog.
  DATA: wa_fieldcat LIKE LINE OF i_fieldcat_alv.     "For ALV call

  g_program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'OUTPUT'
            i_inclname         = g_program
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

  wa_fieldcat-seltext_l = text-h01.
  wa_fieldcat-seltext_m = text-h01.
  wa_fieldcat-seltext_s = text-h01.
  wa_fieldcat-reptext_ddic = text-h01.
  MODIFY i_fieldcat_alv FROM wa_fieldcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'POSTEXT'.
ENDFORM.                    " build_alv_catalog
*&---------------------------------------------------------------------*
*&      Form  output_using_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_using_alv.
  DATA: alv_layout    TYPE slis_layout_alv,            "For ALV call
        alv_grid_titl TYPE lvc_title,                  "For ALV call
        ls_variant    TYPE disvariant.


  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  PERFORM build_sort_table.
  alv_grid_titl = text-001.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title       = alv_grid_titl
            i_callback_program = g_program
            it_sort            = isort
            is_layout          = alv_layout
            it_fieldcat        = i_fieldcat_alv
            i_save             = 'A'
            is_variant         = ls_variant
       TABLES
            t_outtab           = output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.


ENDFORM.                    " output_using_alv
*&---------------------------------------------------------------------*
*&      Form  build_sort_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_sort_table.
  DATA: l_sort TYPE slis_sortinfo_alv.

  l_sort-spos = '1'.
  l_sort-fieldname = 'POSITIONID'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'POSTEXT'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'POSPFCG'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '4'.
  l_sort-fieldname = 'ROLEID'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '5'.
  l_sort-fieldname = 'ROLETEXT'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '6'.
  l_sort-fieldname = 'ROLEPFCG'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '7'.
  l_sort-fieldname = 'TCODE'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

ENDFORM.                    " build_sort_table
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE,
        l_current_user  TYPE sy-uname. "C0700
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 29.03.22 for C0700

  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = l_current_user."sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.
  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = exelog.
  COMMIT WORK.
ENDFORM.                    " exelog
*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_data.
  CLEAR:gf_missing_auth .
** Join of table position and position details

  SELECT a~positionid a~description a~saptechname
           b~roleid
           INTO TABLE lt_position
           FROM /psyng/position AS a
           LEFT OUTER JOIN /psyng/posndet AS b
           ON b~positionid = a~positionid
           WHERE a~positionid IN pposid
           AND a~saptechname IN ppsaptec.

** Filter lt_position table on the basis of role ID
  IF NOT proleid[] IS INITIAL.
    DELETE lt_position WHERE NOT roleid IN proleid.
  ENDIF.
* If role id attributes are requested then we can ignore positions with
* blank role id
  IF NOT prsaptec[] IS INITIAL OR NOT powner[] IS INITIAL
  OR NOT pstatus[] IS INITIAL OR NOT ptcode[] IS INITIAL.
    DELETE lt_position WHERE roleid EQ space.
  ENDIF.

**  Fetch the corresponding roleID details
  IF NOT lt_position[] IS INITIAL.
    SELECT a~roleid a~description a~saptechname
           b~tcode
           INTO TABLE lt_roles
           FROM /psyng/rolehdr AS a
           LEFT OUTER JOIN /psyng/roletrans AS b
           ON a~roleid = b~roleid
           FOR ALL ENTRIES IN lt_position
           WHERE  a~roleid EQ lt_position-roleid
*             OR a~roleid
              AND a~saptechname  IN prsaptec
              AND a~owner        IN powner
              AND a~status       IN pstatus.

    IF NOT ptcode[] IS INITIAL.
      DELETE lt_roles WHERE NOT tcode IN ptcode.
    ENDIF.
    IF NOT lt_roles[] IS INITIAL.
      SELECT * FROM tstct INTO TABLE gt_itstct WHERE sprsl = sy-langu.
    ENDIF.
  ENDIF.


ENDFORM.                    " get_data
*&---------------------------------------------------------------------*
*&      Form  build_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_output.
  LOOP AT lt_position.
    AUTHORITY-CHECK OBJECT 'Y&SW_POSH'
               ID 'ACTVT' FIELD '03'
               ID 'Y&SW_POSID' FIELD lt_position-positionid.
    IF sy-subrc = 0.
** Display positions those donot have any role
*      IF prsaptec[] IS INITIAL AND powner[] IS INITIAL
*      AND pstatus[] IS INITIAL AND ptcode[] IS INITIAL.
      IF lt_position-roleid IS INITIAL.
        g_wa_output-positionid = lt_position-positionid.
        g_wa_output-postext = lt_position-pdescription.
        g_wa_output-pospfcg = lt_position-psaptechname.
        APPEND g_wa_output TO output.
        CLEAR g_wa_output.
        CONTINUE.
      ENDIF.
*      ENDIF.
**   if role found then display all details
      LOOP AT lt_roles WHERE roleid = lt_position-roleid.
*        IF lt_roles-roleid = lt_position-roleid.
        g_wa_output-positionid = lt_position-positionid.
        g_wa_output-postext = lt_position-pdescription.
        g_wa_output-pospfcg = lt_position-psaptechname.
        g_wa_output-roleid = lt_position-roleid.
        g_wa_output-roletext = lt_roles-description.
        g_wa_output-rolepfcg = lt_roles-saptechname.
        g_wa_output-tcode = lt_roles-tcode.
        READ TABLE gt_itstct WITH TABLE KEY sprsl = sy-langu
                                               tcode = lt_roles-tcode.
        IF sy-subrc = 0.
          g_wa_output-ttext = gt_itstct-ttext.
        ENDIF.
        APPEND g_wa_output TO output.
        CLEAR g_wa_output.



      ENDLOOP.
    ELSE.
      gf_missing_auth = 'X'.
    ENDIF.
    CLEAR g_wa_output.
  ENDLOOP.

ENDFORM.                    " build_output
