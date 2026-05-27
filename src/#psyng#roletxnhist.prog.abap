REPORT /psyng/roletxnhist_to_alv NO STANDARD PAGE HEADING.
*----------------------------------------------------------------------
*
* PROGRAM               : /PSYNG/ROLETXNHIST
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
TABLES: /psyng/rolehdr,/psyng/history.

*Change code
TYPE-POOLS: slis. "Define Type-Pool


DATA: v_alv_fieldcat TYPE slis_t_fieldcat_alv,  "Field Catalog
      l_sort TYPE slis_t_sortinfo_alv.
*end


SELECT-OPTIONS: roleid FOR /psyng/rolehdr-roleid.
SELECT-OPTIONS: date FOR sy-datum,
                time FOR sy-uzeit,
                user FOR /psyng/history-create_usr.

*Define Internal Tables
DATA: BEGIN OF gt_hist OCCURS 0,
      oldval LIKE /psyng/history-oldval,
      status LIKE /psyng/history-status,
      create_usr LIKE /psyng/history-create_usr,
      create_dat LIKE /psyng/history-create_dat,
      create_tim LIKE /psyng/history-create_tim,
      END OF gt_hist,

      BEGIN OF gt_tran OCCURS 0,
      hdrfld LIKE /psyng/history-hdrfld,
      oldval LIKE /psyng/history-oldval,
      newval LIKE /psyng/history-newval,
      status LIKE /psyng/history-status,
      create_usr LIKE /psyng/history-create_usr,
      create_dat LIKE /psyng/history-create_dat,
      create_tim LIKE /psyng/history-create_tim,
      END OF gt_tran,

      BEGIN OF gt_role_tcd OCCURS 0,
      oldval LIKE /psyng/history-oldval,
      status(10),
      create_usr LIKE /psyng/history-create_usr,
      name_text LIKE /psyng/bc_uidn-name_text,
      create_dat LIKE /psyng/history-create_dat,
      create_tim LIKE /psyng/history-create_tim,
      tcode LIKE /psyng/history-oldval,
      status_t(10),
      create_usr_t LIKE /psyng/history-create_usr,
      name_text1 LIKE /psyng/bc_uidn-name_text,
      create_dat_t LIKE /psyng/history-create_dat,
      create_tim_t LIKE /psyng/history-create_tim,
      END OF gt_role_tcd.

************************************************************************
*   DECLARATION F1 HELP FOR SELECTION SCREEN FIELDS
************************************************************************
* For field Change Date
AT SELECTION-SCREEN ON HELP-REQUEST FOR date.

  PERFORM show_help USING '/PSYNG/SW_076_CHANGE_DAT'.

* For field Change Time
AT SELECTION-SCREEN ON HELP-REQUEST FOR time.

  PERFORM show_help USING '/PSYNG/SW_076_CHANGE_TIM'.

