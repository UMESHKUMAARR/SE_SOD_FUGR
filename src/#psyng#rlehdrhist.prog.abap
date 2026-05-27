REPORT /PSYNG/RLEHDRHIST_TO_ALV NO STANDARD PAGE HEADING.
*----------------------------------------------------------------------
*
* PROGRAM               : /PSYNG/RLEHDRHIST
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
TABLES: /PSYNG/ROLEHDR,/PSYNG/HISTORY.

*Change code
TYPE-POOLS: SLIS. "Define Type-Pool

*Define Fiel Catalog
DATA: V_ALV_FIELDCAT TYPE SLIS_T_FIELDCAT_ALV,  "Field Catalog
      L_SORT TYPE SLIS_T_SORTINFO_ALV.
*end


SELECT-OPTIONS: ROLEID FOR /PSYNG/ROLEHDR-ROLEID.
SELECT-OPTIONS: DATE FOR SY-DATUM,
                TIME FOR SY-UZEIT,
                USER FOR /PSYNG/HISTORY-CREATE_USR.


*Define Internal Tables
DATA: BEGIN OF GT_ROL_HIS OCCURS 0,
      OLDVAL LIKE /PSYNG/HISTORY-OLDVAL,
      STATUS LIKE /PSYNG/HISTORY-STATUS,
      CREATE_USR LIKE /PSYNG/HISTORY-CREATE_USR,
      CREATE_DAT LIKE /PSYNG/HISTORY-CREATE_DAT,
      CREATE_TIM LIKE /PSYNG/HISTORY-CREATE_TIM,
      END OF GT_ROL_HIS,

      BEGIN OF LT_ROLE_ITM OCCURS 0,
      HDRFLD LIKE /PSYNG/HISTORY-HDRFLD,
      DTLFLD LIKE /PSYNG/HISTORY-DTLFLD,
      OLDVAL LIKE /PSYNG/HISTORY-OLDVAL,
      NEWVAL LIKE /PSYNG/HISTORY-NEWVAL,
      STATUS LIKE /PSYNG/HISTORY-STATUS,
      CREATE_USR LIKE /PSYNG/HISTORY-CREATE_USR,
      CREATE_DAT LIKE /PSYNG/HISTORY-CREATE_DAT,
      CREATE_TIM LIKE /PSYNG/HISTORY-CREATE_TIM,
      END OF LT_ROLE_ITM,

      BEGIN OF GT_FIN_HIS OCCURS 0,
      OLDVAL LIKE /PSYNG/HISTORY-OLDVAL,
      STATUS(10),
      CREATE_USR LIKE /PSYNG/HISTORY-CREATE_USR,
      NAME_TEXT LIKE /PSYNG/BC_UIDN-NAME_TEXT,
      CREATE_DAT LIKE /PSYNG/HISTORY-CREATE_DAT,
      CREATE_TIM LIKE /PSYNG/HISTORY-CREATE_TIM,
      DTLFLD LIKE /PSYNG/HISTORY-DTLFLD,
      OLDVAL1 LIKE /PSYNG/HISTORY-OLDVAL,
      NEWVAL1 LIKE /PSYNG/HISTORY-NEWVAL,
      STATUS1(10),
      CREATE_USR1 LIKE /PSYNG/HISTORY-CREATE_USR,
      NAME_TEXT1 LIKE /PSYNG/BC_UIDN-NAME_TEXT,
      CREATE_DAT1 LIKE /PSYNG/HISTORY-CREATE_DAT,
      CREATE_TIM1 LIKE /PSYNG/HISTORY-CREATE_TIM,
      END OF GT_FIN_HIS.

************************************************************************
*   DECLARATION F1 HELP FOR SELECTION SCREEN FIELDS
************************************************************************
* For field Change Date
At SELECTION-SCREEN ON HELP-REQUEST FOR DATE.

PERFORM show_help USING '/PSYNG/SW_076_CHANGE_DAT'.


* For field Change Time
At SELECTION-SCREEN ON HELP-REQUEST FOR TIME.

PERFORM show_help USING '/PSYNG/SW_076_CHANGE_TIM'.

* For field Change User
At SELECTION-SCREEN ON HELP-REQUEST FOR USER.

PERFORM show_help USING '/PSYNG/SW_076_CHANGE_USR'.


************************************************************************
*   START-OF-SELECTION
************************************************************************
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
  PERFORM GET_DATA.
  PERFORM BUILD_FIELDCAT.
  PERFORM BUILD_SORT.
  PERFORM OUT_PUT.

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


