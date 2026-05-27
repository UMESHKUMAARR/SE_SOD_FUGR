*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/INVISIBLE
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /PSYNG/SW_012.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(SWPROGRAM) LIKE  /PSYNG/SWINVISBL-SWPROGRAM OPTIONAL
*"     VALUE(IF_GET_HIDDEN_ELEMENTS) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      ET_HIDDEN STRUCTURE  /PSYNG/SWINVISBL OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_012'.
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
DATA: lt_hidden     TYPE TABLE OF /psyng/swinvisbl WITH HEADER LINE,
      ls_hidden_dum TYPE /psyng/swinvisbl,
      ls_config     TYPE /psyng/swconfig,
      l_objid       TYPE cdhdr-objectid,
      lt_dum        TYPE TABLE OF cdtxt.

* BOC by RGUPTA on 07.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700


IF if_get_hidden_elements IS NOT INITIAL.
    SELECT * FROM /psyng/swinvisbl INTO TABLE et_hidden. "#EC CI_NOWHERE
ELSE.
  AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
         ID 'Y&SW_ADMF' FIELD 'HIDEELEM'.
  if sy-subrc = 0.
    /PSYNG/SWINVISBL-SWPROGRAM = SWPROGRAM.
    insert into /psyng/swinvisbl values /PSYNG/SWINVISBL.
    if sy-subrc <> 0.
      RETURN-TYPE    = 'E'.
      RETURN-CODE    = '050'.
      RETURN-MESSAGE = text-e01.
      RETURN-MESSAGE_V1 = SWPROGRAM.
    else.
      RETURN-TYPE    = 'S'.
      RETURN-MESSAGE_V1 = SWPROGRAM.
        lt_hidden-swprogram = SWPROGRAM.
        l_objid = SWPROGRAM.
        CALL FUNCTION '/PSYNG/SECONFIG_WRITE_DOCUMENT'
          EXPORTING
            objectid                = l_objid
            tcode                   = '/PSYNG/SW_154'
            utime                   = sy-uzeit
            udate                   = sy-datum
            username                = l_current_user "sy-uname C0700
            planned_change_number   = ' '
            object_change_indicator = 'I'
            planned_or_real_changes = 'R'
            no_change_pointers      = ' '
            n_psyng_swinvisbl       = lt_hidden
            o_psyng_swinvisbl       = ls_hidden_dum
            upd_psyng_swinvisbl     = 'I'
            n_psyng_swconfig        = ls_config
            o_psyng_swconfig        = ls_config
            upd_psyng_swconfig      = ''
            upd_icdtxt_seconfig     = ''
          TABLES
            icdtxt_seconfig         = lt_dum.
    endif.
  else.
      RETURN-TYPE    = 'E'.
      RETURN-CODE    = '108'.
      RETURN-MESSAGE = 'Hide or Un-hide elements'(e03).
  endif.
  ENDIF.
ENDFUNCTION.
