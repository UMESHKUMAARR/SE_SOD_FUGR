*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_AUTH_COUNT
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sw_auth_count NO STANDARD PAGE HEADING.

TABLES: tobj,  ust10s, usr02.

TYPE-POOLS: slis.                                      "For ALV call
DATA: GS_program         LIKE sy-repid.                   "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call

DATA: usercount TYPE i,
      userauthcount TYPE i,
      totalauthcount TYPE i,
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx,
      GS_VARIANT TYPE DISVARIANT.

DATA: BEGIN OF profinfo OCCURS 10.                "Single profile list
        INCLUDE STRUCTURE /psyng/profinfo.
DATA: END OF profinfo.

DATA: iust04 TYPE SORTED TABLE OF ust04 WITH UNIQUE KEY
             bname profile
             WITH HEADER LINE.

DATA: BEGIN OF userauth OCCURS 0.
DATA:   bname LIKE usr02-bname,
        objct LIKE ust10s-objct,
        auth  LIKE ust10s-auth.
DATA: END OF userauth.

DATA: BEGIN OF sumry OCCURS 0.
DATA:   bname LIKE usr02-bname,
        authcount TYPE i. "/PSYNG/AUTHCOUNT.
DATA: END OF sumry.

DATA: BEGIN OF gt_usr02 OCCURS 0,
        class TYPE usr02-class,
        bname TYPE usr02-bname,
      END OF gt_usr02.

SELECTION-SCREEN: BEGIN OF BLOCK exe WITH FRAME TITLE text-000.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(24) text-001.
SELECTION-SCREEN: POSITION 25.
SELECT-OPTIONS:   pbname FOR usr02-bname.  "user ID
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(24) text-011.
SELECTION-SCREEN: POSITION 25.
SELECT-OPTIONS:   s_class FOR usr02-class.  "user group
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(24) text-002.
SELECTION-SCREEN: POSITION 25.
SELECT-OPTIONS:   bobjcts FOR tobj-objct.  "Objects
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK exe.

INITIALIZATION.
  PERFORM list_excluded_objects.

***********************************************************************
*vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
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
  PERFORM check_authority.
  SORT gt_usr02 BY bname.

  GS_program = sy-repid.

  SELECT * FROM ust04 INTO TABLE iust04 WHERE bname IN pbname.
  LOOP AT iust04.
*   Check for users that pass authority check
    READ TABLE gt_usr02 WITH KEY bname = iust04-bname
               TRANSPORTING NO FIELDS
               BINARY SEARCH.
    CHECK sy-subrc = 0.

    REFRESH: profinfo.
    CALL FUNCTION '/PSYNG/SW_GET_SINGLE_PROFS'
         EXPORTING
              profname = iust04-profile
         TABLES
              profinfo = profinfo.
    LOOP AT profinfo.
      SELECT * FROM ust10s WHERE profn = profinfo-profn AND
                                 aktps = 'A'.
        userauth-bname = iust04-bname.
        userauth-objct = ust10s-objct.
        userauth-auth  = ust10s-auth.
        APPEND userauth.
      ENDSELECT.
    ENDLOOP.
  ENDLOOP.

  SORT userauth.
  DELETE ADJACENT DUPLICATES FROM userauth COMPARING ALL FIELDS.

  LOOP AT userauth.
    AT NEW bname.
      usercount = usercount + 1.
    ENDAT.

    userauthcount = userauthcount + 1.
    totalauthcount = totalauthcount + 1.

    AT END OF bname.
      sumry-bname = userauth-bname.
      sumry-authcount = userauthcount.
      APPEND sumry.
      CLEAR userauthcount.
    ENDAT.
  ENDLOOP.

  SORT sumry BY authcount DESCENDING bname.
  DELETE ADJACENT DUPLICATES FROM sumry COMPARING ALL FIELDS.
  PERFORM build_alv_catalog.
  PERFORM output_using_alv.

*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
***********************************************************************