** --------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM GET_DATA.
  DATA: lt_user_info TYPE TABLE OF /psyng/bc_uidn WITH HEADER LINE.


  SELECT  OLDVAL STATUS CREATE_USR CREATE_DAT CREATE_TIM
  FROM /PSYNG/HISTORY INTO TABLE GT_ROL_HIS
           WHERE TABNAME = '/PSYNG/ROLEHDR'
           AND   HDRFLD = 'ROLEID'
           AND   OLDVAL  IN ROLEID
           AND   CREATE_DAT IN DATE
           AND   CREATE_TIM IN TIME
           AND   CREATE_USR IN USER.


  IF NOT GT_ROL_HIS[] IS INITIAL.


    SELECT HDRFLD DTLFLD OLDVAL NEWVAL STATUS CREATE_USR CREATE_DAT
    CREATE_TIM FROM
          /PSYNG/HISTORY INTO CORRESPONDING FIELDS OF TABLE LT_ROLE_ITM
              FOR ALL ENTRIES IN GT_ROL_HIS
              WHERE TABNAME = '/PSYNG/ROLEHDR'
                AND   HDRFLD  = GT_ROL_HIS-OLDVAL
                AND   CREATE_DAT = GT_ROL_HIS-CREATE_DAT
                AND   CREATE_TIM = GT_ROL_HIS-CREATE_TIM
                AND   CREATE_USR = GT_ROL_HIS-CREATE_USR.

  ENDIF.

  CALL FUNCTION '/PSYNG/BC_011'
       TABLES
            it_bname = user
            et_uidn  = lt_user_info.

  LOOP AT GT_ROL_HIS.
    LOOP AT LT_ROLE_ITM WHERE HDRFLD = GT_ROL_HIS-OLDVAL AND CREATE_DAT
    = GT_ROL_HIS-CREATE_DAT AND CREATE_TIM = GT_ROL_HIS-CREATE_TIM AND
    CREATE_USR = GT_ROL_HIS-CREATE_USR.
      MOVE-CORRESPONDING GT_ROL_HIS TO GT_FIN_HIS.

      READ TABLE lt_user_info WITH KEY BNAME = GT_ROL_HIS-CREATE_USR.
      IF SY-SUBRC = 0.
        GT_FIN_HIS-NAME_TEXT = lt_user_info-NAME_TEXT.
      ENDIF.
      READ TABLE lt_user_info WITH KEY BNAME =  LT_ROLE_ITM-CREATE_USR.
      IF SY-SUBRC = 0.
        GT_FIN_HIS-NAME_TEXT1 = lt_user_info-NAME_TEXT.
      ENDIF.

      IF GT_ROL_HIS-STATUS = 'U'.
        GT_FIN_HIS-STATUS = text-005.
      ELSEIF GT_ROL_HIS-STATUS = 'I'.
        GT_FIN_HIS-STATUS = text-006.
      ELSEIF GT_ROL_HIS-STATUS = 'D'.
        GT_FIN_HIS-STATUS = text-007.
      ENDIF.

      GT_FIN_HIS-oldval1 = LT_ROLE_ITM-OLDVAL.
      IF LT_ROLE_ITM-STATUS = 'U'.
        GT_FIN_HIS-STATUS1 = TEXT-005.
      ELSEIF LT_ROLE_ITM-STATUS = 'I'.
        GT_FIN_HIS-STATUS1 = TEXT-006.
      ELSEIF LT_ROLE_ITM-STATUS = 'D'.
        GT_FIN_HIS-STATUS1 = TEXT-007.
      ENDIF.
      GT_FIN_HIS-CREATE_USR1 = LT_ROLE_ITM-CREATE_USR.
      GT_FIN_HIS-CREATE_DAT1 = LT_ROLE_ITM-CREATE_DAT.
      GT_FIN_HIS-CREATE_TIM1 = LT_ROLE_ITM-CREATE_TIM.
      GT_FIN_HIS-DTLFLD = LT_ROLE_ITM-DTLFLD.
      GT_FIN_HIS-NEWVAL1 = LT_ROLE_ITM-NEWVAL.
      APPEND GT_FIN_HIS.
      CLEAR GT_FIN_HIS.
    ENDLOOP.
    IF SY-SUBRC <> 0.
      CLEAR: GT_FIN_HIS.
      MOVE-CORRESPONDING GT_ROL_HIS TO GT_FIN_HIS.
      READ TABLE lt_user_info WITH KEY BNAME = GT_ROL_HIS-CREATE_USR.
      IF SY-SUBRC = 0.
        GT_FIN_HIS-NAME_TEXT = lt_user_info-NAME_TEXT.
      ENDIF.
      IF GT_ROL_HIS-STATUS = 'U'.
        GT_FIN_HIS-STATUS = text-005.
      ELSEIF GT_ROL_HIS-STATUS = 'I'.
        GT_FIN_HIS-STATUS = text-006.
      ELSEIF GT_ROL_HIS-STATUS = 'D'.
        GT_FIN_HIS-STATUS = text-007.
      ENDIF.

      APPEND GT_FIN_HIS.
      CLEAR GT_FIN_HIS.
    ENDIF.
  ENDLOOP.

  SORT GT_FIN_HIS BY OLDVAL CREATE_USR CREATE_DAT CREATE_TIM DTLFLD
       CREATE_USR1 CREATE_DAT1 CREATE_TIM1.
