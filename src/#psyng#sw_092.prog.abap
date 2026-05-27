*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_092
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
*
* COPYRIGHT Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sw_092 NO STANDARD PAGE HEADING LINE-SIZE 400.
*************************************************************
*------------------------tables-----------------------------*
*************************************************************
TABLES:/psyng/sw_sodmtr ,
       /psyng/sw_su24,
       tstc,
       /psyng/swsodvers.
.

*****************************************************
*************data declaration************************
*****************************************************
TYPE-POOLS: slis. "Define Type-Pool

DATA: v_alv_fieldcat TYPE slis_t_fieldcat_alv,  "Field Catalog
      l_sort TYPE slis_t_sortinfo_alv.
DATA: cc  TYPE lvc_t_scol WITH HEADER LINE,
      color TYPE lvc_s_colo.

DATA: gt_sodmat LIKE STANDARD TABLE OF /psyng/sw_sodmtr INITIAL SIZE 0
      WITH HEADER LINE,
      gt_su24 LIKE STANDARD TABLE OF /psyng/sw_su24  INITIAL SIZE 0 WITH
      HEADER LINE.
DATA: BEGIN OF gt_fin_sodtab OCCURS 0.
        INCLUDE STRUCTURE /psyng/sw_sodmtr.
DATA: field_text LIKE dfies-fieldtext,
*      ANDOR(5) TYPE C,
      actvtext3(35) TYPE c,
      actvtext4(35) TYPE c,
      flg,
     END OF gt_fin_sodtab.

DATA: BEGIN OF gt_fin_su24tab OCCURS 0.
        INCLUDE STRUCTURE /psyng/sw_su24.
DATA: field_text LIKE dfies-fieldtext,
      actvtext1(35) TYPE c,
      actvtext2(35) TYPE c,
      obj_sort TYPE n,
      flg,
      color_line(4) TYPE c,           " Line color
      color_cell    TYPE lvc_t_scol,  " Cell color
     END OF gt_fin_su24tab.

DATA: BEGIN OF gt_fin_comp OCCURS 0.
        INCLUDE STRUCTURE /psyng/sw_sodmtr.
DATA: field_text LIKE dfies-fieldtext,
*      ANDOR(5) TYPE C,
      actvtext3(35) TYPE c,
      actvtext4(35) TYPE c,
      tcode1 LIKE /psyng/sw_su24-tcode,
      tcode_text1 LIKE /psyng/sw_su24-tcode_text,
      object1 LIKE /psyng/sw_su24-object,
      obj_text1 LIKE /psyng/sw_su24-obj_text,
      name LIKE /psyng/sw_su24-name,
      field1 LIKE /psyng/sw_su24-field,
      low LIKE /psyng/sw_su24-low,
      high LIKE /psyng/sw_su24-high,
      field_text1 LIKE dfies-fieldtext,
      actvtext1(35) TYPE c,
      actvtext2(35) TYPE c,
      obj_sort TYPE n,
      color_line(4) TYPE c,           " Line color
      color_cell    TYPE lvc_t_scol,  " Cell color
      END OF gt_fin_comp.


DATA : actvttab LIKE STANDARD TABLE OF tactt INITIAL SIZE 0 WITH HEADER
LINE.

DATA:mcount TYPE i.

DATA:BEGIN OF it_text OCCURS 0,
        value TYPE char255,
 END OF it_text.


DATA:BEGIN OF it_text2 OCCURS 0,
        value TYPE char255,
 END OF it_text2.

DATA:text3 TYPE string.
DATA:text4  TYPE string.
DATA: idx LIKE sy-tabix VALUE '1'.
DATA: idx1 LIKE sy-tabix.
DATA : text TYPE string,
        text1 TYPE string,
        saprl LIKE cvers_txt-stext.
DATA:server LIKE msxxlist-name.


*****************************************************
*         selection screen                          *
*****************************************************
SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
SELECT-OPTIONS : s_vrsio FOR /psyng/swsodvers-vrsio,
                 s_tcode FOR tstc-tcode.
