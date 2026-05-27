REPORT /psyng/cffuncthist_to_alv NO STANDARD PAGE HEADING.
*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/CFFUNCTHIST
* AUTHOR                : Principal Synergy LLC
* RELEASE               : 1.0
* DATE OF RELEASE       : 10/19/2004
* TRANSPORT REQUEST #   :
*----------------------------------------------------------------------*
* COPYRIGHTS Principal Synergy LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*
*----------------------------------------------------------------------*

TABLES: /psyng/conflict.

*Define type pool
TYPE-POOLS: slis. "Define Type-Pool

*Define selection screen.
SELECTION-SCREEN BEGIN OF BLOCK sel WITH FRAME TITLE text-001.
SELECT-OPTIONS: conid FOR /psyng/conflict-conid.
PARAMETERS: sodvrsio LIKE /psyng/conflict-vrsio OBLIGATORY.
SELECT-OPTIONS: date FOR sy-datum.
SELECT-OPTIONS: time FOR sy-uzeit.
SELECT-OPTIONS: user FOR sy-uname.
SELECTION-SCREEN END OF BLOCK sel.

*Define Internal Tables
DATA: BEGIN OF gt_con_his OCCURS 0,
      oldval LIKE /psyng/history-oldval,
      status LIKE /psyng/history-status,
      create_usr LIKE /psyng/history-create_usr,
      create_dat LIKE /psyng/history-create_dat,
      create_tim LIKE /psyng/history-create_tim,
      sodvrsio LIKE /psyng/conflict-vrsio,
      END OF gt_con_his.

DATA: BEGIN OF gt_fun_his OCCURS 0,
      hdrfld LIKE /psyng/history-hdrfld,
      oldval LIKE /psyng/history-oldval,
      newval LIKE /psyng/history-newval,
      status LIKE /psyng/history-status,
      create_usr LIKE /psyng/history-create_usr,
      create_dat LIKE /psyng/history-create_dat,
      create_tim LIKE /psyng/history-create_tim,
      END OF gt_fun_his.

DATA: BEGIN OF gt_fin_his OCCURS 0,
      oldval LIKE /psyng/history-oldval,
      status(10) ,
      create_usr LIKE /psyng/history-create_usr,
      name_text LIKE /psyng/bc_uidn-name_text,
      create_dat LIKE /psyng/history-create_dat,
      create_tim LIKE /psyng/history-create_tim,
      funid LIKE /psyng/history-oldval,
      status_f(10),
      create_usr_f LIKE /psyng/history-create_usr,
      name_text1 LIKE /psyng/bc_uidn-name_text,
      create_dat_f LIKE /psyng/history-create_dat,
      create_tim_f LIKE /psyng/history-create_tim,
      sodvrsio(3) , "LIKE /PSYNG/CONFLICT-VRSIO,
      END OF gt_fin_his.

DATA: gt_user_info TYPE TABLE OF /psyng/bc_uidn WITH HEADER LINE.

*Define fieldcatalog
DATA: t_fieldcat TYPE slis_t_fieldcat_alv,   "Fieldcatalog
      l_sort TYPE slis_t_sortinfo_alv.


************************************************************************
*   DECLARATION F1 HELP FOR SELECTION SCREEN FIELDS
************************************************************************
* For field Function ID
AT SELECTION-SCREEN ON HELP-REQUEST FOR conid.

  PERFORM show_help USING '/PSYNG/CFFUNCTHIST_CONID'.

* For field Change Date
AT SELECTION-SCREEN ON HELP-REQUEST FOR date.


  PERFORM show_help USING '/PSYNG/SW_076_CHANGE_DAT'.


* For field Change Time
AT SELECTION-SCREEN ON HELP-REQUEST FOR time.

  PERFORM show_help USING '/PSYNG/SW_076_CHANGE_TIM'.


* For Change User
AT SELECTION-SCREEN ON HELP-REQUEST FOR user.

  PERFORM show_help USING '/PSYNG/SW_076_CHANGE_USR'.




*Start of Selection
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
  PERFORM build_fieldcat.
  PERFORM sort_info.
  PERFORM out_put.


*&---------------------------------------------------------------------*
*&      Form  show_help
*&---------------------------------------------------------------------*
*       Show f1 help for fields
*----------------------------------------------------------------------*
*      -->I_DOKNAME  Document name
*----------------------------------------------------------------------*
FORM show_help USING    i_dokname.

  CALL FUNCTION '/PSYNG/BASIS_F1_HELP'
       EXPORTING
            dokname = i_dokname.

