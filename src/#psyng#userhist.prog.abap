REPORT /psyng/userhist NO STANDARD PAGE HEADING .
*----------------------------------------------------------------------
*
* PROGRAM               : /PSYNG/USERHIST
* AUTHOR                : Principal Synergy LLC
* RELEASE               : 1.0
* DATE OF RELEASE       : 10/19/2004
* TRANSPORT REQUEST #   :
*----------------------------------------------------------------------*
*
* COPYRIGHTS Principal Synergy LLC
*
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*
*----------------------------------------------------------------------*
TABLES: /psyng/history,usr02.


TYPE-POOLS: slis.

*Define internal tables.
DATA: BEGIN OF ty_history,
      hdrfld LIKE /psyng/history-hdrfld,
      name_text4 LIKE /psyng/bc_uidn-name_text,
      oldval LIKE /psyng/history-oldval,
      status(10),
      create_usr LIKE /psyng/history-create_usr,
      name_text LIKE /psyng/bc_uidn-name_text,
      create_dat LIKE /psyng/history-create_dat,
      create_tim LIKE /psyng/history-create_tim,
      oldval1 LIKE /psyng/history-oldval,
      newval1 LIKE /psyng/history-newval,
      status1(10),
      create_usr1 LIKE /psyng/history-create_usr,
      name_text1 LIKE /psyng/bc_uidn-name_text,
      create_dat1 LIKE /psyng/history-create_dat,
      create_tim1 LIKE /psyng/history-create_tim,
      oldval2 LIKE /psyng/history-oldval,
      newval2 LIKE /psyng/history-newval,
      status2(10),
      create_usr2 LIKE /psyng/history-create_usr,
      name_text2 LIKE /psyng/bc_uidn-name_text,
      create_dat2 LIKE /psyng/history-create_dat,
      create_tim2 LIKE /psyng/history-create_tim,
      oldval3 LIKE /psyng/history-oldval,
      status3(10),
      create_usr3 LIKE /psyng/history-create_usr,
      name_text3 LIKE /psyng/bc_uidn-name_text,
      create_dat3 LIKE /psyng/history-create_dat,
      create_tim3 LIKE /psyng/history-create_tim,

      END OF ty_history.

DATA: gt_history LIKE STANDARD TABLE OF ty_history WITH HEADER LINE
      INITIAL SIZE 0.
*Define fieldcatalog
DATA: t_fieldcat TYPE slis_t_fieldcat_alv,    "Field Catalog
      l_sort TYPE slis_t_sortinfo_alv.


SELECT-OPTIONS: wuser FOR usr02-bname.
SELECT-OPTIONS: date  FOR sy-datum,
                time  FOR sy-uzeit,
                user  FOR usr02-bname.

*********************************************************
**F1 help for weaver user
AT SELECTION-SCREEN ON HELP-REQUEST FOR wuser.

  PERFORM show_help USING '/PSYNG/USERHIST_WUSER'.

***********************************************************
* **F1 help for Changed date

AT SELECTION-SCREEN ON HELP-REQUEST FOR date.

  PERFORM show_help USING '/PSYNG/USERHIST_DATE'.

**********************************************************
*  * **F1 help for Changed time
AT SELECTION-SCREEN ON HELP-REQUEST FOR time.

  PERFORM show_help USING '/PSYNG/USERHIST_TIME'.

**********************************************************
*  * **F1 help for Changed by which user

AT SELECTION-SCREEN ON HELP-REQUEST FOR  user.

  PERFORM show_help USING '/PSYNG/USERHIST_USER'.

**********************************************************


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

  PERFORM get_history.
  PERFORM build_fieldcat.
  PERFORM build_sort.
  PERFORM display_alv_output.


