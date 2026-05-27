*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_034
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*

REPORT /psyng/sw_034 .
INCLUDE /PSYNG/SW_CONFIG.
tables : /psyng/syscandt.
parameters : sodvrsio like /psyng/syscandt-vrsio.
DATA: BEGIN OF gt_opts OCCURS 1,
         c(80) TYPE c,
      END OF gt_opts.
DATA: BEGIN OF info OCCURS 1,
         persa LIKE /psyng/sw_uinfo-persa,
         critical type p,
         high TYPE p,
         medium TYPE p,
         low TYPE p,
       END OF info.

DATA: syscandt TYPE STANDARD TABLE OF /psyng/syscandt WITH HEADER LINE.
DATA: conflict TYPE HASHED TABLE OF /psyng/conflict
      WITH UNIQUE KEY conid WITH HEADER LINE.

DATA: records1 TYPE i.
DATA: sw_uinfo TYPE STANDARD TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
DATA: uinfo TYPE HASHED TABLE OF /psyng/sw_uinfo
      WITH UNIQUE KEY bname WITH HEADER LINE.
DATA: wa_uinfo TYPE /psyng/sw_uinfo,
      gf_reject TYPE /psyng/bapiflagx,
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx.
DATA: title(72).

INITIALIZATION.
  PERFORM exelog.
start-of-selection.
*BOC UMITTAL SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
*If the configuration setting SW_ENH_SCAN_TBL = Y,
* a popup is shown to decide which scan table to use for Graphs
data :  ls_tabname TYPE tabname,
        ls_config  TYPE /PSYNG/SWCONFIG,
        l_scantable_decision type flag.
constants : enh_tabname TYPE tabname value '/PSYNG/ENHSCANDT',
            sys_tabname TYPE tabname value '/PSYNG/SYSCANDT'.
se_config_param 'SW_ENH_SCAN_TBL' ls_config-value.
if  ls_config-value = 'Y'.
  CALL FUNCTION 'POPUP_TO_DECIDE'
    EXPORTING
      textline1               = 'Choose SOD-Matrix for Graphs'(014)
      text_option1            = 'Standard SOD-Matrix'(015)
      text_option2            = 'Enhanced SOD-Matrix'(016)
      titel                   = 'Choose SOD-Matrix for Graphs'(014)
      CANCEL_DISPLAY          = ' '
   IMPORTING
    ANSWER                    = l_scantable_decision.
  if l_scantable_decision = '2'.
    ls_tabname = enh_tabname.
  else.
    ls_tabname = sys_tabname.
  endif.
else.
  ls_tabname = sys_tabname.
endif.
*select data from appropriate scan table
CASE ls_tabname.
  WHEN '/PSYNG/ENHSCANDT'.
    SELECT * FROM /PSYNG/ENHSCANDT INTO TABLE syscandt  WHERE
       conid <> 'NONE'
       AND   vrsio =  sodvrsio.
  WHEN '/PSYNG/SYSCANDT'.
    SELECT * FROM /PSYNG/SYSCANDT INTO TABLE syscandt  WHERE
       conid <> 'NONE'
       AND   vrsio =  sodvrsio.

ENDCASE.
*SELECT * FROM (ls_tabname) INTO TABLE syscandt WHERE conid <> 'NONE'
*      and  vrsio = sodvrsio.

IF syscandt[] IS INITIAL.
  CALL FUNCTION 'POPUP_TO_INFORM'
       EXPORTING
            titel = 'No data available'(017)
            txt1  = ''
            txt2  = 'No data available'(017).

  LEAVE PROGRAM.
ENDIF.

SELECT conid imp FROM /psyng/conflict
       INTO CORRESPONDING FIELDS OF TABLE conflict
       where vrsio = sodvrsio.

data : lf_reject type flag.
  CALL FUNCTION '/PSYNG/SW_USER_INFO'
   EXPORTING
     VRSIO                    = sodvrsio