ENDFORM.                    " show_help


*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*

FORM get_data.

  SELECT oldval
      status
      create_usr
      create_dat
      create_tim
      vrsio
      FROM /psyng/history
      INTO TABLE gt_con_his
      WHERE tabname = '/PSYNG/CONFLICT'
      AND oldval  IN conid
      AND create_dat IN date
      AND create_tim IN time
      AND create_usr IN user
      AND vrsio = sodvrsio.

  IF NOT gt_con_his[] IS INITIAL.

    SELECT hdrfld
           oldval
           newval
           status
           create_usr
           create_dat
           create_tim
           FROM /psyng/history
           INTO CORRESPONDING FIELDS OF TABLE gt_fun_his
           FOR ALL ENTRIES IN gt_con_his
           WHERE tabname = '/PSYNG/CONFDET'
           AND   hdrfld  = gt_con_his-oldval
           AND   create_dat = gt_con_his-create_dat
           AND   create_tim = gt_con_his-create_tim
           AND   create_usr = gt_con_his-create_usr
           AND   vrsio      = sodvrsio.
  ENDIF.

  CALL FUNCTION '/PSYNG/BC_011'
       TABLES
            it_bname = user
            et_uidn  = gt_user_info.

  LOOP AT gt_con_his.
   LOOP AT gt_fun_his WHERE hdrfld = gt_con_his-oldval AND create_dat =
       gt_con_his-create_dat AND create_tim = gt_con_his-create_tim AND
               create_usr = gt_con_his-create_usr.
      MOVE-CORRESPONDING gt_con_his TO gt_fin_his.
      READ TABLE gt_user_info WITH KEY bname = gt_con_his-create_usr.
      IF sy-subrc = 0.
        gt_fin_his-name_text = gt_user_info-name_text.
      ENDIF.
      READ TABLE gt_user_info WITH KEY bname =  gt_fun_his-create_usr.
      IF sy-subrc = 0.
        gt_fin_his-name_text1 = gt_user_info-name_text.
      ENDIF.
      IF gt_con_his-status = 'U'.
        gt_fin_his-status = text-006.
      ELSEIF gt_con_his-status = 'I'.
        gt_fin_his-status = text-007.
      ELSEIF gt_con_his-status = 'D'.
        gt_fin_his-status = text-008.
      ENDIF.
      gt_fin_his-funid = gt_fun_his-oldval.
      IF gt_fun_his-status = 'U'.
        gt_fin_his-status_f = text-006.
      ELSEIF gt_fun_his-status = 'I'.
        gt_fin_his-status_f = text-007.
      ELSEIF gt_fun_his-status = 'D'.
        gt_fin_his-status_f = text-008.
      ENDIF.

      gt_fin_his-create_usr_f = gt_fun_his-create_usr.
      gt_fin_his-create_dat_f = gt_fun_his-create_dat.
      gt_fin_his-create_tim_f = gt_fun_his-create_tim.
      APPEND gt_fin_his.
      CLEAR gt_fin_his.
    ENDLOOP.

    IF sy-subrc <> 0.
      CLEAR: gt_fin_his.
      MOVE-CORRESPONDING gt_con_his TO gt_fin_his.
      READ TABLE gt_user_info WITH KEY bname = gt_con_his-create_usr.
      IF sy-subrc = 0.
        gt_fin_his-name_text = gt_user_info-name_text.
      ENDIF.
      IF gt_con_his-status = 'U'.
        gt_fin_his-status = text-006.
      ELSEIF gt_con_his-status = 'I'.
        gt_fin_his-status = text-007.
      ELSEIF gt_con_his-status = 'D'.
        gt_fin_his-status = text-008.
      ENDIF.
      APPEND gt_fin_his.
      CLEAR gt_fin_his.

    ENDIF.

  ENDLOOP.

ENDFORM.                    " GET_DATA

*&---------------------------------------------------------------------*
*&      Form  BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*