* For field Change User
AT SELECTION-SCREEN ON HELP-REQUEST FOR user.

  PERFORM show_help USING '/PSYNG/SW_076_CHANGE_USR'.


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
  PERFORM build_sort.
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
  DATA: lt_user_info TYPE TABLE OF /psyng/bc_uidn WITH HEADER LINE.


  SELECT
         oldval
         status
         create_usr
         create_dat
         create_tim
         FROM /psyng/history INTO TABLE gt_hist
         WHERE tabname = '/PSYNG/ROLEHDR'
          AND   hdrfld  = 'RLETXN'
          AND   oldval  IN roleid
          AND   create_dat IN date
          AND   create_tim IN time
          AND   create_usr IN user.


  IF NOT gt_hist[] IS INITIAL.

    SELECT hdrfld
           oldval
           newval
           status
           create_usr
           create_dat
           create_tim
         FROM /psyng/history INTO CORRESPONDING FIELDS OF TABLE gt_tran
            FOR ALL ENTRIES IN gt_hist
            WHERE tabname = '/PSYNG/ROLETRANS'
                AND   hdrfld  = gt_hist-oldval
                AND   create_dat = gt_hist-create_dat
                AND   create_tim = gt_hist-create_tim
                AND   create_usr = gt_hist-create_usr.

  ENDIF.

  CALL FUNCTION '/PSYNG/BC_011'
       TABLES
            it_bname = user
            et_uidn  = lt_user_info.

  LOOP AT gt_hist.
    LOOP AT gt_tran WHERE hdrfld = gt_hist-oldval AND create_dat =
    gt_hist-create_dat AND create_tim = gt_hist-create_tim AND
    create_usr = gt_hist-create_usr.
      MOVE-CORRESPONDING gt_hist TO gt_role_tcd.

      READ TABLE lt_user_info WITH KEY bname = gt_hist-create_usr.
      IF sy-subrc = 0.
        gt_role_tcd-name_text = lt_user_info-name_text.
      ENDIF.
      READ TABLE lt_user_info WITH KEY bname =  gt_tran-create_usr.
      IF sy-subrc = 0.
        gt_role_tcd-name_text1 = lt_user_info-name_text.
      ENDIF.

      IF gt_hist-status = 'U'.
        gt_role_tcd-status = text-001.
      ELSEIF gt_hist-status = 'I'.
        gt_role_tcd-status = text-002.
      ELSEIF gt_hist-status = 'D'.
        gt_role_tcd-status = text-003.
      ENDIF.
      gt_role_tcd-tcode = gt_tran-oldval.
      IF gt_tran-status = 'U'.
        gt_role_tcd-status_t = text-001.
      ELSEIF gt_tran-status = 'I'.
        gt_role_tcd-status_t = text-002.
      ELSEIF gt_tran-status = 'D'.
        gt_role_tcd-status_t = text-003.
      ENDIF.
      gt_role_tcd-create_usr_t = gt_tran-create_usr.
      gt_role_tcd-create_dat_t = gt_tran-create_dat.
      gt_role_tcd-create_tim_t = gt_tran-create_tim.
      APPEND gt_role_tcd.
      CLEAR gt_role_tcd.
    ENDLOOP.
    IF sy-subrc <> 0.
      CLEAR: gt_role_tcd.
      MOVE-CORRESPONDING gt_hist TO gt_role_tcd.
      READ TABLE lt_user_info WITH KEY bname = gt_hist-create_usr.
      IF sy-subrc = 0.
        gt_role_tcd-name_text = lt_user_info-name_text.
      ENDIF.
      IF gt_hist-status = 'U'.
        gt_role_tcd-status = text-001.
      ELSEIF gt_hist-status = 'I'.
        gt_role_tcd-status = text-002.
      ELSEIF gt_hist-status = 'D'.
        gt_role_tcd-status = text-003.
      ENDIF.
      APPEND gt_role_tcd.
      CLEAR gt_role_tcd.
    ENDIF.
  ENDLOOP.



  SORT gt_role_tcd BY oldval create_usr create_dat create_tim tcode
       create_usr_t create_dat_t create_tim_t.