SELECTION-SCREEN: SKIP.

PARAMETERS : ck_com RADIOBUTTON GROUP rb1,
             ck_sod RADIOBUTTON GROUP rb1,
             ck_su24 RADIOBUTTON GROUP rb1.
SELECTION-SCREEN: END OF BLOCK b1.

******************************************************
**         selection screen Validation               *
******************************************************
*SELECT SINGLE *
*FROM /PSYNG/SWSODVERS
*WHERE VRSIO = S_VRSIO.
*IF SY-SUBRC <> 0.
*MESSAGE E156(/PSYNG/SW).
*ENDIF.

*****************************************************
*         start-of-selection                        *
*****************************************************
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
  SELECT *
  FROM /psyng/sw_sodmtr
  INTO TABLE  gt_sodmat
  WHERE sprsl = sy-langu
  AND vrsio IN s_vrsio
  AND tcode IN s_tcode.

  SELECT *
  FROM /psyng/sw_su24
  INTO TABLE  gt_su24
  WHERE sprsl = sy-langu
  AND tcode IN s_tcode.

  SELECT *
  FROM tactt
  INTO TABLE actvttab
  WHERE spras = sy-langu.

******* For sodmat modification ***********************
  IF ck_su24 <> 'X'.
    LOOP AT gt_sodmat.
      MOVE-CORRESPONDING gt_sodmat TO  gt_fin_sodtab.

      CALL FUNCTION 'AUTH_FIELD_GET_INFO'
        EXPORTING
          fieldname       = gt_sodmat-field
         langu           = sy-langu
       IMPORTING
*   DATEL           =
*   INTTYPE         =
*   LNG             =
*   RC              =
         text            = gt_fin_sodtab-field_text
                .
      CLEAR: gt_fin_sodtab-actvtext3,gt_fin_sodtab-actvtext4.
      IF gt_sodmat-field = 'ACTVT '.
        READ TABLE actvttab WITH KEY actvt = gt_sodmat-val_from.
        IF sy-subrc = 0.
        CONCATENATE gt_sodmat-val_from '(' actvttab-ltext ')'
            INTO gt_fin_sodtab-actvtext3 .
        ENDIF.

        READ TABLE actvttab WITH KEY actvt = gt_sodmat-val_to.
        IF sy-subrc = 0.
          CONCATENATE gt_sodmat-val_to '(' actvttab-ltext ')'
          INTO gt_fin_sodtab-actvtext4.
        ENDIF.
      ELSE.
        gt_fin_sodtab-actvtext3 = gt_sodmat-val_from.
        gt_fin_sodtab-actvtext4 = gt_sodmat-val_to.
      ENDIF.
      IF gt_sodmat-obj_or = ' '.
        gt_fin_sodtab-obj_or = 'AND'.
      ELSE.
        gt_fin_sodtab-obj_or = 'OR'.
      ENDIF.
      APPEND gt_fin_sodtab.

    ENDLOOP.
  ENDIF.
* For su24 modification  ******
  IF ck_sod <> 'X'.
    LOOP AT gt_su24.
      MOVE-CORRESPONDING gt_su24 TO gt_fin_su24tab.

      CALL FUNCTION 'AUTH_FIELD_GET_INFO'
        EXPORTING
          fieldname       = gt_su24-field
         langu           = sy-langu
       IMPORTING