*     ENHANCED_SCANTABLE       = ''
     I_NAME_ONLY              = '' "for personel area we need this as ''
     I_MR_COMPANY             = 'X'
    TABLES
      sw_uinfo                 = sw_uinfo.
LOOP AT sw_uinfo.
  clear lf_reject.
  perform check_rpoug_auth using sw_uinfo sodvrsio
                           changing lf_reject.
    IF lf_reject = 'X'.
      DELETE sw_uinfo.
      gf_missing_auth_ugroup = 'X'.
    ENDIF.
ENDLOOP.



LOOP AT sw_uinfo INTO wa_uinfo.
  INSERT wa_uinfo INTO TABLE uinfo.
ENDLOOP.
CLEAR sw_uinfo.
FREE sw_uinfo.

LOOP AT syscandt.
  READ TABLE uinfo WITH TABLE KEY bname = syscandt-bname.
  CHECK sy-subrc = 0.

  CLEAR gf_reject.
  IF NOT gf_reject IS INITIAL.
    DELETE syscandt.
    DELETE uinfo WHERE bname = syscandt-bname.
    CONTINUE.
  ENDIF.

  IF uinfo-persa IS INITIAL.
    uinfo-persa = 'N/A'.
  ENDIF.
  READ TABLE info WITH KEY persa = uinfo-persa.
  IF sy-subrc = 0.
    READ TABLE conflict WITH TABLE KEY conid = syscandt-conid.
    CHECK sy-subrc = 0.
    CASE conflict-imp.
      WHEN 'HIGH'.
        info-high = info-high + 1.
        MODIFY info TRANSPORTING high WHERE persa = uinfo-persa.
      WHEN 'MEDIUM'.
        info-medium = info-medium + 1.
        MODIFY info TRANSPORTING medium WHERE persa = uinfo-persa.
      WHEN 'LOW'.
        info-low = info-low + 1.
        MODIFY info TRANSPORTING low WHERE persa = uinfo-persa.
      WHEN 'CRITICAL'.
        info-critical = info-critical + 1.
        MODIFY info TRANSPORTING critical WHERE persa = uinfo-persa.

      WHEN OTHERS.
    ENDCASE.
  ELSE.
    IF uinfo-persa IS INITIAL.
      info-persa = 'N/A'.
    ELSE.
      info-persa = uinfo-persa.
    ENDIF.
    READ TABLE conflict WITH TABLE KEY conid = syscandt-conid.
    CHECK sy-subrc = 0.
    CASE conflict-imp.
      WHEN 'CRITICAL'.
        info-critical =  1.
      WHEN 'HIGH'.
        info-high     =  1.
      WHEN 'MEDIUM'.
        info-medium   =  1.
      WHEN 'LOW'.
        info-low      =  1.
      WHEN OTHERS.
    ENDCASE.
    APPEND info.
  ENDIF.
ENDLOOP.

SORT info.

  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE i398(00) WITH text-004.
  ENDIF.

DESCRIBE TABLE info LINES records1.

IF records1 > 23.
  PERFORM split_data_in_multiple_graphs.
ELSE.
  gt_opts-c = 'FIFRST = 3D'.
*--Add version to title
  CONCATENATE 'Ver.'(t01)
              ' : '
              sodvrsio
              ' - '
              text-009
              INTO title SEPARATED BY space.

    CALL FUNCTION 'GRAPH_MATRIX_3D'
         EXPORTING
              col1       = text-i04
              col2       = text-i05
              col3       = text-i06
              col4       = text-i07
              dim1       = text-006
              dim2       = text-007
              mail_allow = 'X'
              titl       = title
              winszx     = '95'
              winszy     = '95'
         TABLES
              data       = info
              opts       = gt_opts.


