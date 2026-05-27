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
FUNCTION /psyng/sw_sod_by_profile_combo.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_ENHANC) TYPE  FLAG DEFAULT ' '
*"  EXPORTING
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      1STOUTPUT_FM STRUCTURE  /PSYNG/1STOUTPUT_U
*"      PROFILES STRUCTURE  /PSYNG/SW_SOD_REMOTE_PROFILES
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_SOD_BY_PROFILE_COMBO'.
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
data : lt_return type table of BAPIRET2 with header line,
       lt_output type table of /PSYNG/SW_SOD_OUTPUT_ORG with header line,
       lt_dum    TYPE TABLE OF /psyng/sw_sel_opts_xubname
                 WITH HEADER LINE.
  CHECK NOT profiles[] IS INITIAL.
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
            IT_SIMU_PROFILE_RFC = profiles
            et_return           = lt_return.
  loop at lt_output.
      move-corresponding lt_output to 1stoutput_fm.
      append 1stoutput_fm.
  endloop.
  free lt_output.
  read table lt_return index 1.
  if sy-subrc = 0.
    move-corresponding lt_return to return.
  endif.
*  CALL FUNCTION '/PSYNG/SW_SOD_SCAN'
*       EXPORTING
*            vrsio               = vrsio
*            xodt_fm             = 'X'
*            userid_fm           = '000000000000'
*            enh_fm              = i_enhanc
*       importing
*            return              = return
*       TABLES
*            1stoutput_fm        = 1stoutput_fm
*            simu_profile_rfc_fm = profiles.

ENDFUNCTION.
