*----------------------------------------------------------------------*
* Report  /PSYNG/SW_103                                         *
* AUTHOR  : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

REPORT /psyng/sw_103 LINE-SIZE 255 ."#EC SAST_CI_GEN_CHECK
*----------------------------------------------------------------------*
*  Tables Declaration
*----------------------------------------------------------------------*
TABLES:info_tran,tdevc,tdevct,df14vd,tstc,
       tstct,tftit ,trdir,trdirt,tadir,
       /psyng/function,/psyng/functtran,/psyng/conflict.
*----------------------------------------------------------------------*
*  type pool and ALV Declaration
*----------------------------------------------------------------------*
TYPE-POOLS : slis.

DATA: g_repid TYPE sy-repid.

**SOD
DATA: gt_sod_fcat TYPE slis_t_fieldcat_alv,
      gs_sod_layout TYPE slis_layout_alv,
      gt_sod_sort TYPE slis_t_sortinfo_alv.
DATA: g_sod_repid TYPE sy-repid.
***********************************

**NON SOD
DATA: gt_nonsod_fcat TYPE slis_t_fieldcat_alv,
      gs_nonsod_layout TYPE slis_layout_alv,
      gt_nonsod_sort TYPE slis_t_sortinfo_alv.
DATA: g_nonsod_repid TYPE sy-repid.

DATA: g_count TYPE i.
***********************************
*Background job variables
DATA: curr_variant LIKE  rsvar-variant,
      vari_desc TYPE varid OCCURS 0 WITH HEADER LINE,
      vari_contents LIKE  rsparams OCCURS 0 WITH HEADER LINE,
      vari_text LIKE varit OCCURS 0 WITH HEADER LINE.
DATA: variant LIKE vari-variant.
DATA: exit_proc.

DATA: gt_rsparams TYPE rsparams OCCURS 0 WITH HEADER LINE.
**************************************



*----------------------------------------------------------------------*
*  Fields Declaration
*----------------------------------------------------------------------*
DATA:g_filename   TYPE rlgrap-filename,
     g_sod_file TYPE string,
     g_nonsod_file  TYPE string.

*----------------------------------------------------------------------*
*  Internal Table and Work area Declaration
*----------------------------------------------------------------------*
****SOD OUTPUT
DATA:BEGIN OF gt_sod_tcodes OCCURS 0,
     vrsio(3) TYPE c,                            "Version
     function TYPE /psyng/function-function,     "Function
     description TYPE /psyng/function-description,"Text
     busarea TYPE /psyng/function-busarea,       "Application Area
     tcode TYPE tstc-tcode,                      "tcode
     ttext TYPE tstct-ttext,                     "tcode text
     devclass TYPE info_tran-devclass,           "Dev class
     ctext TYPE tdevct-ctext,                    "Dev class text
     ps_posid TYPE df14vd-ps_posid,              "name of the sap module
     name TYPE df14vd-name,                      "sap module text
     END OF gt_sod_tcodes .
DATA:g_wa_sod_tcodes  LIKE LINE OF  gt_sod_tcodes .

***NON SOD OUTPUT

DATA:BEGIN OF gt_nonsod_tcodes OCCURS 0,
     tcode TYPE tstc-tcode,           "tcode
     ttext TYPE tstct-ttext,          "text
     devclass TYPE info_tran-devclass,"Dev class
     ctext TYPE tdevct-ctext,         "Dev class text
     ps_posid TYPE df14vd-ps_posid,   "name of the sap module
     name TYPE df14vd-name,           "sap module text
    END OF gt_nonsod_tcodes.
DATA:g_wa_nonsod_tcodes LIKE LINE OF  gt_nonsod_tcodes,
     g_current_user TYPE sy-uname. "C0700

*----------------------------------------------------------------------*
*  SELECTION-SCREEN Declaration
*----------------------------------------------------------------------*
SELECTION-SCREEN : BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
SELECT-OPTIONS   : s_tcode FOR tstc-tcode.
SELECT-OPTIONS   : s_dev FOR tdevc-devclass .
SELECTION-SCREEN : END OF BLOCK b1.
************************************************************
SELECTION-SCREEN : BEGIN OF BLOCK b2 WITH FRAME TITLE text-035.
PARAMETERS:sodvrsio LIKE /psyng/conflict-vrsio  MODIF ID xyz
                    MEMORY ID /psyng/vrsio .
SELECT-OPTIONS   : s_funid FOR /psyng/functtran-functionid MODIF ID xyz.
SELECTION-SCREEN : END OF BLOCK b2.
************************************************************
SELECTION-SCREEN: BEGIN OF BLOCK b3 WITH FRAME TITLE text-038.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: sod RADIOBUTTON GROUP out USER-COMMAND ucmd DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 4(30) text-036.
SELECTION-SCREEN: POSITION 35.
PARAMETERS: nonsod RADIOBUTTON GROUP out .
SELECTION-SCREEN: COMMENT 37(30) text-037.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK b3.
***********************************************************
SELECTION-SCREEN: BEGIN OF BLOCK b4 WITH FRAME TITLE text-002.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: alv RADIOBUTTON GROUP out1 DEFAULT 'X'.  "ALV Output
SELECTION-SCREEN: COMMENT 4(30) text-003.
SELECTION-SCREEN: POSITION 35.
PARAMETERS: std RADIOBUTTON GROUP out1.              "Stanadard output
SELECTION-SCREEN: COMMENT 37(30) text-004.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK b4.
***********************************
SELECTION-SCREEN: BEGIN OF BLOCK b5 WITH FRAME TITLE text-t11.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-t06.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-t07.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN PUSHBUTTON  4(30) text-t09 USER-COMMAND scjb.
SELECTION-SCREEN PUSHBUTTON  40(25) text-t10 USER-COMMAND sm37.
SELECTION-SCREEN: END OF BLOCK b5.
************************************************************
INITIALIZATION.

