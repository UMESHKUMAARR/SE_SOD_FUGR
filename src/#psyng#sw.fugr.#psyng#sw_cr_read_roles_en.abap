FUNCTION /psyng/sw_cr_read_roles_en.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_ROLID) TYPE  /PSYNG/EX_ROLHDR_ST-ROLID OPTIONAL
*"     VALUE(I_ROLID_VALUE) TYPE  /PSYNG/KEY_VAL OPTIONAL
*"     VALUE(I_APPL) TYPE  /PSYNG/EX_ROLHDR_ST-APPL OPTIONAL
*"     VALUE(I_SYSID) TYPE  /PSYNG/EX_ROLHDR_ST-SYSID OPTIONAL
*"  EXPORTING
*"     VALUE(ES_ROLID) LIKE  /PSYNG/EX_ROLHDR_ST STRUCTURE
*"        /PSYNG/EX_ROLHDR_ST
*"     VALUE(ES_ROLID_VALUE) TYPE  /PSYNG/EX_ROLID_VALUE
*"  TABLES
*"      IT_APPL STRUCTURE  /PSYNG/RANGE_APPL OPTIONAL
*"      IT_SYSID STRUCTURE  /PSYNG/RANGE_SYSID OPTIONAL
*"      IT_ROLID STRUCTURE  /PSYNG/RANGE_ROLID OPTIONAL
*"      ET_ROLES_VALUE STRUCTURE  /PSYNG/EX_ROLID_VALUE OPTIONAL
*"  EXCEPTIONS
*"      SOURCE_ROLID_DOESNT_EXIST
*"      NOT_AUTHORIZED_TO_DISPLAY
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_READ_ROLES_EN'.
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
  DATA: ls_rolehdr TYPE  /psyng/ex_rolhdr_st,
        ls_rolid TYPE /psyng/ex_rolhdr_st,
        l_fmname(25) TYPE c,
        lf_installed TYPE flag,
        l_vrsio TYPE /psyng/prog_vrsio.

  ls_rolehdr-rolid = i_rolid.
  ls_rolehdr-appl = i_appl.
  ls_rolehdr-sysid = i_sysid.


  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
   EXPORTING
     i_module               = 'EN'
   IMPORTING
     e_installed            = lf_installed
     e_module_version       = l_vrsio.

  CHECK lf_installed = 'X' AND l_vrsio >= '2.1'.
*--EN analysis from SE is only supported from version 2.1 of EN
*  or higher.
  IF NOT ls_rolehdr-rolid IS INITIAL OR NOT i_rolid_value IS INITIAL.
    l_fmname = '/PSYNG/EX_CR_READ_ROLES'.
    CALL FUNCTION l_fmname
         EXPORTING
              i_rolid                   = ls_rolehdr-rolid
              i_rolid_value             = i_rolid_value
              i_appl                    = ls_rolehdr-appl
              i_sysid                   = ls_rolehdr-sysid
         IMPORTING
              es_rolid                  = ls_rolid
              es_rolid_value            = es_rolid_value
         EXCEPTIONS
              source_rolid_doesnt_exist = 1
              not_authorized_to_display = 2
              OTHERS                    = 3.
*BOC:HBHALLA(PN-11178)(03/01/2025)
***    IF sy-subrc = 1.
***      RAISE source_rolid_doesnt_exist.
***    ELSEIF sy-subrc = 2.
***      RAISE not_authorized_to_display.
***    ENDIF.
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN 1.
                MESSAGE e002(/psyng/sw)
             WITH 'Source Role ID doesnt exist'.
             WHEN 2.
                MESSAGE e002(/psyng/sw)
             WITH 'Not authorized to display Role ID'.
             WHEN OTHERS.
                MESSAGE e002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA(PN-11178)(03/01/2025)
    es_rolid = ls_rolid.
  ENDIF.

*---odubey 2022/01/11
  IF NOT it_rolid[] IS INITIAL.
    CLEAR l_fmname.
    l_fmname = '/PSYNG/EX_GET_ROLES'.
    CALL FUNCTION l_fmname
     EXPORTING
       i_authcheck             = 'X'
     TABLES
       it_appl                 = it_appl
       it_sysid                = it_sysid
       it_rolid                = it_rolid
       et_roles_value          = et_roles_value.
  ENDIF.

ENDFUNCTION.
