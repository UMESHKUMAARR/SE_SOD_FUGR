*----------------------------------------------------------------------*
* FUNCTION              : /PSYNG/SW_035
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
*SW: Mitigation Details Popup Function module
*&---------------------------------------------------------------------*

FUNCTION /psyng/sw_035.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_VRSIO) TYPE  /PSYNG/SODVRSIO
*"     REFERENCE(I_CONID) TYPE  /PSYNG/CONFLICT-CONID
*"     REFERENCE(I_CONTID) TYPE  /PSYNG/1STOUTPUT_U-CONTID
*"     REFERENCE(I_BNAME) TYPE  UST04-BNAME
*"  EXCEPTIONS
*"      MIT_CONTROL_ID_DOESNT_EXIST
*"      CONFLICT_ID_DOESNT_EXIST
*"      USER_ID_DOESNT_EXIST
*"      MIT_NOT_ASIN_TO_USER_AND_CLASS
*"----------------------------------------------------------------------

  TABLES:/psyng/mcuser,/psyng/mchdr,/psyng/mcauditor,usr02.

**Internal table declarartion
  DATA: lt_mchdr TYPE TABLE OF /psyng/mchdr
                                  INITIAL SIZE 0 WITH HEADER LINE,

        lt_mcrepid TYPE TABLE OF /psyng/mcrepid
                                INITIAL SIZE 0 WITH HEADER LINE,

        lt_mctran TYPE TABLE OF /psyng/mctran
                                   INITIAL SIZE 0 WITH HEADER LINE,

        lt_mcuser TYPE TABLE OF  /psyng/mcuser
                                  INITIAL SIZE 0 WITH HEADER LINE,


        lt_mcugroup TYPE TABLE OF /psyng/mcusrgrp
                                 INITIAL SIZE 0 WITH HEADER LINE,
        lt_mcauditor TYPE TABLE OF /psyng/mcauditor
                                    INITIAL SIZE 0 WITH HEADER LINE,

        lt_texts TYPE TABLE OF /psyng/texts
                                   INITIAL SIZE 0 WITH HEADER LINE.

  DATA:lt_conflct TYPE TABLE OF /psyng/conflict
                            INITIAL SIZE 0 WITH HEADER LINE,
       lt_user  TYPE TABLE OF usr02
                            INITIAL SIZE 0 WITH HEADER LINE.

***Internal table decl for userclass
  DATA:BEGIN OF  lt_usr02  OCCURS 0,
      l_class LIKE usr02-class,
      END OF  lt_usr02.

**Workarea declaration
  DATA:wa_lt_mcrepid   LIKE LINE OF  lt_mcrepid,
       wa_lt_mcauditor LIKE LINE OF  lt_mcauditor,
       wa_lt_mctran    LIKE LINE OF  lt_mctran,
       wa_lt_texts     LIKE LINE OF  lt_texts.


**  Checking Conflict id

  SELECT SINGLE * FROM /psyng/conflict  INTO lt_conflct
                                     WHERE conid = i_conid.
  IF sy-subrc NE 0.
    CLEAR lt_conflct.
    RAISE conflict_id_doesnt_exist.
  ENDIF.

****  Checking mitigation id

  SELECT SINGLE * FROM /psyng/mchdr INTO lt_mchdr
                                 WHERE contid = i_contid.
  IF sy-subrc NE 0.
    CLEAR lt_mchdr.
    RAISE mit_control_id_doesnt_exist.
  ENDIF.

*   Checking Userid
  IF NOT i_bname IS INITIAL.

    SELECT SINGLE * FROM usR02 INTO  lt_user
                                 WHERE bname = i_bname.
    IF sy-subrc NE 0.
      CLEAR lt_user.
      RAISE user_id_doesnt_exist.
    ENDIF.
  ENDIF.


  REFRESH:lt_mchdr,lt_mcrepid,lt_mctran,lt_mcuser,lt_mcauditor,
                                               lt_mcugroup,lt_texts.


**Calling fm for mitigation control data
  CALL FUNCTION '/PSYNG/SW_CR_READ_MIT_CONTROLS'
       EXPORTING
            contid    = i_contid
            i_vrsio   = i_vrsio
       IMPORTING
            mchdr     = lt_mchdr
       TABLES
            mcrepid   = lt_mcrepid
            mctran    = lt_mctran
            mcuser    = lt_mcuser
            mcauditor = lt_mcauditor
            mcugroup  = lt_mcugroup
            texts     = lt_texts
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             MIT_CONTROL_ID_DOESNT_EXIST = 1
             NOT_AUTHORIZED_TO_DISPLAY   = 2
             OTHERS                 = 3 .
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.


**Refreshing tables
  REFRESH: gt_mcauditor,gt_mctran,gt_mcrepid,gt_text.

** Clearing assign flag
  CLEAR:g_assign_flag.


*Reading  mitigation user internal table
  READ TABLE lt_mcuser WITH KEY   conid = i_conid  contid = i_contid
                                                    userid = i_bname.
  IF sy-subrc EQ 0.
    /psyng/mcuser-contid = i_contid.
    /psyng/mchdr-approver = lt_mchdr-approver.
    /psyng/mchdr-description = lt_mchdr-description.
    /psyng/mcuser-from_date = lt_mcuser-from_date.
    /psyng/mcuser-to_date = lt_mcuser-to_date.
    /psyng/mcauditor-auditor = lt_mcuser-auditor.