ENDFORM.                    " GET_DATA
*&---------------------------------------------------------------------*
*&      Form  BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM BUILD_FIELDCAT.
DATA: W_FIELDCAT TYPE SLIS_FIELDCAT_ALV.        "Field Catalog Workarea


  W_FIELDCAT-FIELDNAME = 'OLDVAL'.
  W_FIELDCAT-TABNAME   = 'GT_FIN_HIS'.
  W_FIELDCAT-SELTEXT_L = text-008.
  W_FIELDCAT-COL_POS = 1.
  W_FIELDCAT-HOTSPOT = 'X'.
  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND W_FIELDCAT TO V_ALV_FIELDCAT.
  CLEAR W_FIELDCAT.

  W_FIELDCAT-FIELDNAME = 'STATUS'.
  W_FIELDCAT-TABNAME   = 'GT_FIN_HIS'.
  W_FIELDCAT-SELTEXT_L = text-009.
  W_FIELDCAT-COL_POS = 2.
  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND W_FIELDCAT TO V_ALV_FIELDCAT.
  CLEAR W_FIELDCAT.


  W_FIELDCAT-FIELDNAME = 'CREATE_USR'.
  W_FIELDCAT-TABNAME   = 'GT_FIN_HIS'.
  W_FIELDCAT-SELTEXT_L = text-010.
  W_FIELDCAT-COL_POS = 3.
  W_FIELDCAT-HOTSPOT = 'X'.
  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND W_FIELDCAT TO V_ALV_FIELDCAT.
  CLEAR W_FIELDCAT.

  W_FIELDCAT-FIELDNAME = 'NAME_TEXT'.
  W_FIELDCAT-TABNAME   = 'GT_FIN_HIS'.
  W_FIELDCAT-SELTEXT_L = text-021.
  W_FIELDCAT-COL_POS = 4.
  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND W_FIELDCAT TO V_ALV_FIELDCAT.
  CLEAR W_FIELDCAT.

  W_FIELDCAT-FIELDNAME = 'CREATE_DAT'.
  W_FIELDCAT-SELTEXT_L = text-011.
  W_FIELDCAT-TABNAME   = 'GT_FIN_HIS'.
  W_FIELDCAT-COL_POS = 5.
  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND W_FIELDCAT TO V_ALV_FIELDCAT.
  CLEAR W_FIELDCAT.

  W_FIELDCAT-FIELDNAME = 'CREATE_TIM'.
  W_FIELDCAT-SELTEXT_L = text-012.
  W_FIELDCAT-TABNAME   = 'GT_FIN_HIS'.
  W_FIELDCAT-COL_POS = 6.
  W_FIELDCAT-EMPHASIZE = 'C400'.
  APPEND W_FIELDCAT TO V_ALV_FIELDCAT.
  CLEAR W_FIELDCAT.

  W_FIELDCAT-FIELDNAME = 'DTLFLD'.
  W_FIELDCAT-SELTEXT_L = text-013.
  W_FIELDCAT-TABNAME   = 'GT_FIN_HIS'.
  W_FIELDCAT-COL_POS = 7.
  APPEND W_FIELDCAT TO V_ALV_FIELDCAT.
  CLEAR W_FIELDCAT.

  W_FIELDCAT-FIELDNAME = 'OLDVAL1'.
  W_FIELDCAT-SELTEXT_L = text-014.
  W_FIELDCAT-TABNAME   = 'GT_FIN_HIS'.
  W_FIELDCAT-COL_POS = 8.
  APPEND W_FIELDCAT TO V_ALV_FIELDCAT.
  CLEAR W_FIELDCAT.

  W_FIELDCAT-FIELDNAME = 'NEWVAL1'.
  W_FIELDCAT-SELTEXT_L = text-015.
  W_FIELDCAT-TABNAME   = 'GT_FIN_HIS'.
  W_FIELDCAT-COL_POS = 9.
  APPEND W_FIELDCAT TO V_ALV_FIELDCAT.
  CLEAR W_FIELDCAT.

  W_FIELDCAT-FIELDNAME = 'STATUS1'.
  W_FIELDCAT-TABNAME   = 'GT_FIN_HIS'.
  W_FIELDCAT-SELTEXT_L = text-016.
  W_FIELDCAT-COL_POS = 10.
  APPEND W_FIELDCAT TO V_ALV_FIELDCAT.
  CLEAR W_FIELDCAT.

  W_FIELDCAT-FIELDNAME = 'CREATE_USR1'.
  W_FIELDCAT-TABNAME   = 'GT_FIN_HIS'.
  W_FIELDCAT-SELTEXT_L = text-017.
  W_FIELDCAT-COL_POS = 11.
  W_FIELDCAT-HOTSPOT = 'X'.
  APPEND W_FIELDCAT TO V_ALV_FIELDCAT.
  CLEAR W_FIELDCAT.

  W_FIELDCAT-FIELDNAME = 'NAME_TEXT1'.
  W_FIELDCAT-TABNAME   = 'GT_FIN_HIS'.
  W_FIELDCAT-SELTEXT_L = text-022.
  W_FIELDCAT-COL_POS = 12.
  APPEND W_FIELDCAT TO V_ALV_FIELDCAT.
  CLEAR W_FIELDCAT.

  W_FIELDCAT-FIELDNAME = 'CREATE_DAT1'.
  W_FIELDCAT-SELTEXT_L = text-018.
  W_FIELDCAT-TABNAME   = 'GT_FIN_HIS'.
  W_FIELDCAT-COL_POS = 13.
  APPEND W_FIELDCAT TO V_ALV_FIELDCAT.
  CLEAR W_FIELDCAT.

  W_FIELDCAT-FIELDNAME = 'CREATE_TIM1'.
  W_FIELDCAT-SELTEXT_L = text-019.
  W_FIELDCAT-TABNAME   = 'GT_FIN_HIS'.
  W_FIELDCAT-COL_POS = 14.
  APPEND W_FIELDCAT TO V_ALV_FIELDCAT.
  CLEAR W_FIELDCAT.