**&---------------------------------------------------------------------
**
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
*&      Form  GET_HISTORY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_history.
  DATA: o1_psynghistory LIKE /psyng/history,
        o2_psynghistory LIKE /psyng/history,
        g_data_flag.

  DATA: lt_user_info TYPE TABLE OF /psyng/bc_uidn WITH HEADER LINE.


  SELECT * FROM /psyng/history
  WHERE tabname = '/PSYNG/USER'
  AND   hdrfld = 'USERID'
  AND   oldval  IN wuser
  AND   create_dat IN date
  AND   create_tim IN time
  AND   create_usr IN user.

    MOVE /psyng/history-oldval TO gt_history-oldval.
    IF /psyng/history-status = 'U'.
      gt_history-status = text-004.
    ELSEIF /psyng/history-status = 'I'.
      gt_history-status = text-005.
    ELSEIF /psyng/history-status = 'D'.
      gt_history-status = text-006.
    ENDIF.
    MOVE /psyng/history-create_usr TO gt_history-create_usr.
    MOVE /psyng/history-create_dat TO gt_history-create_dat.
    MOVE /psyng/history-create_tim TO gt_history-create_tim.
    CLEAR : g_data_flag,gt_history-oldval1,gt_history-newval1,
    gt_history-status1,gt_history-create_usr1,gt_history-create_dat1,
    gt_history-create_tim1,gt_history-oldval2,gt_history-newval2,
       gt_history-status2,gt_history-create_usr2,gt_history-create_dat2,
       gt_history-create_tim2.

    SELECT SINGLE * FROM /psyng/history       "#EC CI_SEL_NESTED
       INTO o1_psynghistory
    WHERE tabname = '/PSYNG/USER'
    AND   hdrfld  = /psyng/history-oldval
    AND   dtlfld  = 'LOCATION'
    AND   create_dat = /psyng/history-create_dat
    AND   create_tim = /psyng/history-create_tim
    AND   create_usr = /psyng/history-create_usr .
    IF sy-subrc = 0.
      MOVE o1_psynghistory-oldval TO gt_history-oldval1.
      MOVE o1_psynghistory-newval TO gt_history-newval1.
      IF o1_psynghistory-status = 'U'.
        gt_history-status1 = text-004.
      ELSEIF o1_psynghistory-status = 'I'.
        gt_history-status1 = text-005.
      ELSEIF o1_psynghistory-status = 'D'.
        gt_history-status1 = text-006.
      ENDIF.

      MOVE o1_psynghistory-create_usr TO gt_history-create_usr1.
      MOVE o1_psynghistory-create_dat TO gt_history-create_dat1.
      MOVE o1_psynghistory-create_tim TO gt_history-create_tim1.
    ENDIF.
    SELECT SINGLE * FROM /psyng/history       "#EC CI_SEL_NESTED
    INTO o2_psynghistory
    WHERE tabname = '/PSYNG/USER'
    AND   hdrfld  = /psyng/history-oldval
    AND   dtlfld  = 'VALIDDTE'
    AND   create_dat = /psyng/history-create_dat
    AND   create_tim = /psyng/history-create_tim
    AND   create_usr = /psyng/history-create_usr .
    IF sy-subrc = 0.
      MOVE o2_psynghistory-oldval TO gt_history-oldval2.
      MOVE o2_psynghistory-newval TO gt_history-newval2.
      IF o2_psynghistory-status = 'U'.
        gt_history-status2 = text-004.
      ELSEIF o2_psynghistory-status = 'I'.
        gt_history-status2 = text-005.
      ELSEIF o2_psynghistory-status = 'D'.
        gt_history-status2 = text-006.
      ENDIF.

      MOVE o2_psynghistory-create_usr TO gt_history-create_usr2.
      MOVE o2_psynghistory-create_dat TO gt_history-create_dat2.
      MOVE o2_psynghistory-create_tim TO gt_history-create_tim2.

    ENDIF.

    CLEAR : g_data_flag.
    SELECT * FROM /psyng/history        "#EC CI_SEL_NESTED
    WHERE tabname = '/PSYNG/USRDET'
    AND   hdrfld  = /psyng/history-oldval
    AND   dtlfld  = 'POSITIONID'
    AND   create_dat = /psyng/history-create_dat
    AND   create_tim = /psyng/history-create_tim
    AND   create_usr = /psyng/history-create_usr.

      IF sy-subrc = 0.
        MOVE /psyng/history-oldval TO gt_history-oldval3.
        IF /psyng/history-status = 'U'.
          gt_history-status3 = text-004.
        ELSEIF /psyng/history-status = 'I'.
          gt_history-status3 = text-005.
        ELSEIF /psyng/history-status = 'D'.
          gt_history-status3 = text-006.
        ENDIF.

        MOVE /psyng/history-create_usr TO gt_history-create_usr3.
        MOVE /psyng/history-create_dat TO gt_history-create_dat3.
        MOVE /psyng/history-create_tim TO gt_history-create_tim3.
      ENDIF.
      INSERT TABLE gt_history.
      g_data_flag = 'X'.
      CLEAR: gt_history-oldval3,gt_history-status3,
      gt_history-create_usr3,gt_history-create_dat3,
      gt_history-create_tim3.

    ENDSELECT.
    IF g_data_flag = ' '.
      APPEND gt_history.
      CLEAR gt_history.
    ENDIF.

  ENDSELECT.

  CALL FUNCTION '/PSYNG/BC_011'
       TABLES
            it_bname = wuser
            et_uidn  = lt_user_info.

  LOOP AT gt_history.
    READ TABLE lt_user_info WITH KEY bname = gt_history-create_usr.
    IF sy-subrc = 0.
      gt_history-name_text = lt_user_info-name_text.
    ENDIF.

    READ TABLE lt_user_info WITH KEY bname = gt_history-create_usr1.
    IF sy-subrc = 0.
      gt_history-name_text1 = lt_user_info-name_text.
    ENDIF.


    READ TABLE lt_user_info WITH KEY bname = gt_history-create_usr2.
    IF sy-subrc = 0.
      gt_history-name_text2 = lt_user_info-name_text.
    ENDIF.
    READ TABLE lt_user_info WITH KEY bname = gt_history-create_usr3.
    IF sy-subrc = 0.
      gt_history-name_text3 = lt_user_info-name_text.
    ENDIF.
    MODIFY gt_history TRANSPORTING name_text name_text1 name_text2
    name_text3.

    READ TABLE lt_user_info WITH KEY bname = gt_history-oldval.
    IF sy-subrc = 0.
      gt_history-name_text4 = lt_user_info-name_text.
    ENDIF.
    MODIFY gt_history TRANSPORTING name_text name_text1 name_text2
    name_text3 name_text4.


  ENDLOOP.