ENDFORM.                    " GET_DATA
*&---------------------------------------------------------------------*
*&      Form  BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_fieldcat.
 DATA: w_fieldcat TYPE slis_fieldcat_alv.        "Field Catalog Workarea

  REFRESH : v_alv_fieldcat.


  w_fieldcat-fieldname = 'OLDVAL'.
  w_fieldcat-tabname   = 'GT_ROLE_TCD'.
  w_fieldcat-seltext_l = text-004.
  w_fieldcat-col_pos = 1.
  w_fieldcat-hotspot = 'X'.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'STATUS'.
  w_fieldcat-tabname   = 'GT_ROLE_TCD'.
  w_fieldcat-seltext_l = text-005.
  w_fieldcat-col_pos = 2.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.


  w_fieldcat-fieldname = 'CREATE_USR'.
  w_fieldcat-tabname   = 'GT_ROLE_TCD'.
  w_fieldcat-seltext_l = text-006.
  w_fieldcat-col_pos = 3.
  w_fieldcat-emphasize = 'C400'.
  w_fieldcat-hotspot = 'X'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'NAME_TEXT'.
  w_fieldcat-tabname   = 'GT_ROLE_TCD'.
  w_fieldcat-seltext_l = text-023.
  w_fieldcat-col_pos = 4.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_DAT'.
  w_fieldcat-seltext_l = text-007.
  w_fieldcat-tabname   = 'GT_ROLE_TCD'.
  w_fieldcat-col_pos = 5.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_TIM'.
  w_fieldcat-seltext_l = text-008.
  w_fieldcat-tabname   = 'GT_ROLE_TCD'.
  w_fieldcat-col_pos = 6.
  w_fieldcat-emphasize = 'C400'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'TCODE'.
  w_fieldcat-seltext_l = text-009.
  w_fieldcat-tabname   = 'GT_ROLE_TCD'.
  w_fieldcat-col_pos = 7.
  w_fieldcat-hotspot = 'X'.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'STATUS_T'.
  w_fieldcat-tabname   = 'GT_ROLE_TCD'.
  w_fieldcat-seltext_l = text-010.
  w_fieldcat-col_pos = 8.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_USR_T'.
  w_fieldcat-tabname   = 'GT_ROLE_TCD'.
  w_fieldcat-seltext_l = text-011.
  w_fieldcat-hotspot = 'X'.
  w_fieldcat-col_pos = 9.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'NAME_TEXT1'.
  w_fieldcat-tabname   = 'GT_ROLE_TCD'.
  w_fieldcat-seltext_l = text-024.
  w_fieldcat-col_pos = 10.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_DAT_T'.
  w_fieldcat-seltext_l = text-012.
  w_fieldcat-tabname   = 'GT_ROLE_TCD'.
  w_fieldcat-col_pos = 11.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.

  w_fieldcat-fieldname = 'CREATE_TIM_T'.
  w_fieldcat-seltext_l = text-013.
  w_fieldcat-tabname   = 'GT_ROLE_TCD'.
  w_fieldcat-col_pos = 12.
  APPEND w_fieldcat TO v_alv_fieldcat.
  CLEAR w_fieldcat.


ENDFORM.                    " BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*&      Form  BUILD_SORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_sort.
  DATA: w_sort TYPE slis_sortinfo_alv.

  w_sort-spos = '1'.
  w_sort-fieldname = 'OLDVAL'.
  w_sort-tabname = 'GT_ROLE_TCD'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '2'.
  w_sort-fieldname = 'CREATE_DAT'.
  w_sort-tabname = 'GT_ROLE_TCD'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.


  w_sort-spos = '3'.
  w_sort-fieldname = 'CREATE_TIM'.
  w_sort-tabname = 'GT_ROLE_TCD'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '4'.
  w_sort-fieldname = 'CREATE_USR'.
  w_sort-tabname = 'GT_ROLE_TCD'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '5'.
  w_sort-fieldname = 'NAME_TEXT'.
  w_sort-tabname = 'GT_ROLE_TCD'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '6'.
  w_sort-fieldname = 'STATUS'.
  w_sort-tabname = 'GT_ROLE_TCD'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '7'.
  w_sort-fieldname = 'TCODE'.
  w_sort-tabname = 'GT_ROLE_TCD'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.


  w_sort-spos = '8'.
  w_sort-fieldname = 'CREATE_DAT_T'.
  w_sort-tabname = 'GT_ROLE_TCD'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '9'.
  w_sort-fieldname = 'CREATE_TIM_T'.
  w_sort-tabname = 'GT_ROLE_TCD'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '10'.
  w_sort-fieldname = 'CREATE_USR_T'.
  w_sort-tabname = 'GT_ROLE_TCD'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '11'.
  w_sort-fieldname = 'NAME_TEXT1'.
  w_sort-tabname = 'GT_ROLE_TCD'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '12'.
  w_sort-fieldname = 'STATUS_T'.
  w_sort-tabname = 'GT_ROLE_TCD'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.