ENDFORM.                    " BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*&      Form  BUILD_SORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM BUILD_SORT.
DATA: W_SORT TYPE SLIS_SORTINFO_ALV.


  W_SORT-SPOS = '1'.
  W_SORT-FIELDNAME = 'OLDVAL'.
  W_SORT-TABNAME = 'GT_TRAN_HIS'.
  W_SORT-UP = 'X'.
  APPEND W_SORT TO L_SORT.
  CLEAR W_SORT.

  W_SORT-SPOS = '2'.
  W_SORT-FIELDNAME = 'CREATE_DAT'.
  W_SORT-TABNAME = 'GT_TRAN_HIS'.
  W_SORT-UP = 'X'.
  APPEND W_SORT TO L_SORT.
  CLEAR W_SORT.

  W_SORT-SPOS = '3'.
  W_SORT-FIELDNAME = 'CREATE_TIM'.
  W_SORT-TABNAME = 'GT_TRAN_HIS'.
  W_SORT-UP = 'X'.
  APPEND W_SORT TO L_SORT.
  CLEAR W_SORT.

  W_SORT-SPOS = '4'.
  W_SORT-FIELDNAME = 'CREATE_USR'.
  W_SORT-TABNAME = 'GT_TRAN_HIS'.
  W_SORT-UP = 'X'.
  APPEND W_SORT TO L_SORT.
  CLEAR W_SORT.

  W_SORT-SPOS = '5'.
  W_SORT-FIELDNAME = 'NAME_TEXT'.
  W_SORT-TABNAME = 'GT_TRAN_HIS'.
  W_SORT-UP = 'X'.
  APPEND W_SORT TO L_SORT.
  CLEAR W_SORT.

  W_SORT-SPOS = '6'.
  W_SORT-FIELDNAME = 'STATUS'.
  W_SORT-TABNAME = 'GT_TRAN_HIS'.
  W_SORT-UP = 'X'.
  APPEND W_SORT TO L_SORT.
  CLEAR W_SORT.

  W_SORT-SPOS = '7'.
  W_SORT-FIELDNAME = 'DTLFLD'.
  W_SORT-TABNAME = 'GT_TRAN_HIS'.
  W_SORT-UP = 'X'.
  APPEND W_SORT TO L_SORT.
  CLEAR W_SORT.

  W_SORT-SPOS = '8'.
  W_SORT-FIELDNAME = 'CREATE_DAT1'.
  W_SORT-TABNAME = 'GT_TRAN_HIS'.
  W_SORT-UP = 'X'.
  APPEND W_SORT TO L_SORT.
  CLEAR W_SORT.

  W_SORT-SPOS = '9'.
  W_SORT-FIELDNAME = 'CREATE_TIM1'.
  W_SORT-TABNAME = 'GT_TRAN_HIS'.
  W_SORT-UP = 'X'.
  APPEND W_SORT TO L_SORT.
  CLEAR W_SORT.

  W_SORT-SPOS = '10'.
  W_SORT-FIELDNAME = 'CREATE_USR1'.
  W_SORT-TABNAME = 'GT_TRAN_HIS'.
  W_SORT-UP = 'X'.
  APPEND W_SORT TO L_SORT.
  CLEAR W_SORT.

  W_SORT-SPOS = '11'.
  W_SORT-FIELDNAME = 'NAME_TEXT1'.
  W_SORT-TABNAME = 'GT_TRAN_HIS'.
  W_SORT-UP = 'X'.
  APPEND W_SORT TO L_SORT.
  CLEAR W_SORT.

  W_SORT-SPOS = '12'.
  W_SORT-FIELDNAME = 'STATUS1'.
  W_SORT-TABNAME = 'GT_TRAN_HIS'.
  W_SORT-UP = 'X'.
  APPEND W_SORT TO L_SORT.
  CLEAR W_SORT.



