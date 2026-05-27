REPORT /psyng/sw_144 MESSAGE-ID /psyng/sw."#EC SAST_CI_GEN_CHECK
TABLES: /psyng/sw_rfcdes, /psyng/range_sysid.

*----Macros
DEFINE msg.
  if sy-batch = 'X'.
    message s002(/psyng/sw) with &1 &2 &3 &4.
    commit work.
  endif.
END-OF-DEFINITION.

DATA:  g_curr_variant LIKE  rsvar-variant,
       g_variant LIKE vari-variant,
       gs_variant TYPE disvariant,
       g_vari_desc TYPE varid OCCURS 0 WITH HEADER LINE,
       g_vari_contents LIKE  rsparams OCCURS 0 WITH HEADER LINE,
       g_vari_text LIKE varit OCCURS 0 WITH HEADER LINE,
       gt_irsparams    TYPE rsparams OCCURS 0 WITH HEADER LINE,
       g_exit_proc,
       g_program LIKE sy-repid.

*---Selection screen
SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.
SELECTION-SCREEN:SKIP 1.
SELECT-OPTIONS: so_sys FOR /psyng/range_sysid-low NO INTERVALS.
*MATCHCODE OBJECT /PSYNG/SERESID.
SELECTION-SCREEN:SKIP 1.
SELECTION-SCREEN: END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK hblk WITH FRAME TITLE text-t03.
SELECTION-SCREEN:SKIP 1.
SELECTION-SCREEN:BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  1(30) text-001 USER-COMMAND scjb
MODIF ID bgd.
SELECTION-SCREEN PUSHBUTTON  40(30) text-002 USER-COMMAND sm37
MODIF ID sm.
SELECTION-SCREEN:END OF LINE.
SELECTION-SCREEN END OF BLOCK hblk .

PARAMETERS p_skip TYPE flag NO-DISPLAY.

AT SELECTION-SCREEN.

*---SM37
  IF sy-ucomm = 'SM37'.
    AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
    IF sy-subrc <> 0.
      MESSAGE e077(s#) WITH 'SM37'.
    ELSE.
      CALL TRANSACTION 'SM37'.
    ENDIF.
  ENDIF.

*----Schedule bck job
  IF sy-ucomm = 'SCJB'.
    g_exit_proc = 'Y'.
    PERFORM schedule_back_job.
    EXIT.
  ENDIF.

INITIALIZATION.
  g_program = sy-repid.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR so_sys-low.
  PERFORM f4_system USING 'SO_SYS' CHANGING so_sys-low.

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
  IF so_sys[] IS INITIAL.
    MESSAGE s002 WITH 'Please enter the system'(s06).
    LEAVE TO LIST-PROCESSING.
  ENDIF.

  IF g_exit_proc = 'Y'.
*BOC UMITTAL SE VF scan changes-25/11/2024
*    SUBMIT (g_program)
    SUBMIT /PSYNG/SW_144
*EOC UMITTAL SE VF scan changes-25/11/2024
               VIA SELECTION-SCREEN
               USING SELECTION-SET g_curr_variant .
  ENDIF.

*--refresh & update the db
  PERFORM modify_database.


*---------------------------------------------------------------------*
*       FORM modify_database                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM modify_database.
  DATA: l_success TYPE flag,
        lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE,
        lt_system TYPE TABLE OF /psyng/range_sysid WITH HEADER LINE.


  IF NOT so_sys[] IS INITIAL.
    msg  'Refresh Process Started' '' '' '' .

*  --- refresh & update db
    CALL FUNCTION '/PSYNG/SW_ADM_REFRESH_OVRVIEW'
         IMPORTING
              ef_success = l_success
         TABLES
              it_system  = so_sys
              et_return  = lt_return.
    LOOP AT lt_return.
        msg  '|-- ' lt_return-type lt_return-id lt_return-message  .
    ENDLOOP.
    IF l_success = 'X'.
      msg '|--- ' 'Refresh Successfull' '' ''.
      IF g_exit_proc IS INITIAL.
        MESSAGE s002 WITH 'Refresh Successfull'(s04).
      ENDIF.
    ELSE.

      msg '|--- ' 'Refresh Failed!' '' '' .
      IF g_exit_proc IS INITIAL.
        MESSAGE s002 WITH 'Refresh Failed'(s05).
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM schedule_back_job                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM schedule_back_job.
  DATA: curr_report LIKE rsvar-report,
        l_jobname TYPE btcjob.

  CLEAR: curr_report, g_curr_variant.
  PERFORM get_next_variant_id.
  curr_report = sy-repid.
  g_curr_variant = g_variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
       EXPORTING
            curr_report   = curr_report
            curr_variant  = g_curr_variant
            vari_desc     = g_vari_desc
       TABLES
            vari_contents = g_vari_contents
            vari_text     = g_vari_text
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
IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

"(++)EOC UMITTAL SE VF scan-25/11/2024.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    l_jobname = 'SE - Update System Info'(041).
    CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
         EXPORTING
              in_jobname  = l_jobname
              in_repvarnt = g_curr_variant
              in_report   = curr_report.
    IF sy-subrc <> 0.
      CALL SCREEN 1000.
    ENDIF.
  ENDIF.

ENDFORM.                    " schedule_back_job


*---------------------------------------------------------------------*
*       FORM get_next_variant_id                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_next_variant_id.
  DATA: oldnumber(7) TYPE n, oldnumber_c(7).

  CLEAR: g_variant, g_vari_desc.
  REFRESH: g_vari_desc.
  SELECT  variant INTO g_variant FROM varid

  WHERE report = sy-repid   AND
        variant LIKE '/PSYNG/%' AND NOT
        variant LIKE '/PSYNG/Z%'
  ORDER BY variant DESCENDING.
    oldnumber = g_variant+7(7).
    EXIT.
  ENDSELECT.
  IF sy-subrc NE 0.
    g_variant = '/PSYNG/0000000'.
  ELSE.
    oldnumber = oldnumber + 1.
    MOVE oldnumber TO oldnumber_c.
    CONCATENATE text-081 oldnumber_c INTO g_variant.
  ENDIF.

  g_vari_desc-report = sy-repid.
  g_vari_desc-variant = g_variant.
  APPEND g_vari_desc.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM f4_system                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  FIELDNAME                                                     *
*  -->  E_VALUE                                                       *
*---------------------------------------------------------------------*
FORM f4_system USING    fieldname
                 CHANGING e_value.

  DATA: BEGIN OF lt_values OCCURS 0,
            line(255) TYPE c,
          END OF lt_values.
  DATA: lt_fields    TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return    TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_sw_rfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE.

  SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_sw_rfcdes.
  LOOP AT lt_sw_rfcdes.
    lt_values-line = lt_sw_rfcdes-rfcdest.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-rfcname.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-description.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-systid.
    APPEND lt_values.
     lt_values-line = lt_sw_rfcdes-SYS_TYPE.
      APPEND lt_values.
     lt_values-line = lt_sw_rfcdes-SYS_CATEGORY.
      APPEND lt_values.
  ENDLOOP.

  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'RFCDEST'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'RFCNAME'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'DESCRIPTION'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYSTID'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYS_TYPE'.
  append lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYS_CATEGORY'.
  APPEND lt_fields.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield        = 'SYSTID'
       TABLES
            value_tab       = lt_values
            field_tab       = lt_fields
            return_tab      = lt_return
       EXCEPTIONS
            parameter_error = 1
            no_values_found = 2
            OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_value = lt_return-fieldval.
ENDFORM.