ENDFORM.                    " BUILD_SORT
*&---------------------------------------------------------------------*
*&      Form  OUT_PUT
*&---------------------------------------------------------------------*
*       text
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
            i_callback_pf_status_set = 'PF_STATUS'
            i_callback_user_command  = 'USER_COMMAND'
            is_layout                = ls_layout
            it_fieldcat              = v_alv_fieldcat
            it_sort                  = l_sort
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = gt_role_tcd[]
       EXCEPTIONS
            program_error            = 1
            OTHERS                   = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.


ENDFORM.                    " OUT_PUT

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
  DATA: line(80),
        answer.

  CASE rs_selfield-fieldname.
**  For Role ID **
    WHEN 'OLDVAL'.
      CHECK rs_selfield-value <> space.
      SELECT SINGLE description FROM /psyng/rolehdr INTO line
                                  WHERE roleid = rs_selfield-value.
      IF  sy-subrc = 0.
        CONCATENATE rs_selfield-value '=' line INTO line
                    SEPARATED BY space.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
             EXPORTING
                  titlebar              = text-016
                  text_question         = line
                  text_button_1         = text-014
                  icon_button_1         = 'ICON_SYSTEM_OKAY'
                  text_button_2         = text-015
                  icon_button_2         = 'ICON_SYSTEM_CANCEL'
                  default_button        = '1'
                  display_cancel_button = ' '
"(++)BOC UMITTAL SE VF scan-25/11/2024
            EXCEPTIONS
             text_not_found  = 1
             OTHERS         = 2 .
            IF sy-subrc <> 0.
                 MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                         WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
             ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      ELSE.
        MESSAGE i398(00) WITH text-017.
      ENDIF.
*** For User ID ********
    WHEN 'CREATE_USR' OR 'CREATE_USR_T'.
      CHECK rs_selfield-value <> space.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU01'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SU01'.
      ELSE.
        SET PARAMETER ID 'XUS' FIELD rs_selfield-value.
        CALL TRANSACTION 'SU01'.
      ENDIF.
****      For Tcode **********
    WHEN 'TCODE'.
      CHECK rs_selfield-value <> space.
      SELECT SINGLE ttext FROM tstct INTO line
            WHERE sprsl = sy-langu AND tcode = rs_selfield-value.
      CLEAR answer.
      IF line = ' '.
        line = text-018.
      ENDIF.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
           EXPORTING
                titlebar              = rs_selfield-value
                text_question         = line
                text_button_1         = text-019
                icon_button_1         = 'ICON_EXECUTE_OBJECT'
                text_button_2         = text-015
                icon_button_2         = 'ICON_SYSTEM_CANCEL'
                default_button        = '2'
                display_cancel_button = ' '
           IMPORTING
                answer                = answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
          EXCEPTIONS
           text_not_found  = 1
           OTHERS         = 2 .
          IF sy-subrc <> 0.
               MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                       WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
           ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

      CHECK answer = '1'.

      AUTHORITY-CHECK OBJECT 'S_TCODE'
               ID 'TCD' FIELD rs_selfield-value.
      IF sy-subrc = 0.
        SELECT SINGLE tcode FROM tstc INTO rs_selfield-value
          WHERE tcode = rs_selfield-value .
        IF sy-subrc = 0.
          CALL TRANSACTION rs_selfield-value."#EC PATHLOCK_CI_DYN_ACCES

        ELSE.
          MESSAGE s398(00) WITH text-020.
        ENDIF.
      ELSE.
        MESSAGE s398(00) WITH text-021.
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
