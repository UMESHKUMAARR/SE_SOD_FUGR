FUNCTION /psyng/sw_058.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_CONTID) TYPE  /PSYNG/MCHDR-CONTID
*"     REFERENCE(I_RFCDEST) TYPE  RFCDEST
*"  EXCEPTIONS
*"      INVALID_CONTROL
*"----------------------------------------------------------------------
  data : lt_text type table of /PSYNG/TEXTS with header line.
  IF i_rfcdest = 'LOCAL'.
*   Get header
    SELECT SINGLE * FROM /psyng/mchdr WHERE contid = i_contid.

    IF sy-subrc <> 0.
      MESSAGE e128(/psyng/sw) WITH i_contid RAISING invalid_control.
    ENDIF.

*   Get text
    REFRESH gt_text.
    SELECT line text INTO corresponding fields of  TABLE gt_text
    FROM /psyng/texts
           WHERE textname = i_contid
             AND object   = 'M'
             AND spras    = sy-langu
    order by line.
    if gt_text[] is initial.
*--Text not available in logon language
      data : l_default_lang like sy-langu value 'EN'.
      SELECT line  text INTO corresponding fields of
      TABLE gt_text FROM /psyng/texts
             WHERE textname = i_contid
               AND object   = 'M'
               AND spras    = l_default_lang
               order by line.
      if gt_text[] is initial.
*--   Also not found in English, use first language found
      SELECT single spras  INTO l_default_lang
      FROM /psyng/texts
      WHERE textname = i_contid
      AND   object   = 'M'.
      if sy-subrc = 0.
        SELECT line text INTO corresponding fields of
        TABLE gt_text FROM /psyng/texts
               WHERE textname = i_contid
                 AND object   = 'M'
                 AND spras    = l_default_lang
                 order by line.
      endif.
    endif.
   endif.


*   Get TCodes
    SELECT * INTO TABLE gt_mctran FROM /psyng/mctran
           WHERE contid = i_contid.

*   Get Reports
    SELECT * INTO TABLE gt_mcrepid FROM /psyng/mcrepid
           WHERE contid = i_contid.

*   Get Auditors
    SELECT * INTO TABLE gt_mcauditor FROM /psyng/mcauditor
           WHERE contid = i_contid.
  ELSE.


*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
                  .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

    CALL FUNCTION '/PSYNG/SW_CR_READ_MIT_CONTROLS'
      destination I_RFCDEST
      EXPORTING
        contid                            =  i_contid
*     I_VRSIO                           =
     IMPORTING
       mchdr                             = /psyng/mchdr
     TABLES
       mcrepid                           = gt_mcrepid
       mctran                            = gt_mctran
*     MCUSER                            =
       mcauditor                         = gt_mcauditor
*     MCUGROUP                          =
       texts                             = lt_text
      EXCEPTIONS
       mit_control_id_doesnt_exist       = 1
       not_authorized_to_display         = 2
       OTHERS                            = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    IF sy-subrc <> 0.
      if sy-subrc = 1.
*--Doesn't exist on remote system, try local
    CALL FUNCTION '/PSYNG/SW_CR_READ_MIT_CONTROLS'
      EXPORTING
        contid                            =  i_contid
*     I_VRSIO                           =
     IMPORTING
       mchdr                             = /psyng/mchdr
     TABLES
       mcrepid                           = gt_mcrepid
       mctran                            = gt_mctran
*     MCUSER                            =
       mcauditor                         = gt_mcauditor
*     MCUGROUP                          =
       texts                             = lt_text
      EXCEPTIONS
       mit_control_id_doesnt_exist       = 0
       not_authorized_to_display         = 0
       OTHERS                            = 0.
      endif.
    ENDIF.
    free : gt_text.
    loop at lt_text.
      gt_text = lt_text-text.
      append gt_text.
    endloop.

  ENDIF.

  CALL SCREEN 1100 STARTING AT 20 3.
ENDFUNCTION.