FORM build_fieldcat.
  DATA: w_fieldcat TYPE slis_fieldcat_alv.     "Fieldcatalog Workarea

  REFRESH t_fieldcat[].
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'SODVRSIO'.
  w_fieldcat-tabname   = 'GT_FIN_HIS'.
  w_fieldcat-seltext_l = text-009.
  w_fieldcat-col_pos = 1.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'OLDVAL'.
  w_fieldcat-tabname   = 'GT_FIN_HIS'.
  w_fieldcat-seltext_l = text-010.
  w_fieldcat-col_pos = 2.
  w_fieldcat-emphasize = 'C400'.
  w_fieldcat-hotspot = 'X'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'STATUS'.
  w_fieldcat-tabname   = 'GT_FIN_HIS'.
  w_fieldcat-seltext_l = text-011.
  w_fieldcat-col_pos = 3.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_USR'.
  w_fieldcat-tabname   = 'GT_FIN_HIS'.
  w_fieldcat-seltext_l = text-012.
  w_fieldcat-col_pos = 4.
  w_fieldcat-emphasize = 'C400'.
  w_fieldcat-hotspot = 'X'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'NAME_TEXT'.
  w_fieldcat-tabname   = 'GT_FIN_HIS'.
  w_fieldcat-seltext_l = text-020.
  w_fieldcat-col_pos = 5.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_DAT'.
  w_fieldcat-tabname   = 'GT_FIN_HIS'.
  w_fieldcat-seltext_l = text-013.
  w_fieldcat-col_pos = 6.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_TIM'.
  w_fieldcat-tabname   = 'GT_FIN_HIS'.
  w_fieldcat-seltext_l = text-014.
  w_fieldcat-col_pos = 7.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'FUNID'.
  w_fieldcat-tabname   = 'GT_FIN_HIS'.
  w_fieldcat-seltext_l = text-015.
  w_fieldcat-col_pos = 8.
  w_fieldcat-hotspot = 'X'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'STATUS_F'.
  w_fieldcat-tabname   = 'GT_FIN_HIS'.
  w_fieldcat-seltext_l = text-016.
  w_fieldcat-col_pos = 9.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_USR_F'.
  w_fieldcat-tabname   = 'GT_FIN_HIS'.
  w_fieldcat-seltext_l = text-017.
  w_fieldcat-hotspot = 'X'.
  w_fieldcat-col_pos = 10.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'NAME_TEXT1'.
  w_fieldcat-tabname   = 'GT_FIN_HIS'.
  w_fieldcat-seltext_l = text-021.
  w_fieldcat-col_pos = 11.
  w_fieldcat-emphasize = 'C400'.
*  W_FIELDCAT-HOTSPOT = 'X'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.


  w_fieldcat-fieldname = 'CREATE_DAT_F'.
  w_fieldcat-tabname   = 'GT_FIN_HIS'.
  w_fieldcat-seltext_l = text-018.
  w_fieldcat-col_pos = 12.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_TIM_F'.
  w_fieldcat-tabname   = 'GT_FIN_HIS'.
  w_fieldcat-seltext_l = text-019.
  w_fieldcat-col_pos = 13.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

ENDFORM.                    " BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*&      Form  OUT_PUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM out_put.
  DATA: ls_layout  TYPE slis_layout_alv,         "ALV Layout
        l_program  LIKE sy-repid,
        ls_variant TYPE disvariant.

  l_program = sy-repid.
  ls_layout-zebra = 'X'.
  ls_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program       = l_program
            i_callback_pf_status_set = 'PF_STATUS'
            i_callback_user_command  = 'USER_COMMAND'
            is_layout                = ls_layout
            it_fieldcat              = t_fieldcat
            it_sort                  = l_sort
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = gt_fin_his[]
       EXCEPTIONS
            program_error            = 1
            OTHERS                   = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.


ENDFORM.                    " OUT_PUT
*&---------------------------------------------------------------------*
*&      Form  SORT_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM sort_info.
  DATA: w_sort TYPE slis_sortinfo_alv.

  w_sort-spos = '1'.
  w_sort-fieldname = 'SODVRSIO'.
  w_sort-tabname = 'GT_FIN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '2'.
  w_sort-fieldname = 'OLDVAL'.
  w_sort-tabname = 'GT_FIN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '3'.
  w_sort-fieldname = 'CREATE_DAT'.
  w_sort-tabname = 'GT_FIN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '4'.
  w_sort-fieldname = 'CREATE_TIM'.
  w_sort-tabname = 'GT_FIN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '5'.
  w_sort-fieldname = 'CREATE_USR'.
  w_sort-tabname = 'GT_FIN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '6'.
  w_sort-fieldname = 'NAME_TEXT'.
  w_sort-tabname = 'GT_FIN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '7'.
  w_sort-fieldname = 'STATUS'.
  w_sort-tabname = 'GT_FIN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.


  w_sort-spos = '8'.
  w_sort-fieldname = 'FUNID'.
  w_sort-tabname = 'GT_FIN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '9'.
  w_sort-fieldname = 'CREATE_DAT_F'.
  w_sort-tabname = 'GT_FIN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '10'.
  w_sort-fieldname = 'CREATE_TIM_F'.
  w_sort-tabname = 'GT_FIN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '11'.
  w_sort-fieldname = 'CREATE_USR_F'.
  w_sort-tabname = 'GT_FIN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '12'.
  w_sort-fieldname = 'NAME_TEXT1'.
  w_sort-tabname = 'GT_FIN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '13'.
  w_sort-fieldname = 'STATUS_F'.
  w_sort-tabname = 'GT_FIN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.


