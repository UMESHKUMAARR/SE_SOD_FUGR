*----------------------------------------------------------------------*
* Report  /PSYNG/SW_020                                                *
* AUTHOR: Security Weaver, LLC                                         *
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

REPORT /psyng/sw_021 LINE-SIZE 200.

TABLES: /psyng/rolehdr.

TYPE-POOLS: slis.                                      "For ALV call
DATA: gs_program         LIKE sy-repid.                   "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
      gs_variant type disvariant.

DATA: gt_irolehdr TYPE STANDARD TABLE OF /psyng/rolehdr WITH HEADER LINE
.

DATA: BEGIN OF output OCCURS 10,
        roleid LIKE /psyng/rolehdr-roleid,
        roledel,
        hdrdel,
        tcdel,
        txtdel,
        message(100),
      END OF output.

DATA: g_answer,
      g_records TYPE i.     "number of records in internal table

SELECTION-SCREEN: BEGIN OF BLOCK 1st WITH FRAME TITLE text-000.
SELECTION-SCREEN: SKIP 1.
*PARAMETERS: p_vrsio LIKE /psyng/rolehdr-vrsio.
SELECT-OPTIONS: proleids FOR /psyng/rolehdr-roleid.

SELECTION-SCREEN: END OF BLOCK 1st.

*------------------------- AT SELECTION-SCREEN ------------------------*
AT SELECTION-SCREEN.
** Validate version
*  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/swsodvers
*                WHERE vrsio = p_vrsio.
*  IF sy-subrc <> 0.
*    MESSAGE e128(/psyng/sw) WITH text-030.
*  ENDIF.


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
  gs_program = sy-repid.
  AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
           ID 'ACTVT' FIELD '06'
           ID 'Y&SW_ROLID' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  if sy-subrc ne 0.
     MESSAGE e113(/psyng/sw) WITH TEXT-001.
    stop.
  endif.

  PERFORM confirm_deletion.
  IF g_records IS INITIAL.
    MESSAGE i113(/psyng/sw) WITH TEXT-002.
    EXIT.
  ENDIF.

  CHECK g_answer = '1'.

*  SELECT * FROM /psyng/rolehdr INTO TABLE irolehdr
*           WHERE roleid IN proleids.

  SELECT roleid FROM /psyng/rolehdr
     INTO CORRESPONDING FIELDS OF TABLE gt_irolehdr
           WHERE roleid IN proleids.
  SORT gt_irolehdr.

  LOOP AT gt_irolehdr.
    CLEAR output.
    output-roleid = gt_irolehdr-roleid.
    CALL FUNCTION '/PSYNG/SW_DELETE_SW_ROLE_ID'
         EXPORTING
              proleid             = gt_irolehdr-roleid
         IMPORTING
              roleid_deleted      = output-roledel
              role_hdr_deleted    = output-hdrdel
              role_tc_deleted     = output-tcdel
              role_txt_deleted    = output-txtdel
         EXCEPTIONS
              roleid_doesnt_exist = 1
              NOT_AUTHORIZED      = 2
              OTHERS              = 3.
    case sy-subrc.
      when 0.
        output-message = TEXT-003.
      when 1.
        output-message = TEXT-004.
      when 2.
        output-message = TEXT-005.
      when 3.
        output-message = TEXT-006.
    endcase.
    APPEND output.
  ENDLOOP.

  IF output[] IS INITIAL.
    MESSAGE i113(/psyng/sw) WITH TEXT-002.
    EXIT.
  ENDIF.

  PERFORM build_alv_catalog.
  PERFORM output_using_alv.

*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_catalog.
DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  gs_program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = gs_program
            i_internal_tabname = 'OUTPUT'
            i_inclname         = gs_program
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

  wa_fieldcat_alv-seltext_l = TEXT-009.
  wa_fieldcat_alv-seltext_m = TEXT-009.
  wa_fieldcat_alv-seltext_s = TEXT-010.
  wa_fieldcat_alv-reptext_ddic = TEXT-010.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ROLEID'.

  wa_fieldcat_alv-seltext_l = TEXT-011.
  wa_fieldcat_alv-seltext_m = TEXT-012.
  wa_fieldcat_alv-seltext_s = TEXT-013.
  wa_fieldcat_alv-reptext_ddic = TEXT-011.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ROLEDEL'.

  wa_fieldcat_alv-seltext_l = TEXT-014.
  wa_fieldcat_alv-seltext_m = TEXT-015.
  wa_fieldcat_alv-seltext_s = TEXT-016.
  wa_fieldcat_alv-reptext_ddic = TEXT-017.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'HDRDEL'.

  wa_fieldcat_alv-seltext_l = TEXT-018.
  wa_fieldcat_alv-seltext_m = TEXT-019.
  wa_fieldcat_alv-seltext_s = TEXT-020.
  wa_fieldcat_alv-reptext_ddic = TEXT-018.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TCDEL'.

  wa_fieldcat_alv-seltext_l = TEXT-021.
  wa_fieldcat_alv-seltext_m = TEXT-022.
  wa_fieldcat_alv-seltext_s = TEXT-023.
  wa_fieldcat_alv-reptext_ddic = TEXT-021.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TXTDEL'.

  wa_fieldcat_alv-seltext_l = TEXT-024.
  wa_fieldcat_alv-seltext_m = TEXT-024.
  wa_fieldcat_alv-seltext_s = TEXT-025.
  wa_fieldcat_alv-reptext_ddic = TEXT-024.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'MESSAGE'.

ENDFORM.                    " build_alv_catalog
*&---------------------------------------------------------------------*
*&      Form  output_using_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_using_alv.
DATA: alv_layout TYPE slis_layout_alv.

  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title            = TEXT-007
            i_callback_program      = gs_program
            is_layout               = alv_layout
            i_save                  = 'A'
            is_variant              = gs_variant
            it_fieldcat             = i_fieldcat_alv
       TABLES
            t_outtab                = output
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
*&      Form  confirm_deletion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM confirm_deletion.
DATA: records_c(20),
      question(40).

  SELECT COUNT( * ) FROM /psyng/rolehdr INTO g_records
           WHERE roleid IN proleids.

  CHECK NOT g_records IS INITIAL.

  WRITE g_records TO records_c.
  CONDENSE records_c.
  CONCATENATE: TEXT-026 records_c TEXT-027 INTO question
               SEPARATED BY space.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
       EXPORTING
            titlebar              = TEXT-008
            text_question         = question
            text_button_1         = TEXT-028
            default_button        = '2'
            text_button_2         = TEXT-029
            display_cancel_button = ' '
       IMPORTING
            answer                = g_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND  = 2
             OTHERS          = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.                    " confirm_deletion