*   DATEL           =
*   INTTYPE         =
*   LNG             =
*   RC              =
         text            = gt_fin_su24tab-field_text
                .
      CLEAR: gt_fin_su24tab-actvtext2,gt_fin_su24tab-actvtext1.
      IF gt_su24-field = 'ACTVT '.
        READ TABLE actvttab WITH KEY actvt = gt_su24-low.
        IF sy-subrc = 0.
          CONCATENATE gt_su24-low '(' actvttab-ltext ')'
          INTO gt_fin_su24tab-actvtext1 .
        ENDIF.
        READ TABLE actvttab WITH KEY actvt = gt_su24-high.
        IF sy-subrc = 0.
          CONCATENATE gt_su24-high '(' actvttab-ltext ')'
          INTO gt_fin_su24tab-actvtext2.
        ENDIF.
        REFRESH : gt_fin_su24tab-color_cell,cc.
        CLEAR: color.
        IF ( gt_su24-low = '03' OR gt_su24-low = '08' ) AND
        ( gt_su24-high = ' ' ).
          DELETE gt_fin_su24tab-color_cell
          WHERE fname = 'OBJECT'.
          color-col = '7'.   "Orange
          color-int = '1'.   "Intensified
          color-inv = '0'.   "Inverse
          cc-color  = color.
          cc-fname  = 'OBJECT'.
          APPEND cc TO gt_fin_su24tab-color_cell.
        ELSEIF gt_su24-low <> ' ' OR gt_su24-high <> ' '.
*       mcount = 0.
*       MCOUNT = MCOUNT + 1.
          DELETE gt_fin_su24tab-color_cell
          WHERE fname = 'OBJECT'.
          color-col = '5'.   "GREEN
          color-int = '1'.   "Intensified
          color-inv = '0'.   "Inverse
          cc-color  = color.
          cc-fname  = 'OBJECT'.
          APPEND cc TO gt_fin_su24tab-color_cell.

        ENDIF.
      ELSE.
        DELETE gt_fin_su24tab-color_cell
          WHERE fname = 'OBJECT'.
        gt_fin_su24tab-actvtext1 = gt_su24-low.
        gt_fin_su24tab-actvtext2 = gt_su24-high.
      ENDIF.

****************
      CLEAR:mcount.

      SPLIT gt_su24-tcode_text AT space INTO TABLE it_text.

      SPLIT gt_su24-obj_text AT space INTO TABLE it_text2.
      mcount = 0.
      LOOP AT it_text.
        LOOP AT it_text2.". where value = it_text-value.

          text3 = it_text-value.

          text4 = it_text2-value.


          IF text4 CS text3.

            mcount = mcount + 1.
            EXIT.
          ELSEIF text3 CS text4.
            mcount = mcount + 1.
            EXIT.
          ENDIF.

        ENDLOOP.
      ENDLOOP.
IF NOT ( gt_su24-low = '03' OR gt_su24-low = '08' OR gt_su24-low = ' ' )
                      AND gt_su24-high = ' '.

        mcount = mcount + 1.

      ENDIF.
      gt_fin_su24tab-obj_sort = mcount.
      APPEND gt_fin_su24tab.
    ENDLOOP.
  ENDIF.
* For combined modification *****
  IF ck_com = 'X'.
    SORT gt_fin_sodtab BY tcode.
    SORT gt_fin_su24tab BY tcode obj_sort DESCENDING.
    LOOP AT gt_fin_sodtab.
      idx1 = sy-tabix.
      READ TABLE gt_fin_su24tab INDEX idx.
      IF gt_fin_su24tab-tcode <> gt_fin_sodtab-tcode.
        idx = sy-tabix.
        EXIT.
*       continue.
      ELSE.
        MOVE-CORRESPONDING gt_fin_sodtab TO gt_fin_comp.