ENDFORM.                    " GET_HISTORY
*&---------------------------------------------------------------------*
*&      Form  BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_fieldcat.
  DATA: w_fieldcat TYPE slis_fieldcat_alv.      "Field Catalog Workarea

  REFRESH t_fieldcat[].
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'OLDVAL'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-034.
  w_fieldcat-col_pos = 1.
  w_fieldcat-emphasize = 'C100'.
  w_fieldcat-hotspot = 'X'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'NAME_TEXT4'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-039.
  w_fieldcat-col_pos = 2.
  w_fieldcat-emphasize = 'C100'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'STATUS'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-009.
  w_fieldcat-col_pos = 3.
  w_fieldcat-emphasize = 'C100'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_USR'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-007.
  w_fieldcat-hotspot = 'X'.
  w_fieldcat-col_pos = 4.
  w_fieldcat-emphasize = 'C100'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'NAME_TEXT'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-035.
  w_fieldcat-col_pos = 5.
  w_fieldcat-emphasize = 'C100'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_DAT'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-011.
  w_fieldcat-col_pos = 6.
  w_fieldcat-emphasize = 'C100'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_TIM'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-012.
  w_fieldcat-col_pos = 7.
  w_fieldcat-emphasize = 'C100'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'OLDVAL1'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-013.
  w_fieldcat-col_pos = 8.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'NEWVAL1'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-014.
  w_fieldcat-col_pos = 9.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'STATUS1'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-015.
  w_fieldcat-col_pos = 10.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_USR1'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-016.
  w_fieldcat-hotspot = 'X'.
  w_fieldcat-col_pos = 11.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'NAME_TEXT1'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-036.
  w_fieldcat-col_pos = 12.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_DAT1'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-017.
  w_fieldcat-col_pos = 13.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_TIM1'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-018.
  w_fieldcat-col_pos = 14.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'OLDVAL2'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-019.
  w_fieldcat-col_pos = 15.
  w_fieldcat-emphasize = 'C500'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'NEWVAL2'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-020.
  w_fieldcat-col_pos = 16.
  w_fieldcat-emphasize = 'C500'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.


  w_fieldcat-fieldname = 'STATUS2'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-021.
  w_fieldcat-col_pos = 17.
  w_fieldcat-emphasize = 'C500'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_USR2'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-022.
  w_fieldcat-hotspot = 'X'.
  w_fieldcat-col_pos = 18.
  w_fieldcat-emphasize = 'C500'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'NAME_TEXT2'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-037.
  w_fieldcat-col_pos = 19.
  w_fieldcat-emphasize = 'C500'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_DAT2'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-023.
  w_fieldcat-col_pos = 20.
  w_fieldcat-emphasize = 'C500'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_TIM2'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-024.
  w_fieldcat-col_pos = 21.
  w_fieldcat-emphasize = 'C500'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.


  w_fieldcat-fieldname = 'OLDVAL3'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-025.
  w_fieldcat-hotspot = 'X'.
  w_fieldcat-col_pos = 22.
  w_fieldcat-emphasize = 'C200'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'STATUS3'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-026.
  w_fieldcat-col_pos = 23.
  w_fieldcat-emphasize = 'C200'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_USR3'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-027.
  w_fieldcat-hotspot = 'X'.
  w_fieldcat-col_pos = 24.
  w_fieldcat-emphasize = 'C200'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'NAME_TEXT3'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-038.
  w_fieldcat-col_pos = 25.
  w_fieldcat-emphasize = 'C200'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_DAT3'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-028.
  w_fieldcat-col_pos = 26.
  w_fieldcat-emphasize = 'C200'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_TIM3'.
  w_fieldcat-tabname   = 'GT_HISTORY'.
  w_fieldcat-seltext_l = text-029.
  w_fieldcat-col_pos = 27.
  w_fieldcat-emphasize = 'C200'.
  APPEND w_fieldcat TO t_fieldcat.
  CLEAR w_fieldcat.