ENDFORM.                    " SORT_INFO

*---------------------------------------------------------------------*
*       FORM user_double_click                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM user_command USING r_ucomm LIKE sy-ucomm
                                 rs_selfield TYPE slis_selfield.
  DATA: l_line(80),
        l_conid TYPE /psyng/conflict_id.
  DATA: lt_conid LIKE STANDARD TABLE OF /psyng/confdet INITIAL SIZE 0
        WITH HEADER LINE.
  DATA: BEGIN OF it_tcode OCCURS 0,
        functionid LIKE /psyng/functtran-functionid,
        tcode LIKE /psyng/functtran-tcode,
        END OF it_tcode.
  DATA:lt_tcodes TYPE TABLE OF /psyng/range_tcode WITH HEADER LINE.
  DATA:wa_tcodes  LIKE /psyng/range_tcode.


  CASE rs_selfield-fieldname.
    WHEN 'FUNID'.
      CHECK rs_selfield-value <> space.
      SELECT SINGLE description FROM /psyng/function INTO l_line
                                  WHERE function = rs_selfield-value
                                  AND   vrsio    = sodvrsio.

      IF  l_line <> ' '.
        CONCATENATE rs_selfield-value '=' l_line INTO l_line
                    SEPARATED BY space.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
             EXPORTING
                  titlebar              = text-002
                  text_question         = l_line
                  text_button_1         = text-003
                  icon_button_1         = 'ICON_SYSTEM_OKAY'
                  text_button_2         = text-004
                  icon_button_2         = 'ICON_SYSTEM_CANCEL'
                  default_button        = '1'
                  display_cancel_button = ' '
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
            IF sy-subrc <> 0.
                MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
            ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      ELSE.
        MESSAGE i398(00) WITH text-005.
      ENDIF.

    WHEN 'CREATE_USR' OR 'CREATE_USR_F'.
      CHECK rs_selfield-value <> space.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU01'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SU01'.
      ELSE.
        SET PARAMETER ID 'XUS' FIELD rs_selfield-value.
        CALL TRANSACTION 'SU01'.
      ENDIF.

    WHEN 'OLDVAL'.
      MOVE rs_selfield-value TO l_conid.
      CHECK NOT l_conid IS INITIAL.

      SELECT *                "#EC CI_NOWHERE
      FROM /psyng/confdet
      INTO TABLE lt_conid
      WHERE conid = l_conid AND
      vrsio = sodvrsio.

      IF NOT lt_conid[] IS INITIAL .

        SELECT functionid tcode
        FROM /psyng/functtran
        INTO TABLE it_tcode
        FOR ALL ENTRIES IN lt_conid
        WHERE functionid = lt_conid-functionid
        AND vrsio = sodvrsio.
      ENDIF.
      LOOP AT it_tcode.
        wa_tcodes-sign = 'I'.
        wa_tcodes-option = 'EQ'.
        wa_tcodes-low =  it_tcode-tcode.
        APPEND wa_tcodes TO lt_tcodes.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_007'
           EXPORTING
                i_conid  = l_conid
                i_vrsio  = sodvrsio
           TABLES
                it_tcode = lt_tcodes.

  ENDCASE.




ENDFORM.           "user_double_click.

*&---------------------------------------------------------------------*
*&      Form  SW_PF_STATUS_Overall
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*

FORM pf_status USING lt_extab TYPE slis_t_extab.

  SET PF-STATUS 'FUN_HISTRY' EXCLUDING lt_extab.



ENDFORM.                    " SW_PF_STATUS_OVERALL