*      MOVE-CORRESPONDING gt_fin_su24tab TO gt_fin_comp.

        gt_fin_comp-tcode1 = gt_fin_su24tab-tcode.
        gt_fin_comp-tcode_text1  = gt_fin_su24tab-tcode_text.
        gt_fin_comp-object1 = gt_fin_su24tab-object.
        gt_fin_comp-obj_text1 = gt_fin_su24tab-obj_text.
        gt_fin_comp-field1 = gt_fin_su24tab-field.
        gt_fin_comp-field_text1 = gt_fin_su24tab-field_text.
        gt_fin_comp-low = gt_fin_su24tab-low.
        gt_fin_comp-high = gt_fin_su24tab-high.
        gt_fin_comp-actvtext1 = gt_fin_su24tab-actvtext1.
        gt_fin_comp-actvtext2 = gt_fin_su24tab-actvtext2.
        gt_fin_comp-obj_sort = gt_fin_su24tab-obj_sort.
        gt_fin_su24tab-flg = 'X'.
        MODIFY gt_fin_su24tab INDEX idx TRANSPORTING flg.
        gt_fin_sodtab-flg = 'X'.
        MODIFY gt_fin_sodtab INDEX idx1 TRANSPORTING flg.
      ENDIF.
      APPEND gt_fin_comp.
      idx = idx + 1.
    ENDLOOP.
    LOOP AT gt_fin_su24tab WHERE flg = ' '.
      CLEAR: gt_fin_comp.
      gt_fin_comp-tcode = gt_fin_su24tab-tcode.
      gt_fin_comp-tcode_text  = gt_fin_su24tab-tcode_text.
      gt_fin_comp-tcode1 = gt_fin_su24tab-tcode.
      gt_fin_comp-tcode_text1  = gt_fin_su24tab-tcode_text.
      gt_fin_comp-object1 = gt_fin_su24tab-object.
      gt_fin_comp-obj_text1 = gt_fin_su24tab-obj_text.
      gt_fin_comp-field1 = gt_fin_su24tab-field.
      gt_fin_comp-field_text1 = gt_fin_su24tab-field_text.
      gt_fin_comp-low = gt_fin_su24tab-low.
      gt_fin_comp-high = gt_fin_su24tab-high.
      gt_fin_comp-actvtext1 = gt_fin_su24tab-actvtext1.
      gt_fin_comp-actvtext2 = gt_fin_su24tab-actvtext2.
      gt_fin_comp-obj_sort = gt_fin_su24tab-obj_sort.
      APPEND gt_fin_comp.
    ENDLOOP.
    LOOP AT gt_fin_sodtab WHERE flg = ' '.
      CLEAR: gt_fin_comp.
      MOVE-CORRESPONDING gt_fin_sodtab TO gt_fin_comp.
      APPEND gt_fin_comp.
    ENDLOOP.
  ENDIF.

  SORT gt_fin_comp.
  DELETE ADJACENT DUPLICATES FROM gt_fin_comp COMPARING ALL FIELDS.

  CALL FUNCTION 'FIND_DB_APPLICATION_SERVER'
       IMPORTING
            servername            = server
       EXCEPTIONS
            no_application_server = 1
            OTHERS                = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  SELECT SINGLE stext
  FROM cvers_txt
  INTO saprl
  WHERE langu = sy-langu.

  SELECT SINGLE vdesc
  FROM /psyng/swsodvers
  INTO /psyng/swsodvers-vdesc
  WHERE vrsio = s_vrsio-low.
  text = /psyng/swsodvers-vdesc.

  CLEAR :/psyng/swsodvers.
  IF NOT s_vrsio-high IS INITIAL .
    SELECT SINGLE vdesc
    FROM /psyng/swsodvers
    INTO /psyng/swsodvers-vdesc
    WHERE vrsio = s_vrsio-high.
    text1 = /psyng/swsodvers-vdesc.
  CONCATENATE s_vrsio-low '(' text ')' INTO text SEPARATED BY
                           space.
  CONCATENATE s_vrsio-high '(' text1 ')' INTO text1 SEPARATED
                          BY space.
    CONCATENATE  text text-020 text1 INTO text SEPARATED BY space.
  ELSE.
    CONCATENATE s_vrsio-low '(' text ')' INTO text.
  ENDIF.

  IF ck_com = 'X'.
    PERFORM combined_output.
  ELSEIF ck_sod = 'X'.
    PERFORM sod_output.
  ELSE.
    PERFORM su24_output.
  ENDIF.
