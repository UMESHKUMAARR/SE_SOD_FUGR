*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_SOD_BY_ROLE
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /PSYNG/SW_SOD_BY_ROLE.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(AGR_NAME) LIKE  AGR_DEFINE-AGR_NAME
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_ENHANC) TYPE  FLAG DEFAULT ' '
*"  TABLES
*"      1STOUTPUT_FM STRUCTURE  /PSYNG/1STOUTPUT_U
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_SOD_BY_ROLE'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  DATA: BEGIN OF simu_agrs_rfc_fm OCCURS 0.
          INCLUDE STRUCTURE /PSYNG/SW_SOD_REMOTE_ROLES.
  DATA: END OF simu_agrs_rfc_fm.
  data : lt_output type table of /PSYNG/SW_SOD_OUTPUT_ORG with header line,
         lt_dum    TYPE TABLE OF /psyng/sw_sel_opts_xubname
                   WITH HEADER LINE.
  simu_agrs_rfc_fm-rfcdest = 'LOCAL'.
  simu_agrs_rfc_fm-agr_name = AGR_NAME.
  APPEND simu_agrs_rfc_fm.
  CHECK NOT AGR_NAME IS INITIAL.
  lt_dum-low    = '000000000000'.
  lt_dum-sign   = 'I'.
  lt_dum-option = 'EQ'.
  APPEND lt_dum.

  CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
       EXPORTING
            I_VRSIO             = vrsio
            I_OUTPUT            = 'X'
            I_ENH               = i_enhanc
       TABLES
            it_users            = lt_dum
            ET_OUTPUTDET        = lt_output
            IT_SIMU_ROLE_RFC    = simu_agrs_rfc_fm.

  loop at lt_output.
      move-corresponding lt_output to 1stoutput_fm.
      append 1stoutput_fm.
  endloop.
  free lt_output.
*  CALL FUNCTION '/PSYNG/SW_SOD_SCAN'
*   EXPORTING
*      vrsio              = vrsio
*      xodt_fm            = 'X'
*      userid_fm          = '000000000000'
*      enh_fm             = i_enhanc
*   TABLES
**      SPCONFS_FM         =
*      1stoutput_fm       = 1stoutput_fm
*      SIMU_ROLE_RFC_FM   = simu_agrs_rfc_fm.

ENDFUNCTION.