* BOC by RGUPTA on 04.04.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 04.04.22 for C0700

  PERFORM exelog.

AT SELECTION-SCREEN OUTPUT.

  IF sod = 'X'.
    LOOP AT SCREEN.
      IF screen-group1 = 'XYZ'.
        screen-active = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDLOOP.

  ELSE.
    LOOP AT SCREEN.
      IF screen-group1 = 'XYZ'.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

AT SELECTION-SCREEN.

  IF NOT sodvrsio IS INITIAL.
    SELECT SINGLE mandt INTO sy-mandt FROM /psyng/swsodvers
                  WHERE vrsio = sodvrsio.
    IF sy-subrc <> 0.
      MESSAGE e156(/psyng/sw).
    ENDIF.
  ENDIF.
*************************************
  IF sy-ucomm = 'SM37'.
    AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
    IF sy-subrc <> 0.
      MESSAGE e077(s#) WITH 'SM37'.
    ELSE.
      CALL TRANSACTION 'SM37'.
    ENDIF.
  ENDIF.
  IF sy-ucomm = 'SCJB'.
    exit_proc = 'Y'.
    PERFORM schedule_back_job.
  ENDIF.

*----------------------------------------------------------------------*
*  START-OF-SELECTION.
*----------------------------------------------------------------------*
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
*****background job from selection screen
  g_repid = sy-repid.
  IF exit_proc = 'Y'.
    SUBMIT (g_repid)"#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(12/12/24)
           VIA SELECTION-SCREEN
           USING SELECTION-SET curr_variant .
  ENDIF.


****************************************

  PERFORM get_data.
  MESSAGE s398(00) WITH ' Total'(032) g_count 'Record(s)'(033).


******SOD Transactions
  IF sod EQ 'X'.
    IF alv ='X'.
      PERFORM display_sod_alv_output.
    ELSE.
      PERFORM display_sod_std_output.
    ENDIF.
  ELSE.
*****NONSOD Transactions
    IF alv ='X'.
      PERFORM display_nonsod_alv_output.
    ELSE.
      PERFORM display_nonsod_std_output.
    ENDIF.
  ENDIF.

TOP-OF-PAGE.

***Printing filed names in sod output for standard output
  IF sod EQ 'X'.
    WRITE:/
                   'SOD Version'(023),
               15  'SOD FunctionID'(012),
               32  'Function Description'(013),
               65  'SOD Application Area'(014),
               89  'Transaction'(005),
              115  'Transaction Text'(006),
              155  'Development Class'(007),
              175  'Development Class Text'(008),
              220  'SAP Module'(009),
              235  'SAP Module Text'(010).
  ELSE.
***Printing filed names in NONSOD output for standard output

    WRITE:/     'Transaction'(005),
           45   'Transaction Text'(006),
           83   'Development Class'(007),
           105  'Development Class Text'(008),
           155  'SAP Module'(009),
           175  'SAP Module Text'(010).
  ENDIF.
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
*       text log the details of execution history of this report
*----------------------------------------------------------------------*
FORM exelog.
  DATA: task_name(8),
        exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE.

  MOVE sy-uzeit TO task_name.
  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = g_current_user. "sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.

  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    STARTING NEW TASK task_name DESTINATION IN GROUP DEFAULT
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

  IF sod EQ 'X'.
**  *******  getting SOD data
    SELECT h~vrsio h~function
           h~description h~busarea
           a~tcode b~ttext
           c~devclass
           e~ctext
           f~ps_posid f~name


    INTO TABLE gt_sod_tcodes

    FROM tstc AS a
    INNER JOIN tstct AS b
        ON a~tcode = b~tcode

   INNER JOIN /psyng/functtran AS g
        ON a~tcode = g~tcode

    INNER JOIN /psyng/function AS h
        ON g~functionid = h~function

    INNER JOIN info_tran AS c
       ON b~tcode = c~tcode
    INNER JOIN tdevc AS d
       ON c~devclass = d~devclass

    INNER JOIN tdevct AS e
       ON d~devclass = e~devclass

    INNER JOIN df14vd AS f
       ON d~component = f~fctr_id

    WHERE b~sprsl = sy-langu
            AND e~spras  = sy-langu

                AND f~langu  = sy-langu
                        AND a~tcode IN  s_tcode
                        AND
                        d~devclass IN  s_dev
                        AND g~functionid IN s_funid
                             AND g~vrsio EQ sodvrsio
                             AND h~vrsio EQ sodvrsio.
    IF sy-subrc <> 0.
      MESSAGE s113(/psyng/sw) WITH text-015.
      LEAVE LIST-PROCESSING.

    ENDIF.

***getting no of records as count for SOD
    DESCRIBE TABLE gt_sod_tcodes  LINES g_count.
**********************************************************************
  ELSE.
*******  getting NON SOD data
    SELECT a~tcode b~ttext
              c~devclass
              e~ctext
              f~ps_posid f~name

       INTO TABLE gt_nonsod_tcodes

       FROM tstc AS a
       INNER JOIN tstct AS b
           ON a~tcode = b~tcode

       INNER JOIN info_tran AS c
          ON b~tcode = c~tcode
       INNER JOIN tdevc AS d
          ON c~devclass = d~devclass

       INNER JOIN tdevct AS e
          ON d~devclass = e~devclass

       INNER JOIN df14vd AS f
          ON d~component = f~fctr_id

       WHERE b~sprsl = sy-langu
               AND e~spras  = sy-langu

                   AND f~langu  = sy-langu
                           AND a~tcode IN  s_tcode
                           AND
                           d~devclass IN  s_dev.

    IF sy-subrc <> 0.
      MESSAGE s113(/psyng/sw) WITH text-015.
      LEAVE LIST-PROCESSING.

    ENDIF.
******getting no of records as count for NON SOD
    CLEAR:g_count.
    DESCRIBE TABLE gt_nonsod_tcodes LINES g_count.
  ENDIF.
ENDFORM.                    " get_data

*&---------------------------------------------------------------------*
*&      Form  display_sod_alv_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_sod_alv_output.

  DATA: ls_sod_variant TYPE disvariant.
  PERFORM sod_fill_fieldcat.

  g_sod_repid = sy-repid.
  gs_sod_layout-zebra = 'X'.
  gs_sod_layout-colwidth_optimize = 'X'.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   EXPORTING
     i_callback_program          = g_sod_repid
     i_callback_pf_status_set    = 'SET_PF_STATUS'
     i_callback_user_command     = 'USER_DOUBLE_CLICK_ON_DETL'
     i_callback_top_of_page      = 'SOD_TOP_OF_PAGE'
     is_layout                   = gs_sod_layout
     it_fieldcat                 = gt_sod_fcat
     it_sort                     = gt_sod_sort
     i_default                   = 'X'
     i_save                      = 'A'
     is_variant                  = ls_sod_variant
*    IT_EVENTS                   =
  TABLES
      t_outtab                   = gt_sod_tcodes[]
   EXCEPTIONS
     program_error               = 1
     OTHERS                      = 2
            .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " display_sod_alv_output
*&---------------------------------------------------------------------*
*&      Form  display_nonsod_alv_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_nonsod_alv_output.
  DATA: ls_nonsod_variant TYPE disvariant.
  PERFORM nonsod_fill_fieldcat.

  g_nonsod_repid = sy-repid.
  gs_nonsod_layout-zebra = 'X'.
  gs_nonsod_layout-colwidth_optimize = 'X'.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   EXPORTING
     i_callback_program          =  g_nonsod_repid
     i_callback_pf_status_set    = 'SET_PF_STATUS'
     i_callback_user_command     = 'USER_DOUBLE_CLICK_ON_DETL'
     i_callback_top_of_page      = 'NONSOD_TOP_OF_PAGE'
     is_layout                   =  gs_nonsod_layout
     it_fieldcat                 =  gt_nonsod_fcat
     it_sort                     =  gt_nonsod_sort
     i_default                   = 'X'
     i_save                      = 'A'
     is_variant                  = ls_nonsod_variant
*    IT_EVENTS                   =
  TABLES
      t_outtab                   = gt_nonsod_tcodes[]
   EXCEPTIONS
     program_error               = 1
     OTHERS                      = 2
            .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " display_nonsod_alv_output
*&---------------------------------------------------------------------*
*&      Form  fill_fieldcat
*&---------------------------------------------------------------------*
*       text  sod field catalog
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM sod_fill_fieldcat.

  DATA: lw_sod_fcat TYPE slis_fieldcat_alv.
  DATA: lw_sod_sort TYPE slis_sortinfo_alv.

  REFRESH : gt_sod_fcat.


*************sod fieldcatalog********************
  lw_sod_fcat-col_pos = '1'.
  lw_sod_fcat-fieldname = 'VRSIO'.
  lw_sod_fcat-emphasize = 'C400'.
  lw_sod_fcat-seltext_l = text-011.
  APPEND lw_sod_fcat TO gt_sod_fcat.
  CLEAR lw_sod_fcat.

  lw_sod_fcat-col_pos = '2'.
  lw_sod_fcat-fieldname = 'FUNCTION'.
  lw_sod_fcat-seltext_l = text-012.
  lw_sod_fcat-emphasize = 'C400'.
  APPEND lw_sod_fcat TO gt_sod_fcat.
  CLEAR lw_sod_fcat.

  lw_sod_fcat-col_pos = '3'.
  lw_sod_fcat-fieldname = 'DESCRIPTION'.
  lw_sod_fcat-seltext_l = text-013.
  APPEND lw_sod_fcat TO gt_sod_fcat.
  CLEAR lw_sod_fcat.


  lw_sod_fcat-col_pos = '4'.
  lw_sod_fcat-fieldname = 'BUSAREA'.
  lw_sod_fcat-seltext_l = text-014.
  lw_sod_fcat-emphasize = 'C400'.
  APPEND lw_sod_fcat TO gt_sod_fcat.
  CLEAR lw_sod_fcat.

*********************************
  lw_sod_fcat-col_pos = '5'.
  lw_sod_fcat-fieldname = 'TCODE'.
  lw_sod_fcat-emphasize = 'C400'.
  lw_sod_fcat-hotspot = 'X'.
  lw_sod_fcat-seltext_l = text-005.
  APPEND lw_sod_fcat TO gt_sod_fcat.
  CLEAR lw_sod_fcat.

  lw_sod_fcat-col_pos = '6'.
  lw_sod_fcat-fieldname = 'TTEXT'.
  lw_sod_fcat-seltext_l = text-006.
  APPEND lw_sod_fcat TO gt_sod_fcat.
  CLEAR lw_sod_fcat.

  lw_sod_fcat-col_pos = '7'.
  lw_sod_fcat-fieldname = 'DEVCLASS'.
  lw_sod_fcat-seltext_l = text-007.
  lw_sod_fcat-emphasize = 'C400'.
  APPEND lw_sod_fcat TO gt_sod_fcat.
  CLEAR lw_sod_fcat.


  lw_sod_fcat-col_pos = '8'.
  lw_sod_fcat-fieldname = 'CTEXT'.
  lw_sod_fcat-seltext_l = text-008.
  APPEND lw_sod_fcat TO gt_sod_fcat.
  CLEAR lw_sod_fcat.


  lw_sod_fcat-col_pos = '9'.
  lw_sod_fcat-fieldname = 'PS_POSID'.
  lw_sod_fcat-seltext_l = text-009.
  lw_sod_fcat-emphasize = 'C400'.
  APPEND lw_sod_fcat TO gt_sod_fcat.
  CLEAR lw_sod_fcat.

  lw_sod_fcat-col_pos = '10'.
  lw_sod_fcat-fieldname = 'NAME'.
  lw_sod_fcat-seltext_l = text-010.
  APPEND lw_sod_fcat TO gt_sod_fcat.
  CLEAR lw_sod_fcat.


***  *****  sod sort  *********


  lw_sod_sort-spos = '1'.
  lw_sod_sort-fieldname = 'VRSIO'.
  lw_sod_sort-tabname = 'GT_SOD_TCODES'.
  lw_sod_sort-up = 'X'.
  APPEND lw_sod_sort TO gt_sod_sort.
  CLEAR lw_sod_sort.

  lw_sod_sort-spos = '2'.
  lw_sod_sort-fieldname = 'FUNCTION'.
  lw_sod_sort-tabname = 'GT_SOD_TCODES'.
  lw_sod_sort-up = 'X'.
  APPEND lw_sod_sort TO gt_sod_sort.
  CLEAR lw_sod_sort.

  lw_sod_sort-spos = '3'.
  lw_sod_sort-fieldname = 'DESCRIPTION'.
  lw_sod_sort-tabname = 'GT_SOD_TCODES'.
  lw_sod_sort-up = 'X'.
  APPEND lw_sod_sort TO gt_sod_sort.
  CLEAR lw_sod_sort.

  lw_sod_sort-spos = '4'.
  lw_sod_sort-fieldname = 'BUSAREA'.
  lw_sod_sort-tabname = 'GT_SOD_TCODES'.
  lw_sod_sort-up = 'X'.
  APPEND lw_sod_sort TO gt_sod_sort.
  CLEAR lw_sod_sort.

  lw_sod_sort-spos = '5'.
  lw_sod_sort-fieldname = 'TCODE'.
  lw_sod_sort-tabname = 'GT_SOD_TCODES'.
  lw_sod_sort-up = 'X'.
  APPEND lw_sod_sort TO gt_sod_sort.
  CLEAR lw_sod_sort.

  lw_sod_sort-spos = '6'.
  lw_sod_sort-fieldname = 'TTEXT'.
  lw_sod_sort-tabname = 'GT_SOD_TCODES'.
  lw_sod_sort-up = 'X'.
  APPEND lw_sod_sort TO gt_sod_sort.
  CLEAR lw_sod_sort.

  lw_sod_sort-spos = '7'.
  lw_sod_sort-fieldname = 'DEVCLASS'.
  lw_sod_sort-tabname = 'GT_SOD_TCODES'.
  lw_sod_sort-up = 'X'.
  APPEND lw_sod_sort TO gt_sod_sort.
  CLEAR lw_sod_sort.

  lw_sod_sort-spos = '8'.
  lw_sod_sort-fieldname = 'CTEXT'.
  lw_sod_sort-tabname = 'GT_SOD_TCODES'.
  lw_sod_sort-up = 'X'.
  APPEND lw_sod_sort TO gt_sod_sort.
  CLEAR lw_sod_sort.

  lw_sod_sort-spos = '9'.
  lw_sod_sort-fieldname = 'PS_POSID'.
  lw_sod_sort-tabname = 'GT_SOD_TCODES'.
  lw_sod_sort-up = 'X'.
  APPEND lw_sod_sort TO gt_sod_sort.
  CLEAR lw_sod_sort.

  lw_sod_sort-spos = '10'.
  lw_sod_sort-fieldname = 'NAME'.
  lw_sod_sort-tabname = 'GT_SOD_TCODES'.
  lw_sod_sort-up = 'X'.
  APPEND lw_sod_sort TO gt_sod_sort.
  CLEAR lw_sod_sort.

ENDFORM.                    " sod_fill_fieldcat

*&---------------------------------------------------------------------*
*&      Form  fill_fieldcat
*&---------------------------------------------------------------------*
*       text  for nonsod field catalog
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM nonsod_fill_fieldcat.

  DATA: lw_nonsod_fcat TYPE slis_fieldcat_alv.
  DATA: lw_nonsod_sort TYPE slis_sortinfo_alv.

  REFRESH : gt_nonsod_fcat.

  lw_nonsod_fcat-col_pos = '1'.
  lw_nonsod_fcat-fieldname = 'TCODE'.
  lw_nonsod_fcat-hotspot = 'X'.
  lw_nonsod_fcat-emphasize = 'C400'.
  lw_nonsod_fcat-seltext_l = text-005.
  APPEND lw_nonsod_fcat TO gt_nonsod_fcat.
  CLEAR lw_nonsod_fcat.

  lw_nonsod_fcat-col_pos = '2'.
  lw_nonsod_fcat-fieldname = 'TTEXT'.
  lw_nonsod_fcat-seltext_l = text-006.
  APPEND lw_nonsod_fcat TO gt_nonsod_fcat.
  CLEAR lw_nonsod_fcat.

  lw_nonsod_fcat-col_pos = '3'.
  lw_nonsod_fcat-fieldname = 'DEVCLASS'.
  lw_nonsod_fcat-seltext_l = text-007.
  lw_nonsod_fcat-emphasize = 'C400'.
  APPEND lw_nonsod_fcat TO gt_nonsod_fcat.
  CLEAR lw_nonsod_fcat.


  lw_nonsod_fcat-col_pos = '4'.
  lw_nonsod_fcat-fieldname = 'CTEXT'.
  lw_nonsod_fcat-seltext_l = text-008.
  APPEND lw_nonsod_fcat TO gt_nonsod_fcat.
  CLEAR lw_nonsod_fcat.


  lw_nonsod_fcat-col_pos = '5'.
  lw_nonsod_fcat-fieldname = 'PS_POSID'.
  lw_nonsod_fcat-seltext_l = text-009.
  lw_nonsod_fcat-emphasize = 'C400'.
  APPEND lw_nonsod_fcat TO gt_nonsod_fcat.
  CLEAR lw_nonsod_fcat.

  lw_nonsod_fcat-col_pos = '6'.
  lw_nonsod_fcat-fieldname = 'NAME'.
  lw_nonsod_fcat-seltext_l = text-010.
  APPEND lw_nonsod_fcat TO gt_nonsod_fcat.
  CLEAR lw_nonsod_fcat.


***  *****    sort  *********

  lw_nonsod_sort-spos = '1'.
  lw_nonsod_sort-fieldname = 'TCODE'.
  lw_nonsod_sort-tabname = 'GT_NONSOD_TCODES'.
  lw_nonsod_sort-up = 'X'.
  APPEND lw_nonsod_sort TO gt_nonsod_sort.
  CLEAR lw_nonsod_sort.

  lw_nonsod_sort-spos = '2'.
  lw_nonsod_sort-fieldname = 'TTEXT'.
  lw_nonsod_sort-tabname = 'GT_NONSOD_TCODES'.
  lw_nonsod_sort-up = 'X'.
  APPEND lw_nonsod_sort TO gt_nonsod_sort.
  CLEAR lw_nonsod_sort.

  lw_nonsod_sort-spos = '3'.
  lw_nonsod_sort-fieldname = 'DEVCLASS'.
  lw_nonsod_sort-tabname = 'GT_NONSOD_TCODES'.
  lw_nonsod_sort-up = 'X'.
  APPEND lw_nonsod_sort TO gt_nonsod_sort.
  CLEAR lw_nonsod_sort.

  lw_nonsod_sort-spos = '4'.
  lw_nonsod_sort-fieldname = 'CTEXT'.
  lw_nonsod_sort-tabname = 'GT_NONSOD_TCODES'.
  lw_nonsod_sort-up = 'X'.
  APPEND lw_nonsod_sort TO gt_nonsod_sort.
  CLEAR lw_nonsod_sort.

  lw_nonsod_sort-spos = '5'.
  lw_nonsod_sort-fieldname = 'PS_POSID'.
  lw_nonsod_sort-tabname = 'GT_NONSOD_TCODES'.
  lw_nonsod_sort-up = 'X'.
  APPEND lw_nonsod_sort TO gt_nonsod_sort.
  CLEAR lw_nonsod_sort.

  lw_nonsod_sort-spos = '6'.
  lw_nonsod_sort-fieldname = 'NAME'.
  lw_nonsod_sort-tabname = 'GT_NONSOD_TCODES'.
  lw_nonsod_sort-up = 'X'.
  APPEND lw_nonsod_sort TO gt_nonsod_sort.
  CLEAR lw_nonsod_sort.

ENDFORM.                    " nonsod_fill_fieldcat1



*&---------------------------------------------------------------------*
*&      Form  USER_DOUBLE_CLICK_ON_DETL for both SOD and NONSOD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM user_double_click_on_detl USING r_ucomm LIKE sy-ucomm
                                 rs_selfield TYPE slis_selfield.
  DATA : l_answer,l_ttext(80).
*  CASE r_ucomm.
*    WHEN 'DOWNLOAD'.
**   ALV  Output details in XL Format for SOD and NONSOD
*      PERFORM get_download.
*      CLEAR: rs_selfield-fieldname.
*  ENDCASE.

  CASE rs_selfield-fieldname.
    WHEN 'TCODE'.
      CHECK rs_selfield-value <> '*'."only for real tcodes
      SELECT ttext FROM tstct INTO l_ttext
            WHERE sprsl = sy-langu AND tcode = rs_selfield-value.
        EXIT.
      ENDSELECT.
      CLEAR l_answer.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
           EXPORTING
                titlebar              = rs_selfield-value
                text_question         = l_ttext
                text_button_1         = 'Execute'(017)
                icon_button_1         = 'ICON_EXECUTE_OBJECT'
                text_button_2         = 'Cancel'(029)
                icon_button_2         = 'ICON_SYSTEM_CANCEL'
                default_button        = '2'
                display_cancel_button = ' '
           IMPORTING
                answer                = l_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024.
       EXCEPTIONS
          TEXT_NOT_FOUND = 1
          OTHERS = 2.
IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

"(++)EOC UMITTAL SE VF scan-25/11/2024.

      CHECK l_answer = '1'.

      AUTHORITY-CHECK OBJECT 'S_TCODE'
               ID 'TCD' FIELD rs_selfield-value.
      IF sy-subrc = 0.
*check if transaction exists
        SELECT SINGLE tcode FROM tstc INTO rs_selfield-value
          WHERE tcode = rs_selfield-value ."#EC SAST_CI_GEN_CHECK
        IF sy-subrc = 0.
          CALL TRANSACTION rs_selfield-value."#EC PATHLOCK_CI_DYN_ACCES
        ELSE.
          MESSAGE s398(00) WITH 'Transaction does not exist.'(030).
        ENDIF.
      ELSE.
        MESSAGE s398(00) WITH 'Not authorized to run transaction'(031).
      ENDIF.

      CLEAR: rs_selfield-fieldname.
  ENDCASE.


ENDFORM.                           "USER_DOUBLE_CLICK_ON_DETL

*---------------------------------------------------------------------*
*    SOD_TOP_OF_PAGE                                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*

FORM  sod_top_of_page.
  DATA: l_sod_header TYPE slis_t_listheader,
        l_wa TYPE slis_listheader,
        l_exedate(10).

*TITLE AREA
  l_wa-typ = 'H'(018).
  l_wa-info = text-019.
  APPEND l_wa TO l_sod_header.

*BELOW AREA.
  l_wa-typ = 'S'(020).
  l_wa-key = 'User & Date:'(021).
  CONCATENATE sy-datum+4(2) '/' sy-datum+6(2) '/' sy-datum(4)
              INTO l_exedate.
*  CONCATENATE sy-uname 'on'(022) l_exedate "C0700
  CONCATENATE g_current_user 'on'(022) l_exedate "C0700
              INTO l_wa-info SEPARATED BY space.
  APPEND l_wa TO l_sod_header.


******************************************

  IF NOT sodvrsio IS INITIAL.
    l_wa-typ = 'S'(020).
    l_wa-key = text-034 .
    l_wa-info = sodvrsio.
    APPEND l_wa TO l_sod_header.
  ENDIF.

*****************************************

  IF NOT  s_funid-low IS INITIAL.
    IF NOT  s_funid-high IS INITIAL.
      l_wa-typ = 'S'(020).
      l_wa-key = text-024.  .
      CONCATENATE text-025  s_funid-low text-026  s_funid-high
                     INTO l_wa-info SEPARATED BY space.
      APPEND l_wa TO l_sod_header.
    ENDIF.
  ENDIF.

  IF NOT s_funid-low IS INITIAL.
    IF s_funid-high IS INITIAL.
      l_wa-typ = 'S'(020).
      l_wa-key = text-024 .
      l_wa-info =  s_funid-low.
      APPEND l_wa TO l_sod_header.
    ENDIF.
  ENDIF.

  IF NOT  s_funid-high IS INITIAL.
    IF s_funid-low IS INITIAL.
      l_wa-typ = 'S'(020).
      l_wa-key = text-024 .
      l_wa-info =  s_funid-high.
      APPEND l_wa TO l_sod_header.
    ENDIF.
  ENDIF.
*****************************************


  IF NOT s_tcode-low IS INITIAL.
    IF NOT s_tcode-high IS INITIAL.
      l_wa-typ = 'S'(020).
      l_wa-key = text-027.  .
      CONCATENATE text-025 s_tcode-low text-026 s_tcode-high
                     INTO l_wa-info SEPARATED BY space.
      APPEND l_wa TO l_sod_header.
    ENDIF.
  ENDIF.

  IF NOT s_tcode-low IS INITIAL.
    IF  s_tcode-high IS INITIAL.
      l_wa-typ = 'S'(020).
      l_wa-key = text-027 .
      l_wa-info = s_tcode-low.
      APPEND l_wa TO l_sod_header.
    ENDIF.
  ENDIF.

  IF NOT s_tcode-high IS INITIAL.
    IF  s_tcode-low IS INITIAL.
      l_wa-typ = 'S'(020).
      l_wa-key = text-027 .
      l_wa-info = s_tcode-high.
      APPEND l_wa TO l_sod_header.
    ENDIF.
  ENDIF.
*****************************************

  IF NOT s_dev-low IS INITIAL.
    IF NOT s_dev-high IS INITIAL.
      l_wa-typ = 'S'(020).
      l_wa-key = text-028.
      CONCATENATE text-025 s_dev-low text-026 s_dev-high
                     INTO l_wa-info SEPARATED BY space.
      APPEND l_wa TO l_sod_header.
    ENDIF.
  ENDIF.

  IF NOT s_dev-low IS INITIAL.
    IF s_dev-high IS INITIAL.
      l_wa-typ = 'S'(020).
      l_wa-key = text-028 .
      l_wa-info = s_dev-low.
      APPEND l_wa TO l_sod_header.
    ENDIF.
  ENDIF.

  IF NOT s_dev-high IS INITIAL.
    IF s_dev-low IS INITIAL.
      l_wa-typ = 'S'(020).
      l_wa-key = text-028 .
      l_wa-info = s_dev-high.
      APPEND l_wa TO l_sod_header.
    ENDIF.
  ENDIF.
*******************************************

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = l_sod_header
            i_logo             = 'Z_3SW_LOGO_JPG'.


ENDFORM.                               "SOD_TOP_OF_PAGE

*---------------------------------------------------------------------*
*  NONSOD_TOP_OF_PAGE                                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*

FORM nonsod_top_of_page .
  DATA: l_nonsod_header TYPE slis_t_listheader,
        l_wa TYPE slis_listheader,
        l_exedate(10).

*TITLE AREA
  l_wa-typ = 'H'(018).
  l_wa-info = text-042.
  APPEND l_wa TO l_nonsod_header.

*BELOW AREA.
  l_wa-typ = 'S'(020).
  l_wa-key = 'User & Date:'(021).
  CONCATENATE sy-datum+4(2) '/' sy-datum+6(2) '/' sy-datum(4)
              INTO l_exedate.
*  CONCATENATE sy-uname 'on'(022) l_exedate
  CONCATENATE g_current_user 'on'(022) l_exedate "C0700
              INTO l_wa-info SEPARATED BY space.
  APPEND l_wa TO l_nonsod_header.


******************************************

  IF NOT s_tcode-low IS INITIAL.
    IF NOT s_tcode-high IS INITIAL.
      l_wa-typ = 'S'(020).
      l_wa-key = text-027.  .
      CONCATENATE text-025 s_tcode-low text-026 s_tcode-high
                     INTO l_wa-info SEPARATED BY space.
      APPEND l_wa TO l_nonsod_header.
    ENDIF.
  ENDIF.

  IF NOT s_tcode-low IS INITIAL.
    IF  s_tcode-high IS INITIAL.
      l_wa-typ = 'S'(020).
      l_wa-key = text-027 .
      l_wa-info = s_tcode-low.
      APPEND l_wa TO l_nonsod_header.
    ENDIF.
  ENDIF.

  IF NOT s_tcode-high IS INITIAL.
    IF  s_tcode-low IS INITIAL.
      l_wa-typ = 'S'(020).
      l_wa-key = text-027 .
      l_wa-info = s_tcode-high.
      APPEND l_wa TO l_nonsod_header.
    ENDIF.
  ENDIF.
*****************************************

  IF NOT s_dev-low IS INITIAL.
    IF NOT s_dev-high IS INITIAL.
      l_wa-typ = 'S'(020).
      l_wa-key = text-028.
      CONCATENATE text-025 s_dev-low text-026 s_dev-high
                     INTO l_wa-info SEPARATED BY space.
      APPEND l_wa TO l_nonsod_header.
    ENDIF.
  ENDIF.

  IF NOT s_dev-low IS INITIAL.
    IF s_dev-high IS INITIAL.
      l_wa-typ = 'S'(020).
      l_wa-key = text-028 .
      l_wa-info = s_dev-low.
      APPEND l_wa TO l_nonsod_header.
    ENDIF.
  ENDIF.

  IF NOT s_dev-high IS INITIAL.
    IF s_dev-low IS INITIAL.
      l_wa-typ = 'S'(020).
      l_wa-key = text-028 .
      l_wa-info = s_dev-high.
      APPEND l_wa TO l_nonsod_header.
    ENDIF.
  ENDIF.
*******************************************

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = l_nonsod_header
            i_logo             = 'Z_3SW_LOGO_JPG'.


ENDFORM.                           "NONSOD_TOP_OF_PAGE


**&---------------------------------------------------------------------
**
**&      Form  set_pf_status  for program /PSYNG/SW_103
**&---------------------------------------------------------------------
**
**----------------------------------------------------------------------
*
FORM set_pf_status USING rt_extab TYPE slis_t_extab.
  SET PF-STATUS 'STANDARD' EXCLUDING rt_extab.
ENDFORM.                                      "SET_PF_STATUS
*
*&---------------------------------------------------------------------*
*&      Form  display_sod_std_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_sod_std_output.

  .
** specific sod tcodes

  WRITE:/ .
  SORT gt_sod_tcodes BY tcode.
  LOOP AT gt_sod_tcodes INTO g_wa_sod_tcodes.
    WRITE:/     g_wa_sod_tcodes-vrsio,
            15  g_wa_sod_tcodes-function,
            32  g_wa_sod_tcodes-description,
            65  g_wa_sod_tcodes-busarea,
            89  g_wa_sod_tcodes-tcode,
           115  g_wa_sod_tcodes-ttext,
           155  g_wa_sod_tcodes-devclass,
           175  g_wa_sod_tcodes-ctext,
           220  g_wa_sod_tcodes-ps_posid,
           235  g_wa_sod_tcodes-name.

  ENDLOOP.


ENDFORM.                    " display_sod_std_output

*&---------------------------------------------------------------------*
*&      Form  display_nonsod_std_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_nonsod_std_output.


** specific nonsod tcodes

  WRITE:/ .
  SORT gt_nonsod_tcodes BY tcode.
  LOOP AT gt_nonsod_tcodes INTO g_wa_nonsod_tcodes.
    WRITE:/     g_wa_nonsod_tcodes-tcode,
           45   g_wa_nonsod_tcodes-ttext,
           83   g_wa_nonsod_tcodes-devclass,
           105  g_wa_nonsod_tcodes-ctext,
           155  g_wa_nonsod_tcodes-ps_posid,
           175  g_wa_nonsod_tcodes-name.

  ENDLOOP.

ENDFORM.                    " display_nonsod_std_output
*&---------------------------------------------------------------------*
*       text background job with varient
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM schedule_back_job.
  DATA: curr_report LIKE rsvar-report.


  CLEAR: curr_report, curr_variant.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab.
  curr_report = sy-repid.
  curr_variant = variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
       EXPORTING
            curr_report   = curr_report
            curr_variant  = curr_variant
            vari_desc     = vari_desc
       TABLES
            vari_contents = vari_contents
            vari_text     = vari_text
"(++)BOC UMITTAL SE VF scan-25/11/2024.
       EXCEPTIONS
          ILLEGAL_REPORT_OR_VARIANT = 1
          ILLEGAL_VARIANTNAME = 2
          NOT_AUTHORIZED = 3
          NOT_EXECUTED = 4
          REPORT_NOT_EXISTENT = 5
          REPORT_NOT_SUPPLIED = 6
          VARIANT_EXISTS = 7
          VARIANT_LOCKED = 8
          OTHERS = 9.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
*****SOD TCodes Tie UP with SAP
    CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
         EXPORTING
              in_jobname  = text-t12
              in_repvarnt = curr_variant
              in_report   = curr_report.
    IF sy-subrc <> 0.
      CALL SCREEN 1000.
    ENDIF.
  ENDIF.

ENDFORM.                    " schedule_back_job
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text background job with new varient
*----------------------------------------------------------------------*
FORM get_next_variant_id.
  DATA: oldnumber(7) TYPE n, oldnumber_c(7).

  CLEAR: variant, vari_desc.
  REFRESH: vari_desc.

  SELECT variant INTO variant FROM varid WHERE report = sy-repid AND
                           variant LIKE '/PSYNG/%'
    order by variant DESCENDING.
    oldnumber = variant+7(7).
    exit.
  ENDSELECT.
  IF sy-subrc NE 0.
    variant = '/PSYNG/0000000'.
  ELSE.
    oldnumber = oldnumber + 1.
    MOVE oldnumber TO oldnumber_c.
    CONCATENATE '/PSYNG/' oldnumber_c INTO variant.
  ENDIF.

  vari_desc-report = sy-repid.
  vari_desc-variant = variant.
  APPEND vari_desc.

ENDFORM.                    " get_next_variant_id
*&---------------------------------------------------------------------*
*&      Form  fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*       text filling all selection screen items
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab.

  REFRESH : gt_rsparams.
*Select options

  LOOP AT s_funid.
    gt_rsparams-selname = 'S_FUNID'.
    gt_rsparams-kind = 'S'.
    MOVE-CORRESPONDING s_funid TO gt_rsparams.
    APPEND gt_rsparams.
  ENDLOOP.

  LOOP AT s_tcode.
    gt_rsparams-selname = 'S_TCODE'.
    gt_rsparams-kind = 'S'.
    MOVE-CORRESPONDING s_tcode TO gt_rsparams.
    APPEND gt_rsparams.
  ENDLOOP.

  LOOP AT s_dev.
    gt_rsparams-selname = 'S_DEV'.
    gt_rsparams-kind = 'S'.
    MOVE-CORRESPONDING s_dev TO gt_rsparams.
    APPEND gt_rsparams.
  ENDLOOP.

* **************************************
*Parameters
  gt_rsparams-selname = 'SODVRSIO'.
  gt_rsparams-kind = 'P'.
  gt_rsparams-sign = 'I'.
  gt_rsparams-option = 'EQ'.
  gt_rsparams-low = sodvrsio.
  APPEND gt_rsparams.

  gt_rsparams-selname = 'SOD'.
  gt_rsparams-kind = 'P'.
  gt_rsparams-sign = 'I'.
  gt_rsparams-option = 'EQ'.
  gt_rsparams-low = sod.
  APPEND gt_rsparams.

  gt_rsparams-selname = 'NONSOD'.
  gt_rsparams-kind = 'P'.
  gt_rsparams-sign = 'I'.
  gt_rsparams-option = 'EQ'.
  gt_rsparams-low = nonsod.
  APPEND gt_rsparams.

  gt_rsparams-selname = 'ALV'.
  gt_rsparams-kind = 'P'.
  gt_rsparams-sign = 'I'.
  gt_rsparams-option = 'EQ'.
  gt_rsparams-low = alv.
  APPEND gt_rsparams.

  gt_rsparams-selname = 'STD'.
  gt_rsparams-kind = 'P'.
  gt_rsparams-sign = 'I'.
  gt_rsparams-option = 'EQ'.
  gt_rsparams-low = std.
  APPEND gt_rsparams.

ENDFORM.                    " fill_sel_screen_fields_to_tab