*&---------------------------------------------------------------------*
*&      Form  Combined_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM combined_output.
*write:/50 text-015 color 1.
  WRITE:/3 text-016 ,saprl,70 text-017,server .
  SKIP.
  WRITE:/3 text-018 ,sy-mandt,70 text-017,text .
  SKIP 2.
  WRITE:/60 text-024 COLOR 1,250 text-025 COLOR 2.
  SORT gt_fin_comp BY tcode obj_sort DESCENDING.

  LOOP AT gt_fin_comp.
    text3 = gt_fin_comp-tcode_text.
    ON CHANGE OF  gt_fin_comp-tcode.
      WRITE:/3 text-004,20 gt_fin_comp-tcode,text3.
    ENDON.
    text4 = gt_fin_comp-description.
    ON CHANGE OF  gt_fin_comp-function.
      WRITE:/15 text-006,40 gt_fin_comp-function,text4.
      FORMAT COLOR 2 ON.
WRITE:/20 text-008,30 text-021,35 text-009,120 text-011,140 text-013,180
  text-014,200 '!!',210 text-009,280 text-011,310 text-013,330 text-014,
                                    360 text-022 .
      FORMAT COLOR 2 OFF.
    ENDON.
    IF gt_fin_comp-field1 = 'ACTVT'.
  IF ( gt_fin_comp-actvtext1 = '03(Display)' OR gt_fin_comp-actvtext1 =
       '08(Display change documents)' ) AND gt_fin_comp-actvtext2 = ' '.
        WRITE:/20 gt_fin_comp-valueset,30 gt_fin_comp-obj_or,35
     gt_fin_comp-object,gt_fin_comp-obj_text,120 gt_fin_comp-field,
     gt_fin_comp-field_text,140 gt_fin_comp-actvtext3,180
     gt_fin_comp-actvtext4,200 '!!',210 gt_fin_comp-object1 COLOR 7,
  gt_fin_comp-obj_text1, 280 gt_fin_comp-field1,gt_fin_comp-field_text1,
     310 gt_fin_comp-actvtext1, 330 gt_fin_comp-actvtext2,360
     gt_fin_comp-obj_sort  .

      ELSE.
        IF NOT gt_fin_comp-actvtext1 IS INITIAL.
          WRITE:/20 gt_fin_comp-valueset,30 gt_fin_comp-obj_or,35
         gt_fin_comp-object,gt_fin_comp-obj_text,120 gt_fin_comp-field,
         gt_fin_comp-field_text,140 gt_fin_comp-actvtext3,180
         gt_fin_comp-actvtext4,200 '!!',210 gt_fin_comp-object1 COLOR 5,
  gt_fin_comp-obj_text1, 280 gt_fin_comp-field1,gt_fin_comp-field_text1,
         310 gt_fin_comp-actvtext1, 330 gt_fin_comp-actvtext2,360
         gt_fin_comp-obj_sort  .
        ELSE.
          WRITE:/20 gt_fin_comp-valueset,30 gt_fin_comp-obj_or,35
    gt_fin_comp-object,gt_fin_comp-obj_text,120 gt_fin_comp-field,
    gt_fin_comp-field_text,140 gt_fin_comp-actvtext3,180
    gt_fin_comp-actvtext4,200 '!!',210 gt_fin_comp-object1,
gt_fin_comp-obj_text1, 280 gt_fin_comp-field1,gt_fin_comp-field_text1,
    310 gt_fin_comp-actvtext1, 330 gt_fin_comp-actvtext2,360
    gt_fin_comp-obj_sort  .
        ENDIF.
      ENDIF.

    ELSE.
      WRITE:/20 gt_fin_comp-valueset,30 gt_fin_comp-obj_or,35
      gt_fin_comp-object,gt_fin_comp-obj_text,120 gt_fin_comp-field,
      gt_fin_comp-field_text,140 gt_fin_comp-actvtext3,180
      gt_fin_comp-actvtext4,200 '!!',210 gt_fin_comp-object1,
  gt_fin_comp-obj_text1, 280 gt_fin_comp-field1,gt_fin_comp-field_text1,
      310 gt_fin_comp-actvtext1, 330 gt_fin_comp-actvtext2,360
      gt_fin_comp-obj_sort  .
    ENDIF.
  ENDLOOP.


