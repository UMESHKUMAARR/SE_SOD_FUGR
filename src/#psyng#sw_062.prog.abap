*----------------------------------------------------------------------*
* Report  /PSYNG/SW_062                                                *
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
REPORT /psyng/sw_062 .
DATA : g_ta_loccon TYPE /psyng/sw_loccon OCCURS 0 WITH HEADER LINE,
       g_ta_locapp TYPE /psyng/sw_locapp OCCURS 0 WITH HEADER LINE,
       g_ta_lochdr TYPE /psyng/sw_lochdr OCCURS 0 WITH HEADER LINE,
       g_sum_app TYPE i,
       g_sum_con TYPE i,
       g_sum_hdr TYPE i.
DATA : g_pos1 TYPE i VALUE 0,
       g_pos2 TYPE i VALUE 10,
       g_pos3 TYPE i VALUE 22,
       g_pos4 TYPE i VALUE 33,
       g_pos5 TYPE i VALUE 44,
       g_pos6 TYPE i VALUE 55,
       g_pos7 TYPE i VALUE 68,
       g_pos8 TYPE i VALUE 80,
       g_pos9 TYPE i VALUE 95,
       g_pos10 TYPE i VALUE 110,
       g_pos11 TYPE i VALUE 120.

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
*BOC UMITTAL SE VF scan-25/11/2024
*--> authorirty checks is placed on DUMMY fields already
*--> hence , commenting the code.
*  AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
*           ID 'CLASS' DUMMY
*           ID 'Y&SW_VRSIO' DUMMY
*           ID 'Y&SW_COMP' DUMMY.

*  IF sy-subrc NE 0.
*    MESSAGE e398(00) WITH 'You are not Authorized.'(010).
*  ENDIF.
*EOC UMITTAL SE VF scan-25/11/2024
  PERFORM get_data.
  PERFORM display_header.
  PERFORM display_lochdr.
  PERFORM display_locapp.
  PERFORM display_loccon.


*&---------------------------------------------------------------------*
*&      Form  display_loccon
*&---------------------------------------------------------------------*
*       Display data from /PSYNG/SW_LOCCON table
*----------------------------------------------------------------------*
FORM display_loccon.
  NEW-LINE.
  FORMAT INTENSIFIED ON COLOR COL_HEADING.
  WRITE :    AT g_pos1 text-h01, "MANDT
            AT g_pos2 text-h02, "ORGNR
            AT g_pos3 text-h03, "SYSID
            AT g_pos4 text-h04, "ERDAT
            AT g_pos5 text-h05, "CONID
            AT g_pos6 text-h06, "AFF_USR_CT
            AT g_pos7 text-h07, "AFF_UG_COUNT
            AT g_pos8 text-h08. "BUSAREA
  FORMAT INTENSIFIED OFF.
  LOOP AT g_ta_loccon.
    NEW-LINE.
    WRITE  :  AT g_pos1 g_ta_loccon-mandt,
              AT g_pos2 g_ta_loccon-orgnr,
              AT g_pos3 g_ta_loccon-sysid,
              AT g_pos4 g_ta_loccon-erdat,
              AT g_pos5 g_ta_loccon-conid,
              AT g_pos6 g_ta_loccon-aff_usr_ct LEFT-JUSTIFIED,
              AT g_pos7 g_ta_loccon-aff_ug_count LEFT-JUSTIFIED,
              AT g_pos8 g_ta_loccon-busarea.
  ENDLOOP.
ENDFORM.                    " get_and_display_loccon
*&---------------------------------------------------------------------*
*&      Form  display_locapp
*&---------------------------------------------------------------------*
*       Display data from /PSYNG/SW_LOCAPP table
*----------------------------------------------------------------------*
FORM display_locapp.
  NEW-LINE.
  FORMAT INTENSIFIED ON COLOR COL_HEADING.

  WRITE :   AT g_pos1 text-h01, "MANDT
            AT g_pos2 text-h02, "ORGNR
            AT g_pos3 text-h03, "SYSID
            AT g_pos4 text-h04, "ERDAT
            AT g_pos5 text-h08, "BUSAREA
            AT g_pos6 text-h06, "AFF_USR_CT
            AT g_pos7 text-h07, "AFF_UG_COUNT
            AT g_pos8 text-h10. "SOD_COUNT
  FORMAT INTENSIFIED OFF.

  LOOP AT g_ta_locapp.
    NEW-LINE.
    WRITE :   AT g_pos1 g_ta_locapp-mandt,
              AT g_pos2 g_ta_locapp-orgnr,
              AT g_pos3 g_ta_locapp-sysid,
              AT g_pos4 g_ta_locapp-erdat,
              AT g_pos5 g_ta_locapp-busarea,
              AT g_pos6 g_ta_locapp-aff_usr_ct,
              AT g_pos7 g_ta_locapp-aff_ug_count,
              AT g_pos8 g_ta_locapp-sod_count.
  ENDLOOP.