ENDFORM.                    " BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV_OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM display_alv_output.
  DATA: ls_layout  TYPE slis_layout_alv,          "ALV Report Layout
        l_program  TYPE sy-repid,
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
            t_outtab                 = gt_history[]
       EXCEPTIONS
            program_error            = 1
            OTHERS                   = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.


ENDFORM.                    " DISPLAY_ALV_OUTPUT

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
  DATA: l_line(80).

  CASE rs_selfield-fieldname.
**  For position  ID **
    WHEN 'OLDVAL3'.
      CHECK rs_selfield-value <> space.
      SELECT SINGLE description FROM /psyng/position INTO l_line
                                  WHERE positionid = rs_selfield-value.
      IF  sy-subrc = 0.
        CONCATENATE rs_selfield-value '=' l_line INTO l_line
                    SEPARATED BY space.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
             EXPORTING
                  titlebar              = text-030
                  text_question         = l_line
                  text_button_1         = text-031
                  icon_button_1         = 'ICON_SYSTEM_OKAY'
                  text_button_2         = text-032
                  icon_button_2         = 'ICON_SYSTEM_CANCEL'
                  default_button        = '1'
                  display_cancel_button = ' '
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND  = 1
             OTHERS          = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      ELSE.
        MESSAGE i398(00) WITH text-033.
      ENDIF.
*********** For user id *********************
    WHEN 'OLDVAL' OR 'CREATE_USR' OR 'CREATE_USR1' OR 'CREATE_USR2' OR
       'CREATE_USR3'.
      CHECK rs_selfield-value <> space.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU01'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SU01'.
      ELSE.
        SET PARAMETER ID 'XUS' FIELD rs_selfield-value.
        CALL TRANSACTION 'SU01'.
      ENDIF.
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
*&---------------------------------------------------------------------*
*&      Form  BUILD_SORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_sort.
  DATA: w_sort TYPE slis_sortinfo_alv.

  w_sort-spos = '1'.
  w_sort-fieldname = 'OLDVAL'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '2'.
  w_sort-fieldname = 'NAME_TEXT4'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '3'.
  w_sort-fieldname = 'CREATE_DAT'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '4'.
  w_sort-fieldname = 'CREATE_TIM'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '5'.
  w_sort-fieldname = 'CREATE_USR'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '6'.
  w_sort-fieldname = 'NAME_TEXT'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '7'.
  w_sort-fieldname = 'STATUS'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.


  w_sort-spos = '8'.
  w_sort-fieldname = 'OLDVAL1'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '9'.
  w_sort-fieldname = 'CREATE_DAT1'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '10'.
  w_sort-fieldname = 'CREATE_TIM1'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '11'.
  w_sort-fieldname = 'CREATE_USR1'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '12'.
  w_sort-fieldname = 'NAME_TEXT1'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '13'.
  w_sort-fieldname = 'STATUS1'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '14'.
  w_sort-fieldname = 'OLDVAL2'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '15'.
  w_sort-fieldname = 'CREATE_DAT2'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '16'.
  w_sort-fieldname = 'CREATE_TIM2'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '17'.
  w_sort-fieldname = 'CREATE_USR2'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '18'.
  w_sort-fieldname = 'NAME_TEXT2'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '19'.
  w_sort-fieldname = 'STATUS2'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '20'.
  w_sort-fieldname = 'OLDVAL3'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '21'.
  w_sort-fieldname = 'CREATE_DAT3'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '22'.
  w_sort-fieldname = 'CREATE_TIM3'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '23'.
  w_sort-fieldname = 'CREATE_USR3'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '24'.
  w_sort-fieldname = 'NAME_TEXT3'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '25'.
  w_sort-fieldname = 'STATUS3'.
  w_sort-tabname = 'GT_TRAN_HIS'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.


ENDFORM.                    " BUILD_SORT