ENDFORM.                    " Combined_output
*&---------------------------------------------------------------------*
*&      Form  SOD_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM sod_output.
  PERFORM build_fieldcat.
  PERFORM sod_sort.
  PERFORM out_put.


ENDFORM.                    " SOD_output
*&---------------------------------------------------------------------*
*&      Form  SU24_Output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM su24_output.
  PERFORM su24_fieldcat.
  PERFORM su24_sort.
  PERFORM su24_display.
ENDFORM.                    " SU24_Output
*&---------------------------------------------------------------------*
*&      Form  BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_fieldcat.
 DATA: w_fieldcat TYPE slis_fieldcat_alv.        "Field Catalog Workarea

  REFRESH : v_alv_fieldcat.

  w_fieldcat-fieldname = 'VRSIO'.
  w_fieldcat-tabname   = 'GT_FIN_SODTAB'.
  w_fieldcat-seltext_l = text-023.
  w_fieldcat-col_pos = 1.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'TCODE'.
  w_fieldcat-tabname   = 'GT_FIN_SODTAB'.
  w_fieldcat-seltext_l = text-004.
  w_fieldcat-col_pos = 1.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'TCODE_TEXT'.
  w_fieldcat-tabname   = 'GT_FIN_SODTAB'.
  w_fieldcat-seltext_l = text-005.
  w_fieldcat-col_pos = 2.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'FUNCTION'.
  w_fieldcat-tabname   = 'GT_FIN_SODTAB'.
  w_fieldcat-seltext_l = text-006.
  w_fieldcat-col_pos = 3.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'DESCRIPTION'.
  w_fieldcat-tabname   = 'GT_FIN_SODTAB'.
  w_fieldcat-seltext_l = text-007.
  w_fieldcat-col_pos = 4.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'VALUESET'.
  w_fieldcat-tabname   = 'GT_FIN_SODTAB'.
  w_fieldcat-seltext_l = text-008.
  w_fieldcat-col_pos = 5.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'OBJ_OR'.
  w_fieldcat-tabname   = 'GT_FIN_SODTAB'.
  w_fieldcat-seltext_l = text-021.
  w_fieldcat-col_pos = 6.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.
  w_fieldcat-fieldname = 'OBJECT'.
  w_fieldcat-tabname   = 'GT_FIN_SODTAB'.
  w_fieldcat-seltext_l = text-009.
  w_fieldcat-col_pos = 7.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'OBJ_TEXT'.
  w_fieldcat-tabname   = 'GT_FIN_SODTAB'.
  w_fieldcat-seltext_l = text-010.
  w_fieldcat-col_pos = 8.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'FIELD'.
  w_fieldcat-tabname   = 'GT_FIN_SODTAB'.
  w_fieldcat-seltext_l = text-011.
  w_fieldcat-col_pos = 9.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'FIELD_TEXT'.
  w_fieldcat-tabname   = 'GT_FIN_SODTAB'.
  w_fieldcat-seltext_l = text-012.
  w_fieldcat-col_pos = 10.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'ACTVTEXT3'.
  w_fieldcat-tabname   = 'GT_FIN_SODTAB'.
  w_fieldcat-seltext_l = text-013.
  w_fieldcat-col_pos = 11.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'ACTVTEXT4'.
  w_fieldcat-tabname   = 'GT_FIN_SODTAB'.
  w_fieldcat-seltext_l = text-014.
  w_fieldcat-col_pos = 12.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

ENDFORM.                    " BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*&      Form  OUT_PUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM out_put.
  DATA: ls_layout  TYPE slis_layout_alv,            "ALV Report Layout
        l_program  LIKE sy-repid,
        ls_variant TYPE disvariant.

  l_program = sy-repid.
  ls_layout-zebra = 'X'.
  ls_layout-colwidth_optimize = 'X'.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program       = l_program
            i_callback_top_of_page  = 'USER-TOP-OF-PAGE'