ENDFORM.                    " get_and_display_locapp
*&---------------------------------------------------------------------*
*&      Form  display_lochdr
*&---------------------------------------------------------------------*
*       Display data from /PSYNG/SW_LOCHDR table
*----------------------------------------------------------------------*
FORM display_lochdr.
  NEW-LINE.
  FORMAT INTENSIFIED ON COLOR COL_HEADING.

  WRITE :    AT g_pos1 text-h01, "MANDT
            AT g_pos2 text-h02, "ORGNR
            AT g_pos3 text-h03, "SYSID
            AT g_pos4 text-h04, "ERDAT
            AT g_pos5 text-h09, "ERZET
            AT g_pos6 text-h06, "AFF_USR_CT
            AT g_pos7 text-h14, "TOT_USR_CT
            AT g_pos8 text-h10, "SOD_COUNT
            AT g_pos9 text-h11, "OLDST_DATE
            AT g_pos10 text-h12, "SW_VRSIO
            AT g_pos11 text-h13. "SOD_VRSIO
  FORMAT INTENSIFIED OFF.
  LOOP AT g_ta_lochdr.
    NEW-LINE.
    WRITE :   AT g_pos1 g_ta_lochdr-mandt,
              AT g_pos2 g_ta_lochdr-orgnr,
              AT g_pos3 g_ta_lochdr-sysid,
              AT g_pos4 g_ta_lochdr-erdat,
              AT g_pos5 g_ta_lochdr-erzet,
              AT g_pos6 g_ta_lochdr-aff_usr_ct,
              AT g_pos7 g_ta_lochdr-tot_usr_ct,
              AT g_pos8 g_ta_lochdr-sod_count,
              AT g_pos9 g_ta_lochdr-oldst_date,
              AT g_pos10 g_ta_lochdr-sw_vrsio,
              AT g_pos11 g_ta_lochdr-sod_vrsio.
  ENDLOOP.

ENDFORM.                    " get_and_display_lochdr
*&---------------------------------------------------------------------*
*&      Form  display_header
*&---------------------------------------------------------------------*
*       Display Header data
*----------------------------------------------------------------------*
FORM display_header.
  DATA : checksm TYPE i.
  PERFORM chksm CHANGING checksm.
  WRITE : AT g_pos10 checksm.
  ULINE.
ENDFORM.                    " display_header
*&---------------------------------------------------------------------*
*&      Form  chksm
*&---------------------------------------------------------------------*
*       Calculate checksum
*----------------------------------------------------------------------*
*  <--  e_checksum    CheckSum Value
*----------------------------------------------------------------------*
FORM chksm CHANGING e_chksm TYPE i.
  DATA : base TYPE i,
         multiplier_1 TYPE i VALUE   1709 ,
         multiplier_2 TYPE i VALUE   1061,
         multiplier_3 TYPE i VALUE   711,
         divider      TYPE i VALUE   577.

  base   =   ( g_sum_app   * multiplier_1 )
           + ( g_sum_hdr   * multiplier_2 )
           + ( g_sum_con   * multiplier_3 ).
  e_chksm = base MOD divider.
ENDFORM.                    " chksm
*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       get data from summary tables
*----------------------------------------------------------------------*
FORM get_data.
  SELECT * FROM /psyng/sw_loccon INTO TABLE g_ta_loccon ORDER BY sysid.
  LOOP AT g_ta_loccon.
* sum of affected user count for calculating checksum
    g_sum_con = g_sum_con + g_ta_loccon-aff_usr_ct.
  ENDLOOP.
  SELECT * FROM /psyng/sw_locapp INTO TABLE g_ta_locapp ORDER BY sysid.
  LOOP AT g_ta_locapp.
* sum of affected user count for calculating checksum
    g_sum_app = g_sum_app + g_ta_locapp-aff_usr_ct.
  ENDLOOP.
  SELECT * FROM /psyng/sw_lochdr INTO TABLE g_ta_lochdr ORDER BY sysid.
  LOOP AT g_ta_lochdr.
* sum of affected user count for calculating checksum
    g_sum_hdr = g_sum_hdr + g_ta_lochdr-tot_usr_ct.
  ENDLOOP.



ENDFORM.                    " get_data