ENDFORM.                    " BUILD_SORT
*&---------------------------------------------------------------------*
*&      Form  OUT_PUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM OUT_PUT.
data: l_program  TYPE sy-repid,
      ls_variant TYPE disvariant,
      ls_layout  TYPE SLIS_LAYOUT_ALV.           "ALV Report Layout.

  l_program = sy-repid.
  ls_layout-zebra = 'X'.
  ls_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
     I_CALLBACK_PROGRAM                = l_program
     I_CALLBACK_PF_STATUS_SET          = 'PF_STATUS'
     I_CALLBACK_USER_COMMAND           = 'USER_COMMAND'
     IS_LAYOUT                         = ls_layout
     IT_FIELDCAT                       = V_ALV_FIELDCAT
     IT_SORT                           = L_SORT
     I_SAVE                            = 'A'
     IS_VARIANT                        = ls_variant
    TABLES
      T_OUTTAB                          = GT_FIN_HIS[]
   EXCEPTIONS
     PROGRAM_ERROR                     = 1
     OTHERS                            = 2.
  IF SY-SUBRC <> 0.
 MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
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
FORM USER_COMMAND USING r_ucomm LIKE sy-ucomm
                                 rs_selfield TYPE slis_selfield.
  DATA: LINE(80).
  CASE rs_selfield-fieldname.
    WHEN 'OLDVAL'.
      CHECK rs_selfield-value <> space.
      SELECT single description FROM /PSYNG/ROLEHDR INTO line
                                  WHERE ROLEID = rs_selfield-value.
      IF  sy-subrc = 0.
        CONCATENATE rs_selfield-value '=' line INTO line
                    SEPARATED BY space.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
             EXPORTING
                  titlebar              = text-003
                  text_question         = line
                  text_button_1         = text-001
                  icon_button_1         = 'ICON_SYSTEM_OKAY'
                  text_button_2         = text-002
                  icon_button_2         = 'ICON_SYSTEM_CANCEL'
                  default_button        = '1'
                  display_cancel_button = ' '
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 3 .
            IF sy-subrc <> 0.
                 MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                         WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
             ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.                    .
      ELSE.
        MESSAGE I398(00) WITH text-004.
      endif.

    WHEN 'CREATE_USR' OR 'CREATE_USR1'.
      CHECK rs_selfield-value <> space.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU01'.
      IF sy-subrc <> 0.
        MESSAGE E077(S#) WITH 'SU01'.
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

FORM PF_STATUS USING LT_EXTAB TYPE SLIS_T_EXTAB.

  SET PF-STATUS 'FUN_HISTRY' EXCLUDING LT_EXTAB.



ENDFORM.                    " SW_PF_STATUS_OVERALL