*            I_CALLBACK_PF_STATUS_SET = 'PF_STATUS'
*            I_CALLBACK_USER_COMMAND  = 'USER_COMMAND'
            is_layout                = ls_layout
            it_fieldcat              = v_alv_fieldcat
            it_sort                  = l_sort
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = gt_fin_sodtab
       EXCEPTIONS
            program_error            = 1
            OTHERS                   = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " OUT_PUT
*---------------------------------------------------------------------*
*       USER-TOP-OF-PAGE                                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM user-top-of-page.
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader.



  wa-typ = 'H'.
  wa-info = text-015.
  APPEND wa TO header.

  wa-typ = 'S'.
  wa-key = text-016.
  wa-info = saprl. "sy-saprl.
  APPEND wa TO header.

  wa-typ = 'S'.
  wa-key = text-017.
  wa-info = server . "sy-HOST.
  APPEND wa TO header.

  wa-typ = 'S'.
  wa-key = text-018.
  wa-info = sy-mandt.
  APPEND wa TO header.

  wa-typ = 'S'.
  wa-key = text-019.
  wa-info = text.
  APPEND wa TO header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = header
            i_logo             = 'Z_3SW_LOGO_JPG'.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SU24_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM su24_fieldcat.
 DATA: w_fieldcat TYPE slis_fieldcat_alv.        "Field Catalog Workarea

  REFRESH : v_alv_fieldcat.


  w_fieldcat-fieldname = 'TCODE'.
  w_fieldcat-tabname   = 'GT_FIN_SU24TAB'.
  w_fieldcat-seltext_l = text-004.
  w_fieldcat-col_pos = 1.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'TCODE_TEXT'.
  w_fieldcat-tabname   = 'GT_FIN_SU24TAB'.
  w_fieldcat-seltext_l = text-005.
  w_fieldcat-col_pos = 2.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.


  w_fieldcat-fieldname = 'OBJECT'.
  w_fieldcat-tabname   = 'GT_FIN_SU24TAB'.
  w_fieldcat-seltext_l = text-009.
  w_fieldcat-col_pos = 3.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'OBJ_TEXT'.
  w_fieldcat-tabname   = 'GT_FIN_SU24TAB'.
  w_fieldcat-seltext_l = text-010.
  w_fieldcat-col_pos = 4.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'FIELD'.
  w_fieldcat-tabname   = 'GT_FIN_SU24TAB'.
  w_fieldcat-seltext_l = text-011.
  w_fieldcat-col_pos = 5.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'FIELD_TEXT'.
  w_fieldcat-tabname   = 'GT_FIN_SU24TAB'.
  w_fieldcat-seltext_l = text-012.
  w_fieldcat-col_pos = 6.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'ACTVTEXT1'.
  w_fieldcat-tabname   = 'GT_FIN_SU24TAB'.
  w_fieldcat-seltext_l = text-013.
  w_fieldcat-col_pos = 7.

*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'ACTVTEXT2'.
  w_fieldcat-tabname   = 'GT_FIN_SU24TAB'.
  w_fieldcat-seltext_l = text-014.
  w_fieldcat-col_pos = 8.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'OBJ_SORT'.
  w_fieldcat-tabname   = 'GT_FIN_SU24TAB'.
  w_fieldcat-seltext_l = text-022.
  w_fieldcat-col_pos = 8.
*  W_FIELDCAT-HOTSPOT = 'X'.
*  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.




ENDFORM.                    " SU24_FIELDCAT
*&---------------------------------------------------------------------*
*&      Form  SU24_Display
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM su24_display.
  DATA: ls_layout  TYPE slis_layout_alv,            "ALV Report Layout
         l_program  LIKE sy-repid,
         ls_variant TYPE disvariant.

  l_program = sy-repid.
  ls_layout-zebra = 'X'.
  ls_layout-colwidth_optimize = 'X'.
  MOVE 'COLOR_LINE' TO ls_layout-info_fieldname.
  MOVE 'COLOR_CELL' TO ls_layout-coltab_fieldname.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program       = l_program
            i_callback_top_of_page  = 'USER-TOP-OF-PAGE'