ENDIF.
*&---------------------------------------------------------------------*
*&      Form  split_data_in_multiple_graphs
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM split_data_in_multiple_graphs.
  DATA: BEGIN OF info2 OCCURS 1,
           persa LIKE /psyng/sw_uinfo-persa,
           critical type p,
           high TYPE p,
           medium TYPE p,
           low TYPE p,
         END OF info2.
  DATA: title(72),
        records2 TYPE i.


  title = TEXT-012.

  CLEAR: records1, records2.
  LOOP AT info.
    MOVE-CORRESPONDING info TO info2.
    DELETE info.
    APPEND info2.
    DESCRIBE TABLE info LINES records1.
    DESCRIBE TABLE info2 LINES records2.
    IF ( records2 > 23 ) OR ( records1 = 0 ) .
 gt_opts-c = 'FIFRST = 3D'.
*--Add version to title
  CONCATENATE 'Ver.'(t01)
              ' : '
              sodvrsio
              ' - '
              title
              INTO title SEPARATED BY space.

    CALL FUNCTION 'GRAPH_MATRIX_3D'
         EXPORTING
              col1       = text-i04
              col2       = text-i05
              col3       = text-i06
              col4       = text-i07
              dim1       = text-006
              dim2       = text-007
              mail_allow = 'X'
              titl       = title
              winszx     = '95'
              winszy     = '95'
         TABLES
              data       = info2
              opts       = gt_opts.
      REFRESH: info2.
      title = TEXT-013.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " split_data_in_multiple_graphs

*&---------------------------------------------------------------------*
*&      Form  check_ugroup_auth
*&---------------------------------------------------------------------*
*       Check authority to user group
*----------------------------------------------------------------------*
*      -->I_CLASS   User Group
*      <--E_REJECT  Reject record?  X = Reject, Space = Keep
*----------------------------------------------------------------------*
FORM check_ugroup_auth USING    i_class TYPE usr02-class
                       CHANGING e_reject TYPE /psyng/bapiflagx.
ENDFORM.                    " check_ugroup_auth
*---------------------------------------------------------------------*
*       FORM check_rpoug_auth                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IS_UINFO                                                      *
*  -->  I_VRSIO                                                       *
*  -->  EF_REJECT                                                     *
*---------------------------------------------------------------------*
FORM check_rpoug_auth USING    is_uinfo TYPE /psyng/sw_uinfo
                               i_vrsio  TYPE /psyng/sodvrsio
                      CHANGING ef_reject TYPE flag.
  TYPES : BEGIN OF typ_rpoug ,
    vrsio TYPE /psyng/sodvrsio,
    class TYPE xuclass,
    company TYPE char20,
    rejected TYPE flag,
    END OF typ_rpoug.
  STATICS : lt_rpoug TYPE HASHED TABLE OF   typ_rpoug WITH UNIQUE KEY
   vrsio class company WITH HEADER LINE.

  READ TABLE lt_rpoug WITH TABLE KEY vrsio = i_vrsio
                                     class = is_uinfo-class
                                     company = is_uinfo-company.
  IF sy-subrc = 0.
    ef_reject =  lt_rpoug-rejected.
  ELSE.
     lt_rpoug-vrsio = i_vrsio.
     lt_rpoug-class = is_uinfo-class.
     lt_rpoug-company = is_uinfo-company.
    IF NOT is_uinfo-class IS INITIAL AND
       NOT is_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD is_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP'   FIELD is_uinfo-company.
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ELSEIF NOT is_uinfo-class IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD is_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ELSEIF NOT is_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP'   FIELD is_uinfo-company.
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ENDIF.
    ef_reject =  lt_rpoug-rejected.
    INSERT TABLE lt_rpoug.
  ENDIF.
  clear lt_rpoug.

ENDFORM.                    " check_rpoug_auth
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE,
        l_current_user TYPE sy-uname. "C0700
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 29.03.22 for C0700
  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = l_current_user. "sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.
  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = exelog.
  COMMIT WORK.
ENDFORM.                    " exelog