*&---------------------------------------------------------------------*
*&      Form  BUILD_ALV_CATALOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_catalog.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = GS_program
            i_internal_tabname = 'SUMRY'
            i_inclname         = GS_program
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

  wa_fieldcat_alv-seltext_l = TEXT-005.
  wa_fieldcat_alv-seltext_m = TEXT-006.
  wa_fieldcat_alv-seltext_s = TEXT-007.
  wa_fieldcat_alv-reptext_ddic = TEXT-006.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'AUTHCOUNT'.

ENDFORM.                    " BUILD_ALV_CATALOG
*&---------------------------------------------------------------------*
*&      Form  OUTPUT_USING_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_using_alv.
  DATA: c_usercount(4),
        averageauth TYPE i,
        c_averageauth(4),
        alv_layout       TYPE slis_layout_alv,
        alv_grid_titl    TYPE lvc_title.


  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE s398(00) WITH text-003.
  ENDIF.

  c_usercount = usercount.
  averageauth = totalauthcount / usercount.
  c_averageauth = averageauth.
  CONCATENATE TEXT-008 c_usercount TEXT-009 c_averageauth
              TEXT-010 INTO alv_grid_titl
              SEPARATED BY space.

  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title            = alv_grid_titl
            i_callback_program      = GS_program
            is_layout               = alv_layout
            i_save                  = 'A'
            is_variant              = Gs_variant
            it_fieldcat             = i_fieldcat_alv
       TABLES
            t_outtab                = sumry
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.                    " OUTPUT_USING_ALV

*&---------------------------------------------------------------------*
*&      Form  LIST_EXCLUDED_OBJECTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM list_excluded_objects.
  bobjcts-sign = 'E'. bobjcts-option = 'EQ'.
  bobjcts-low = 'S_GUI'. APPEND bobjcts.

  bobjcts-sign = 'E'. bobjcts-option = 'EQ'.
  bobjcts-low = 'S_CARRID'. APPEND bobjcts.

  bobjcts-sign = 'E'. bobjcts-option = 'EQ'.
  bobjcts-low = 'S_ALV_LAYO'. APPEND bobjcts.
ENDFORM.                    " LIST_EXCLUDED_OBJECTS

*&---------------------------------------------------------------------*
*&      Form  check_authority
*&---------------------------------------------------------------------*
*       Perform necessary authority checks
*----------------------------------------------------------------------*
FORM check_authority.

  SELECT class bname INTO TABLE gt_usr02 FROM usr02
         WHERE bname IN pbname
           AND class IN s_class.
*DHO 20101202
*  SORT gt_usr02 BY class.
*  LOOP AT gt_usr02.
*    AT NEW class.
*      CHECK NOT gt_usr02-class IS INITIAL.
**     Check user group authority
*      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
*               ID 'CLASS' FIELD gt_usr02-class.
*      IF sy-subrc <> 0.
*        DELETE gt_usr02 WHERE class = gt_usr02-class.
*        gf_missing_auth_ugroup = 'X'.
*      ENDIF.
*    ENDAT.
*  ENDLOOP.
*DHO 20101202
data : lt_uinfo type table of /psyng/sw_uinfo with header line.
  loop at gt_usr02.
      lt_uinfo-bname = gt_usr02-bname.
      append lt_uinfo.
  endloop.
    CALL FUNCTION '/PSYNG/SW_USER_INFO'
     EXPORTING
*       VRSIO                    = sodvrsio
*       ENHANCED_SCANTABLE       = ''
       I_NAME_ONLY              = 'X'
       I_MR_COMPANY             = 'X'
      TABLES
        sw_uinfo                 = lt_uinfo.
  LOOP AT lt_uinfo.
  if not lt_uinfo-class is initial AND
     not lt_uinfo-company is initial.
    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
         ID 'CLASS' FIELD lt_uinfo-class
         ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_COMP'   field lt_uinfo-company.
      IF sy-subrc <> 0.
        DELETE gt_usr02 WHERE bname = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
  elseif not lt_uinfo-class is initial.
    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
         ID 'CLASS' FIELD lt_uinfo-class
         ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        DELETE gt_usr02 WHERE bname = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
  elseif not lt_uinfo-company is initial.
    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
         ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_COMP'   field lt_uinfo-company.
      IF sy-subrc <> 0.
        DELETE gt_usr02 WHERE bname = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
  endif.
  ENDLOOP.

ENDFORM.                    " check_authority