*            I_CALLBACK_PF_STATUS_SET = 'PF_STATUS'
*            I_CALLBACK_USER_COMMAND  = 'USER_COMMAND'
            is_layout                = ls_layout
            it_fieldcat              = v_alv_fieldcat
            it_sort                  = l_sort
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = gt_fin_su24tab
       EXCEPTIONS
            program_error            = 1
            OTHERS                   = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.


ENDFORM.                    " SU24_Display
*&---------------------------------------------------------------------*
*&      Form  SOD_SORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM sod_sort.
  DATA: w_sort TYPE slis_sortinfo_alv.
  REFRESH : l_sort.
  w_sort-spos = '1'.
  w_sort-fieldname = 'VRSIO'.
  w_sort-tabname = 'GT_FIN_SODTAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '2'.
  w_sort-fieldname = 'TCODE'.
  w_sort-tabname = 'GT_FIN_SODTAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '3'.
  w_sort-fieldname = 'TCODE_TEXT'.
  w_sort-tabname = 'GT_FIN_SODTAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '4'.
  w_sort-fieldname = 'FUNCTION'.
  w_sort-tabname = 'GT_FIN_SODTAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '5'.
  w_sort-fieldname = 'DESCRIPTION'.
  w_sort-tabname = 'GT_FIN_SODTAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '6'.
  w_sort-fieldname = 'OBJECT'.
  w_sort-tabname = 'GT_FIN_SODTAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '7'.
  w_sort-fieldname = 'OBJ_TEXT'.
  w_sort-tabname = 'GT_FIN_SODTAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '8'.
  w_sort-fieldname = 'FIELD'.
  w_sort-tabname = 'GT_FIN_SODTAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '9'.
  w_sort-fieldname = 'ACTVTEXT3'.
  w_sort-tabname = 'GT_FIN_SODTAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '10'.
  w_sort-fieldname = 'ACTVTEXT4'.
  w_sort-tabname = 'GT_FIN_SODTAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.





ENDFORM.                    " SOD_SORT
*&---------------------------------------------------------------------*
*&      Form  SU24_SORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM su24_sort.
  DATA: w_sort TYPE slis_sortinfo_alv.
  REFRESH : l_sort.
  w_sort-spos = '1'.
  w_sort-fieldname = 'TCODE'.
  w_sort-tabname = 'GT_FIN_SU24TAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '2'.
  w_sort-fieldname = 'TCODE_TEXT'.
  w_sort-tabname = 'GT_FIN_SU24TAB'.
  w_sort-down = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '3'.
  w_sort-fieldname = 'OBJ_SORT'.
  w_sort-tabname = 'GT_FIN_SU24TAB'.
  w_sort-up = ' '.
  w_sort-down = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '4'.
  w_sort-fieldname = 'OBJECT'.
  w_sort-tabname = 'GT_FIN_SU24TAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '5'.
  w_sort-fieldname = 'OBJ_TEXT'.
  w_sort-tabname = 'GT_FIN_SU24TAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '6'.
  w_sort-fieldname = 'FIELD'.
  w_sort-tabname = 'GT_FIN_SU24TAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '7'.
  w_sort-fieldname = 'FIELD_TEXT'.
  w_sort-tabname = 'GT_FIN_SU24TAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '8'.
  w_sort-fieldname = 'ACTVTEXT1'.
  w_sort-tabname = 'GT_FIN_SU24TAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '9'.
  w_sort-fieldname = 'ACTVTEXT2'.
  w_sort-tabname = 'GT_FIN_SU24TAB'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.
ENDFORM.                                                    " SU24_SORT