**Getting Mitigation text data
    LOOP AT lt_texts INTO wa_lt_texts  WHERE textname = i_contid
                                                  AND object   = 'M'.
      wa_gt_text-text = wa_lt_texts-text.
      APPEND wa_gt_text TO gt_text.
      CLEAR  wa_lt_texts-text.
    ENDLOOP.

**Getting Mitigation Auditors data
    LOOP AT lt_mcauditor INTO wa_lt_mcauditor WHERE
                                       contid = lt_mchdr-contid.
      wa_gt_mcauditor-auditor = wa_lt_mcauditor-auditor.
      APPEND wa_gt_mcauditor TO gt_mcauditor.
      CLEAR  wa_lt_mcauditor-auditor.
    ENDLOOP.

**Getting Mitigation Programs data
    LOOP AT lt_mcrepid INTO wa_lt_mcrepid WHERE
                                       contid = lt_mchdr-contid.

      wa_gt_mcrepid-repid = wa_lt_mcrepid-repid.
      wa_gt_mcrepid-frequency = wa_lt_mcrepid-frequency.
      APPEND wa_gt_mcrepid TO gt_mcrepid.
      CLEAR  wa_lt_mcrepid-repid.
    ENDLOOP.

**Getting Mitigation Tcodes data
    LOOP AT lt_mctran INTO wa_lt_mctran WHERE
                                       contid = lt_mchdr-contid.
      wa_gt_mctran-tcode = wa_lt_mctran-tcode.
      wa_gt_mctran-frequency = wa_lt_mctran-frequency.
      APPEND wa_gt_mctran TO gt_mctran.
      CLEAR  wa_lt_mctran-tcode.
    ENDLOOP.

***Refreshing Tables.
    REFRESH:lt_mcuser,lt_mcugroup,lt_mchdr,lt_texts.
    REFRESH : lt_mctran,lt_mcrepid,lt_mcauditor.

**Calling screen for displaying Data In screen
    CALL SCREEN 1001 STARTING AT 20 3.

    EXIT.

  ELSE.

**Fetching  CLASS for that User from usr02 table .

    SELECT SINGLE class FROM usr02 INTO lt_usr02 WHERE bname = i_bname.

*  ***Reading mitigation usergroup internal table

    READ TABLE lt_mcugroup WITH KEY conid = i_conid contid = i_contid
                                             class = lt_usr02-l_class.
    IF sy-subrc EQ 0.

      /psyng/mcuser-contid = i_contid.
      /psyng/mchdr-approver = lt_mchdr-approver.
      /psyng/mchdr-description = lt_mchdr-description.
      /psyng/mcuser-from_date = lt_mcugroup-from_date.
      /psyng/mcuser-to_date = lt_mcugroup-to_date.

***Getting auditor from mcuser table for that mitigation id and conflict
      LOOP AT lt_mcuser WHERE conid = i_conid AND contid = i_contid.
        /psyng/mcauditor-auditor = lt_mcuser-auditor.
      ENDLOOP.
      REFRESH lt_mcuser.
      g_assign_flag = 'X'.

**Getting Mitigation text data

      LOOP AT lt_texts INTO wa_lt_texts  WHERE textname = i_contid
                                                     AND object   = 'M'
                                                AND vrsio    = i_vrsio.
        wa_gt_text-text = wa_lt_texts-text.
        APPEND wa_gt_text TO gt_text.
        CLEAR  wa_lt_texts-text.
      ENDLOOP.

**Getting Mitigation Auditors data
      LOOP AT lt_mcauditor INTO wa_lt_mcauditor WHERE
                                         contid = lt_mchdr-contid.

        wa_gt_mcauditor-auditor = wa_lt_mcauditor-auditor.
        APPEND wa_gt_mcauditor TO gt_mcauditor.
        CLEAR  wa_lt_mcauditor-auditor.
      ENDLOOP.

**Getting Mitigation Programs data
      LOOP AT lt_mcrepid INTO wa_lt_mcrepid WHERE
                                         contid = lt_mchdr-contid.

        wa_gt_mcrepid-repid = wa_lt_mcrepid-repid.
        wa_gt_mcrepid-frequency = wa_lt_mcrepid-frequency.
        APPEND wa_gt_mcrepid TO gt_mcrepid.
        CLEAR  wa_lt_mcrepid-repid.
      ENDLOOP.

**Getting Mitigation Tcodes data

      LOOP AT lt_mctran INTO wa_lt_mctran WHERE
                                         contid = lt_mchdr-contid.
        wa_gt_mctran-tcode = wa_lt_mctran-tcode.
        wa_gt_mctran-frequency = wa_lt_mctran-frequency.
        APPEND wa_gt_mctran TO gt_mctran.
        CLEAR  wa_lt_mctran-tcode.
      ENDLOOP.

***Refreshing tables.
      REFRESH:lt_mcuser,lt_mcugroup,lt_texts,lt_mchdr.
      REFRESH : lt_mctran,lt_mcrepid,lt_mcauditor.

**Calling screen for displaying Data In screen
      CALL SCREEN 1001 STARTING AT 20 3.

      EXIT.
    ELSE.
***    Raising exception for class if it is not assigned.
      RAISE mit_not_asin_to_user_and_class.
    ENDIF.
  ENDIF.


ENDFUNCTION.
