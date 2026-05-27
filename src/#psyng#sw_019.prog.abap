*----------------------------------------------------------------------*
* Report  /PSYNG/SW_019                                                *
* AUTHOR: Security Weaver LLC
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
REPORT /psyng/sw_019 .

TABLES: /psyng/critcodes.

TYPE-POOLS: slis.

PARAMETERS : sodvrsio LIKE /psyng/critcodes-vrsio.

DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call

DATA : g_wa_busarea TYPE /psyng/busarea.


DATA: BEGIN OF output OCCURS 0,
        tcode LIKE tstc-tcode,
        ttext LIKE tstct-ttext,
        imp        LIKE /psyng/critcodes-imp,
        owner      LIKE /psyng/critcodes-owner,
        busarea(100),
        functionid LIKE /psyng/function-function,
        description LIKE /psyng/function-description,
      END OF output.

DATA: gt_function TYPE STANDARD TABLE OF /psyng/function WITH HEADER
LINE.
DATA: gt_functtran TYPE STANDARD TABLE OF /psyng/functtran
      WITH HEADER LINE.
DATA: gt_critcodes TYPE STANDARD TABLE OF /psyng/critcodes
      WITH HEADER LINE.
DATA: itstct TYPE STANDARD TABLE OF tstct WITH HEADER LINE.

*------------------------ START-OF-SELECTION --------------------------*
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
  SELECT tcode imp owner busarea FROM /psyng/critcodes
           INTO CORRESPONDING FIELDS OF TABLE gt_critcodes
           WHERE vrsio = sodvrsio
           ORDER BY tcode.
  SORT gt_critcodes BY tcode.

  IF NOT gt_critcodes[] IS INITIAL.

    SELECT tcode ttext FROM tstct
           INTO CORRESPONDING FIELDS OF TABLE itstct
           FOR ALL ENTRIES IN gt_critcodes
           WHERE tcode = gt_critcodes-tcode AND
                 sprsl = sy-langu.
    SORT itstct BY tcode.

    SELECT functionid tcode FROM /psyng/functtran
             INTO CORRESPONDING FIELDS OF TABLE gt_functtran
             FOR ALL ENTRIES IN gt_critcodes
             WHERE tcode = gt_critcodes-tcode
             AND vrsio   = sodvrsio.
    SORT gt_functtran BY tcode.

  ENDIF.

  IF NOT gt_functtran[] IS INITIAL.

    SELECT function description FROM /psyng/function
           INTO CORRESPONDING FIELDS OF TABLE gt_function
           FOR ALL ENTRIES IN gt_functtran
           WHERE function = gt_functtran-functionid
           AND   vrsio    = sodvrsio.

  ENDIF.
  SORT gt_function BY function.

  LOOP AT gt_critcodes.
    output-tcode = gt_critcodes-tcode.
    output-imp   = gt_critcodes-imp.
    output-owner = gt_critcodes-owner.
*    output-busarea = gt_critcodes-busarea.

    SELECT SINGLE * FROM /psyng/busarea        "#EC CI_SEL_NESTED
    INTO g_wa_busarea
      WHERE busarea = gt_critcodes-busarea.
    IF sy-subrc = 0.
      output-busarea = g_wa_busarea-text.
    ENDIF.
    CLEAR g_wa_busarea.

    READ TABLE itstct WITH KEY tcode = gt_critcodes-tcode
                               BINARY SEARCH.

    IF sy-subrc = 0.
      output-ttext = itstct-ttext.
    ELSE.
      output-ttext = 'Tcode for cross system analysis'(005).
    ENDIF.
    CLEAR itstct-ttext.

    LOOP AT gt_functtran WHERE tcode = gt_critcodes-tcode.

     READ TABLE gt_function WITH KEY function = gt_functtran-functionid
                    BINARY SEARCH.

      IF sy-subrc = 0.
        output-functionid    = gt_function-function.
        output-description = gt_function-description.
      ENDIF.

      APPEND output.

    ENDLOOP.

    IF sy-subrc <> 0.

      APPEND output.

    ENDIF.

    CLEAR output.

  ENDLOOP.

  SORT output.
  DELETE ADJACENT DUPLICATES FROM output.

*------------------------- END-OF-SELECTION --------------------------*
END-OF-SELECTION.
  PERFORM alv_output.

*---------------------------------------------------------------------*
*       FORM alv_output                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_output.
  DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
  DATA: l_sort TYPE slis_sortinfo_alv,
        ls_variant    TYPE disvariant,
        alv_layout    TYPE slis_layout_alv,
        alv_grid_titl TYPE lvc_title,
        program       LIKE sy-repid.


  program = sy-repid.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = program
            i_internal_tabname = 'OUTPUT'
            i_inclname         = program
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

  MOVE text-004 TO alv_grid_titl.

  l_sort-spos = '1'.
  l_sort-fieldname = 'TCODE'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'TTEXT'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'IMP'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.


  l_sort-spos = '4'.
  l_sort-fieldname = 'OWNER'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.


  l_sort-spos = '5'.
  l_sort-fieldname = 'BUSAREA'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.


  l_sort-spos = '6'.
  l_sort-fieldname = 'FUNCTIONID'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.


  l_sort-spos = '7'.
  l_sort-fieldname = 'DESCRIPTION'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.





  PERFORM change_catalog_info.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title       = alv_grid_titl
            i_callback_program = program
            it_sort            = isort
            is_layout          = alv_layout
            it_fieldcat        = i_fieldcat_alv
            i_save             = 'A'
            is_variant         = ls_variant
       TABLES
            t_outtab           = output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " alv_output
*&---------------------------------------------------------------------*
*&      Form  change_catalog_info
*&---------------------------------------------------------------------*
FORM change_catalog_info.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  wa_fieldcat_alv-seltext_l = 'Function Description'(008).
  wa_fieldcat_alv-seltext_m = 'Function'(009).
  wa_fieldcat_alv-seltext_s = 'Function'(009).
  wa_fieldcat_alv-reptext_ddic = 'Function Description'(008).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'DESCRIPTION'.

  wa_fieldcat_alv-seltext_l = 'Application Area'(001).
  wa_fieldcat_alv-seltext_m = 'Application Area'(001).
  wa_fieldcat_alv-seltext_s = 'Application Area'(001).
  wa_fieldcat_alv-reptext_ddic = 'Application Area'(001).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'BUSAREA'.

  wa_fieldcat_alv-seltext_l = 'Owner UID'(003).
  wa_fieldcat_alv-seltext_m = 'Owner UID'(003).
  wa_fieldcat_alv-seltext_s = 'Owner UID'(003).
  wa_fieldcat_alv-reptext_ddic = 'Owner UID'(003).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'OWNER'.

  wa_fieldcat_alv-seltext_l = 'Sensitivity Level'(002).
  wa_fieldcat_alv-seltext_m = 'Sensitivity Level'(002).
  wa_fieldcat_alv-seltext_s = 'Sensitivity Level'(002).
  wa_fieldcat_alv-reptext_ddic = 'Sensitivity Level'(002).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'IMP'.


ENDFORM.                    " change_catalog_info
